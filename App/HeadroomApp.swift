import HeadroomCore
import SwiftUI

@main
struct HeadroomApp: App {
    @State private var store: PlanStore

    init() {
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("-uiTestSamplePlan") || arguments.contains("-uiTestEmptyPlan") {
            // UI tests run against a throwaway file: the sample plan confirmed today, or nothing.
            let url = URL.temporaryDirectory.appending(path: "uitest-plan.json")
            try? FileManager.default.removeItem(at: url)
            let store = PlanStore(fileURL: url)
            if arguments.contains("-uiTestSamplePlan") {
                store.update { $0 = SamplePlan.make(today: .today()) }
            }
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
