import Foundation
import SwiftUI
import Testing
@testable import Headroom

/// A stand-in for Face ID / passcode.
final class StubAuthenticator: Authenticator, @unchecked Sendable {
    var available = true
    var succeeds = true
    private(set) var prompts = 0

    func availability() -> String? { available ? nil : "Set a passcode on this iPhone to use the lock." }

    func authenticate(reason: String) async -> Bool {
        prompts += 1
        return succeeds
    }
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

    @Test("the setting is remembered")
    func persists() {
        let defaults = UserDefaults(suiteName: "AppLockTests-\(UUID().uuidString)")!
        AppLock(authenticator: StubAuthenticator(), defaults: defaults).isEnabled = true
        #expect(AppLock(authenticator: StubAuthenticator(), defaults: defaults).isEnabled)
    }
}
