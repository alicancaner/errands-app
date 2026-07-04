import SwiftUI

/// Screen for the Shortcut → App Intent probe (Task 1.2, Gate E).
/// Lists texts received via AddTextIntent while the app was closed.
struct IntentLogView: View {
    @State private var lines: [String] = IntentTextStore.load()

    var body: some View {
        List {
            Section {
                if lines.isEmpty {
                    Text("Nothing received yet. Run the “Errand” shortcut, then come back here.")
                        .foregroundStyle(.secondary)
                }
                ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                    Text(line)
                        .font(.caption.monospaced())
                }
            } header: {
                Text("Received texts (newest first)")
            } footer: {
                Text("Each line should have arrived WITHOUT the app opening.")
            }
        }
        .navigationTitle("Intent Log")
        .refreshable { lines = IntentTextStore.load() }
        .onAppear { lines = IntentTextStore.load() }
    }
}

#Preview {
    NavigationStack {
        IntentLogView()
    }
}
