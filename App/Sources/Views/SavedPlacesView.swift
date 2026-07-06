import SwiftData
import SwiftUI

/// The global place book: every place the user has pinned and nicknamed.
/// Rename to change what future errands match; delete to stop future
/// auto-attaching (errands where the place is already pinned keep it).
struct SavedPlacesView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \SavedPlace.nickname) private var places: [SavedPlace]

    @State private var renaming: SavedPlace?
    @State private var newNickname = ""

    var body: some View {
        List {
            if places.isEmpty {
                Text("No saved places yet. Pin one from any errand's Add a location.")
                    .foregroundStyle(.secondary)
            } else {
                Section {
                    ForEach(places) { place in
                        Button {
                            renaming = place
                            newNickname = place.nickname
                        } label: {
                            placeRow(place)
                        }
                        .foregroundStyle(.primary)
                    }
                    .onDelete(perform: delete)
                } footer: {
                    Text("Tap a place to rename it. Deleting stops it from attaching to future errands — errands where it is already pinned keep it.")
                }
            }
        }
        .navigationTitle("Saved places")
        .alert("Rename this place", isPresented: isRenaming) {
            TextField("Nickname", text: $newNickname)
            Button("Save") { rename() }
            Button("Cancel", role: .cancel) { renaming = nil }
        }
    }

    private func placeRow(_ place: SavedPlace) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(place.nickname)
                .font(.headline)
            Text([place.name, place.address].compactMap { $0 }.joined(separator: " · "))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var isRenaming: Binding<Bool> {
        Binding(
            get: { renaming != nil },
            set: { if !$0 { renaming = nil } }
        )
    }

    private func rename() {
        guard let place = renaming else { return }
        let trimmed = newNickname.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            place.nickname = trimmed
            try? context.save()
            LocationEngine.shared.requestReplan()
        }
        renaming = nil
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            context.delete(places[index])
        }
        try? context.save()
        LocationEngine.shared.requestReplan()
    }
}
