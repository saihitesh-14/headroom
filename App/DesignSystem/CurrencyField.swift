import HeadroomCore
import SwiftUI

/// An amount input: "$" prefix, trailing aligned, Overpass tabular digits.
/// The labeled form is a native row; `compact` drops the label for the what-if bar.
struct CurrencyField: View {
    let label: String
    @Binding var text: String
    var allowsNegative = false
    var identifier: String?
    var compact = false

    var body: some View {
        if compact {
            field
        } else {
            LabeledContent(label) {
                HStack(spacing: 0) {
                    Spacer(minLength: 0)
                    field
                }
            }
        }
    }

    private var field: some View {
        HStack(spacing: 0) {
            Text("$")
                .foregroundStyle(text.isEmpty ? Theme.textSecondary : Theme.textPrimary)
                .accessibilityHidden(true)
            TextField(label, text: $text, prompt: Text("0.00").foregroundStyle(Theme.textSecondary))
                .keyboardType(allowsNegative ? .numbersAndPunctuation : .decimalPad)
                .foregroundStyle(Theme.textPrimary)
                .fixedSize()
                .accessibilityLabel(label)
                .accessibilityValue(spokenValue)
                .accessibilityIdentifier(identifier ?? label)
        }
        .overpass(.amount)
    }

    /// What VoiceOver reads for the amount: "$700", "minus $45.50", or "empty".
    /// Text that is not an amount yet is read as typed.
    private var spokenValue: String {
        let amount = allowsNegative ? MoneyInput.parseBalance(text) : MoneyInput.parse(text)
        return amount.map(\.spokenText) ?? (text.isEmpty ? "empty" : text)
    }
}
