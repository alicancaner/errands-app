import Foundation
import SwiftData

/// One resolved store branch, cached from map search.
///
/// Stored as a plain Codable value inside `Errand` (no relationship needed:
/// candidates are a disposable cache, re-resolved as the user moves).
struct CachedCandidate: Codable, Hashable {
    var name: String
    var lat: Double
    var lon: Double
}

@Model
final class Errand {
    var title: String
    var storePhrases: [String]

    // Resolved-branch cache; empty until StoreResolver (Task 2.5) fills it.
    var candidates: [CachedCandidate]
    var candidatesExpireAt: Date?
    // Where the cache was resolved. Re-resolve after moving > 10 km away.
    var cacheAnchorLat: Double?
    var cacheAnchorLon: Double?

    var createdAt: Date
    var completedAt: Date?

    var isCompleted: Bool { completedAt != nil }

    init(title: String, storePhrases: [String], createdAt: Date = .now) {
        self.title = title
        self.storePhrases = storePhrases
        self.candidates = []
        self.createdAt = createdAt
    }
}
