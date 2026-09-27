/// One day of a projected checking balance.
public struct DayPoint: Hashable, Sendable {
    public struct Line: Hashable, Sendable {
        public let name: String
        /// Always positive; `isIncome` gives the direction.
        public let amount: Money
        public let isIncome: Bool
        public let isPurchase: Bool
    }

    public let date: LocalDate
    /// Balance after the day's money out, before its money in. Minimums use this.
    public let low: Money
    /// Balance at the end of the day.
    public let close: Money
    /// What moved that day: money out first, then money in.
    public let lines: [Line]
}

/// The pure cash-flow engine. Same inputs always give the same outputs.
public enum CashEngine {
    /// Purchases can be checked for today through today + 30.
    public static let purchaseRangeDays = 30
    /// Every analysis runs through today + 61 (30-day range + 31 days of lookahead).
    public static let horizonDays = 61

    /// Day-by-day checking balance from `today` through `through`, with an optional purchase.
    ///
    /// Rules:
    /// - On `today`, bills are subtracted unless marked already out, and income is
    ///   added only if marked still coming (the confirmed balance may already include it).
    /// - Within a day, money out (including the purchase) happens before money in.
    public static func project(_ plan: CashPlan, today: LocalDate, through end: LocalDate,
                               purchase: Purchase?) -> [DayPoint] {
        guard let snapshot = plan.balance, today <= end else { return [] }
        let marksApply = snapshot.asOf == today

        var outflowsByDay: [LocalDate: [DayPoint.Line]] = [:]
        var inflowsByDay: [LocalDate: [DayPoint.Line]] = [:]
        for event in plan.events {
            for date in event.schedule.occurrences(from: today, through: end) {
                let line = DayPoint.Line(name: event.name, amount: event.amount,
                                         isIncome: event.kind == .income, isPurchase: false)
                switch event.kind {
                case .bill:
                    if date == today, marksApply, snapshot.billsAlreadyOutToday.contains(event.id) { continue }
                    outflowsByDay[date, default: []].append(line)
                case .income:
                    if date == today, !(marksApply && snapshot.incomeStillComingToday.contains(event.id)) { continue }
                    inflowsByDay[date, default: []].append(line)
                }
            }
        }
        if let purchase, purchase.date >= today, purchase.date <= end {
            let line = DayPoint.Line(name: purchase.item, amount: purchase.price, isIncome: false, isPurchase: true)
            outflowsByDay[purchase.date, default: []].append(line)
        }

        var points: [DayPoint] = []
        var balance = snapshot.amount
        var date = today
        while date <= end {
            let outs = outflowsByDay[date] ?? []
            let ins = inflowsByDay[date] ?? []
            let low = outs.reduce(balance) { $0 - $1.amount }
            let close = ins.reduce(low) { $0 + $1.amount }
            points.append(DayPoint(date: date, low: low, close: close, lines: outs + ins))
            balance = close
            date = date.adding(days: 1)
        }
        return points
    }
}
