import HeadroomCore
import SwiftUI

/// An amount in SF Rounded tabular digits that rolls to its new value when it changes.
struct MoneyText: View {
    let money: Money
    var style: Font.TextStyle = .body
    var weight: Font.Weight = .semibold
    var signed = false

    var body: some View {
        Text(signed && money > .zero ? "+" + money.formatted : money.formatted)
            .font(Theme.money(style, weight: weight))
            .contentTransition(.numericText())
    }
}
