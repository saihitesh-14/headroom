import SwiftUI
import Testing
import UIKit
@testable import Headroom

/// The bundled Overpass font is registered and built with the right features (section 3.5).
@MainActor
@Suite("Typography")
struct TypographyTests {
    init() {
        Typography.register()
    }

    private func width(_ text: String, _ font: UIFont) -> CGFloat {
        (text as NSString).size(withAttributes: [.font: font]).width
    }

    @Test("the font is registered under its PostScript name")
    func registered() {
        #expect(UIFont(name: "Overpass-Regular", size: 17) != nil)
    }

    @Test("amounts use tabular figures, so columns line up")
    func tabularFigures() {
        let font = Typography.uiFont(.amount)
        let widths = ["0", "1", "7"].map { width($0, font) }
        #expect(widths[0] > 0)
        #expect(widths[0] == widths[1])
        #expect(widths[1] == widths[2])
    }

    @Test("readings are drawn heavier than the default weight through the wght axis")
    func weightAxisIsApplied() {
        let reading = Typography.uiFont(.readingL)
        let regular = Typography.baseFont(weight: 400, pointSize: reading.pointSize)
        #expect(reading.pointSize == regular.pointSize)
        #expect(width("$505", reading) > width("$505", regular))
    }

    @Test("the minus sign is exactly as wide as the plus sign")
    func minusMatchesPlus() {
        let font = Typography.uiFont(.amount)
        #expect(width("\u{2212}", font) == width("+", font))
    }

    @Test("Dynamic Type scales every role, and Bold Text adds weight")
    func scalesAndBolds() {
        let large = Typography.uiFont(.amount, size: .large)
        let xxxLarge = Typography.uiFont(.amount, size: .accessibility3)
        #expect(large.pointSize == 17)
        #expect(xxxLarge.pointSize > large.pointSize)
        let bold = Typography.uiFont(.amount, boldText: true)
        #expect(width("Headroom", bold) > width("Headroom", large))
    }

    @Test("the acknowledgment names the typeface and shows the bundled license")
    func acknowledgment() {
        #expect(Typography.credit.typeface == "Overpass typeface")
        #expect(Typography.credit.license == "SIL Open Font License 1.1")
        let text = Typography.credit.licenseText
        #expect(text?.hasPrefix("Copyright 2021 The Overpass Project Authors") == true)
        #expect(text?.contains("SIL OPEN FONT LICENSE Version 1.1") == true)
    }

    @Test("cap height is 0.7 em, which sizes the glyphs")
    func capHeight() {
        let font = Typography.uiFont(.readingXL)
        #expect(abs(font.capHeight / font.pointSize - 0.7) < 0.01)
    }
}
