import Charts
import HeadroomCore
import SwiftUI

/// Everything the Ask gauge plots, taken from the engine (docs/REDESIGN-SPEC.md 6.6).
/// X is a day index from today; Y is whole cents. The view only places these values.
struct RoomGaugeModel {
    let today: LocalDate
    /// The last day shown: a week past the low, at least 21 days from today.
    let windowEnd: LocalDate
    let windowDays: Int
    /// The balance path without any purchase.
    let path: [ChartPoint]
    let floor: Int
    /// Where clearance is measured from: the floor, or $0 when the low is below $0.
    let datum: Int
    /// The lowest point, in cents.
    let low: Int
    /// A quarter into the day of the low, where the ring sits.
    let lowX: Double
    let domain: ClosedRange<Int>
    /// Rises from the floor, hangs below it, or hangs below $0.
    let clearance: ClearanceGlyph.Kind
    /// "Floor $200"
    let floorLabel: String
    /// The gauge in words for VoiceOver (`Explainer.roomSummary`).
    let accessibilityValue: String

    private let lowText: String

    init(_ detail: RoomDetail) {
        today = detail.points.first?.date ?? detail.low.date
        windowEnd = ChartWindow.end(today: today, horizon: detail.through, including: [detail.low.date])
        windowDays = today.days(until: windowEnd)
        path = ChartPath.points(Array(detail.points.prefix(windowDays + 1)))
        floor = detail.floor.cents
        low = detail.low.amount.cents
        datum = low < 0 ? 0 : floor
        lowX = Double(today.days(until: detail.low.date)) + 0.25
        domain = ChartScale.domain(values: path.map(\.amount), floor: detail.floor, lowLabelBelow: false, topRatio: 8)
        clearance = ClearanceGlyph.Kind(low: detail.low.amount, floor: detail.floor)
        floorLabel = "Floor \(detail.floor.displayText)"
        accessibilityValue = Explainer.roomSummary(detail)
        lowText = "Lowest \(detail.low.amount.displayText) on \(detail.low.date.shortTextNoBreak)"
    }

    var xDomain: ClosedRange<Double> { 0...Double(windowDays + 1) }

    var tint: Color { clearance.tint }

    /// The fill between the path and the floor, wherever the path dips below it.
    var showsBelowFloorArea: Bool { path.contains { $0.amount.cents < floor } }

    /// The $0 rule is drawn only when the path goes below $0.
    var showsZeroRule: Bool { path.contains { $0.amount.cents < 0 } }

    /// "Lowest $705 on Tue Oct 13". At accessibility sizes the floor moves here from the plot.
    func caption(accessibilitySize: Bool) -> String {
        accessibilitySize ? "\(lowText). \(floorLabel)." : lowText
    }
}

/// The balance ahead on Ask, drawn as a small section: the path from today through a week
/// past its lowest point, the floor as the datum, and clearance at true scale at the low.
/// Static: no selection, no legend, no animation. One VoiceOver element with a full sentence.
struct RoomGauge: View {
    let detail: RoomDetail
    @ScaledMetric(relativeTo: .body) private var height: CGFloat = 150
    @Environment(\.dynamicTypeSize) private var size

    var body: some View {
        let model = RoomGaugeModel(detail)
        VStack(alignment: .leading, spacing: Theme.Space.s) {
            chart(model)
            HStack(alignment: .firstTextBaseline, spacing: Theme.Space.s) {
                LowRing(tint: model.tint)
                    .alignmentGuide(.firstTextBaseline) { $0[.bottom] - 1 }
                Text(model.caption(accessibilitySize: size.isAccessibilitySize))
                    .font(.footnote)
                    .foregroundStyle(Theme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func chart(_ model: RoomGaugeModel) -> some View {
        let tint = model.tint
        let labelsFloor = !size.isAccessibilitySize
        return Chart {
            if model.showsBelowFloorArea {
                ForEach(model.path, id: \.x) { point in
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

            if model.showsZeroRule {
                RuleMark(y: .value("Zero", 0))
                    .foregroundStyle(Theme.chartBaseline)
                    .lineStyle(StrokeStyle(lineWidth: 1))
            }

            ForEach(model.path, id: \.x) { point in
                LineMark(x: .value("Day", point.x), y: .value("Balance", point.amount.cents),
                         series: .value("Line", "balance"))
                    .foregroundStyle(Theme.textPrimary)
                    .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                    .interpolationMethod(.stepEnd)
            }

            RuleMark(y: .value("Floor", model.floor))
                .foregroundStyle(Theme.textPrimary)
                .lineStyle(StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: [6, 3]))
                .annotation(position: .top, alignment: .trailing, spacing: 3) {
                    if labelsFloor {
                        InstrumentLabel(model.floorLabel, pad: CGSize(width: 3, height: 0))
                    }
                }

            ClearanceMarks(x: model.lowX, datum: model.datum, low: model.low, tint: tint, measured: true)

            PointMark(x: .value("Day", model.lowX), y: .value("Low", model.low))
                .symbol { LowRing(tint: tint) }
        }
        .chartXScale(domain: model.xDomain)
        .chartYScale(domain: model.domain)
        .chartXAxis { ChartAxes.dayRuler(DayRuler(today: model.today, end: model.windowEnd,
                                                 accessibilitySize: size.isAccessibilitySize)) }
        .chartYAxis(.hidden)
        .chartLegend(.hidden)
        .frame(height: min(max(height, 130), 200))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Balance ahead")
        .accessibilityValue(model.accessibilityValue)
        .accessibilityIdentifier("roomGauge")
    }
}
