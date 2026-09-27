import Accessibility
import HeadroomCore
import Testing
@testable import Headroom

/// The Result chart's data (docs/REDESIGN-SPEC.md sections 6.1 to 6.5), for the sample plan
/// with today = Sun Sep 27 2026 and a $700 laptop on Fri Oct 2: the wireframe numbers.
@MainActor
@Suite("Result chart")
struct ResultChartTests {
    let today = LocalDate(year: 2026, month: 9, day: 27)!

    func date(_ month: Int, _ day: Int) -> LocalDate { LocalDate(year: 2026, month: month, day: day)! }

    func analysis(price: Int = 700, on purchaseDate: LocalDate? = nil) throws -> Analysis {
        let purchase = Purchase(item: "laptop", price: .dollars(price), date: purchaseDate ?? date(10, 2))
        guard case .analyzed(let a) = CashEngine.analyze(SamplePlan.make(today: today), purchase: purchase, today: today) else {
            throw CancellationError()
        }
        return a
    }

    @Test("the window runs from today through a week past the earliest fit")
    func window() throws {
        let model = ResultChartModel(try analysis())
        #expect(model.windowEnd == date(10, 23))
        #expect(model.windowDays == 26)
        #expect(model.xDomain == 0...27)
        #expect(model.baseline.count == 2 * 27 + 1)
        #expect(model.withPurchase.map(\.x) == model.baseline.map(\.x))
        #expect(model.withPurchase.last?.x == 27)
    }

    @Test("marks sit at the engine's dates and amounts")
    func marks() throws {
        let model = ResultChartModel(try analysis())
        #expect(model.floor == 20_000)
        #expect(model.datum == 20_000)
        #expect(model.low == 500)
        #expect(model.lowX == 16.25)
        #expect(model.purchaseX == 5)
        #expect(model.showsBelowFloorArea)
        #expect(model.staff == [0, 500, 1_000, 1_500].map { Money.dollars($0) })
        #expect(model.domain.contains(0) && model.domain.contains(20_000))
    }

    @Test("the floor label sits on the side of the datum away from the low")
    func floorLabelSide() throws {
        #expect(!ResultChartModel(try analysis()).floorLabelBelow)
        #expect(!ResultChartModel(try analysis(price: 800)).floorLabelBelow)
        #expect(ResultChartModel(try analysis(on: date(10, 16))).floorLabelBelow)
    }

    @Test("below zero, the clearance is measured from the $0 rule")
    func datumBelowZero() throws {
        let model = ResultChartModel(try analysis(price: 800))
        #expect(model.low == -9_500)
        #expect(model.datum == 0)
    }

    @Test("the peel moves the With line from the Without line to the engine's path")
    func peel() throws {
        let model = ResultChartModel(try analysis())
        #expect(model.withShown(peel: 0) == model.baseline)
        #expect(model.withShown(peel: 1) == model.withPurchase)
        #expect(model.withShown(peel: 0).map(\.x) == model.withPurchase.map(\.x))
    }

