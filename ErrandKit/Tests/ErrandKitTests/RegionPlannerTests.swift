import XCTest
@testable import ErrandKit

final class RegionPlannerTests: XCTestCase {

    // All tests position the user at (0, 0) and place stores by latitude
    // offset: 1 degree of latitude ≈ 111,320 m, so 0.01° ≈ 1,113 m.
    private let origin = GeoPoint(lat: 0, lon: 0)

    private func store(_ id: String, latMeters: Double, lonMeters: Double = 0) -> StoreCandidate {
        StoreCandidate(
            id: id,
            point: GeoPoint(lat: latMeters / 111_320.0, lon: lonMeters / 111_320.0)
        )
    }

    // Expected use
    func testNearestFirstWhenNoHeading() {
        let candidates = [
            store("far", latMeters: 10_000),
            store("near", latMeters: 3_000),
            store("mid", latMeters: 6_000),
        ]
        let plan = RegionPlanner.plan(
            candidates: candidates, position: origin,
            heading: nil, isDriving: false,
            insideOuterRingOf: [], cap: 2
        )
        XCTAssertEqual(plan.map(\.storeID), ["near", "mid"])
        XCTAssertTrue(plan.allSatisfy { $0.ring == .outer && $0.radius == 1_750 })
    }

    func testTwoRingPairing() {
        // Store 1 km away, and we're told we're inside its outer ring.
        let candidates = [store("close", latMeters: 1_000)]
        let plan = RegionPlanner.plan(
            candidates: candidates, position: origin,
            heading: nil, isDriving: false,
            insideOuterRingOf: ["close"], cap: 20
        )
        XCTAssertEqual(plan.count, 2)
        XCTAssertEqual(plan.filter { $0.ring == .outer }.map(\.radius), [1_750])
        XCTAssertEqual(plan.filter { $0.ring == .inner }.map(\.radius), [250])
        XCTAssertTrue(plan.allSatisfy { $0.storeID == "close" })
    }

    func testDrivingAheadBeatsBehind() {
        // Heading due north: 1 km ahead should beat 600 m behind.
        let candidates = [
            store("behind", latMeters: -600),
            store("ahead", latMeters: 1_000),
        ]
        let plan = RegionPlanner.plan(
            candidates: candidates, position: origin,
            heading: 0, isDriving: true,
            insideOuterRingOf: [], cap: 1
        )
        XCTAssertEqual(plan.map(\.storeID), ["ahead"])
    }

    func testBehindStoreNeverFullyExcluded() {
        let candidates = [
            store("behind", latMeters: -600),
            store("ahead", latMeters: 1_000),
        ]
        let plan = RegionPlanner.plan(
            candidates: candidates, position: origin,
            heading: 0, isDriving: true,
            insideOuterRingOf: [], cap: 20
        )
        XCTAssertTrue(plan.contains { $0.storeID == "behind" })
    }

    func testNoDirectionBiasWhenNotDriving() {
        // Walking with a heading: nearest still wins.
        let candidates = [
            store("behind", latMeters: -600),
            store("ahead", latMeters: 1_000),
        ]
        let plan = RegionPlanner.plan(
            candidates: candidates, position: origin,
            heading: 0, isDriving: false,
            insideOuterRingOf: [], cap: 1
        )
        XCTAssertEqual(plan.map(\.storeID), ["behind"])
    }

    // Edge cases
    func testEmptyCandidatesGivesEmptyPlan() {
        let plan = RegionPlanner.plan(
            candidates: [], position: origin,
            heading: nil, isDriving: false,
            insideOuterRingOf: [], cap: 20
        )
        XCTAssertTrue(plan.isEmpty)
    }

    func testCapEnforcedAt20With40Candidates() {
        let candidates = (1...40).map { store("s\(String(format: "%02d", $0))", latMeters: Double($0) * 500) }
        let plan = RegionPlanner.plan(
            candidates: candidates, position: origin,
            heading: nil, isDriving: false,
            insideOuterRingOf: [], cap: 20
        )
        XCTAssertEqual(plan.count, 20)
    }

    // Exclusions (Task 2.8.1)
    func testExcludedNearestStoreAbsentAndSlotGoesToNextCandidate() {
        let candidates = [
            store("near", latMeters: 1_000),
            store("mid", latMeters: 3_000),
            store("far", latMeters: 5_000),
        ]
        let plan = RegionPlanner.plan(
            candidates: candidates, position: origin,
            heading: nil, isDriving: false,
            insideOuterRingOf: [], excluding: ["near"], cap: 2
        )
        XCTAssertEqual(plan.map(\.storeID), ["mid", "far"])
    }

    func testExcludingEveryCandidateGivesEmptyPlan() {
        let candidates = [
            store("a", latMeters: 1_000),
            store("b", latMeters: 2_000),
        ]
        let plan = RegionPlanner.plan(
            candidates: candidates, position: origin,
            heading: nil, isDriving: false,
            insideOuterRingOf: [], excluding: ["a", "b"], cap: 20
        )
        XCTAssertTrue(plan.isEmpty)
    }

    func testExcludedStoreGetsNoInnerRingEvenWhenInsideItsOuterRing() {
        let candidates = [
            store("excluded", latMeters: 1_000),
            store("kept", latMeters: 2_000),
        ]
        let plan = RegionPlanner.plan(
            candidates: candidates, position: origin,
            heading: nil, isDriving: false,
            insideOuterRingOf: ["excluded"], excluding: ["excluded"], cap: 20
        )
        XCTAssertFalse(plan.contains { $0.storeID == "excluded" })
        XCTAssertEqual(plan.map(\.storeID), ["kept"])
    }

    func testStableOrderingForEqualScores() {
        // Two stores at identical distance: tie broken by StoreID.
        let candidates = [
            store("zeta", latMeters: 2_000),
            store("alpha", latMeters: -2_000),
        ]
        let plan = RegionPlanner.plan(
            candidates: candidates, position: origin,
            heading: nil, isDriving: false,
            insideOuterRingOf: [], cap: 20
        )
        XCTAssertEqual(plan.map(\.storeID), ["alpha", "zeta"])
    }
}
