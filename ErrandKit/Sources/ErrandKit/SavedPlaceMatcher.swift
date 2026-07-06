import Foundation

/// Decides whether a saved place's nickname is mentioned by a store phrase —
/// the "place book pays off" rule: any significant word of the nickname
/// appearing as a whole word in the phrase counts as a mention.
public enum SavedPlaceMatcher {

    /// Words shorter than this never anchor a match ("s", "in", "a").
    static let minWordLength = 3

    /// True when `phrase` mentions `nickname` (whole-word, case-insensitive).
    public static func matches(nickname: String, phrase: String) -> Bool {
        let nicknameWords = significantWords(of: nickname)
        guard !nicknameWords.isEmpty else { return false }
        let phraseWords = Set(significantWords(of: phrase))
        return nicknameWords.contains { phraseWords.contains($0) }
    }

    /// Lowercased alphanumeric words of length >= minWordLength.
    static func significantWords(of text: String) -> [String] {
        text.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.count >= minWordLength }
    }
}
