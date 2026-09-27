import HeadroomCore
import SwiftUI

/// Choose the lowest checking balance to keep.
struct FloorSheet: View {
    @Environment(PlanStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var amountText = ""
    @State private var showError = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledContent("Keep at least") {
                        TextField("Cash floor", text: $amountText, prompt: Text("0.00"))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .font(Theme.money(.body, weight: .regular))
                    }
                } footer: {
                    if showError {
                        Text("Enter an amount, like 200. $0 is fine.")
                            .foregroundStyle(Theme.danger)
                    } else {
                        Text("Headroom warns you when a purchase would take checking below this amount.")
                    }
                }
            }
            .listRowBackground(Theme.surface)
            .themedList()
            .navigationTitle("Cash floor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(role: .confirm) { save() }
                }
            }
            .onAppear {
                if let floor = store.plan.floor { amountText = MoneyInput.editableText(floor) }
            }
        }
    }

    private func save() {
        guard let floor = MoneyInput.parse(amountText) else {
            withAnimation { showError = true }
            return
        }
        store.update { $0.floor = floor }
        dismiss()
    }
}
