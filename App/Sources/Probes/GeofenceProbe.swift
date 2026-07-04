import CoreLocation
import Foundation
import UserNotifications

/// Owns the CLLocationManager for the geofencing probe (Task 1.1, Gate D).
///
/// Must be created at app launch: when iOS relaunches a terminated app for a
/// region event, the event is only delivered if a manager with a delegate
/// exists by the end of launch.
final class GeofenceProbe: NSObject, ObservableObject {
    static let shared = GeofenceProbe()

    @Published private(set) var events: [String] = []
    @Published private(set) var authDescription: String = "unknown"
    @Published private(set) var notificationsGranted: Bool?
    @Published private(set) var plantedAt: Date?

    private let manager = CLLocationManager()
    private var isPlanting = false

    private static let eventsKey = "geofence.events"
    private static let plantedKey = "geofence.plantedAt"
    private static let regionID = "tripwire"
    private static let maxEvents = 20

    private override init() {
        super.init()
        events = UserDefaults.standard.stringArray(forKey: Self.eventsKey) ?? []
        plantedAt = UserDefaults.standard.object(forKey: Self.plantedKey) as? Date
        manager.delegate = self
        UNUserNotificationCenter.current().delegate = self
        log("App launched")
    }

    // MARK: - Actions

    /// Standard two-step CoreLocation flow: When In Use first, then Always.
    func requestLocationPermission() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse:
            manager.requestAlwaysAuthorization()
        case .authorizedAlways:
            log("Location already set to Always")
        default:
            log("Location denied/restricted — fix in Settings > Privacy > Location")
        }
    }

    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                self.notificationsGranted = granted
                self.log(granted ? "Notifications allowed" : "Notifications NOT allowed\(error.map { ": \($0.localizedDescription)" } ?? "")")
            }
        }
    }

    func plantTripwireHere() {
        isPlanting = true
        log("Planting: getting current location…")
        manager.requestLocation()
    }

    // MARK: - Internals

    private func plant(at coordinate: CLLocationCoordinate2D) {
        // Replace any previous tripwire so there is only ever one.
        for region in manager.monitoredRegions where region.identifier == Self.regionID {
            manager.stopMonitoring(for: region)
        }
        let region = CLCircularRegion(center: coordinate, radius: 300, identifier: Self.regionID)
        region.notifyOnEntry = true
        region.notifyOnExit = true
        manager.startMonitoring(for: region)

        let now = Date()
        plantedAt = now
        UserDefaults.standard.set(now, forKey: Self.plantedKey)
        log(String(format: "Planted 300 m tripwire at %.5f, %.5f", coordinate.latitude, coordinate.longitude))
    }

    private func fireNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

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

    private func describe(_ status: CLAuthorizationStatus) -> String {
        switch status {
        case .notDetermined: return "not determined"
        case .restricted: return "restricted"
        case .denied: return "DENIED"
        case .authorizedWhenInUse: return "While Using (need Always)"
        case .authorizedAlways: return "Always ✓"
        @unknown default: return "unknown"
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension GeofenceProbe: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let text = describe(manager.authorizationStatus)
        DispatchQueue.main.async { self.authDescription = text }
        log("Location permission: \(text)")
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard isPlanting, let location = locations.last else { return }
        isPlanting = false
        plant(at: location.coordinate)
    }

    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        let stamp = Date().formatted(date: .omitted, time: .standard)
        log("ENTER \(region.identifier)")
        fireNotification(title: "ENTERED tripwire", body: "Crossed into the 300 m ring at \(stamp)")
    }

    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        let stamp = Date().formatted(date: .omitted, time: .standard)
        log("EXIT \(region.identifier)")
        fireNotification(title: "EXITED tripwire", body: "Crossed out of the 300 m ring at \(stamp)")
    }

    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        log("Monitoring FAILED for \(region?.identifier ?? "?"): \(error.localizedDescription)")
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        isPlanting = false
        log("Location error: \(error.localizedDescription)")
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension GeofenceProbe: UNUserNotificationCenterDelegate {
    /// Show banners even while the app is in the foreground (useful during testing).
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .list])
    }
}
