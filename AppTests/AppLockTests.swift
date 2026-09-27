import Foundation
import SwiftUI
import Testing
@testable import Headroom

/// A stand-in for Face ID / passcode.
final class StubAuthenticator: Authenticator, @unchecked Sendable {
    var available = true
    var succeeds = true
    var delay: Duration = .zero
    private(set) var prompts = 0

    func availability() -> String? { available ? nil : "Set a passcode on this iPhone to use the lock." }

    func authenticate(reason: String) async -> Bool {
        prompts += 1
        if delay > .zero { try? await Task.sleep(for: delay) }
        return succeeds
    }
}

/// An authenticator that reports one kind of biometry.
struct FixedBiometryAuthenticator: Authenticator {
    let kind: Biometry

    func availability() -> String? { nil }
    func authenticate(reason: String) async -> Bool { true }
    func biometry() -> Biometry { kind }
}

@MainActor
@Suite("AppLock")
struct AppLockTests {
    func makeLock(_ auth: StubAuthenticator = StubAuthenticator(), enabled: Bool = true) -> AppLock {
        let defaults = UserDefaults(suiteName: "AppLockTests-\(UUID().uuidString)")!
        let lock = AppLock(authenticator: auth, defaults: defaults)
        lock.isEnabled = enabled
        return lock
    }

    @Test("off by default")
    func offByDefault() {
        let defaults = UserDefaults(suiteName: "AppLockTests-\(UUID().uuidString)")!
        #expect(AppLock(authenticator: StubAuthenticator(), defaults: defaults).isEnabled == false)
    }

    @Test("locks when the app goes to the background")
    func locksOnBackground() {
        let lock = makeLock()
        lock.scenePhaseChanged(to: .background)
        #expect(lock.isLocked)
    }

    @Test("does not lock on inactive, because the Face ID prompt itself makes the app inactive")
    func ignoresInactive() {
        let lock = makeLock()
        lock.scenePhaseChanged(to: .inactive)
        #expect(!lock.isLocked)
    }

    @Test("never locks when turned off")
    func disabledNeverLocks() {
        let lock = makeLock(enabled: false)
        lock.scenePhaseChanged(to: .background)
        #expect(!lock.isLocked)
    }

    @Test("never locks when the device cannot authenticate, and says why")
    func unavailableNeverLocks() {
        let auth = StubAuthenticator()
        auth.available = false
        let lock = makeLock(auth)
        lock.scenePhaseChanged(to: .background)
        #expect(!lock.isLocked)
        #expect(lock.unavailableReason == "Set a passcode on this iPhone to use the lock.")
    }

    @Test("unlocks only when authentication succeeds")
    func unlock() async {
        let auth = StubAuthenticator()
        let lock = makeLock(auth)
        lock.scenePhaseChanged(to: .background)
        auth.succeeds = false
        await lock.unlock()
        #expect(lock.isLocked)
        auth.succeeds = true
        await lock.unlock()
        #expect(!lock.isLocked)
        #expect(auth.prompts == 2)
    }

    @Test("returning from the background prompts once; cancelling does not start a loop")
    func noPromptLoop() async {
        let auth = StubAuthenticator()
        let lock = makeLock(auth)
        lock.scenePhaseChanged(to: .background)
        auth.succeeds = false                     // the user cancels Face ID
        await lock.appBecameActive()              // background → active: prompt
        await lock.appBecameActive()              // Face ID sheet closes: inactive → active, no new prompt
        #expect(auth.prompts == 1)
        #expect(lock.isLocked)
        await lock.unlock()                       // the Unlock button still works
        #expect(auth.prompts == 2)
    }

    @Test("two unlock requests at once show one prompt")
    func noDoublePrompt() async {
        let auth = StubAuthenticator()
        auth.delay = .milliseconds(100)
        let lock = makeLock(auth)
        lock.scenePhaseChanged(to: .background)
        async let first: Void = lock.unlock()
        async let second: Void = lock.unlock()
        _ = await (first, second)
        #expect(auth.prompts == 1)
        #expect(!lock.isLocked)
    }

    @Test("an authenticator that does not report biometry means the passcode")
    func defaultBiometry() {
        #expect(StubAuthenticator().biometry() == .none)
        #expect(makeLock().biometry == .none)
    }

    @Test("the lock reports the device's biometry")
    func reportsBiometry() {
        let defaults = UserDefaults(suiteName: "AppLockTests-\(UUID().uuidString)")!
        for kind in [Biometry.faceID, .touchID, .opticID, .none] {
            #expect(AppLock(authenticator: FixedBiometryAuthenticator(kind: kind), defaults: defaults).biometry == kind)
        }
    }

    @Test("the lock copy names the biometry", arguments: [
        (Biometry.faceID, "Lock with Face ID", "Unlock with Face ID", "faceid",
         "Asks for Face ID or your passcode when you come back to Headroom."),
        (Biometry.touchID, "Lock with Touch ID", "Unlock with Touch ID", "touchid",
         "Asks for Touch ID or your passcode when you come back to Headroom."),
        (Biometry.opticID, "Lock with Optic ID", "Unlock with Optic ID", "opticid",
         "Asks for Optic ID or your passcode when you come back to Headroom."),
        (Biometry.none, "Lock with passcode", "Unlock with passcode", "lock",
         "Asks for your passcode when you come back to Headroom."),
    ])
    func copy(kind: Biometry, toggle: String, unlock: String, symbol: String, footer: String) {
        #expect(kind.lockTitle == toggle)
        #expect(kind.unlockTitle == unlock)
        #expect(kind.symbolName == symbol)
        #expect(kind.lockFooter == footer)
    }

    @Test("the setting is remembered")
    func persists() {
        let defaults = UserDefaults(suiteName: "AppLockTests-\(UUID().uuidString)")!
        AppLock(authenticator: StubAuthenticator(), defaults: defaults).isEnabled = true
        #expect(AppLock(authenticator: StubAuthenticator(), defaults: defaults).isEnabled)
    }
}
