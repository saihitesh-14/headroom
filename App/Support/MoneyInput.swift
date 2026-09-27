import Foundation
import HeadroomCore

/// Reads an amount typed into a field. Integer math only; never goes through Double.
enum MoneyInput {
    /// "700", "1,249.99", "$45" → cents. Anything else, negative, or over $10,000,000 → nil.
    static func parse(_ text: String) -> Money? {
        var cleaned = text.trimmingCharacters(in: .whitespaces)
        if cleaned.hasPrefix("$") { cleaned.removeFirst() }
        cleaned = cleaned.replacingOccurrences(of: ",", with: "")
        let parts = cleaned.split(separator: ".", omittingEmptySubsequences: false)
        guard (1...2).contains(parts.count),
              let whole = parts.first, !whole.isEmpty, whole.count <= 9,
              whole.allSatisfy(\.isASCIIDigit),
              let dollars = Int(whole) else { return nil }
        var cents = 0
        if parts.count == 2 {
            let fraction = parts[1]
            guard (1...2).contains(fraction.count), fraction.allSatisfy(\.isASCIIDigit),
                  let value = Int(fraction) else { return nil }
            cents = fraction.count == 1 ? value * 10 : value
        }
        let money = Money(cents: dollars * 100 + cents)
        return money <= .maximum ? money : nil
    }

    /// Like `parse`, but a checking balance may start with "-" when overdrawn. A real minus
    /// sign (U+2212, as the app displays it) is accepted too, so a pasted amount still reads.
    static func parseBalance(_ text: String) -> Money? {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard trimmed.hasPrefix("-") || trimmed.hasPrefix("\u{2212}") else { return parse(trimmed) }
        return parse(String(trimmed.dropFirst())).map { -$0 }
    }

    /// What to prefill in a field: no "$", no commas ("1249.99", "700").
    static func editableText(_ money: Money) -> String {
        let cents = money.cents.magnitude
        let fraction = cents % 100
        let sign = money.cents < 0 ? "-" : ""
        guard fraction != 0 else { return "\(sign)\(cents / 100)" }
        return "\(sign)\(cents / 100)." + (fraction < 10 ? "0" : "") + "\(fraction)"
    }
}

extension Character {
    var isASCIIDigit: Bool { ("0"..."9").contains(self) }
}
