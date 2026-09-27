/// The lowest balance in a range and the first day it happens.
public struct Low: Hashable, Sendable {
    public let amount: Money
    public let date: LocalDate

    public init(amount: Money, date: LocalDate) {
        self.amount = amount
        self.date = date
    }
}

/// Something the engine needs before it can give an answer.
public enum MissingInfo: Hashable, Sendable {
    case balance
    case balanceNotConfirmedToday(lastConfirmed: LocalDate)
    case floor
    case noEvents
    case invalidPrice
    case dateInPast
    case dateBeyondRange(latest: LocalDate)
}

public enum Verdict: Hashable, Sendable {
    case fits(room: Money)
    case crossesFloor(by: Money)
    case goesNegative(by: Money)
}

/// The plan dips below the floor (or zero) even without the purchase.
public enum BaselineWarning: Hashable, Sendable {
    case belowFloor(Low)
    case negative(Low)
}

public enum EarliestFit: Hashable, Sendable {
    public enum NoFitReason: Hashable, Sendable {
        /// Even without the purchase, the plan is below the floor late in the range.
        case planAlreadyShort
        /// The plan is fine, but no date leaves enough room for this price.
        case notEnoughRoom
    }

    case on(LocalDate)
    case none(NoFitReason)
}

public struct Analysis: Sendable {
    public let purchase: Purchase
    public let floor: Money
    public let today: LocalDate
    public let verdict: Verdict
    /// today + 61, the same for every purchase date.
    public let checkedThrough: LocalDate
    public let baseline: [DayPoint]
    public let withPurchase: [DayPoint]
    /// Lowest point without the purchase, today through the horizon.
    public let baselineLow: Low
    /// Lowest point without the purchase, from the purchase date through the horizon.
    public let baselineLowFromPurchaseDate: Low
    /// Lowest point with the purchase, from the purchase date through the horizon.
    public let purchaseLow: Low
    public let baselineWarning: BaselineWarning?
    public let spendingRoomToday: Money
    public let earliestFit: EarliestFit
}

public enum Outcome: Sendable {
    case needsInfo([MissingInfo])
    case analyzed(Analysis)
}

public enum RoomOutcome: Hashable, Sendable {
    case needsInfo([MissingInfo])
    case room(Money, through: LocalDate)
}

extension CashEngine {
    /// What happens to checking if `purchase` is made on its date.
    public static func analyze(_ plan: CashPlan, purchase: Purchase, today: LocalDate) -> Outcome {
        var missing = planMissing(plan, today: today)
        if purchase.price <= .zero || purchase.price > .maximum { missing.append(.invalidPrice) }
        let latest = today.adding(days: purchaseRangeDays)
        if purchase.date < today {
            missing.append(.dateInPast)
        } else if purchase.date > latest {
            missing.append(.dateBeyondRange(latest: latest))
        }
        guard missing.isEmpty, let floor = plan.floor else { return .needsInfo(missing) }

        let horizon = today.adding(days: horizonDays)
        let baseline = project(plan, today: today, through: horizon, purchase: nil)
        let withPurchase = project(plan, today: today, through: horizon, purchase: purchase)
        let baselineLow = lowest(baseline)
        let baselineLowFromDate = lowest(baseline.filter { $0.date >= purchase.date })
        let purchaseLow = lowest(withPurchase.filter { $0.date >= purchase.date })

        return .analyzed(Analysis(
            purchase: purchase,
            floor: floor,
            today: today,
            verdict: verdict(low: purchaseLow.amount, floor: floor),
            checkedThrough: horizon,
            baseline: baseline,
            withPurchase: withPurchase,
            baselineLow: baselineLow,
            baselineLowFromPurchaseDate: baselineLowFromDate,
            purchaseLow: purchaseLow,
            baselineWarning: warning(for: baselineLow, floor: floor),
            spendingRoomToday: max(.zero, baselineLow.amount - floor),
            earliestFit: earliestFit(baseline: baseline, price: purchase.price, floor: floor, today: today)
        ))
    }

    /// How much could be spent today without going below the floor through the horizon.
    public static func spendingRoom(_ plan: CashPlan, today: LocalDate) -> RoomOutcome {
        let missing = planMissing(plan, today: today)
        guard missing.isEmpty, let floor = plan.floor else { return .needsInfo(missing) }
        let horizon = today.adding(days: horizonDays)
        let low = lowest(project(plan, today: today, through: horizon, purchase: nil))
        return .room(max(.zero, low.amount - floor), through: horizon)
    }

    private static func planMissing(_ plan: CashPlan, today: LocalDate) -> [MissingInfo] {
        var missing: [MissingInfo] = []
        if let balance = plan.balance {
            if balance.asOf != today { missing.append(.balanceNotConfirmedToday(lastConfirmed: balance.asOf)) }
        } else {
            missing.append(.balance)
        }
        if plan.floor == nil { missing.append(.floor) }
        if plan.events.isEmpty { missing.append(.noEvents) }
        return missing
    }

    private static func verdict(low: Money, floor: Money) -> Verdict {
        if low < .zero { return .goesNegative(by: -low) }
        if low < floor { return .crossesFloor(by: floor - low) }
        return .fits(room: low - floor)
    }

    private static func warning(for low: Low, floor: Money) -> BaselineWarning? {
        if low.amount < .zero { return .negative(low) }
        if low.amount < floor { return .belowFloor(low) }
        return nil
    }

    /// First day that reaches the minimum `low`. `points` is never empty here.
    private static func lowest(_ points: [DayPoint]) -> Low {
        var best = points[0]
        for point in points.dropFirst() where point.low < best.low { best = point }
        return Low(amount: best.low, date: best.date)
    }

    /// On and after the purchase date, the balance is the baseline minus the price,
    /// so a date fits when the lowest baseline point from that date on covers price + floor.
    private static func earliestFit(baseline: [DayPoint], price: Money, floor: Money, today: LocalDate) -> EarliestFit {
        var suffixLow = Array(repeating: Money.zero, count: baseline.count)
        var running = baseline[baseline.count - 1].low
        for index in stride(from: baseline.count - 1, through: 0, by: -1) {
            running = min(running, baseline[index].low)
            suffixLow[index] = running
        }
        for offset in 0...purchaseRangeDays where suffixLow[offset] - price >= floor {
            return .on(today.adding(days: offset))
        }
        return .none(suffixLow[purchaseRangeDays] < floor ? .planAlreadyShort : .notEnoughRoom)
    }
}
