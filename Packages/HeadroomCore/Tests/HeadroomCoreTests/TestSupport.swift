import Foundation
@testable import HeadroomCore

/// All engine tests run on Sat 2026-09-26. "Day N" means today + N.
let today = LocalDate(year: 2026, month: 9, day: 26)!

func d(_ year: Int, _ month: Int, _ day: Int) -> LocalDate {
    LocalDate(year: year, month: month, day: day)!
}

func day(_ offset: Int) -> LocalDate {
    today.adding(days: offset)
}

func dollars(_ value: Int) -> Money { .dollars(value) }

func bill(_ name: String, _ amount: Int, _ schedule: Schedule, id: UUID = UUID()) -> CashEvent {
    CashEvent(id: id, name: name, amount: .dollars(amount), kind: .bill, schedule: schedule)
}

func income(_ name: String, _ amount: Int, _ schedule: Schedule, id: UUID = UUID()) -> CashEvent {
    CashEvent(id: id, name: name, amount: .dollars(amount), kind: .income, schedule: schedule)
}

func makePlan(
    balance: Money,
    floor: Money? = nil,
    asOf: LocalDate = today,
    billsAlreadyOutToday: Set<UUID> = [],
    incomeStillComingToday: Set<UUID> = [],
    _ events: CashEvent...
) -> CashPlan {
    CashPlan(
        balance: BalanceSnapshot(amount: balance, asOf: asOf,
                                 billsAlreadyOutToday: billsAlreadyOutToday,
                                 incomeStillComingToday: incomeStillComingToday),
        floor: floor,
        events: events
    )
}

extension Array where Element == DayPoint {
    func point(on date: LocalDate) -> DayPoint? { first { $0.date == date } }
}
