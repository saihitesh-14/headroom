import Foundation
import HeadroomCore
import Testing
@testable import Headroom

/// A stand-in for the on-device model that returns fixed phrases, or fails.
struct StubInterpreter: QuestionInterpreter {
    var phrases = InterpretedPhrases(item: "", dateText: nil)
    var fails = false

    func interpret(_ text: String) async throws -> InterpretedPhrases {
        if fails { throw CancellationError() }
        return phrases
    }
}

@Suite("AIReader")
struct AIReaderTests {
    let now = Date()

    func read(_ text: String, _ stub: StubInterpreter) async -> AIReadResult {
        await AIReader.read(text, interpreter: stub, today: now, timeZone: .current)
    }

    @Test("the price always comes from the typed digits, whatever the model says")
    func priceFromDigits() async {
        let stub = StubInterpreter(phrases: InterpretedPhrases(item: "laptop", dateText: "next Friday"))
        let result = await read("Can I buy a $700 laptop next Friday?", stub)
        #expect(result.parsed.price == .dollars(700))
        #expect(result.parsed.item == "laptop")
        #expect(result.parsed.source == .onDeviceAI)
        #expect(result.note == nil)
    }

    @Test("a date phrase that is not in the question is ignored")
    func dateMustBeInSentence() async {
        let text = "Can I buy a $45 jacket next Friday?"
        let stub = StubInterpreter(phrases: InterpretedPhrases(item: "jacket", dateText: "tomorrow"))
        let result = await read(text, stub)
        #expect(result.parsed.date == QuestionParser.parse(text, today: now, timeZone: .current).date)
        #expect(result.parsed.date != LocalDate(now).adding(days: 1))
    }

    @Test("a date phrase from the question is used")
    func dateFromSentence() async {
        let stub = StubInterpreter(phrases: InterpretedPhrases(item: "jacket", dateText: "tomorrow"))
        let result = await read("thinking about a $45 jacket, maybe tomorrow", stub)
        #expect(result.parsed.date == LocalDate(now).adding(days: 1))
    }

    @Test("an item that is not in the question is ignored")
    func itemMustBeInSentence() async {
        let stub = StubInterpreter(phrases: InterpretedPhrases(item: "MacBook Pro", dateText: nil))
        let result = await read("Can I buy a $700 laptop?", stub)
        #expect(result.parsed.item == "laptop")
    }

    @Test("the model's item is used when it comes from the question")
    func itemFromSentence() async {
        let stub = StubInterpreter(phrases: InterpretedPhrases(item: "Running Shoes", dateText: nil))
        let result = await read("thinking I might grab running shoes, $120", stub)
        #expect(result.parsed.item == "running shoes")
    }

    @Test("a model error falls back to the built-in parser, with a note")
    func fallbackOnError() async {
        let text = "Can I buy a $700 laptop next Friday?"
        let result = await read(text, StubInterpreter(fails: true))
        #expect(result.parsed == QuestionParser.parse(text, today: now, timeZone: .current))
        #expect(result.parsed.source == .builtIn)
        #expect(result.note == "Read without on-device AI this time. Look over each field.")
    }
}
