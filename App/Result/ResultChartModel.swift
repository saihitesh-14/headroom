import HeadroomCore

/// Everything the Result chart plots, taken from the engine (docs/REDESIGN-SPEC.md 6.1 and 6.2).
/// X is a day index from today; Y is whole cents. The view only places these values.
struct ResultChartModel {
    /// A day read from the chart by selection: its lines and both closes.
    struct Callout: Equatable {
        struct Line: Equatable {
            let name: String
            /// Signed: income is positive, money out is negative.
            let amount: Money
        }

        let date: LocalDate
        let lines: [Line]
        let withClose: Money
        let withoutClose: Money
    }

    let today: LocalDate
    /// The last day shown: a week past the latest date that matters.
    let windowEnd: LocalDate
    let windowDays: Int
    /// The Without line.
    let baseline: [ChartPoint]
    /// The With line once it has peeled away by the price.
    let withPurchase: [ChartPoint]
    let floor: Int
    /// Where clearance is measured from: the floor, or $0 when the verdict goes below $0.
    let datum: Int
    /// The purchase low, in cents.
    let low: Int
    /// A quarter into the day of the purchase low, where the ring sits.
    let lowX: Double
    let purchaseX: Double
    let domain: ClosedRange<Int>
    let staff: [Money]
    /// "With laptop"
    let withName: String
    /// "Without laptop"
    let withoutName: String
    /// The chart's VoiceOver value: the summary, any dates below the floor, and the horizon.
    let accessibilityValue: String

    private let withDays: [DayPoint]
    private let baseDays: [DayPoint]

    init(_ a: Analysis) {
        today = a.today
        windowEnd = Explainer.chartWindowEnd(a)
        windowDays = a.today.days(until: windowEnd)
        baseDays = Array(a.baseline.prefix(windowDays + 1))
        withDays = Array(a.withPurchase.prefix(windowDays + 1))
        baseline = ChartPath.points(baseDays)
        withPurchase = ChartPath.points(withDays)
        floor = a.floor.cents
        if case .goesNegative = a.verdict { datum = 0 } else { datum = a.floor.cents }
        low = a.purchaseLow.amount.cents
        lowX = Double(a.today.days(until: a.purchaseLow.date)) + 0.25
        purchaseX = Double(a.today.days(until: a.purchase.date))
        domain = ChartScale.domain(values: (baseline + withPurchase).map(\.amount), floor: a.floor,
                                   lowLabelBelow: a.purchaseLow.amount < a.floor, topRatio: 14)
        staff = ChartScale.staff(domain: domain)
        (withName, withoutName) = Self.seriesNames(a.purchase)
        accessibilityValue = [
            Explainer.summary(a),
            Explainer.belowFloorText(a).map { $0 + "." },
            "Checked through \(a.checkedThrough.spokenText).",
        ].compactMap { $0 }.joined(separator: " ")
    }

    /// "With laptop" and "Without laptop", using the item as it was read.
    static func seriesNames(_ purchase: Purchase) -> (with: String, without: String) {
        let item = purchase.item.isEmpty ? "purchase" : purchase.item
        return ("With \(item)", "Without \(item)")
    }

    var xDomain: ClosedRange<Double> { 0...Double(windowDays + 1) }

    /// "Floor $200" sits on the side of the datum away from the low, where the lines near
    /// the low cannot run under it: below the datum when the low stays at or above the floor.
    var floorLabelBelow: Bool { low >= floor }

    /// The fill between the With line and the floor is drawn when the With line dips below it.
    /// Before the peel it has no height, so it grows as the line peels down.
    var showsBelowFloorArea: Bool { withPurchase.contains { $0.amount.cents < floor } }

    /// The With line part way through the peel: 0 lies on the Without line, 1 is the engine's
    /// path. Positions are rounded to whole cents; only 0 and 1 are ever set, and Charts
    /// animates between them.
    func withShown(peel: Double) -> [ChartPoint] {
        zip(baseline, withPurchase).map { base, with in
            let gap = with.amount.cents - base.amount.cents
            return ChartPoint(x: base.x, amount: Money(cents: base.amount.cents + Int((Double(gap) * peel).rounded())))
        }
    }

    /// The whole day under a selected x, kept inside the window.
    func day(at x: Double) -> Int {
        min(max(Int(x.rounded(.down)), 0), windowDays)
    }

    func callout(day: Int) -> Callout {
        let with = withDays[day]
        return Callout(
            date: with.date,
            lines: with.lines.map { line in
                let name = line.isPurchase ? Self.capitalizedFirst(line.name.isEmpty ? "purchase" : line.name) : line.name
                return Callout.Line(name: name, amount: line.isIncome ? line.amount : -line.amount)
            },
            withClose: with.close,
            withoutClose: baseDays[day].close
        )
    }

    private static func capitalizedFirst(_ text: String) -> String {
        guard let first = text.first else { return text }
        return first.uppercased() + text.dropFirst()
    }
}
