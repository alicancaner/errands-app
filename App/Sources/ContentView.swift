import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            ErrandListView()
                .navigationTitle("Errands")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        NavigationLink {
                            DiagnosticsView()
                        } label: {
                            Image(systemName: "wrench.adjustable")
                        }
                    }
                }
        }
    }
}

#Preview {
    ContentView()
}
