import SwiftUI

/// Design tokens. Views use these instead of hard-coded colors, radii, or fonts.
/// See docs/DESIGN.md for the rules behind them.
enum Theme {
    // Color: one accent (Evergreen) on cool neutrals. Amber and brick are for warnings only.
    static let accent = Color(.accent)
    static let canvas = Color(.canvas)
    static let surface = Color(.surface)
    static let textPrimary = Color(.textPrimary)
    static let textSecondary = Color(.textSecondary)
    static let warning = Color(.warning)
    static let danger = Color(.danger)
    static let chartBaseline = Color(.chartBaseline)

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

    /// Money is set in SF Rounded with tabular digits so columns line up.
    static func money(_ style: Font.TextStyle, weight: Font.Weight = .semibold) -> Font {
        .system(style, design: .rounded, weight: weight).monospacedDigit()
    }
}

extension View {
    /// A solid content surface with the one corner radius.
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
}
