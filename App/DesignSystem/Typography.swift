import CoreText
import SwiftUI
import UIKit

/// Where Overpass is used, and how it is set there (docs/REDESIGN-SPEC.md section 3.4).
/// Overpass sets readings, amounts, instrument labels, and the verdict line. SF Pro sets
/// every sentence. Amounts inside sentences stay SF.
enum OverpassRole: Hashable {
    case readingXL, readingL, readingUnit, verdict, wordmark, navInline,
         amount, amountTotal, instrument, instrumentStrong

    /// Point size at the default Dynamic Type size.
    var size: CGFloat {
        switch self {
        case .readingXL: 56
        case .readingL: 44
        case .readingUnit: 20
        case .verdict: 22
        case .wordmark: 34
        case .navInline, .amount, .amountTotal: 17
        case .instrument, .instrumentStrong: 13
        }
    }

    /// The text style whose Dynamic Type curve this role follows.
    var style: UIFont.TextStyle {
        switch self {
        case .readingXL, .readingL, .wordmark: .largeTitle
        case .readingUnit: .title3
        case .verdict: .title2
        case .navInline: .headline
        case .amount, .amountTotal: .body
        case .instrument, .instrumentStrong: .footnote
        }
    }

    /// The `wght` axis value. Bold Text adds 100.
    var weight: CGFloat {
        switch self {
        case .readingUnit, .amount, .instrument: 500
        case .wordmark: 700
        default: 600
        }
    }

    var tracking: CGFloat {
        switch self {
        case .readingXL: -0.5
        case .readingL: -0.4
        case .wordmark: -0.3
        case .instrument, .instrumentStrong: 0.2
        default: 0
        }
    }
}

/// The only place fonts are built. Overpass is the bundled variable font; weights come
/// from its `wght` axis (never named instances), and every run gets tabular figures.
@MainActor
enum Typography {
    static let postScriptName = "Overpass-Regular"
    private static let wghtAxis = NSNumber(value: 0x7767_6874) // 'wght'
    private static var cache: [String: UIFont] = [:]

    /// Called first thing in HeadroomApp.init.
    static func register() {
        guard let url = Bundle.main.url(forResource: "Overpass-Variable", withExtension: "ttf") else {
            assertionFailure("Overpass-Variable.ttf missing from the bundle")
            return
        }
        CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil) // already registered is fine
    }

    /// The font for a role at a Dynamic Type size, with Bold Text adding 100 to `wght`.
    static func uiFont(_ role: OverpassRole, size: DynamicTypeSize = .large, boldText: Bool = false) -> UIFont {
        let key = "\(role)-\(size)-\(boldText)"
        if let font = cache[key] { return font }
        let traits = UITraitCollection(preferredContentSizeCategory: UIContentSizeCategory(size))
        let font = UIFontMetrics(forTextStyle: role.style).scaledFont(
            for: baseFont(weight: role.weight + (boldText ? 100 : 0), pointSize: role.size),
            compatibleWith: traits
        )
        cache[key] = font
        return font
    }

    /// Overpass at one `wght` with tabular figures, not scaled for Dynamic Type.
    static func baseFont(weight: CGFloat, pointSize: CGFloat) -> UIFont {
        let descriptor = UIFontDescriptor(fontAttributes: [
            .name: postScriptName,
            UIFontDescriptor.AttributeName(rawValue: kCTFontVariationAttribute as String): [wghtAxis: weight],
            .featureSettings: [[kCTFontOpenTypeFeatureTag: "tnum", kCTFontOpenTypeFeatureValue: 1]],
        ])
        return UIFont(descriptor: descriptor, size: pointSize)
    }

    /// A SwiftUI font for a role. Prefer `.overpass(_:)`, which also applies tracking.
    static func font(_ role: OverpassRole, size: DynamicTypeSize = .large, boldText: Bool = false) -> Font {
        Font(uiFont(role, size: size, boldText: boldText) as CTFont)
    }

    /// The typeface credit in Settings > Acknowledgments. It lives here because the typeface
    /// is only named in this file (section 3.3).
    struct Credit {
        let typeface: String
        let license: String
        /// The bundled license file, exactly as shipped.
        let licenseText: String?
    }

    static let credit = Credit(
        typeface: "Overpass typeface",
        license: "SIL Open Font License 1.1",
        licenseText: Bundle.main.url(forResource: "Overpass-OFL", withExtension: "txt")
            .flatMap { try? String(contentsOf: $0, encoding: .utf8) }
    )

    /// Cap height for a role; glyphs beside a reading are sized from it.
    static func capHeight(_ role: OverpassRole, size: DynamicTypeSize = .large, boldText: Bool = false) -> CGFloat {
        uiFont(role, size: size, boldText: boldText).capHeight
    }
}

/// Sets Overpass for a role, following Dynamic Type and Bold Text live.
struct OverpassModifier: ViewModifier {
    let role: OverpassRole
    @Environment(\.dynamicTypeSize) private var size
    @Environment(\.legibilityWeight) private var legibility

    func body(content: Content) -> some View {
        content
            .font(Typography.font(role, size: size, boldText: legibility == .bold))
            .tracking(role.tracking)
    }
}

extension View {
    /// Sets text in Overpass for one of the roles in section 3.4.
    func overpass(_ role: OverpassRole) -> some View {
        modifier(OverpassModifier(role: role))
    }
}
