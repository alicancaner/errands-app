import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink("Geofence Probe") {
                        GeofenceProbeView()
                    }
                } header: {
                    Text("Capability probes")
                } footer: {
                    Text("Errands v0.2 — Milestone 1 probes")
                }
            }
            .navigationTitle("Errands")
        }
    }
}

#Preview {
    ContentView()
}
