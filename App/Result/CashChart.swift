import Charts
import HeadroomCore
import SwiftUI

/// Checking balance with and without the purchase, against the floor.
/// Plots whole cents (Int) so money never passes through floating point.
struct CashChart: View {
    let analysis: Analysis

    private let withLabel = "With purchase"
    private let withoutLabel = "Without"

    var body: some View {
        Chart {
            ForEach(analysis.baseline, id: \.date) { point in
                LineMark(x: .value("Date", Date(point.date)), y: .value("Balance", point.low.cents))
                    .foregroundStyle(by: .value("Line", withoutLabel))
                    .interpolationMethod(.stepEnd)
            }
            ForEach(analysis.withPurchase, id: \.date) { point in
                LineMark(x: .value("Date", Date(point.date)), y: .value("Balance", point.low.cents))
                    .foregroundStyle(by: .value("Line", withLabel))
                    .interpolationMethod(.stepEnd)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))
            }
            RuleMark(y: .value("Floor", analysis.floor.cents))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                .foregroundStyle(Theme.textSecondary)
                .annotation(position: .top, alignment: .leading) {
                    Text("Floor \(analysis.floor.formatted)")
                        .font(.caption2)
                        .foregroundStyle(Theme.textSecondary)
                }
            RuleMark(x: .value("Purchase", Date(analysis.purchase.date)))
                .lineStyle(StrokeStyle(lineWidth: 1))
                .foregroundStyle(Theme.accent.opacity(0.35))
            PointMark(x: .value("Date", Date(analysis.purchaseLow.date)),
                      y: .value("Balance", analysis.purchaseLow.amount.cents))
                .foregroundStyle(ResultStatus(analysis).tint)
                .symbolSize(60)
                .annotation(position: .trailing, alignment: .leading, spacing: 6) {
                    Text(analysis.purchaseLow.amount.formatted)
                        .font(Theme.money(.caption, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                }
        }
        .chartForegroundStyleScale([withoutLabel: Theme.chartBaseline, withLabel: Theme.accent])
        .chartYScale(domain: yDomain)
        .chartLegend(position: .top, alignment: .leading)
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { value in
                AxisGridLine().foregroundStyle(Theme.chartBaseline.opacity(0.3))
                AxisValueLabel {
                    if let cents = value.as(Int.self) {
                        Text(Money(cents: cents).formatted).font(.caption2)
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: 14)) { _ in
                AxisGridLine().foregroundStyle(Theme.chartBaseline.opacity(0.2))
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
            }
        }
        .frame(height: 220)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Balance chart")
        .accessibilityValue(summary)
        .accessibilityIdentifier("chart")
    }

    /// Fits the data (and the floor and zero) with a little headroom, instead of the
    /// automatic range, which can reach far below the lowest point.
    private var yDomain: ClosedRange<Int> {
        let values = (analysis.baseline + analysis.withPurchase).flatMap { [$0.low.cents, $0.close.cents] }
            + [analysis.floor.cents, 0]
        let low = values.min() ?? 0, high = values.max() ?? 0
        let pad = max((high - low) / 10, 1_000)
        return (min(low, 0) - pad)...(high + pad)
    }

    private var summary: String {
        "With this purchase, lowest point \(analysis.purchaseLow.amount.formatted) on \(analysis.purchaseLow.date.shortText). "
            + "Without it, lowest point \(analysis.baselineLow.amount.formatted) on \(analysis.baselineLow.date.shortText). "
            + "Floor \(analysis.floor.formatted)."
    }
}
