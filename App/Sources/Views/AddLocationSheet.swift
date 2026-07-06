import MapKit
import SwiftData
import SwiftUI

/// Search-and-pin: find a place by the name the user knows, give it a
/// nickname, and save. Saving does two things — attaches the place to THIS
/// errand (a value copy in `errand.pinned`, immune to cache refreshes) and
/// adds it to the global place book so future errands that mention the
/// nickname attach it automatically.
struct AddLocationSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let errand: Errand
    @ObservedObject private var engine = LocationEngine.shared

    @State private var query = ""
    @State private var results: [CachedCandidate] = []
    @State private var isSearching = false
    @State private var hasSearched = false
    @State private var pickedPlace: CachedCandidate?
    @State private var nickname = ""
    @State private var isNaming = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    TextField("Name of the place, e.g. Yaletown Animal Hospital", text: $query)
                        .submitLabel(.search)
                        .onSubmit {
                            Task { await search() }
                        }
                } footer: {
                    Text("Search by the place's real name, then give it your own nickname.")
                }

                if isSearching {
                    Section {
                        ProgressView("Searching…")
                    }
                } else if hasSearched && results.isEmpty {
                    Section {
                        Text("No places found — try the exact name")
                            .foregroundStyle(.secondary)
                    }
                } else if !results.isEmpty {
                    Section("Results") {
                        ForEach(results, id: \.self) { place in
                            Button {
                                pick(place)
                            } label: {
                                resultRow(place)
                            }
                            .foregroundStyle(.primary)
                        }
                    }
                }
            }
            .navigationTitle("Add a location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("What do you call this place? e.g. Furfur's vet",
                   isPresented: $isNaming) {
                TextField("Nickname", text: $nickname)
                Button("Save") { save() }
                Button("Cancel", role: .cancel) { pickedPlace = nil }
            }
        }
    }

    private func resultRow(_ place: CachedCandidate) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(place.name)
                .font(.headline)
            if let address = place.address {
                Text(address)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if let distance = distanceLabel(for: place) {
                Text("\(distance) away")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Search

    /// One MKLocalSearch around the last known position — same 20 km region
    /// StoreResolver uses, but inline: these results are picked by hand, not
    /// cached.
    private func search() async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        isSearching = true
        defer {
            isSearching = false
            hasSearched = true
        }

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = trimmed
        if let here = engine.lastKnownLocation {
            request.region = MKCoordinateRegion(
                center: here.coordinate,
                latitudinalMeters: StoreResolver.searchRadiusMeters,
                longitudinalMeters: StoreResolver.searchRadiusMeters
            )
        }
        do {
            let response = try await MKLocalSearch(request: request).start()
            results = response.mapItems.map { item in
                CachedCandidate(
                    name: item.name ?? trimmed,
                    lat: item.placemark.coordinate.latitude,
                    lon: item.placemark.coordinate.longitude,
                    address: item.placemark.title
                )
            }
        } catch {
            results = []
        }
    }

    private func distanceLabel(for place: CachedCandidate) -> String? {
        guard let here = engine.lastKnownLocation else { return nil }
        let distance = here.distance(
            from: CLLocation(latitude: place.lat, longitude: place.lon)
        )
        if distance < 1000 {
            return "\(Int(distance.rounded())) m"
        }
        return String(format: "%.1f km", distance / 1000)
    }

    // MARK: - Pin & save

    private func pick(_ place: CachedCandidate) {
        pickedPlace = place
        nickname = place.name
        isNaming = true
    }

    private func save() {
        guard let place = pickedPlace else { return }
        let trimmed = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalNickname = trimmed.isEmpty ? place.name : trimmed

        errand.pinned.append(place)
        context.insert(SavedPlace(
            nickname: finalNickname,
            name: place.name,
            address: place.address,
            lat: place.lat,
            lon: place.lon
        ))
        try? context.save()
        LocationEngine.shared.requestReplan()
        dismiss()
    }
}
