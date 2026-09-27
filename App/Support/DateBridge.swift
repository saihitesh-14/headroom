import Foundation
import HeadroomCore

// The only place `Date` meets `LocalDate`. Always Gregorian, in the device's time zone,
// so a phone set to another calendar system still gets the right calendar day.

private func gregorian(_ timeZone: TimeZone) -> Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = timeZone
    return calendar
}

extension LocalDate {
    /// The calendar day `date` falls on in `timeZone`.
    init(_ date: Date, timeZone: TimeZone = .current) {
        let parts = gregorian(timeZone).dateComponents([.year, .month, .day], from: date)
        self = LocalDate(year: parts.year!, month: parts.month!, day: parts.day!)!
    }

    static func today(in timeZone: TimeZone = .current) -> LocalDate {
        LocalDate(Date(), timeZone: timeZone)
    }
}

extension Date {
    /// Noon on `day` in `timeZone` (noon never falls in a daylight-saving gap).
    init(_ day: LocalDate, timeZone: TimeZone = .current) {
        let parts = DateComponents(year: day.year, month: day.month, day: day.day, hour: 12)
        self = gregorian(timeZone).date(from: parts)!
    }
}
