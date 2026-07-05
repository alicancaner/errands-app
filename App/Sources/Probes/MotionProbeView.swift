import CoreMotion
import SwiftUI

/// Motion-activity probe (Task 1.3, Gate F): are walking/driving/stationary
/// states (and confidence) sane on this phone?
final class MotionProbe: ObservableObject {
    @Published private(set) var state = "not started"
    @Published private(set) var confidence = "—"
    @Published private(set) var permission = "unknown"
    @Published private(set) var isRunning = false
    @Published private(set) var history: [String] = []

    private let manager = CMMotionActivityManager()

    func start() {
        guard CMMotionActivityManager.isActivityAvailable() else {
            state = "Motion activity NOT available on this device"
            return
        }
        isRunning = true
        updatePermissionText()
        // First call triggers the Motion & Fitness permission popup.
        manager.startActivityUpdates(to: .main) { [weak self] activity in
            guard let self, let activity else { return }
            self.state = Self.describe(activity)
            self.confidence = Self.describe(activity.confidence)
            self.updatePermissionText()
        }
    }

    func stop() {
        manager.stopActivityUpdates()
        isRunning = false
        state = "stopped"
        confidence = "—"
    }

    /// The motion coprocessor records activity ~24/7 regardless of apps;
    /// query the last hour so a walk can be reviewed after the fact.
    func queryLastHour() {
        guard CMMotionActivityManager.isActivityAvailable() else { return }
        history = ["querying…"]
        let now = Date()
        manager.queryActivityStarting(from: now.addingTimeInterval(-3600), to: now, to: .main) { [weak self] activities, error in
            guard let self else { return }
            self.updatePermissionText()
            if let error {
                self.history = ["query failed: \(error.localizedDescription)"]
                return
            }
            guard let activities, !activities.isEmpty else {
                self.history = ["no recorded activity in the last hour"]
                return
            }
            let formatter = Date.FormatStyle(date: .omitted, time: .standard)
            var lines: [String] = []
            var lastLabel = ""
            for activity in activities {
                let label = Self.describe(activity)
                guard label != lastLabel else { continue }  // collapse repeats
                lastLabel = label
                lines.append("\(activity.startDate.formatted(formatter))  \(label) (\(Self.describe(activity.confidence)))")
            }
            self.history = lines.suffix(50).reversed()
        }
    }

    private func updatePermissionText() {
        switch CMMotionActivityManager.authorizationStatus() {
        case .notDetermined: permission = "not asked yet"
        case .restricted: permission = "restricted"
        case .denied: permission = "DENIED — Settings > Privacy > Motion & Fitness"
        case .authorized: permission = "Allowed ✓"
        @unknown default: permission = "unknown"
        }
    }

    private static func describe(_ activity: CMMotionActivity) -> String {
        var parts: [String] = []
        if activity.walking { parts.append("walking") }
        if activity.running { parts.append("running") }
        if activity.cycling { parts.append("cycling") }
        if activity.automotive { parts.append("driving") }
        if activity.stationary { parts.append("stationary") }
        if activity.unknown { parts.append("unknown") }
        return parts.isEmpty ? "(none)" : parts.joined(separator: " + ")
    }

    private static func describe(_ confidence: CMMotionActivityConfidence) -> String {
        switch confidence {
        case .low: return "low"
        case .medium: return "medium"
        case .high: return "high"
        @unknown default: return "?"
        }
    }
}

struct MotionProbeView: View {
    @StateObject private var probe = MotionProbe()

    var body: some View {
        List {
            Section("Motion & Fitness") {
                Button(probe.isRunning ? "Stop" : "Start motion updates") {
                    probe.isRunning ? probe.stop() : probe.start()
                }
                LabeledContent("Permission", value: probe.permission)
            }
            Section("Live state") {
                LabeledContent("Activity", value: probe.state)
                LabeledContent("Confidence", value: probe.confidence)
            }
            Section {
                Button("Show last hour's history") {
                    probe.queryLastHour()
                }
                ForEach(Array(probe.history.enumerated()), id: \.offset) { _, line in
                    Text(line)
                        .font(.caption.monospaced())
                }
            } header: {
                Text("Recorded history (newest first)")
            } footer: {
                Text("The phone records this even while the app is closed — walk first, check afterwards.")
            }
        }
        .navigationTitle("Motion Probe")
    }
}

#Preview {
    NavigationStack {
        MotionProbeView()
    }
}
