/// Turns an `Analysis` into plain English. Deterministic: numbers always come from the engine.
///
/// Copy rules: short sentences, no dashes as punctuation, and never "affordable",
/// "safe to spend", or "buy now".
public enum Explainer {
    /// One row in "What moves your balance".
    public struct Reason: Hashable, Sendable {
        /// "Paycheck, Sep 30" or "Groceries, 3 times"
        public let label: String
        /// Signed: income is positive, money out is negative.
        public let amount: Money
    }

    public static func headline(_ a: Analysis) -> String {
        if a.baselineLowFromPurchaseDate.amount < .zero { return "Known bills already exceed projected cash" }
        if a.baselineLowFromPurchaseDate.amount < a.floor { return "Your plan is already below your floor" }
        switch a.verdict {
        case .fits: return "Fits your cash floor"
        case .crossesFloor: return "Would cross your cash floor"
        case .goesNegative: return "Known bills exceed projected cash"
        }
    }

    public static func summary(_ a: Analysis) -> String {
        let base = a.baselineLowFromPurchaseDate
        if base.amount < a.floor {
            let gap = base.amount < .zero
                ? "which is \((-base.amount).formatted) more than you have"
                : "which is \((a.floor - base.amount).formatted) below your \(a.floor.formatted) floor"
            return "Without this purchase, your balance drops to \(base.amount.formatted) on \(base.date.shortText), "
                + "\(gap). This purchase adds \(a.purchase.price.formatted) to the shortfall."
        }
        let low = "Lowest point: \(a.purchaseLow.amount.formatted) on \(a.purchaseLow.date.shortText)."
        switch a.verdict {
        case .fits(let room) where room == .zero:
            return "\(low) That's exactly your \(a.floor.formatted) floor."
        case .fits(let room):
            return "\(low) That's \(room.formatted) above your \(a.floor.formatted) floor."
        case .crossesFloor(let by):
            return "\(low) That's \(by.formatted) below your \(a.floor.formatted) floor."
        case .goesNegative(let by):
            return "\(low) Your known bills would be \(by.formatted) more than your projected cash."
        }
    }

    /// Money in and out from today to the lowest point, grouped by name, largest first (max 5).
    public static func reasons(_ a: Analysis) -> [Reason] {
        struct Group { var label: String; var total: Money; var count: Int; var firstDate: LocalDate; var order: Int }
        var groups: [String: Group] = [:]
        var order = 0
        for point in a.withPurchase where point.date <= a.purchaseLow.date {
            // On the day of the low, money in lands after the low, so it did not move the balance there.
            let lines = point.date == a.purchaseLow.date ? point.lines.filter { !$0.isIncome } : point.lines
            for line in lines {
                let name = line.isPurchase ? capitalizedFirst(line.name) : line.name
                let key = "\(line.isPurchase)|\(line.isIncome)|\(name)"
                let signed = line.isIncome ? line.amount : -line.amount
                if var group = groups[key] {
                    group.total = group.total + signed
                    group.count += 1
                    groups[key] = group
                } else {
                    groups[key] = Group(label: name, total: signed, count: 1, firstDate: point.date, order: order)
                    order += 1
                }
            }
        }
        return groups.values
            .sorted { lhs, rhs in
                lhs.total.cents.magnitude != rhs.total.cents.magnitude
                    ? lhs.total.cents.magnitude > rhs.total.cents.magnitude
                    : lhs.order < rhs.order
            }
            .prefix(5)
            .map { group in
                let when = group.count == 1 ? group.firstDate.monthDayText : "\(group.count) times"
                return Reason(label: "\(group.label), \(when)", amount: group.total)
            }
    }

    /// The first income on or after the lowest point (same-day pay lands after the low).
    public static func nextIncomeText(_ a: Analysis) -> String {
        for point in a.withPurchase where point.date >= a.purchaseLow.date {
            if let line = point.lines.first(where: \.isIncome) {
                return "Next income: \(line.name) +\(line.amount.formatted) on \(point.date.shortText)"
            }
        }
        return "No income in your plan through \(a.checkedThrough.shortText)"
    }

    /// A dip below the floor (or zero) that happens before the purchase date, which the
    /// verdict alone would not mention. nil when there is none, or when the headline
    /// already says the plan is short from the purchase date on.
    public static func baselineWarningText(_ a: Analysis) -> String? {
        guard let warning = a.baselineWarning, a.baselineLowFromPurchaseDate.amount >= a.floor else { return nil }
        switch warning {
        case .negative(let low) where low.date < a.purchase.date:
            return "Before this purchase, your plan goes to \(low.amount.formatted) on \(low.date.shortText)."
        case .belowFloor(let low) where low.date < a.purchase.date:
            return "Before this purchase, your plan drops to \(low.amount.formatted) on \(low.date.shortText), "
                + "below your \(a.floor.formatted) floor."
        default:
            return nil
        }
    }

    /// Value for the "Earliest date that fits" row.
    public static func earliestFitValue(_ a: Analysis) -> String {
        switch a.earliestFit {
        case .on(let date): return date == a.today ? "Today" : date.shortText
        case .none: return "None by \(a.today.adding(days: CashEngine.purchaseRangeDays).shortText)"
        }
    }

    /// Why no date fits, or nil when one does.
    public static func earliestFitNote(_ a: Analysis) -> String? {
        switch a.earliestFit {
        case .on: return nil
        case .none(.planAlreadyShort): return "Your plan dips below your floor even without this purchase."
        case .none(.notEnoughRoom): return "No date in the next 30 days leaves room for \(a.purchase.price.formatted)."
        }
    }

    public static func text(for missing: MissingInfo) -> String {
        switch missing {
        case .balance:
            return "Add your checking balance."
        case .balanceNotConfirmedToday(let last):
            return "Confirm your checking balance for today. Last confirmed \(last.shortText)."
        case .floor:
            return "Choose a cash floor, the lowest balance you want to keep. $0 is fine."
        case .noEvents:
            return "Add at least one paycheck or bill."
        case .invalidPrice:
            return "Enter a price between $0.01 and \(Money.maximum.formatted)."
        case .dateInPast:
            return "Pick today or a later date."
        case .dateBeyondRange(let latest):
            return "Pick a date on or before \(latest.shortText). Headroom checks purchases up to 30 days out."
        }
    }

    /// How the numbers are calculated, in plain English.
    public static let assumptions: [String] = [
        "Bills and paychecks happen on the dates in your plan.",
        "On any day, money out is counted before money in, so a purchase on payday is checked before the pay lands.",
        "For items dated today, bills are subtracted and pay is not added, unless you marked them when you confirmed your balance.",
        "Every purchase date is checked through the same end date, 61 days from today, so next month's bills are always included.",
        "This is an estimate from the plan you entered, not a guarantee.",
    ]

    private static func capitalizedFirst(_ text: String) -> String {
        guard let first = text.first else { return text }
        return first.uppercased() + text.dropFirst()
    }
}
