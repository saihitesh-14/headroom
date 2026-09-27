import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            Tab("Ask", systemImage: "text.bubble") {
                AskView()
            }
            Tab("Plan", systemImage: "calendar") {
                PlanView()
            }
            Tab("Settings", systemImage: "gearshape") {
                SettingsView()
            }
        }
        .tint(Theme.accent)
    }
}

#Preview {
    RootView()
}
