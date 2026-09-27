import HeadroomCore
import SwiftUI

struct RootView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(AppLock.self) private var lock
    @State private var today = LocalDate.today()
    @State private var selectedTab = AppTab.ask

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Ask", systemImage: "text.bubble", value: AppTab.ask) {
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
        .overlay {
            // Hide amounts in the app switcher, and while locked.
            if lock.isLocked || scenePhase != .active {
                PrivacyCover(isLocked: lock.isLocked) {
                    Task { await lock.unlock() }
                }
            }
        }
        .onChange(of: scenePhase) { _, phase in
            lock.scenePhaseChanged(to: phase)
            if phase == .active {
                today = .today()
                if lock.isLocked { Task { await lock.unlock() } }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
            today = .today()
        }
        .task {
            if lock.isLocked { await lock.unlock() }
        }
    }
}

enum AppTab: Hashable {
    case ask, plan, settings
}

/// Covers the app with no amounts visible. Offers Unlock when the lock is on.
private struct PrivacyCover: View {
    let isLocked: Bool
    let onUnlock: () -> Void

    var body: some View {
        ZStack {
            Theme.canvas.ignoresSafeArea()
            VStack(spacing: Theme.Space.l) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 36, weight: .medium))
                    .foregroundStyle(Theme.accent)
                Text("Headroom")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                if isLocked {
                    Button("Unlock", action: onUnlock)
                        .buttonStyle(.glassProminent)
                        .controlSize(.large)
                }
            }
        }
        .accessibilityElement(children: .contain)
    }
}
