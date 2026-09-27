import Foundation
import HeadroomCore

/// The editable form state for one paycheck or bill.
struct EventDraft: Identifiable {
    enum RepeatKind: String, CaseIterable, Identifiable {
        case once, weekly, everyTwoWeeks, twiceMonthly, monthly
        var id: String { rawValue }
        var title: String {
            switch self {
            case .once: "Once"
            case .weekly: "Weekly"
            case .everyTwoWeeks: "Every 2 weeks"
            case .twiceMonthly: "Twice a month"
            case .monthly: "Monthly"
            }
        }
    }

    let id: UUID
    let kind: CashEvent.Kind
    let isNew: Bool
    var name: String
    var amountText: String
    var repeatKind: RepeatKind
    /// The date for "once", or the first occurrence for weekly / every 2 weeks.
    var date: Date
    var day1: Int
    var day2: Int

    init(newOf kind: CashEvent.Kind, today: LocalDate, timeZone: TimeZone = .current) {
        id = UUID()
        self.kind = kind
        isNew = true
        name = ""
        amountText = ""
        repeatKind = kind == .income ? .everyTwoWeeks : .monthly
        date = Date(today, timeZone: timeZone)
        day1 = today.day
        day2 = today.day == 15 ? 1 : 15
    }

    init(event: CashEvent, today: LocalDate, timeZone: TimeZone = .current) {
        id = event.id
        kind = event.kind
        isNew = false
        name = event.name
        amountText = MoneyInput.editableText(event.amount)
        date = Date(today, timeZone: timeZone)
        day1 = today.day
        day2 = today.day == 15 ? 1 : 15
        switch event.schedule {
        case .once(let day):
            repeatKind = .once
            date = Date(day, timeZone: timeZone)
        case .weekly(let from):
            repeatKind = .weekly
            date = Date(from, timeZone: timeZone)
        case .everyTwoWeeks(let from):
            repeatKind = .everyTwoWeeks
            date = Date(from, timeZone: timeZone)
        case .twiceMonthly(let first, let second):
            repeatKind = .twiceMonthly
            day1 = first
            day2 = second
        case .monthly(let day):
            repeatKind = .monthly
            day1 = day
        }
    }

    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    private var amount: Money? {
        guard let money = MoneyInput.parse(amountText), money > .zero else { return nil }
        return money
    }

    /// Problems to show under the fields, in field order.
    var errors: [String] {
        var list: [String] = []
        if trimmedName.isEmpty { list.append("Add a name.") }
        if amount == nil { list.append("Enter an amount, like 750 or 49.99.") }
        if repeatKind == .twiceMonthly {
            // Two days that land on the same date would count once and understate the total.
            if day1 == day2 {
                list.append("Pick two different days.")
            } else if min(day1, day2) > 28 {
                list.append("Pick at least one day on the 28th or earlier.")
            }
        }
        return list
    }

    func makeEvent(timeZone: TimeZone = .current) -> CashEvent? {
        guard errors.isEmpty, let amount else { return nil }
        let day = LocalDate(date, timeZone: timeZone)
        let schedule: Schedule = switch repeatKind {
        case .once: .once(day)
        case .weekly: .weekly(from: day)
        case .everyTwoWeeks: .everyTwoWeeks(from: day)
        case .twiceMonthly: .twiceMonthly(day1: day1, day2: day2)
        case .monthly: .monthly(day: day1)
        }
        return CashEvent(id: id, name: trimmedName, amount: amount, kind: kind, schedule: schedule)
    }
}