    @Test("the day ruler labels today, month starts and the window end")
    func ruler() {
        let ruler = DayRuler(today: today, end: date(10, 23), accessibilitySize: false)
        #expect(ruler.marks == [.init(index: 0, label: "Today"), .init(index: 4, label: "Oct 1", isMonthStart: true),
                                .init(index: 26, label: "Oct 23")])
        #expect(ruler.ticks == Array(0...26))
        #expect(ruler.endMark == .init(index: 26, label: "Oct 23"))
        #expect(ruler.mark(at: 4)?.label == "Oct 1")
        #expect(ruler.mark(at: 5) == nil)

        let large = DayRuler(today: today, end: date(10, 23), accessibilitySize: true)
        #expect(large.marks == [.init(index: 0, label: "Today"), .init(index: 26, label: "Oct 23")])
        #expect(large.ticks == [0, 7, 14, 21])
    }

    @Test("a selected day reads that day's lines and both closes")
    func callout() throws {
        let model = ResultChartModel(try analysis())
        #expect(model.day(at: 5.7) == 5)
        #expect(model.day(at: -3) == 0)
        #expect(model.day(at: 400) == 26)

        let callout = model.callout(day: 5)
        #expect(callout.date == date(10, 2))
        #expect(callout.lines == [.init(name: "Rent", amount: .dollars(-750)), .init(name: "Laptop", amount: .dollars(-700))])
        #expect(callout.withClose == .dollars(250))
        #expect(callout.withoutClose == .dollars(950))
        #expect(model.withName == "With laptop")
        #expect(model.withoutName == "Without laptop")
    }

    @Test("VoiceOver hears the summary, the below-floor dates and the horizon")
    func accessibilityValue() throws {
        let model = ResultChartModel(try analysis())
        #expect(model.accessibilityValue == "Lowest point: $5 on Tue Oct 13. That's $195 below your $200 floor. "
            + "Below your floor Tue\u{00A0}Oct\u{00A0}6 to Thu\u{00A0}Oct\u{00A0}15. Checked through Friday, November 27.")
    }

    @Test("a plan that never dips has no below-floor words")
    func accessibilityValueWithoutDip() throws {
        let model = ResultChartModel(try analysis(price: 100, on: date(10, 16)))
        #expect(!model.showsBelowFloorArea)
        #expect(model.accessibilityValue.hasSuffix("floor. Checked through Friday, November 27."))
    }

    @Test("the audio graph has two continuous series of daily lows")
    func descriptor() throws {
        let a = try analysis()
        let chart = CashChartDescriptor(analysis: a, windowDays: 26).makeChartDescriptor()
        #expect(chart.title == "Balance with and without laptop")
        #expect(chart.summary == ResultChartModel(a).accessibilityValue)
        #expect(chart.series.map(\.name) == ["With laptop", "Without laptop"])
        #expect(chart.series.allSatisfy { $0.isContinuous && $0.dataPoints.count == 27 })
        let low = chart.series[0].dataPoints[16]
        #expect(low.xValue.__number == 16)
        #expect(low.yValue?.__number == 5)
        #expect(chart.series[1].dataPoints[16].yValue?.__number == 705)

        let x = try #require(chart.xAxis as? AXNumericDataAxisDescriptor)
        #expect(x.range == 0...26)
        #expect(x.valueDescriptionProvider(16) == "Tuesday, October 13")
        let y = try #require(chart.yAxis)
        #expect(y.valueDescriptionProvider(5) == "$5")
        #expect(y.valueDescriptionProvider(-95.5) == "minus $95.50")
    }
}

@MainActor
@Suite("Result screen")
struct ResultScreenTests {
    let today = LocalDate(year: 2026, month: 9, day: 27)!

    func outcome(price: Money = .dollars(700), phone: Money = .dollars(45)) -> Outcome {
        var plan = SamplePlan.make(today: today)
        if let index = plan.events.firstIndex(where: { $0.name == "Phone" }) { plan.events[index].amount = phone }
        return CashEngine.analyze(plan, purchase: Purchase(item: "laptop", price: price, date: today.adding(days: 5)), today: today)
    }

    @Test("a verdict change is announced with its headline and reading")
    func announcement() {
        #expect(ResultView.announcement(for: outcome()) == "Dips below your floor. $195 below your $200 floor.")
        #expect(ResultView.announcement(for: .needsInfo([.floor])) == "Add a few details first.")
    }

    @Test("the what-if price commits only a positive amount")
    func committedPrice() {
        #expect(WhatIfBar.committedPrice("700") == .dollars(700))
        #expect(WhatIfBar.committedPrice("49.99") == Money(cents: 4_999))
        #expect(WhatIfBar.committedPrice("0") == nil)
        #expect(WhatIfBar.committedPrice("") == nil)
        #expect(WhatIfBar.committedPrice("abc") == nil)
    }

    @Test("the ledger shows cents on every row once any row has cents")
    func ledgerCents() throws {
        guard case .analyzed(let whole) = outcome(), case .analyzed(let cents) = outcome(phone: Money(cents: 4_550)) else {
            throw CancellationError()
        }
        #expect(!Explainer.ledger(whole).showsCents)
        #expect(Explainer.ledger(cents).showsCents)
    }

    @Test("a ledger row is read as its label and a signed spoken amount")
    func ledgerRowLabel() throws {
        guard case .analyzed(let a) = outcome() else { throw CancellationError() }
        let labels = Explainer.ledger(a).rows.map(LedgerView.spokenLabel)
        #expect(labels.contains("Rent, Oct 2, minus $750"))
        #expect(labels.contains("Paycheck, Oct 1, plus $800"))
    }
}
