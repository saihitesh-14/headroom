import HeadroomCore
import SwiftUI

/// Shows what the question was read as. Nothing is calculated until the user checks it.
struct ConfirmCard: View {
    @Environment(\.today) private var today
    @Environment(\.dismiss) private var dismiss
    @State var draft: PurchaseDraft
    let onCheck: (Purchase) -> Void
    @State private var showErrors = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledContent("Item") {
                        TextField("Item", text: $draft.item, prompt: Text("Laptop"))
                            .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("Price") {
                        TextField("Price", text: $draft.priceText, prompt: Text("0.00"))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .font(Theme.money(.body, weight: .regular))
                            .accessibilityIdentifier("price")
                    }
                    DatePicker("Date", selection: $draft.date, displayedComponents: .date)
                } header: {
                    Text(draft.source == .onDeviceAI ? "Read by on-device AI" : "Read by the built-in parser")
                } footer: {
                    let errors = draft.errors(today: today)
                    if showErrors, !errors.isEmpty {
                        Text(errors.joined(separator: " "))
                            .foregroundStyle(Theme.danger)
                    } else {
                        Text("Paid from checking. Make sure these match what you meant.")
                    }
                }
            }
            .listRowBackground(Theme.surface)
            .themedList()
            .navigationTitle("Check this purchase")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Check", role: .confirm, action: check)
                        .accessibilityIdentifier("confirmCheck")
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func check() {
        guard let purchase = draft.makePurchase(today: today) else {
            withAnimation { showErrors = true }
            return
        }
        onCheck(purchase)
    }
}
