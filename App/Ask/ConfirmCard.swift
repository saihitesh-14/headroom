import HeadroomCore
import SwiftUI

/// Confirm details (docs/REDESIGN-SPEC.md 5.2): the question as typed, with the words that
/// were read underlined, then the fields they became. Nothing is calculated until Check.
struct ConfirmCard: View {
    @Environment(\.today) private var today
    @Environment(\.dismiss) private var dismiss
    @State var draft: PurchaseDraft
    /// Shown under the quote when on-device AI could not read the question.
    var note: String?
    /// The question as typed, or nil when opened with "Enter details instead".
    var question: String?
    /// Where each field was read from in `question`.
    var spans: [ReadSpan] = []
    let onCheck: (Purchase) -> Void
    @State private var showErrors = false
    @FocusState private var focus: Field?

    private enum Field { case item, price }

    var body: some View {
        NavigationStack {
            Form {
                if let question {
                    // No card: the quote sits on the sheet, lined up with the rows below it.
                    Section {
                        quote(question)
                            .listRowBackground(Color.clear)
                    }
                }

                Section {
                    LabeledContent("Item") {
                        TextField("Item", text: $draft.item, prompt: Text("Laptop"))
                            .multilineTextAlignment(.trailing)
                            .focused($focus, equals: .item)
                    }
                    CurrencyField(label: "Price", text: $draft.priceText, identifier: "price")
                        .focused($focus, equals: .price)
                    LabeledContent {
                        DatePicker("Date", selection: $draft.date, displayedComponents: .date)
                            .labelsHidden()
                    } label: {
                        VStack(alignment: .leading) {
                            Text("Date")
                            // Ink, not Graphite: at the medium detent the rows are glass over
                            // the dimmed screen, where Graphite falls to 4.2:1.
                            Text(LocalDate(draft.date).weekdayName)
                                .font(.footnote)
                                .foregroundStyle(Theme.textPrimary)
                        }
                    }
                } header: {
                    Text("Purchase").sectionText()
                } footer: {
                    footer
                }
            }
            .navigationTitle("Confirm details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Check", role: .confirm, action: check)
                        .accessibilityIdentifier("confirmCheck")
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { focus = nil }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    /// The question in curly quotes, then where it was read.
    private func quote(_ question: String) -> some View {
        VStack(alignment: .leading, spacing: Theme.Space.s) {
            Text(QuestionSpans.quote(question, spans: spans))
                .font(.body)
                .foregroundStyle(Theme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            VStack(alignment: .leading, spacing: Theme.Space.xs) {
                Text(draft.source == .onDeviceAI ? "Read on this iPhone with on-device AI." : "Read on this iPhone.")
                if let note { Text(note) }
            }
            .font(.footnote)
            .foregroundStyle(Theme.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder private var footer: some View {
        let errors = draft.errors(today: today)
        if showErrors, !errors.isEmpty {
            Label(errors.joined(separator: " "), systemImage: "exclamationmark.circle")
                .foregroundStyle(Theme.danger)
        } else {
            VStack(alignment: .leading, spacing: Theme.Space.xs) {
                if question == nil, let note { Text(note) }
                Text("Paid from checking. Make sure these match what you meant.")
            }
            .sectionText()
        }
    }

    private func check() {
        guard let purchase = draft.makePurchase(today: today) else {
            withAnimation { showErrors = true }
            // Said on every failed Check, not only the first, so a second try is not silent.
            AccessibilityNotification.Announcement(draft.errors(today: today).joined(separator: " ")).post()
            return
        }
        onCheck(purchase)
    }
}
