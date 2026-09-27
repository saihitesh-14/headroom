import HeadroomCore

/// Short, plain descriptions of a schedule for list rows.
enum ScheduleText {
    private static let weekdayPlurals = ["Sundays", "Mondays", "Tuesdays", "Wednesdays",
                                         "Thursdays", "Fridays", "Saturdays"]

    static func describe(_ schedule: Schedule, today: LocalDate) -> String {
        switch schedule {
        case .once(let date):
            return "Once, \(date.shortText)"
        case .weekly(let anchor):
            return "Weekly on \(weekdayPlurals[anchor.weekday - 1])"
        case .everyTwoWeeks:
            if let next = schedule.occurrences(from: today, through: today.adding(days: 13)).first {
                return "Every 2 weeks, next \(next.shortText)"
            }
            return "Every 2 weeks"
        case .twiceMonthly(let day1, let day2):
            let days = [day1, day2].sorted()
            return "Twice a month, \(ordinal(days[0])) and \(ordinal(days[1]))"
        case .monthly(let day):
            return "Monthly on the \(ordinal(day))"
        }
    }

    static func ordinal(_ n: Int) -> String {
        let suffix: String
        switch (n % 10, n % 100) {
        case (_, 11...13): suffix = "th"
        case (1, _): suffix = "st"
        case (2, _): suffix = "nd"
        case (3, _): suffix = "rd"
        default: suffix = "th"
        }
        return "\(n)\(suffix)"
    }
}
