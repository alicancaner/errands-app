import CoreLocation
import CoreMotion
import ErrandKit
import MapKit
import SwiftData
import SwiftUI
import UserNotifications

/// The debugging lifeline for field failures (DESIGN.md §7): shows exactly
/// which tripwires are planted, what the engine did and why, permission
/// states, cache freshness, and every raw dictated utterance.
struct DiagnosticsView: View {
    @ObservedObject private var engine = LocationEngine.shared
    @Query(sort: \Errand.createdAt, order: .reverse) private var errands: [Errand]
    @State private var locationStatus = "checking…"
    @State private var notificationStatus = "checking…"
    @State private var motionStatus = "checking…"

    private var regions: [MonitoredRegionInfo] { engine.plantedRegions() }

    var body: some View {
        List {
            mapSection
            regionsSection
            permissionsSection
            cachesSection
            eventsSection
            utterancesSection
            probesSection
        }
        .navigationTitle("Diagnostics")
        .task { await loadPermissionStatuses() }
    }

    // MARK: - Sections

    private var mapSection: some View {
        Section("Planted tripwires") {
            Map(initialPosition: .automatic) {
                UserAnnotation()
                ForEach(regions) { info in
                    MapCircle(center: info.center, radius: info.radius)
                        .foregroundStyle(color(for: info.ring).opacity(0.15))
                        .stroke(color(for: info.ring), lineWidth: 2)
                    if info.ring == .outer {
                        Marker(info.storeName, coordinate: info.center)
                            .tint(color(for: info.ring))
                    }
                }
            }
            .frame(height: 280)
            .listRowInsets(EdgeInsets())

            Button("Replan now") {
                engine.requestReplan()
            }
        }
    }

    private var regionsSection: some View {
        Section("\(regions.count) of 20 region slots used") {
            if regions.isEmpty {
                Text("No tripwires planted (no open errands with resolved stores, or no location fix yet)")
                    .foregroundStyle(.secondary)
            }
            ForEach(regions) { info in
                HStack {
                    Circle()
                        .fill(color(for: info.ring))
                        .frame(width: 10, height: 10)
                    Text(info.storeName)
                    Spacer()
                    Text(info.ring == .outer ? "outer · \(Int(info.radius)) m" : "inner · \(Int(info.radius)) m")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var permissionsSection: some View {
        Section("Permissions") {
            LabeledContent("Location", value: locationStatus)
            LabeledContent("Notifications", value: notificationStatus)
            LabeledContent("Motion & Fitness", value: motionStatus)
        }
    }

    private var cachesSection: some View {
        Section("Store caches (open errands)") {
            let open = errands.filter { !$0.isCompleted }
            if open.isEmpty {
                Text("No open errands").foregroundStyle(.secondary)
            }
            ForEach(open) { errand in
                VStack(alignment: .leading, spacing: 2) {
                    Text(errand.title)
                    Text(cacheSummary(for: errand))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var eventsSection: some View {
        Section("Engine log (newest first)") {
            if engine.events.isEmpty {
                Text("No events yet").foregroundStyle(.secondary)
            }
            ForEach(engine.events, id: \.self) { line in
                Text(line).font(.caption.monospaced())
            }
        }
    }

    private var utterancesSection: some View {
        Section {
            let utterances = UtteranceLog.load()
            if utterances.isEmpty {
                Text("No voice adds yet").foregroundStyle(.secondary)
            }
            ForEach(utterances, id: \.self) { line in
                Text(line).font(.caption)
            }
        } header: {
            Text("Raw dictated utterances (verbatim)")
        } footer: {
            Text("Stays on this phone. Used to check the sentence parser against how you actually talk.")
        }
    }

    private var probesSection: some View {
        Section {
            NavigationLink("Geofence Probe") { GeofenceProbeView() }
            NavigationLink("Intent Log") { IntentLogView() }
            NavigationLink("Search Probe") { SearchProbeView() }
            NavigationLink("Motion Probe") { MotionProbeView() }
        } header: {
            Text("Capability probes (Milestone 1)")
        } footer: {
            Text("Errands v0.3 — Milestone 2")
        }
    }

    // MARK: - Helpers

    private func color(for ring: RingKind) -> Color {
        ring == .outer ? .blue : .orange
    }

    private func cacheSummary(for errand: Errand) -> String {
        guard !errand.storePhrases.isEmpty else { return "no store tagged" }
        guard let expires = errand.candidatesExpireAt else { return "not resolved yet" }
        let names = errand.candidates.prefix(3).map(\.name).joined(separator: ", ")
        let expiry = expires.formatted(.relative(presentation: .named))
        let extra = errand.candidates.count > 3 ? " +\(errand.candidates.count - 3) more" : ""
        return "\(errand.candidates.count) branches (\(names)\(extra)) — cache expires \(expiry)"
    }

    private func loadPermissionStatuses() async {
        locationStatus = describe(CLLocationManager().authorizationStatus)
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        notificationStatus = settings.authorizationStatus == .authorized ? "Allowed ✓" : "NOT allowed"
        motionStatus = describe(CMMotionActivityManager.authorizationStatus())
    }

    private func describe(_ status: CLAuthorizationStatus) -> String {
        switch status {
        case .notDetermined: return "not asked yet"
        case .restricted: return "restricted"
        case .denied: return "DENIED"
        case .authorizedWhenInUse: return "While Using (need Always)"
        case .authorizedAlways: return "Always ✓"
        @unknown default: return "unknown"
        }
    }

    private func describe(_ status: CMAuthorizationStatus) -> String {
        switch status {
        case .notDetermined: return "not asked yet"
        case .restricted: return "restricted"
        case .denied: return "DENIED"
        case .authorized: return "Allowed ✓"
        @unknown default: return "unknown"
        }
    }
}
