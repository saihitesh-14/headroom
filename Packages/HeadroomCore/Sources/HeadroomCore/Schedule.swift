/// When a bill or paycheck happens.
public enum Schedule: Codable, Hashable, Sendable {
    case once(LocalDate)
    /// Every 7 days. `from` is the first occurrence; nothing happens before it.
    case weekly(from: LocalDate)
    /// Every 14 days. `from` is the first occurrence; nothing happens before it.
    case everyTwoWeeks(from: LocalDate)
    /// Two days each month (1...31). Days past a month's end land on its last day.
    case twiceMonthly(day1: Int, day2: Int)
    /// One day each month (1...31). Days past a month's end land on its last day.
    case monthly(day: Int)

    /// Every occurrence in the closed range `from...through`, in date order.
    public func occurrences(from start: LocalDate, through end: LocalDate) -> [LocalDate] {
        guard start <= end else { return [] }
        switch self {
        case .once(let date):
            return (start...end).contains(date) ? [date] : []
        case .weekly(let anchor):
            return repeating(every: 7, anchor: anchor, from: start, through: end)
        case .everyTwoWeeks(let anchor):
            return repeating(every: 14, anchor: anchor, from: start, through: end)
        case .twiceMonthly(let day1, let day2):
            return monthlyDates(days: [day1, day2], from: start, through: end)
        case .monthly(let day):
            return monthlyDates(days: [day], from: start, through: end)
        }
    }

    private func repeating(every interval: Int, anchor: LocalDate, from start: LocalDate, through end: LocalDate) -> [LocalDate] {
        var date = anchor
        if anchor < start {
            // Jump to the first occurrence on or after `start`, staying on the anchor's cycle.
            let behind = anchor.days(until: start)
            let steps = (behind + interval - 1) / interval
            date = anchor.adding(days: steps * interval)
        }
        var result: [LocalDate] = []
        while date <= end {
            result.append(date)
            date = date.adding(days: interval)
        }
        return result
    }

    private func monthlyDates(days: [Int], from start: LocalDate, through end: LocalDate) -> [LocalDate] {
        var result: [LocalDate] = []
        var year = start.year, month = start.month
        while (year, month) <= (end.year, end.month) {
            let lastDay = LocalDate.daysInMonth(year: year, month: month)
            let dates = Set(days.map { LocalDate(year: year, month: month, day: min(max($0, 1), lastDay))! })
            result += dates.sorted().filter { $0 >= start && $0 <= end }
            month += 1
            if month > 12 { month = 1; year += 1 }
        }
        return result
    }
}
