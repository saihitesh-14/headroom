import HeadroomCore
import Testing
@testable import Headroom

/// "Coming up" on Ask (docs/REDESIGN-SPEC.md 5.1): the running-balance register from today
/// down to the lowest day, for the sample plan with today = Sun Sep 27 2026.
@Suite("Coming up")
struct ComingUpListTests {
    let today = LocalDate(year: 2026, month: 9, day: 27)!

    func date(_ month: Int, _ day: Int) -> LocalDate { LocalDate(year: 2026, month: month, day: day)! }

    func sampleEntries() throws -> [RegisterEntry] {
        guard case .room(let detail) = CashEngine.roomDetail(SamplePlan.make(today: today), today: today) else {
            throw CancellationError()
        }
        return CashEngine.register(detail.points, through: detail.low.date)
    }

    /// `count` lines of $10 out, one a day from Mon Sep 28, starting from $1,000.
    func entries(_ count: Int, cents: Int = 1_000) -> [RegisterEntry] {
        (0..<count).map { index in
            RegisterEntry(name: "Bill \(index + 1)", amount: Money(cents: -cents), date: today.adding(days: index + 1),
                          balanceAfter: Money(cents: 100_000 - cents * (index + 1)), isIncome: false)
        }
    }

    @Test("the sample rows read as in the wireframe, ending on the lowest day")
    func sampleRows() throws {
        let model = ComingUpModel(entries: try sampleEntries())
        #expect(model.rows.map(\.name) == ["Groceries", "Paycheck", "Rent", "Groceries", "Phone", "Groceries"])
        #expect(model.rows.map(\.amount) == ["\u{2212}$100", "+$800", "\u{2212}$750", "\u{2212}$100", "\u{2212}$45", "\u{2212}$100"])
        #expect(model.rows.map(\.balance) == ["Balance $900", "Balance $1,700", "Balance $950", "Balance $850",
                                              "Balance $805", "Balance $705"])
        #expect(model.rows.first?.meta == "Tue\u{00A0}Sep\u{00A0}29")
        #expect(model.rows.last?.meta == "Tue\u{00A0}Oct\u{00A0}13, your lowest")
        #expect(model.rows.map(\.isLowest) == [false, false, false, false, false, true])
        #expect(model.rows.map(\.id) == Array(0..<6))
    }

    @Test("each row is one VoiceOver sentence with a full date and spoken signs")
    func spoken() throws {
        let model = ComingUpModel(entries: try sampleEntries())
        #expect(model.rows[0].spokenLabel == "Groceries, Tuesday, September 29, minus $100, balance $900")
        #expect(model.rows[1].spokenLabel == "Paycheck, Thursday, October 1, plus $800, balance $1,700")
        #expect(model.rows[5].spokenLabel == "Groceries, Tuesday, October 13, your lowest, minus $100, balance $705")
    }

    @Test("six rows or fewer all show, with nothing to expand")
    func sixRows() throws {
        let model = ComingUpModel(entries: try sampleEntries())
        #expect(model.hiddenCount == 0)
        #expect(model.expandLabel == nil)
        #expect(model.visible(expanded: false).before.count == 6)
        #expect(model.visible(expanded: false).after.isEmpty)
    }

    @Test("past six rows, the first five and the lowest day show, and the rest expand in place")
    func collapsed() {
        let model = ComingUpModel(entries: entries(9))
        #expect(model.hiddenCount == 3)
        #expect(model.expandLabel == "Show 3 more before Tue\u{00A0}Oct\u{00A0}6")
        let collapsed = model.visible(expanded: false)
        #expect(collapsed.before.map(\.id) == [0, 1, 2, 3, 4])
        #expect(collapsed.after.map(\.id) == [8])
        #expect(collapsed.after.first?.isLowest == true)
        let expanded = model.visible(expanded: true)
        #expect(expanded.before.map(\.id) == Array(0..<9))
        #expect(expanded.after.isEmpty)
        #expect(ComingUpModel(entries: entries(7)).expandLabel == "Show 1 more before Sun\u{00A0}Oct\u{00A0}4")
    }

    @Test("a column where any row has cents shows cents on every row")
    func cents() {
        var list = entries(2)
        list.append(RegisterEntry(name: "Coffee", amount: Money(cents: -450), date: date(10, 1),
                                  balanceAfter: Money(cents: 97_550), isIncome: false))
        let model = ComingUpModel(entries: list)
        #expect(model.rows.map(\.amount) == ["\u{2212}$10.00", "\u{2212}$10.00", "\u{2212}$4.50"])
        #expect(model.rows.map(\.balance) == ["Balance $990.00", "Balance $980.00", "Balance $975.50"])
    }

    @Test("no entries leaves nothing to list")
    func empty() {
        let model = ComingUpModel(entries: [])
        #expect(model.rows.isEmpty)
        #expect(model.expandLabel == nil)
    }
}
