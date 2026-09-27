import Foundation
import Testing
@testable import HeadroomCore

@Suite("Projection")
struct ProjectionTests {
    @Test("same-day pay and rent: rent goes out first (E4)")
    func outflowsBeforeInflows() {
        let plan = makePlan(balance: dollars(300),
                            income("Paycheck", 800, .once(day(3))),
                            bill("Rent", 750, .once(day(3))))
        let path = CashEngine.project(plan, today: today, through: day(3), purchase: nil)
        #expect(path.count == 4)
        #expect(path.point(on: day(3))?.low == dollars(-450))
        #expect(path.point(on: day(3))?.close == dollars(350))
        #expect(path.point(on: day(2))?.close == dollars(300))
    }

    @Test("pay dated today is not added unless marked still coming (E5)")
    func todaysIncomeIgnoredByDefault() {
        let plan = makePlan(balance: dollars(100),
                            income("Paycheck", 800, .once(today)),
                            bill("Rent", 750, .once(day(1))))
        let path = CashEngine.project(plan, today: today, through: day(1), purchase: nil)
        #expect(path.point(on: today)?.close == dollars(100))
        #expect(path.point(on: day(1))?.low == dollars(-650))
    }

    @Test("pay dated today marked still coming lands after today's bills (E5b)")
    func todaysIncomeMarkedStillComing() {
        let payID = UUID()
        let plan = makePlan(balance: dollars(100), incomeStillComingToday: [payID],
                            income("Paycheck", 800, .once(today), id: payID),
                            bill("Rent", 750, .once(day(1))))
        let path = CashEngine.project(plan, today: today, through: day(1), purchase: nil)
        #expect(path.point(on: today)?.low == dollars(100))
        #expect(path.point(on: today)?.close == dollars(900))
        #expect(path.point(on: day(1))?.low == dollars(150))
    }

    @Test("bill dated today is subtracted unless marked already out (E6 path)")
    func todaysBillSubtractedByDefault() {
        let plan = makePlan(balance: dollars(500), bill("Rent", 400, .once(today)))
        let purchase = Purchase(item: "shoes", price: dollars(50), date: today)
        let path = CashEngine.project(plan, today: today, through: day(1), purchase: purchase)
        #expect(path.point(on: today)?.low == dollars(50))
    }

    @Test("bill dated today marked already out is not subtracted again (E6b path)")
    func todaysBillMarkedAlreadyOut() {
        let rentID = UUID()
        let plan = makePlan(balance: dollars(500), billsAlreadyOutToday: [rentID],
                            bill("Rent", 400, .once(today), id: rentID))
        let purchase = Purchase(item: "shoes", price: dollars(50), date: today)
        let path = CashEngine.project(plan, today: today, through: day(1), purchase: purchase)
        #expect(path.point(on: today)?.low == dollars(450))
    }

    @Test("a purchase on payday is checked against the pre-paycheck balance")
    func purchaseOnPaydayGoesOutBeforePay() {
        let plan = makePlan(balance: dollars(850), income("Paycheck", 800, .once(day(2))))
        let purchase = Purchase(item: "laptop", price: dollars(700), date: day(2))
        let path = CashEngine.project(plan, today: today, through: day(2), purchase: purchase)
        #expect(path.point(on: day(1))?.close == dollars(850))
        #expect(path.point(on: day(2))?.low == dollars(150))
        #expect(path.point(on: day(2))?.close == dollars(950))
    }

    @Test("each day lists what moved, money out before money in")
    func dayLinesListEvents() {
        let plan = makePlan(balance: dollars(300),
                            income("Paycheck", 800, .once(day(3))),
                            bill("Rent", 750, .once(day(3))))
        let purchase = Purchase(item: "laptop", price: dollars(20), date: day(3))
        let lines = CashEngine.project(plan, today: today, through: day(3), purchase: purchase)
            .point(on: day(3))?.lines ?? []
        #expect(lines.map(\.name) == ["Rent", "laptop", "Paycheck"])
        #expect(lines.map(\.isIncome) == [false, false, true])
        #expect(lines.map(\.isPurchase) == [false, true, false])
        #expect(lines.map(\.amount) == [dollars(750), dollars(20), dollars(800)])
    }

    @Test("recurring events repeat across the whole range")
    func recurringEventsRepeat() {
        let plan = makePlan(balance: dollars(1_000), bill("Groceries", 100, .weekly(from: day(2))))
        let path = CashEngine.project(plan, today: today, through: day(16), purchase: nil)
        #expect(path.last?.close == dollars(700))   // days 2, 9, 16
    }

    @Test("no balance means no path")
    func noBalanceNoPath() {
        let plan = CashPlan(balance: nil, floor: nil, events: [])
        #expect(CashEngine.project(plan, today: today, through: day(3), purchase: nil).isEmpty)
    }
}
