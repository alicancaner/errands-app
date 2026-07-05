import Foundation
import SwiftData

/// The user's standing decision about one store branch, keyed by the
/// engine's StoreID ("lat,lon|name"). Global — outlives any single errand.
@Model
final class StorePreference {
    var storeKey: String
    var name: String
    var excluded: Bool
    var remindWhenDriving: Bool
    var remindWhenWalking: Bool

    init(storeKey: String, name: String) {
        self.storeKey = storeKey
        self.name = name
        self.excluded = false
        self.remindWhenDriving = true
        self.remindWhenWalking = true
    }
}

extension StorePreference {
    /// Fetches the preference row for `storeKey`, creating it on first use —
    /// every view that flips a toggle goes through here so a branch never
    /// gets two preference rows.
    static func upsert(storeKey: String, name: String, in context: ModelContext) -> StorePreference {
        let descriptor = FetchDescriptor<StorePreference>(
            predicate: #Predicate { $0.storeKey == storeKey }
        )
        if let existing = (try? context.fetch(descriptor))?.first {
            return existing
        }
        let created = StorePreference(storeKey: storeKey, name: name)
        context.insert(created)
        return created
    }
}
