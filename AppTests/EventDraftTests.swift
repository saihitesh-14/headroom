import Foundation
import HeadroomCore
import Testing
@testable import Headroom

@Suite("EventDraft")
struct EventDraftTests {
    let today = LocalDate(year: 2026, month: 9, day: 26)!
    let tz = TimeZone(identifier: "America/Phoenix")!

    @Test("an existing event survives editing unchanged", arguments: [
        Schedule.once(LocalDate(year: 2026, month: 10, day: 2)!),
        .weekly(from: LocalDate(year: 2026, month: 9, day: 28)!),
        .everyTwoWeeks(from: LocalDate(year: 2026, month: 9, day: 30)!),
        .twiceMonthly(day1: 1, day2: 15),
        .monthly(day: 31),
    ])
    func roundTrip(schedule: Schedule) {
        let event = CashEvent(name: "Rent", amount: Money(cents: 75_050), kind: .bill, schedule: schedule)
        let draft = EventDraft(event: event, today: today, timeZone: tz)
        #expect(draft.makeEvent(timeZone: tz) == event)
    }

    @Test("a new bill starts empty and is not valid until named and priced")
    func newDraftValidation() {
        var draft = EventDraft(newOf: .bill, today: today, timeZone: tz)
        #expect(draft.makeEvent(timeZone: tz) == nil)
        #expect(draft.errors == ["Add a name.", "Enter an amount, like 750 or 49.99."])
        draft.name = "  Rent "
        draft.amountText = "750"
        let event = draft.makeEvent(timeZone: tz)
        #expect(event?.name == "Rent")
        #expect(event?.amount == .dollars(750))
        #expect(event?.kind == .bill)
        #expect(event?.schedule == .monthly(day: 26))
        #expect(draft.errors.isEmpty)
    }

    @Test("a zero amount is rejected")
    func zeroAmount() {
        var draft = EventDraft(newOf: .income, today: today, timeZone: tz)
        draft.name = "Paycheck"
        draft.amountText = "0"
        #expect(draft.makeEvent(timeZone: tz) == nil)
        #expect(draft.errors == ["Enter an amount, like 750 or 49.99."])
    }

    @Test("switching repeat type uses the date or days on screen")
    func repeatKinds() {
        var draft = EventDraft(newOf: .income, today: today, timeZone: tz)
        draft.name = "Paycheck"
        draft.amountText = "800"
        draft.date = Date(LocalDate(year: 2026, month: 9, day: 30)!, timeZone: tz)
        draft.repeatKind = .everyTwoWeeks
        #expect(draft.makeEvent(timeZone: tz)?.schedule == .everyTwoWeeks(from: LocalDate(year: 2026, month: 9, day: 30)!))
        draft.repeatKind = .twiceMonthly
        draft.day1 = 15
        draft.day2 = 1
        #expect(draft.makeEvent(timeZone: tz)?.schedule == .twiceMonthly(day1: 15, day2: 1))
    }
}
