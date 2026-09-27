import HeadroomCore
import Testing
@testable import Headroom

@Suite("MoneyInput")
struct MoneyInputTests {
    @Test("parses what people type into an amount field", arguments: [
        ("700", 70_000),
        ("1,249.99", 124_999),
        ("$1,249.99", 124_999),
        ("0.5", 50),
        ("0.05", 5),
        (" 45 ", 4_500),
        ("10000000", 1_000_000_000),
    ])
    func parses(text: String, cents: Int) {
        #expect(MoneyInput.parse(text) == Money(cents: cents))
    }

    @Test("rejects anything that is not a plain amount", arguments: [
        "", "abc", "12.345", "-5", "1.2.3", "10000000.01", "99999999999999999999", "$", ".",
    ])
    func rejects(text: String) {
        #expect(MoneyInput.parse(text) == nil)
    }

    @Test("a balance can be negative when overdrawn")
    func signedBalance() {
        #expect(MoneyInput.parseBalance("-45.50") == Money(cents: -4_550))
        #expect(MoneyInput.parseBalance("-$1,200") == Money(cents: -120_000))
        #expect(MoneyInput.parseBalance("$1,000") == Money(cents: 100_000))
        #expect(MoneyInput.parseBalance("--5") == nil)
        #expect(MoneyInput.editableText(Money(cents: -4_550)) == "-45.50")
    }

    @Test("a pasted display amount with a real minus sign (U+2212) reads like a hyphen")
    func unicodeMinus() {
        #expect(MoneyInput.parseBalance("\u{2212}45.50") == Money(cents: -4_550))
        #expect(MoneyInput.parseBalance("\u{2212}$1,200") == Money(cents: -120_000))
        #expect(MoneyInput.parseBalance("\u{2212}\u{2212}5") == nil)
        #expect(MoneyInput.parseBalance("-\u{2212}5") == nil)
        #expect(MoneyInput.parse("\u{2212}5") == nil)
    }

    @Test func editableTextHasNoSymbolOrCommas() {
        #expect(MoneyInput.editableText(Money(cents: 124_999)) == "1249.99")
        #expect(MoneyInput.editableText(Money(cents: 70_000)) == "700")
        #expect(MoneyInput.editableText(Money(cents: 5)) == "0.05")
    }
}
