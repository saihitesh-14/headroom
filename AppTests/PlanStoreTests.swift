import Foundation
import HeadroomCore
import Testing
@testable import Headroom

@MainActor
@Suite("PlanStore")
struct PlanStoreTests {
    let today = LocalDate(year: 2026, month: 9, day: 26)!

    func tempURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
            .appendingPathComponent("plan.json")
    }

    @Test("a saved plan loads back identically")
    func roundTrip() {
        let url = tempURL()
        let store = PlanStore(fileURL: url)
        store.update { $0 = SamplePlan.make(today: today) }
        #expect(PlanStore(fileURL: url).plan == SamplePlan.make(today: today).withIDs(from: store.plan))
        #expect(PlanStore(fileURL: url).plan == store.plan)
    }

    @Test("a missing file starts an empty plan")
    func missingFile() {
        let store = PlanStore(fileURL: tempURL())
        #expect(store.plan == CashPlan())
        #expect(!store.isUnavailable)
    }

    @Test("a corrupt file is kept aside, not overwritten, and the app starts fresh")
    func corruptFile() throws {
        let url = tempURL()
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data("{ not json".utf8).write(to: url)
        let store = PlanStore(fileURL: url)
        #expect(store.plan == CashPlan())
        #expect(!store.isUnavailable)
        let backup = url.deletingLastPathComponent().appendingPathComponent("plan.corrupt.json")
        #expect(try String(contentsOf: backup, encoding: .utf8) == "{ not json")
    }

    @Test("a file that cannot be read right now (phone locked) is never overwritten, and loads once readable")
    func unreadableFile() throws {
        let url = tempURL()
        let original = PlanStore(fileURL: url)
        original.update { $0 = SamplePlan.make(today: today) }
        try FileManager.default.setAttributes([.posixPermissions: 0o000], ofItemAtPath: url.path)
        defer { try? FileManager.default.setAttributes([.posixPermissions: 0o644], ofItemAtPath: url.path) }

        let store = PlanStore(fileURL: url)
        #expect(store.isUnavailable)
        store.update { $0 = CashPlan() }          // an edit while unavailable must not write
        try FileManager.default.setAttributes([.posixPermissions: 0o644], ofItemAtPath: url.path)
        #expect(PlanStore.load(from: url) == .loaded(original.plan))

        store.reloadIfUnavailable()
        #expect(!store.isUnavailable)
        #expect(store.plan == original.plan)
    }

    @Test("delete all removes the file and empties the plan")
    func deleteAll() {
        let url = tempURL()
        let store = PlanStore(fileURL: url)
        store.update { $0 = SamplePlan.make(today: today) }
        #expect(FileManager.default.fileExists(atPath: url.path))
        store.deleteAll()
        #expect(store.plan == CashPlan())
        #expect(!FileManager.default.fileExists(atPath: url.path))
    }

    @Test("confirming the balance stamps today and keeps today's marks")
    func confirmBalance() {
        let store = PlanStore(fileURL: tempURL())
        let rent = CashEvent(name: "Rent", amount: .dollars(750), kind: .bill, schedule: .once(today))
        store.update { $0.events = [rent] }
        store.confirmBalance(.dollars(900), today: today, billsAlreadyOut: [rent.id], incomeStillComing: [])
        #expect(store.plan.balance == BalanceSnapshot(amount: .dollars(900), asOf: today, billsAlreadyOutToday: [rent.id]))
    }
}

extension CashPlan {
    /// The same plan with event IDs copied from `other` (IDs are random per build).
    func withIDs(from other: CashPlan) -> CashPlan {
        var copy = self
        for index in copy.events.indices where index < other.events.count {
            copy.events[index].id = other.events[index].id
        }
        return copy
    }
}
