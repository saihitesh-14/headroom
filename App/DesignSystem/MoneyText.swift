import HeadroomCore
import SwiftUI

/// An amount in Overpass tabular figures that rolls to its new value when it changes.
/// Shows a real minus sign ("\u{2212}$750"); VoiceOver hears "minus $750".
struct MoneyText: View {
    let money: Money
    var role: OverpassRole = .amount
    /// Adds "+" to amounts above zero ("+$800").
    var signed = false
    /// Always shows cents. A column where any row has cents shows cents on every row.
    var forceCents = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Text(money.displayText(signed: signed, forceCents: forceCents))
            .overpass(role)
            .accessibilityLabel(money.spokenText(signed: signed))
            .contentTransition(reduceMotion ? .identity : .numericText(value: Double(money.cents)))
    }
}
