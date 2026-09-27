import Charts
import HeadroomCore
import SwiftUI

/// The section drawing on Result (docs/REDESIGN-SPEC.md 6.2 to 6.5): checking with and
/// without the purchase over the decision window, the floor as the datum, and clearance
/// measured at true scale at the purchase low. Plots whole cents (Int) against a day index.
///
/// `peel` (0 or 1) lays the With line on the Without line or at its engine path, and
/// `measured` closes or opens the clearance mark; the parent animates both (section 7).
struct CashChart: View {
    let analysis: Analysis
    let peel: Double
    let measured: Bool

    private let model: ResultChartModel
    private let tint: Color
    @State private var selectedX: Double?
    @ScaledMetric(relativeTo: .body) private var plotHeight: CGFloat = 260
    @Environment(\.dynamicTypeSize) private var size
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.legibilityWeight) private var legibility

    init(analysis: Analysis, peel: Double, measured: Bool) {
        self.analysis = analysis
        self.peel = peel
        self.measured = measured
        model = ResultChartModel(analysis)
        tint = ResultStatus(analysis).tint
    }

    private var selectedDay: Int? { selectedX.map(model.day(at:)) }

    /// Half the LowRing: 11 pt, or 12 pt with Bold Text.
    private var ringRadius: CGFloat { legibility == .bold ? 6 : 5.5 }

    var body: some View {
        let shown = model.withShown(peel: peel)
        Chart {
            if model.showsBelowFloorArea {
                ForEach(shown, id: \.x) { point in
                    AreaMark(
                        x: .value("Day", point.x),
                        yStart: .value("Low", min(point.amount.cents, model.floor)),
                        yEnd: .value("Floor", model.floor),
                        series: .value("Area", "below")
                    )
                    .interpolationMethod(.stepEnd)
                    .foregroundStyle(HatchStyle.paint(tint))
                }
            }

            RuleMark(y: .value("Zero", 0))
                .foregroundStyle(Theme.chartBaseline)
                .lineStyle(StrokeStyle(lineWidth: 1))

            ForEach(model.baseline, id: \.x) { point in
                LineMark(x: .value("Day", point.x), y: .value("Balance", point.amount.cents),
                         series: .value("Line", "without"))
                    .foregroundStyle(Theme.chartBaseline)
                    .lineStyle(StrokeStyle(lineWidth: 1.5, lineJoin: .round))
                    .interpolationMethod(.stepEnd)
            }

            ForEach(shown, id: \.x) { point in
                LineMark(x: .value("Day", point.x), y: .value("Balance", point.amount.cents),
                         series: .value("Line", "with"))
                    .foregroundStyle(Theme.textPrimary)
                    .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                    .interpolationMethod(.stepEnd)
            }

            RuleMark(y: .value("Floor", model.floor))
                .foregroundStyle(Theme.textPrimary)
                .lineStyle(StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: [6, 3]))
                .annotation(position: model.floorLabelBelow ? .bottom : .top, alignment: .trailing, spacing: 3) {
                    InstrumentLabel("Floor \(analysis.floor.displayText)", pad: CGSize(width: 3, height: 0))
                }

            RuleMark(x: .value("Buy", model.purchaseX))
                .foregroundStyle(Theme.textSecondary)
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [2, 3]))
            PointMark(x: .value("Buy", model.purchaseX), y: .value("Top", model.domain.upperBound))
                .symbolSize(0)
                .annotation(position: .bottomTrailing, spacing: 2,
                            overflowResolution: .init(x: .fit(to: .chart), y: .disabled)) {
                    InstrumentLabel(Explainer.purchaseMarker(analysis.purchase), pad: CGSize(width: 3, height: 0))
                }

            ClearanceMarks(x: model.lowX, datum: model.datum, low: model.low, tint: tint, measured: measured)

            // The ring fades in with the measurement. The opacity sits on the symbol view,
            // because a mark's own opacity does not reach a custom symbol.
            PointMark(x: .value("Day", model.lowX), y: .value("Low", model.low))
                .symbol { LowRing(tint: tint).opacity(measured ? 1 : 0) }
            // The ring's label rides an invisible point: Charts ignores the annotation position
            // of a mark drawn with a custom symbol view. The spacing clears the ring's radius.
            PointMark(x: .value("Day", model.lowX), y: .value("Low", model.low))
                .symbolSize(0)
                .annotation(position: model.low < model.floor ? .bottom : .top, spacing: 5 + ringRadius,
                            overflowResolution: .init(x: .fit(to: .chart), y: .disabled)) {
                    InstrumentLabel(Explainer.lowMarker(analysis), role: .instrumentStrong,
                                    color: Theme.textPrimary, pad: CGSize(width: 2, height: 2))
                        .opacity(measured ? 1 : 0)
                }

            if let selectedX, let selectedDay {
                RuleMark(x: .value("Selected", min(max(selectedX, 0), model.xDomain.upperBound)))
                    .foregroundStyle(Theme.textPrimary)
                    .lineStyle(StrokeStyle(lineWidth: 1))
                    .annotation(position: .top, spacing: 4,
                                overflowResolution: .init(x: .fit(to: .chart), y: .fit(to: .chart))) {
                        SelectionCallout(callout: model.callout(day: selectedDay),
                                         withName: model.withName, withoutName: model.withoutName)
                    }
            }
        }
        .chartXScale(domain: model.xDomain)
        .chartYScale(domain: model.domain)
        .chartXAxis { ChartAxes.dayRuler(DayRuler(today: model.today, end: model.windowEnd,
                                                 accessibilitySize: size.isAccessibilitySize)) }
        .chartYAxis { ChartAxes.staff(model.staff) }
        .chartLegend(.hidden)
        // Read any day. In a scroll view, Swift Charts' own selection gesture starts with a long
        // press and clears on release, so vertical scrolling and the back swipe keep working.
        // (A custom long-press-then-drag chartGesture blocks scrolling on iOS 26.)
        .chartXSelection(value: $selectedX)
        .sensoryFeedback(.selection, trigger: selectedDay)
        .animation(reduceMotion ? nil : .smooth(duration: 0.3), value: analysis.purchase)
        .frame(height: min(max(plotHeight, 220), 360))
        .padding(.top, Theme.Space.xs)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Balance chart")
        .accessibilityValue(model.accessibilityValue)
        .accessibilityIdentifier("chart")
        .accessibilityChartDescriptor(CashChartDescriptor(analysis: analysis, windowDays: model.windowDays))
    }
}

