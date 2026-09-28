import HeadroomCore
import SwiftUI

/// The what-if controls docked above the tab bar on Result (docs/REDESIGN-SPEC.md 5.3):
/// a date capsule that opens a calendar, and a price capsule. Both are Liquid Glass.
///
/// A typed price is committed on submit, on focus loss, or after a 400 ms pause, so the
/// verdict and its haptic never flip mid-typing. An invalid price keeps the last valid
/// one analyzed and says so under the bar.
struct WhatIfBar: View {
    @Binding var purchase: Purchase
    let today: LocalDate
    @State private var priceText: String
    @State private var priceError = false
    @State private var showDate = false
    @FocusState private var priceFocused: Bool
    @Environment(\.colorSchemeContrast) private var contrast

    static let priceErrorText = "Enter a price, like 700 or 49.99."

    init(purchase: Binding<Purchase>, today: LocalDate) {
        _purchase = purchase
        self.today = today
        _priceText = State(initialValue: MoneyInput.editableText(purchase.wrappedValue.price))
    }

    /// The price a what-if entry commits, or nil when it is not a positive amount.
    static func committedPrice(_ text: String) -> Money? {
        guard let price = MoneyInput.parse(text), price > .zero else { return nil }
        return price
    }

    var body: some View {
        GlassEffectContainer(spacing: Theme.Space.s) {
            VStack(alignment: .leading, spacing: Theme.Space.s) {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: Theme.Space.s) { dateCapsule; priceCapsule }
                    VStack(alignment: .leading, spacing: Theme.Space.s) { dateCapsule; priceCapsule }
                }
                if priceError { priceErrorLine }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .scenePadding(.horizontal)
        .padding(.vertical, Theme.Space.s)
        .task(id: priceText) {
            do { try await Task.sleep(for: .milliseconds(400)) } catch { return }
            commit()
        }
        .onChange(of: priceFocused) { _, focused in
            if !focused { commit() }
        }
        .onChange(of: priceError) { _, shown in
            if shown { AccessibilityNotification.Announcement(Self.priceErrorText).post() }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { priceFocused = false }
            }
        }
    }

    private var dateCapsule: some View {
        Button { showDate = true } label: {
            Label(purchase.date.shortText, systemImage: "calendar")
                .font(.body)
                .foregroundStyle(Theme.accent)
                .padding(.horizontal, Theme.Space.l)
                .frame(minHeight: 44)
                .contentShape(.capsule)
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: .capsule)
        .overlay { contrastStroke }
        .accessibilityLabel("Purchase date, \(purchase.date.spokenText)")
        .accessibilityHint("Opens a calendar")
        .accessibilityIdentifier("whatIfDate")
        .popover(isPresented: $showDate) {
            DatePicker("Purchase date", selection: dateBinding,
                       in: Date(today)...Date(today.adding(days: CashEngine.purchaseRangeDays)),
                       displayedComponents: .date)
                .datePickerStyle(.graphical)
                .tint(Theme.accent)
                .padding()
                .presentationCompactAdaptation(.popover)
        }
    }

    private var priceCapsule: some View {
        CurrencyField(label: "Price", text: $priceText, compact: true)
            .focused($priceFocused)
            .onSubmit(commit)
            .padding(.horizontal, Theme.Space.l)
            .frame(minWidth: 96, minHeight: 44)
            .contentShape(.capsule)
            .onTapGesture { priceFocused = true }
            .glassEffect(.regular.interactive(), in: .capsule)
            .overlay { contrastStroke }
    }

    /// The error sits on glass of its own: the bar floats over the scrolling Result, and bare
    /// Brick text there would land on Ink text and lines. The glass is tinted with Paper so a
    /// bright line passing behind it stays faint under the words.
    private var priceErrorLine: some View {
        Label(Self.priceErrorText, systemImage: "exclamationmark.circle")
            .font(.footnote)
            .foregroundStyle(Theme.danger)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, Theme.Space.m)
            .padding(.vertical, Theme.Space.s)
            .glassEffect(.regular.tint(Theme.canvas.opacity(0.6)),
                         in: .rect(cornerRadius: Theme.radius, style: .continuous))
    }

    /// Increase Contrast outlines each capsule in Graphite.
    @ViewBuilder
    private var contrastStroke: some View {
        if contrast == .increased {
            Capsule()
                .strokeBorder(Theme.textSecondary, lineWidth: 1)
                .allowsHitTesting(false)
        }
    }

    private var dateBinding: Binding<Date> {
        Binding(
            get: { Date(purchase.date) },
            set: { purchase.date = LocalDate($0) }
        )
    }

    private func commit() {
        guard let price = Self.committedPrice(priceText) else {
            priceError = true
            return
        }
        priceError = false
        if price != purchase.price { purchase.price = price }
    }
}
