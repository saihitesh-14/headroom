import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            Theme.canvas.ignoresSafeArea()
                .navigationTitle("Settings")
        }
    }
}
