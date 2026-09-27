import HeadroomCore
import Testing
@testable import Headroom

@Suite("ScheduleText")
struct ScheduleTextTests {
    let today = LocalDate(year: 2026, month: 9, day: 26)!

    @Test func describesEachSchedule() {
        #expect(ScheduleText.describe(.once(LocalDate(year: 2026, month: 10, day: 2)!), today: today) == "Once, Fri Oct 2")
        #expect(ScheduleText.describe(.weekly(from: LocalDate(year: 2026, month: 9, day: 28)!), today: today) == "Weekly on Mondays")
        #expect(ScheduleText.describe(.everyTwoWeeks(from: LocalDate(year: 2026, month: 9, day: 16)!), today: today)
                == "Every 2 weeks, next Wed Sep 30")
        #expect(ScheduleText.describe(.twiceMonthly(day1: 1, day2: 15), today: today) == "Twice a month, 1st and 15th")
        #expect(ScheduleText.describe(.monthly(day: 22), today: today) == "Monthly on the 22nd")
        #expect(ScheduleText.describe(.monthly(day: 31), today: today) == "Monthly on the 31st")
    }

    @Test func ordinals() {
        #expect([1, 2, 3, 4, 11, 12, 13, 21, 22, 23, 31].map(ScheduleText.ordinal)
                == ["1st", "2nd", "3rd", "4th", "11th", "12th", "13th", "21st", "22nd", "23rd", "31st"])
    }
}
