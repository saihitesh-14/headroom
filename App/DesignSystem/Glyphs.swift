import HeadroomCore
import SwiftUI

// The drawing marks (docs/REDESIGN-SPEC.md sections 1.2 and 4.2). Each has one meaning
// everywhere: the ring is the lowest point, the dashed Ink rule is your floor, the line
// with slash ticks is clearance measured to the floor, and a solid rule is $0.
// All are SwiftUI shapes sized from the text beside them, and all are decorative:
// the words next to them say the same thing, so they are hidden from VoiceOver.

/// A 45 degree slash from bottom leading to top trailing: the end of a dimension line.
/// Drawn at 9 x 9 pt with a 1.5 pt round-cap stroke.
struct DimensionTick: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        return path
    }
}

/// A horizontal line through the vertical middle of its frame.
private struct HorizontalLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return path
    }
}

/// The floor: a 1.5 pt dashed Ink rule with the dash rhythm of the app icon.
/// Height 2 pt; the caller sets the width.
struct DatumRule: View {
    var body: some View {
        HorizontalLine()
            .stroke(Theme.textPrimary, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: [6, 3]))
            .frame(height: 2)
            .accessibilityHidden(true)
    }
}

/// The lowest point: an 11 pt ring (12 pt with Bold Text), Paper inside, status stroke.
struct LowRing: View {
    let tint: Color
    @Environment(\.legibilityWeight) private var legibility

    var body: some View {
        let diameter: CGFloat = legibility == .bold ? 12 : 11
        Circle()
            .fill(Theme.canvas)
            .overlay(Circle().strokeBorder(tint, lineWidth: 2))
            .frame(width: diameter, height: diameter)
            .accessibilityHidden(true)
    }
}

/// The clearance mark in miniature, set beside a reading. Its bottom sits on the text
/// baseline and it is as tall as the reading's capitals.
struct ClearanceGlyph: View {
    enum Kind: Hashable {
        /// Low at or above the floor: rises from the datum.
        case above
        /// Low below the floor, at or above $0: hangs from the datum.
        case below
        /// Low below $0: hangs from the solid $0 rule.
        case belowZero

        /// The variant for a lowest point measured against a floor.
        init(low: Money, floor: Money) {
            self = low < .zero ? .belowZero : low < floor ? .below : .above
        }

        /// Evergreen above the floor, Amber below it, Brick below $0.
        var tint: Color {
            switch self {
            case .above: Theme.accent
            case .below: Theme.warning
            case .belowZero: Theme.danger
            }
        }
    }

    let kind: Kind
    let tint: Color
    /// The paired reading font's cap height.
    let height: CGFloat

    private static let lineWidth: CGFloat = 1.5

    var body: some View {
        let width = height * 0.34
        let stubAtTop = kind != .above
        ZStack {
            GlyphStub(atTop: stubAtTop, inset: Self.lineWidth / 2)
                .stroke(tint, style: StrokeStyle(lineWidth: Self.lineWidth, dash: kind == .belowZero ? [] : [3, 2]))
            ClearanceLine(inset: Self.lineWidth / 2, tick: width * 0.6)
                .stroke(tint, style: StrokeStyle(lineWidth: Self.lineWidth, lineCap: .round))
        }
        .frame(width: width, height: height)
        .alignmentGuide(.firstTextBaseline) { $0[.bottom] }
        .accessibilityHidden(true)
    }
}

/// The datum or $0 stub across the full width of a clearance glyph.
private struct GlyphStub: Shape {
    let atTop: Bool
    let inset: CGFloat

    func path(in rect: CGRect) -> Path {
        let y = atTop ? rect.minY + inset : rect.maxY - inset
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: y))
        path.addLine(to: CGPoint(x: rect.maxX, y: y))
        return path
    }
}

/// A vertical dimension line at the horizontal center with a slash tick at each end.
private struct ClearanceLine: Shape {
    let inset: CGFloat
    let tick: CGFloat

    func path(in rect: CGRect) -> Path {
        let top = CGPoint(x: rect.midX, y: rect.minY + inset)
        let bottom = CGPoint(x: rect.midX, y: rect.maxY - inset)
        var path = Path()
        path.move(to: bottom)
        path.addLine(to: top)
        for end in [top, bottom] {
            path.addPath(DimensionTick().path(in: CGRect(
                x: end.x - tick / 2, y: end.y - tick / 2, width: tick, height: tick)))
        }
        return path
    }
}

/// The verdict mark: a balance step above, through, or below the datum, in the status
/// tint. Drawn in a 26 x 20 unit box scaled to 1.3 cap heights of the text beside it.
struct VerdictGlyph: View {
    enum Kind: Hashable {
        case stays, dips, belowZero, needsInfo

        var tint: Color {
            switch self {
            case .stays: Theme.accent
            case .dips: Theme.warning
            case .belowZero: Theme.danger
            case .needsInfo: Theme.textSecondary
            }
        }
    }

