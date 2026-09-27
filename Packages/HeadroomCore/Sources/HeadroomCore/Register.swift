/// One line in a running-balance register ("Coming up").
public struct RegisterEntry: Hashable, Sendable {
    public let name: String
    /// Signed: income is positive, money out is negative.
    public let amount: Money
    public let date: LocalDate
    /// The balance right after this line.
    public let balanceAfter: Money
    public let isIncome: Bool

    public init(name: String, amount: Money, date: LocalDate, balanceAfter: Money, isIncome: Bool) {
        self.name = name
        self.amount = amount
        self.date = date
        self.balanceAfter = balanceAfter
        self.isIncome = isIncome
    }
}

extension CashEngine {
    /// Every line from the first day through `through`, with the balance after each one.
    ///
    /// Lines are applied in engine order (money out, then money in). On the `through` day only
    /// money out is listed, because that day's income lands after its low, as in `Explainer.reasons`.
    public static func register(_ days: [DayPoint], through end: LocalDate) -> [RegisterEntry] {
        var balance = openingBalance(days)
        var entries: [RegisterEntry] = []
        for day in days where day.date <= end {
            let lines = day.date == end ? day.lines.filter { !$0.isIncome } : day.lines
            for line in lines {
                let signed = line.isIncome ? line.amount : -line.amount
                balance = balance + signed
                entries.append(RegisterEntry(name: line.name, amount: signed, date: day.date,
                                             balanceAfter: balance, isIncome: line.isIncome))
            }
        }
        return entries
    }

    /// Checking at the start of the first day: its low plus that day's money out. $0 for no days.
    static func openingBalance(_ days: [DayPoint]) -> Money {
        guard let first = days.first else { return .zero }
        return first.lines.filter { !$0.isIncome }.reduce(first.low) { $0 + $1.amount }
    }
}
