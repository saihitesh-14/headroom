import SwiftUI
import Testing
import UIKit
@testable import Headroom

/// Gate 14a (docs/REDESIGN-SPEC.md section 10): navigation titles are set in Overpass through
/// the bar's title properties, which HeadroomApp.init sets before any bar exists. The test host
/// is the app, so its init has run by the time these tests do.
@MainActor
@Suite("Navigation titles")
struct NavigationTitleTests {
    private let bar = UINavigationBar.appearance()

    @Test("large titles use the wordmark role")
    func largeTitle() throws {
        let font = try #require(bar.largeTitleTextAttributes?[.font] as? UIFont)
        let wordmark = Typography.uiFont(.wordmark)
        #expect(font.familyName == "Overpass")
        #expect(font.familyName == wordmark.familyName)
        #expect(font.pointSize == wordmark.pointSize)
    }

    @Test("inline titles use the navInline role")
    func inlineTitle() throws {
        let font = try #require(bar.titleTextAttributes?[.font] as? UIFont)
        let inline = Typography.uiFont(.navInline)
        #expect(font.familyName == inline.familyName)
        #expect(font.pointSize == inline.pointSize)
    }
}
