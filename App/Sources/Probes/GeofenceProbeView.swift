import SwiftUI

/// Screen for the background-geofencing probe (Task 1.1, Gate D).
struct GeofenceProbeView: View {
    @ObservedObject private var probe = GeofenceProbe.shared

    var body: some View {
        List {
            Section("1. Permissions") {
                Button("Request Always permission") {
                    probe.requestLocationPermission()
                }
                LabeledContent("Location", value: probe.authDescription)
                Button("Request notification permission") {
                    probe.requestNotificationPermission()
                }
                LabeledContent("Notifications", value: notificationStatusText)
            }

            Section("2. Tripwire") {
                Button("Plant tripwire here (300 m)") {
                    probe.plantTripwireHere()
                }
                if let plantedAt = probe.plantedAt {
                    LabeledContent("Planted", value: plantedAt.formatted(date: .abbreviated, time: .shortened))
                }
            }

            Section("Event log (last 20)") {
                if probe.events.isEmpty {
                    Text("No events yet").foregroundStyle(.secondary)
                }
                ForEach(Array(probe.events.enumerated()), id: \.offset) { _, line in
                    Text(line)
                        .font(.caption.monospaced())
                }
            }
        }
        .navigationTitle("Geofence Probe")
    }

    private var notificationStatusText: String {
        switch probe.notificationsGranted {
        case .some(true): return "Allowed ✓"
        case .some(false): return "NOT allowed"
        case .none: return "not requested"
        }
    }
}

#Preview {
    NavigationStack {
        GeofenceProbeView()
    }
}
