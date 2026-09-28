import HeadroomCore
import SwiftUI

/// What the purchase does to checking (docs/REDESIGN-SPEC.md 5.3). No cards: the verdict
/// and reading are set in type on Paper, then the open chart, the ledger, and the glass
/// what-if bar. Every number here comes from the engine.
struct ResultView: View {
    @Environment(PlanStore.self) private var store
    @Environment(\.today) private var today
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var size
    /// True while the Confirm sheet that opened this screen is still closing over it.
    let isCovered: Bool
    @State private var purchase: Purchase
    @State private var confirmingBalance = false
    // The measurement (section 7): the With line peels away, then clearance opens.
    @State private var peel: Double = 0
    @State private var measured = false
    @State private var hasPlayed = false
    @State private var measuredPurchase: Purchase?

    static let needsInfoHeadline = "Add a few details first"

    init(initialPurchase: Purchase, isCovered: Bool = false) {
        self.isCovered = isCovered
        _purchase = State(initialValue: initialPurchase)
    }

    /// What starts (or restarts) the measurement: a new purchase, or the screen coming into view.
    private struct MeasureKey: Equatable {
        let purchase: Purchase
        let isCovered: Bool
    }

    private var outcome: Outcome {
        CashEngine.analyze(store.plan, purchase: purchase, today: today)
    }

    /// Changes only when the verdict changes, so the haptic and announcement fire on real changes.
    private static func status(_ outcome: Outcome) -> ResultStatus {
        if case .analyzed(let a) = outcome { return ResultStatus(a) }
        return .needsInfo
    }

    /// Spoken when the verdict changes: the headline, then the reading with its unit words.
    static func announcement(for outcome: Outcome) -> String {
        guard case .analyzed(let a) = outcome else { return "\(needsInfoHeadline)." }
        let reading = Explainer.reading(a)
        return "\(Explainer.headline(a)). \(reading.amount.spokenText) \(reading.words)."
    }

