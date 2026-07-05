import XCTest
@testable import ErrandKit

/// Smoke test proving the package + toolchain wiring works (Task 2.0).
final class ErrandKitSmokeTests: XCTestCase {
    func testGeoPointRoundTrip() {
        let p = GeoPoint(lat: 39.0, lon: -108.5)
        XCTAssertEqual(p, GeoPoint(lat: 39.0, lon: -108.5))
    }
}
