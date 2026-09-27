import HeadroomCore
import SwiftUI

/// The result state, always shown as glyph shape + words + tint (never color alone).
enum ResultStatus: Equatable {
    case fits, crossesFloor, goesNegative, needsInfo

    /// A purchase only lowers the balance, so a plan that is already short
    /// always yields a crossesFloor or goesNegative verdict too.
    init(_ analysis: Analysis) {
        switch analysis.verdict {
        case .fits: self = .fits
        case .crossesFloor: self = .crossesFloor
        case .goesNegative: self = .goesNegative
        }
    }

    /// The verdict glyph: a step that stays above, dips through, or falls below the datum.
    var glyph: VerdictGlyph.Kind {
        switch self {
        case .fits: .stays
        case .crossesFloor: .dips
        case .goesNegative: .belowZero
        case .needsInfo: .needsInfo
        }
    }

    var tint: Color {
        switch self {
        case .fits: Theme.accent
        case .crossesFloor: Theme.warning
        case .goesNegative: Theme.danger
        case .needsInfo: Theme.textSecondary
        }
    }
}

/// The verdict line: the verdict glyph, then the headline in Overpass. A header for VoiceOver.
struct StatusLabel: View {
    let status: ResultStatus
    let title: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Theme.Space.s) {
            VerdictGlyph(kind: status.glyph)
            Text(title)
                .overpass(.verdict)
                .foregroundStyle(Theme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
        .accessibilityIdentifier("verdict")
    }
}
