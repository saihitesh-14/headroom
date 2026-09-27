import HeadroomCore
import SwiftUI
import Testing
@testable import Headroom

/// The Ask gauge's data (docs/REDESIGN-SPEC.md 5.1 and 6.6) for the sample plan with
/// today = Sun Sep 27 2026: room $505, lowest $705 on Tue Oct 13, the wireframe numbers.
@MainActor
@Suite("Room gauge")
struct RoomGaugeTests {
    let today = LocalDate(year: 2026, month: 9, day: 27)!

    func date(_ month: Int, _ day: Int) -> LocalDate { LocalDate(year: 2026, month: month, day: day)! }

    func detail(_ change: (inout CashPlan) -> Void = { _ in }) throws -> RoomDetail {
        var plan = SamplePlan.make(today: today)
        change(&plan)
        guard case .room(let detail) = CashEngine.roomDetail(plan, today: today) else { throw CancellationError() }
        return detail
    }

    @Test("the window runs from today through a week past the low")
    func window() throws {
        let model = RoomGaugeModel(try detail())
        #expect(model.windowEnd == date(10, 20))
        #expect(model.windowDays == 23)
        #expect(model.xDomain == 0...24)
        #expect(model.path.count == 2 * 24 + 1)
        #expect(model.path.first == ChartPoint(x: 0, amount: .dollars(1_000)))
        #expect(model.path.last?.x == 24)
        #expect(model.path.map(\.amount).min() == .dollars(705))
    }

    @Test("marks sit at the engine's low and floor, measured up from the floor")
    func marks() throws {
        let model = RoomGaugeModel(try detail())
        #expect(model.floor == 20_000)
        #expect(model.datum == 20_000)
        #expect(model.low == 70_500)
        #expect(model.lowX == 16.25)
        #expect(model.clearance == .above)
        #expect(model.tint == Theme.accent)
        #expect(!model.showsBelowFloorArea)
        #expect(!model.showsZeroRule)
        // lo = $0, hi = $1,700: 6% below (at least $50) and 8% above (at least $50).
        #expect(model.domain == -10_200...183_600)
    }

    @Test("the caption names the low, and takes the floor from the plot at accessibility sizes")
    func caption() throws {
        let model = RoomGaugeModel(try detail())
        #expect(model.floorLabel == "Floor $200")
        #expect(model.caption(accessibilitySize: false) == "Lowest $705 on Tue\u{00A0}Oct\u{00A0}13")
        #expect(model.caption(accessibilitySize: true) == "Lowest $705 on Tue\u{00A0}Oct\u{00A0}13. Floor $200.")
        #expect(model.accessibilityValue == Explainer.roomSummary(try detail()))
    }

    @Test("a low below the floor hangs from the datum in Amber, over the below-floor fill")
    func belowFloor() throws {
        let model = RoomGaugeModel(try detail { $0.floor = .dollars(800) })
        #expect(model.clearance == .below)
        #expect(model.tint == Theme.warning)
        #expect(model.datum == 80_000)
        #expect(model.low == 70_500)
        #expect(model.showsBelowFloorArea)
        #expect(!model.showsZeroRule)
    }

    @Test("a low exactly at the floor has no clearance line: the ring sits on the datum")
    func atFloor() throws {
        let model = RoomGaugeModel(try detail { $0.floor = .dollars(705) })
        #expect(model.clearance == .above)
        #expect(model.datum == model.low)
        #expect(!model.showsBelowFloorArea)
    }

    @Test("a low below $0 is measured from the $0 rule in Brick")
    func belowZero() throws {
        let model = RoomGaugeModel(try detail { $0.balance = BalanceSnapshot(amount: .dollars(200), asOf: today) })
        #expect(model.low == -9_500)
        #expect(model.clearance == .belowZero)
        #expect(model.tint == Theme.danger)
        #expect(model.datum == 0)
        #expect(model.showsZeroRule)
        #expect(model.showsBelowFloorArea)
        #expect(model.domain.contains(-9_500))
    }
}

/// What the top of Ask shows: the reading, the stale-balance question, or what is missing.
@Suite("Ask home state")
struct AskHomeStateTests {
    let today = LocalDate(year: 2026, month: 9, day: 27)!

    @Test("a plan confirmed today shows the room and its detail")
    func room() {
        guard case .room(let detail) = AskHomeState(plan: SamplePlan.make(today: today), today: today) else {
            Issue.record("expected the room")
            return
        }
        #expect(detail.room == .dollars(505))
    }

    @Test("when the only thing missing is today's confirmation, it asks about the balance")
    func stale() {
        let yesterday = today.adding(days: -1)
        var plan = SamplePlan.make(today: today)
        plan.balance?.asOf = yesterday
        #expect(AskHomeState(plan: plan, today: today) == .stale(balance: .dollars(1_000), lastConfirmed: yesterday))
    }

    @Test("anything else missing lists what to add")
    func needsInfo() {
        let yesterday = today.adding(days: -1)
        var plan = SamplePlan.make(today: today)
        plan.balance?.asOf = yesterday
        plan.floor = nil
        #expect(AskHomeState(plan: plan, today: today)
            == .needsInfo([.balanceNotConfirmedToday(lastConfirmed: yesterday), .floor]))
        #expect(AskHomeState(plan: CashPlan(floor: .dollars(0)), today: today) == .needsInfo([.balance, .noEvents]))
    }
}
