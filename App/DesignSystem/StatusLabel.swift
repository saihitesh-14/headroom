import HeadroomCore
import SwiftUI

/// The result state, always shown as icon + words (never color alone).
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

    var symbol: String {
        switch self {
        case .fits: "checkmark.circle.fill"
        case .crossesFloor: "exclamationmark.triangle.fill"
        case .goesNegative: "xmark.octagon.fill"
        case .needsInfo: "questionmark.circle.fill"
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

struct StatusLabel: View {
    let status: ResultStatus
    let title: String

    var body: some View {
        Label {
            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Theme.textPrimary)
        } icon: {
            Image(systemName: status.symbol)
                .foregroundStyle(status.tint)
                .symbolRenderingMode(.hierarchical)
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("verdict")
    }
}
