import AppIntents
import ErrandKit
import Foundation
import SwiftData

/// The real voice entry point (Task 2.6): Back Tap / "Hey Siri, Errand" →
/// dictation → this intent. Parses, asks "Where from?" if no store was
/// named, persists, and kicks off candidate resolution — app never opens.
struct AddErrandIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Errand"
    static var description = IntentDescription(
        "Adds an errand and reminds you near matching stores."
    )
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Text")
    var text: String

    // Deliberately optional: filled by the "Where from?" follow-up only
    // when the dictated sentence named no store.
    @Parameter(title: "Store")
    var store: String?

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        // Gate H requirement: every raw dictated utterance is logged
        // verbatim, on-device only, before any parsing can mangle it.
        UtteranceLog.append(text)

        guard let parsed = try? UtteranceParser.parse(text) else {
            return .result(dialog: "I didn't catch that — try again.")
        }

        var stores = parsed.storePhrases
        if stores.isEmpty {
            let answer: String
            if let store {
                answer = store
            } else if let asked = try await $store.requestValue(
                IntentDialog("Where from?")
            ) as String? {
                answer = asked
            } else {
                answer = ""
            }
            UtteranceLog.append("\(answer) (follow-up answer)")
            stores = UtteranceParser.storePhrases(fromClause: answer)
        }

        let errand = Errand(title: parsed.title, storePhrases: stores)
        let context = AppDatabase.container.mainContext
        context.insert(errand)
        try? context.save()

        // Resolve branches + replant geofences in the background.
        LocationEngine.shared.requestReplan()

        let storeText = stores.isEmpty
            ? "no store — it won't remind you"
            : stores.joined(separator: ", ")
        return .result(dialog: "Added: \(parsed.title) — \(storeText)")
    }
}

/// Verbatim log of everything dictation handed us, newest first, on-device
/// only. This is what turns the Gate H field week into real parser test
/// cases (the parser's one-sentence-shape assumption is unproven).
enum UtteranceLog {
    static let key = "utterances.log"
    private static let maxEntries = 200

    static func append(_ utterance: String) {
        let stamp = Date().formatted(date: .abbreviated, time: .standard)
        var lines = load()
        lines.insert("\(stamp) — \(utterance)", at: 0)
        if lines.count > maxEntries {
            lines.removeLast(lines.count - maxEntries)
        }
        UserDefaults.standard.set(lines, forKey: key)
    }

    static func load() -> [String] {
        UserDefaults.standard.stringArray(forKey: key) ?? []
    }
}
