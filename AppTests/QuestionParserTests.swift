import Foundation
import HeadroomCore
import Testing
@testable import Headroom

@Suite("QuestionParser")
struct QuestionParserTests {
    let now = Date()
    var today: LocalDate { LocalDate(now) }

    func parse(_ text: String) -> ParsedQuestion {
        QuestionParser.parse(text, today: now, timeZone: .current)
    }

    @Test("reads the example question")
    func example() {
        let q = parse("Can I buy a $700 laptop next Friday?")
        #expect(q.price == .dollars(700))
        #expect(q.item == "laptop")
        #expect(q.source == .builtIn)
        guard let date = q.date else {
            Issue.record("expected a date")
            return
        }
        #expect(date.weekday == 6)
        #expect((1...13).contains(today.days(until: date)))
    }

    @Test("prices with commas and cents", arguments: [
        ("what if I get $1,249.99 headphones", 124_999),
        ("Can I get a jacket for $700.", 70_000),
        ("is $ 45 ok for shoes", 4_500),
        ("buy a $0.99 app", 99),
        ("new winter jacket, $130, maybe in two weeks", 13_000),
        ("a $1,249.99, or cheaper?", 124_999),
    ])
    func prices(text: String, cents: Int) {
        #expect(parse(text).price == Money(cents: cents))
    }

    @Test("no price when it is ambiguous or not a dollar amount", arguments: [
        "Can I buy a laptop for 1249",
        "a $700 laptop and a $50 case",
        "a $99999999999999999 yacht",
        "Can I buy a laptop?",
        "a $2k laptop",
        "a $5K bike",
        "is $1.5k too much for a couch",
        "a $700.555 phone",
    ])
    func noPrice(text: String) {
        #expect(parse(text).price == nil)
    }

    @Test("no date phrase means today")
    func defaultsToToday() {
        #expect(parse("Can I buy a $700 laptop?").date == today)
    }

    @Test("tomorrow is the next calendar day")
    func tomorrow() {
        #expect(parse("can i get a $45 jacket tomorrow").date == today.adding(days: 1))
    }

    @Test("item is what is left after the filler words", arguments: [
        ("Can I buy a $700 laptop next Friday?", "laptop"),
        ("what if I get $1,249.99 headphones on Oct 15", "headphones"),
        ("can i get a $45 jacket tomorrow", "jacket"),
        ("Should I buy new running shoes for $120", "new running shoes"),
        ("$20", nil),
    ])
    func items(text: String, item: String?) {
        #expect(parse(text).item == item)
    }
}

@Suite("PurchaseDraft")
struct PurchaseDraftTests {
    let today = LocalDate(year: 2026, month: 9, day: 26)!
    let tz = TimeZone(identifier: "America/Phoenix")!

    @Test("a fully parsed question becomes a purchase")
    func fromParsed() {
        let parsed = ParsedQuestion(item: "laptop", price: .dollars(700),
                                    date: LocalDate(year: 2026, month: 10, day: 2), source: .builtIn)
        let draft = PurchaseDraft(parsed: parsed, today: today, timeZone: tz)
        #expect(draft.priceText == "700")
        #expect(draft.errors(today: today, timeZone: tz).isEmpty)
        #expect(draft.makePurchase(today: today, timeZone: tz)
                == Purchase(item: "laptop", price: .dollars(700), date: LocalDate(year: 2026, month: 10, day: 2)!))
    }

    @Test("a missing price must be filled in; an empty item is fine")
    func missingPrice() {
        var draft = PurchaseDraft(parsed: ParsedQuestion(item: nil, price: nil, date: nil, source: .builtIn), today: today, timeZone: tz)
        #expect(draft.errors(today: today, timeZone: tz) == ["Enter a price, like 700 or 49.99."])
        #expect(draft.makePurchase(today: today, timeZone: tz) == nil)
        draft.priceText = "49.99"
        #expect(draft.makePurchase(today: today, timeZone: tz) == Purchase(item: "Purchase", price: Money(cents: 4_999), date: today))
    }

    @Test("a date past the 30-day range is flagged, not silently moved")
    func dateOutOfRange() {
        let parsed = ParsedQuestion(item: "trip", price: .dollars(300), date: today.adding(days: 45), source: .builtIn)
        let draft = PurchaseDraft(parsed: parsed, today: today, timeZone: tz)
        #expect(draft.errors(today: today, timeZone: tz)
                == ["Pick a date on or before Mon Oct 26. Headroom checks purchases up to 30 days out."])
        #expect(draft.makePurchase(today: today, timeZone: tz) == nil)
    }
}
