import HeadroomCore
import SwiftUI

@main
struct HeadroomApp: App {
    @State private var store: PlanStore

    init() {
        if ProcessInfo.processInfo.arguments.contains("-uiTestSamplePlan") {
            // UI tests run against a throwaway file holding the sample plan, confirmed today.
            let url = URL.temporaryDirectory.appending(path: "uitest-plan.json")
            try? FileManager.default.removeItem(at: url)
            let store = PlanStore(fileURL: url)
            store.update { $0 = SamplePlan.make(today: .today()) }
            _store = State(initialValue: store)
        } else {
            _store = State(initialValue: PlanStore())
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
        }
    }
}
