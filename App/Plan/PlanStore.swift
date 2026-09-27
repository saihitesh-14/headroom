import Foundation
import HeadroomCore
import Observation

/// Keeps the plan in one JSON file in Application Support, written with complete
/// file protection (unreadable while the phone is locked). No network, no analytics.
@MainActor
@Observable
final class PlanStore {
    private(set) var plan: CashPlan
    private(set) var saveFailed = false
    let fileURL: URL

    static var defaultFileURL: URL {
        URL.applicationSupportDirectory.appending(path: "Headroom/plan.json")
    }

    init(fileURL: URL = PlanStore.defaultFileURL) {
        self.fileURL = fileURL
        plan = Self.load(from: fileURL)
    }

    /// A missing or unreadable file starts an empty plan rather than crashing.
    static func load(from url: URL) -> CashPlan {
        guard let data = try? Data(contentsOf: url),
              let plan = try? JSONDecoder().decode(CashPlan.self, from: data) else { return CashPlan() }
        return plan
    }

    func update(_ change: (inout CashPlan) -> Void) {
        change(&plan)
        save()
    }

    func confirmBalance(_ amount: Money, today: LocalDate, billsAlreadyOut: Set<UUID>, incomeStillComing: Set<UUID>) {
        update {
            $0.balance = BalanceSnapshot(amount: amount, asOf: today,
                                         billsAlreadyOutToday: billsAlreadyOut,
                                         incomeStillComingToday: incomeStillComing)
        }
    }

    func upsert(_ event: CashEvent) {
        update { plan in
            if let index = plan.events.firstIndex(where: { $0.id == event.id }) {
                plan.events[index] = event
            } else {
                plan.events.append(event)
            }
        }
    }

    func delete(eventID: UUID) {
        update { $0.events.removeAll { $0.id == eventID } }
    }

    func deleteAll() {
        plan = CashPlan()
        try? FileManager.default.removeItem(at: fileURL)
        saveFailed = false
    }

    private func save() {
        do {
            try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(),
                                                    withIntermediateDirectories: true)
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
            try encoder.encode(plan).write(to: fileURL, options: [.atomic, .completeFileProtection])
            saveFailed = false
        } catch {
            saveFailed = true
        }
    }
}
