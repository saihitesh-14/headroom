# Privacy First Financial Decision Assistant: revised prototype plan

## 1. Decision and assumptions

Build a **US, iPhone, single-user personal prototype** for a solo developer new to Swift. The first target case is a student with a regular paycheck and rent, paying for purchases from checking/debit. Its first useful experience is: “If I buy this for $X on date Y, what happens to my cash before my upcoming bills?” The first prototype includes a narrow AI question interface with **both local and optional cloud modes**, but every financial result comes from deterministic code.

This is a planning document, not a claim that any purchase is financially safe. The user confirms and owns every decision. Public distribution, bank connections, investment advice, payments, and automated transfers are outside this prototype.

### Why the original plan needs narrowing

The original vision and the separation between AI and financial math are strong. Its stated MVP combines onboarding, full transaction management, CSV normalization, goals, credit cards, local AI, secure storage, and simulations. Those are several releases of work. Manual data is also a major practical constraint: a precise algorithm cannot compensate for an old checking balance or a missing bill.

For example, the sample student has $1,600 income and $1,250 in listed monthly expenses, leaving an apparent $350. Without a dated checking balance, paycheck and bill dates, card payment obligations, and goal contributions, the app cannot responsibly say whether a $700 laptop fits the plan or delays a goal by two weeks. Bill timing is central to real cash flow, as [CFPB guidance](https://www.consumerfinance.gov/data-research/research-reports/consumer-insights-paying-bills/) emphasizes.

## 2. Product promise

**Question:** “Can I buy this now, or is another date less disruptive to the plan I entered?”

**Answer:** A dated, inspectable cash-flow comparison. Show the lowest projected checking balance, when it occurs, which bills and paychecks drive it, and whether the purchase crosses the user’s chosen cash floor. If information is inadequate, request the missing inputs instead of guessing.

Use these result states:

1. **Fits your selected cash floor** — all modeled dates stay at or above the floor.
2. **Would cross your cash floor** — known obligations remain payable, but the floor is breached.
3. **Known obligations exceed projected cash** — the scenario has a negative projected checking balance.
4. **Needs more information** — a required input is missing or stale.

Avoid “affordable,” “safe to spend,” “best date,” and an app action called “Buy now.” Use **“Estimated spending room through [date]”** and show the calculation date, horizon, and excluded or unconfirmed items.

## 3. First prototype scope

### Include

- One checking account with a **balance and the time it was confirmed**. Prefill the last balance and ask the user to reconfirm or update it for each new analysis.
- A regular **net** paycheck: amount, next date, cadence, and an editable list of exceptional pay dates. If income is irregular, accept only individually dated expected inflows and mark them uncertain.
- Dated rent, utilities, debt minimums, subscriptions, and a weekly estimate for essential variable spending such as groceries and transport.
- A user-chosen **minimum checking cash floor**. A separate emergency savings balance is informational and cannot silently fund purchases.
- One optional savings goal and its planned contribution date and amount. Show whether a purchase pressures the next contribution; calculate a precise goal delay only when a contribution rule is explicitly modeled.
- A purchase entry form with item, price, proposed date, and **checking/debit funding only** for the first engine.
- A 30-day baseline and purchase scenario, an explanation panel, a “What if I change the date or price?” control, and a clear prompt to refresh stale inputs.
- AI-assisted parsing of a narrow question such as “Can I buy a $700 laptop next Friday?” into item, price, and date. The user reviews the parsed values before analysis. Support a local model plus **OpenAI as the first optional cloud provider** behind a common interface. In cloud mode, the model may receive the full profile and history currently stored in the app, as requested by the user. The result and its numeric explanation are generated from engine output.
- Local storage, device authentication, offline use, and tests of the engine’s important edge cases.

### Add after the first decision loop works

Manual transaction history; CSV import and duplicate detection; categorization with user corrections; several goals; richer irregular-income scenarios; credit-card purchase modeling; and broader conversational questions. Credit cards need billing-cycle, statement, payment, and interest assumptions. Treating a card limit as cash would be misleading; [CFPB explains why grace periods depend on payment behavior](https://www.consumerfinance.gov/ask-cfpb/what-is-a-grace-period-for-a-credit-card-en-47/).

### Defer until a separate product phase

Bank aggregation, cloud sync, reward optimization, receipt scanning, price monitoring, investing, and consumer-facing public launch. Do not create empty data models or navigation tabs for these future features now.

## 4. Core calculation contract

Use integer cents or a fixed decimal money type; never binary floating point for money. Model **dated events**, not only monthly averages. Give every event an account, signed amount, date, recurrence rule if any, and source or confidence flag.

For each date in the horizon:

`projected checking = confirmed opening checking balance + modeled net income - modeled bills - essential spending allowance - planned transfers out - proposed purchase`

Run the same timeline with and without the purchase. The engine returns both daily paths, each minimum balance and date, the difference caused by the purchase, the first tested purchase date that meets the cash floor, and structured explanation factors. If the baseline already falls below the floor or below zero, say that the issue precedes the purchase. “Estimated spending room for a purchase today through day 30” is `max(0, minimum baseline projected checking balance minus the selected floor)`, subject to the stated inputs. It is an estimate under the entered plan, not a guarantee of funds.

Rules that must be explicit:

- A balance snapshot has an as-of time; transactions already reflected in it must not be subtracted again.
- A transfer between checking and savings is a movement between accounts, not an expense when displaying total wealth. The purchase scenario names its funding account.
- Due dates, month-end recurrences, time zones, same-day pay/bill order, refunds, and missed paychecks require deterministic handling. Where exact intraday order is unknown, use and disclose a conservative assumption.
- Expected future income is an assumption, not confirmed cash. Exclude uncertain income from a conservative scenario or present both scenarios.
- If the user has not entered a required bill, confirmed the balance for this analysis, or explicitly selected a cash floor (which can be $0), do not produce a confident result.
- A “first date that fits” applies only within the displayed horizon and known events; show “none found” when appropriate.
- Need versus want is a user context field, not an objective fact inferred from a merchant or product name. It may influence wording, but never changes the arithmetic.

## 5. AI contract for the first prototype

Implement an `AIProvider` interface with two first adapters: Apple **Foundation Models** for an eligible iPhone and **OpenAI** for optional cloud use. Because the user is flexible about where local inference runs, use an authenticated **Mac-local model adapter** if the test iPhone cannot run Apple’s model. Label Mac-local separately: the phone sends data to that Mac, so AI is unavailable away from it, although the calculator still works on the phone. Add Google Gemini and Anthropic Claude through the same interface after the first end-to-end flow works. Accept only supported intents: new purchase, change price/date, estimated spending room, and explain result. The model extracts or selects structured fields; the user confirms any item, amount, or date it interpreted. The financial engine then computes a typed result, and a deterministic formatter renders the numeric facts and reasons. A model may paraphrase those factors, but the app must show the engine’s canonical numbers and fall back to its deterministic explanation if the generated prose is unavailable or inconsistent. For questions outside these intents, explain the prototype’s current capabilities instead of inventing an answer.

The app checks local model availability at runtime. If Apple Intelligence is disabled, unsupported, still downloading, or unavailable for another reason, present the structured purchase form and let the user explicitly select cloud mode if configured. Do **not** silently switch from local to cloud. The financial feature works offline even when neither AI mode is available. Apple [requires availability handling](https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel) and [warns that its on-device model is unsuitable for basic math](https://developer.apple.com/documentation/FoundationModels/generating-content-and-performing-tasks-with-foundation-models). Local model use depends on supported hardware, software, region, and settings.

In iPhone-local mode, prompts and financial records stay on the phone. In Mac-local mode, selected data travels over a protected local connection to the user’s Mac and stays within the user’s devices. In cloud mode, show **“OpenAI cloud: your stored financial profile and history may be sent for this answer”** and make the exact request payload inspectable before sending. This mode may send the full stored profile, transaction history when that feature is added, and the engine’s current analysis. It is selected deliberately and never used as an automatic fallback from local mode. A growing history may exceed a model’s context limit; in that case, disclose the limitation and ask for a date range or another explicit strategy rather than silently claim the model saw everything. Keep provider calls stateless unless a concrete feature requires otherwise. Cloud mode is an explicit privacy trade-off: OpenAI receives the request and may retain or process it under its current API terms. [Official OpenAI documentation](https://developers.openai.com/api/docs/guides/your-data) distinguishes model-training use, abuse monitoring, and response storage; turning off response storage alone does not imply zero retention. For the first OpenAI implementation, use a stateless request with response storage disabled where the selected endpoint supports it, and do not use a persistent conversation resource by default.

For this **personal-only prototype**, a key entered by its sole user can be kept in the iOS Keychain for direct HTTPS calls; never hardcode keys in the app, repository, screenshots, or logs. This is a prototype convenience, not a distributable key-management design. Before sharing the app or using a developer-owned key for other users, put provider credentials behind a small authenticated backend or another provider-supported credential flow. [OpenAI’s API reference](https://developers.openai.com/api/reference/overview) says API keys should not be exposed in client-side apps, and [Google’s Gemini key guidance](https://ai.google.dev/gemini-api/docs/api-key) recommends a backend for production clients. Keychain protects a stored secret on the device; it cannot make a public client a trusted server.

## 6. Suggested iOS architecture

Build a small SwiftUI app with four areas: **Home**, **Ask about a purchase**, **Plan inputs**, and **Privacy/settings**. Use plain Swift domain types and pure functions for simulation; keep them separate from SwiftUI and persistence. Start with these domain concepts: `BalanceSnapshot`, `CashEvent`, `Recurrence`, `CashFloor`, `GoalContribution`, `PurchaseScenario`, and `AnalysisResult`. Add a repository protocol for local data and an AI parser protocol with a manual fallback. Do not start with the original plan’s full 16-model schema.

The flow is:

`SwiftUI input → validated scenario → pure cash-flow engine → typed analysis → deterministic explanation → SwiftUI result`

`Selected AI parser (local or cloud) → user-confirmed scenario fields` feeds into that same flow. A cloud request also passes through a sharing-disclosure and request-preview step. SwiftData can be considered for the local store, but select and verify its file protection and migration behavior rather than assuming the framework alone is an encryption design. [Apple documents iOS Data Protection levels](https://developer.apple.com/documentation/uikit/encrypting-your-app-s-files), including a default that may remain accessible after first unlock.

## 7. Privacy and security decisions to make early

- No sign-in, bank connection, ad SDK, or remote analytics in this prototype. The optional OpenAI path and any Mac-local connection are the only planned app-controlled network paths, and the UI labels them plainly. Device backups need their own explicit policy.
- Use an appropriate iOS **Data Protection** class for the financial database and its auxiliary files; test reads while locked. Protect credentials or encryption keys in **Keychain** if the chosen store needs them. Use `LocalAuthentication` for Face ID/Touch ID with device passcode fallback. [Apple’s authentication documentation](https://developer.apple.com/documentation/localauthentication) explains that app access control and biometrics are separate from storage protection.
- Clear sensitive content in app-switcher snapshots and avoid amounts in notifications, logs, crash metadata, and copied text by default.
- State exactly whether data enters iOS device/iCloud backups. Apple notes that Application Support content is normally backed up and provides a backup-exclusion mechanism; if the prototype excludes user records, explain that device loss means data loss until a secure recovery option exists. [Apple file-system guidance](https://developer.apple.com/documentation/foundation/using-the-file-system-effectively).
- Provide local delete/reset. If CSV is added later, define imported-file disposal and handle raw files as sensitive data.
- Do a separate legal, security, and App Store review before any public release. A personal prototype is a different scope from a public financial product; a disclaimer alone does not settle regulatory requirements. [FTC Safeguards Rule overview](https://www.ftc.gov/business-guidance/resources/ftc-safeguards-rule-what-your-business-needs-know), [Apple App Review](https://developer.apple.com/app-store/review/).

## 8. Build order for a solo Swift beginner

| Stage | Deliverable | Exit check |
|---|---|---|
| 1. Learn the tools | Tiny SwiftUI app on your actual iPhone; basic forms, navigation, and local persistence | Can enter, edit, and reopen fictional data offline |
| 2. Build money core | Pure Swift money/date types and 30-day event simulation | Known scenarios produce exact expected balances; no UI is needed to inspect the logic |
| 3. Finish first decision loop | Short setup, purchase form, cash timeline, what-if, explanation | A change in rent or pay date visibly changes the correct projected low point |
| 4. Add first AI feature | iPhone-local model if supported, otherwise an authenticated Mac-local adapter; OpenAI cloud mode behind `AIProvider`; field confirmation, full-payload preview, Keychain key storage | Parser errors cannot silently change the result; cloud is never selected without user action; manual form works when AI is unavailable |
| 5. Protect and validate | File protection, app lock, freshness checks, test scenarios, real-device check | Offline and lock behavior are verified; missing data never yields a confident claim |

This is still meaningful work. A focused **cash-flow vertical slice before AI** might take an experienced iOS engineer roughly **4–8 weeks**. Local and OpenAI modes, security checks, and real-device testing add work beyond that. For one person new to Swift, especially part time, plan for **several months**; the exact calendar depends on prior programming experience, hardware, and hours available. Use the exit checks instead of a fixed release date.

## 9. Acceptance tests

Use fictional profiles and exact expected outputs. Cover pay before/after rent; rent and pay on the same day; month-end recurrence; zero and negative starting cash; stale opening balance; unknown or missed income; a purchase that crosses only the user cash floor; a purchase that makes a known bill unpayable; a purchase date beyond the 30-day horizon; and a goal transfer that should be skipped or postponed under an explicit rule. Test that a question parsed as `$700` cannot become `$70` without user confirmation. Verify no financial data appears in logs, the app works in airplane mode for core calculations and local AI when available, and protected files cannot be opened in the tested lock state.

One exact engine fixture: opening checking cash is $1,000; the cash floor is $200; an $800 paycheck lands on day 4; $750 rent is due on day 5; and $200 in essential spending is scheduled on day 9. With no other events, baseline cash reaches a low of $850. A $700 cash purchase today reaches a low of $150 on day 9, so the correct state is **“Would cross your cash floor” by $50**, while the listed obligations remain payable.

The first prototype is complete when one person can enter a real but manually maintained plan, ask about a purchase in natural language through a chosen available AI mode, confirm the extracted values, inspect two dated cash paths, understand why the conclusion changed, and update stale inputs. Its answer remains useful through the manual form when AI is unavailable. An OpenAI request must show the user exactly which profile and history fields it sends.

## 10. Remaining implementation choices

1. Check the test iPhone model and iOS version before choosing the final local adapter. The preferred path is on-iPhone Foundation Models; Mac-local is the fallback if that hardware is ineligible.
2. Set the device-backup policy before entering real financial data: excluding app records reduces cloud exposure but means device loss can mean data loss until a secure recovery option exists; retaining backups aids recovery and must be disclosed as part of the privacy behavior.
