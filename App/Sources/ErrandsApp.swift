import SwiftData
import SwiftUI

@main
struct ErrandsApp: App {
    // Created at launch so region events that relaunch a terminated app
    // are delivered to each CLLocationManager delegate.
    private let geofenceProbe = GeofenceProbe.shared
    private let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: Errand.self)
        } catch {
            fatalError("Could not create SwiftData container: \(error)")
        }
        LocationEngine.shared.configure(container: container)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
