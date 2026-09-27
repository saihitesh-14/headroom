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
        let magnitude = cents.magnitude
        let dollars = magnitude / 100
        let remainder = magnitude % 100
        var text = (cents < 0 ? "-$" : "$") + Self.grouped(dollars)
        if remainder != 0 {
            text += "." + (remainder < 10 ? "0" : "") + String(remainder)
        }
        return text
    }

    public var description: String { formatted }

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
