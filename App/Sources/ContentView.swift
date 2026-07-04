import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "checklist")
                .font(.largeTitle)
            Text("Errands v0.1 — pipeline works")
                .font(.headline)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
