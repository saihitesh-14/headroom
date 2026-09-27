import HeadroomCore

/// A realistic student plan for demos, screenshots, and the UI test.
/// Built relative to `today`, so it is always confirmed and never stale.
enum SamplePlan {
    static func make(today: LocalDate) -> CashPlan {
        CashPlan(
            balance: BalanceSnapshot(amount: .dollars(1_000), asOf: today),
            floor: .dollars(200),
            events: [
                CashEvent(name: "Paycheck", amount: .dollars(800), kind: .income,
                          schedule: .everyTwoWeeks(from: today.adding(days: 4))),
                CashEvent(name: "Rent", amount: .dollars(750), kind: .bill,
                          schedule: .monthly(day: today.adding(days: 5).day)),
                CashEvent(name: "Phone", amount: .dollars(45), kind: .bill,
                          schedule: .monthly(day: today.adding(days: 12).day)),
                CashEvent(name: "Streaming", amount: .dollars(12), kind: .bill,
                          schedule: .monthly(day: today.adding(days: 20).day)),
                CashEvent(name: "Groceries", amount: .dollars(100), kind: .bill,
                          schedule: .weekly(from: today.adding(days: 2))),
            ]
        )
    }
}
