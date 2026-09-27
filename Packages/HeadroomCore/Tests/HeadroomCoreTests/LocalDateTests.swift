import Foundation
import Testing
@testable import HeadroomCore

@Suite("LocalDate")
struct LocalDateTests {
    let sep26 = LocalDate(year: 2026, month: 9, day: 26)!

    @Test func sep26_2026IsSaturday() {
        #expect(sep26.weekday == 7)
    }

    @Test func adding37DaysCrossesTwoMonthEnds() {
        #expect(sep26.adding(days: 37) == LocalDate(year: 2026, month: 11, day: 2))
        #expect(sep26.adding(days: -26) == LocalDate(year: 2026, month: 8, day: 31))
    }

    @Test func daysUntilIsSigned() {
        let nov2 = LocalDate(year: 2026, month: 11, day: 2)!
        #expect(sep26.days(until: nov2) == 37)
        #expect(nov2.days(until: sep26) == -37)
    }

    @Test func rejectsImpossibleDates() {
        #expect(LocalDate(year: 2028, month: 2, day: 29) != nil)
        #expect(LocalDate(year: 2027, month: 2, day: 29) == nil)
        #expect(LocalDate(year: 2026, month: 13, day: 1) == nil)
        #expect(LocalDate(year: 2026, month: 4, day: 31) == nil)
        #expect(LocalDate(year: 2026, month: 1, day: 0) == nil)
    }

    @Test func leapYearRules() {
        #expect(LocalDate.daysInMonth(year: 2000, month: 2) == 29)
        #expect(LocalDate.daysInMonth(year: 2100, month: 2) == 28)
        #expect(LocalDate.daysInMonth(year: 2028, month: 2) == 29)
        #expect(LocalDate.daysInMonth(year: 2027, month: 2) == 28)
        #expect(LocalDate.daysInMonth(year: 2026, month: 12) == 31)
    }

    @Test func walkingDayByDayFrom2000To2100NeverSkipsOrRepeats() {
        var date = LocalDate(year: 2000, month: 1, day: 1)!
        let start = date
        var weekday = date.weekday
        for offset in 1...36_889 {   // 101 years with 25 leap days = 36,890 days, so 36,889 steps
            let next = date.adding(days: 1)
            if date.day < LocalDate.daysInMonth(year: date.year, month: date.month) {
                #expect(next == LocalDate(year: date.year, month: date.month, day: date.day + 1))
            } else if date.month < 12 {
                #expect(next == LocalDate(year: date.year, month: date.month + 1, day: 1))
            } else {
                #expect(next == LocalDate(year: date.year + 1, month: 1, day: 1))
            }
            weekday = weekday % 7 + 1
            #expect(next.weekday == weekday)
            #expect(start.days(until: next) == offset)
            #expect(start.adding(days: offset) == next)
            date = next
        }
        #expect(date == LocalDate(year: 2100, month: 12, day: 31))
    }

    @Test func ordering() {
        #expect(sep26 < sep26.adding(days: 1))
        #expect(LocalDate(year: 2026, month: 12, day: 31)! < LocalDate(year: 2027, month: 1, day: 1)!)
    }

    @Test func displayText() {
        #expect(sep26.shortText == "Sat Sep 26")
        #expect(sep26.monthDayText == "Sep 26")
        #expect(sep26.description == "2026-09-26")
    }

    @Test("new sentences keep a date on one line with no-break spaces")
    func shortTextNoBreak() {
        #expect(LocalDate(year: 2026, month: 10, day: 2)!.shortTextNoBreak == "Fri\u{00A0}Oct\u{00A0}2")
        #expect(sep26.shortTextNoBreak == "Sat\u{00A0}Sep\u{00A0}26")
        #expect(sep26.shortText == "Sat Sep 26")
    }

    @Test("full weekday names for labels", arguments: [
        (26, "Saturday"), (27, "Sunday"), (28, "Monday"), (29, "Tuesday"), (30, "Wednesday"),
    ])
    func weekdayName(day: Int, expected: String) {
        #expect(LocalDate(year: 2026, month: 9, day: day)!.weekdayName == expected)
    }

    @Test("VoiceOver dates spell out the weekday and month")
    func spokenText() {
        #expect(LocalDate(year: 2026, month: 10, day: 2)!.spokenText == "Friday, October 2")
        #expect(LocalDate(year: 2026, month: 10, day: 13)!.spokenText == "Tuesday, October 13")
        #expect(LocalDate(year: 2027, month: 1, day: 1)!.spokenText == "Friday, January 1")
        #expect(LocalDate(year: 2026, month: 12, day: 31)!.spokenText == "Thursday, December 31")
        #expect(LocalDate(year: 2026, month: 5, day: 3)!.spokenText == "Sunday, May 3")
    }

    @Test func codableAsISODateString() throws {
        let data = try JSONEncoder().encode(sep26)
        #expect(String(decoding: data, as: UTF8.self) == "\"2026-09-26\"")
        #expect(try JSONDecoder().decode(LocalDate.self, from: data) == sep26)
        #expect(throws: (any Error).self) {
            try JSONDecoder().decode(LocalDate.self, from: Data("\"2027-02-29\"".utf8))
        }
    }
}
