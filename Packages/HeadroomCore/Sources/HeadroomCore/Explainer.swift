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

    /// The gap the clearance mark measures, with its unit words ("$195" + "below your $200 floor").
    public struct Reading: Hashable, Sendable {
        public enum Kind: Hashable, Sendable {
            /// The low is at or above the floor.
            case above
            /// The low is below the floor and at or above $0.
            case below
            /// The low is below $0; the gap is measured to $0.
            case belowZero
        }

        /// Never negative.
        public let amount: Money
        public let words: String
        public let kind: Kind
    }

    /// "What moves your balance": from today's balance, through the grouped movements, to the low.
    /// `start` plus every row plus `remainder` equals `end.amount`.
    public struct Ledger: Hashable, Sendable {
        /// Checking today, before anything scheduled today.
        public let start: Money
        /// The same rows as `reasons`, largest first (max 5).
        public let rows: [Reason]
        /// "Everything else, N items" when there are more than 5 groups.
        public let remainder: Reason?
        /// The lowest point with the purchase.
        public let end: Low
    }

    public static func headline(_ a: Analysis) -> String {
        if a.baselineLowFromPurchaseDate.amount < .zero { return "Checking already goes below $0" }
        if a.baselineLowFromPurchaseDate.amount < a.floor { return "Already dips below your floor" }
        switch a.verdict {
        case .fits(let room) where room == .zero: return "Stays at your floor"
        case .fits: return "Stays above your floor"
        case .crossesFloor: return "Dips below your floor"
        case .goesNegative: return "Takes checking below $0"
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
            return "\(low) That's \(by.formatted) below $0."
        }
    }

    /// Money in and out from today to the lowest point, grouped by name, largest first (max 5).
    public static func reasons(_ a: Analysis) -> [Reason] {
        groupedMovements(a).prefix(5).map(\.reason)
    }

    /// One name's movements from today to the lowest point.
    private struct MovementGroup {
        var label: String
        var total: Money
        var count: Int
        var firstDate: LocalDate
        var order: Int

        var reason: Reason {
            let when = count == 1 ? firstDate.monthDayText : "\(count) times"
            return Reason(label: "\(label), \(when)", amount: total)
        }
    }

    /// Every movement from today to the lowest point, grouped by name, largest first.
    private static func groupedMovements(_ a: Analysis) -> [MovementGroup] {
        var groups: [String: MovementGroup] = [:]
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
                    groups[key] = MovementGroup(label: name, total: signed, count: 1, firstDate: point.date, order: order)
                    order += 1
                }
            }
        }
        return groups.values.sorted { lhs, rhs in
            lhs.total.cents.magnitude != rhs.total.cents.magnitude
                ? lhs.total.cents.magnitude > rhs.total.cents.magnitude
                : lhs.order < rhs.order
        }
    }

    /// The whole ledger: today's balance, the grouped rows, anything past the fifth group, and the low.
    public static func ledger(_ a: Analysis) -> Ledger {
        let groups = groupedMovements(a)
        let rest = groups.dropFirst(5)
        var remainder: Reason?
        if !rest.isEmpty {
            let items = rest.reduce(0) { $0 + $1.count }
            let total = rest.reduce(Money.zero) { $0 + $1.total }
            remainder = Reason(label: "Everything else, \(items) \(items == 1 ? "item" : "items")", amount: total)
        }
        return Ledger(start: CashEngine.openingBalance(a.withPurchase), rows: groups.prefix(5).map(\.reason),
                      remainder: remainder, end: a.purchaseLow)
    }

    /// "What moves your balance by Tue Oct 13"
    public static func ledgerHeading(_ a: Analysis) -> String {
        "What moves your balance by \(a.purchaseLow.date.shortTextNoBreak)"
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
            return "Before this purchase, your balance drops to \(low.amount.displayText) on \(low.date.shortText)."
        case .belowFloor(let low) where low.date < a.purchase.date:
            return "Before this purchase, your balance drops to \(low.amount.displayText) on \(low.date.shortText), "
                + "below your \(a.floor.displayText) floor."
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

    // MARK: Result readings

    /// The clearance the mark measures: from the purchase low to the floor, or to $0 below zero.
    public static func reading(_ a: Analysis) -> Reading {
        let floorWords = "your \(a.floor.displayText) floor"
        switch a.verdict {
        case .fits(let room): return Reading(amount: room, words: "above \(floorWords)", kind: .above)
        case .crossesFloor(let by): return Reading(amount: by, words: "below \(floorWords)", kind: .below)
        case .goesNegative(let by): return Reading(amount: by, words: "below $0", kind: .belowZero)
        }
    }

    /// The plain sentence under the verdict, naming the balance at the low.
    /// A plan already short from the purchase date on keeps `summary`, which says so.
    public static func purchaseSentence(_ a: Analysis) -> String {
        if a.baselineLowFromPurchaseDate.amount < a.floor { return summary(a) }
        let spend = "Spending \(purchaseLine(a.purchase))"
        let low = "\(a.purchaseLow.amount.displayText) on \(a.purchaseLow.date.shortTextNoBreak)"
        switch a.verdict {
        case .fits: return "\(spend) leaves checking at \(low), its lowest point."
        case .crossesFloor, .goesNegative: return "\(spend) takes checking down to \(low)."
        }
    }

    /// "$700 on Fri Oct 2"
    public static func purchaseLine(_ p: Purchase) -> String {
        "\(p.price.displayText) on \(p.date.shortTextNoBreak)"
    }

    /// "Laptop, Oct 2", the purchase rule's label.
    public static func purchaseMarker(_ p: Purchase) -> String {
        "\(p.item.isEmpty ? "Purchase" : capitalizedFirst(p.item)), \(p.date.monthDayText)"
    }

    /// "$5, Oct 13", the label beside the ring at the purchase low.
    public static func lowMarker(_ a: Analysis) -> String {
        "\(a.purchaseLow.amount.displayText), \(a.purchaseLow.date.monthDayText)"
    }

    /// The date for the "Try" button: nil when the purchase already fits, when no date fits,
    /// or when the earliest fit is the purchase date itself.
    public static func earliestFitDate(_ a: Analysis) -> LocalDate? {
        if case .fits = a.verdict { return nil }
        guard case .on(let date) = a.earliestFit, date != a.purchase.date else { return nil }
        return date
    }

    /// "Try Fri Oct 16", or "Try today".
    public static func tryLabel(_ date: LocalDate, today: LocalDate) -> String {
        date == today ? "Try today" : "Try \(date.shortTextNoBreak)"
    }

    // MARK: Chart

    /// Runs of days whose low is below the floor, in date order.
    public static func belowFloorSpans(_ days: [DayPoint], floor: Money) -> [ClosedRange<LocalDate>] {
        var spans: [ClosedRange<LocalDate>] = []
        var start: LocalDate?
        var last: LocalDate?
        for day in days {
            if day.low < floor {
                if start == nil { start = day.date }
                last = day.date
            } else if let first = start, let end = last {
                spans.append(first...end)
                start = nil
            }
        }
        if let first = start, let end = last { spans.append(first...end) }
        return spans
    }

    /// "Below your floor Tue Oct 6 to Thu Oct 15", over the whole horizon with the purchase.
    /// One day reads "on Tue Oct 6"; several spans are joined with ", and ". nil when there is none.
    public static func belowFloorText(_ a: Analysis) -> String? {
        let spans = belowFloorSpans(a.withPurchase, floor: a.floor)
        guard !spans.isEmpty else { return nil }
        let parts = spans.map { span in
            span.lowerBound == span.upperBound
                ? "on \(span.lowerBound.shortTextNoBreak)"
                : "\(span.lowerBound.shortTextNoBreak) to \(span.upperBound.shortTextNoBreak)"
        }
        return "Below your floor " + parts.joined(separator: ", and ")
    }

    /// The last day the Result chart shows. It always contains the purchase date, both lows,
    /// and the "Try" date when that button shows.
    public static func chartWindowEnd(_ a: Analysis) -> LocalDate {
        var including = [a.purchase.date, a.purchaseLow.date, a.baselineLow.date]
        if let fit = earliestFitDate(a) { including.append(fit) }
        return ChartWindow.end(today: a.today, horizon: a.checkedThrough, including: including)
    }

    /// "Checked through Fri Nov 27. The lowest point is in view."
    public static func chartCaption(_ a: Analysis) -> String {
        "Checked through \(a.checkedThrough.shortTextNoBreak). The lowest point is in view."
    }

    // MARK: Home screen

    /// The line under the spending room.
    public static func roomCaption(_ d: RoomDetail) -> String {
        let floor = d.floor.displayText
        let date = d.low.date.shortTextNoBreak
        if d.low.amount < .zero {
            return "Your balance already goes below $0 on \(date), before any purchase."
        }
        if d.low.amount < d.floor {
            return "Your balance already dips below your \(floor) floor on \(date), before any purchase."
        }
        if d.low.amount == d.floor {
            return "Your balance reaches your \(floor) floor on \(date), so there is no room to spend today."
        }
        return "Spend up to this today and stay at or above your \(floor) floor through \(d.through.shortTextNoBreak)."
    }

    /// The home gauge in words, for VoiceOver.
    public static func roomSummary(_ d: RoomDetail) -> String {
        let floor = d.floor.displayText
        let position: String
        if d.low.amount < .zero {
            position = "which is \((-d.low.amount).displayText) below $0"
        } else if d.low.amount < d.floor {
            position = "which is \((d.floor - d.low.amount).displayText) below your \(floor) floor"
        } else if d.low.amount == d.floor {
            position = "which is exactly your \(floor) floor"
        } else {
            position = "which is \((d.low.amount - d.floor).displayText) above your \(floor) floor"
        }
        return "Starts at \(d.start.displayText) today. "
            + "Lowest \(d.low.amount.displayText) on \(d.low.date.shortTextNoBreak), \(position). "
            + "Checked through \(d.through.shortTextNoBreak)."
    }

    // MARK: Missing inputs

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
