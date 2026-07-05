import Foundation

/// A plain latitude/longitude pair.
///
/// ErrandKit never imports CoreLocation, so coordinates travel as this
/// simple struct; the app layer converts to/from `CLLocationCoordinate2D`.
public struct GeoPoint: Equatable, Hashable, Sendable {
    public let lat: Double
    public let lon: Double

    public init(lat: Double, lon: Double) {
        self.lat = lat
        self.lon = lon
    }
}
