import Foundation
import Testing
@testable import HeadroomCore

@Suite("Charting")
struct ChartingTests {
    func p1Analysis() throws -> Analysis {
        try #require(analyzed(CashEngine.analyze(samplePlanP1(),
                                                 purchase: Purchase(item: "laptop", price: dollars(700), date: d(2026, 10, 2)),
                                                 today: today)))
    }

    // MARK: ChartPath

    @Test("each day gives its low and its close, plus one closing run")
    func pathHasTwoPointsPerDayPlusOne() throws {
        let a = try p1Analysis()
        let points = ChartPath.points(a.baseline)
        #expect(points.count == 2 * a.baseline.count + 1)
        #expect(points.last?.x == Double(a.baseline.count))
        #expect(points.last?.amount == a.baseline.last?.close)
        #expect(points.first == ChartPoint(x: 0, amount: dollars(1_000)))
    }

    @Test("the drawn minimum is exactly the engine's low")
    func pathMinimumIsTheLow() throws {
        let a = try p1Analysis()
        #expect(ChartPath.points(a.baseline).map(\.amount).min() == a.baselineLow.amount)
        #expect(ChartPath.points(a.withPurchase).map(\.amount).min() == a.purchaseLow.amount)
    }

    @Test("the paycheck on Wed Sep 30 (day 4) rises at x = 4.5")
    func paydayRisesMidDay() throws {
        let points = ChartPath.points(try p1Analysis().baseline)
        #expect(points[8] == ChartPoint(x: 4, amount: dollars(900)))
        #expect(points[9] == ChartPoint(x: 4.5, amount: dollars(1_700)))
        #expect(points[10] == ChartPoint(x: 5, amount: dollars(950)))   // Rent on Oct 1 goes out first
    }

    @Test("with and without share the same x values, so one can morph into the other")
    func pathsShareXValues() throws {
        let a = try p1Analysis()
        #expect(ChartPath.points(a.baseline).map(\.x) == ChartPath.points(a.withPurchase).map(\.x))
    }

    @Test("no days, no path")
    func emptyPath() {
        #expect(ChartPath.points([]).isEmpty)
    }

    // MARK: ChartWindow

    @Test("the sample result window runs through Thu Oct 22, a week past the Oct 15 fit")
    func analysisWindow() throws {
        let a = try p1Analysis()
        let end = ChartWindow.end(today: today, horizon: a.checkedThrough,
                                  including: [a.purchase.date, a.purchaseLow.date, a.baselineLow.date, d(2026, 10, 15)])
        #expect(end == d(2026, 10, 22))
    }

    @Test("the sample home window runs through Mon Oct 19, a week past the Oct 12 low")
    func roomWindow() throws {
        let detail = try #require(roomDetail(samplePlanP1()))
        #expect(ChartWindow.end(today: today, horizon: detail.through, including: [detail.low.date]) == d(2026, 10, 19))
    }

    @Test("the window is at least 21 days and never past the horizon")
    func windowBounds() {
        let horizon = day(61)
        #expect(ChartWindow.end(today: today, horizon: horizon, including: [today]) == day(20))
        #expect(ChartWindow.end(today: today, horizon: horizon, including: []) == day(20))
        #expect(ChartWindow.end(today: today, horizon: horizon, including: [day(13)]) == day(20))
        #expect(ChartWindow.end(today: today, horizon: horizon, including: [day(14)]) == day(21))
        #expect(ChartWindow.end(today: today, horizon: horizon, including: [day(58)]) == horizon)
        #expect(ChartWindow.end(today: today, horizon: horizon, including: [horizon]) == horizon)
    }

    @Test("the window always contains the purchase low and the baseline low", arguments: [
        (samplePlanP1(), 700),
        (workedExamplePlan(), 700),
        (rentAndPayPlan(pay: 900), 300),
        (rentAndPayPlan(pay: 800), 50),
        (makePlan(balance: dollars(500), floor: dollars(200), bill("Rent", 400, .once(day(3)))), 20),
    ])
    func windowContainsLows(plan: CashPlan, price: Int) throws {
        for offset in 0...30 {
            let a = try #require(analyzed(CashEngine.analyze(plan, purchase: Purchase(item: "x", price: dollars(price), date: day(offset)), today: today)))
            let end = ChartWindow.end(today: today, horizon: a.checkedThrough,
                                      including: [a.purchase.date, a.purchaseLow.date, a.baselineLow.date])
            #expect(end >= a.purchaseLow.date && end >= a.baselineLow.date && end >= a.purchase.date)
            #expect(end <= a.checkedThrough)
        }
    }

    // MARK: ChartScale.domain

    @Test("the Y domain pads the data and always includes the floor and $0")
    func domainPadding() {
        let result = ChartScale.domain(values: [dollars(5), dollars(1_700)], floor: dollars(200), lowLabelBelow: true, topRatio: 14)
        #expect(result == -27_200...193_800)
        let ask = ChartScale.domain(values: [dollars(705), dollars(1_700)], floor: dollars(200), lowLabelBelow: false, topRatio: 8)
        #expect(ask == -10_200...183_600)
        let tiny = ChartScale.domain(values: [dollars(50)], floor: .zero, lowLabelBelow: false, topRatio: 8)
        #expect(tiny == -5_000...10_000)
    }

    @Test("the Y domain includes the floor and $0 for any data", arguments: [
        ([1_000, 2_000], 200), ([-200, 100], 0), ([-5_000, -4_000], 300), ([150, 180], 500), ([0], 0),
    ])
    func domainIncludesFloorAndZero(values: [Int], floor: Int) {
        for lowLabelBelow in [true, false] {
            for topRatio in [8, 14] {
                let domain = ChartScale.domain(values: values.map(dollars), floor: dollars(floor),
                                               lowLabelBelow: lowLabelBelow, topRatio: topRatio)
                #expect(domain.contains(0))
                #expect(domain.contains(dollars(floor).cents))
                for value in values { #expect(domain.contains(dollars(value).cents)) }
            }
        }
    }

    // MARK: ChartScale.staff

    @Test("the sample staff reads $0, $500, $1,000, $1,500")
    func sampleStaff() {
        #expect(ChartScale.staff(domain: -27_200...193_800) == [0, 500, 1_000, 1_500].map(dollars))
        #expect(ChartScale.staff(domain: -5_000...10_000) == [-50, 0, 50, 100].map(dollars))
    }

    @Test("the staff has at most 5 values, includes $0, and uses the finest step that fits", arguments: [
        -27_200...193_800, -5_000...10_000, -10_000...15_000, -40_000...260_000, -1_000_000...9_000_000,
        -60_000...5_000, -123_456...7_654_321, -5_000...5_000,
    ])
    func staffRules(domain: ClosedRange<Int>) {
        let staff = ChartScale.staff(domain: domain)
        #expect(staff.count <= 5)
        #expect(staff.contains(.zero))
        #expect(staff.allSatisfy { domain.contains($0.cents) })
        #expect(staff == staff.sorted())
        let steps = [5_000, 10_000, 20_000, 25_000, 50_000, 100_000, 200_000, 250_000, 500_000,
                     1_000_000, 2_000_000, 2_500_000, 5_000_000]
        let step = staff.count > 1 ? staff[1].cents - staff[0].cents : 0
        let finer = steps.filter { $0 < step }
        for candidate in finer {
            let count = Array(stride(from: 0, through: domain.upperBound, by: candidate)).count
                + Array(stride(from: -candidate, through: domain.lowerBound, by: -candidate)).count
            #expect(count > 5, "step \(candidate) would also fit \(domain)")
        }
    }

    // MARK: ChartScale.dayMarks

    @Test("day marks are today, each month start, and the end")
    func dayMarks() {
        #expect(ChartScale.dayMarks(today: today, end: d(2026, 10, 22)) == [today, d(2026, 10, 1), d(2026, 10, 22)])
        #expect(ChartScale.dayMarks(today: today, end: d(2026, 11, 26)) == [today, d(2026, 10, 1), d(2026, 11, 1), d(2026, 11, 26)])
    }

    @Test("a month start within 3 days of either end is dropped")
    func dayMarksDropCrowdedMonthStarts() {
        #expect(ChartScale.dayMarks(today: d(2026, 9, 29), end: d(2026, 10, 22)) == [d(2026, 9, 29), d(2026, 10, 22)])
        #expect(ChartScale.dayMarks(today: d(2026, 9, 28), end: d(2026, 10, 22)) == [d(2026, 9, 28), d(2026, 10, 1), d(2026, 10, 22)])
        #expect(ChartScale.dayMarks(today: today, end: d(2026, 11, 2)) == [today, d(2026, 10, 1), d(2026, 11, 2)])
        #expect(ChartScale.dayMarks(today: today, end: d(2026, 11, 4)) == [today, d(2026, 10, 1), d(2026, 11, 1), d(2026, 11, 4)])
    }

    @Test("a window that starts or ends on the 1st does not repeat it")
    func dayMarksOnFirstOfMonth() {
        #expect(ChartScale.dayMarks(today: d(2026, 10, 1), end: d(2026, 10, 21)) == [d(2026, 10, 1), d(2026, 10, 21)])
        #expect(ChartScale.dayMarks(today: d(2026, 10, 10), end: d(2026, 11, 1)) == [d(2026, 10, 10), d(2026, 11, 1)])
    }
}
