import SwiftData

/// The single shared SwiftData container. The app UI, the location engine,
/// and App Intents (which iOS may run in a background-launched process,
/// without the UI) must all open the same store.
enum AppDatabase {
    static let container: ModelContainer = {
        do {
            return try ModelContainer(for: Errand.self)
        } catch {
            fatalError("Could not create SwiftData container: \(error)")
        }
    }()
}