    var body: some View {
        let outcome = self.outcome
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.xl) {
                switch outcome {
                case .needsInfo(let missing):
                    needsInfo(missing)
                case .analyzed(let analysis):
                    verdict(analysis)
                    earliestFit(analysis)
                    chart(analysis)
                    ledger(analysis)
                    assumptions
                }
            }
            .scenePadding(.horizontal)
            .padding(.vertical, Theme.Space.l)
            .animation(reduceMotion ? nil : .smooth(duration: 0.3), value: purchase)
        }
        .scrollDismissesKeyboard(.interactively)
        .scrollEdgeEffectStyle(.soft, for: .top)
        .background(Theme.canvas.ignoresSafeArea())
        .safeAreaBar(edge: .bottom) { WhatIfBar(purchase: $purchase, today: today) }
        .navigationTitle(displayName)
        .navigationSubtitle(Explainer.purchaseLine(purchase))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // The same subtitle drawn in Graphite: the bar sets navigationSubtitle in the system
            // secondary label, 3.32:1 on Paper, and ignores a style on the Text.
            ToolbarItem(placement: .subtitle) {
                Text(Explainer.purchaseLine(purchase))
                    .font(.footnote)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .sensoryFeedback(trigger: Self.status(outcome)) { _, new in
            switch new {
            case .fits: .success
            case .crossesFloor: .warning
            case .goesNegative: .error
            case .needsInfo: nil
            }
        }
        .onChange(of: Self.status(outcome)) {
            AccessibilityNotification.Announcement(Self.announcement(for: self.outcome)).post()
        }
        .task(id: MeasureKey(purchase: purchase, isCovered: isCovered)) { await playMeasurement() }
        .sheet(isPresented: $confirmingBalance) { ConfirmBalanceSheet() }
    }

    private var displayName: String {
        guard let first = purchase.item.first else { return "Purchase" }
        return first.uppercased() + purchase.item.dropFirst()
    }

    // MARK: Motion

    /// Reduce Motion shows the finished drawing at once.
    private var shownPeel: Double { reduceMotion ? 1 : peel }
    private var shownMeasured: Bool { reduceMotion || measured }

    /// First appearance: the With line peels down from the Without line by the price
    /// (450 ms), then the clearance line opens from the datum to the low (300 ms).
    /// After a date or price change the chart morphs, and the measurement replays, shortened.
    private func playMeasurement() async {
        guard !reduceMotion else {
            // Keep the finished state, so turning Reduce Motion off later changes nothing.
            (peel, measured, hasPlayed, measuredPurchase) = (1, true, true, purchase)
            return
        }
        // The answer to the Check tap plays once it can be seen, not behind the closing sheet.
        // The sheet closing restarts this task; the wait is only a fallback, so the drawing
        // is always finished even if that signal never comes.
        if isCovered, !hasPlayed {
            guard (try? await Task.sleep(for: .milliseconds(1_500))) != nil else { return }
        }
        // Coming back to the screen with nothing changed: leave the drawing as it is.
        if measured, measuredPurchase == purchase { return }
        if !hasPlayed {
            hasPlayed = true
            withAnimation(.easeOut(duration: 0.45)) { peel = 1 }
            guard (try? await Task.sleep(for: .milliseconds(450))) != nil else { return }
        } else {
            var closed = Transaction()
            closed.disablesAnimations = true
            withTransaction(closed) { measured = false }
            guard (try? await Task.sleep(for: .milliseconds(300))) != nil else { return }
        }
        withAnimation(.easeOut(duration: 0.3)) { measured = true }
        measuredPurchase = purchase
    }

    // MARK: Sections

    private func verdict(_ a: Analysis) -> some View {
        let status = ResultStatus(a)
        return VStack(alignment: .leading, spacing: Theme.Space.s) {
            StatusLabel(status: status, title: Explainer.headline(a))
            ReadingLockup(reading: Explainer.reading(a), tint: status.tint)
            Text(Explainer.purchaseSentence(a))
                .font(.body)
                .foregroundStyle(Theme.textPrimary)
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

    /// "Try Fri Oct 16" when a later date fits; why none does otherwise. Hidden when it fits.
    @ViewBuilder
    private func earliestFit(_ a: Analysis) -> some View {
        if let date = Explainer.earliestFitDate(a) {
            VStack(alignment: .leading, spacing: Theme.Space.s) {
                Text("Earliest date that stays above your floor")
                    .font(.footnote)
                    .foregroundStyle(Theme.textSecondary)
                Button(Explainer.tryLabel(date, today: today)) { purchase.date = date }
                    .buttonStyle(EarliestFitButtonStyle())
                    .accessibilityHint("Earliest date that stays above your floor")
                    .accessibilityIdentifier("tryEarliestDate")
            }
        } else if ResultStatus(a) != .fits, let note = Explainer.earliestFitNote(a) {
            Text(note)
                .font(.footnote)
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func chart(_ a: Analysis) -> some View {
        let names = ResultChartModel.seriesNames(a.purchase)
        return VStack(alignment: .leading, spacing: Theme.Space.m) {
            CashChart(analysis: a, peel: shownPeel, measured: shownMeasured)
            if let caption = ResultChartModel(a).caption(accessibilitySize: size.isAccessibilitySize) {
                // At accessibility sizes the ring's and the floor's labels leave the plot for this line.
                HStack(alignment: .firstTextBaseline, spacing: Theme.Space.s) {
                    LowRing(tint: ResultStatus(a).tint)
                        .alignmentGuide(.firstTextBaseline) { $0[.bottom] - 1 }
                    Text(caption)
                        .font(.footnote)
                        .foregroundStyle(Theme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            ChartLegend(withName: names.with, withoutName: names.without)
            if let below = Explainer.belowFloorText(a) {
                BelowFloorLine(text: below, tint: ResultStatus(a).tint)
            }
            Text(Explainer.chartCaption(a))
                .font(.footnote)
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func ledger(_ a: Analysis) -> some View {
        VStack(alignment: .leading, spacing: Theme.Space.m) {
            Text(Explainer.ledgerHeading(a))
                .font(.headline)
                .foregroundStyle(Theme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            LedgerView(ledger: Explainer.ledger(a), tint: ResultStatus(a).tint)
            Text(Explainer.nextIncomeText(a))
                .font(.footnote)
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
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
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.top, Theme.Space.s)
        }
        .tint(Theme.accent)
    }

    private func needsInfo(_ missing: [MissingInfo]) -> some View {
        VStack(alignment: .leading, spacing: Theme.Space.m) {
            StatusLabel(status: .needsInfo, title: Self.needsInfoHeadline)
            ForEach(missing, id: \.self) { item in
                Text(Explainer.text(for: item))
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if missing.contains(where: { if case .balanceNotConfirmedToday = $0 { true } else { $0 == .balance } }) {
                Button { confirmingBalance = true } label: {
                    Text("Confirm balance").foregroundStyle(Theme.onAccent)
                }
                .buttonStyle(.glassProminent)
            }
        }
    }
}

/// "Try Fri Oct 16": an Evergreen label on a pale Evergreen capsule, as tall as a large
/// bordered button. The system bordered fill (about 18% of the tint) leaves the label at
/// 4.37:1 on Paper in light mode; a lighter fill keeps it at 4.5:1 or more in every appearance.
struct EarliestFitButtonStyle: ButtonStyle {
    static let fillOpacity = 0.08

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body)
            .foregroundStyle(Theme.accent)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .frame(minHeight: 44)
            .background(Theme.accent.opacity(Self.fillOpacity), in: .capsule)
            .contentShape(.capsule)
            .opacity(configuration.isPressed ? 0.6 : 1)
    }
}

/// The Result reading: the clearance glyph, the gap in Overpass, and its unit words on the
/// same baseline, so "$195" can never be read as a balance. One VoiceOver element.
struct ReadingLockup: View {
    let reading: Explainer.Reading
    let tint: Color
    @Environment(\.dynamicTypeSize) private var size
    @Environment(\.legibilityWeight) private var legibility
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline, spacing: Theme.Space.s) { glyph; figure; words }
            VStack(alignment: .leading, spacing: Theme.Space.xs) {
                HStack(alignment: .firstTextBaseline, spacing: Theme.Space.s) { glyph; figure }
                words
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(reading.amount.spokenText) \(reading.words)")
    }

    private var glyph: some View {
        let kind: ClearanceGlyph.Kind = switch reading.kind {
        case .above: .above
        case .below: .below
        case .belowZero: .belowZero
        }
        return ClearanceGlyph(kind: kind, tint: tint,
                              height: Typography.capHeight(.readingL, size: size, boldText: legibility == .bold))
    }

    private var figure: some View {
        Text(reading.amount.displayText)
            .overpass(.readingL)
            .foregroundStyle(Theme.textPrimary)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .contentTransition(reduceMotion ? .identity : .numericText(value: Double(reading.amount.cents)))
    }

    private var words: some View {
        Text(reading.words)
            .overpass(.readingUnit)
            .foregroundStyle(Theme.textPrimary)
            .fixedSize(horizontal: false, vertical: true)
    }
}
