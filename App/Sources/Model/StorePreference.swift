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
