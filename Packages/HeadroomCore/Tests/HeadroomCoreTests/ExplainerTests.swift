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
        #expect(Explainer.headline(a) == "Dips below your floor")
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
        #expect(Explainer.headline(a) == "Already dips below your floor")
        let summary = Explainer.summary(a)
        #expect(summary.contains("$100 on Tue Sep 29"))
        #expect(summary.lowercased().contains("this purchase adds $20"))
        #expect(Explainer.earliestFitNote(a) == "Your plan dips below your floor even without this purchase.")
    }

    @Test("each verdict has its own headline")
    func headlines() throws {
        let fits = try analysis(workedExamplePlan(), "book", dollars(20), today)
        let negative = try analysis(rentAndPayPlan(pay: 900), "desk", dollars(300), d(2026, 10, 24))
        #expect(Explainer.headline(fits) == "Stays above your floor")
        #expect(Explainer.summary(fits) == "Lowest point: $830 on Mon Oct 5. That's $630 above your $200 floor.")
        #expect(Explainer.headline(negative) == "Takes checking below $0")
        #expect(Explainer.summary(negative).contains("-$200 on Sun Nov 1"))
        #expect(Explainer.summary(negative) == "Lowest point: -$200 on Sun Nov 1. That's $200 below $0.")
    }

    @Test("landing exactly on the floor, and a plan already below $0, have their own headlines")
    func headlineEdges() throws {
        let exact = makePlan(balance: dollars(1_000), floor: dollars(200), bill("Bill", 400, .once(day(3))))
        #expect(Explainer.headline(try analysis(exact, "x", dollars(400), today)) == "Stays at your floor")
        #expect(Explainer.headline(try analysis(exact, "x", dollars(399), today)) == "Stays above your floor")
        let negative = makePlan(balance: dollars(-50), floor: dollars(0), income("Paycheck", 500, .once(day(70))))
        #expect(Explainer.headline(try analysis(negative, "snack", dollars(10), today)) == "Checking already goes below $0")
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
            if let warning = Explainer.baselineWarningText(a) { strings.append(warning) }
            // Everything added for the Datum redesign.
            let reading = Explainer.reading(a)
            let ledger = Explainer.ledger(a)
            strings += [Explainer.purchaseSentence(a), reading.amount.displayText, reading.words,
                        Explainer.purchaseLine(a.purchase), Explainer.purchaseMarker(a.purchase), Explainer.lowMarker(a),
                        Explainer.chartCaption(a), Explainer.ledgerHeading(a), Explainer.tryLabel(a.purchase.date, today: a.today)]
            strings += ledger.rows.map(\.label) + [ledger.remainder?.label].compactMap { $0 }
            if let below = Explainer.belowFloorText(a) { strings.append(below) }
            if let fit = Explainer.earliestFitDate(a) { strings.append(Explainer.tryLabel(fit, today: a.today)) }
        }
        let plans = [samplePlanP1(), workedExamplePlan(), rentAndPayPlan(pay: 800)]
            + [300, 500, 600].map { makePlan(balance: dollars($0), floor: dollars(200), bill("Rent", 400, .once(day(3)))) }
        for plan in plans {
            let detail = try #require(roomDetail(plan))
            strings += [Explainer.roomCaption(detail), Explainer.roomSummary(detail)]
        }
        let allMissing: [MissingInfo] = [.balance, .balanceNotConfirmedToday(lastConfirmed: day(-1)), .floor, .noEvents,
                                         .invalidPrice, .dateInPast, .dateBeyondRange(latest: day(30))]
        strings += allMissing.map(Explainer.text(for:))
        for text in strings {
            #expect(!text.contains("\u{2014}") && !text.contains("\u{2013}"), "dash in: \(text)")
            #expect(!text.contains("\u{00B7}"), "middle dot in: \(text)")
            for banned in ["affordable", "safe to spend", "buy now"] {
                #expect(!text.lowercased().contains(banned), "\(banned) in: \(text)")
            }
        }
        // The minus sign and the no-break space are allowed, and the new copy uses both.
        #expect(strings.contains { $0.contains("\u{2212}") })
        #expect(strings.contains { $0.contains("\u{00A0}") })
    }
}

