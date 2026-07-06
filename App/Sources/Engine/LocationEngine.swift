import CoreLocation
import CoreMotion
import ErrandKit
import Foundation
import SwiftData
import UserNotifications

/// The integration heart: wakes on significant location changes, refreshes
/// stale store caches, asks `RegionPlanner` which geofences to monitor, and
/// on geofence entry asks `NotificationPolicy` what to do. All decisions
/// live in ErrandKit; this class only wires iOS frameworks to them.
///
/// Must be created (and configured) at app launch: when iOS relaunches a
/// terminated app for a region event, the event is only delivered if a
/// manager with a delegate exists by the end of launch.
final class LocationEngine: NSObject, ObservableObject {
    static let shared = LocationEngine()

    /// Rolling event log (persisted) — surfaced by the Diagnostics screen.
    @Published private(set) var events: [String] = []

    /// Last fix we saw — drives the "850 m away" labels on branch cards.
    @Published private(set) var lastKnownLocation: CLLocation?

    private let manager = CLLocationManager()
    private let motion = CMMotionActivityManager()
    private var container: ModelContainer?
    private var isReplanning = false

    private static let eventsKey = "engine.events"
    private static let maxEvents = 50
    private static let regionPrefix = "errand|"

    private override init() {
        super.init()
        events = UserDefaults.standard.stringArray(forKey: Self.eventsKey) ?? []
        manager.delegate = self
    }

    /// Called once at launch. Starts the cheap always-on wake source.
    func configure(container: ModelContainer) {
        self.container = container
        lastKnownLocation = manager.location
        manager.startMonitoringSignificantLocationChanges()
        log("Engine started (significant-location-change monitoring on)")
        requestReplan()
    }

    /// Asks for a fresh location; the replan runs when it arrives.
    /// Call after any errand change (add / complete / delete).
    func requestReplan() {
        manager.requestLocation()
    }

    // MARK: - Effective branches

    /// candidates (auto) + pinned (manual) + nickname-matched saved places,
    /// deduped by storeKey. Pins and saved places are immune to cache refreshes.
    static func effectiveBranches(for errand: Errand, savedPlaces: [SavedPlace]) -> [CachedCandidate] {
        var seen = Set<StoreID>()
        var result: [CachedCandidate] = []
        let matched = savedPlaces.filter { place in
            errand.storePhrases.contains { SavedPlaceMatcher.matches(nickname: place.nickname, phrase: $0) }
        }.map(\.asCandidate)
        for candidate in errand.pinned + matched + errand.candidates {
            let key = storeKey(for: candidate)
            if seen.insert(key).inserted { result.append(candidate) }
        }
        return result
    }

    // MARK: - Replanning

