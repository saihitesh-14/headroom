import HeadroomCore
import SwiftUI

extension Explainer.Ledger {
    /// Every amount in the ledger's column, top to bottom.
    var amounts: [Money] {
        [start] + rows.map(\.amount) + [remainder?.amount].compactMap { $0 } + [end.amount]
    }

    /// The column rule: once any row has cents, every row shows cents.
    var showsCents: Bool { amounts.contains { $0.cents % 100 != 0 } }
}

/// "What moves your balance": checking today, the grouped movements, then a double rule
/// and the lowest point, the way a ledger sums a column (docs/REDESIGN-SPEC.md 5.3).
/// Open on Paper, with hairlines between rows. Rows stack at accessibility sizes.
///
/// Rows are stacks rather than a Grid: in the scrolling Result screen a Grid sized its amount
/// column wider than any amount and left a gap above the total. The double rule takes the
/// amount column's width from the amounts themselves.
struct LedgerView: View {
    let ledger: Explainer.Ledger
    /// The status tint for the ring on the lowest point.
    let tint: Color
    @Environment(\.dynamicTypeSize) private var size

    /// "Rent, Oct 2, minus $750"
    static func spokenLabel(_ reason: Explainer.Reason) -> String {
        "\(reason.label), \(reason.amount.spokenText(signed: true))"
    }

    private struct Line {
        let label: String
        let amount: Money
        let signed: Bool
    }

    private var lines: [Line] {
        [Line(label: "Checking today", amount: ledger.start, signed: false)]
            + (ledger.rows + [ledger.remainder].compactMap { $0 }).map { Line(label: $0.label, amount: $0.amount, signed: true) }
    }

    private var totalLabel: String { "Lowest point, \(ledger.end.date.shortTextNoBreak)" }

    var body: some View {
        let stacked = size.isAccessibilitySize
        VStack(alignment: .leading, spacing: Theme.Space.m) {
            ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                if index > 0 { Divider() }
                row(stacked: stacked) {
                    Text(line.label)
                        .font(.body)
                        .foregroundStyle(Theme.textPrimary)
                } amount: {
                    amount(line.amount, signed: line.signed)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(line.label), \(line.amount.spokenText(signed: line.signed))")
            }
            if !stacked {
                columnRule.frame(maxWidth: .infinity, alignment: .trailing)
            }
            row(stacked: stacked) {
                HStack(spacing: Theme.Space.s) {
                    LowRing(tint: tint)
                    Text(totalLabel)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Theme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } amount: {
                VStack(alignment: .leading, spacing: Theme.Space.s) {
                    if stacked { columnRule }
                    MoneyText(money: ledger.end.amount, role: .amountTotal, forceCents: ledger.showsCents)
                        .foregroundStyle(Theme.textPrimary)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(totalLabel), \(ledger.end.amount.spokenText)")
        }
    }

    /// A label and its amount: side by side with the amount trailing, or stacked at
    /// accessibility sizes.
    private func row<Label: View, Amount: View>(
        stacked: Bool, @ViewBuilder label: () -> Label, @ViewBuilder amount: () -> Amount
    ) -> some View {
        let layout = stacked
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Theme.Space.xs))
            : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: Theme.Space.l))
        return layout {
            label()
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: stacked ? nil : .infinity, alignment: .leading)
            amount()
        }
    }

    private func amount(_ money: Money, signed: Bool) -> some View {
        MoneyText(money: money, signed: signed, forceCents: ledger.showsCents)
            .foregroundStyle(Theme.textPrimary)
    }

    /// The double rule, exactly as wide as the widest amount in the column.
    private var columnRule: some View {
        ZStack(alignment: .trailing) {
            ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                amount(line.amount, signed: line.signed).fixedSize()
            }
            MoneyText(money: ledger.end.amount, role: .amountTotal, forceCents: ledger.showsCents).fixedSize()
        }
        .hidden()
        .frame(height: 4)
        .overlay { DoubleRule() }
        .accessibilityHidden(true)
    }
}

/// Two 1 px Ink lines 2 pt apart: the sum rule above the ledger total, and nowhere else.
struct DoubleRule: View {
    @Environment(\.displayScale) private var displayScale

    var body: some View {
        VStack(spacing: 2) {
            Rectangle().frame(height: 1 / displayScale)
            Rectangle().frame(height: 1 / displayScale)
        }
        .foregroundStyle(Theme.textPrimary)
        .accessibilityHidden(true)
    }
}
