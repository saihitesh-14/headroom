import HeadroomCore
import SwiftUI

struct RootView: View {
    @Environment(\.scenePhase) private var scenePhase
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
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { today = .today() }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
            today = .today()
        }
    }
}

enum AppTab: Hashable {
    case ask, plan, settings
}
