import Testing
@testable import HeadroomCore

@Suite("Money")
struct MoneyTests {
    @Test("formats like a US price", arguments: [
        (70_000, "$700"),
        (124_999, "$1,249.99"),
        (-45_000, "-$450"),
        (5, "$0.05"),
        (105, "$1.05"),
        (0, "$0"),
        (-5, "-$0.05"),
        (100_000_000, "$1,000,000"),
    ])
    func formatting(cents: Int, expected: String) {
        #expect(Money(cents: cents).formatted == expected)
    }

    @Test func dollarsAreHundredsOfCents() {
        #expect(Money.dollars(7) == Money(cents: 700))
    }

    @Test func arithmeticAndOrdering() {
        let a = Money.dollars(10), b = Money(cents: 250)
        #expect(a + b == Money(cents: 1_250))
        #expect(a - b == Money(cents: 750))
        #expect(-b == Money(cents: -250))
        #expect(b < a)
    }

    @Test func maximumIsTenMillionDollars() {
        #expect(Money.maximum == Money.dollars(10_000_000))
    }

    @Test("display text uses a real minus sign, and formatted keeps the hyphen")
    func displayTextNegative() {
        let rent = Money(cents: -45_000)
        #expect(rent.displayText == "\u{2212}$450")
        #expect(rent.displayText(signed: true) == "\u{2212}$450")
        #expect(rent.formatted == "-$450")
        #expect(rent.spokenText == "minus $450")
    }

    @Test("signed display text and speech say plus for money in")
    func displayTextSigned() {
        let pay = Money.dollars(800)
        #expect(pay.displayText == "$800")
        #expect(pay.displayText(signed: true) == "+$800")
        #expect(pay.spokenText == "$800")
        #expect(pay.spokenText(signed: true) == "plus $800")
        #expect(Money.zero.displayText(signed: true) == "$0")
        #expect(Money.zero.spokenText(signed: true) == "$0")
        #expect(Money(cents: -45_000).spokenText(signed: true) == "minus $450")
    }

    @Test("forced cents show two digits, and speech drops zero cents")
    func displayTextForceCents() {
        let phone = Money.dollars(45)
        #expect(phone.displayText(forceCents: true) == "$45.00")
        #expect(phone.displayText == "$45")
        #expect(phone.spokenText == "$45")
        #expect(Money(cents: -4_500).displayText(forceCents: true) == "\u{2212}$45.00")
        #expect(Money(cents: 5).displayText(forceCents: true) == "$0.05")
        #expect(Money(cents: 124_999).displayText == "$1,249.99")
        #expect(Money(cents: 124_999).displayText(signed: true, forceCents: true) == "+$1,249.99")
        #expect(Money(cents: 124_999).spokenText == "$1,249.99")
    }

    @Test("display text reads as a string in interpolation, not a function")
    func displayTextInterpolates() {
        let floor = Money.dollars(200)
        #expect("Floor \(floor.displayText)" == "Floor $200")
        #expect("\(Money(cents: -500).spokenText)" == "minus $5")
    }
}
