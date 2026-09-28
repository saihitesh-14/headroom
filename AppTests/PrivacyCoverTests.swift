import Foundation
import Testing
import UIKit
@testable import Headroom

/// The lock cover and app-switcher snapshot (docs/REDESIGN-SPEC.md 5.7) draw in a window of
/// their own above the app's window. Sheets, popovers and dialogs are presented inside the
/// app's window, so an open Confirm details or balance sheet is covered too, and VoiceOver
/// cannot reach it while the cover shows.
@MainActor
@Suite("Privacy cover", .serialized)
struct PrivacyCoverTests {
    /// A stand-in for the app's window, on the test host's scene.
    func appWindow() throws -> UIWindow {
        let scene = try #require(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        return UIWindow(windowScene: scene)
    }

    func makeCover() -> PrivacyCoverWindow {
        let defaults = UserDefaults(suiteName: "PrivacyCoverTests-\(UUID().uuidString)")!
        return PrivacyCoverWindow(lock: AppLock(authenticator: StubAuthenticator(), defaults: defaults))
    }

    @Test("the cover has a window of its own above the app window and everything presented in it")
    func coversPresentations() throws {
        let app = try appWindow()
        let cover = makeCover()
        cover.attach(to: app)
        cover.setCovered(true, animated: false)

        let window = try #require(cover.window)
        #expect(window !== app)
        #expect(window.windowScene === app.windowScene)
        #expect(!window.isHidden)
        #expect(window.alpha == 1)
        #expect(window.isUserInteractionEnabled)
        #expect(window.windowLevel > .alert)
        #expect(window.rootViewController?.view.accessibilityViewIsModal == true)
        // VoiceOver cannot reach the app window, which holds any open sheet or popover.
        #expect(app.accessibilityElementsHidden)

        cover.setCovered(false, animated: false)
        #expect(window.isHidden)
        #expect(!app.accessibilityElementsHidden)
    }

    @Test("a cover asked for before the app window exists shows as soon as it does")
    func coverBeforeAttach() throws {
        let cover = makeCover()
        cover.setCovered(true, animated: false)
        #expect(cover.window == nil)

        let app = try appWindow()
        cover.attach(to: app)
        #expect(cover.window?.isHidden == false)
        #expect(app.accessibilityElementsHidden)
        cover.setCovered(false, animated: false)
    }

    @Test("the fade out ends with the window hidden, and lets touches through while it runs")
    func fadeOut() async throws {
        let app = try appWindow()
        let cover = makeCover()
        cover.attach(to: app)
        cover.setCovered(true, animated: false)
        cover.setCovered(false, animated: true)

        let window = try #require(cover.window)
        #expect(!window.isUserInteractionEnabled)
        #expect(!app.accessibilityElementsHidden)
        try await Task.sleep(for: .milliseconds(600))
        #expect(window.isHidden)
    }

    @Test("covering again during the fade shows the whole cover at once")
    func coverDuringFade() async throws {
        let app = try appWindow()
        let cover = makeCover()
        cover.attach(to: app)
        cover.setCovered(true, animated: false)
        cover.setCovered(false, animated: true)
        cover.setCovered(true, animated: true)

        let window = try #require(cover.window)
        #expect(!window.isHidden)
        #expect(window.alpha == 1)
        #expect(window.layer.animationKeys() == nil)
        #expect(window.isUserInteractionEnabled)
        #expect(app.accessibilityElementsHidden)
        // The cancelled fade must not hide the cover when it ends.
        try await Task.sleep(for: .milliseconds(600))
        #expect(!window.isHidden)
        cover.setCovered(false, animated: false)
    }
}
