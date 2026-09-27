import Foundation
import HeadroomCore
import SwiftUI
import Testing
@testable import Headroom

/// The words of a question that were read into each field, underlined on the Confirm sheet
/// (docs/REDESIGN-SPEC.md 5.2 and section 10, step 10). Anything not found stays plain.
@Suite("QuestionSpans")
struct QuestionSpansTests {
    let now = Date()
    var today: LocalDate { LocalDate(now) }

    func find(_ text: String, parsed: ParsedQuestion? = nil) -> [ReadSpan] {
        let parsed = parsed ?? QuestionParser.parse(text, today: now, timeZone: .current)
        return QuestionSpans.find(in: text, parsed: parsed, today: now, timeZone: .current)
    }

    /// The underlined words for one field, in the order they appear.
    func words(_ field: ReadSpan.Field, in text: String, parsed: ParsedQuestion? = nil) -> [String] {
        find(text, parsed: parsed).filter { $0.field == field }.map { String(text[$0.range]) }
    }

    @Test("the example question underlines the price, the item, and the date")
    func example() {
        let text = "Can I buy a $700 laptop next Friday?"
        let spans = find(text)
        #expect(spans.map { String(text[$0.range]) } == ["$700", "laptop", "next Friday"])
        #expect(spans.map(\.field) == [.price, .item, .date])
    }

    @Test("two amounts give no price span, and the item is still found")
    func twoAmounts() {
        let text = "a $700 laptop and a $50 case"
        #expect(words(.price, in: text).isEmpty)
        #expect(words(.item, in: text) == ["laptop", "case"])
    }

    @Test("an amount the parser could not use gives no price span")
    func unusableAmount() {
        let text = "a $99999999999999999 yacht"
        #expect(words(.price, in: text).isEmpty)
    }

    @Test("a price written with a space keeps its whole token")
    func spacedPrice() {
        #expect(words(.price, in: "is $ 45 ok for shoes") == ["$ 45"])
    }

    @Test("item words match without regard to case, one span per word")
    func itemCase() {
        let text = "Can I buy a $120 Laptop Stand tomorrow"
        #expect(words(.item, in: text) == ["Laptop", "Stand"])
        #expect(words(.date, in: text) == ["tomorrow"])
    }

    @Test("an item word is only matched as a whole word")
    func wholeWords() {
        let text = "Can I get a $30 laptop top?"
        let parsed = ParsedQuestion(item: "top", price: .dollars(30), date: today, source: .onDeviceAI)
        let spans = find(text, parsed: parsed).filter { $0.field == .item }
        #expect(spans.count == 1)
        #expect(spans.first.map { text.distance(from: text.startIndex, to: $0.range.lowerBound) } == 23)
    }

    @Test("an item that is not in the question gets no underline")
    func itemNotFound() {
        let parsed = ParsedQuestion(item: "macbook", price: .dollars(700), date: today, source: .onDeviceAI)
        #expect(words(.item, in: "Can I buy a $700 laptop?", parsed: parsed).isEmpty)
    }

    @Test("no date phrase means no date span")
    func noDate() {
        let text = "Can I buy a $700 laptop?"
        #expect(words(.date, in: text).isEmpty)
        #expect(find(text).map(\.field) == [.price, .item])
    }

    @Test("a date phrase that was not what the field was read as stays plain")
    func dateMismatch() {
        let parsed = ParsedQuestion(item: "jacket", price: .dollars(45), date: today, source: .onDeviceAI)
        #expect(words(.date, in: "Can I buy a $45 jacket tomorrow?", parsed: parsed).isEmpty)
    }

    @Test("ranges stay aligned after accented letters and emoji")
    func nonASCII() {
        let text = "\u{1F3A7} a $120 caf\u{E9} headset tomorrow"
        #expect(words(.price, in: text) == ["$120"])
        #expect(words(.item, in: text) == ["caf\u{E9}", "headset"])
        #expect(words(.date, in: text) == ["tomorrow"])
    }

    @Test("an empty item and no price leave only what was found")
    func nothingRead() {
        let parsed = ParsedQuestion(item: nil, price: nil, date: today, source: .builtIn)
        #expect(find("hello there", parsed: parsed).isEmpty)
    }

    @Test("the quote sits in curly quotes, with only the read words underlined")
    func quote() {
        let text = "Can I buy a $700 laptop next Friday?"
        let quote = QuestionSpans.quote(text, spans: find(text))
        #expect(String(quote.characters) == "\u{201C}\(text)\u{201D}")
        let underlined = quote.runs.filter { $0.underlineStyle != nil }.map { String(quote[$0.range].characters) }
        #expect(underlined == ["$700", "laptop", "next Friday"])
    }
}
