import Foundation
import HeadroomCore

enum ParseSource: Equatable, Sendable {
    case builtIn, onDeviceAI
}

/// What a question like "Can I buy a $700 laptop next Friday?" says. Any field can be
/// missing; the user always confirms before anything is calculated.
struct ParsedQuestion: Equatable, Sendable {
    var item: String?
    var price: Money?
    var date: LocalDate?
    var source: ParseSource
}

/// The built-in, deterministic question reader. No model, no network.
enum QuestionParser {
    /// "$700", "$1,249.99", "$ 45". A comma may follow as punctuation ("$130, maybe"), but
    /// nothing that would make the number mean something else: more digits ("$1,2",
    /// "$700.555") or a letter ("$2k", "$1.5K"). Those come back blank for the user to type.
    private static let moneyPattern = try! NSRegularExpression(
        pattern: #"\$\s?(?:\d{1,3}(?:,\d{3})+|\d+)(?:\.\d{1,2})?(?!\d)(?!,\d)(?!\.\d)(?![A-Za-z])"#)
    private static let dateDetector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue)

    private static let fillerWords: Set<String> = [
        "a", "about", "afford", "an", "and", "at", "be", "buy", "by", "can", "could", "do", "does",
        "fine", "for", "get", "grab", "how", "i", "if", "is", "it", "me", "my", "ok", "okay", "on",
        "pay", "purchase", "should", "spend", "that", "the", "this", "to", "we", "what", "would",
    ]

    /// Every dollar amount written with a "$", as typed (e.g. "$1,249.99").
    static func moneyTokens(in text: String) -> [String] {
        let range = NSRange(text.startIndex..., in: text)
        return moneyPattern.matches(in: text, range: range).compactMap { Range($0.range, in: text).map { String(text[$0]) } }
    }

    /// Where each dollar amount sits in `text`, in UTF-16 units, in the order they appear.
    static func moneyRanges(in text: String) -> [NSRange] {
        moneyPattern.matches(in: text, range: NSRange(text.startIndex..., in: text)).map(\.range)
    }

    /// The first date phrase in `text` and the moment it names, as the system's date detector reads it.
    static func firstDate(in text: String) -> (range: NSRange, date: Date)? {
        let range = NSRange(text.startIndex..., in: text)
        guard let match = dateDetector.firstMatch(in: text, range: range), let date = match.date else { return nil }
        return (match.range, date)
    }

    /// The amounts in `text` that parse and are within the $10,000,000 cap.
    static func prices(in text: String) -> [Money] {
        moneyTokens(in: text).compactMap(amount(ofToken:))
    }

    /// The first date phrase in `text`, resolved relative to now by the system's date detector.
    static func date(in text: String, today: Date, timeZone: TimeZone) -> LocalDate? {
        let range = NSRange(text.startIndex..., in: text)
        guard let match = dateDetector.firstMatch(in: text, range: range), let date = match.date else { return nil }
        return LocalDate(date, timeZone: timeZone)
    }

    static func parse(_ text: String, today: Date, timeZone: TimeZone) -> ParsedQuestion {
        let tokens = moneyTokens(in: text)
        // Exactly one amount, or the user fills it in. Never guess between two.
        let price = tokens.count == 1 ? amount(ofToken: tokens[0]) : nil

        var rest = text
        for token in tokens { rest = rest.replacingOccurrences(of: token, with: " ") }

        var date = LocalDate(today, timeZone: timeZone)
        let range = NSRange(rest.startIndex..., in: rest)
        if let match = dateDetector.firstMatch(in: rest, range: range), let found = match.date,
           let phrase = Range(match.range, in: rest) {
            date = LocalDate(found, timeZone: timeZone)
            rest.replaceSubrange(phrase, with: " ")
        }

        return ParsedQuestion(item: item(in: rest), price: price, date: date, source: .builtIn)
    }

    private static func amount(ofToken token: String) -> Money? {
        MoneyInput.parse(token.replacingOccurrences(of: " ", with: ""))
    }

    private static func item(in text: String) -> String? {
        let words = text
            .components(separatedBy: CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "'-")).inverted)
            .filter { !$0.isEmpty }
            .filter { !fillerWords.contains($0.lowercased()) }
        guard !words.isEmpty else { return nil }
        return words.joined(separator: " ").lowercased()
    }
}
