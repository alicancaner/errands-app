import XCTest
@testable import ErrandKit

final class CandidateCachePolicyTests: XCTestCase {

    private let now = Date(timeIntervalSince1970: 1_000_000)
    private let here = GeoPoint(lat: 0, lon: 0)

    private func fresh() -> Date { now.addingTimeInterval(3_600) }

    // Expected use
    func testFreshCacheNearAnchorIsNotStale() {
        XCTAssertFalse(CandidateCachePolicy.isStale(
            expiresAt: fresh(), anchor: here, position: here, now: now
        ))
    }

    func testNeverResolvedIsStale() {
        XCTAssertTrue(CandidateCachePolicy.isStale(
            expiresAt: nil, anchor: nil, position: here, now: now
        ))
    }

    func testExpiredCacheIsStale() {
        let past = now.addingTimeInterval(-1)
        XCTAssertTrue(CandidateCachePolicy.isStale(
            expiresAt: past, anchor: here, position: here, now: now
        ))
    }

    func testMovedElevenKilometersFromAnchorIsStale() {
        // ~11 km north of the anchor (1° latitude ≈ 111,195 m).
        let position = GeoPoint(lat: 11_000 / 111_195.0, lon: 0)
        XCTAssertTrue(CandidateCachePolicy.isStale(
            expiresAt: fresh(), anchor: here, position: position, now: now
        ))
    }

    // Edge: boundaries
    func testExactlyAtExpiryIsStale() {
        XCTAssertTrue(CandidateCachePolicy.isStale(
            expiresAt: now, anchor: here, position: here, now: now
        ))
    }

    func testNineKilometersFromAnchorIsNotStale() {
        let position = GeoPoint(lat: 9_000 / 111_195.0, lon: 0)
        XCTAssertFalse(CandidateCachePolicy.isStale(
            expiresAt: fresh(), anchor: here, position: position, now: now
        ))
    }

    func testMissingAnchorIsStale() {
        XCTAssertTrue(CandidateCachePolicy.isStale(
            expiresAt: fresh(), anchor: nil, position: here, now: now
        ))
    }
}

final class GeoPointDistanceTests: XCTestCase {

    func testOneDegreeOfLatitudeIsAbout111Km() {
        let a = GeoPoint(lat: 0, lon: 0)
        let b = GeoPoint(lat: 1, lon: 0)
        XCTAssertEqual(a.distanceMeters(to: b), 111_195, accuracy: 100)
    }

    func testDistanceToSelfIsZero() {
        let a = GeoPoint(lat: 45, lon: 45)
        XCTAssertEqual(a.distanceMeters(to: a), 0, accuracy: 0.001)
    }
}
