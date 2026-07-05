import Foundation

/// Result of parsing a spoken errand like "buy lentils from walmart".
public struct ParsedErrand: Equatable, Sendable {
    public let title: String
    public let storePhrases: [String]

    public init(title: String, storePhrases: [String]) {
        self.title = title
        self.storePhrases = storePhrases
    }
}

public enum ParseError: Error, Equatable {
    case empty
}

/// Splits a dictated utterance into an errand title and store phrases.
public enum UtteranceParser {

    /// Parses an utterance such as "buy lentils from walmart or city market".
    ///
    /// Only the LAST "from"/"at" clause is treated as the store clause, so
    /// store names inside the title survive ("buy a walmart gift card from
    /// target"). Articles are preserved in store phrases ("the persian
    /// market") because they matter for fuzzy map search.
    ///
    /// - Parameter utterance: raw dictated text.
    /// - Returns: `ParsedErrand` with title and 0+ store phrases.
    /// - Throws: `ParseError.empty` for empty/whitespace input.
    public static func parse(_ utterance: String) throws -> ParsedErrand {
        let trimmed = utterance.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw ParseError.empty }

        // Reason: search backwards so only the last from/at clause splits —
        // earlier occurrences belong to the title.
        var splitRange: Range<String.Index>?
        for keyword in [" from ", " at "] {
            if let r = trimmed.range(of: keyword, options: [.backwards, .caseInsensitive]) {
                if splitRange == nil || r.lowerBound > splitRange!.lowerBound {
                    splitRange = r
                }
            }
        }

        guard let r = splitRange else {
            return ParsedErrand(title: trimmed, storePhrases: [])
        }

        let title = trimmed[..<r.lowerBound].trimmingCharacters(in: .whitespaces)
        let stores = splitStores(String(trimmed[r.upperBound...]))
        return ParsedErrand(title: title, storePhrases: stores)
    }

    /// Splits a store clause on commas / "or" / "and" into trimmed phrases.
    private static func splitStores(_ clause: String) -> [String] {
        clause
            .components(separatedBy: ",")
            .flatMap { $0.components(separatedBy: " or ") }
            .flatMap { $0.components(separatedBy: " and ") }
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }
}
