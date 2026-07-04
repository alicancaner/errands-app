import CoreMotion
import SwiftUI

/// Motion-activity probe (Task 1.3, Gate F): are walking/driving/stationary
/// states (and confidence) sane on this phone?
final class MotionProbe: ObservableObject {
    @Published private(set) var state = "not started"
    @Published private(set) var confidence = "—"
    @Published private(set) var permission = "unknown"
    @Published private(set) var isRunning = false

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
        }
        .navigationTitle("Motion Probe")
    }
}

#Preview {
    NavigationStack {
        MotionProbeView()
    }
}
