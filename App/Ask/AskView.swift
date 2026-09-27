import HeadroomCore
import SwiftUI

/// What the top of Ask shows: the spending room with the drawing behind it, the question
/// about a balance confirmed on an earlier day, or what the plan is missing.
enum AskHomeState: Equatable {
    case room(RoomDetail)
    /// The only thing missing is today's confirmation of this balance.
    case stale(balance: Money, lastConfirmed: LocalDate)
    case needsInfo([MissingInfo])

    init(plan: CashPlan, today: LocalDate) {
        switch CashEngine.roomDetail(plan, today: today) {
        case .room(let detail):
            self = .room(detail)
        case .needsInfo(let missing):
            if case .balanceNotConfirmedToday(let last)? = missing.first, missing.count == 1,
               let balance = plan.balance {
                self = .stale(balance: balance.amount, lastConfirmed: last)
            } else {
                self = .needsInfo(missing)
            }
        }
    }
}

/// Home (docs/REDESIGN-SPEC.md 5.1): the spending room keyed by the clearance glyph to a
/// true-scale gap in the gauge, then one question, then what is coming up.
struct AskView: View {
    @Binding var selectedTab: AppTab
    @Environment(PlanStore.self) private var store
    @Environment(\.today) private var today
    @State private var question = ""
    @State private var confirm: ConfirmRequest?
    @State private var path: [Purchase] = []
    /// True from the moment the Confirm sheet opens until it has finished closing.
    @State private var confirmOnScreen = false
    @State private var confirmingBalance = false
    @State private var isReading = false
    @FocusState private var questionFocused: Bool
    @AppStorage(OnDeviceAI.settingKey) private var useOnDeviceAI = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.dynamicTypeSize) private var size
    @Environment(\.legibilityWeight) private var legibility

    private var isEmptyPlan: Bool {
        store.plan.balance == nil && store.plan.floor == nil && store.plan.events.isEmpty
    }

    private var hasText: Bool {
        !question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if store.isUnavailable {
                    unavailableState
                } else if isEmptyPlan {
                    EmptyStateView(
                        onSetUp: { selectedTab = .plan },
                        onSample: { store.update { $0 = SamplePlan.make(today: today) } }
                    )
                } else {
                    content
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Theme.canvas.ignoresSafeArea())
            .navigationTitle("Headroom")
            .navigationDestination(for: Purchase.self) {
                // Result opens under the closing sheet; its measurement waits until it is in view.
                ResultView(initialPurchase: $0, isCovered: confirmOnScreen)
            }
            .onChange(of: confirm?.id) { _, id in
                if id != nil { confirmOnScreen = true }
            }
            .sheet(item: $confirm, onDismiss: { confirmOnScreen = false }) { request in
                ConfirmCard(draft: request.draft, note: request.note,
                            question: request.question, spans: request.spans) { purchase in
                    confirm = nil
                    path.append(purchase)
                }
            }
            .sheet(isPresented: $confirmingBalance) { ConfirmBalanceSheet() }
        }
    }

    private var content: some View {
        let state = AskHomeState(plan: store.plan, today: today)
        return ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Space.xxl) {
                    switch state {
                    case .room(let detail):
                        reading(detail)
                        RoomGauge(detail: detail)
                    case .stale(let balance, let lastConfirmed):
                        stalePrompt(balance: balance, lastConfirmed: lastConfirmed)
                    case .needsInfo(let missing):
                        needsInfo(missing)
                    }
                    askSection
                    if case .room(let detail) = state {
                        let entries = CashEngine.register(detail.points, through: detail.low.date)
                        if !entries.isEmpty {
                            ComingUpList(entries: entries,
                                         tint: ClearanceGlyph.Kind(low: detail.low.amount, floor: detail.floor).tint)
                        }
                    }
                }
                .scenePadding(.horizontal)
                .padding(.top, Theme.Space.s)
                .padding(.bottom, Theme.Space.xxl)
            }
            .scrollDismissesKeyboard(.interactively)
            // Keep the Ask button above the keyboard while the question is being typed.
            .onChange(of: questionFocused) { _, focused in
                if focused { scrollToField(proxy) }
            }
            .onChange(of: question) {
                if questionFocused { scrollToField(proxy) }
            }
        }
    }

    private func scrollToField(_ proxy: ScrollViewProxy) {
        proxy.scrollTo("askField", anchor: .bottom)
    }

    /// The plan file exists but is protected until the iPhone is unlocked.
    private var unavailableState: some View {
        VStack(alignment: .leading, spacing: Theme.Space.s) {
            DatumRule()
                .frame(width: 120)
                .padding(.bottom, Theme.Space.s)
            Text("Unlock your iPhone to open your plan")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Theme.textPrimary)
            Text("Your plan is protected while the phone is locked. It opens as soon as you unlock.")
                .font(.body)
                .foregroundStyle(Theme.textSecondary)
        }
        .scenePadding(.horizontal)
        .padding(.top, Theme.Space.xl)
    }

    // MARK: Spending room

    /// "Spending room today", the clearance glyph and the figure, then what it means.
    /// One VoiceOver element; the figure keeps the `spendingRoom` identifier.
    private func reading(_ detail: RoomDetail) -> some View {
        let kind = ClearanceGlyph.Kind(low: detail.low.amount, floor: detail.floor)
        return VStack(alignment: .leading, spacing: Theme.Space.xs) {
            Text("Spending room today")
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
            HStack(alignment: .firstTextBaseline, spacing: Theme.Space.s) {
                ClearanceGlyph(kind: kind, tint: kind.tint,
                               height: Typography.capHeight(.readingXL, size: size, boldText: legibility == .bold))
                Text(detail.room.displayText)
                    .overpass(.readingXL)
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .contentTransition(reduceMotion ? .identity : .numericText(value: Double(detail.room.cents)))
                    .accessibilityIdentifier("spendingRoom")
            }
            Text(Explainer.roomCaption(detail))
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }

    private func stalePrompt(balance: Money, lastConfirmed: LocalDate) -> some View {
        VStack(alignment: .leading, spacing: Theme.Space.l) {
            VStack(alignment: .leading, spacing: Theme.Space.xs) {
                Text("Is your balance still \(balance.displayText)?")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Last confirmed \(lastConfirmed.shortTextNoBreak). Headroom only answers with today's balance.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            HStack(spacing: Theme.Space.m) {
                Button { confirmSameBalance(balance) } label: {
                    Text("Yes").foregroundStyle(Theme.onAccent)
                }
                .buttonStyle(.glassProminent)
                Button("Change it") { confirmingBalance = true }
                    .buttonStyle(.glass)
            }
            .controlSize(.large)
        }
    }

    private func needsInfo(_ missing: [MissingInfo]) -> some View {
        VStack(alignment: .leading, spacing: Theme.Space.m) {
            StatusLabel(status: .needsInfo, title: ResultView.needsInfoHeadline)
            VStack(alignment: .leading, spacing: Theme.Space.s) {
                ForEach(missing, id: \.self) { item in
                    Text(Explainer.text(for: item))
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Button("Open Plan") { selectedTab = .plan }
                .buttonStyle(.glass)
                .controlSize(.large)
        }
    }

    /// "Yes" confirms the same amount. If something is scheduled today, ask about it first.
    private func confirmSameBalance(_ balance: Money) {
        let hasItemsToday = store.plan.events.contains { !$0.schedule.occurrences(from: today, through: today).isEmpty }
        if hasItemsToday {
            confirmingBalance = true
        } else {
            store.confirmBalance(balance, today: today, billsAlreadyOut: [], incomeStillComing: [])
        }
    }

    // MARK: Question

    private var askSection: some View {
        VStack(alignment: .leading, spacing: Theme.Space.s) {
            Text("Ask about a purchase")
                .font(.headline)
                .foregroundStyle(Theme.textPrimary)
                .accessibilityAddTraits(.isHeader)
                .padding(.bottom, Theme.Space.xs)
            questionField
            Text("Include a price and a day.")
                .font(.footnote)
                .foregroundStyle(Theme.textSecondary)
            Button {
                questionFocused = false
                confirm = ConfirmRequest(draft: PurchaseDraft(
                    parsed: ParsedQuestion(item: nil, price: nil, date: nil, source: .builtIn), today: today))
            } label: {
                Text("Enter details instead")
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .foregroundStyle(Theme.accent)
        }
    }

    /// The question on a Plate, with the Ask capsule in its bottom-trailing corner once
    /// there is text. The placeholder is its own text so it wraps instead of truncating.
    private var questionField: some View {
        VStack(alignment: .trailing, spacing: Theme.Space.s) {
            // The placeholder sits in the layout under the field, so a wrapped placeholder
            // at large text sizes grows the Plate instead of spilling out of it.
            ZStack(alignment: .topLeading) {
                if question.isEmpty {
                    Text("Can I buy a $700 laptop next Friday?")
                        .font(.title3)
                        .foregroundStyle(Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
                // An empty prompt: the title stays the VoiceOver label, but only the
                // placeholder above is drawn.
                TextField("Question", text: $question, prompt: Text(verbatim: ""), axis: .vertical)
                    .font(.title3)
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1...6)
                    .focused($questionFocused)
                    .submitLabel(.go)
                    .onSubmit(ask)
                    .onChange(of: question) { _, new in
                        // Return in a vertical field arrives as a newline: treat it as Ask.
                        if new.hasSuffix("\n") {
                            question.removeLast()
                            ask()
                        }
                    }
                    .accessibilityLabel("Question")
                    .accessibilityHint("For example, can I buy a $700 laptop next Friday?")
                    .accessibilityIdentifier("question")
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .contentShape(.rect)
            .onTapGesture { questionFocused = true }
            askButton
        }
        .padding(Theme.Space.l)
        .frame(maxWidth: .infinity, minHeight: 96, alignment: .topLeading)
        .background(Theme.surface, in: .rect(cornerRadius: Theme.radius, style: .continuous))
        .overlay {
            if contrast == .increased {
                RoundedRectangle(cornerRadius: Theme.radius, style: .continuous)
                    .strokeBorder(Theme.textSecondary, lineWidth: 1)
            }
        }
        .id("askField")
    }

    private var askButton: some View {
        Button(action: ask) {
            Group {
                if isReading {
                    Label("Reading", systemImage: "sparkles")
                        .symbolEffect(.pulse, options: .repeating, isActive: !reduceMotion)
                        .accessibilityLabel("Reading your question")
                } else {
                    Text("Ask")
                }
            }
            .foregroundStyle(Theme.onAccent)
            // The regular capsule is 34 pt tall; this makes it a 44 pt touch target.
            .frame(minHeight: 30)
            .contentShape(.rect)
        }
        .buttonStyle(.glassProminent)
        .controlSize(.regular)
        .opacity(hasText ? 1 : 0)
        .disabled(!hasText || isReading)
        .allowsHitTesting(hasText)
        .accessibilityHidden(!hasText)
        .accessibilityIdentifier("check")
        .animation(reduceMotion ? nil : .easeOut(duration: 0.15), value: hasText)
    }

    /// Reads the question once, then asks the user to confirm what was read. Nothing is
    /// calculated until they check it.
    private func ask() {
        let text = question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !isReading, confirm == nil, !text.isEmpty else { return }
        questionFocused = false
        guard useOnDeviceAI, OnDeviceAI.availability == .available else {
            let now = Date()
            let parsed = QuestionParser.parse(text, today: now, timeZone: .current)
            confirm = ConfirmRequest(draft: PurchaseDraft(parsed: parsed, today: today), question: text,
                                     spans: QuestionSpans.find(in: text, parsed: parsed, today: now, timeZone: .current))
            return
        }
        isReading = true
        Task {
            let now = Date()
            let result = await AIReader.read(text, interpreter: OnDeviceInterpreter(), today: now, timeZone: .current)
            isReading = false
            confirm = ConfirmRequest(draft: PurchaseDraft(parsed: result.parsed, today: today),
                                     note: result.note, question: text,
                                     spans: QuestionSpans.find(in: text, parsed: result.parsed, today: now, timeZone: .current))
        }
    }
}

struct ConfirmRequest: Identifiable {
    let id = UUID()
    let draft: PurchaseDraft
    var note: String?
    /// The question as typed, or nil when opened with "Enter details instead".
    var question: String?
    /// Where each field was read from in `question`, for the underlines on the Confirm sheet.
    var spans: [ReadSpan] = []
}
