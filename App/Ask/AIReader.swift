import Foundation
import HeadroomCore

/// Phrases copied out of the question by a model. There is deliberately no price field:
/// prices only ever come from the digits the user typed.
struct InterpretedPhrases: Equatable, Sendable {
    var item: String
    var dateText: String?
}

protocol QuestionInterpreter: Sendable {
    func interpret(_ text: String) async throws -> InterpretedPhrases
}

struct AIReadResult: Equatable {
    var parsed: ParsedQuestion
    /// Shown on the confirm card when the model could not be used.
    var note: String?
}

/// Combines a model's reading with the built-in parser, trusting the model only for
/// phrases that really appear in the question.
enum AIReader {
    static func read(_ text: String, interpreter: any QuestionInterpreter,
                     today: Date, timeZone: TimeZone) async -> AIReadResult {
        let builtIn = QuestionParser.parse(text, today: today, timeZone: timeZone)
        let phrases: InterpretedPhrases
        do {
            phrases = try await interpreter.interpret(text)
        } catch {
            return AIReadResult(parsed: builtIn, note: "Read without on-device AI this time. Look over each field.")
        }

        let question = text.lowercased()
        var result = builtIn
        result.source = .onDeviceAI

        let item = phrases.item.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !item.isEmpty, question.contains(item) {
            result.item = item
        }

        if let dateText = phrases.dateText?.trimmingCharacters(in: .whitespacesAndNewlines),
           !dateText.isEmpty, question.contains(dateText.lowercased()),
           let date = QuestionParser.date(in: dateText, today: today, timeZone: timeZone) {
            result.date = date
        }

        // result.price stays builtIn.price: exactly one typed amount, or blank for the user.
        return AIReadResult(parsed: result, note: nil)
    }
}
