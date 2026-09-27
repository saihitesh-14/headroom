import Foundation   // UUID only. Engine logic never uses Date, Calendar, or TimeZone.

/// A paycheck or a bill.
public struct CashEvent: Codable, Hashable, Identifiable, Sendable {
    public enum Kind: String, Codable, Sendable { case income, bill }

    public var id: UUID
    public var name: String
    /// Always positive; `kind` gives the direction.
    public var amount: Money
    public var kind: Kind
    public var schedule: Schedule

    public init(id: UUID = UUID(), name: String, amount: Money, kind: Kind, schedule: Schedule) {
        self.id = id
        self.name = name
        self.amount = amount
        self.kind = kind
        self.schedule = schedule
    }
}

/// The checking balance the user confirmed, and on which day.
public struct BalanceSnapshot: Hashable, Sendable {
    public var amount: Money
    public var asOf: LocalDate
    /// Bills scheduled on `asOf` that are already reflected in `amount`.
    public var billsAlreadyOutToday: Set<UUID>
    /// Income scheduled on `asOf` that is not in `amount` yet but will arrive that day.
    public var incomeStillComingToday: Set<UUID>

    public init(amount: Money, asOf: LocalDate,
                billsAlreadyOutToday: Set<UUID> = [], incomeStillComingToday: Set<UUID> = []) {
        self.amount = amount
        self.asOf = asOf
        self.billsAlreadyOutToday = billsAlreadyOutToday
        self.incomeStillComingToday = incomeStillComingToday
    }
}

extension BalanceSnapshot: Codable {
    private enum CodingKeys: String, CodingKey { case amount, asOf, billsAlreadyOutToday, incomeStillComingToday }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        amount = try c.decode(Money.self, forKey: .amount)
        asOf = try c.decode(LocalDate.self, forKey: .asOf)
        billsAlreadyOutToday = try c.decodeIfPresent(Set<UUID>.self, forKey: .billsAlreadyOutToday) ?? []
        incomeStillComingToday = try c.decodeIfPresent(Set<UUID>.self, forKey: .incomeStillComingToday) ?? []
    }
}

/// Everything the user entered about their money.
public struct CashPlan: Codable, Hashable, Sendable {
    public var balance: BalanceSnapshot?
    /// The lowest checking balance the user wants to keep. nil means "not chosen yet".
    public var floor: Money?
    public var events: [CashEvent]

    public init(balance: BalanceSnapshot? = nil, floor: Money? = nil, events: [CashEvent] = []) {
        self.balance = balance
        self.floor = floor
        self.events = events
    }
}

/// The purchase being considered. Always paid from checking.
public struct Purchase: Codable, Hashable, Sendable {
    public var item: String
    public var price: Money
    public var date: LocalDate

    public init(item: String, price: Money, date: LocalDate) {
        self.item = item
        self.price = price
        self.date = date
    }
}
