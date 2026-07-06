import ErrandKit
import MapKit
import SwiftData
import SwiftUI

/// One errand's matched store branches: a map of everywhere a reminder could
/// fire, and per-branch control over whether it does. Preferences are GLOBAL
/// per branch ("never that Walmart" holds for every future errand), keyed by
/// the engine's StoreID so the engine and this view always agree.
///
/// v2 (Task 2.9): cards show address + distance and sort nearest-first; map
/// pins and cards select each other; pinned/place-book branches are badged
/// and can be un-pinned; "Add a location" opens the search-and-pin sheet.
struct ErrandDetailView: View {
    @Environment(\.modelContext) private var context
    let errand: Errand
    @Query private var preferences: [StorePreference]
    @Query private var savedPlaces: [SavedPlace]
    @ObservedObject private var engine = LocationEngine.shared
    @State private var selectedKey: StoreID?
    @State private var showingAddLocation = false

    /// Auto + pinned + place-book branches, nearest first (original order
    /// when we do not know where the user is).
    private var branches: [CachedCandidate] {
        let effective = LocationEngine.effectiveBranches(for: errand, savedPlaces: savedPlaces)
        guard let here = engine.lastKnownLocation else { return effective }
        return effective.sorted { meters(to: $0, from: here) < meters(to: $1, from: here) }
    }

    var body: some View {
        ScrollViewReader { proxy in
            List {
                headerSection
                if branches.isEmpty {
                    Section {
                        Text("Locations not resolved yet — branches appear after the next location fix, or add one yourself with the search button above.")
                            .foregroundStyle(.secondary)
                    }
                } else {
                    mapSection
                    branchesSection
                }
            }
            .onChange(of: selectedKey) { _, newKey in
                guard let newKey else { return }
                withAnimation { proxy.scrollTo(newKey) }
            }
        }
        .navigationTitle(errand.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingAddLocation = true
                } label: {
                    Label("Add a location", systemImage: "plus.magnifyingglass")
                }
            }
        }
        .sheet(isPresented: $showingAddLocation) {
            AddLocationSheet(errand: errand)
        }
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
            Map(initialPosition: .automatic, selection: $selectedKey) {
                UserAnnotation()
                ForEach(branches, id: \.self) { candidate in
                    Marker(
                        candidate.name,
                        coordinate: CLLocationCoordinate2D(
                            latitude: candidate.lat, longitude: candidate.lon
                        )
                    )
                    .tint(tint(for: candidate))
                    .tag(LocationEngine.storeKey(for: candidate))
                }
            }
            .frame(height: 240)
            .listRowInsets(EdgeInsets())
        } footer: {
            Text("Blue = can remind you. Orange = pinned by you. Gray = excluded. Tap a pin to find its card below.")
        }
    }

    private var branchesSection: some View {
        Section("\(branches.count) matched branches") {
            ForEach(branches, id: \.self) { candidate in
                branchRow(candidate)
            }
        }
    }

    private func branchRow(_ candidate: CachedCandidate) -> some View {
        let key = LocationEngine.storeKey(for: candidate)
        let excluded = isExcluded(candidate)
        let pinned = pinnedKeys.contains(key)
        return VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Text(candidate.name)
                    .font(.headline)
                    .foregroundStyle(excluded ? .secondary : .primary)
                if pinned {
                    Image(systemName: "pin.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
            if let address = candidate.address {
                Text(address)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if let distance = distanceLabel(for: candidate) {
                Text("\(distance) away")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Toggle("Use this location", isOn: useBinding(for: candidate))
            Toggle("Remind when driving", isOn: drivingBinding(for: candidate))
                .disabled(excluded)
            Toggle("Remind when walking", isOn: walkingBinding(for: candidate))
                .disabled(excluded)
        }
        .id(key)
        .listRowBackground(selectedKey == key ? Color.accentColor.opacity(0.15) : nil)
        .contentShape(Rectangle())
        .onTapGesture { selectedKey = key }
        .swipeActions(edge: .trailing) {
            if pinned {
                Button(role: .destructive) {
                    unpin(candidate)
                } label: {
                    Label("Unpin", systemImage: "pin.slash")
                }
            } else if !excluded {
                Button(role: .destructive) {
                    setExcluded(candidate, true)
                } label: {
                    Label("Exclude", systemImage: "nosign")
                }
            }
        }
        .contextMenu {
            if pinned {
                Button(role: .destructive) {
                    unpin(candidate)
                } label: {
                    Label("Unpin this location", systemImage: "pin.slash")
                }
            } else if !excluded {
                Button(role: .destructive) {
                    setExcluded(candidate, true)
                } label: {
                    Label("Exclude this location", systemImage: "nosign")
                }
            }
        }
    }

    // MARK: - Distance & badges

    private func meters(to candidate: CachedCandidate, from location: CLLocation) -> CLLocationDistance {
        location.distance(from: CLLocation(latitude: candidate.lat, longitude: candidate.lon))
    }

    private func distanceLabel(for candidate: CachedCandidate) -> String? {
        guard let here = engine.lastKnownLocation else { return nil }
        let distance = meters(to: candidate, from: here)
        if distance < 1000 {
            return "\(Int(distance.rounded())) m"
        }
        return String(format: "%.1f km", distance / 1000)
    }

    /// Keys of branches the user attached by hand (pins) or via the place
    /// book (nickname match) — badged and un-pinnable rather than excludable.
    private var pinnedKeys: Set<StoreID> {
        var keys = Set(errand.pinned.map { LocationEngine.storeKey(for: $0) })
        for place in savedPlaces where errand.storePhrases.contains(where: {
            SavedPlaceMatcher.matches(nickname: place.nickname, phrase: $0)
        }) {
            keys.insert(LocationEngine.storeKey(for: place.asCandidate))
        }
        return keys
    }

    private func tint(for candidate: CachedCandidate) -> Color {
        if isExcluded(candidate) { return .gray }
        if pinnedKeys.contains(LocationEngine.storeKey(for: candidate)) { return .orange }
        return .blue
    }

    private func unpin(_ candidate: CachedCandidate) {
        let key = LocationEngine.storeKey(for: candidate)
        errand.pinned.removeAll { LocationEngine.storeKey(for: $0) == key }
        try? context.save()
        LocationEngine.shared.requestReplan()
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