@Suite("Explainer review fixes")
struct ExplainerReviewFixTests {
    func analysis(_ plan: CashPlan, _ price: Money, _ date: LocalDate) throws -> Analysis {
        try #require(analyzed(CashEngine.analyze(plan, purchase: Purchase(item: "laptop", price: price, date: date), today: today)))
    }

    @Test("pay that lands after the day's low is not listed as moving the balance to the low")
    func reasonsExcludePayAfterLow() throws {
        let plan = makePlan(balance: dollars(1_000), floor: dollars(0),
                            income("Paycheck", 800, .once(day(4))),
                            bill("Rent", 100, .once(day(10))))
        let a = try analysis(plan, dollars(900), day(4))
        #expect(a.purchaseLow == Low(amount: dollars(100), date: day(4)))
        #expect(Explainer.reasons(a).map(\.label) == ["Laptop, Sep 30"])
        #expect(Explainer.nextIncomeText(a) == "Next income: Paycheck +$800 on Wed Sep 30")
    }

    @Test("a dip below zero before the purchase date is put into words")
    func warningBeforePurchaseNegative() throws {
        let plan = makePlan(balance: dollars(300), floor: dollars(100),
                            bill("Rent", 750, .once(day(2))),
                            income("Paycheck", 800, .once(day(4))))
        let a = try analysis(plan, dollars(50), day(5))
        #expect(a.verdict == .fits(room: dollars(200)))
        #expect(Explainer.baselineWarningText(a) == "Before this purchase, your balance drops to \u{2212}$450 on Mon Sep 28.")
    }

    @Test("a dip below the floor before the purchase date is put into words")
    func warningBeforePurchaseBelowFloor() throws {
        let plan = makePlan(balance: dollars(300), floor: dollars(100),
                            bill("Rent", 220, .once(day(2))),
                            income("Paycheck", 800, .once(day(4))))
        let a = try analysis(plan, dollars(50), day(5))
        #expect(Explainer.baselineWarningText(a) == "Before this purchase, your balance drops to $80 on Mon Sep 28, below your $100 floor.")
    }

    @Test("no separate warning when the plan is fine, or when the headline already says it is short")
    func noWarningWhenCovered() throws {
        #expect(Explainer.baselineWarningText(try analysis(workedExamplePlan(), dollars(20), today)) == nil)
        let short = makePlan(balance: dollars(500), floor: dollars(200), bill("Rent", 400, .once(day(3))))
        #expect(Explainer.baselineWarningText(try analysis(short, dollars(20), today)) == nil)
    }
}

/// "NBSP" in the spec: new sentences join weekday, month and day with U+00A0.
private let nbsp = "\u{00A0}"

@Suite("Explainer readings")
struct ExplainerReadingTests {
    func analysis(_ plan: CashPlan, _ item: String, _ price: Money, _ date: LocalDate) throws -> Analysis {
        try #require(analyzed(CashEngine.analyze(plan, purchase: Purchase(item: item, price: price, date: date), today: today)))
    }

    func p1() throws -> Analysis { try analysis(samplePlanP1(), "laptop", dollars(700), d(2026, 10, 2)) }

    /// Balance $1,000, floor $200: a one-day dip on Tue Sep 29 and a three-day dip Tue Oct 6 to Thu Oct 8.
    func twoDipsPlan() -> CashPlan {
        makePlan(balance: dollars(1_000), floor: dollars(200),
                 bill("Tuition", 850, .once(day(3))), income("Refund", 850, .once(day(3))),
                 bill("Rent", 900, .once(day(10))), income("Paycheck", 900, .once(day(12))))
    }

    /// Seven different bills before the low, one of them twice.
    func sevenGroupsPlan() -> CashPlan {
        makePlan(balance: dollars(5_000), floor: dollars(0),
                 bill("Rent", 700, .once(day(1))), bill("Car", 600, .once(day(2))),
                 bill("Phone", 50, .once(day(3))), bill("Gym", 40, .once(day(4))),
                 bill("Snacks", 5, .once(day(1))), bill("Books", 20, .once(day(6))), bill("Snacks", 5, .once(day(8))))
    }

    // MARK: Sentence and reading

