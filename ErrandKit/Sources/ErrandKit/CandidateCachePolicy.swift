import Foundation

public extension GeoPoint {
    /// Great-circle distance to another point, in meters.
    func distanceMeters(to other: GeoPoint) -> Double {
        Geo.distanceMeters(from: self, to: other)
    }
}

/// Decides when an errand's resolved-branch cache must be refreshed.
///
/// Stale = never resolved, past its expiry, or the user has moved more than
/// 10 km from where the search was run (branches "near me" are different now).
public enum CandidateCachePolicy {

    /// How long a successful resolution stays valid.
    public static let lifetime: TimeInterval = 24 * 60 * 60

    /// Movement from the cache anchor that forces a re-resolve.
    public static let maxAnchorDistance: Double = 10_000

    public static func isStale(
        expiresAt: Date?,
        anchor: GeoPoint?,
        position: GeoPoint,
        now: Date
    ) -> Bool {
        guard let expiresAt, let anchor else { return true }
        if now >= expiresAt { return true }
        return position.distanceMeters(to: anchor) > maxAnchorDistance
    }
}
