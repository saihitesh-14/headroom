import HeadroomCore
import SwiftUI

/// The "Coming up" register as text (docs/REDESIGN-SPEC.md 5.1): each line from today down to
/// the lowest day, with the balance after it. Every amount comes from `CashEngine.register`.
struct ComingUpModel: Equatable {
    struct Row: Equatable, Identifiable {
        /// Position in the full register, so rows keep their identity when the list expands.
        let id: Int
        /// "Groceries"
        let name: String
        /// "\u{2212}$100", "+$800"
        let amount: String
        /// "Tue Sep 29", or "Tue Oct 13, your lowest" on the last row.
        let meta: String
        /// "Balance $900"
        let balance: String
        /// The last row: the lowest day.
        let isLowest: Bool
        /// "Groceries, Tuesday, September 29, minus $100, balance $900"
        let spokenLabel: String
    }

    /// At most this many rows show before the list is expanded.
    static let maxRows = 6

    let rows: [Row]
    /// "Show 3 more before Tue Oct 13", when rows are hidden.
    let expandLabel: String?

    init(entries: [RegisterEntry]) {
        // The column rule: once any row in a column has cents, every row in it shows cents.
        let amountCents = entries.contains { $0.amount.cents % 100 != 0 }
        let balanceCents = entries.contains { $0.balanceAfter.cents % 100 != 0 }
        rows = entries.enumerated().map { index, entry in
            let isLowest = index == entries.count - 1
            let lowest = isLowest ? ", your lowest" : ""
            return Row(
                id: index,
                name: entry.name,
                amount: entry.amount.displayText(signed: true, forceCents: amountCents),
                meta: entry.date.shortTextNoBreak + lowest,
                balance: "Balance \(entry.balanceAfter.displayText(forceCents: balanceCents))",
                isLowest: isLowest,
                spokenLabel: "\(entry.name), \(entry.date.spokenText)\(lowest), "
                    + "\(entry.amount.spokenText(signed: true)), balance \(entry.balanceAfter.spokenText)"
            )
        }
        let hidden = max(0, entries.count - Self.maxRows)
        expandLabel = entries.last.flatMap { last in
            hidden > 0 ? "Show \(hidden) more before \(last.date.shortTextNoBreak)" : nil
        }
    }

    /// How many rows the collapsed list leaves out.
    var hiddenCount: Int { max(0, rows.count - Self.maxRows) }

    /// The rows to show: before the expand button, and after it. Collapsed past six rows,
    /// the first five show, then the button, then the lowest day, which always stays in view.
    func visible(expanded: Bool) -> (before: [Row], after: [Row]) {
        guard !expanded, hiddenCount > 0, let last = rows.last else { return (rows, []) }
        return (Array(rows.prefix(Self.maxRows - 1)), [last])
    }
}

/// "Coming up" under the question: a running-balance register down to the lowest day.
/// Rows stack at accessibility sizes; each row is one VoiceOver sentence.
struct ComingUpList: View {
    let model: ComingUpModel
    /// The status tint for the ring on the lowest day.
    let tint: Color
    @State private var expanded = false
    @Environment(\.dynamicTypeSize) private var size
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(entries: [RegisterEntry], tint: Color) {
        model = ComingUpModel(entries: entries)
        self.tint = tint
    }

    var body: some View {
        let shown = model.visible(expanded: expanded)
        VStack(alignment: .leading, spacing: Theme.Space.m) {
            Text("Coming up")
                .font(.headline)
                .foregroundStyle(Theme.textPrimary)
                .accessibilityAddTraits(.isHeader)
            VStack(alignment: .leading, spacing: Theme.Space.m) {
                ForEach(shown.before) { item in
                    if item.id > 0 { Divider() }
                    row(item)
                }
                if !shown.after.isEmpty, let label = model.expandLabel {
                    Divider()
                    Button {
                        withAnimation(reduceMotion ? nil : .default) { expanded = true }
                    } label: {
                        Text(label)
                            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                            .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Theme.accent)
                }
                ForEach(shown.after) { item in
                    Divider()
                    row(item)
                }
            }
        }
    }

    private func row(_ row: ComingUpModel.Row) -> some View {
        VStack(alignment: .leading, spacing: Theme.Space.xs) {
            line {
                Text(row.name)
                    .font(.body)
                    .foregroundStyle(Theme.textPrimary)
            } trailing: {
                Text(row.amount)
                    .overpass(.amount)
                    .foregroundStyle(Theme.textPrimary)
            }
            line {
                HStack(alignment: .firstTextBaseline, spacing: Theme.Space.s) {
                    if row.isLowest {
                        LowRing(tint: tint)
                            .alignmentGuide(.firstTextBaseline) { $0[.bottom] - 1 }
                    }
                    Text(row.meta)
                        .font(.footnote)
                        .foregroundStyle(Theme.textSecondary)
                }
            } trailing: {
                Text(row.balance)
                    .overpass(.instrument)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(row.spokenLabel)
    }

    /// A label and its trailing value, side by side, or stacked at accessibility sizes.
    private func line<Leading: View, Trailing: View>(
        @ViewBuilder _ leading: () -> Leading, @ViewBuilder trailing: () -> Trailing
    ) -> some View {
        let layout = size.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Theme.Space.xs))
            : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: Theme.Space.l))
        return layout {
            leading()
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: size.isAccessibilitySize ? nil : .infinity, alignment: .leading)
            trailing()
        }
    }
}
