import SwiftUI

/// First launch (docs/REDESIGN-SPEC.md 5.6): the instrument drawn with no numbers, what
/// Headroom does, and two ways to start. One prominent button. Static, so nothing to gate
/// for Reduce Motion.
struct EmptyStateView: View {
    let onSetUp: () -> Void
    let onSample: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.xl) {
                SectionDrawing()
                    .padding(.vertical, Theme.Space.s)
                VStack(alignment: .leading, spacing: Theme.Space.s) {
                    Text("See a purchase before you make it")
                        .overpass(.verdict)
                        .foregroundStyle(Theme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                    Text("Add your balance, paychecks, and bills. Then ask what a purchase does to checking.")
                        .font(.body)
                        .foregroundStyle(Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                VStack(alignment: .leading, spacing: Theme.Space.s) {
                    Button(action: onSetUp) {
                        Text("Set up your plan").foregroundStyle(Theme.onAccent)
                    }
                    .buttonStyle(.glassProminent)
                    .controlSize(.large)
                    Button(action: onSample) {
                        Text("Try the sample plan")
                            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                            .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Theme.accent)
                }
                Label("Headroom never sends your plan anywhere.", systemImage: "lock")
                    .font(.footnote)
                    .foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .scenePadding(.horizontal)
            .padding(.top, Theme.Space.s)
            .padding(.bottom, Theme.Space.xxl)
        }
    }
}
