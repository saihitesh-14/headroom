import HeadroomCore
import SwiftUI

struct RootView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(AppLock.self) private var lock
    @Environment(PlanStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var today = LocalDate.today()
    @State private var selectedTab = AppTab.ask

    /// Amounts are hidden in the app switcher and while locked.
    private var covered: Bool { lock.isLocked || scenePhase != .active }

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Ask", systemImage: "chart.line.flattrend.xyaxis", value: AppTab.ask) {
                AskView(selectedTab: $selectedTab)
            }
            Tab("Plan", systemImage: "calendar", value: AppTab.plan) {
                PlanView()
            }
            Tab("Settings", systemImage: "gearshape", value: AppTab.settings) {
                SettingsView()
            }
        }
        .tint(Theme.accent)
        .environment(\.today, today)
        .accessibilityHidden(covered)
        .overlay {
            ZStack {
                if covered {
                    PrivacyCover(isLocked: lock.isLocked, biometry: lock.biometry) {
                        Task { await lock.unlock() }
                    }
                    // Appears at once, so the app-switcher snapshot never catches it half drawn;
                    // fades out on unlock.
                    .transition(.asymmetric(insertion: .identity, removal: .opacity))
                }
            }
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: covered)
        }
        .onChange(of: scenePhase) { _, phase in
            lock.scenePhaseChanged(to: phase)
            if phase == .active {
                today = .today()
                store.reloadIfUnavailable()
                Task { await lock.appBecameActive() }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
            today = .today()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.protectedDataDidBecomeAvailableNotification)) { _ in
            store.reloadIfUnavailable()
        }
        .task {
            await lock.appBecameActive()
        }
    }
}

enum AppTab: Hashable {
    case ask, plan, settings
}

/// The lock cover and app-switcher snapshot (docs/REDESIGN-SPEC.md 5.7): the wordmark on the
/// datum, with no amounts. When locked, it says so and offers Unlock (retry stays manual).
private struct PrivacyCover: View {
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
