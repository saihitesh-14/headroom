/// An amount of US dollars stored as whole cents. Never uses floating point.
public struct Money: Hashable, Comparable, Sendable, CustomStringConvertible {
    public var cents: Int

    public init(cents: Int) {
        self.cents = cents
    }

    public static let zero = Money(cents: 0)

    /// The largest amount the app accepts for any single input ($10,000,000).
    public static let maximum = Money(cents: 1_000_000_000)

    public static func dollars(_ dollars: Int) -> Money {
        Money(cents: dollars * 100)
    }

    public static func + (lhs: Money, rhs: Money) -> Money { Money(cents: lhs.cents + rhs.cents) }
    public static func - (lhs: Money, rhs: Money) -> Money { Money(cents: lhs.cents - rhs.cents) }
    public static prefix func - (value: Money) -> Money { Money(cents: -value.cents) }
    public static func < (lhs: Money, rhs: Money) -> Bool { lhs.cents < rhs.cents }

    /// "$700", "$1,249.99", "-$450", "$0.05". Whole dollars drop the cents.
    public var formatted: String {
        (cents < 0 ? "-" : "") + Self.magnitudeText(cents.magnitude, forceCents: false)
    }

    public var description: String { formatted }

    /// For display: "\u{2212}$750" with a real minus sign (U+2212). Whole dollars drop the cents.
    public var displayText: String { displayText() }

    /// For display. `signed` adds "+" to amounts above zero ("+$800"). `forceCents`
    /// always shows two cent digits ("$45.00"), for columns where any row has cents.
    public func displayText(signed: Bool = false, forceCents: Bool = false) -> String {
        let sign = cents < 0 ? "\u{2212}" : (signed && cents > 0 ? "+" : "")
        return sign + Self.magnitudeText(cents.magnitude, forceCents: forceCents)
    }

    /// For VoiceOver: "minus $750", "$700". The sign is always a word.
    public var spokenText: String { spokenText(signed: false) }

    /// For VoiceOver. `signed` says "plus" for amounts above zero ("plus $800").
    public func spokenText(signed: Bool) -> String {
        let sign = cents < 0 ? "minus " : (signed && cents > 0 ? "plus " : "")
        return sign + Self.magnitudeText(cents.magnitude, forceCents: false)
    }

    /// "$1,249.99", "$700", or "$700.00" with `forceCents`. Never has a sign.
    private static func magnitudeText(_ magnitude: UInt, forceCents: Bool) -> String {
        let remainder = magnitude % 100
        var text = "$" + grouped(magnitude / 100)
        if remainder != 0 || forceCents {
            text += "." + (remainder < 10 ? "0" : "") + String(remainder)
        }
        return text
    }

    private static func grouped(_ value: UInt) -> String {
        let digits = Array(String(value))
        var result = ""
        for (index, digit) in digits.enumerated() {
            if index > 0, (digits.count - index) % 3 == 0 { result.append(",") }
            result.append(digit)
        }
        return result
    }
}

extension Money: Codable {
    public init(from decoder: any Decoder) throws {
        cents = try decoder.singleValueContainer().decode(Int.self)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(cents)
    }
}
