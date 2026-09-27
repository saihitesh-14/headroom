import Foundation
import Testing
@testable import HeadroomCore

@Suite("Explainer")
struct ExplainerTests {
    func analysis(_ plan: CashPlan, _ item: String, _ price: Money, _ date: LocalDate) throws -> Analysis {
        try #require(analyzed(CashEngine.analyze(plan, purchase: Purchase(item: item, price: price, date: date), today: today)))
    }

    @Test("worked example headline and summary (X1)")
    func workedExample() throws {
        let a = try analysis(workedExamplePlan(), "laptop", dollars(700), today)
        #expect(Explainer.headline(a) == "Would cross your cash floor")
        #expect(Explainer.summary(a).contains("$150"))
        #expect(Explainer.summary(a).contains("$50 below your $200 floor"))
    }

    @Test("sample plan reasons, grouped and largest first (X2)")
    func samplePlanReasons() throws {
        let a = try analysis(samplePlanP1(), "laptop", dollars(700), d(2026, 10, 2))
        let reasons = Explainer.reasons(a)
        #expect(reasons.map(\.label) == ["Paycheck, Sep 30", "Rent, Oct 1", "Laptop, Oct 2", "Groceries, 3 times", "Phone, Oct 8"])
        #expect(reasons.map(\.amount) == [dollars(800), dollars(-750), dollars(-700), dollars(-300), dollars(-45)])
        #expect(Explainer.nextIncomeText(a) == "Next income: Paycheck +$800 on Wed Oct 14")
    }

    @Test("a plan already short says so and shows the purchase's share (X3)")
    func planAlreadyShort() throws {
        let plan = makePlan(balance: dollars(500), floor: dollars(200), bill("Rent", 400, .once(day(3))))
        let a = try analysis(plan, "book", dollars(20), today)
        #expect(Explainer.headline(a) == "Your plan is already below your floor")
        let summary = Explainer.summary(a)
        #expect(summary.contains("$100 on Tue Sep 29"))
        #expect(summary.lowercased().contains("this purchase adds $20"))
        #expect(Explainer.earliestFitNote(a) == "Your plan dips below your floor even without this purchase.")
    }

    @Test("each verdict has its own headline")
    func headlines() throws {
        let fits = try analysis(workedExamplePlan(), "book", dollars(20), today)
        let negative = try analysis(rentAndPayPlan(pay: 900), "desk", dollars(300), d(2026, 10, 24))
        #expect(Explainer.headline(fits) == "Fits your cash floor")
        #expect(Explainer.summary(fits) == "Lowest point: $830 on Mon Oct 5. That's $630 above your $200 floor.")
        #expect(Explainer.headline(negative) == "Known bills exceed projected cash")
        #expect(Explainer.summary(negative).contains("-$200 on Sun Nov 1"))
    }

    @Test("earliest date that fits reads as a date, today, or none")
    func earliestFitText() throws {
        #expect(Explainer.earliestFitValue(try analysis(samplePlanP1(), "laptop", dollars(700), d(2026, 10, 2))) == "Thu Oct 15")
        #expect(Explainer.earliestFitValue(try analysis(workedExamplePlan(), "book", dollars(20), day(3))) == "Today")
        let none = try analysis(workedExamplePlan(), "laptop", dollars(700), today)
        #expect(Explainer.earliestFitValue(none) == "None by Mon Oct 26")
        #expect(Explainer.earliestFitNote(none) == "No date in the next 30 days leaves room for $700.")
        #expect(Explainer.earliestFitNote(try analysis(samplePlanP1(), "laptop", dollars(700), d(2026, 10, 2))) == nil)
    }

    @Test("no income after the low is stated plainly")
    func noNextIncome() throws {
        let a = try analysis(workedExamplePlan(), "laptop", dollars(700), today)
        #expect(Explainer.nextIncomeText(a) == "No income in your plan through Thu Nov 26")
    }

    @Test("every missing input has an instruction")
    func missingTexts() {
        #expect(Explainer.text(for: .balanceNotConfirmedToday(lastConfirmed: d(2026, 9, 25)))
                == "Confirm your checking balance for today. Last confirmed Fri Sep 25.")
        #expect(Explainer.text(for: .dateBeyondRange(latest: day(30)))
                == "Pick a date on or before Mon Oct 26. Headroom checks purchases up to 30 days out.")
    }

    @Test("no dashes or banned phrases in anything the engine says (X4)")
    func copyRules() throws {
        let analyses = try [
            analysis(workedExamplePlan(), "laptop", dollars(700), today),
            analysis(workedExamplePlan(), "book", dollars(20), today),
            analysis(samplePlanP1(), "laptop", dollars(700), d(2026, 10, 2)),
            analysis(rentAndPayPlan(pay: 900), "desk", dollars(300), d(2026, 10, 24)),
            analysis(rentAndPayPlan(pay: 800), "headphones", dollars(50), today),
            analysis(makePlan(balance: dollars(500), floor: dollars(200), bill("Rent", 400, .once(day(3)))), "book", dollars(20), today),
            analysis(makePlan(balance: dollars(-50), floor: dollars(0), income("Paycheck", 500, .once(day(70)))), "snack", dollars(10), today),
        ]
        var strings = Explainer.assumptions
        for a in analyses {
            strings += [Explainer.headline(a), Explainer.summary(a), Explainer.nextIncomeText(a), Explainer.earliestFitValue(a)]
            strings += Explainer.reasons(a).map(\.label)
            if let note = Explainer.earliestFitNote(a) { strings.append(note) }
        }
        let allMissing: [MissingInfo] = [.balance, .balanceNotConfirmedToday(lastConfirmed: day(-1)), .floor, .noEvents,
                                         .invalidPrice, .dateInPast, .dateBeyondRange(latest: day(30))]
        strings += allMissing.map(Explainer.text(for:))
        for text in strings {
            #expect(!text.contains("\u{2014}") && !text.contains("\u{2013}"), "dash in: \(text)")
            for banned in ["affordable", "safe to spend", "buy now"] {
                #expect(!text.lowercased().contains(banned), "\(banned) in: \(text)")
            }
        }
    }
}
