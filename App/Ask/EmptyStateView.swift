import SwiftUI

/// First launch: what Headroom does and two ways to start.
struct EmptyStateView: View {
    let onSetUp: () -> Void
    let onSample: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.xl) {
            Image(systemName: "chart.line.downtrend.xyaxis")
                .font(.system(size: 44, weight: .medium))
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: Theme.Space.s) {
                Text("See a purchase before you make it")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text("Add your balance, paychecks, and bills. Then ask what a purchase does to checking.")
                    .font(.body)
                    .foregroundStyle(Theme.textSecondary)
            }
            VStack(spacing: Theme.Space.m) {
                Button(action: onSetUp) {
                    Text("Set up my plan").frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
                Button(action: onSample) {
                    Text("Try the sample plan").frame(maxWidth: .infinity)
                }
                .buttonStyle(.glass)
            }
            .controlSize(.large)
            Label("Headroom never sends your plan anywhere.", systemImage: "lock")
                .font(.footnote)
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(.horizontal, Theme.Space.xl)
        .padding(.top, Theme.Space.xl)
    }
}