    @MainActor
    private func replan(around location: CLLocation) async {
        guard let container, !isReplanning else { return }
        isReplanning = true
        defer { isReplanning = false }

        let position = GeoPoint(
            lat: location.coordinate.latitude,
            lon: location.coordinate.longitude
        )
        let context = container.mainContext
        guard let open = try? context.fetch(
            FetchDescriptor<Errand>(predicate: #Predicate { $0.completedAt == nil })
        ) else { return }

        await refreshStaleCaches(of: open, at: position, context: context)

        let savedPlaces = (try? context.fetch(FetchDescriptor<SavedPlace>())) ?? []

        // Unique store branches across all open errands.
        var byID: [StoreID: StoreCandidate] = [:]
        for errand in open {
            for candidate in Self.effectiveBranches(for: errand, savedPlaces: savedPlaces) {
                let id = Self.storeKey(for: candidate)
                byID[id] = StoreCandidate(
                    id: id, point: GeoPoint(lat: candidate.lat, lon: candidate.lon)
                )
            }
        }
        let candidates = Array(byID.values)
        let insideOuter = Set(candidates
            .filter { $0.point.distanceMeters(to: position) < RegionPlanner.outerRadius }
            .map(\.id))

        // Standing user exclusions: never plant rings on these branches.
        let excludedPrefs = (try? context.fetch(
            FetchDescriptor<StorePreference>(predicate: #Predicate { $0.excluded })
        )) ?? []
        let excluded = Set(excludedPrefs.map(\.storeKey))

        let plan = RegionPlanner.plan(
            candidates: candidates,
            position: position,
            heading: location.course >= 0 ? location.course : nil,
            isDriving: await isDrivingNow(),
            insideOuterRingOf: insideOuter,
            excluding: excluded
        )
        apply(plan)
        log("Planned \(plan.count) regions from \(candidates.count) branches (\(open.count) open errands, \(excluded.count) excluded)")
    }

    @MainActor
    private func refreshStaleCaches(of errands: [Errand], at position: GeoPoint, context: ModelContext) async {
        for errand in errands where !errand.storePhrases.isEmpty {
            let anchor = errand.cacheAnchorLat.flatMap { lat in
                errand.cacheAnchorLon.map { GeoPoint(lat: lat, lon: $0) }
            }
            guard CandidateCachePolicy.isStale(
                expiresAt: errand.candidatesExpireAt,
                anchor: anchor, position: position, now: .now
            ) else { continue }

            // nil = every search failed; leave the cache stale so the next
            // wake retries (e.g. no signal right now).
            guard let found = await StoreResolver.resolve(
                phrases: errand.storePhrases, around: position
            ) else {
                log("Resolve FAILED for “\(errand.title)” — will retry next wake")
                continue
            }
            errand.candidates = found
            errand.candidatesExpireAt = Date().addingTimeInterval(CandidateCachePolicy.lifetime)
            errand.cacheAnchorLat = position.lat
            errand.cacheAnchorLon = position.lon
            log("Resolved \(found.count) branches for “\(errand.title)”")
        }
        try? context.save()
    }

    /// Diffs the plan against currently monitored regions; touches only ours
    /// (prefix "errand|") so probe regions keep working.
    private func apply(_ plan: [PlannedRegion]) {
        let desired = Dictionary(uniqueKeysWithValues: plan.map {
            (Self.regionIdentifier(ring: $0.ring, storeID: $0.storeID), $0)
        })
        let current = manager.monitoredRegions.filter {
            $0.identifier.hasPrefix(Self.regionPrefix)
        }

        for region in current where desired[region.identifier] == nil {
            manager.stopMonitoring(for: region)
        }
        let currentIDs = Set(current.map(\.identifier))
        for (id, planned) in desired where !currentIDs.contains(id) {
            let region = CLCircularRegion(
                center: CLLocationCoordinate2D(latitude: planned.center.lat, longitude: planned.center.lon),
                radius: planned.radius,
                identifier: id
            )
            region.notifyOnEntry = true
            // Leaving an outer ring changes what should be planted (its
            // inner ring is now pointless) — use exits as a replan trigger.
            region.notifyOnExit = planned.ring == .outer
            manager.startMonitoring(for: region)
        }
    }

    // MARK: - Entry events

    @MainActor
    private func handleEntry(ring: RingKind, storeID: StoreID) async {
        guard let container else { return }
        let isDriving = await isDrivingNow()
        let context = container.mainContext
        guard let open = try? context.fetch(
            FetchDescriptor<Errand>(predicate: #Predicate { $0.completedAt == nil })
        ) else { return }

        // The user's standing toggles for this branch, if any were ever set.
        let preference = (try? context.fetch(
            FetchDescriptor<StorePreference>(predicate: #Predicate { $0.storeKey == storeID })
        ))?.first

        let savedPlaces = (try? context.fetch(FetchDescriptor<SavedPlace>())) ?? []

        var needsReplan = false
        for errand in open where Self.effectiveBranches(for: errand, savedPlaces: savedPlaces)
            .contains(where: { Self.storeKey(for: $0) == storeID }) {
            let decision = NotificationPolicy.decide(
                ring: ring,
                isDriving: isDriving,
                errandCompleted: errand.isCompleted,
                lastNotifiedAt: errand.notifiedAt[storeID],
                remindWhenDriving: preference?.remindWhenDriving ?? true,
                remindWhenWalking: preference?.remindWhenWalking ?? true,
                now: .now
            )
            switch decision {
            case .notifyNow:
                notify(errand: errand, storeID: storeID)
                errand.notifiedAt[storeID] = .now
            case .plantInner:
                needsReplan = true
                log("ENTER outer \(Self.displayName(of: storeID)) not driving → plant inner")
            case .suppress:
                log("ENTER \(Self.displayName(of: storeID)) for “\(errand.title)” → suppressed")
            }
        }
        try? context.save()
        if needsReplan {
            requestReplan()
        }
    }

    private func notify(errand: Errand, storeID: StoreID) {
        let store = Self.displayName(of: storeID)
        let content = UNMutableNotificationContent()
        content.title = errand.title
        content.body = "\(store) is nearby"
        content.sound = .default
        UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        )
        log("NOTIFY “\(errand.title)” near \(store)")
    }

    // MARK: - Motion

    /// Snapshot of "am I driving right now?" from the motion coprocessor's
    /// recent history. None/unknown/low-confidence → false (Gate F: the safe
    /// default is "not driving", which walks the two-ring path).
    private func isDrivingNow() async -> Bool {
        guard CMMotionActivityManager.isActivityAvailable() else { return false }
        return await withCheckedContinuation { continuation in
            motion.queryActivityStarting(
                from: Date().addingTimeInterval(-120), to: Date(), to: .main
            ) { activities, _ in
                let latest = activities?.reversed().first { $0.confidence != .low }
                continuation.resume(returning: latest?.automotive ?? false)
            }
        }
    }

    // MARK: - Identifiers

    /// StoreID = "lat,lon|name" — stable across replans, and carries the
    /// display name so entry events can name the store without a lookup.
    /// Internal so views key `StorePreference` records identically.
    static func storeKey(for candidate: CachedCandidate) -> StoreID {
        String(format: "%.5f,%.5f|%@", candidate.lat, candidate.lon, candidate.name)
    }

    private static func regionIdentifier(ring: RingKind, storeID: StoreID) -> String {
        "errand|\(ring == .inner ? "inner" : "outer")|\(storeID)"
    }

    private static func parseIdentifier(_ id: String) -> (ring: RingKind, storeID: StoreID)? {
        let parts = id.split(separator: "|", maxSplits: 2, omittingEmptySubsequences: false)
        guard parts.count == 3, parts[0] == "errand" else { return nil }
        return (parts[1] == "inner" ? .inner : .outer, String(parts[2]))
    }

    private static func displayName(of storeID: StoreID) -> String {
        storeID.split(separator: "|", maxSplits: 1, omittingEmptySubsequences: false)
            .last.map(String.init) ?? storeID
    }

    // MARK: - Log

    private func log(_ message: String) {
        let stamp = Date().formatted(date: .abbreviated, time: .standard)
        let line = "\(stamp) — \(message)"
        DispatchQueue.main.async {
            self.events.insert(line, at: 0)
            if self.events.count > Self.maxEvents {
                self.events.removeLast(self.events.count - Self.maxEvents)
            }
            UserDefaults.standard.set(self.events, forKey: Self.eventsKey)
        }
    }
}

// MARK: - Diagnostics support

/// A currently monitored errand region, parsed for display. Carries its
/// storeKey so Diagnostics can exclude the branch straight from a region row.
struct MonitoredRegionInfo: Identifiable {
    let id: String
    let storeKey: StoreID
    let storeName: String
    let center: CLLocationCoordinate2D
    let radius: Double
    let ring: RingKind
}

extension LocationEngine {
    /// Snapshot of the errand regions iOS is watching right now.
    func plantedRegions() -> [MonitoredRegionInfo] {
        manager.monitoredRegions.compactMap { region in
            guard let circular = region as? CLCircularRegion,
                  let (ring, storeID) = Self.parseIdentifier(region.identifier)
            else { return nil }
            return MonitoredRegionInfo(
                id: region.identifier,
                storeKey: storeID,
                storeName: Self.displayName(of: storeID),
                center: circular.center,
                radius: circular.radius,
                ring: ring
            )
        }
        .sorted { $0.id < $1.id }
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationEngine: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        DispatchQueue.main.async { self.lastKnownLocation = location }
        log("Wake at \(String(format: "%.4f, %.4f", location.coordinate.latitude, location.coordinate.longitude))")
        Task { @MainActor in
            await self.replan(around: location)
        }
    }

    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        guard let (ring, storeID) = Self.parseIdentifier(region.identifier) else { return }
        log("ENTER \(ring == .inner ? "inner" : "outer") ring: \(Self.displayName(of: storeID))")
        Task { @MainActor in
            await self.handleEntry(ring: ring, storeID: storeID)
        }
    }

    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        guard let (ring, storeID) = Self.parseIdentifier(region.identifier), ring == .outer else { return }
        log("EXIT outer ring: \(Self.displayName(of: storeID)) → replan")
        requestReplan()
    }

    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        log("Monitoring FAILED for \(region?.identifier ?? "?"): \(error.localizedDescription)")
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        log("Location error: \(error.localizedDescription)")
    }
}
