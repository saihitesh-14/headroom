import Charts
import HeadroomCore
import SwiftUI

// Pieces shared by the Result chart and the Ask gauge (docs/REDESIGN-SPEC.md sections 6.2,
// 6.3 and 6.6): the clearance mark at true scale, the day ruler, the staff, and the words
// under the chart. Both charts plot a day index from today on X and whole cents on Y.

/// Clearance at true scale: a vertical dimension line from the datum to the low, with a
/// slash tick at each end, 8 pt to the right of the ring. With `measured` false the line
/// has closed onto the datum, ready to open like a caliper. Omitted when the low sits
/// exactly on the datum, where the ring alone says so.
struct ClearanceMarks: ChartContent {
    let x: Double
    let datum: Int
    let low: Int
    let tint: Color
    let measured: Bool

    var body: some ChartContent {
        if low != datum {
            let tip = measured ? low : datum
            RuleMark(x: .value("Day", x), yStart: .value("Datum", datum), yEnd: .value("Low", tip))
                .foregroundStyle(tint)
                .lineStyle(StrokeStyle(lineWidth: 1.5))
                .offset(x: 8)
            PointMark(x: .value("Day", x), y: .value("Datum", datum))
                .symbol { ClearanceTick(tint: tint) }
                .offset(x: 8)
            PointMark(x: .value("Day", x), y: .value("Low", tip))
                .symbol { ClearanceTick(tint: tint) }
                .offset(x: 8)
        }
    }
}

/// One 9 x 9 pt slash tick at an end of the clearance line.
private struct ClearanceTick: View {
    let tint: Color

    var body: some View {
        DimensionTick()
            .stroke(tint, style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
            .frame(width: 9, height: 9)
    }
}

/// The ruler under a chart: a short tick per day (weekly at accessibility sizes), and a
/// long, labeled tick at today, each first of the month, and the window end. At
/// accessibility sizes only today and the end are labeled.
struct DayRuler: Equatable {
    struct Mark: Equatable {
        /// Days from today.
        let index: Int
        /// "Today", or "Oct 1".
        let label: String
        /// A first of the month between today and the end, which gives way when labels collide.
        var isMonthStart = false
    }

    let ticks: [Int]
    let marks: [Mark]

    init(today: LocalDate, end: LocalDate, accessibilitySize: Bool) {
        let days = today.days(until: end)
        let dates = ChartScale.dayMarks(today: today, end: end)
            .filter { !accessibilitySize || $0 == today || $0 == end }
        marks = dates.map { date in
            Mark(index: today.days(until: date), label: date == today ? "Today" : date.monthDayText,
                 isMonthStart: date != today && date != end)
        }
        ticks = Array(stride(from: 0, through: max(days, 0), by: accessibilitySize ? 7 : 1))
    }

    /// The last mark when it is past today: the window end.
    var endMark: Mark? { marks.count > 1 ? marks.last : nil }

    /// The mark plotted at a value.
    func mark(at value: Double?) -> Mark? {
        guard let value else { return nil }
        return marks.first { Double($0.index) == value }
    }
}

/// Axis builders for both charts. No gridlines anywhere: the drawing carries the lines.
enum ChartAxes {
    /// The day ruler along the bottom, in Rule ticks with Graphite instrument labels.
    /// Labels hang to the right of their tick, except the window end, which hangs to the
    /// left so it stays inside the plot. Where labels would touch, a month start gives way
    /// to "Today" and the end.
    @AxisContentBuilder
    static func dayRuler(_ ruler: DayRuler) -> some AxisContent {
        AxisMarks(values: ruler.ticks.map(Double.init)) { _ in
            AxisTick(centered: true, length: 3, stroke: StrokeStyle(lineWidth: 1))
                .foregroundStyle(Theme.chartBaseline)
        }
        AxisMarks(values: ruler.marks.map { Double($0.index) }) { value in
            let mark = ruler.mark(at: value.as(Double.self))
            AxisTick(length: 7, stroke: StrokeStyle(lineWidth: 1))
                .foregroundStyle(Theme.chartBaseline)
            AxisValueLabel(anchor: mark == ruler.endMark ? .topTrailing : .top,
                           collisionResolution: .greedy(priority: mark?.isMonthStart == false ? 1 : 0, minimumSpacing: 6)) {
                InstrumentLabel(mark?.label ?? "")
            }
        }
    }

    /// The staff on the trailing edge: a tick and an amount at each step, in cents.
    @AxisContentBuilder
    static func staff(_ values: [Money]) -> some AxisContent {
        AxisMarks(position: .trailing, values: values.map(\.cents)) { value in
            AxisTick(length: 7, stroke: StrokeStyle(lineWidth: 1))
                .foregroundStyle(Theme.chartBaseline)
            // Spaced clear of the tick, so "$500" never reads as a negative amount.
            AxisValueLabel(horizontalSpacing: 10) {
                InstrumentLabel(value.as(Int.self).map { Money(cents: $0).displayText } ?? "")
            }
        }
    }
}

/// An instrument label: Overpass 13 in Graphite ("Floor $200", "Oct 1", "$500").
/// `pad` sets it on a Paper pad, `pad.width` points each side and `pad.height` above and
/// below, so it stays legible over lines and fills.
struct InstrumentLabel: View {
    let text: String
    var role: OverpassRole = .instrument
    var color: Color = Theme.textSecondary
    var pad: CGSize?

    nonisolated init(_ text: String, role: OverpassRole = .instrument, color: Color = Theme.textSecondary, pad: CGSize? = nil) {
        self.text = text
        self.role = role
        self.color = color
        self.pad = pad
    }

    var body: some View {
        Text(text)
            .overpass(role)
            .foregroundStyle(color)
            .lineLimit(1)
            .fixedSize()
            .padding(.horizontal, pad?.width ?? 0)
            .padding(.vertical, pad?.height ?? 0)
            .background(pad == nil ? .clear : Theme.canvas)
    }
}

/// The legend under the Result chart, drawn with the real line weights.
struct ChartLegend: View {
    let withName: String
    let withoutName: String
    @Environment(\.dynamicTypeSize) private var size

    var body: some View {
        let layout = size.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Theme.Space.xs))
            : AnyLayout(HStackLayout(spacing: Theme.Space.l))
        layout {
            entry(withName, color: Theme.textPrimary, weight: 2.5)
            entry(withoutName, color: Theme.chartBaseline, weight: 1.5)
        }
        .font(.footnote)
        .foregroundStyle(Theme.textSecondary)
        .accessibilityElement(children: .combine)
    }

    private func entry(_ name: String, color: Color, weight: CGFloat) -> some View {
        HStack(spacing: Theme.Space.s) {
            Capsule()
                .fill(color)
                .frame(width: 24, height: weight)
                .accessibilityHidden(true)
            Text(name)
        }
    }
}

/// "Below your floor Tue Oct 6 to Thu Oct 15", with a swatch of the chart's below-floor fill.
struct BelowFloorLine: View {
    let text: String
    let tint: Color

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Theme.Space.s) {
            RoundedRectangle(cornerRadius: 2)
                .fill(tint.opacity(0.16))
                .strokeBorder(tint, lineWidth: 1)
                .frame(width: 16, height: 10)
                .alignmentGuide(.firstTextBaseline) { $0[.bottom] }
                .accessibilityHidden(true)
            Text(text)
                .font(.footnote)
                .foregroundStyle(Theme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
