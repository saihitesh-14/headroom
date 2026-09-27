import Foundation
import FoundationModels

/// What the on-device model is asked to copy out of a question. Phrases only, in this order;
/// an empty dateText means the question did not say when.
@Generable
struct QuestionPhrases {
    @Guide(description: "The thing the person wants to buy, copied exactly from their words, without the price. Example: laptop")
    var item: String

    @Guide(description: "The words that say when they want to buy it, copied exactly, such as 'next Friday' or 'Oct 15'. Empty if they did not say.")
    var dateText: String
}

/// Apple's on-device model (Foundation Models). Nothing leaves the iPhone.
struct OnDeviceInterpreter: QuestionInterpreter {
    func interpret(_ text: String) async throws -> InterpretedPhrases {
        // A new session per request: sessions keep history and allow one request at a time.
        let session = LanguageModelSession(instructions: """
            You copy phrases out of a question about buying something. \
            Only use words that appear in the question. Never invent words and never do arithmetic.
            """)
        let response = try await session.respond(to: text, generating: QuestionPhrases.self)
        let phrases = response.content
        return InterpretedPhrases(item: phrases.item, dateText: phrases.dateText.isEmpty ? nil : phrases.dateText)
    }
}

enum OnDeviceAI {
    enum Availability: Equatable {
        case available
        case unavailable(String)
    }

    static var availability: Availability {
        switch SystemLanguageModel.default.availability {
        case .available:
            return .available
        case .unavailable(let reason):
            switch reason {
            case .deviceNotEligible:
                return .unavailable("This iPhone does not support Apple Intelligence.")
            case .appleIntelligenceNotEnabled:
                return .unavailable("Turn on Apple Intelligence in the Settings app to use this.")
            case .modelNotReady:
                return .unavailable("Apple Intelligence is still getting ready. Try again later.")
            @unknown default:
                return .unavailable("On-device AI is not available right now.")
            }
        }
    }

    /// The Settings toggle. Off, or unavailable, means the built-in parser reads questions.
    static let settingKey = "useOnDeviceAI"
}
