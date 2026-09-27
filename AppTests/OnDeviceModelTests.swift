import Foundation
import HeadroomCore
import Testing
@testable import Headroom

/// Runs the real on-device model. Skipped where Apple Intelligence is unavailable (CI, older phones).
@Suite("On-device model", .enabled(if: OnDeviceAI.availability == .available), .timeLimit(.minutes(2)))
struct OnDeviceModelTests {
    @Test("reads five phrasings; prices always equal the typed digits", arguments: [
        ("Can I buy a $700 laptop next Friday?", 70_000),
        ("thinking about grabbing $249.99 headphones tomorrow", 24_999),
        ("would a $1,200 bike on Oct 15 be ok", 120_000),
        ("is it fine if I get concert tickets for $85", 8_500),
        ("new winter jacket, $130, maybe in two weeks", 13_000),
    ])
    func readsRealQuestions(text: String, cents: Int) async {
        let now = Date()
        let result = await AIReader.read(text, interpreter: OnDeviceInterpreter(), today: now, timeZone: .current)
        #expect(result.parsed.price == Money(cents: cents))
        if result.note == nil {
            #expect(result.parsed.source == .onDeviceAI)
            #expect(result.parsed.item.map { text.lowercased().contains($0) } ?? true)
        }
        let today = LocalDate(now)
        #expect(result.parsed.date.map { $0 >= today && $0 <= today.adding(days: 60) } ?? false)
    }
}
