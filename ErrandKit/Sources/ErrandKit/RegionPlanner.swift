import Foundation

public typealias StoreID = String

/// A resolved store branch that could receive a geofence.
public struct StoreCandidate: Equatable, Sendable {
    public let id: StoreID
    public let point: GeoPoint

    public init(id: StoreID, point: GeoPoint) {
        self.id = id
        self.point = point
    }
}

public enum RingKind: Equatable, Sendable {
    case outer
    case inner
}

/// One geofence the engine should have iOS monitor.
public struct PlannedRegion: Equatable, Sendable {
    public let storeID: StoreID
    public let center: GeoPoint
    public let radius: Double
    public let ring: RingKind

    public init(storeID: StoreID, center: GeoPoint, radius: Double, ring: RingKind) {
        self.storeID = storeID
        self.center = center
        self.radius = radius
        self.ring = ring
    }
}

/// Picks which (at most `cap`) geofences to plant, nearest-first with an
/// optional direction bias while driving, pairing an inner ring onto stores
/// whose outer ring we're already inside.
public enum RegionPlanner {

    public static let outerRadius: Double = 1_750
    public static let innerRadius: Double = 250

    /// Plans the geofence set for the current situation.
    ///
    /// - Parameters:
    ///   - candidates: all resolved branches for all open errands.
    ///   - position: current location.
    ///   - heading: course over ground in degrees (0 = north), if known.
    ///   - isDriving: whether motion says we're in a vehicle.
    ///   - insideOuterRingOf: stores whose outer ring we're currently inside.
    ///   - excluding: user-excluded stores; never receive any region, their
    ///     slots go to the next-best candidates.
    ///   - cap: iOS region-monitoring limit (20).
    /// - Returns: regions to monitor; inner rings count against the cap.
    public static func plan(
        candidates: [StoreCandidate],
        position: GeoPoint,
        heading: Double?,
        isDriving: Bool,
        insideOuterRingOf: Set<StoreID>,
        excluding: Set<StoreID> = [],
        cap: Int = 20
    ) -> [PlannedRegion] {
        // Score = distance, penalized by angular deviation from heading when
        // driving. Multiplicative penalty (max 2x at 180°) deprioritizes
        // stores behind us without ever excluding them.
        let allowed = candidates.filter { !excluding.contains($0.id) }
        let scored = allowed.map { candidate -> (score: Double, candidate: StoreCandidate) in
            let distance = Geo.distanceMeters(from: position, to: candidate.point)
            var score = distance
            if isDriving, let heading {
                let bearing = Geo.bearingDegrees(from: position, to: candidate.point)
                let deviation = Geo.angularDifference(heading, bearing)
                score = distance * (1 + deviation / 180.0)
            }
            return (score, candidate)
        }
        .sorted {
            $0.score != $1.score ? $0.score < $1.score : $0.candidate.id < $1.candidate.id
        }

        var regions: [PlannedRegion] = []
        for (_, candidate) in scored {
            if regions.count >= cap { break }
            regions.append(PlannedRegion(
                storeID: candidate.id, center: candidate.point,
                radius: outerRadius, ring: .outer
            ))
            if insideOuterRingOf.contains(candidate.id), regions.count < cap {
                regions.append(PlannedRegion(
                    storeID: candidate.id, center: candidate.point,
                    radius: innerRadius, ring: .inner
                ))
            }
        }
        return regions
    }
}

/// Foundation-only geodesy helpers (no CoreLocation on Windows/Linux).
enum Geo {

    /// Haversine great-circle distance in meters.
    static func distanceMeters(from a: GeoPoint, to b: GeoPoint) -> Double {
        let earthRadius = 6_371_000.0
        let dLat = (b.lat - a.lat) * .pi / 180
        let dLon = (b.lon - a.lon) * .pi / 180
        let lat1 = a.lat * .pi / 180
        let lat2 = b.lat * .pi / 180
        let h = sin(dLat / 2) * sin(dLat / 2)
            + cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2)
        return 2 * earthRadius * asin(min(1, sqrt(h)))
    }

    /// Initial bearing from `a` to `b` in degrees, 0 = north, clockwise.
    static func bearingDegrees(from a: GeoPoint, to b: GeoPoint) -> Double {
        let lat1 = a.lat * .pi / 180
        let lat2 = b.lat * .pi / 180
        let dLon = (b.lon - a.lon) * .pi / 180
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let degrees = atan2(y, x) * 180 / .pi
        return (degrees + 360).truncatingRemainder(dividingBy: 360)
    }

    /// Smallest absolute difference between two bearings, in [0, 180].
    static func angularDifference(_ a: Double, _ b: Double) -> Double {
        let diff = abs(a - b).truncatingRemainder(dividingBy: 360)
        return diff > 180 ? 360 - diff : diff
    }
}
