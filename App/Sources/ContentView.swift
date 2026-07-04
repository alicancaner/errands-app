import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink("Geofence Probe") {
                        GeofenceProbeView()
                    }
                    NavigationLink("Intent Log") {
                        IntentLogView()
                    }
                    NavigationLink("Search Probe") {
                        SearchProbeView()
                    }
                    NavigationLink("Motion Probe") {
                        MotionProbeView()
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
