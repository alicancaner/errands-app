import SwiftData
import SwiftUI

@main
struct ErrandsApp: App {
    // Created at launch so region events that relaunch a terminated app
    // are delivered to the probe's CLLocationManager delegate.
    private let geofenceProbe = GeofenceProbe.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: Errand.self)
    }
}
