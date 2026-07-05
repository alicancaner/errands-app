import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            ErrandListView()
                .navigationTitle("Errands")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        NavigationLink {
                            DiagnosticsHomeView()
                        } label: {
                            Image(systemName: "wrench.adjustable")
                        }
                    }
                }
        }
    }
}

/// Tucked-away home for the Milestone 1 capability probes; Task 2.7 adds the
/// real diagnostics (planted regions map, event log) on top.
struct DiagnosticsHomeView: View {
    var body: some View {
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
                Text("Errands v0.3 — Milestone 2")
            }
        }
        .navigationTitle("Diagnostics")
    }
}

#Preview {
    ContentView()
}
