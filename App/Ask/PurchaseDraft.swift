import Foundation
import HeadroomCore

/// The confirm step: what the question was read as, editable before anything is calculated.
struct PurchaseDraft {
    var item: String
    var priceText: String
    var date: Date
    let source: ParseSource

    init(parsed: ParsedQuestion, today: LocalDate, timeZone: TimeZone = .current) {
        item = parsed.item ?? ""
        priceText = parsed.price.map(MoneyInput.editableText) ?? ""
        date = Date(parsed.date ?? today, timeZone: timeZone)
        source = parsed.source
    }

    private var price: Money? {
        guard let money = MoneyInput.parse(priceText), money > .zero else { return nil }
        return money
    }

    func errors(today: LocalDate, timeZone: TimeZone = .current) -> [String] {
        var list: [String] = []
        if price == nil { list.append("Enter a price, like 700 or 49.99.") }
        let day = LocalDate(date, timeZone: timeZone)
        let latest = today.adding(days: CashEngine.purchaseRangeDays)
        if day < today {
            list.append(Explainer.text(for: .dateInPast))
        } else if day > latest {
            list.append(Explainer.text(for: .dateBeyondRange(latest: latest)))
        }
        return list
    }

    func makePurchase(today: LocalDate, timeZone: TimeZone = .current) -> Purchase? {
        guard errors(today: today, timeZone: timeZone).isEmpty, let price else { return nil }
        let name = item.trimmingCharacters(in: .whitespacesAndNewlines)
        return Purchase(item: name.isEmpty ? "Purchase" : name, price: price, date: LocalDate(date, timeZone: timeZone))
    }
}
