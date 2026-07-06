import Foundation
import SwiftData

/// One place the user taught the app ("Furfur's vet"). Global place book:
/// future errands whose store phrase mentions the nickname attach it
/// automatically. Deleting a SavedPlace stops future attaching only — value
/// copies already pinned onto errands survive.
@Model
final class SavedPlace {
    var nickname: String
    var name: String
    var address: String?
    var lat: Double
    var lon: Double
    var createdAt: Date

    init(nickname: String, name: String, address: String?, lat: Double, lon: Double) {
        self.nickname = nickname
        self.name = name
        self.address = address
        self.lat = lat
        self.lon = lon
        self.createdAt = .now
    }

    var asCandidate: CachedCandidate {
        CachedCandidate(name: name, lat: lat, lon: lon, address: address)
    }
}
