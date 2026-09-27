import LocalAuthentication
import Observation
import SwiftUI

/// Face ID / Touch ID / passcode, behind a protocol so the lock rules are testable.
protocol Authenticator: Sendable {
    /// nil when this device can authenticate; otherwise the reason to show.
    func availability() -> String?
    func authenticate(reason: String) async -> Bool
}

struct DeviceAuthenticator: Authenticator {
    func availability() -> String? {
        var error: NSError?
        // A fresh context every time; contexts are single-use.
        if LAContext().canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) { return nil }
        return "Set a passcode on this iPhone to use the lock."
    }

    func authenticate(reason: String) async -> Bool {
        do {
            return try await LAContext().evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)
        } catch {
            return false
        }
    }
}

/// Opt-in app lock. Locks only when the app goes to the background: the Face ID
/// prompt itself makes the app inactive, so locking on inactive would loop.
@MainActor
@Observable
final class AppLock {
    static let enabledKey = "appLockEnabled"

    private let authenticator: any Authenticator
    private let defaults: UserDefaults
    private(set) var isLocked = false
    private var isAuthenticating = false
    /// Set when the app locks in the background; the next return to the app prompts once.
    private var promptWhenActive = false

    var isEnabled: Bool {
        didSet { defaults.set(isEnabled, forKey: Self.enabledKey) }
    }

    /// Why the lock cannot be turned on, or nil when it can.
    var unavailableReason: String? { authenticator.availability() }

    init(authenticator: any Authenticator = DeviceAuthenticator(), defaults: UserDefaults = .standard) {
        self.authenticator = authenticator
        self.defaults = defaults
        isEnabled = defaults.bool(forKey: Self.enabledKey)
        isLocked = isEnabled && authenticator.availability() == nil
        promptWhenActive = isLocked
    }

    func scenePhaseChanged(to phase: ScenePhase) {
        guard phase == .background, isEnabled, authenticator.availability() == nil else { return }
        isLocked = true
        promptWhenActive = true
    }

    /// Prompts once after returning from the background (or at launch). Closing the Face ID
    /// sheet also makes the app active, so this must not prompt again; Unlock retries.
    func appBecameActive() async {
        guard promptWhenActive, isLocked else { return }
        promptWhenActive = false
        await unlock()
    }

    func unlock() async {
        guard isLocked, !isAuthenticating else { return }
        isAuthenticating = true
        defer { isAuthenticating = false }
        if await authenticator.authenticate(reason: "Unlock Headroom to see your plan.") {
            isLocked = false
        }
    }
}
