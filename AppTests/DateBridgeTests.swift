import Foundation
import HeadroomCore
import Testing
@testable import Headroom

@Suite("DateBridge")
struct DateBridgeTests {
    let phoenix = TimeZone(identifier: "America/Phoenix")!
    let newYork = TimeZone(identifier: "America/New_York")!

    func instant(_ iso: String) -> Date {
        try! Date(iso, strategy: .iso8601)
    }

    @Test("23:30 local time stays on the local day, not the UTC day")
    func lateEveningStaysLocal() {
        let lateSep26 = instant("2026-09-27T06:30:00Z")   // 23:30 on Sep 26 in Phoenix (UTC-7)
        #expect(LocalDate(lateSep26, timeZone: phoenix) == LocalDate(year: 2026, month: 9, day: 26))
        #expect(LocalDate(lateSep26, timeZone: .gmt) == LocalDate(year: 2026, month: 9, day: 27))
    }

    @Test("round trips through Date across daylight-saving changes", arguments: [
        (2026, 3, 8), (2026, 11, 1), (2026, 9, 26), (2028, 2, 29), (2026, 12, 31),
    ])
    func roundTrip(year: Int, month: Int, day: Int) {
        let local = LocalDate(year: year, month: month, day: day)!
        #expect(LocalDate(Date(local, timeZone: newYork), timeZone: newYork) == local)
    }
}
