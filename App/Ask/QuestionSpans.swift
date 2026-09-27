import Foundation
import HeadroomCore
import SwiftUI

/// Where in the question one field was read from.
struct ReadSpan: Equatable {
    enum Field: Equatable { case item, price, date }
    let field: Field
    let range: Range<String.Index>
}

/// Finds the words of a question that became the item, price, and date on the Confirm sheet,
/// so the quote can underline them (docs/REDESIGN-SPEC.md 5.2). A field whose words cannot be
/// found exactly gets no span: the quote never guesses.
enum QuestionSpans {
    /// `parsed` is what `text` was read as, by the built-in parser or on-device AI, with the
    /// same `today` and `timeZone`. Spans come back in the order they appear and never overlap.
    static func find(in text: String, parsed: ParsedQuestion, today: Date, timeZone: TimeZone) -> [ReadSpan] {
        var spans: [ReadSpan] = []
        let money = QuestionParser.moneyRanges(in: text)

        // Price: the one amount in the question, when it is the price that was read.
        if money.count == 1, parsed.price != nil, let range = Range(money[0], in: text) {
            spans.append(ReadSpan(field: .price, range: range))
        }

        // Date: the detector's first phrase, found with every amount blanked out by the same
        // number of spaces so offsets still line up with the question. Underlined only when it
        // names the date that was read.
        let blanked = NSMutableString(string: text)
        for range in money {
            blanked.replaceCharacters(in: range, with: String(repeating: " ", count: range.length))
        }
        if let parsedDate = parsed.date, let match = QuestionParser.firstDate(in: blanked as String),
           LocalDate(match.date, timeZone: timeZone) == parsedDate, let range = Range(match.range, in: text) {
            spans.append(ReadSpan(field: .date, range: range))
        }

        // Item: each word as a whole word, ignoring case, outside the spans found so far.
        for word in (parsed.item ?? "").split(whereSeparator: \.isWhitespace) {
            var start = text.startIndex
            while let found = text.range(of: word, options: .caseInsensitive, range: start..<text.endIndex) {
                if isWholeWord(found, in: text), !spans.contains(where: { $0.range.overlaps(found) }) {
                    spans.append(ReadSpan(field: .item, range: found))
                    break
                }
                start = found.upperBound
            }
        }

        return spans.sorted { $0.range.lowerBound < $1.range.lowerBound }
    }

    /// The question in curly quotes, with each span dotted-underlined in Graphite.
    static func quote(_ text: String, spans: [ReadSpan]) -> AttributedString {
        var quote = AttributedString("\u{201C}")
        var cursor = text.startIndex
        for span in spans.sorted(by: { $0.range.lowerBound < $1.range.lowerBound }) where span.range.lowerBound >= cursor {
            quote += AttributedString(String(text[cursor..<span.range.lowerBound]))
            var read = AttributedString(String(text[span.range]))
            read.underlineStyle = Text.LineStyle(pattern: .dot, color: Theme.textSecondary)
            quote += read
            cursor = span.range.upperBound
        }
        quote += AttributedString(String(text[cursor...]) + "\u{201D}")
        return quote
    }

    /// No letter or digit touches either end of `range`.
    private static func isWholeWord(_ range: Range<String.Index>, in text: String) -> Bool {
        let before = range.lowerBound > text.startIndex ? text[text.index(before: range.lowerBound)] : nil
        let after = range.upperBound < text.endIndex ? text[range.upperBound] : nil
        return [before, after].allSatisfy { character in
            guard let character else { return true }
            return !character.isLetter && !character.isNumber
        }
    }
}
