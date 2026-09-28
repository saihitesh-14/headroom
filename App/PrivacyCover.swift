import SwiftUI
import UIKit

/// The lock cover and app-switcher snapshot (docs/REDESIGN-SPEC.md 5.7): the wordmark on the
/// datum, with no amounts. When locked, it says so and offers Unlock (retry stays manual).
struct PrivacyCover: View {
    let isLocked: Bool
    let biometry: Biometry
    let onUnlock: () -> Void

    var body: some View {
        GeometryReader { proxy in
            VStack(alignment: .leading, spacing: 0) {
                Text("Headroom")
                    .overpass(.wordmark)
                    .foregroundStyle(Theme.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                DatumRule()
                    .padding(.top, Theme.Space.s)
                if isLocked {
                    Text("Locked. Unlock to see your plan.")
                        .font(.body)
                        .foregroundStyle(Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, Theme.Space.xl)
                    Button(action: onUnlock) {
                        Label(biometry.unlockTitle, systemImage: biometry.symbolName)
                            .foregroundStyle(Theme.onAccent)
                    }
                    .buttonStyle(.glassProminent)
                    .controlSize(.large)
                    .padding(.top, Theme.Space.l)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .scenePadding(.horizontal)
            // The top of the block sits at 40% of the height.
            .padding(.top, proxy.size.height * 0.4)
        }
        .background(Theme.canvas.ignoresSafeArea())
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
    }
}

/// The privacy cover in a window of its own, above the app's window.
///
/// Sheets, popovers and dialogs are presented inside the app's window, above the view that
/// presents them, so a cover drawn in the view tree would sit under an open Confirm details
/// or balance sheet. This window sits above all of them. While it shows, the app's window is
/// hidden from VoiceOver. It appears at once, so the app-switcher snapshot never catches it
/// half drawn, and fades out (0.2 s, instant with Reduce Motion) letting touches through.
@MainActor
final class PrivacyCoverWindow {
    private let lock: AppLock
    private(set) var window: UIWindow?
    private weak var appWindow: UIWindow?
    /// Whether the cover should show; kept until there is a window to show it in.
    private var isCovering = false

    init(lock: AppLock) {
        self.lock = lock
    }

    /// Makes the cover's window on the app window's scene, and shows it if it should show.
    func attach(to appWindow: UIWindow) {
        guard appWindow !== self.appWindow, let scene = appWindow.windowScene else { return }
        window?.isHidden = true
        self.appWindow = appWindow

        let host = UIHostingController(rootView: PrivacyCoverRoot(lock: lock))
        host.view.backgroundColor = .clear
        host.view.accessibilityViewIsModal = true
        let window = UIWindow(windowScene: scene)
        window.windowLevel = .alert + 1
        window.backgroundColor = .clear
        window.rootViewController = host
        window.isHidden = true
        self.window = window
        apply(animated: false)
    }

    func setCovered(_ covered: Bool, animated: Bool) {
        guard covered != isCovering else { return }
        isCovering = covered
        apply(animated: animated)
    }

    private func apply(animated: Bool) {
        guard let window else { return }
        appWindow?.accessibilityElementsHidden = isCovering
        if isCovering {
            // Instant: any fade still running is dropped and the cover is whole.
            window.layer.removeAllAnimations()
            window.alpha = 1
            window.isUserInteractionEnabled = true
            window.isHidden = false
            UIAccessibility.post(notification: .screenChanged, argument: nil)
        } else {
            window.isUserInteractionEnabled = false
            UIAccessibility.post(notification: .screenChanged, argument: nil)
            guard animated, !window.isHidden else {
                window.isHidden = true
                return
            }
            UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseInOut]) {
                window.alpha = 0
            } completion: { [weak self] _ in
                // Covered again while fading: that cover stays.
                guard let self, !self.isCovering else { return }
                window.isHidden = true
                window.alpha = 1
            }
        }
    }
}

/// Keeps the cover's window in step with RootView: it finds the app's window and passes on
/// whether the cover should show.
struct PrivacyCoverPresenter: UIViewRepresentable {
    let lock: AppLock
    let covered: Bool
    /// False with Reduce Motion: the cover then also leaves at once.
    let animated: Bool

    func makeCoordinator() -> PrivacyCoverWindow { PrivacyCoverWindow(lock: lock) }

    func makeUIView(context: Context) -> WindowAnchor {
        let anchor = WindowAnchor()
        let cover = context.coordinator
        anchor.onWindow = { [weak cover] window in cover?.attach(to: window) }
        return anchor
    }

    func updateUIView(_ anchor: WindowAnchor, context: Context) {
        context.coordinator.setCovered(covered, animated: animated)
    }

    /// An empty view that reports the window it lands in.
    final class WindowAnchor: UIView {
        var onWindow: ((UIWindow) -> Void)?

        override init(frame: CGRect) {
            super.init(frame: frame)
            isUserInteractionEnabled = false
            isAccessibilityElement = false
        }

        required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

        override func didMoveToWindow() {
            super.didMoveToWindow()
            if let window { onWindow?(window) }
        }
    }
}

/// The cover as its window shows it, following the lock as it changes.
private struct PrivacyCoverRoot: View {
    let lock: AppLock

    var body: some View {
        PrivacyCover(isLocked: lock.isLocked, biometry: lock.biometry) {
            Task { await lock.unlock() }
        }
    }
}
