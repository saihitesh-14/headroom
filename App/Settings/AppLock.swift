import LocalAuthentication
import Observation
import SwiftUI

/// What unlocks Headroom besides the passcode. It names the lock in Settings and on the cover.
enum Biometry: Equatable, Sendable {
    /// `none` means only the passcode unlocks.
    case faceID, touchID, opticID, none

    /// "Face ID", or nil for the passcode alone.
    var name: String? {
        switch self {
        case .faceID: "Face ID"
        case .touchID: "Touch ID"
        case .opticID: "Optic ID"
        case .none: nil
        }
    }

    /// The Settings toggle: "Lock with Face ID", or "Lock with passcode".
    var lockTitle: String { "Lock with \(name ?? "passcode")" }

    /// The lock cover's button: "Unlock with Face ID", or "Unlock with passcode".
    var unlockTitle: String { "Unlock with \(name ?? "passcode")" }

    /// The SF Symbol beside `unlockTitle`.
    var symbolName: String {
        switch self {
        case .faceID: "faceid"
        case .touchID: "touchid"
        case .opticID: "opticid"
        case .none: "lock"
        }
    }

    /// The Settings footer under the toggle.
    var lockFooter: String {
        guard let name else { return "Asks for your passcode when you come back to Headroom." }
        return "Asks for \(name) or your passcode when you come back to Headroom."
    }
}

/// Face ID / Touch ID / passcode, behind a protocol so the lock rules are testable.
protocol Authenticator: Sendable {
    /// nil when this device can authenticate; otherwise the reason to show.
    func availability() -> String?
    func authenticate(reason: String) async -> Bool
    /// What the prompt will ask for besides the passcode.
    func biometry() -> Biometry
}

extension Authenticator {
    /// An authenticator that does not say is taken to use the passcode alone.
    func biometry() -> Biometry { .none }
}

struct DeviceAuthenticator: Authenticator {
    func availability() -> String? {
        var error: NSError?
        // A fresh context every time; contexts are single-use.
        if LAContext().canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) { return nil }
        return "Set a passcode on this iPhone to use the lock."
    }

    /// The enrolled biometry that can unlock right now. Face ID that is not set up, turned
    /// off for Headroom, or locked out leaves the passcode, so that reads as `none`.
    func biometry() -> Biometry {
        let context = LAContext()
        var error: NSError?
        // biometryType is only filled in after canEvaluatePolicy.
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else { return .none }
        switch context.biometryType {
        case .faceID: return .faceID
        case .touchID: return .touchID
        case .opticID: return .opticID
        case .none: return .none
        @unknown default: return .none
        }
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

    /// What unlocks the app besides the passcode, for the toggle and the Unlock button.
    var biometry: Biometry { authenticator.biometry() }

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