/// The selected day on a Plate callout: the date, that day's lines, and both closes.
private struct SelectionCallout: View {
    let callout: ResultChartModel.Callout
    let withName: String
    let withoutName: String

    var body: some View {
        let amounts = callout.lines.map(\.amount) + [callout.withClose, callout.withoutClose]
        let cents = amounts.contains { $0.cents % 100 != 0 }
        VStack(alignment: .leading, spacing: Theme.Space.xs) {
            Text(callout.date.shortText)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Theme.textPrimary)
            Grid(alignment: .leading, horizontalSpacing: Theme.Space.m, verticalSpacing: Theme.Space.xs) {
                ForEach(Array(callout.lines.enumerated()), id: \.offset) { _, line in
                    row(line.name, line.amount.displayText(signed: true, forceCents: cents))
                }
                row(withName, callout.withClose.displayText(forceCents: cents))
                row(withoutName, callout.withoutClose.displayText(forceCents: cents))
            }
        }
        .fixedSize()
        .padding(Theme.Space.m)
        .background(Theme.surface, in: .rect(cornerRadius: Theme.radius, style: .continuous))
    }

    private func row(_ name: String, _ amount: String) -> some View {
        GridRow(alignment: .firstTextBaseline) {
            Text(name)
                .font(.footnote)
                .foregroundStyle(Theme.textSecondary)
            Text(amount)
                .overpass(.instrument)
                .foregroundStyle(Theme.textPrimary)
                .gridColumnAlignment(.trailing)
        }
    }
}
