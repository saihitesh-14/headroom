import SwiftUI

/// A labeled amount input: "$" prefix, right-aligned, tabular digits.
struct CurrencyField: View {
    let label: String
    @Binding var text: String
    var allowsNegative = false
    var identifier: String?

    var body: some View {
        LabeledContent(label) {
            HStack(spacing: 1) {
                Spacer(minLength: 0)
                Text("$").foregroundStyle(Theme.textSecondary)
                TextField(label, text: $text, prompt: Text("0.00"))
                    .keyboardType(allowsNegative ? .numbersAndPunctuation : .decimalPad)
                    .fixedSize()
                    .accessibilityIdentifier(identifier ?? label)
            }
            .font(Theme.money(.body, weight: .regular))
        }
    }
}