    @Test("the sentence names the real low: takes checking down to $5 (P1)")
    func purchaseSentenceCrosses() throws {
        #expect(Explainer.purchaseSentence(try p1())
                == "Spending $700 on Fri\(nbsp)Oct\(nbsp)2 takes checking down to $5 on Mon\(nbsp)Oct\(nbsp)12.")
    }

    @Test("a purchase that stays above the floor leaves checking at its lowest point")
    func purchaseSentenceFits() throws {
        let a = try analysis(workedExamplePlan(), "book", dollars(20), today)
        #expect(Explainer.purchaseSentence(a)
                == "Spending $20 on Sat\(nbsp)Sep\(nbsp)26 leaves checking at $830 on Mon\(nbsp)Oct\(nbsp)5, its lowest point.")
    }

    @Test("a purchase that goes below $0 shows the minus sign")
    func purchaseSentenceNegative() throws {
        let a = try analysis(rentAndPayPlan(pay: 900), "desk", dollars(300), d(2026, 10, 24))
        #expect(Explainer.purchaseSentence(a)
                == "Spending $300 on Sat\(nbsp)Oct\(nbsp)24 takes checking down to \u{2212}$200 on Sun\(nbsp)Nov\(nbsp)1.")
    }

    @Test("a plan already short keeps the existing summary")
    func purchaseSentencePlanAlreadyShort() throws {
        let short = try analysis(makePlan(balance: dollars(500), floor: dollars(200), bill("Rent", 400, .once(day(3)))),
                                 "book", dollars(20), today)
        #expect(Explainer.purchaseSentence(short) == Explainer.summary(short))
        let negative = try analysis(makePlan(balance: dollars(-50), floor: dollars(0), income("Paycheck", 500, .once(day(70)))),
                                    "snack", dollars(10), today)
        #expect(Explainer.purchaseSentence(negative) == Explainer.summary(negative))
    }

    @Test("the reading carries its unit words, so it never reads as a balance")
    func readings() throws {
        #expect(Explainer.reading(try p1()) == Explainer.Reading(amount: dollars(195), words: "below your $200 floor", kind: .below))
        #expect(Explainer.reading(try analysis(workedExamplePlan(), "book", dollars(20), today))
                == Explainer.Reading(amount: dollars(630), words: "above your $200 floor", kind: .above))
        let exact = makePlan(balance: dollars(1_000), floor: dollars(200), bill("Bill", 400, .once(day(3))))
        #expect(Explainer.reading(try analysis(exact, "x", dollars(400), today))
                == Explainer.Reading(amount: .zero, words: "above your $200 floor", kind: .above))
        #expect(Explainer.reading(try analysis(rentAndPayPlan(pay: 900), "desk", dollars(300), d(2026, 10, 24)))
                == Explainer.Reading(amount: dollars(200), words: "below $0", kind: .belowZero))
    }

    // MARK: Labels

    @Test("subtitle, chart markers and the ledger heading")
    func labels() throws {
        let a = try p1()
        #expect(Explainer.purchaseLine(a.purchase) == "$700 on Fri\(nbsp)Oct\(nbsp)2")
        #expect(Explainer.purchaseMarker(a.purchase) == "Laptop, Oct 2")
        #expect(Explainer.purchaseMarker(Purchase(item: "", price: dollars(5), date: d(2026, 10, 2))) == "Purchase, Oct 2")
        #expect(Explainer.lowMarker(a) == "$5, Oct 12")
        #expect(Explainer.lowMarker(try analysis(rentAndPayPlan(pay: 900), "desk", dollars(300), d(2026, 10, 24))) == "\u{2212}$200, Nov 1")
        #expect(Explainer.ledgerHeading(a) == "What moves your balance by Mon\(nbsp)Oct\(nbsp)12")
        #expect(Explainer.chartCaption(a) == "Checked through Thu\(nbsp)Nov\(nbsp)26. The lowest point is in view.")
    }

    // MARK: Earliest fit

    @Test("the earliest fit for the sample is Thu Oct 15, offered as a Try button")
    func earliestFitDate() throws {
        let date = try #require(Explainer.earliestFitDate(try p1()))
        #expect(date == d(2026, 10, 15))
        #expect(Explainer.tryLabel(date, today: today) == "Try Thu\(nbsp)Oct\(nbsp)15")
        #expect(Explainer.tryLabel(today, today: today) == "Try today")
    }

    @Test("no Try date when the purchase already fits or no date fits")
    func noEarliestFitDate() throws {
        #expect(Explainer.earliestFitDate(try analysis(workedExamplePlan(), "book", dollars(20), day(3))) == nil)
        #expect(Explainer.earliestFitDate(try analysis(workedExamplePlan(), "laptop", dollars(700), today)) == nil)
        let short = makePlan(balance: dollars(500), floor: dollars(200), bill("Rent", 400, .once(day(3))))
        #expect(Explainer.earliestFitDate(try analysis(short, "book", dollars(20), today)) == nil)
    }

    // MARK: Chart window

    @Test("the result window runs a week past the Try date (P1: Thu Oct 22)")
    func chartWindowEnd() throws {
        #expect(Explainer.chartWindowEnd(try p1()) == d(2026, 10, 22))
        // Fits: no Try date, so the window follows the lows and is at least 21 days.
        #expect(Explainer.chartWindowEnd(try analysis(workedExamplePlan(), "book", dollars(20), today)) == day(20))
    }

    @Test("the result window always contains the lows and the Try date", arguments: [
        (samplePlanP1(), 700), (workedExamplePlan(), 700), (rentAndPayPlan(pay: 900), 300), (rentAndPayPlan(pay: 800), 50),
    ])
    func chartWindowContainsWhatMatters(plan: CashPlan, price: Int) throws {
        for offset in 0...30 {
            let a = try analysis(plan, "x", dollars(price), day(offset))
            let end = Explainer.chartWindowEnd(a)
            #expect(end >= a.purchaseLow.date && end >= a.baselineLow.date && end >= a.purchase.date)
            if let fit = Explainer.earliestFitDate(a) { #expect(end >= fit) }
        }
    }

    // MARK: Below the floor

    @Test("the sample dips below the floor Mon Oct 5 to Wed Oct 14 (P1)")
    func belowFloorSample() throws {
        let a = try p1()
        #expect(Explainer.belowFloorSpans(a.withPurchase, floor: a.floor) == [d(2026, 10, 5)...d(2026, 10, 14)])
        #expect(Explainer.belowFloorText(a) == "Below your floor Mon\(nbsp)Oct\(nbsp)5 to Wed\(nbsp)Oct\(nbsp)14")
    }

    @Test("one day reads 'on', and several spans are joined with ', and'")
    func belowFloorSeveralSpans() throws {
        let a = try analysis(twoDipsPlan(), "gum", dollars(1), today)
        #expect(Explainer.belowFloorSpans(a.withPurchase, floor: a.floor) == [day(3)...day(3), day(10)...day(12)])
        #expect(Explainer.belowFloorText(a)
                == "Below your floor on Tue\(nbsp)Sep\(nbsp)29, and Tue\(nbsp)Oct\(nbsp)6 to Thu\(nbsp)Oct\(nbsp)8")
    }

    @Test("nothing below the floor, no line")
    func belowFloorNone() throws {
        #expect(Explainer.belowFloorText(try analysis(workedExamplePlan(), "book", dollars(20), today)) == nil)
        #expect(Explainer.belowFloorSpans([], floor: dollars(200)).isEmpty)
    }

    // MARK: Ledger

    @Test("the sample ledger adds up: 1,000 + 800 - 750 - 700 - 300 - 45 = 5 (P1)")
    func sampleLedger() throws {
        let a = try p1()
        let ledger = Explainer.ledger(a)
        #expect(ledger.start == dollars(1_000))
        #expect(ledger.rows == Explainer.reasons(a))
        #expect(ledger.remainder == nil)
        #expect(ledger.end == Low(amount: dollars(5), date: d(2026, 10, 12)))
    }

    @Test("the ledger reconciles to the low for every fixture", arguments: [
        (samplePlanP1(), 700, 6), (workedExamplePlan(), 700, 0), (workedExamplePlan(), 20, 0),
        (rentAndPayPlan(pay: 900), 300, 28), (rentAndPayPlan(pay: 800), 50, 0),
        (makePlan(balance: dollars(500), floor: dollars(200), bill("Rent", 400, .once(day(3)))), 20, 0),
        (makePlan(balance: dollars(-50), floor: dollars(0), income("Paycheck", 500, .once(day(70)))), 10, 0),
        (makePlan(balance: dollars(500), floor: dollars(0), bill("Rent", 400, .once(today)), income("Paycheck", 900, .once(day(2)))), 50, 0),
        (makePlan(balance: dollars(300), income("Paycheck", 800, .once(day(3))), bill("Rent", 750, .once(day(3)))), 20, 3),
    ])
    func ledgerReconciles(plan: CashPlan, price: Int, offset: Int) throws {
        var plan = plan
        if plan.floor == nil { plan.floor = .zero }
        let a = try analysis(plan, "x", dollars(price), day(offset))
        let ledger = Explainer.ledger(a)
        let moved = ledger.rows.reduce(ledger.remainder?.amount ?? .zero) { $0 + $1.amount }
        #expect(ledger.start + moved == ledger.end.amount)
        #expect(ledger.end == a.purchaseLow)
        #expect(ledger.rows.count <= 5)
    }

    @Test("more than five groups roll up into 'Everything else', counting each item")
    func ledgerRemainder() throws {
        // Groups by size: Rent 700, Car 600, Laptop 100, Phone 50, Gym 40, then Books 20 and Snacks 5 + 5.
        let a = try analysis(sevenGroupsPlan(), "laptop", dollars(100), day(8))
        #expect(a.purchaseLow == Low(amount: dollars(3_480), date: day(8)))
        let ledger = Explainer.ledger(a)
        #expect(ledger.rows.map(\.label) == ["Rent, Sep 27", "Car, Sep 28", "Laptop, Oct 4", "Phone, Sep 29", "Gym, Sep 30"])
        #expect(ledger.remainder == Explainer.Reason(label: "Everything else, 3 items", amount: dollars(-30)))
        #expect(Explainer.reasons(a) == ledger.rows)
    }

    @Test("a single leftover item is singular")
    func ledgerRemainderSingular() throws {
        let plan = makePlan(balance: dollars(5_000), floor: dollars(0),
                            bill("Rent", 700, .once(day(1))), bill("Car", 600, .once(day(2))),
                            bill("Phone", 50, .once(day(3))), bill("Gym", 40, .once(day(4))),
                            bill("Books", 20, .once(day(6))))
        let ledger = Explainer.ledger(try analysis(plan, "laptop", dollars(100), day(8)))
        #expect(ledger.remainder == Explainer.Reason(label: "Everything else, 1 item", amount: dollars(-20)))
    }

    // MARK: Home screen

    @Test("the home caption states the promise through the horizon (P1)")
    func roomCaption() throws {
        let detail = try #require(roomDetail(samplePlanP1()))
        #expect(Explainer.roomCaption(detail)
                == "Spend up to this today and stay at or above your $200 floor through Thu\(nbsp)Nov\(nbsp)26.")
    }

    @Test("with no room, the caption says why", arguments: [
        (500, "Your balance already dips below your $200 floor on Tue\u{00A0}Sep\u{00A0}29, before any purchase."),
        (600, "Your balance reaches your $200 floor on Tue\u{00A0}Sep\u{00A0}29, so there is no room to spend today."),
        (300, "Your balance already goes below $0 on Tue\u{00A0}Sep\u{00A0}29, before any purchase."),
    ])
    func roomCaptionNoRoom(balance: Int, expected: String) throws {
        let detail = try #require(roomDetail(makePlan(balance: dollars(balance), floor: dollars(200), bill("Rent", 400, .once(day(3))))))
        #expect(detail.room == .zero)
        #expect(Explainer.roomCaption(detail) == expected)
    }

    @Test("the gauge summary reads the whole drawing (P1)")
    func roomSummary() throws {
        let detail = try #require(roomDetail(samplePlanP1()))
        #expect(Explainer.roomSummary(detail)
                == "Starts at $1,000 today. Lowest $705 on Mon\(nbsp)Oct\(nbsp)12, which is $505 above your $200 floor. "
                + "Checked through Thu\(nbsp)Nov\(nbsp)26.")
    }

    @Test("the gauge summary names a low at, below, or under zero", arguments: [
        (600, "which is exactly your $200 floor."),
        (500, "which is $100 below your $200 floor."),
        (300, "which is $100 below $0."),
    ])
    func roomSummaryNoRoom(balance: Int, expected: String) throws {
        let detail = try #require(roomDetail(makePlan(balance: dollars(balance), floor: dollars(200), bill("Rent", 400, .once(day(3))))))
        #expect(Explainer.roomSummary(detail).contains(expected))
    }
}
