import HeadroomCore
import SwiftUI

/// Everything the engine knows (docs/REDESIGN-SPEC.md 5.4): checking (balance and floor),
/// income, and bills, as native inset rows on Paper.
struct PlanView: View {
    @Environment(PlanStore.self) private var store
    @Environment(\.today) private var today
    @Environment(\.dynamicTypeSize) private var size
    @State private var draft: EventDraft?
    @State private var editingBalance = false
    @State private var editingFloor = false

    private var income: [CashEvent] { store.plan.events.filter { $0.kind == .income } }
    private var bills: [CashEvent] { store.plan.events.filter { $0.kind == .bill } }

    /// The amounts form one trailing column: if any has cents, all show cents.
    private var forceCents: Bool {
        let amounts = [store.plan.balance?.amount, store.plan.floor].compactMap { $0 } + store.plan.events.map(\.amount)
        return amounts.contains { $0.cents % 100 != 0 }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button { editingBalance = true } label: { balanceRow }
                    Button { editingFloor = true } label: { floorRow }
                } header: {
                    Text("Checking").sectionText()
                } footer: {
                    VStack(alignment: .leading, spacing: Theme.Space.xs) {
                        if store.saveFailed {
                            Label("Your last change was not saved. Make it again.", systemImage: "exclamationmark.circle")
                                .foregroundStyle(Theme.danger)
                        }
                        Text("The lowest balance you want to keep. $0 is fine.")
                            .sectionText()
                    }
                }

                Section {
                    ForEach(income) { eventRow($0) }
                    addButton("Add income", kind: .income)
                } header: {
                    Text("Income").sectionText()
                }

                Section {
                    ForEach(bills) { eventRow($0) }
                    addButton("Add bill", kind: .bill)
                } header: {
                    Text("Bills").sectionText()
                } footer: {
                    Text("Include a weekly amount for groceries and transport.").sectionText()
                }
            }
            .themedList()
            .navigationTitle("Plan")
            .sheet(item: $draft) { EventEditor(draft: $0) }
            .sheet(isPresented: $editingBalance) { ConfirmBalanceSheet() }
            .sheet(isPresented: $editingFloor) { FloorSheet() }
        }
    }

    private var balanceRow: some View {
        row("Balance") {
            if let balance = store.plan.balance, balance.asOf != today {
                Label("Last confirmed \(balance.asOf.shortTextNoBreak)", systemImage: "clock")
                    .foregroundStyle(Theme.warning)
            } else {
                Text(store.plan.balance == nil ? "Not added yet" : "Confirmed today")
                    .foregroundStyle(Theme.textSecondary)
            }
        } value: {
            if let balance = store.plan.balance {
                MoneyText(money: balance.amount, forceCents: forceCents)
                    .foregroundStyle(Theme.textPrimary)
            } else {
                Text("Add").foregroundStyle(Theme.accent)
            }
        }
    }

    private var floorRow: some View {
        row("Floor") {
            Text("Keep at least this much")
                .foregroundStyle(Theme.textSecondary)
        } value: {
            if let floor = store.plan.floor {
                MoneyText(money: floor, forceCents: forceCents)
                    .foregroundStyle(Theme.textPrimary)
            } else {
                Text("Choose").foregroundStyle(Theme.accent)
            }
        }
    }

    private func eventRow(_ event: CashEvent) -> some View {
        Button {
            draft = EventDraft(event: event, today: today)
        } label: {
            row(event.name) {
                Text(ScheduleText.describe(event.schedule, today: today))
                    .foregroundStyle(Theme.textSecondary)
            } value: {
                // Income is Ink with a "+", never the accent.
                MoneyText(money: event.kind == .income ? event.amount : -event.amount, signed: true,
                          forceCents: forceCents)
                    .foregroundStyle(Theme.textPrimary)
            }
        }
        .swipeActions {
            Button("Delete", role: .destructive) { store.delete(eventID: event.id) }
        }
    }

    /// A label over its meta line, the value in a trailing column, and a chevron. At
    /// accessibility sizes the value moves under the label.
    private func row<Meta: View, Value: View>(_ title: String, @ViewBuilder meta: () -> Meta,
                                              @ViewBuilder value: () -> Value) -> some View {
        let stacked = size.isAccessibilitySize
        let layout = stacked
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Theme.Space.xs))
            : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: Theme.Space.s))
        return HStack(alignment: .firstTextBaseline, spacing: Theme.Space.s) {
            layout {
                VStack(alignment: .leading, spacing: Theme.Space.xs) {
                    Text(title).foregroundStyle(Theme.textPrimary)
                    meta().font(.footnote)
                }
                if !stacked { Spacer(minLength: Theme.Space.s) }
                value()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            // The system's gray, as on a navigation row; `.tertiary` inside a Button would be tinted.
            Image(systemName: "chevron.forward")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Color(uiColor: .tertiaryLabel))
                .accessibilityHidden(true)
        }
        .contentShape(.rect)
    }

    private func addButton(_ title: String, kind: CashEvent.Kind) -> some View {
        Button {
            draft = EventDraft(newOf: kind, today: today)
        } label: {
            Label(title, systemImage: "plus")
        }
    }
}
