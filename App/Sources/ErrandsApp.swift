import SwiftData
import SwiftUI

@main
struct ErrandsApp: App {
    // Created at launch so region events that relaunch a terminated app
    // are delivered to each CLLocationManager delegate.
    private let geofenceProbe = GeofenceProbe.shared

    init() {
        LocationEngine.shared.configure(container: AppDatabase.container)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(AppDatabase.container)
    }
}