    let kind: Kind
    /// The text the glyph sits beside; its cap height sizes the glyph.
    let role: OverpassRole
    @Environment(\.dynamicTypeSize) private var size
    @Environment(\.legibilityWeight) private var legibility

    init(kind: Kind, relativeTo role: OverpassRole = .verdict) {
        self.kind = kind
        self.role = role
    }

    init(_ kind: Kind, relativeTo role: OverpassRole = .verdict) {
        self.init(kind: kind, relativeTo: role)
    }

    var body: some View {
        let bold = legibility == .bold
        let cap = Typography.capHeight(role, size: size, boldText: bold)
        let height = cap * 1.3
        ZStack {
            VerdictDatum(y: kind == .stays ? 15 : 12)
                .stroke(kind.tint, style: StrokeStyle(lineWidth: 1.5, dash: kind == .belowZero ? [] : [3, 2]))
            if let step = VerdictStep(kind: kind) {
                step.stroke(kind.tint, style: StrokeStyle(lineWidth: bold ? 2.5 : 2, lineCap: .round, lineJoin: .round))
            }
        }
        .frame(width: height * 26 / 20, height: height)
        // Centered on the capitals of the first line: its baseline sits 0.15 cap above the box bottom.
        .alignmentGuide(.firstTextBaseline) { $0[.bottom] - 0.15 * cap }
        .accessibilityHidden(true)
    }
}

/// Scales points in a 26 x 20 unit box to a rect.
private func unitPoint(_ x: CGFloat, _ y: CGFloat, in rect: CGRect) -> CGPoint {
    CGPoint(x: rect.minX + x * rect.width / 26, y: rect.minY + y * rect.height / 20)
}

/// The verdict glyph's datum (dashed) or $0 rule (solid), across the step's width.
private struct VerdictDatum: Shape {
    let y: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: unitPoint(1, y, in: rect))
        path.addLine(to: unitPoint(25, y, in: rect))
        return path
    }
}

/// The balance step for each verdict, in 26 x 20 units.
private struct VerdictStep: Shape {
    let points: [(CGFloat, CGFloat)]

    init?(kind: VerdictGlyph.Kind) {
        switch kind {
        case .stays: points = [(1, 4), (9, 4), (9, 9), (17, 9), (17, 6), (25, 6)]
        case .dips: points = [(1, 4), (9, 4), (9, 18), (17, 18), (17, 9), (25, 9)]
        case .belowZero: points = [(1, 4), (9, 4), (9, 19), (25, 19)]
        case .needsInfo: return nil
        }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addLines(points.map { unitPoint($0.0, $0.1, in: rect) })
        return path
    }
}

/// The instrument drawn with no numbers, for the first launch: a balance profile stepping
/// down to its lowest point, the floor, and the clearance between them. Static.
struct SectionDrawing: View {
    var body: some View {
        GeometryReader { proxy in
            let scale = proxy.size.width / 320
            let tick: CGFloat = 9
            ZStack(alignment: .topLeading) {
                SectionProfile()
                    .stroke(Theme.textPrimary, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                DatumRule()
                    .frame(width: proxy.size.width)
                    .position(x: proxy.size.width / 2, y: 96 * scale)
                SectionClearance(x: 160 * scale, top: 72 * scale, bottom: 96 * scale, tick: tick)
                    .stroke(Theme.accent, style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
                LowRing(tint: Theme.accent)
                    .position(x: 152 * scale, y: 72 * scale)
            }
        }
        .aspectRatio(320 / 112, contentMode: .fit)
        .frame(maxHeight: 140)
        .accessibilityHidden(true)
    }
}

/// `M0,24 H64 V48 H136 V72 H200 V40 H264 V16 H320` in a 320 x 112 box.
private struct SectionProfile: Shape {
    func path(in rect: CGRect) -> Path {
        let points: [(CGFloat, CGFloat)] = [
            (0, 24), (64, 24), (64, 48), (136, 48), (136, 72), (200, 72),
            (200, 40), (264, 40), (264, 16), (320, 16),
        ]
        var path = Path()
        path.addLines(points.map { CGPoint(x: rect.minX + $0.0 * rect.width / 320, y: rect.minY + $0.1 * rect.height / 112) })
        return path
    }
}

/// The empty-state clearance: a vertical line from the datum up to the low, ticked at each end.
private struct SectionClearance: Shape {
    let x: CGFloat, top: CGFloat, bottom: CGFloat, tick: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: x, y: bottom))
        path.addLine(to: CGPoint(x: x, y: top))
        for y in [top, bottom] {
            path.addPath(DimensionTick().path(in: CGRect(x: x - tick / 2, y: y - tick / 2, width: tick, height: tick)))
        }
        return path
    }
}

/// The below-floor fill in the chart. Gate 14b may swap in a 45 degree hatch;
/// until it passes, this is the flat 16% status tint.
enum HatchStyle {
    static func paint(_ tint: Color) -> AnyShapeStyle {
        AnyShapeStyle(tint.opacity(0.16))
    }
}
