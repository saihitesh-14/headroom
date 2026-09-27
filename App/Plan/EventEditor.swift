import HeadroomCore
import SwiftUI

/// Add or edit one paycheck or bill.
struct EventEditor: View {
    @Environment(PlanStore.self) private var store
    @Environment(\.today) private var today
    @Environment(\.dismiss) private var dismiss
    @State var draft: EventDraft
    @State private var showErrors = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledContent("Name") {
                        TextField("Name", text: $draft.name,
                                  prompt: Text(draft.kind == .income ? "Paycheck" : "Rent"))
                            .multilineTextAlignment(.trailing)
                            .textInputAutocapitalization(.words)
                    }
                    CurrencyField(label: "Amount", text: $draft.amountText)
                } footer: {
                    if showErrors, !draft.errors.isEmpty {
                        Label(draft.errors.joined(separator: " "), systemImage: "exclamationmark.circle")
                            .foregroundStyle(Theme.danger)
                    }
                }

                Section {
                    Picker("Repeats", selection: $draft.repeatKind) {
                        ForEach(EventDraft.RepeatKind.allCases) { Text($0.title).tag($0) }
                    }
                    scheduleFields
                } footer: {
                    if showsMonthEndNote {
                        Text("In shorter months this lands on the last day of the month.")
                            .sectionText()
                    }
                }

                if !draft.isNew {
                    Section {
                        Button("Delete", role: .destructive) {
                            store.delete(eventID: draft.id)
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(role: .confirm) { save() }
                }
            }
        }
    }

    private var title: String {
        if !draft.isNew { return draft.kind == .income ? "Edit income" : "Edit bill" }
        return draft.kind == .income ? "New income" : "New bill"
    }

    @ViewBuilder private var scheduleFields: some View {
        switch draft.repeatKind {
        case .once:
            DatePicker("Date", selection: $draft.date, displayedComponents: .date)
        case .weekly, .everyTwoWeeks:
            DatePicker("Next date", selection: $draft.date, displayedComponents: .date)
        case .twiceMonthly:
            dayPicker("First day", selection: $draft.day1)
            dayPicker("Second day", selection: $draft.day2)
        case .monthly:
            dayPicker("Day of month", selection: $draft.day1)
        }
    }

    private func dayPicker(_ title: String, selection: Binding<Int>) -> some View {
        Picker(title, selection: selection) {
            ForEach(1...31, id: \.self) { Text(ScheduleText.ordinal($0)).tag($0) }
        }
    }

    private var showsMonthEndNote: Bool {
        switch draft.repeatKind {
        case .monthly: draft.day1 > 28
        case .twiceMonthly: max(draft.day1, draft.day2) > 28
        default: false
        }
    }

    private func save() {
        guard let event = draft.makeEvent() else {
            withAnimation { showErrors = true }
            AccessibilityNotification.Announcement(draft.errors.joined(separator: " ")).post()
            return
        }
        store.upsert(event)
        dismiss()
    }
}
