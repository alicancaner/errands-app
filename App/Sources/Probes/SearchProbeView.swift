import CoreLocation
import MapKit
import SwiftUI

/// Fuzzy place-search probe (Task 1.3, Gate F): does MKLocalSearch resolve
/// sloppy store phrases ("persian market") to real nearby branches?
final class SearchProbe: NSObject, ObservableObject {
    struct Row: Identifiable {
        let id = UUID()
        let name: String
        let address: String
        let distanceKm: Double
    }

    @Published private(set) var rows: [Row] = []
    @Published private(set) var status = "Type a store name and tap Search."

    private let manager = CLLocationManager()
    private var pendingQuery: String?

    override init() {
        super.init()
        manager.delegate = self
    }

    func search(_ query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        pendingQuery = trimmed
        setStatus("Getting current location…")
        manager.requestLocation()
    }

    private func runSearch(_ query: String, around location: CLLocation) {
        setStatus("Searching “\(query)”…")
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        // 40 km across = roughly "within 20 km of here".
        request.region = MKCoordinateRegion(center: location.coordinate,
                                            latitudinalMeters: 40_000,
                                            longitudinalMeters: 40_000)
        MKLocalSearch(request: request).start { [weak self] response, error in
            guard let self else { return }
            if let error {
                self.setStatus("Search failed: \(error.localizedDescription)")
                return
            }
            let items = response?.mapItems ?? []
            let rows = items.map { item in
                let distance = item.placemark.location.map { $0.distance(from: location) / 1000 } ?? .nan
                return Row(name: item.name ?? "?",
                           address: item.placemark.title ?? "no address",
                           distanceKm: distance)
            }.sorted { $0.distanceKm < $1.distanceKm }
            DispatchQueue.main.async {
                self.rows = rows
                self.status = rows.isEmpty ? "No results for “\(query)”." : "\(rows.count) results, nearest first:"
            }
        }
    }

    private func setStatus(_ text: String) {
        DispatchQueue.main.async { self.status = text }
    }
}

extension SearchProbe: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let query = pendingQuery, let location = locations.last else { return }
        pendingQuery = nil
        runSearch(query, around: location)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        pendingQuery = nil
        setStatus("Location error: \(error.localizedDescription)")
    }
}

struct SearchProbeView: View {
    @StateObject private var probe = SearchProbe()
    @State private var query = ""

    var body: some View {
        List {
            Section("Store search (20 km around you)") {
                TextField("e.g. walmart, persian market", text: $query)
                    .autocorrectionDisabled()
                    .onSubmit { probe.search(query) }
                Button("Search") { probe.search(query) }
                Text(probe.status)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Section {
                ForEach(probe.rows) { row in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(row.name).font(.headline)
                        Text(row.address).font(.caption).foregroundStyle(.secondary)
                        Text(row.distanceKm.isNaN ? "distance unknown"
                             : String(format: "%.1f km away", row.distanceKm))
                            .font(.caption.bold())
                    }
                }
            }
        }
        .navigationTitle("Search Probe")
    }
}

#Preview {
    NavigationStack {
        SearchProbeView()
    }
}
