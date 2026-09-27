import Foundation
import Testing
@testable import HeadroomCore

/// Unwraps an analyzed outcome or records a failure.
func analyzed(_ outcome: Outcome, sourceLocation: SourceLocation = #_sourceLocation) -> Analysis? {
    if case .analyzed(let analysis) = outcome { return analysis }
    Issue.record("Expected an analysis, got \(outcome)", sourceLocation: sourceLocation)
    return nil
}

func missing(_ outcome: Outcome) -> [MissingInfo] {
    if case .needsInfo(let list) = outcome { return list }
    return []
}

/// The worked example from the original plan (E1).
func workedExamplePlan(extra: CashEvent...) -> CashPlan {
    var plan = makePlan(balance: dollars(1_000), floor: dollars(200),
                        income("Paycheck", 800, .once(day(4))),
                        bill("Rent", 750, .once(day(5))),
                        bill("Essentials", 200, .once(day(9))))
    plan.events += extra
    return plan
}

/// The sample plan (P1) built inline.
func samplePlanP1() -> CashPlan {
    makePlan(balance: dollars(1_000), floor: dollars(200),
             income("Paycheck", 800, .everyTwoWeeks(from: d(2026, 9, 30))),
             bill("Rent", 750, .monthly(day: 1)),
             bill("Phone", 45, .monthly(day: 8)),
             bill("Streaming", 12, .monthly(day: 16)),
             bill("Groceries", 100, .weekly(from: d(2026, 9, 28))))
}

/// Rent $900 on the 1st, pay on the 15th (E3 / E13).
func rentAndPayPlan(pay: Int) -> CashPlan {
    makePlan(balance: dollars(1_000), floor: dollars(0),
             bill("Rent", 900, .monthly(day: 1)),
             income("Paycheck", pay, .monthly(day: 15)))
}

