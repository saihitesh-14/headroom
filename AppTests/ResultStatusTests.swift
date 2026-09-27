import Foundation
import HeadroomCore
import Testing
@testable import Headroom

@Suite("ResultStatus")
struct ResultStatusTests {
    let today = LocalDate(year: 2026, month: 9, day: 26)!

    func status(balance: Int, floor: Int, billOnDay3: Int, price: Int) throws -> ResultStatus {
        let plan = CashPlan(
            balance: BalanceSnapshot(amount: .dollars(balance), asOf: today),
            floor: .dollars(floor),
            events: [CashEvent(name: "Rent", amount: .dollars(billOnDay3), kind: .bill, schedule: .once(today.adding(days: 3)))]
        )
        guard case .analyzed(let a) = CashEngine.analyze(plan, purchase: Purchase(item: "x", price: .dollars(price), date: today), today: today) else {
            throw CancellationError()
        }
        return ResultStatus(a)
    }

    @Test func fitsCrossesAndNegative() throws {
        #expect(try status(balance: 1_000, floor: 200, billOnDay3: 400, price: 100) == .fits)
        #expect(try status(balance: 1_000, floor: 200, billOnDay3: 400, price: 500) == .crossesFloor)
        #expect(try status(balance: 1_000, floor: 200, billOnDay3: 400, price: 700) == .goesNegative)
    }

    @Test("a plan already below the floor shows the warning state even for a tiny purchase")
    func alreadyShortPlan() throws {
        #expect(try status(balance: 500, floor: 200, billOnDay3: 400, price: 1) == .crossesFloor)
        #expect(try status(balance: 300, floor: 0, billOnDay3: 400, price: 1) == .goesNegative)
    }
}
