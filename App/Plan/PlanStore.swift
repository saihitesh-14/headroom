import Foundation
import HeadroomCore
import Observation

/// Keeps the plan in one JSON file in Application Support, written with complete
/// file protection (unreadable while the phone is locked). No network, no analytics.
@MainActor
@Observable
final class PlanStore {
    enum LoadResult: Equatable {
        case missing, loaded(CashPlan), unreadable, corrupt
    }

    private(set) var plan = CashPlan()
    private(set) var saveFailed = false
    /// The file exists but cannot be read right now (for example, the phone is locked and
    /// the file has complete protection). Edits are refused so the real plan is never overwritten.
    private(set) var isUnavailable = false
    let fileURL: URL

    static var defaultFileURL: URL {
        URL.applicationSupportDirectory.appending(path: "Headroom/plan.json")
    }

    init(fileURL: URL = PlanStore.defaultFileURL) {
        self.fileURL = fileURL
        apply(Self.load(from: fileURL))
    }

    static func load(from url: URL) -> LoadResult {
        guard FileManager.default.fileExists(atPath: url.path) else { return .missing }
        guard let data = try? Data(contentsOf: url) else { return .unreadable }
        guard let plan = try? JSONDecoder().decode(CashPlan.self, from: data) else { return .corrupt }
        return .loaded(plan)
    }

    /// Try again after the phone unlocks or the app becomes active.
    func reloadIfUnavailable() {
        guard isUnavailable else { return }
        apply(Self.load(from: fileURL))
    }

    private func apply(_ result: LoadResult) {
        switch result {
        case .missing:
            plan = CashPlan()
            isUnavailable = false
        case .loaded(let loaded):
            plan = loaded
            isUnavailable = false
        case .corrupt:
            // Keep the unreadable contents next to the new plan instead of overwriting them.
            let backup = fileURL.deletingLastPathComponent().appendingPathComponent("plan.corrupt.json")
            try? FileManager.default.removeItem(at: backup)
            try? FileManager.default.moveItem(at: fileURL, to: backup)
            plan = CashPlan()
            isUnavailable = false
        case .unreadable:
            plan = CashPlan()
            isUnavailable = true
        }
    }

    func update(_ change: (inout CashPlan) -> Void) {
        guard !isUnavailable else { return }
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
        guard !isUnavailable else { return }
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
