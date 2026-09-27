import SwiftUI

struct AskView: View {
    @Binding var selectedTab: AppTab

    var body: some View {
        NavigationStack {
            Theme.canvas.ignoresSafeArea()
                .navigationTitle("Ask")
        }
    }
}
