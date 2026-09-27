import HeadroomCore
import Testing
@testable import Headroom

@Suite("SamplePlan")
struct SamplePlanTests {
    @Test("the sample plan reproduces P1: $700 laptop on Fri Oct 2")
    func reproducesP1() throws {
        let today = LocalDate(year: 2026, month: 9, day: 26)!
        let outcome = CashEngine.analyze(SamplePlan.make(today: today),
                                         purchase: Purchase(item: "laptop", price: .dollars(700),
                                                            date: LocalDate(year: 2026, month: 10, day: 2)!),
                                         today: today)
        guard case .analyzed(let a) = outcome else {
            Issue.record("expected an analysis")
            return
        }
        #expect(a.verdict == .crossesFloor(by: .dollars(195)))
        #expect(a.purchaseLow == Low(amount: .dollars(5), date: LocalDate(year: 2026, month: 10, day: 12)!))
        #expect(a.spendingRoomToday == .dollars(505))
        #expect(a.earliestFit == .on(LocalDate(year: 2026, month: 10, day: 15)!))
    }

    @Test("the sample plan is always confirmed for the day it is made")
    func confirmedToday() {
        let today = LocalDate(year: 2027, month: 1, day: 30)!
        let plan = SamplePlan.make(today: today)
        #expect(plan.balance?.asOf == today)
        #expect(plan.floor == .dollars(200))
        if case .room = CashEngine.spendingRoom(plan, today: today) {} else {
            Issue.record("sample plan should never need more information")
        }
    }
}
