import SwiftUI
import UIKit

/// Design tokens. Views use these instead of hard-coded colors, radii, or fonts.
/// See docs/DESIGN.md for the rules behind them. Values live in the asset catalog
/// (docs/REDESIGN-SPEC.md section 2.1), with High Contrast variants where needed.
enum Theme {
    // Color: one accent (Evergreen) on cool neutrals. Amber and brick are for status only.
    static let accent = Color(.accent)
    /// Paper: every screen background.
    static let canvas = Color(.canvas)
    /// Plate: the question field and the chart callout, equal to system inset rows.
    static let surface = Color(.surface)
    /// Ink: text, figures, the balance path, the datum.
    static let textPrimary = Color(.textPrimary)
    /// Graphite: secondary text, instrument labels, list headers and footers.
    static let textSecondary = Color(.textSecondary)
    static let warning = Color(.warning)
    static let danger = Color(.danger)
    /// Rule: graphics only (the Without line, ruler and staff ticks), never text.
    static let chartBaseline = Color(.chartBaseline)
    /// The label color on every prominent Evergreen button.
    static let onAccent = Color(.onAccent)

    /// The only corner radius for surfaces. Buttons are capsules; inputs are native rows.
    static let radius: CGFloat = 20

    enum Space {
        static let xs: CGFloat = 4
        static let s: CGFloat = 8
        static let m: CGFloat = 12
        static let l: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
    }

    /// Money in Overpass with tabular figures: `.amount`, or `.amountTotal` at semibold and
    /// heavier (the instrument roles for caption and footnote sizes). Prefer `.overpass(_:)`
    /// or `MoneyText`, which follow Dynamic Type and Bold Text live; this Font is sized for
    /// the settings at the time it is built.
    @MainActor
    static func money(_ style: Font.TextStyle = .body, weight: Font.Weight = .medium) -> Font {
        let strong = [Font.Weight.semibold, .bold, .heavy, .black].contains(weight)
        let small = [Font.TextStyle.caption, .caption2, .footnote].contains(style)
        let role: OverpassRole = switch (small, strong) {
        case (false, false): .amount
        case (false, true): .amountTotal
        case (true, false): .instrument
        case (true, true): .instrumentStrong
        }
        let size = DynamicTypeSize(UIApplication.shared.preferredContentSizeCategory) ?? .large
        return Typography.font(role, size: size, boldText: UIAccessibility.isBoldTextEnabled)
    }
}

extension View {
    /// A solid content surface with the one corner radius. Removed once no caller remains.
    func surfaceCard() -> some View {
        padding(Theme.Space.l)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.surface, in: .rect(cornerRadius: Theme.radius, style: .continuous))
    }

    /// Lists and forms on the themed canvas instead of the system gray.
    func themedList() -> some View {
        scrollContentBackground(.hidden)
            .background(Theme.canvas)
    }

    /// List and Form section headers and footers: the system font, in Graphite
    /// (system secondaryLabel is too faint on Paper).
    func sectionText() -> some View {
        font(nil).foregroundStyle(Theme.textSecondary)
    }
}
