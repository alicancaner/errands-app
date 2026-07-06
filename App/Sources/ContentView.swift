import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            ErrandListView()
                .navigationTitle("Errands")
                .toolbar {
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        NavigationLink {
                            SavedPlacesView()
                        } label: {
                            Image(systemName: "bookmark")
                        }
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
