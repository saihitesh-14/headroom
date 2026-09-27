import HeadroomCore
import SwiftUI

struct SettingsView: View {
    @Environment(PlanStore.self) private var store
    @Environment(AppLock.self) private var lock
    @Environment(\.today) private var today
    @State private var confirmingDelete = false
    @State private var confirmingSample = false

    var body: some View {
        @Bindable var lock = lock
        NavigationStack {
            List {
                Section {
                    Toggle("Lock with Face ID", isOn: $lock.isEnabled)
                        .disabled(lock.unavailableReason != nil)
                        .tint(Theme.accent)
                } footer: {
                    Text(lock.unavailableReason ?? "Asks for Face ID or your passcode when you come back to Headroom.")
                }

                Section {
                    Label("No network requests", systemImage: "wifi.slash")
                    Label("Stored only on this iPhone", systemImage: "iphone")
                    Label("Protected while the phone is locked", systemImage: "lock.shield")
                } header: {
                    Text("Privacy")
                } footer: {
                    Text("Headroom has no accounts and no analytics. Your plan is included in your encrypted iPhone backups.")
                }

                Section {
                    Button("Load the sample plan") { confirmingSample = true }
                    Button("Delete all data", role: .destructive) { confirmingDelete = true }
                } footer: {
                    Text("Loading the sample plan replaces your current plan.")
                }

                Section {
                    LabeledContent("Version", value: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "")
                } footer: {
                    Text("Headroom gives estimates from the plan you enter. It is not financial advice.")
                }
            }
            .themedList()
            .navigationTitle("Settings")
            .confirmationDialog("Delete your plan, balance, and settings from this iPhone?",
                                isPresented: $confirmingDelete, titleVisibility: .visible) {
                Button("Delete all data", role: .destructive) {
                    store.deleteAll()
                    lock.isEnabled = false
                }
            }
            .confirmationDialog("Replace your plan with the sample plan?",
                                isPresented: $confirmingSample, titleVisibility: .visible) {
                Button("Load the sample plan") { store.update { $0 = SamplePlan.make(today: today) } }
            }
        }
    }
}
