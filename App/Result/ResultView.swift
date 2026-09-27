import HeadroomCore
import SwiftUI

/// What the purchase does to checking. Every number here comes from the engine.
struct ResultView: View {
    @Environment(PlanStore.self) private var store
    @Environment(\.today) private var today
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var purchase: Purchase
    @State private var priceText: String
    @State private var confirmingBalance = false

    init(initialPurchase: Purchase) {
        _purchase = State(initialValue: initialPurchase)
        _priceText = State(initialValue: MoneyInput.editableText(initialPurchase.price))
    }

    private var outcome: Outcome {
        CashEngine.analyze(store.plan, purchase: purchase, today: today)
    }

    private var priceIsValid: Bool {
        guard let price = MoneyInput.parse(priceText) else { return false }
        return price > .zero
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.xl) {
                switch outcome {
                case .needsInfo(let missing):
                    needsInfo(missing)
                    whatIf
                case .analyzed(let analysis):
                    header(analysis)
                    CashChart(analysis: analysis)
                    keyFigures(analysis)
                    whatIf
                    reasons(analysis)
                    assumptions
                }
            }
            .padding(.horizontal, Theme.Space.xl)
            .padding(.vertical, Theme.Space.l)
            .animation(reduceMotion ? nil : .smooth, value: purchase)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Theme.canvas.ignoresSafeArea())
        .navigationTitle(displayName)
        .navigationBarTitleDisplayMode(.inline)
        .sensoryFeedback(.selection, trigger: statusKey)
        .sheet(isPresented: $confirmingBalance) { ConfirmBalanceSheet() }
    }

    private var displayName: String {
        guard let first = purchase.item.first else { return "Purchase" }
        return first.uppercased() + purchase.item.dropFirst()
    }

    /// Changes only when the verdict changes, so the haptic fires on real changes.
    private var statusKey: String {
        if case .analyzed(let a) = outcome { return "\(ResultStatus(a))" }
        return "needsInfo"
    }

    // MARK: Sections

    private func header(_ a: Analysis) -> some View {
        VStack(alignment: .leading, spacing: Theme.Space.s) {
            StatusLabel(status: ResultStatus(a), title: Explainer.headline(a))
            Text(Explainer.summary(a))
                .font(.body)
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("chartSummary")
            if let warning = Explainer.baselineWarningText(a) {
                Label(warning, systemImage: "exclamationmark.circle")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Theme.warning)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func keyFigures(_ a: Analysis) -> some View {
        VStack(spacing: 0) {
            figureRow("Earliest date that fits") {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(Explainer.earliestFitValue(a)).foregroundStyle(Theme.textPrimary)
                }
            }
            if let note = Explainer.earliestFitNote(a) {
                Text(note)
                    .font(.footnote)
                    .foregroundStyle(Theme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, Theme.Space.m)
            }
            Divider()
            figureRow("Spending room today") {
                MoneyText(money: a.spendingRoomToday).foregroundStyle(Theme.textPrimary)
            }
            Divider()
            figureRow("Checked through") {
                Text(a.checkedThrough.shortText).foregroundStyle(Theme.textPrimary)
            }
        }
        .surfaceCard()
    }

    private func figureRow<Value: View>(_ label: String, @ViewBuilder value: () -> Value) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label).foregroundStyle(Theme.textSecondary)
            Spacer(minLength: Theme.Space.m)
            value()
        }
        .padding(.vertical, Theme.Space.m)
        .accessibilityElement(children: .combine)
    }

    private var whatIf: some View {
        VStack(alignment: .leading, spacing: Theme.Space.m) {
            Text("Try another date or price")
                .font(.headline)
                .foregroundStyle(Theme.textPrimary)
            VStack(spacing: 0) {
                DatePicker("Date", selection: dateBinding,
                           in: Date(today)...Date(today.adding(days: CashEngine.purchaseRangeDays)),
                           displayedComponents: .date)
                    .padding(.vertical, Theme.Space.s)
                Divider()
                CurrencyField(label: "Price", text: $priceText)
                    .onChange(of: priceText) { _, text in
                        if let price = MoneyInput.parse(text), price > .zero { purchase.price = price }
                    }
                .padding(.vertical, Theme.Space.m)
                if !priceIsValid {
                    Text("Enter a price, like 700 or 49.99.")
                        .font(.footnote)
                        .foregroundStyle(Theme.danger)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, Theme.Space.s)
                }
            }
            .surfaceCard()
        }
    }

    private var dateBinding: Binding<Date> {
        Binding(
            get: { Date(purchase.date) },
            set: { purchase.date = LocalDate($0) }
        )
    }

    private func reasons(_ a: Analysis) -> some View {
        VStack(alignment: .leading, spacing: Theme.Space.m) {
            Text("What moves your balance")
                .font(.headline)
                .foregroundStyle(Theme.textPrimary)
            VStack(spacing: 0) {
                ForEach(Array(Explainer.reasons(a).enumerated()), id: \.offset) { index, reason in
                    if index > 0 { Divider() }
                    HStack(alignment: .firstTextBaseline) {
                        Text(reason.label).foregroundStyle(Theme.textPrimary)
                        Spacer(minLength: Theme.Space.m)
                        MoneyText(money: reason.amount, signed: true)
                            .foregroundStyle(reason.amount > .zero ? Theme.accent : Theme.textPrimary)
                    }
                    .padding(.vertical, Theme.Space.m)
                    .accessibilityElement(children: .combine)
                }
                Text(Explainer.nextIncomeText(a))
                    .font(.footnote)
                    .foregroundStyle(Theme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, Theme.Space.s)
            }
            .surfaceCard()
        }
    }

    private var assumptions: some View {
        DisclosureGroup("How this is calculated") {
            VStack(alignment: .leading, spacing: Theme.Space.s) {
                ForEach(Explainer.assumptions, id: \.self) { line in
                    Text(line)
                        .font(.footnote)
                        .foregroundStyle(Theme.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.top, Theme.Space.s)
        }
        .tint(Theme.accent)
        .surfaceCard()
    }

    private func needsInfo(_ missing: [MissingInfo]) -> some View {
        VStack(alignment: .leading, spacing: Theme.Space.m) {
            StatusLabel(status: .needsInfo, title: "Needs more information")
            ForEach(missing, id: \.self) { item in
                Text(Explainer.text(for: item))
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
            }
            if missing.contains(where: { if case .balanceNotConfirmedToday = $0 { true } else { $0 == .balance } }) {
                Button("Confirm balance") { confirmingBalance = true }
                    .buttonStyle(.glassProminent)
            }
        }
        .surfaceCard()
    }
}