@Suite("Analysis")
struct AnalysisTests {
    @Test("your worked example crosses the floor by $50 (E1)")
    func workedExample() throws {
        let a = try #require(analyzed(CashEngine.analyze(workedExamplePlan(),
                                                         purchase: Purchase(item: "laptop", price: dollars(700), date: today),
                                                         today: today)))
        #expect(a.baselineLow == Low(amount: dollars(850), date: day(9)))
        #expect(a.purchaseLow == Low(amount: dollars(150), date: day(9)))
        #expect(a.verdict == .crossesFloor(by: dollars(50)))
        #expect(a.spendingRoomToday == dollars(650))
        #expect(a.earliestFit == .none(.notEnoughRoom))
        #expect(a.baselineWarning == nil)
        #expect(a.checkedThrough == d(2026, 11, 26))
        #expect(a.baseline.count == 62)
        #expect(a.withPurchase.count == 62)
    }

    @Test("a second paycheck makes the day after payday the earliest fit (E2)")
    func earliestFitIsDayAfterPayday() throws {
        let plan = workedExamplePlan(extra: income("Paycheck", 800, .once(day(18))))
        let a = try #require(analyzed(CashEngine.analyze(plan,
                                                         purchase: Purchase(item: "laptop", price: dollars(700), date: today),
                                                         today: today)))
        #expect(a.earliestFit == .on(day(19)))
    }

    @Test("a late purchase date still sees next month's rent (E3)")
    func lookaheadCatchesNextMonthsRent() throws {
        let a = try #require(analyzed(CashEngine.analyze(rentAndPayPlan(pay: 900),
                                                         purchase: Purchase(item: "desk", price: dollars(300), date: d(2026, 10, 24)),
                                                         today: today)))
        #expect(a.verdict == .goesNegative(by: dollars(200)))
        #expect(a.purchaseLow == Low(amount: dollars(-200), date: d(2026, 11, 1)))
    }

    @Test("buying today is not falsely safer than buying later (E13)")
    func sameHorizonForEveryDate() throws {
        let a = try #require(analyzed(CashEngine.analyze(rentAndPayPlan(pay: 800),
                                                         purchase: Purchase(item: "headphones", price: dollars(50), date: today),
                                                         today: today)))
        #expect(a.verdict == .goesNegative(by: dollars(50)))
        #expect(a.purchaseLow.date == d(2026, 11, 1))
        #expect(a.spendingRoomToday == dollars(0))
        #expect(a.earliestFit == .none(.notEnoughRoom))
    }

    @Test("today's unmarked rent is subtracted (E6) and a marked one is not (E6b)")
    func todaysBillMarks() throws {
        let rentID = UUID()
        let purchase = Purchase(item: "shoes", price: dollars(50), date: today)
        let unmarked = makePlan(balance: dollars(500), floor: dollars(0), bill("Rent", 400, .once(today), id: rentID))
        let marked = makePlan(balance: dollars(500), floor: dollars(0), billsAlreadyOutToday: [rentID],
                              bill("Rent", 400, .once(today), id: rentID))
        #expect(analyzed(CashEngine.analyze(unmarked, purchase: purchase, today: today))?.verdict == .fits(room: dollars(50)))
        #expect(analyzed(CashEngine.analyze(marked, purchase: purchase, today: today))?.verdict == .fits(room: dollars(450)))
    }

    @Test("a balance confirmed yesterday needs reconfirming (E7)")
    func staleBalance() {
        let plan = makePlan(balance: dollars(1_000), floor: dollars(200), asOf: d(2026, 9, 25), bill("Rent", 750, .monthly(day: 1)))
        let outcome = CashEngine.analyze(plan, purchase: Purchase(item: "laptop", price: dollars(700), date: today), today: today)
        #expect(missing(outcome) == [.balanceNotConfirmedToday(lastConfirmed: d(2026, 9, 25))])
    }

    @Test("each missing input is reported, and several at once are all listed (E8)")
    func missingInputs() {
        let good = Purchase(item: "laptop", price: dollars(700), date: today)
        var noFloor = workedExamplePlan(); noFloor.floor = nil
        var noEvents = workedExamplePlan(); noEvents.events = []
        let plan = workedExamplePlan()
        #expect(missing(CashEngine.analyze(noFloor, purchase: good, today: today)) == [.floor])
        #expect(missing(CashEngine.analyze(noEvents, purchase: good, today: today)) == [.noEvents])
        #expect(missing(CashEngine.analyze(plan, purchase: Purchase(item: "x", price: .zero, date: today), today: today)) == [.invalidPrice])
        #expect(missing(CashEngine.analyze(plan, purchase: Purchase(item: "x", price: Money(cents: 1_000_000_001), date: today), today: today)) == [.invalidPrice])
        #expect(missing(CashEngine.analyze(plan, purchase: Purchase(item: "x", price: dollars(5), date: d(2026, 9, 25)), today: today)) == [.dateInPast])
        #expect(missing(CashEngine.analyze(plan, purchase: Purchase(item: "x", price: dollars(5), date: day(31)), today: today)) == [.dateBeyondRange(latest: day(30))])
        let empty = CashPlan()
        #expect(missing(CashEngine.analyze(empty, purchase: Purchase(item: "x", price: .zero, date: day(40)), today: today))
                == [.balance, .floor, .noEvents, .invalidPrice, .dateBeyondRange(latest: day(30))])
    }

    @Test("the last day in range is allowed")
    func lastDayInRangeAllowed() {
        let outcome = CashEngine.analyze(workedExamplePlan(), purchase: Purchase(item: "x", price: dollars(5), date: day(30)), today: today)
        #expect(missing(outcome).isEmpty)
    }

    @Test("zero starting cash goes negative (E9)")
    func zeroStart() throws {
        let plan = makePlan(balance: dollars(0), floor: dollars(0), income("Paycheck", 500, .once(day(70))))
        let a = try #require(analyzed(CashEngine.analyze(plan, purchase: Purchase(item: "snack", price: dollars(10), date: today), today: today)))
        #expect(a.verdict == .goesNegative(by: dollars(10)))
        #expect(a.purchaseLow.date == today)
    }

    @Test("negative starting cash is flagged before the purchase (E10)")
    func negativeStart() throws {
        let plan = makePlan(balance: dollars(-50), floor: dollars(0), income("Paycheck", 500, .once(day(70))))
        let a = try #require(analyzed(CashEngine.analyze(plan, purchase: Purchase(item: "snack", price: dollars(10), date: today), today: today)))
        #expect(a.verdict == .goesNegative(by: dollars(60)))
        #expect(a.baselineWarning == .negative(Low(amount: dollars(-50), date: today)))
    }

    @Test("landing exactly on the floor fits; one cent more crosses (E11, E11b)")
    func exactlyAtFloor() {
        let plan = makePlan(balance: dollars(1_000), floor: dollars(200), bill("Bill", 400, .once(day(3))))
        #expect(analyzed(CashEngine.analyze(plan, purchase: Purchase(item: "x", price: dollars(400), date: today), today: today))?.verdict
                == .fits(room: .zero))
        #expect(analyzed(CashEngine.analyze(plan, purchase: Purchase(item: "x", price: Money(cents: 40_001), date: today), today: today))?.verdict
                == .crossesFloor(by: Money(cents: 1)))
    }

    @Test("a plan already below the floor says so (E12)")
    func planAlreadyShort() throws {
        let plan = makePlan(balance: dollars(500), floor: dollars(200), bill("Rent", 400, .once(day(3))))
        let a = try #require(analyzed(CashEngine.analyze(plan, purchase: Purchase(item: "book", price: dollars(20), date: today), today: today)))
        #expect(a.verdict == .crossesFloor(by: dollars(120)))
        #expect(a.baselineLowFromPurchaseDate == Low(amount: dollars(100), date: d(2026, 9, 29)))
        #expect(a.baselineWarning == .belowFloor(Low(amount: dollars(100), date: d(2026, 9, 29))))
        #expect(a.earliestFit == .none(.planAlreadyShort))
    }

    @Test("the sample plan: $700 laptop next Friday (P1)")
    func samplePlan() throws {
        let a = try #require(analyzed(CashEngine.analyze(samplePlanP1(),
                                                         purchase: Purchase(item: "laptop", price: dollars(700), date: d(2026, 10, 2)),
                                                         today: today)))
        #expect(a.verdict == .crossesFloor(by: dollars(195)))
        #expect(a.purchaseLow == Low(amount: dollars(5), date: d(2026, 10, 12)))
        #expect(a.spendingRoomToday == dollars(505))
        #expect(a.earliestFit == .on(d(2026, 10, 15)))
        #expect(a.checkedThrough == d(2026, 11, 26))
    }

    @Test("if a date fits, every later date fits too (MON)", arguments: [
        (samplePlanP1(), 700),
        (rentAndPayPlan(pay: 900), 300),
        (rentAndPayPlan(pay: 800), 50),
        (workedExamplePlan(extra: income("Paycheck", 800, .once(day(18)))), 700),
    ])
    func fitIsMonotonic(plan: CashPlan, price: Int) throws {
        var fitSeen = false
        for offset in 0...30 {
            let a = try #require(analyzed(CashEngine.analyze(plan, purchase: Purchase(item: "x", price: dollars(price), date: day(offset)), today: today)))
            let fits = if case .fits = a.verdict { true } else { false }
            if fitSeen { #expect(fits, "day \(offset) should fit because an earlier day did") }
            fitSeen = fitSeen || fits
            if case .on(let first) = a.earliestFit, fits {
                #expect(first <= day(offset))
            }
        }
    }

    @Test("spending room for the home screen")
    func spendingRoom() {
        #expect(CashEngine.spendingRoom(samplePlanP1(), today: today) == .room(dollars(505), through: d(2026, 11, 26)))
        var stale = samplePlanP1()
        stale.balance?.asOf = d(2026, 9, 25)
        #expect(CashEngine.spendingRoom(stale, today: today) == .needsInfo([.balanceNotConfirmedToday(lastConfirmed: d(2026, 9, 25))]))
        #expect(CashEngine.spendingRoom(CashPlan(), today: today) == .needsInfo([.balance, .floor, .noEvents]))
    }
}
