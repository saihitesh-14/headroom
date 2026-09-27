/// One vertex of a drawn balance path. `x` is a day index from today (day i runs from i to i + 1),
/// so charts never touch `Date`, time zones, or daylight saving.
public struct ChartPoint: Hashable, Sendable {
    public let x: Double
    public let amount: Money

    public init(x: Double, amount: Money) {
        self.x = x
        self.amount = amount
    }
}

public enum ChartPath {
    /// For day index i: `(i, low)` then `(i + 0.5, close)`, then `(n, last.close)` after the last day.
    ///
    /// Drawn as steps, money out shows at the start of its day and money in halfway through, so the
    /// drawn minimum is exactly the engine's `low` and the last day draws a run, not a spike.
    /// Paths of the same length always share the same x values.
    public static func points(_ days: [DayPoint]) -> [ChartPoint] {
        guard let last = days.last else { return [] }
        var points: [ChartPoint] = []
        points.reserveCapacity(days.count * 2 + 1)
        for (index, day) in days.enumerated() {
            points.append(ChartPoint(x: Double(index), amount: day.low))
            points.append(ChartPoint(x: Double(index) + 0.5, amount: day.close))
        }
        points.append(ChartPoint(x: Double(days.count), amount: last.close))
        return points
    }
}

public enum ChartWindow {
    /// The last day a chart shows: a week past the latest date that matters, at least 21 days
    /// from today, and never past the horizon.
    public static func end(today: LocalDate, horizon: LocalDate, including dates: [LocalDate]) -> LocalDate {
        let latest = dates.max() ?? today
        return min(horizon, max(today.adding(days: 20), latest.adding(days: 7)))
    }
}

public enum ChartScale {
    /// The Y domain in cents. Always includes the floor and $0, with room below for the low's
    /// label (`lowLabelBelow`) and `topRatio` percent of the range above.
    public static func domain(values: [Money], floor: Money, lowLabelBelow: Bool, topRatio: Int) -> ClosedRange<Int> {
        let cents = values.map(\.cents)
        let lo = min(cents.min() ?? 0, floor.cents, 0)
        let hi = max(cents.max() ?? floor.cents, floor.cents)
        let range = max(hi - lo, 10_000)
        let bottom = lowLabelBelow ? max(range * 16 / 100, 10_000) : max(range * 6 / 100, 5_000)
        let top = max(range * topRatio / 100, 5_000)
        return (lo - bottom)...(hi + top)
    }

    /// Y axis values: every multiple of the finest step ($50, $100, $200, $250, $500, $1,000, ...)
    /// that leaves at most 4 intervals (5 values) inside `domain`. Includes $0 when the domain does.
    public static func staff(domain: ClosedRange<Int>) -> [Money] {
        for step in steps {
            let first = ceilDiv(domain.lowerBound, step)
            let last = floorDiv(domain.upperBound, step)
            if last - first + 1 <= 5 {
                return first > last ? [] : (first...last).map { Money(cents: $0 * step) }
            }
        }
        return []
    }

    /// Today, every first of the month inside the range, and `end`. A month start closer than
    /// 3 days to today or to `end` is dropped so labels never collide.
    public static func dayMarks(today: LocalDate, end: LocalDate) -> [LocalDate] {
        var marks = [today]
        var monthStart = nextMonthStart(after: today)
        while monthStart < end {
            if today.days(until: monthStart) >= 3, monthStart.days(until: end) >= 3 {
                marks.append(monthStart)
            }
            monthStart = nextMonthStart(after: monthStart)
        }
        if end > today { marks.append(end) }
        return marks
    }

    /// $50, then 1, 2, 2.5 and 5 times each power of ten from $100, in cents.
    private static let steps: [Int] = {
        var steps = [5_000]
        var power = 10_000
        while power <= 1_000_000_000_000_000 {
            steps += [power, power * 2, power * 5 / 2, power * 5]
            power *= 10
        }
        return steps
    }()

    private static func floorDiv(_ value: Int, _ divisor: Int) -> Int {
        (value - floorMod(value, divisor)) / divisor
    }

    private static func ceilDiv(_ value: Int, _ divisor: Int) -> Int {
        -floorDiv(-value, divisor)
    }

    private static func nextMonthStart(after date: LocalDate) -> LocalDate {
        date.month == 12
            ? LocalDate(year: date.year + 1, month: 1, day: 1)!
            : LocalDate(year: date.year, month: date.month + 1, day: 1)!
    }
}
