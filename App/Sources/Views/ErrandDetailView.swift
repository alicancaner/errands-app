import ErrandKit
import MapKit
import SwiftData
import SwiftUI

/// One errand's matched store branches: a map of everywhere a reminder could
/// fire, and per-branch control over whether it does. Preferences are GLOBAL
/// per branch ("never that Walmart" holds for every future errand), keyed by
/// the engine's StoreID so the engine and this view always agree.
struct ErrandDetailView: View {
    @Environment(\.modelContext) private var context
    let errand: Errand
    @Query private var preferences: [StorePreference]

    var body: some View {
        List {
            headerSection
            if errand.candidates.isEmpty {
                Section {
                    Text("Locations not resolved yet — branches appear after the next location fix.")
                        .foregroundStyle(.secondary)
                }
            } else {
                mapSection
                branchesSection
            }
        }
        .navigationTitle(errand.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Sections

    private var headerSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 4) {
                Text(errand.title)
                    .font(.headline)
                if !errand.storePhrases.isEmpty {
                    Text(errand.storePhrases.joined(separator: " · "))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var mapSection: some View {
        Section {
            Map(initialPosition: .automatic) {
                UserAnnotation()
                ForEach(errand.candidates, id: \.self) { candidate in
                    Marker(
                        candidate.name,
                        coordinate: CLLocationCoordinate2D(
                            latitude: candidate.lat, longitude: candidate.lon
                        )
                    )
                    .tint(isExcluded(candidate) ? Color.gray : Color.blue)
                }
            }
            .frame(height: 240)
            .listRowInsets(EdgeInsets())
        } footer: {
            Text("Blue = can remind you. Gray = excluded.")
        }
    }

    private var branchesSection: some View {
        Section("\(errand.candidates.count) matched branches") {
            ForEach(errand.candidates, id: \.self) { candidate in
                branchRow(candidate)
            }
        }
    }

    private func branchRow(_ candidate: CachedCandidate) -> some View {
        let excluded = isExcluded(candidate)
        return VStack(alignment: .leading, spacing: 6) {
            Text(candidate.name)
                .font(.headline)
                .foregroundStyle(excluded ? .secondary : .primary)
            Toggle("Use this location", isOn: useBinding(for: candidate))
            Toggle("Remind when driving", isOn: drivingBinding(for: candidate))
                .disabled(excluded)
            Toggle("Remind when walking", isOn: walkingBinding(for: candidate))
                .disabled(excluded)
        }
        .swipeActions(edge: .trailing) {
            if !excluded {
                Button(role: .destructive) {
                    setExcluded(candidate, true)
                } label: {
                    Label("Exclude", systemImage: "nosign")
                }
            }
        }
        .contextMenu {
            if !excluded {
                Button(role: .destructive) {
                    setExcluded(candidate, true)
                } label: {
                    Label("Exclude this location", systemImage: "nosign")
                }
            }
        }
    }

    // MARK: - Preference plumbing

    private func preference(for candidate: CachedCandidate) -> StorePreference? {
        let key = LocationEngine.storeKey(for: candidate)
        return preferences.first { $0.storeKey == key }
    }

    private func isExcluded(_ candidate: CachedCandidate) -> Bool {
        preference(for: candidate)?.excluded ?? false
    }

    /// Applies one change to the branch's preference (creating it on first
    /// use), saves, and replans so the change takes effect on the spot.
    private func update(_ candidate: CachedCandidate, _ mutate: (StorePreference) -> Void) {
        let pref = StorePreference.upsert(
            storeKey: LocationEngine.storeKey(for: candidate),
            name: candidate.name,
            in: context
        )
        mutate(pref)
        try? context.save()
        LocationEngine.shared.requestReplan()
    }

    private func setExcluded(_ candidate: CachedCandidate, _ excluded: Bool) {
        update(candidate) { $0.excluded = excluded }
    }

    private func useBinding(for candidate: CachedCandidate) -> Binding<Bool> {
        Binding(
            get: { !isExcluded(candidate) },
            set: { setExcluded(candidate, !$0) }
        )
    }

    private func drivingBinding(for candidate: CachedCandidate) -> Binding<Bool> {
        Binding(
            get: { preference(for: candidate)?.remindWhenDriving ?? true },
            set: { value in update(candidate) { $0.remindWhenDriving = value } }
        )
    }

    private func walkingBinding(for candidate: CachedCandidate) -> Binding<Bool> {
        Binding(
            get: { preference(for: candidate)?.remindWhenWalking ?? true },
            set: { value in update(candidate) { $0.remindWhenWalking = value } }
        )
    }
}
