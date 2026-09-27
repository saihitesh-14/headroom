import HeadroomCore
import SwiftUI

@main
struct HeadroomApp: App {
    @State private var store: PlanStore
    @State private var lock: AppLock

    init() {
        Typography.register()
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("-uiTestSamplePlan") || arguments.contains("-uiTestEmptyPlan") {
            // UI tests run against a throwaway file (the sample plan confirmed today, or nothing)
            // and throwaway settings, so a lock turned on by hand never blocks a test.
            let url = URL.temporaryDirectory.appending(path: "uitest-plan.json")
            try? FileManager.default.removeItem(at: url)
            let store = PlanStore(fileURL: url)
            if arguments.contains("-uiTestSamplePlan") {
                store.update { $0 = SamplePlan.make(today: .today()) }
            }
            let defaults = UserDefaults(suiteName: "uitest")!
            defaults.removePersistentDomain(forName: "uitest")
            _store = State(initialValue: store)
            _lock = State(initialValue: AppLock(defaults: defaults))
        } else {
            _store = State(initialValue: PlanStore())
            _lock = State(initialValue: AppLock())
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .environment(lock)
        }
    }
}
