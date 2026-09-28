import Testing
import UIKit
@testable import Headroom

/// Text contrast on fills the section 2.2 table does not list (docs/REDESIGN-SPEC.md 2.2
/// and the section 8 checklist: every text pair at 4.5:1 or more, light and dark).
@MainActor
@Suite("Contrast")
struct ContrastTests {
    /// Light, dark, and both with Increase Contrast.
    static let appearances: [(String, UITraitCollection)] = [
        ("light", UITraitCollection { $0.userInterfaceStyle = .light }),
        ("dark", UITraitCollection { $0.userInterfaceStyle = .dark }),
        ("light, increased contrast", UITraitCollection { $0.userInterfaceStyle = .light; $0.accessibilityContrast = .high }),
        ("dark, increased contrast", UITraitCollection { $0.userInterfaceStyle = .dark; $0.accessibilityContrast = .high }),
    ]

    /// sRGB red, green and blue from 0 to 1.
    func rgb(_ resource: ColorResource, _ traits: UITraitCollection) -> [Double] {
        var (r, g, b, a) = (CGFloat.zero, CGFloat.zero, CGFloat.zero, CGFloat.zero)
        UIColor(resource: resource).resolvedColor(with: traits).getRed(&r, green: &g, blue: &b, alpha: &a)
        return [r, g, b].map(Double.init)
    }

    /// WCAG 2.x relative luminance.
    func luminance(_ rgb: [Double]) -> Double {
        let linear = rgb.map { $0 <= 0.04045 ? $0 / 12.92 : pow(($0 + 0.055) / 1.055, 2.4) }
        return 0.2126 * linear[0] + 0.7152 * linear[1] + 0.0722 * linear[2]
    }

    func contrast(_ a: [Double], _ b: [Double]) -> Double {
        let (la, lb) = (luminance(a), luminance(b))
        return (max(la, lb) + 0.05) / (min(la, lb) + 0.05)
    }

    @Test("Try Fri Oct 16: the Evergreen label on its pale Evergreen capsule is at least 4.5:1")
    func earliestFitButton() {
        let opacity = EarliestFitButtonStyle.fillOpacity
        for (name, traits) in Self.appearances {
            let accent = rgb(.accent, traits), paper = rgb(.canvas, traits)
            let fill = zip(accent, paper).map { opacity * $0 + (1 - opacity) * $1 }
            #expect(contrast(accent, fill) >= 4.5, "\(name)")
        }
    }
}
