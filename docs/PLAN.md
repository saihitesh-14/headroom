# Headroom — MVP Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A privacy-first iPhone app that answers *"If I buy this for $X on date Y, what happens to my checking balance before my upcoming bills?"* — clean, calm UI; shipped as a small, tested, public GitHub project under **saihitesh-14**.

**Architecture:** A pure-Swift engine package (`HeadroomCore`) simulates dated cash events day by day and returns a typed analysis; no UI, no network, no time-zone-dependent dates. A SwiftUI app (Apple HIG + iOS 26 Liquid Glass, design rules adapted from the taste skill) collects the plan, reads the question (built-in parser; Apple's on-device model when available), makes the user confirm item/price/date, and renders the engine's numbers. **AI never does math; every number comes from digits you typed or from the engine.**

**Tech Stack:** Swift 6 · SwiftUI · Swift Charts · SF Symbols · Swift Testing + XCTest UI test · XcodeGen 2.46 · LocalAuthentication · Foundation Models · GitHub Actions (`macos-26`)

**Spec:** your original plan (saved into the repo as `docs/original-plan.md`) + the changes listed under Context + your feedback (clean aesthetic UI via the taste skill; saihitesh-14 account).

---

## Context

You want a quick, working MVP you can test and publish on GitHub as a portfolio project, with a clean, good-looking UI. The original plan is sound but sized like several releases. This plan keeps its core (a deterministic cash-flow engine with honest result states) and cuts everything else to a version I build in this session, milestone by milestone, with tests at every step. A second reviewer checked the engine rules and Apple/GitHub details; its fixes are in.

**What changed from the original plan**
- Mac-local AI adapter: **dropped**. OpenAI cloud mode, goals, credit cards, CSV/transactions: **README roadmap**.
- Storage: **JSON file** with iOS file protection instead of SwiftData.
- Engine: **one fixed horizon** (today → today+61) for every purchase date; the original 30-day window missed next month's rent for late dates and could make "buy today" look falsely safe.
- Engine: when you confirm your balance, **anything scheduled today can be marked** (bill already came out / pay still coming), so payday and rent day don't give false alarms.
- AI: built-in parser first; Apple's on-device model reads the *item and date phrase only*; prices always come from the digits you typed. **No network code at all.**

---

## 1. What you'll have at the end

- `github.com/saihitesh-14/headroom`: public repo, README built like a small landing page (hero screenshot, how it works, privacy model), MIT license, CI badge. Commits authored as saihitesh-14.
- An app that runs in the iPhone Simulator (and on your iPhone via Xcode), in light and dark mode.
- ~45 engine tests (including your worked example), parser/storage tests, one UI smoke test; CI green on every push.

**Screens (wireframes, real numbers from the sample plan, asked Sat Sep 26)**
```
Ask (home)                               Result
┌──────────────────────────────────┐    ┌──────────────────────────────────┐
│ Headroom                         │    │ ‹ Ask                            │
│                                  │    │ ⚠︎ Would cross your cash floor    │
│ Spending room today              │    │ Lowest point: $5 on Mon Oct 12.  │
│ $505                             │    │ That's $195 below your $200 floor│
│ above your $200 floor,           │    │                                  │
│ through Thu Nov 26               │    │ [chart: without / with / floor]  │
│                                  │    │                                  │
│ Ask about a purchase             │    │ Earliest date that fits Thu Oct 15│
│ ┌──────────────────────────────┐ │    │ Spending room today         $505 │
│ │ Can I buy a $700 laptop next │ │    │ Checked through      Thu Nov 26 │
│ │ Friday?                      │ │    │                                  │
│ └──────────────────────────────┘ │    │ Try another date or price        │
│            ( Check )             │    │ Date [Fri Oct 2]  Price [$700]   │
│        Use the form instead      │    │                                  │
│                                  │    │ What moves your balance          │
│                                  │    │ Paycheck, Sep 30          +$800  │
│                                  │    │ Rent, Oct 1               -$750  │
│                                  │    │ Laptop, Oct 2             -$700  │
│                                  │    │ Groceries, 3 times        -$300  │
│                                  │    │ Phone, Oct 8               -$45  │
│                                  │    │ Next paycheck: +$800 on Wed Oct 14│
│  (  Ask    Plan    Settings  )   │    │ ▸ How this is calculated         │
└──────────────────────────────────┘    └──────────────────────────────────┘
```

## 2. Scope

**In the MVP**
- One checking balance, **confirmed today** (one tap when unchanged); today's scheduled items can be marked.
- Cash floor, explicitly set (can be $0).
- Income and bills: once, weekly, every 2 weeks, twice a month, monthly (days 29–31 fall on the month's last day).
- Weekly essentials (groceries/transport) as a weekly bill on a chosen weekday.
- **Ask:** type a question or use the form → confirm item / price / date → result.
- **Result:** 4 states (*Fits your cash floor* / *Would cross your cash floor* / *Known bills exceed projected cash* / *Needs more information*), lowest balance with and without the purchase, spending room, earliest date that fits (or why none), chart, what-if date & price, reasons, assumptions, "checked through".
- **Empty state** for first launch with "Set up my plan" and "Try the sample plan".
- **Privacy:** no network code, opt-in Face ID/passcode lock, app-switcher cover, file protection, delete-all.
- **On-device AI** question reading via Apple Foundation Models when available (last feature milestone).

**Not in the MVP** (README roadmap): OpenAI cloud mode with payload preview · savings goals · credit cards · transaction history / CSV import · irregular income · skipping/moving one occurrence · per-event same-day timing · spelled-out amounts ("seven hundred") · notifications · iCloud sync.

## 3. Decisions — change any before approving

| Decision | Default |
|---|---|
| App / repo name | **Headroom** (`headroom`) |
| Project folder | `~/Desktop/Headroom` |
| GitHub | **public** repo `saihitesh-14/headroom`; I confirm with you again right before pushing |
| Commit author | saihitesh-14 (name "Sai Hitesh Bommgani", GitHub no-reply email `215173653+saihitesh-14@users.noreply.github.com`), set for this repo only; each commit also ends with a `Co-Authored-By: Claude` line (say if you'd rather not) |
| Push | `gh` already has saihitesh-14 signed in (inactive). I switch to it for the push and switch back to Saihitesh2006 afterward |
| Accent color | **Evergreen** (deep, muted green) on cool neutral grays; amber and brick only for warnings |
| License | MIT |
| Minimum iOS | **26** (any iPhone 11 or newer). On-device AI also needs an Apple Intelligence iPhone (15 Pro or newer) |
| AI in MVP | Built-in parser + Apple on-device model; OpenAI later |
| Face ID lock | Included, **off by default** |
| Device backups | Normal iOS behavior (encrypted device/iCloud backups include your plan); README says so |
| Your original plan in the repo | Yes, `docs/original-plan.md` |
| Execution | **Native**: I build every task in this session, then one fresh reviewer checks the whole project before the push |

## 4. What I need from you

1. **Install Xcode** from the Mac App Store (free, large download; start it now, you have ~96 GB free). Open it once, accept the license, let it install the **iOS** platform/simulator.
2. Point the command-line tools at it (needs your password, so you run it):
   `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`
3. Approving this plan = OK for me to run `brew install xcodegen` (Homebrew, a few MB).
4. **Design check-in** after Task 10: I show you light and dark screenshots before moving on.
5. Right before the push: confirm repo name and visibility.
6. Optional, for your iPhone: plug it in, turn on Developer Mode, pick your Apple ID team in Xcode (a free Apple ID works; reinstall every 7 days).

While Xcode downloads I build the engine (Tasks 1–6): it compiles with the tools you have now; its tests run as soon as Xcode is in.

## 5. Design direction (taste skill, adapted for iOS)

The taste skill says native mobile is outside its web scope and points to Apple's HIG, so: **Apple HIG + native SwiftUI is the base**, and the skill's portable rules plus its mobile/fintech guidance sit on top. Its landing-page rules apply in full to the GitHub README.

- **Design read:** native iOS personal-finance utility for students (and portfolio reviewers), calm and trust-first, leaning toward Apple HIG + iOS 26 Liquid Glass + SF Pro with rounded tabular numerals + one accent color.
- **Dials:** DESIGN_VARIANCE 4 (native patterns, left-aligned, one strong focal number), MOTION_INTENSITY 3 (native transitions only), VISUAL_DENSITY 3 (airy; one focal point per screen).
- **Structure:** Liquid Glass tab bar (Ask / Plan / Settings), `NavigationStack`, sheets for editors. Glass only on the navigation/control layer (tab bar, toolbars, the one primary button per screen via `.glassProminent`); content sits on solid surfaces. No box-in-box: native inset-grouped lists and whitespace instead of card stacks; no stat-card grids or three equal cards.
- **Color:** cool neutral base (off-white / off-black, not pure #FFF/#000), one accent (Evergreen) used for all interactive elements and the "fits" state; muted amber (crosses floor) and brick (goes negative) for warnings only. Status is always icon + words, never color alone. All colors are tokens in `Theme.swift` + asset-catalog light/dark variants; no hard-coded colors in views.
- **Type:** SF Pro with Dynamic Type; money in SF Rounded, `monospacedDigit()`; one large number per screen (spending room on Ask, lowest point on Result); hierarchy through weight and color, not size jumps. Nothing smaller than footnote.
- **Shape lock:** 20 pt continuous corners for surfaces, capsule for buttons, native rows for inputs. Nothing else.
- **States:** composed empty state (first launch), inline errors under fields, a "Reading your question…" placeholder while AI runs, needs-info screens that list exactly what to fix with one action each.
- **Motion:** `.contentTransition(.numericText())` when what-if numbers change, chart eases between values, light haptic when the verdict changes; all off under Reduce Motion.
- **Copy:** short, plain, specific. **Zero em/en dashes in any UI string** (engine strings are tested for it), at most one middle dot per line, no filler verbs ("elevate", "seamless", "unlock"), button labels of 1–3 words, one label per intent ("Check" everywhere).
- **Icons:** SF Symbols only. App icon: simple, one accent glyph on neutral.
- **Accessibility:** WCAG AA contrast in both modes, VoiceOver labels on the chart and verdict, layouts hold at XL Dynamic Type, Increase Contrast respected.
- **Recorded in** `docs/DESIGN.md` (design read, dials, tokens, rules; credits the taste skill).

---

## Global Constraints

- Money is `Money` (Int cents). Never `Double`/`Float` for money, including when parsing text (use integer/`Decimal` math). Amounts are capped at **$10,000,000**; larger inputs are rejected.
- Engine dates are `LocalDate` (year, month, day). Engine logic never uses `Date`, `Calendar`, or `TimeZone`. The app converts at one place (`DateBridge`) using the **Gregorian** calendar and the device time zone.
- Engine functions are pure: `today` is always a parameter.
- Deployment target **iOS 26.0**; package `swift-tools-version: 6.0`, platforms `.iOS(.v26), .macOS(.v15)`. No iOS 27-only APIs (CI builds with Xcode 26.x on `macos-26`).
- No network code (CI fails on `URLSession`, `URLRequest`, `NWConnection`, `AsyncImage`, `WKWebView`, or `"http` string literals in app/engine sources).
- Never print or log amounts.
- Wording: never "affordable", "safe to spend", or "Buy now"; say "spending room through [date]". Every result shows "Checked through [date]" and its assumptions. No em/en dashes in user-visible strings.
- Views use `Theme` tokens only (colors, radii, spacing, number font).
- On-device AI: runtime availability check; never silently switches how questions are read; any error falls back to the built-in parser with a visible note.
- Bundle ID `io.github.saihitesh-14.headroom`. Swift 6 language mode.

## Engine rules (the contract)

1. **Required inputs** (otherwise *needs info*): a balance confirmed **today**; an explicitly set floor ($0 allowed); at least one income or bill; price $0.01–$10,000,000; purchase date today…today+30.
2. **Today's items:** when you confirm your balance, anything scheduled today is listed so you can mark *bills that already came out* and *income still coming today*. Unmarked bills are subtracted; unmarked income is not added. The app never overstates cash.
3. **Same day:** money out (including the purchase) before money in; the day's *low* is what counts. So a purchase *on* payday is checked against the pre-paycheck balance, and the earliest date that fits is usually the day after payday.
4. **One fixed horizon:** every analysis runs from today through **today+61** (30-day purchase range + 31 days lookahead), the same end for every purchase date. Late dates still see next month's rent, and if a date fits, every later date fits too.
5. **Verdict** for a purchase on D: the lowest point from D through the horizon (on and after D, the balance is the baseline minus the price). Below $0 → *known bills exceed projected cash*; below the floor → *would cross your floor by $X*; else *fits* (room = low − floor; exactly at the floor fits). If the plan is below the floor from D on even without the purchase, the headline says so and shows the purchase's share.
6. **Spending room today** = max(0, lowest baseline point from today through the horizon − floor).
7. **Earliest date that fits** = first date today…today+30 that fits; otherwise *none*, with the reason: *plan already short* or *not enough room*.
8. **Lowest point date** = the first day that reaches the minimum.

## Review Focus

Failure modes a real user will hit that happy-path tests miss; each has a test in its owning task.
1. **Balance confirmed yesterday** (or app left open past midnight) → *needs info* with one-tap "Still $X", never a verdict on a stale balance. *(Task 5: E7)*
2. **Payday or rent day** → marked pay isn't ignored, a cleared bill isn't subtracted twice. *(Tasks 4–5: E5, E5b, E6, E6b)*
3. **Purchase near the end of the range, or "buy today" vs later** → same horizon for all dates; next month's rent always seen. *(Task 5: E3, E13, MON)*
4. **Bill on the 29th–31st in a short month; biweekly anchors before the range** → last day of month; never an occurrence before its start. *(Task 3: S1–S3)*
5. **Prices like "$1,249.99", "$700.", "1249", two amounts, huge numbers, or an AI that would say 70 for "$700"** → price only from typed digits; ambiguous → left blank for the user. *(Tasks 9, 12)*

---

## File structure

```
Headroom/
├── README.md · LICENSE · .gitignore
├── project.yml                        # XcodeGen spec (source of truth); sources as synced folders
├── Headroom.xcodeproj/                # generated, committed so anyone can open it
├── .github/workflows/ci.yml
├── docs/ PLAN.md · DESIGN.md · original-plan.md · screenshots/
├── Packages/HeadroomCore/
│   ├── Package.swift
│   ├── Sources/HeadroomCore/
│   │   ├── Money.swift                # cents arithmetic, cap, "$1,249.99" formatting
│   │   ├── LocalDate.swift            # calendar-day math (days-from-civil), weekday, month length
│   │   ├── Schedule.swift             # recurrence → occurrences(from:through:), sign-safe modulo
│   │   ├── CashPlan.swift             # CashEvent, BalanceSnapshot, CashPlan, Purchase
│   │   ├── Projection.swift           # day-by-day simulation (rules 2–3)
│   │   ├── Analysis.swift             # Outcome, Verdict, horizon, room, earliest fit (rules 1, 4–8)
│   │   └── Explainer.swift            # deterministic headline / summary / reasons / assumptions
│   └── Tests/HeadroomCoreTests/       # one test file per source file
├── App/
│   ├── HeadroomApp.swift · RootView.swift          # tabs, lock gate, privacy cover
│   ├── DesignSystem/ Theme.swift · MoneyText.swift · StatusLabel.swift
│   ├── Plan/     PlanStore.swift · SamplePlan.swift · PlanView.swift · EventEditor.swift · ConfirmBalanceSheet.swift
│   ├── Ask/      AskView.swift · EmptyStateView.swift · ConfirmCard.swift · QuestionParser.swift · OnDeviceInterpreter.swift
│   ├── Result/   ResultView.swift · CashChart.swift
│   ├── Settings/ SettingsView.swift · AppLock.swift
│   ├── Support/  DateBridge.swift                  # the only place Date meets LocalDate
│   └── Resources/ Assets.xcassets                  # color sets (light/dark), app icon
├── AppTests/     QuestionParserTests.swift · DateBridgeTests.swift · PlanStoreTests.swift · SamplePlanTests.swift · InterpreterTests.swift
└── AppUITests/   SmokeTests.swift
```

## Core interfaces (HeadroomCore)

```swift
public struct Money: Codable, Hashable, Comparable, Sendable {
    public var cents: Int
    public static let maximum = Money(cents: 1_000_000_000)          // $10,000,000
    public static func dollars(_ d: Int) -> Money
    public static func + (l: Money, r: Money) -> Money                // also -, prefix -
    public var formatted: String                                      // "$700", "$1,249.99", "-$450", "$0.05"
}

public struct LocalDate: Codable, Hashable, Comparable, Sendable {
    public let year: Int, month: Int, day: Int
    public init?(year: Int, month: Int, day: Int)                     // nil for invalid dates
    public func adding(days: Int) -> LocalDate
    public func days(until other: LocalDate) -> Int
    public var weekday: Int                                           // 1 = Sunday … 7 = Saturday
    public static func daysInMonth(year: Int, month: Int) -> Int
    public var shortText: String                                      // "Fri Oct 2"
}

public enum Schedule: Codable, Hashable, Sendable {
    case once(LocalDate)
    case weekly(from: LocalDate)                                      // `from` = first occurrence
    case everyTwoWeeks(from: LocalDate)
    case twiceMonthly(day1: Int, day2: Int)                           // 1…31, clamped to month length
    case monthly(day: Int)                                            // 1…31, clamped to month length
    public func occurrences(from: LocalDate, through: LocalDate) -> [LocalDate]
}

public struct CashEvent: Codable, Hashable, Identifiable, Sendable {
    public enum Kind: String, Codable, Sendable { case income, bill }
    public var id: UUID; public var name: String
    public var amount: Money                                          // positive; kind gives direction
    public var kind: Kind; public var schedule: Schedule
}
public struct BalanceSnapshot: Codable, Hashable, Sendable {
    public var amount: Money; public var asOf: LocalDate
    public var billsAlreadyOutToday: Set<UUID> = []                   // today's bills already reflected
    public var incomeStillComingToday: Set<UUID> = []                 // today's income not yet reflected
}
public struct CashPlan: Codable, Hashable, Sendable {
    public var balance: BalanceSnapshot?; public var floor: Money?; public var events: [CashEvent]
}
public struct Purchase: Codable, Hashable, Sendable { public var item: String; public var price: Money; public var date: LocalDate }

public struct DayPoint: Hashable, Sendable {
    public let date: LocalDate; public let low: Money; public let close: Money
    public let lines: [Line]                                          // what moved that day
    public struct Line: Hashable, Sendable { public let name: String; public let amount: Money; public let isIncome: Bool; public let isPurchase: Bool }
}
public struct Low: Hashable, Sendable { public let amount: Money; public let date: LocalDate }

public enum MissingInfo: Hashable, Sendable {
    case balance, balanceNotConfirmedToday(lastConfirmed: LocalDate), floor, noEvents
    case invalidPrice, dateInPast, dateBeyondRange(latest: LocalDate)
}
public enum Verdict: Hashable, Sendable { case fits(room: Money), crossesFloor(by: Money), goesNegative(by: Money) }
public enum BaselineWarning: Hashable, Sendable { case belowFloor(Low), negative(Low) }
public enum EarliestFit: Hashable, Sendable {
    case on(LocalDate)
    case none(NoFitReason)
    public enum NoFitReason: Hashable, Sendable { case planAlreadyShort, notEnoughRoom }
}

public struct Analysis: Sendable {
    public let purchase: Purchase; public let floor: Money; public let today: LocalDate
    public let verdict: Verdict
    public let checkedThrough: LocalDate                              // today + 61
    public let baseline: [DayPoint]; public let withPurchase: [DayPoint]   // today…checkedThrough
    public let baselineLow: Low                                       // today…horizon
    public let baselineLowFromPurchaseDate: Low                       // D…horizon ("already short?")
    public let purchaseLow: Low                                       // D…horizon, with purchase
    public let baselineWarning: BaselineWarning?
    public let spendingRoomToday: Money
    public let earliestFit: EarliestFit
}
public enum Outcome: Sendable { case needsInfo([MissingInfo]); case analyzed(Analysis) }
public enum RoomOutcome: Hashable, Sendable { case needsInfo([MissingInfo]); case room(Money, through: LocalDate) }

public enum CashEngine {
    public static let purchaseRangeDays = 30, horizonDays = 61
    public static func project(_ plan: CashPlan, today: LocalDate, through: LocalDate, purchase: Purchase?) -> [DayPoint]
    public static func analyze(_ plan: CashPlan, purchase: Purchase, today: LocalDate) -> Outcome
    public static func spendingRoom(_ plan: CashPlan, today: LocalDate) -> RoomOutcome   // Ask home screen; rule-1 checks minus the purchase ones
}
public enum Explainer {
    public static func headline(_ a: Analysis) -> String              // "Would cross your cash floor"
    public static func summary(_ a: Analysis) -> String               // "Lowest point: $150 on Mon Oct 5. That's $50 below your $200 floor."
    public static func reasons(_ a: Analysis) -> [String]             // money in/out from today to the low, grouped by name,
                                                                      // largest first (max 5); then first income on/after the low
    public static func earliestFitText(_ a: Analysis) -> String
    public static func text(for missing: MissingInfo) -> String
    public static let assumptions: [String]                           // rules 2–4 in plain English
}
```

## Test contract (exact expected values)

All engine tests use **today = Sat 2026-09-26**; "day N" = today+N; horizon = Thu 2026-11-26; events one-time unless stated.

| # | Setup | Expected |
|---|---|---|
| E1 | **Your worked example:** $1,000, floor $200, pay $800 day 4, rent $750 day 5, essentials $200 day 9; buy $700 today | baseline low $850 (day 9); with purchase $150 on day 9; `crossesFloor(by: $50)`; room today $650; earliest fit `none(.notEnoughRoom)` |
| E2 | E1 + second $800 pay on day 18 | earliest fit **day 19** (on day 18 the purchase goes out before the pay: $850 − $700 = $150) |
| E3 | $1,000; floor $0; rent $900 monthly day 1; pay $900 monthly day 15; buy $300 on Oct 24 | `goesNegative(by: $200)`, low on Nov 1 (a fixed 30-day window would wrongly say *fits*) |
| E4 | projection: $300; pay $800 and rent $750 both day 3 | day 3 low −$450, close $350 |
| E5 | projection: $100; pay $800 dated today (unmarked); rent $750 day 1 | day 0 $100; day 1 low −$650 |
| E5b | E5 with the pay marked "still coming today" | day 0 close $900; day 1 low $150 |
| E6 | $500; floor $0; rent $400 today (unmarked); buy $50 today | low $50 today; `fits(room: $50)` |
| E6b | E6 with the rent marked "already came out" | low $450 today; `fits(room: $450)` |
| E7 | balance confirmed Sep 25 (also: app left open past midnight) | `needsInfo([.balanceNotConfirmedToday(lastConfirmed: Sep 25)])` |
| E8 | no floor / no events / price $0 / price $10,000,000.01 / date Sep 25 / date day 31, and several at once | the matching `needsInfo` case(s), all listed |
| E9 | $0; floor $0; pay $500 on day 70 (beyond horizon); buy $10 today | `goesNegative(by: $10)` today |
| E10 | −$50; floor $0; pay $500 on day 70; buy $10 today | `goesNegative(by: $60)`; baseline warning `.negative(−$50 today)` |
| E11 | $1,000; floor $200; bill $400 day 3; buy $400 today | low $200 on day 3 → `fits(room: $0)` |
| E11b | same, buy $400.01 | `crossesFloor(by: $0.01)` |
| E12 | $500; floor $200; rent $400 day 3; buy $20 today | `crossesFloor(by: $120)`; baseline already $100 on Tue Sep 29 (below floor); earliest fit `none(.planAlreadyShort)` |
| E13 | $1,000; floor $0; rent $900 monthly day 1; pay $800 monthly day 15; buy $50 today | `goesNegative(by: $50)` on Nov 1 (buying today is not falsely "safer"); room today $0; earliest fit `none(.notEnoughRoom)` |
| P1 | **Sample plan:** $1,000, floor $200, pay $800 every 2 weeks from Sep 30, rent $750 monthly day 1, phone $45 day 8, streaming $12 day 16, groceries $100 weekly from Sep 28; buy $700 on Fri Oct 2 | `crossesFloor(by: $195)`, low $5 on Mon Oct 12; room today $505; earliest fit Thu Oct 15 |
| MON | property on P1, E3, E13: if date D fits, every later date in range fits | holds |
| S1 | monthly day 31, Jan–Apr 2027 | Jan 31, Feb 28, Mar 31, Apr 30 (2028: Feb 29) |
| S2 | twiceMonthly 15 & 31, Feb 2027 | Feb 15, Feb 28 |
| S3 | everyTwoWeeks from Fri Oct 2, range Sep 26–Nov 15 | Oct 2, Oct 16, Oct 30, Nov 13; never Sep 18 |
| D1 | LocalDate | Sep 26 2026 is Saturday; +37 days = Nov 2 2026; 2028-02-29 valid; 2027-02-29 nil; day-number round-trip 2000–2100 |
| M1 | Money formatting | 70000 → "$700"; 124999 → "$1,249.99"; −45000 → "-$450"; 5 → "$0.05" |
| X1 | Explainer on E1 | headline "Would cross your cash floor"; summary contains "$150" and "$50 below your $200 floor" |
| X2 | reasons on P1 | Paycheck +$800, Rent -$750, Laptop -$700, Groceries -$300 (3 times), Phone -$45; then "Next paycheck: +$800 on Wed Oct 14" |
| X3 | Explainer on E12 | headline "Your plan is already below your floor"; summary names $100 on Tue Sep 29 and "this purchase adds $20" |
| X4 | every string Explainer can produce (all cases above) | no "—", "–", "affordable", "safe to spend", "buy now" |

---

## Tasks

Each task: write failing tests → run → implement → run → commit. Engine: `swift test --package-path Packages/HeadroomCore`. App: `xcodebuild test -scheme Headroom -destination 'platform=iOS Simulator,name=<installed iPhone>'`.

### Milestone 1 — Engine (while Xcode downloads)

#### Task 1: Repo + package skeleton

- Create `~/Desktop/Headroom/` (git init; repo-local `user.name`/`user.email` for saihitesh-14), `.gitignore` (Xcode/SwiftPM), `LICENSE` (MIT), `README.md` stub, `docs/PLAN.md` (this plan), `docs/original-plan.md`, `Packages/HeadroomCore/Package.swift`.
- [ ] `swift build --package-path Packages/HeadroomCore` succeeds → commit `chore: project skeleton`

#### Task 2: Money + LocalDate

tests M1, D1.
- [ ] Tests → fail → implement (days-from-civil / civil-from-days) → pass → commit `feat(core): money and calendar-day types`

#### Task 3: Schedule

tests S1–S3; `once` inside/outside range; range with no occurrences.
- [ ] Tests → fail → implement (floor-based modulo, month clamping) → pass → commit `feat(core): recurring schedules`

#### Task 4: Projection

tests E4, E5, E5b; E6/E6b path values; purchase applied on its date before income; each day's `lines`.
- [ ] Tests → fail → implement rules 2–3 → pass → commit `feat(core): day-by-day projection`

#### Task 5: Analysis

tests E1–E3, E6/E6b verdicts, E7–E13, P1 (plan built inline), MON; `spendingRoom` for P1 = $505 through Nov 26.
- [ ] Tests → fail → implement rules 1, 4–8 (one projection; verdict = min baseline low from D through horizon − price) → pass → commit `feat(core): purchase analysis`

#### Task 6: Explainer

tests X1–X4; one string per `MissingInfo` and per `NoFitReason`.
- [ ] Tests → fail → implement → pass → commit `feat(core): plain-English explanations`

**Checkpoint:** all engine tests green once Xcode is installed.

### Milestone 2 — App you can use

#### Task 7: App scaffold, design system, CI

- `project.yml`: app `Headroom` (iOS 26.0, sources as `syncedFolder`), `HeadroomTests` (`bundle.unit-test`), `HeadroomUITests` (`bundle.ui-testing`), local package `HeadroomCore`; `xcodegen generate`.
- `Theme` (color tokens backed by asset-catalog light/dark sets, spacing scale, 20 pt continuous radius, `moneyFont(_:)` = SF Rounded + monospaced digits), `MoneyText` (formatted amount with numeric content transition), `StatusLabel` (icon + words + tint per verdict). `docs/DESIGN.md`.
- `HeadroomApp` + `RootView` with Liquid Glass tab bar: Ask / Plan / Settings.
- `.github/workflows/ci.yml` on `macos-26`: engine tests; `xcodebuild build … -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO`; no-network grep.
- [ ] App launches in the Simulator with three tabs in light and dark; CI steps pass locally → commit `chore: Xcode project, design system, CI`

#### Task 8: Plan storage + Plan tab

- `PlanStore` (`@Observable`; `CashPlan` JSON in Application Support, written with `[.atomic, .completeFileProtection]`; unreadable file → empty plan, no crash).
- `SamplePlan.make(today:)` (P1's plan, relative to today).
- `PlanView` (inset-grouped: balance, floor, income, bills, weekly essentials), `EventEditor` sheet (labels above inputs, errors below), `ConfirmBalanceSheet` ("Still $X?" + today's items with *already came out* / *still coming today* toggles).
- Tests: store round-trip; corrupt file; `SamplePlan.make(today: 2026-09-26)` reproduces P1.
- [ ] Tests pass; add/edit/delete an event and relaunch → data persists → commit `feat(app): plan inputs and storage`

#### Task 9: Ask flow + built-in parser

- `DateBridge`: `LocalDate(_ date: Date, timeZone: TimeZone = .current)` and `Date(_ day: LocalDate, timeZone:)`, always Gregorian.
- `QuestionParser`: `parse(_ text: String, today: Date, timeZone: TimeZone) -> ParsedQuestion { item: String?; price: Money?; date: LocalDate?; source: ParseSource }` (`enum ParseSource { case builtIn, onDeviceAI }`) from `prices(in:) -> [Money]` (regex, integer math, cap) and `date(in:today:timeZone:) -> LocalDate?` (`NSDataDetector`). Price is set only when the text has exactly one amount. No date phrase → today.
- `AskView` (spending room as the one large number, question field with label above, "Check", "Use the form instead"), `EmptyStateView` (first launch: "Set up my plan" / "Try the sample plan"), stale-balance prompt ("Is your balance still $1,000?" Yes / Update), `ConfirmCard` (editable item/price/date, "Check").
- Tests: "$1,249.99" → 124999; "$700." → 70000; "1249" → nil; two amounts → nil; "$99999999999999999" → nil; no date → today; "tomorrow" → today+1 and "next Friday" → a Friday 1–13 days out (computed from the real current date, never hardcoded); DateBridge: 23:30 local stays on the local day; Gregorian even if the device uses another calendar.
- [ ] Tests → implement → pass → commit `feat(app): ask and confirm`

#### Task 10: Result screen + design check-in

- `ResultView`: `StatusLabel` + summary, `CashChart`, key figures as a plain list (earliest date that fits, spending room, checked through), "Try another date or price" (date picker today…today+30, price field; engine re-runs live with numeric transitions), "What moves your balance" (≤ 5 rows + next income), "How this is calculated" disclosure (assumptions).
- `CashChart` (Swift Charts): baseline in secondary gray, with-purchase in accent, dashed floor rule, purchase-date marker, lowest point labeled; VoiceOver summary.
- UI smoke test (local only, not CI): launch with `-uiTestSamplePlan` (sample plan, confirmed today, lock off) → type "Can I buy a $700 laptop next Friday?" → Check → a verdict label appears.
- [ ] Implement → UI test passes → capture Ask / Result / Plan / Empty in light and dark → **show you for sign-off** → commit `feat(app): result screen and chart`

**Checkpoint:** usable, good-looking app end to end in the Simulator.

### Milestone 3 — Privacy + AI

#### Task 11: Privacy features

- `AppLock`, opt-in: new `LAContext` per attempt, `.deviceOwnerAuthentication` (passcode fallback); lock only on `.background` (the Face ID prompt itself makes the app `.inactive`); if `canEvaluatePolicy` fails, the toggle is disabled with the reason; `NSFaceIDUsageDescription`.
- Privacy cover when not `.active` (app mark on neutral, no amounts); "Delete all data" with confirmation; Settings privacy statement: "This app makes no network requests. Your plan stays on this device."
- [ ] Implement → verify in Simulator (Features ▸ Face ID ▸ Enrolled) → commit `feat(app): app lock and privacy cover`

#### Task 12: On-device AI reading

- `OnDeviceInterpreter`: `@Generable` struct with **exact phrases only**: `item: String`, `dateText: String?` (no price field). New `LanguageModelSession` per request. The date phrase must appear in the sentence and parse via `QuestionParser.date`; otherwise the built-in date result is used. **Price always from `QuestionParser.prices`.** Plain `catch` → built-in parser + visible note.
- Settings toggle "Read questions with on-device AI", enabled only when `SystemLanguageModel.default.availability == .available`; otherwise shows why (not eligible / Apple Intelligence off / model downloading / other).
- Confirm card shows the source ("Read by on-device AI" / "Read by built-in parser"); "Reading your question…" placeholder while it runs.
- Tests (stubbed interpreter): price equals the typed digits whatever the model returns; date phrase not in the sentence is ignored; thrown error → built-in result with note.
- [ ] Tests → implement → manual check in Simulator with 5 phrasings → commit `feat(app): on-device AI question reading`

### Milestone 4 — Ship

#### Task 13: README, icon, review, publish

- README as a small landing page (taste skill's landing rules): name + one-line value prop (≤ 20 words) + hero image (Ask and Result, light and dark), then How it works (diagram), Privacy, The math (engine rules), Run & test, Roadmap, "Estimates, not financial advice". No em dashes, no filler verbs, one badge (CI).
- App icon: one accent glyph on neutral.
- Design pre-flight (from `docs/DESIGN.md`): zero em/en dashes in UI strings, one accent, shape lock, both modes checked, XL Dynamic Type holds, VoiceOver labels, contrast, Reduce Motion, empty/error states present.
- Fresh reviewer pass on the whole project; fix findings.
- **With your OK:** `gh auth switch --user saihitesh-14` → `gh repo create saihitesh-14/headroom --public --source . --push` → `gh auth switch --user Saihitesh2006`; confirm CI green; add badge.
- [ ] Commit `docs: README and screenshots` → push → CI green

---

## Verification (end to end)

1. `swift test --package-path Packages/HeadroomCore`: all engine tests pass (E1 worked example, E3/E13 horizon, P1 sample plan, X4 copy rules).
2. `xcodebuild test` on an iPhone Simulator: parser, date bridge, storage, sample plan, interpreter, and UI smoke tests pass.
3. Manual run in Simulator, light and dark: first launch shows the empty state → Try the sample plan → Ask "Can I buy a $700 laptop next Friday?" → confirm → verdict, chart, earliest date that fits; change date/price → numbers animate to new values; mark a today item → result changes; background the app → cover shows; turn on lock → Face ID prompt on return; XL text size still readable.
4. No-network grep (CI step) → no matches.
5. GitHub: `saihitesh-14/headroom` public, commits show saihitesh-14 as author, README renders with screenshots, CI badge green.
