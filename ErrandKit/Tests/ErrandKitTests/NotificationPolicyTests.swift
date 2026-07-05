import XCTest
@testable import ErrandKit

final class NotificationPolicyTests: XCTestCase {

    private let now = Date(timeIntervalSince1970: 1_000_000)

    private func decide(
        ring: RingKind,
        isDriving: Bool = false,
        errandCompleted: Bool = false,
        lastNotifiedAt: Date? = nil
    ) -> NotificationDecision {
        NotificationPolicy.decide(
            ring: ring,
            isDriving: isDriving,
            errandCompleted: errandCompleted,
            lastNotifiedAt: lastNotifiedAt,
            now: now
        )
    }

    // Expected use — the decision table from the plan
    func testOuterRingWhileDrivingNotifies() {
        XCTAssertEqual(decide(ring: .outer, isDriving: true), .notifyNow)
    }

    func testOuterRingWhileNotDrivingPlantsInner() {
        // Walking, stationary, and unknown motion all arrive as isDriving:
        // false (Gate F: treat none/unknown as "not driving").
        XCTAssertEqual(decide(ring: .outer, isDriving: false), .plantInner)
    }

    func testInnerRingNotifiesWhenNotDriving() {
        XCTAssertEqual(decide(ring: .inner, isDriving: false), .notifyNow)
    }

    func testInnerRingNotifiesWhenDriving() {
        XCTAssertEqual(decide(ring: .inner, isDriving: true), .notifyNow)
    }

    // Cooldown
    func testNotifiedOneHourAgoSuppresses() {
        let oneHourAgo = now.addingTimeInterval(-3_600)
        XCTAssertEqual(
            decide(ring: .outer, isDriving: true, lastNotifiedAt: oneHourAgo),
            .suppress
        )
    }

    func testCooldownAlsoSuppressesInnerRing() {
        let oneHourAgo = now.addingTimeInterval(-3_600)
        XCTAssertEqual(
            decide(ring: .inner, lastNotifiedAt: oneHourAgo),
            .suppress
        )
    }

    func testCooldownAlsoSuppressesInnerPlanting() {
        // No point planting an inner ring whose entry would be suppressed.
        let oneHourAgo = now.addingTimeInterval(-3_600)
        XCTAssertEqual(
            decide(ring: .outer, isDriving: false, lastNotifiedAt: oneHourAgo),
            .suppress
        )
    }

    // Edge: cooldown is "< 2 h ago" — exactly 2 h ago is allowed again.
    func testNotifiedExactlyTwoHoursAgoAllowsAgain() {
        let twoHoursAgo = now.addingTimeInterval(-7_200)
        XCTAssertEqual(
            decide(ring: .outer, isDriving: true, lastNotifiedAt: twoHoursAgo),
            .notifyNow
        )
    }

    // Completed errand wins over everything
    func testCompletedErrandSuppressesEverywhere() {
        XCTAssertEqual(
            decide(ring: .inner, isDriving: true, errandCompleted: true),
            .suppress
        )
        XCTAssertEqual(
            decide(ring: .outer, isDriving: true, errandCompleted: true),
            .suppress
        )
        XCTAssertEqual(
            decide(ring: .outer, isDriving: false, errandCompleted: true),
            .suppress
        )
    }
}
