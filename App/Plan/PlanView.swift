import HeadroomCore
import SwiftUI

/// Everything the engine knows: balance, floor, income, and bills.
struct PlanView: View {
    @Environment(PlanStore.self) private var store
    @Environment(\.today) private var today
    @State private var draft: EventDraft?
    @State private var editingBalance = false
    @State private var editingFloor = false

    private var income: [CashEvent] { store.plan.events.filter { $0.kind == .income } }
    private var bills: [CashEvent] { store.plan.events.filter { $0.kind == .bill } }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button { editingBalance = true } label: { balanceRow }
                } header: {
                    Text("Checking")
                }

                Section {
                    Button { editingFloor = true } label: { floorRow }
                } header: {
                    Text("Cash floor")
                } footer: {
                    Text("The lowest balance you want to keep. $0 is fine.")
                }

                Section("Income") {
                    ForEach(income) { eventRow($0) }
                    addButton("Add income", kind: .income)
                }

                Section {
                    ForEach(bills) { eventRow($0) }
                    addButton("Add bill", kind: .bill)
                } header: {
                    Text("Bills")
                } footer: {
                    Text("Include a weekly amount for groceries and transport.")
                }
            }
            .listRowBackground(Theme.surface)
            .themedList()
            .navigationTitle("Plan")
            .sheet(item: $draft) { EventEditor(draft: $0) }
            .sheet(isPresented: $editingBalance) { ConfirmBalanceSheet() }
            .sheet(isPresented: $editingFloor) { FloorSheet() }
        }
    }

    private var balanceRow: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: Theme.Space.xs) {
                Text("Balance").foregroundStyle(Theme.textPrimary)
                Text(balanceStatus)
                    .font(.footnote)
                    .foregroundStyle(isStale ? Theme.warning : Theme.textSecondary)
            }
            Spacer()
            if let balance = store.plan.balance {
                MoneyText(money: balance.amount)
                    .foregroundStyle(Theme.textPrimary)
            } else {
                Text("Add").foregroundStyle(Theme.accent)
            }
        }
    }

    private var isStale: Bool {
        guard let balance = store.plan.balance else { return false }
        return balance.asOf != today
    }

    private var balanceStatus: String {
        guard let balance = store.plan.balance else { return "Not added yet" }
        return balance.asOf == today ? "Confirmed today" : "Last confirmed \(balance.asOf.shortText)"
    }

    private var floorRow: some View {
        HStack {
            Text("Keep at least").foregroundStyle(Theme.textPrimary)
            Spacer()
            if let floor = store.plan.floor {
                MoneyText(money: floor).foregroundStyle(Theme.textPrimary)
            } else {
                Text("Choose").foregroundStyle(Theme.accent)
            }
        }
    }

    private func eventRow(_ event: CashEvent) -> some View {
        Button {
            draft = EventDraft(event: event, today: today)
        } label: {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: Theme.Space.xs) {
                    Text(event.name).foregroundStyle(Theme.textPrimary)
                    Text(ScheduleText.describe(event.schedule, today: today))
                        .font(.footnote)
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                MoneyText(money: event.kind == .income ? event.amount : -event.amount, signed: true)
                    .foregroundStyle(event.kind == .income ? Theme.accent : Theme.textPrimary)
            }
        }
        .swipeActions {
            Button("Delete", role: .destructive) { store.delete(eventID: event.id) }
        }
    }

    private func addButton(_ title: String, kind: CashEvent.Kind) -> some View {
        Button {
            draft = EventDraft(newOf: kind, today: today)
        } label: {
            Label(title, systemImage: "plus")
        }
    }
}
