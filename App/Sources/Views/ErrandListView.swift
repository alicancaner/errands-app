import ErrandKit
import SwiftData
import SwiftUI

/// The main screen: open errands, done errands, and (until the voice flow
/// lands in Task 2.6) a temporary text field for adding one by typing.
struct ErrandListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Errand.createdAt, order: .reverse) private var errands: [Errand]
    @State private var draft = ""

    private var open: [Errand] { errands.filter { !$0.isCompleted } }
    private var done: [Errand] { errands.filter(\.isCompleted) }

    var body: some View {
        List {
            Section {
                TextField("buy lentils from walmart", text: $draft)
                    .submitLabel(.done)
                    .onSubmit(addFromDraft)
            } header: {
                Text("Add errand (typing is temporary — voice comes next)")
            }

            Section("To do") {
                if open.isEmpty {
                    Text("Nothing to do 🎉")
                        .foregroundStyle(.secondary)
                }
                ForEach(open) { errand in
                    NavigationLink {
                        ErrandDetailView(errand: errand)
                    } label: {
                        ErrandRow(errand: errand)
                    }
                        .swipeActions(edge: .leading) {
                            Button {
                                errand.completedAt = .now
                                LocationEngine.shared.requestReplan()
                            } label: {
                                Label("Done", systemImage: "checkmark")
                            }
                            .tint(.green)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                context.delete(errand)
                                LocationEngine.shared.requestReplan()
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }

            if !done.isEmpty {
                Section("Done") {
                    ForEach(done) { errand in
                        NavigationLink {
                            ErrandDetailView(errand: errand)
                        } label: {
                            ErrandRow(errand: errand)
                        }
                            .foregroundStyle(.secondary)
                            .swipeActions(edge: .leading) {
                                Button {
                                    errand.completedAt = nil
                                    LocationEngine.shared.requestReplan()
                                } label: {
                                    Label("Undo", systemImage: "arrow.uturn.backward")
                                }
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    context.delete(errand)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
            }
        }
    }

    private func addFromDraft() {
        guard let parsed = try? UtteranceParser.parse(draft) else { return }
        context.insert(Errand(title: parsed.title, storePhrases: parsed.storePhrases))
        draft = ""
        // New errand needs branches resolved and regions replanted.
        LocationEngine.shared.requestReplan()
    }
}

private struct ErrandRow: View {
    let errand: Errand

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(errand.title)
                .strikethrough(errand.isCompleted)
            if !errand.storePhrases.isEmpty {
                Text(errand.storePhrases.joined(separator: " · "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
