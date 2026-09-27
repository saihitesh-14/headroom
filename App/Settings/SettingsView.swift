import HeadroomCore
import SwiftUI

/// Settings (docs/REDESIGN-SPEC.md 5.5): the lock, on-device AI, what Headroom does with
/// your plan, the sample plan and deleting everything, and acknowledgments. All system type.
struct SettingsView: View {
    @Environment(PlanStore.self) private var store
    @Environment(AppLock.self) private var lock
    @Environment(\.today) private var today
    @State private var confirmingDelete = false
    @State private var confirmingSample = false
    @AppStorage(OnDeviceAI.settingKey) private var useOnDeviceAI = true

    private var aiUnavailableReason: String? {
        if case .unavailable(let reason) = OnDeviceAI.availability { return reason }
        return nil
    }

    private var aiBinding: Binding<Bool> {
        Binding(get: { useOnDeviceAI && aiUnavailableReason == nil }, set: { useOnDeviceAI = $0 })
    }

    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
    }

    var body: some View {
        @Bindable var lock = lock
        let biometry = lock.biometry
        let lockUnavailableReason = lock.unavailableReason
        NavigationStack {
            List {
                Section {
                    Toggle(biometry.lockTitle, isOn: $lock.isEnabled)
                        .disabled(lockUnavailableReason != nil)
                        .tint(Theme.accent)
                } footer: {
                    Text(lockUnavailableReason ?? biometry.lockFooter).sectionText()
                }

                Section {
                    Toggle("Read questions with on-device AI", isOn: aiBinding)
                        .disabled(aiUnavailableReason != nil)
                        .tint(Theme.accent)
                } footer: {
                    Text(aiUnavailableReason
                         ?? "Uses Apple's on-device model to read your question. It never leaves this iPhone, and prices always come from the digits you type.")
                        .sectionText()
                }

                Section {
                    privacyRow("Headroom never sends your plan anywhere.", systemImage: "iphone")
                    privacyRow("Works without internet", systemImage: "wifi.slash")
                    privacyRow("Unreadable while your iPhone is locked", systemImage: "lock.shield")
                } header: {
                    Text("Privacy").sectionText()
                } footer: {
                    Text("Headroom has no accounts and no analytics. Your plan is included in your iPhone backups.")
                        .sectionText()
                }

                Section {
                    Button("Try the sample plan") { confirmingSample = true }
                    Button("Delete everything", role: .destructive) { confirmingDelete = true }
                } footer: {
                    Text("The sample plan replaces your current plan.").sectionText()
                }

                Section {
                    NavigationLink("Acknowledgments") { AcknowledgmentsView() }
                    LabeledContent("Version") {
                        Text(version).foregroundStyle(Theme.textSecondary)
                    }
                } footer: {
                    Text("Headroom gives estimates from the plan you enter. It is not financial advice.")
                        .sectionText()
                }
            }
            .themedList()
            .navigationTitle("Settings")
            .confirmationDialog("Delete your plan, balance, and settings from this iPhone?",
                                isPresented: $confirmingDelete, titleVisibility: .visible) {
                Button("Delete everything", role: .destructive) {
                    store.deleteAll()
                    lock.isEnabled = false
                }
            }
            .confirmationDialog("Replace your plan with the sample plan?",
                                isPresented: $confirmingSample, titleVisibility: .visible) {
                Button("Replace plan", role: .destructive) {
                    store.update { $0 = SamplePlan.make(today: today) }
                }
            }
        }
    }

    /// A statement, not a control: Ink words beside a Graphite symbol.
    private func privacyRow(_ title: String, systemImage: String) -> some View {
        Label {
            Text(title).foregroundStyle(Theme.textPrimary)
        } icon: {
            Image(systemName: systemImage).foregroundStyle(Theme.textSecondary)
        }
    }
}
