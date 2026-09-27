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
}
