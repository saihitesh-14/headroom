import Foundation
import Testing
@testable import HeadroomCore

@Suite("Register")
struct RegisterTests {
    @Test("the sample register runs down to the Mon Oct 12 low (P1)")
    func samplePlanRegister() throws {
        let detail = try #require(roomDetail(samplePlanP1()))
        let entries = CashEngine.register(detail.points, through: detail.low.date)
        #expect(entries.count == 6)
        #expect(entries.map(\.balanceAfter) == [900, 1_700, 950, 850, 805, 705].map(dollars))
        #expect(entries.map(\.name) == ["Groceries", "Paycheck", "Rent", "Groceries", "Phone", "Groceries"])
        #expect(entries.map(\.amount) == [-100, 800, -750, -100, -45, -100].map(dollars))
        #expect(entries.map(\.isIncome) == [false, true, false, false, false, false])
        #expect(entries.map(\.date) == [d(2026, 9, 28), d(2026, 9, 30), d(2026, 10, 1), d(2026, 10, 5), d(2026, 10, 8), d(2026, 10, 12)])
    }

    @Test("the last balance is the low", arguments: [
        samplePlanP1(), workedExamplePlan(), rentAndPayPlan(pay: 900), rentAndPayPlan(pay: 800),
        makePlan(balance: dollars(500), floor: dollars(200), bill("Rent", 400, .once(day(3)))),
        makePlan(balance: dollars(300), floor: dollars(0), income("Paycheck", 800, .once(day(3))), bill("Rent", 750, .once(day(3)))),
    ])
    func lastBalanceIsTheLow(plan: CashPlan) throws {
        let detail = try #require(roomDetail(plan))
        let entries = CashEngine.register(detail.points, through: detail.low.date)
        #expect((entries.last?.balanceAfter ?? detail.start) == detail.low.amount)
    }

    @Test("on the last day only money out counts, because pay lands after the low")
    func throughDayExcludesIncome() {
        let plan = makePlan(balance: dollars(300), income("Paycheck", 800, .once(day(3))), bill("Rent", 750, .once(day(3))))
        let points = CashEngine.project(plan, today: today, through: day(10), purchase: nil)
        let entries = CashEngine.register(points, through: day(3))
        #expect(entries.map(\.name) == ["Rent"])
        #expect(entries.map(\.balanceAfter) == [dollars(-450)])
    }

    @Test("on earlier days money out comes before money in, like the engine")
    func engineOrderWithinADay() {
        let plan = makePlan(balance: dollars(300), income("Paycheck", 800, .once(day(3))), bill("Rent", 750, .once(day(3))))
        let points = CashEngine.project(plan, today: today, through: day(10), purchase: nil)
        let entries = CashEngine.register(points, through: day(4))
        #expect(entries.map(\.name) == ["Rent", "Paycheck"])
        #expect(entries.map(\.amount) == [dollars(-750), dollars(800)])
        #expect(entries.map(\.balanceAfter) == [dollars(-450), dollars(350)])
        #expect(entries.map(\.isIncome) == [false, true])
    }

    @Test("the opening balance counts today's bills, so today's rent shows as a row")
    func openingBalanceIncludesTodaysBills() {
        let plan = makePlan(balance: dollars(500), bill("Rent", 400, .once(today)), income("Paycheck", 100, .once(day(1))))
        let points = CashEngine.project(plan, today: today, through: day(5), purchase: nil)
        let entries = CashEngine.register(points, through: day(2))
        #expect(entries.map(\.name) == ["Rent", "Paycheck"])
        #expect(entries.map(\.balanceAfter) == [dollars(100), dollars(200)])
        #expect(entries.map(\.date) == [today, day(1)])
    }

    @Test("nothing past the through day, and nothing from no days")
    func bounds() {
        let plan = makePlan(balance: dollars(1_000), bill("Groceries", 100, .weekly(from: day(2))))
        let points = CashEngine.project(plan, today: today, through: day(30), purchase: nil)
        #expect(CashEngine.register(points, through: day(9)).map(\.date) == [day(2), day(9)])
        #expect(CashEngine.register(points, through: day(1)).isEmpty)
        #expect(CashEngine.register([], through: day(9)).isEmpty)
    }
}
