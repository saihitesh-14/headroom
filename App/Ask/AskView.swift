import HeadroomCore
import SwiftUI

/// Home: spending room today, then one question.
struct AskView: View {
    @Binding var selectedTab: AppTab
    @Environment(PlanStore.self) private var store
    @Environment(\.today) private var today
    @State private var question = ""
    @State private var confirm: ConfirmRequest?
    @State private var path: [Purchase] = []
    @State private var confirmingBalance = false
    @State private var isReading = false
    @AppStorage(OnDeviceAI.settingKey) private var useOnDeviceAI = true
    @ScaledMetric(relativeTo: .largeTitle) private var heroSize: CGFloat = 56
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var isEmptyPlan: Bool {
        store.plan.balance == nil && store.plan.floor == nil && store.plan.events.isEmpty
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
            .navigationDestination(for: Purchase.self) { ResultView(initialPurchase: $0) }
            .sheet(item: $confirm) { request in
                ConfirmCard(draft: request.draft, note: request.note) { purchase in
                    confirm = nil
                    path.append(purchase)
                }
            }
            .sheet(isPresented: $confirmingBalance) { ConfirmBalanceSheet() }
        }
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.xxl) {
                roomSection
                askSection
            }
            .padding(.horizontal, Theme.Space.xl)
            .padding(.top, Theme.Space.s)
            .padding(.bottom, Theme.Space.xxl)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    /// The plan file exists but is protected until the iPhone is unlocked.
    private var unavailableState: some View {
        VStack(alignment: .leading, spacing: Theme.Space.s) {
            Image(systemName: "lock.fill")
                .font(.system(size: 36, weight: .medium))
                .foregroundStyle(Theme.accent)
            Text("Unlock your iPhone to open your plan")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Theme.textPrimary)
            Text("Your plan is protected while the phone is locked. It opens as soon as you unlock.")
                .font(.body)
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(.horizontal, Theme.Space.xl)
        .padding(.top, Theme.Space.xl)
    }

    // MARK: Spending room

    @ViewBuilder private var roomSection: some View {
        switch CashEngine.spendingRoom(store.plan, today: today) {
        case .room(let room, let through):
            VStack(alignment: .leading, spacing: Theme.Space.xs) {
                Text("Spending room today")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Theme.textSecondary)
                Text(room.formatted)
                    .font(.system(size: heroSize, weight: .semibold, design: .rounded).monospacedDigit())
                    .foregroundStyle(Theme.textPrimary)
                    .contentTransition(.numericText())
                    .accessibilityIdentifier("spendingRoom")
                Text("above your \(store.plan.floor?.formatted ?? "$0") floor, through \(through.shortText)")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
            }
            .accessibilityElement(children: .combine)
        case .needsInfo(let missing):
            if case .balanceNotConfirmedToday(let last)? = missing.first, missing.count == 1,
               let balance = store.plan.balance {
                stalePrompt(balance: balance.amount, lastConfirmed: last)
            } else {
                needsInfoCard(missing)
            }
        }
    }

    private func stalePrompt(balance: Money, lastConfirmed: LocalDate) -> some View {
        VStack(alignment: .leading, spacing: Theme.Space.m) {
            VStack(alignment: .leading, spacing: Theme.Space.xs) {
                Text("Is your balance still \(balance.formatted)?")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text("Last confirmed \(lastConfirmed.shortText). Headroom only answers with today's balance.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
            }
            HStack(spacing: Theme.Space.m) {
                Button("Yes") { confirmSameBalance(balance) }
                    .buttonStyle(.glassProminent)
                Button("Update") { confirmingBalance = true }
                    .buttonStyle(.glass)
            }
            .controlSize(.large)
        }
        .surfaceCard()
    }

    private func needsInfoCard(_ missing: [MissingInfo]) -> some View {
        VStack(alignment: .leading, spacing: Theme.Space.m) {
            StatusLabel(status: .needsInfo, title: "Needs more information")
            VStack(alignment: .leading, spacing: Theme.Space.s) {
                ForEach(missing, id: \.self) { item in
                    Text(Explainer.text(for: item))
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            Button("Open Plan") { selectedTab = .plan }
                .buttonStyle(.glass)
        }
        .surfaceCard()
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
        VStack(alignment: .leading, spacing: Theme.Space.m) {
            Text("Ask about a purchase")
                .font(.headline)
                .foregroundStyle(Theme.textPrimary)
            TextField("Question", text: $question,
                      prompt: Text("Can I buy a $700 laptop next Friday?"), axis: .vertical)
                .lineLimit(2...4)
                .padding(Theme.Space.l)
                .background(Theme.surface, in: .rect(cornerRadius: Theme.radius, style: .continuous))
                .submitLabel(.go)
                .onSubmit(check)
                .accessibilityIdentifier("question")
            Button(action: check) {
                Group {
                    if isReading {
                        Label("Reading your question", systemImage: "sparkles")
                            .symbolEffect(.pulse, options: .repeating, isActive: !reduceMotion)
                    } else {
                        Text("Check")
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .controlSize(.large)
            .disabled(isReading || question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .accessibilityIdentifier("check")
            Button("Use the form instead") {
                confirm = ConfirmRequest(draft: PurchaseDraft(
                    parsed: ParsedQuestion(item: nil, price: nil, date: nil, source: .builtIn), today: today))
            }
            .font(.subheadline.weight(.medium))
            .frame(maxWidth: .infinity)
        }
    }

    private func check() {
        let text = question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isReading else { return }
        guard useOnDeviceAI, OnDeviceAI.availability == .available else {
            let parsed = QuestionParser.parse(text, today: Date(), timeZone: .current)
            confirm = ConfirmRequest(draft: PurchaseDraft(parsed: parsed, today: today))
            return
        }
        isReading = true
        Task {
            let result = await AIReader.read(text, interpreter: OnDeviceInterpreter(), today: Date(), timeZone: .current)
            isReading = false
            confirm = ConfirmRequest(draft: PurchaseDraft(parsed: result.parsed, today: today), note: result.note)
        }
    }
}

struct ConfirmRequest: Identifiable {
    let id = UUID()
    let draft: PurchaseDraft
    var note: String?
}
