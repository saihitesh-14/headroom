import Foundation
import Testing
@testable import HeadroomCore

func d(_ year: Int, _ month: Int, _ day: Int) -> LocalDate {
    LocalDate(year: year, month: month, day: day)!
}

@Suite("Schedule")
struct ScheduleTests {
    @Test("monthly on the 31st lands on the last day of short months (S1)")
    func monthlyClampsToMonthEnd() {
        #expect(Schedule.monthly(day: 31).occurrences(from: d(2027, 1, 1), through: d(2027, 4, 30))
                == [d(2027, 1, 31), d(2027, 2, 28), d(2027, 3, 31), d(2027, 4, 30)])
        #expect(Schedule.monthly(day: 31).occurrences(from: d(2028, 2, 1), through: d(2028, 2, 29))
                == [d(2028, 2, 29)])
    }

    @Test("twice monthly on the 15th and 31st in February (S2)")
    func twiceMonthlyInFebruary() {
        #expect(Schedule.twiceMonthly(day1: 15, day2: 31).occurrences(from: d(2027, 2, 1), through: d(2027, 2, 28))
                == [d(2027, 2, 15), d(2027, 2, 28)])
    }

    @Test("twice monthly never doubles up when both days clamp to the same date")
    func twiceMonthlyCollapsesClampedDuplicates() {
        #expect(Schedule.twiceMonthly(day1: 30, day2: 31).occurrences(from: d(2027, 2, 1), through: d(2027, 2, 28))
                == [d(2027, 2, 28)])
    }

    @Test("twice monthly is sorted even when day2 < day1")
    func twiceMonthlySorted() {
        #expect(Schedule.twiceMonthly(day1: 20, day2: 5).occurrences(from: d(2026, 10, 1), through: d(2026, 10, 31))
                == [d(2026, 10, 5), d(2026, 10, 20)])
    }

    @Test("every two weeks never produces a date before its first occurrence (S3)")
    func biweeklyStartsAtAnchor() {
        #expect(Schedule.everyTwoWeeks(from: d(2026, 10, 2)).occurrences(from: d(2026, 9, 26), through: d(2026, 11, 15))
                == [d(2026, 10, 2), d(2026, 10, 16), d(2026, 10, 30), d(2026, 11, 13)])
    }

    @Test("every two weeks from an anchor before the range stays on its cycle")
    func biweeklyAnchorBeforeRange() {
        #expect(Schedule.everyTwoWeeks(from: d(2026, 9, 4)).occurrences(from: d(2026, 9, 26), through: d(2026, 10, 20))
                == [d(2026, 10, 2), d(2026, 10, 16)])
    }

    @Test func weeklyFromAnchorInsideRange() {
        #expect(Schedule.weekly(from: d(2026, 9, 28)).occurrences(from: d(2026, 9, 26), through: d(2026, 10, 12))
                == [d(2026, 9, 28), d(2026, 10, 5), d(2026, 10, 12)])
    }

    @Test func weeklyFromAnchorBeforeRange() {
        #expect(Schedule.weekly(from: d(2026, 9, 1)).occurrences(from: d(2026, 9, 26), through: d(2026, 10, 10))
                == [d(2026, 9, 29), d(2026, 10, 6)])
    }

    @Test func onceInsideAndOutsideRange() {
        #expect(Schedule.once(d(2026, 10, 1)).occurrences(from: d(2026, 9, 26), through: d(2026, 10, 1)) == [d(2026, 10, 1)])
        #expect(Schedule.once(d(2026, 9, 25)).occurrences(from: d(2026, 9, 26), through: d(2026, 10, 1)).isEmpty)
        #expect(Schedule.once(d(2026, 10, 2)).occurrences(from: d(2026, 9, 26), through: d(2026, 10, 1)).isEmpty)
    }

    @Test func emptyOrInvertedRangeHasNoOccurrences() {
        #expect(Schedule.monthly(day: 1).occurrences(from: d(2026, 9, 2), through: d(2026, 9, 30)).isEmpty)
        #expect(Schedule.weekly(from: d(2026, 9, 1)).occurrences(from: d(2026, 10, 1), through: d(2026, 9, 1)).isEmpty)
    }

    @Test func monthlyAcrossYearEnd() {
        #expect(Schedule.monthly(day: 1).occurrences(from: d(2026, 11, 15), through: d(2027, 2, 1))
                == [d(2026, 12, 1), d(2027, 1, 1), d(2027, 2, 1)])
    }

    @Test func codableRoundTrip() throws {
        let schedules: [Schedule] = [.once(d(2026, 10, 1)), .weekly(from: d(2026, 9, 28)),
                                     .everyTwoWeeks(from: d(2026, 9, 30)), .twiceMonthly(day1: 1, day2: 15), .monthly(day: 31)]
        let data = try JSONEncoder().encode(schedules)
        #expect(try JSONDecoder().decode([Schedule].self, from: data) == schedules)
    }
}
