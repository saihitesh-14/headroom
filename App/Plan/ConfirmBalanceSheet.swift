import HeadroomCore
import SwiftUI

/// Confirm today's checking balance and say how today's scheduled items stand.
struct ConfirmBalanceSheet: View {
    @Environment(PlanStore.self) private var store
    @Environment(\.today) private var today
    @Environment(\.dismiss) private var dismiss
    @State private var amountText = ""
    @State private var billsOut: Set<UUID> = []
    @State private var incomeComing: Set<UUID> = []
    @State private var showError = false

    private var todaysEvents: [CashEvent] {
        store.plan.events.filter { !$0.schedule.occurrences(from: today, through: today).isEmpty }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    CurrencyField(label: "Balance", text: $amountText, allowsNegative: true)
                } footer: {
                    if showError {
                        Text("Enter the balance your bank shows, like 1,000 or 1000.00.")
                            .foregroundStyle(Theme.danger)
                    } else {
                        Text("Use the balance your bank shows right now.")
                    }
                }

                if !todaysEvents.isEmpty {
                    Section {
                        ForEach(todaysEvents) { event in
                            if event.kind == .bill {
                                Toggle(isOn: .member($billsOut, event.id)) {
                                    itemLabel(event, detail: "Already came out")
                                }
                            } else {
                                Toggle(isOn: .member($incomeComing, event.id)) {
                                    itemLabel(event, detail: "Still coming today")
                                }
                            }
                        }
                    } header: {
                        Text("Scheduled today")
                    } footer: {
                        Text("Unless you mark them, bills dated today are subtracted and pay dated today is not added.")
                    }
                }
            }
            .tint(Theme.accent)
            .listRowBackground(Theme.surface)
            .themedList()
            .navigationTitle("Checking balance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(role: .confirm) { confirm() }
                }
            }
            .onAppear(perform: prefill)
        }
    }

    private func itemLabel(_ event: CashEvent, detail: String) -> some View {
        VStack(alignment: .leading, spacing: Theme.Space.xs) {
            Text("\(event.name), \(event.amount.formatted)")
            Text(detail).font(.footnote).foregroundStyle(Theme.textSecondary)
        }
    }

    private func prefill() {
        guard let balance = store.plan.balance else { return }
        amountText = MoneyInput.editableText(balance.amount)
        if balance.asOf == today {
            billsOut = balance.billsAlreadyOutToday
            incomeComing = balance.incomeStillComingToday
        }
    }

    private func confirm() {
        guard let amount = MoneyInput.parseBalance(amountText) else {
            withAnimation { showError = true }
            return
        }
        let todayIDs = Set(todaysEvents.map(\.id))
        store.confirmBalance(amount, today: today,
                             billsAlreadyOut: billsOut.intersection(todayIDs),
                             incomeStillComing: incomeComing.intersection(todayIDs))
        dismiss()
    }
}
