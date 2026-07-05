import ErrandKit
import Foundation
import MapKit

/// Resolves store phrases into concrete nearby branches via MKLocalSearch.
///
/// Gate F finding: searching by the NAME the user said is the strong path;
/// category descriptors are unreliable — so each phrase is searched verbatim.
enum StoreResolver {

    static let searchRadiusMeters: CLLocationDistance = 20_000
    static let maxBranchesPerPhrase = 8

    /// Runs one search per phrase in a 20 km region around `position`.
    ///
    /// - Returns: all found branches, or `nil` if every search failed —
    ///   the caller must then leave the cache stale so the next wake retries.
    static func resolve(phrases: [String], around position: GeoPoint) async -> [CachedCandidate]? {
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: position.lat, longitude: position.lon),
            latitudinalMeters: searchRadiusMeters,
            longitudinalMeters: searchRadiusMeters
        )

        var found: [CachedCandidate] = []
        var anySucceeded = false
        for phrase in phrases {
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = phrase
            request.region = region
            do {
                let response = try await MKLocalSearch(request: request).start()
                anySucceeded = true
                found += response.mapItems.prefix(maxBranchesPerPhrase).map { item in
                    CachedCandidate(
                        name: item.name ?? phrase,
                        lat: item.placemark.coordinate.latitude,
                        lon: item.placemark.coordinate.longitude
                    )
                }
            } catch {
                // No results and network failures both land here; a phrase
                // that fails simply contributes no branches this round.
                continue
            }
        }
        return anySucceeded ? found : nil
    }
}
