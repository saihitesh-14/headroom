import Accessibility
import HeadroomCore
import SwiftUI

/// The Result chart for Audio Graphs (docs/REDESIGN-SPEC.md 6.5): two continuous series of
/// daily lows over the chart's window. Values become Double only here, for audio.
struct CashChartDescriptor: AXChartDescriptorRepresentable {
    let analysis: Analysis
    let windowDays: Int

    func makeChartDescriptor() -> AXChartDescriptor {
        let model = ResultChartModel(analysis)
        let today = analysis.today
        let xAxis = AXNumericDataAxisDescriptor(
            title: "Day",
            range: 0...Double(windowDays),
            gridlinePositions: []
        ) { today.adding(days: Int($0)).spokenText }
        let yAxis = AXNumericDataAxisDescriptor(
            title: "Balance in dollars",
            range: Double(model.domain.lowerBound) / 100...Double(model.domain.upperBound) / 100,
            gridlinePositions: model.staff.map { Double($0.cents) / 100 }
        ) { Money(cents: Int(($0 * 100).rounded())).spokenText }
        let item = analysis.purchase.item.isEmpty ? "purchase" : analysis.purchase.item
        return AXChartDescriptor(
            title: "Balance with and without \(item)",
            summary: model.accessibilityValue,
            xAxis: xAxis,
            yAxis: yAxis,
            additionalAxes: [],
            series: [
                series(model.withName, analysis.withPurchase),
                series(model.withoutName, analysis.baseline),
            ]
        )
    }

    private func series(_ name: String, _ days: [DayPoint]) -> AXDataSeriesDescriptor {
        AXDataSeriesDescriptor(
            name: name,
            isContinuous: true,
            dataPoints: days.prefix(windowDays + 1).enumerated().map { index, day in
                AXDataPoint(x: Double(index), y: Double(day.low.cents) / 100)
            }
        )
    }
}
