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
        // The cover draws in a window above this one, so it also covers any open sheet,
        // popover or dialog. It appears at once, so the app-switcher snapshot never catches
        // it half drawn, and fades out on unlock.
        .background {
            PrivacyCoverPresenter(lock: lock, covered: covered, animated: !reduceMotion)
                .accessibilityHidden(true)
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
