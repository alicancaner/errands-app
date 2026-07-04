import AppIntents
import Foundation

/// App Intent probe (Task 1.2, Gate E): receives text from the Shortcuts app
/// without opening the app, and appends it to a local store.
struct AddTextIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Text"
    static var description = IntentDescription("Stores a line of text in Errands (probe).")

    // The whole point of the probe: the app must NOT come to the foreground.
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Text")
    var text: String

    func perform() async throws -> some IntentResult {
        IntentTextStore.append(text)
        return .result()
    }
}

/// UserDefaults-backed store, newest first. Fine for the probe; the real app
/// will use SwiftData.
enum IntentTextStore {
    static let key = "intent.receivedTexts"

    static func append(_ text: String) {
        let stamp = Date().formatted(date: .abbreviated, time: .standard)
        var lines = load()
        lines.insert("\(stamp) — \(text)", at: 0)
        UserDefaults.standard.set(lines, forKey: key)
    }

    static func load() -> [String] {
        UserDefaults.standard.stringArray(forKey: key) ?? []
    }
}
