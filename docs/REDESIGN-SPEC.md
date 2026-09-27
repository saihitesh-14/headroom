# Headroom UI spec, final build version: "Datum"

**Base:** Datum had the highest total (121). This spec adds the runner-up ideas the judges named from Double Rule (120) and Forecast Low (101), and fixes every fatal flaw they raised (section 1.4).

**Scope:** native SwiftUI on iOS 26. The engine math does not change. The Liquid Glass tab bar and toolbars stay. Charts use Swift Charts.

**Example numbers:** every figure in the wireframes is real engine output for `SamplePlan.make(today:)` with today = Sun Sep 27 2026, the same data as the current screenshots. I checked each one by hand: room $505, baseline low $705 on Tue Oct 13, a $700 laptop on Fri Oct 2 gives a low of $5 on Tue Oct 13, below the floor Tue Oct 6 to Thu Oct 15, earliest fit Fri Oct 16. Engine tests use the existing `samplePlanP1()` fixture with today = Sat Sep 26 2026. The expected literals for that fixture are in section 11.

**Ground rules for the whole document:**

- Every number on screen comes from HeadroomCore. Views only format and place values. Animation interpolates positions between two engine states and never shows a number that did not come from the engine.
- UI copy is sentence case with zero U+2013 or U+2014 dashes, no middle dots, no ALL-CAPS labels, no arrows appended to buttons, and no filler verbs.
- ASCII wireframes use "-" for minus. The app shows U+2212 "−" (section 3.6).
- Swift token names stay the same (`Theme.canvas`, `Theme.textPrimary`, and so on) to keep the diff small. Only their values change. Design names (Paper, Ink, and the rest) are mapped in section 2.1.

---

## 1. Concept and signature element

### 1.1 Concept

Headroom is drawn as a surveyor's section drawing of the weeks ahead. The balance path is the profile. The cash floor is the datum, a dashed line taken from the app icon. The instrument measures one thing: **clearance**, the vertical distance between the lowest projected balance and the floor. That distance is the idea the product is named after. It is dimensioned the way a draftsman dimensions a drawing, with a vertical line and a 45 degree slash tick at each end. It is drawn at true scale inside the chart, and the same mark appears as a small glyph beside the big number. So a student can see why the number is what it is instead of taking a bare figure on trust.

Everything around the mark stays quiet: ink on pale paper, native iOS chrome, no cards. The one custom typeface is Overpass, the libre cut of Highway Gothic, the lettering on US low-clearance signs. It is used only for readings, amounts, instrument labels, the verdict line, and the wordmark. SF Pro sets everything the iPhone says. The tone is a calibrated instrument, not an alarm: it measures, labels, and lets you try another date.

### 1.2 The signature: the clearance mark

**Form**

- A vertical dimension line, 1.5 pt, in the status tint.
- A 9 pt slash tick at 45 degrees at each end (a Shape, never an arrowhead).
- It stands on the datum, a 1.5 pt dashed Ink rule with dash [6, 3] and round caps, the rhythm from the app icon.

**Meaning (strict).** The mark only measures from the lowest projected point to the floor. In the below-$0 case it measures to $0. It never measures anything else. Plan does not get one, because balance minus floor is not clearance.

**Variants.** They differ in shape as well as color, so color is never the only cue.

| Variant | Shape | Tint | Used when |
|---|---|---|---|
| Above | Rises up from the datum to the low | Evergreen | Low is at or above the floor |
| Below | Hangs down from the datum to the low | Amber | Low is below the floor and at or above $0 |
| Below zero | Hangs down from the solid $0 rule to the low | Brick | Low is below $0 |

**Where it appears (and nowhere else)**

1. **Ask.** At true scale in the balance gauge at the baseline low, plus `ClearanceGlyph` beside the big "$505".
2. **Result.** At true scale in the chart at the purchase low, plus `ClearanceGlyph` beside the reading "$195". It plays the app's one orchestrated motion (section 7).
3. **Verdict glyphs.** These echo it: a step above, through, or below the datum.
4. **First-launch drawing.** Shown static, with no numbers.
5. **Lock cover.** Shows the datum alone.

**Symbol language.** There are four marks, each with one meaning everywhere:

| Mark | Means |
|---|---|
| Ring (11 pt circle, Paper fill, 2 pt status stroke) | The lowest point |
| Dashed Ink rule | Your floor |
| Vertical line with slash ticks | Clearance, measured to the floor |
| Solid 1 pt rule | $0 |

### 1.3 What the mark replaces

| Before | After |
|---|---|
| Stock "big number, small gray label" hero | The number is keyed by the clearance glyph to a true-scale gap in a drawing |
| Green With line crossing the floor under a warning verdict | Ink line in every verdict. Only status marks use status color |
| Four identical cards on Result | No cards. Verdict and reading set in type, open chart, open ledger, glass control bar |
| Falling-market stock symbol on first launch | The instrument drawn with no numbers |

### 1.4 Fatal flaws the judges raised, and how this spec resolves them

| Flaw | Resolution |
|---|---|
| Build cost: 8 custom SF Symbol sets, each with 3 weight masters | **Zero symbol sets.** `ClearanceGlyph`, `VerdictGlyph`, `DatumRule`, `DimensionTick`, `LowRing` and `SectionDrawing` are SwiftUI Shapes, sized from the text they sit beside (section 4.2). The Ask tab uses the SF Symbol `chart.line.flattrend.xyaxis`. The custom tab symbol is deferred (section 12). |
| The true-scale mark shrinks to about 12 to 17 pt on a fixed 61-day linear chart, exactly when the answer is bad | **Decision window**, taken from Forecast Low's windowed Y domain. The chart shows today through the lowest point plus 7 days, at least 21 days wide. Y is fitted to that window and always includes the floor and $0. By construction the window contains every low that matters, and the caption says so: "Checked through Fri Nov 27. The lowest point is in view." Sample result: the mark is about 23 pt at 260 pt plot height (about 12 pt before). Ask gauge: about 39 pt at 150 pt (about 29 pt before). There is no picker and no scrolling, so the Y scale never changes except in answer to a date or price change. |
| "$195" as the Result hero can be misread as a balance | The figure always carries its unit words on the same baseline ("$195 below your $200 floor"). The plain sentence under it names the actual balance ("...takes checking down to $5 on Tue Oct 13"), grafted from Double Rule. The chart's ring label shows the balance ("$5, Oct 13"). |
| Overpass next to SF Pro is two grotesques, so it reads as a font mistake if the roles blur | Strict split, enforced in CI (section 3.3). Overpass never appears inside an SF sentence. It sets readings, amount columns, instrument labels, the verdict line, and the wordmark, at sizes and weights clearly apart from the SF text beside them. |
| Custom large-title fonts under Liquid Glass bars are flaky | Nav-title restyling is a **gated** last step with written acceptance tests. If any test fails, titles stay system SF Pro. The identity does not depend on them (section 10, step 14). |
| Wrong fallback font names ("Overpass-SemiBold") | Verified in the actual file: the PostScript name is `Overpass-Regular`, and the named instances are `OverpassRoman-Medium`, `OverpassRoman-SemiBold` and `OverpassRoman-Bold`. This spec never uses instance names. It builds weights through the `wght` variation axis (section 3.5). |
| Hatch fill inside Swift Charts marks is unverified | Gated spike (section 10, step 14). The fallback is a flat 16% status tint. The non-color cues (verdict glyph shape, mark direction, ring, and the words "Below your floor Tue Oct 6 to Thu Oct 15") exist either way. |
| Draggable glass cursor overlay competes with scroll and back-swipe | Not built. Swift Charts selection behind a long press (section 6.4) reads any day. The date changes through the docked what-if bar and the one-tap "Try Fri Oct 16". |
| Scope too big for one pass | Phased checklist (section 10). The engine goes first and is fully tested, then tokens and type, then one screen per step. Every step leaves the app shippable. |

### 1.5 Grafts

| Idea | From | Where |
|---|---|---|
| Plain sentence under the verdict that names the real low | Double Rule | Result, `Explainer.purchaseSentence` |
| Unit words stated with the gap figure, so it cannot read as a balance | Double Rule | Result and Ask readings |
| "Coming up" running-balance register down to the lowest day | Double Rule | Ask, under the question |
| Verdict glyphs as SwiftUI Shapes instead of symbol sets | Double Rule | `VerdictGlyph` |
| U+00A0 inside dates in new engine sentences | Double Rule | New Explainer functions |
| VoiceOver says "plus" and "minus" explicitly | Double Rule | `Money.spokenText` |
| Selection scrubbing with a callout of that day's engine lines, instead of a drag cursor | Double Rule | Result chart |
| Double rule only above the ledger total (accounting convention for a sum) | Datum and Double Rule | Result ledger |
| Windowed Y domain that always includes floor and $0 | Forecast Low | Result chart and Ask gauge |
| "Peel" motion: the With line leaves the Without line by exactly the price | Forecast Low | First half of the one orchestrated moment |
| Below-floor date range stated in words under the chart | Forecast Low | Result |

---

## 2. Tokens

### 2.1 Color

| Design name | Swift token (name unchanged) | Asset | Light | Dark | Role |
|---|---|---|---|---|---|
| Paper | `Theme.canvas` | Canvas | `#F3F5F6` | `#000000` | Every screen background. Dark is true black, matching the iOS base and OLED. This replaces the tinted `#0E0F11`. |
| Plate | `Theme.surface` | Surface | `#FFFFFF` | `#1C1C1E` | The only custom surface: the question field and the chart selection callout. Equal to the system inset row color, so it matches Plan and Settings rows. |
| Ink | `Theme.textPrimary` | TextPrimary | `#101417` | `#F2F4F5` | Primary text, every figure, the balance path, the datum, the double rule |
| Graphite | `Theme.textSecondary` | TextSecondary | `#525B64` | `#A1A9B1` | Secondary text, instrument labels, every List/Form header and footer (replaces system secondaryLabel), the question placeholder, the purchase rule |
| Rule | `Theme.chartBaseline` | ChartBaseline | `#78818A` | `#6F7880` | Without-purchase line, ruler ticks, staff ticks. **Graphics only, never text.** |
| Evergreen | `Theme.accent` | AccentColor | `#1F6E54` | `#4CB891` | The one accent: things you can tap, and the stays-above state (clearance mark, verdict glyph, ring). Never static amounts, never income. |
| Amber | `Theme.warning` | Warning | `#8F5D00` | `#E5A843` | Status only: dips below the floor, and the stale-balance note |
| Brick | `Theme.danger` | Danger | `#A33E2B` | `#F07F68` | Status only: below $0, and field errors (always with a glyph) |
| On Accent | `Theme.onAccent` (new) | OnAccent (new) | `#FFFFFF` | `#000000` | Label color on every prominent Evergreen button |

**Increase Contrast.** Add "High Contrast" appearances to these colorsets:

| Colorset | Light (HC) | Dark (HC) |
|---|---|---|
| TextSecondary | `#3E464E` | `#C5CBD1` |
| ChartBaseline | `#5B636B` | `#8E969E` |
| AccentColor | `#185A45` | `#6CCBA6` |
| Warning | `#7A4F00` | unchanged |

When `colorSchemeContrast == .increased`, the question field and the what-if capsules also get a 1 pt `Theme.textSecondary` stroke.

### 2.2 Contrast, text on background (WCAG 2.x, computed from the hex values above)

Light mode. The Sheet column is the system sheet background `#F2F2F7`. The Glass column is the light glass pill as measured in the current screenshots, `#F8F8FA`.

| Text | on Paper `#F3F5F6` | on Plate `#FFFFFF` | on Sheet `#F2F2F7` | on Glass `#F8F8FA` |
|---|---|---|---|---|
| Ink `#101417` | 16.93 | 18.51 | 16.59 | 17.45 |
| Graphite `#525B64` | 6.32 | 6.91 | 6.19 | 6.51 |
| Evergreen `#1F6E54` | 5.62 | 6.15 | 5.51 | 5.79 |
| Amber `#8F5D00` | 5.14 | 5.62 | 5.04 | 5.30 |
| Brick `#A33E2B` | 5.85 | 6.40 | 5.74 | 6.03 |
| On Accent `#FFFFFF` on Evergreen | 6.15 | | | |

Dark mode. The Sheet row column is `#2C2C2E`. The Glass column is `#2D3132`, as measured.

| Text | on Paper `#000000` | on Plate `#1C1C1E` | on Sheet row `#2C2C2E` | on Glass `#2D3132` |
|---|---|---|---|---|
| Ink `#F2F4F5` | 19.03 | 15.42 | 12.63 | 11.92 |
| Graphite `#A1A9B1` | 8.83 | 7.15 | 5.86 | 5.53 |
| Evergreen `#4CB891` | 8.57 | 6.95 | 5.69 | 5.37 |
| Amber `#E5A843` | 10.01 | 8.11 | 6.65 | 6.27 |
| Brick `#F07F68` | 7.94 | 6.43 | 5.27 | 4.97 |
| On Accent `#000000` on Evergreen | 8.57 | | | |

All pairs pass AA (4.5:1) at every size used.

Old failures for reference:

- System secondaryLabel `#86868B` on `#F4F5F7`: 3.32
- White on dark `#34A17B`: 3.22
- Old ChartBaseline `#9AA1A9` on canvas: 2.39

High Contrast variants:

| Variant | Light | Dark |
|---|---|---|
| Graphite | `#3E464E`: 8.76 on Paper, 9.59 on Plate | `#C5CBD1`: 12.84 on black, 10.40 on Plate |
| Evergreen | `#185A45`: 7.42 on Paper; white label 8.12 | `#6CCBA6`: 10.73 on black; black label 10.73 |
| Amber | `#7A4F00`: 6.52 on Paper | unchanged |

### 2.3 Contrast, non-text (WCAG 1.4.11, 3:1 minimum)

| Mark | Light | Dark |
|---|---|---|
| Datum, With line, double rule (Ink on Paper) | 16.93 | 19.03 |
| Without line, ruler ticks (Rule on Paper) | 3.62 | 4.67 |
| Ink vs Rule (the two lines against each other) | 4.68 | 4.07 |
| Purchase rule (Graphite on Paper) | 6.32 | 8.83 |
| Clearance mark and ring, stays above (Evergreen on Paper) | 5.62 | 8.57 |
| Clearance mark and ring, dips (Amber on Paper) | 5.14 | 10.01 |
| Clearance mark and ring, below $0 (Brick on Paper) | 5.85 | 7.94 |
| Amber mark on its own 16% below-floor fill (`#E3DDCF` / `#251B0B`) | 4.15 | 8.07 |
| Brick mark on its 16% fill (`#E6D8D6` / `#261411`) | 4.62 | 6.67 |
| Evergreen mark on its 16% fill (`#D1DFDC` / `#0C1D17`) | 4.48 | 7.12 |
| Ink line crossing any 16% fill | 13.36 or more | 15.35 or more |
| Graphite label on any 16% fill (labels also get a Paper pad) | 4.99 or more | 7.12 or more |

Verdict glyphs render in `.monochrome` status tint. They are never `.hierarchical`, which was measured at 1.38:1 in light mode.

### 2.4 Color rules

- One accent. Evergreen means "you can tap this" or "stays above your floor". Income amounts are Ink with a "+" sign.
- Status color is always paired with a glyph shape and words. In the chart it is also paired with the mark's direction, the ring, and the below-floor text line.
- No gradients, no shadows, no tinted cards.
- Status fills are only ever the 16% below-floor area in the chart.

---

## 3. Type

### 3.1 Overpass (the readings)

Facts below were verified in the downloaded file on Sep 27 2026.

- **Repo path:** `ofl/overpass/Overpass[wght].ttf`
- **Raw URL:** `https://raw.githubusercontent.com/google/fonts/main/ofl/overpass/Overpass%5Bwght%5D.ttf`
- **Size and hash:** 318,700 bytes. SHA-256 `970717df17a7f9911dee45f60695d05bfa9d745fa0a11fc5c348371fa21f0073`.
- **License:** SIL Open Font License 1.1.
  - Repo path `ofl/overpass/OFL.txt`, raw URL `https://raw.githubusercontent.com/google/fonts/main/ofl/overpass/OFL.txt`.
  - SHA-256 `86e5ff25c701ec446d20b1a85b02ee6d36de8503a7288a4c948f5459809af1f0`.
  - Copyright line: "Copyright 2021 The Overpass Project Authors". There is **no Reserved Font Name**.
- **Names:**
  - Family `Overpass`, PostScript `Overpass-Regular`, variation PostScript prefix `OverpassRoman`.
  - Axis `wght` from 100 to 900, default 400.
  - Named instances: `OverpassRoman-Thin` through `OverpassRoman-Black`.
- **Features:** `tnum`, `pnum`, `case`, `frac`, `zero`, `ss01`, `calt`, `liga` and others.
  - `tnum` maps `zero` through `nine` to `.tf` forms, each 1232 units wide (em 2000).
  - Default figures are proportional (`one` is 746, `zero` is 1284). **Tabular figures must be requested explicitly on every Overpass run.**
- **Glyphs:**
  - U+2212 minus is present and is 1290 wide, identical to `plus` (1290). Hyphen-minus is 798.
  - U+00A0 and U+2009 are present.
- **Metrics:** cap height 1400/2000 (0.70 em), used to size glyphs.
- **Not shipped:** `Overpass-Italic[wght].ttf`.
- **Bundle:**
  - Copy to `App/Resources/Fonts/Overpass-Variable.ttf`, renamed from the bracketed name. The contents stay byte-identical to the repo file.
  - Copy the license to `App/Resources/Fonts/Overpass-OFL.txt`.
  - Credit in Settings > Acknowledgments.
  - I checked both files against the CI "No network code" grep. Neither matches, so the check stays green.
- **Why this face:** Highway Gothic is the lettering on low-clearance signs, which tell drivers how much headroom they have. The reason belongs to this product.

### 3.2 SF Pro (the instructions)

This is the system font, used through text styles and never bundled. It sets every sentence, engine explanation, caption, list row label, section heading, footer, button, and system control.

### 3.3 Role split (enforced)

- **Overpass** sets:
  1. Every amount in a column or on its own: MoneyText, CurrencyField digits and "$", ledger, Plan, Coming up.
  2. The readings: "$505", and "$195" with its unit phrase.
  3. Instrument labels inside charts and on axes.
  4. The verdict line and the empty-state headline.
  5. The "Headroom" wordmark on the lock cover.
  6. Navigation titles, only if gate 14a passes.
- **SF Pro** sets everything else.
- **Overpass never sits inside an SF sentence.** Amounts inside sentences stay SF.
- A label and value pair may mix fonts only when the value sits in its own trailing column or trailing Text, as in "Balance" (SF) next to "$900" (Overpass).
- **CI enforces it** (section 10, step 13): the strings `"Overpass`, `CTFontManager` and `kCTFontVariationAttribute` may appear only in `App/DesignSystem/Typography.swift`.

### 3.4 Type scale

Sizes follow a classic ladder (13, 15, 17, 20, 22, 34, 44, 56) fitted to iOS text styles. Every Overpass role scales with `UIFontMetrics(forTextStyle:)`. Nothing is smaller than 13 pt.

**Bold Text:** when `legibilityWeight == .bold`, every Overpass `wght` goes up 100.

| Role (`OverpassRole`) | Face and wght | Base pt | Scales with | Tracking | Extras | Used for |
|---|---|---|---|---|---|---|
| `.readingXL` | Overpass 600 | 56 | `.largeTitle` | -0.5 | tnum, `lineLimit(1)`, `minimumScaleFactor(0.5)` | Ask "$505" |
| `.readingL` | Overpass 600 | 44 | `.largeTitle` | -0.4 | tnum, `lineLimit(1)`, `minimumScaleFactor(0.5)` | Result clearance figure |
| `.readingUnit` | Overpass 500 | 20 | `.title3` | 0 | tnum | "below your $200 floor" beside `.readingL` |
| `.verdict` | Overpass 600 | 22 | `.title2` | 0 | multiline | Verdict line, empty-state headline |
| `.wordmark` | Overpass 700 | 34 | `.largeTitle` | -0.3 | | Lock cover, unavailable state; nav large titles if gated in |
| `.navInline` | Overpass 600 | 17 | `.headline` | 0 | | Inline nav titles, only if gated in |
| `.amount` | Overpass 500 | 17 | `.body` | 0 | tnum, trailing aligned | MoneyText default, ledger, Plan, Coming up, CurrencyField, what-if price |
| `.amountTotal` | Overpass 600 | 17 | `.body` | 0 | tnum | Ledger total |
| `.instrument` | Overpass 500 | 13 | `.footnote` | +0.2 | tnum | Axis labels, "Floor $200", "Laptop, Oct 2", staff values, callout amounts |
| `.instrumentStrong` | Overpass 600 | 13 | `.footnote` | +0.2 | tnum | Ring label "$5, Oct 13" |

| SF role | Style | Used for |
|---|---|---|
| Section heading | `.headline` (17 semibold), `.isHeader` | "Ask about a purchase", "Coming up", "What moves your balance by Tue Oct 13" |
| Question text | `.title3` (20) | What the user types, so it reads as their own sentence |
| Stale question | `.title3.weight(.semibold)` | "Is your balance still $1,000?" |
| Body | `.body` (17) | Result sentence, list labels, empty-state body |
| Support | `.subheadline` (15) | "Spending room today", reading captions |
| Note | `.footnote` (13) | Helper text, footers, legend, chart captions, "Next income" |

### 3.5 Implementation (the only place fonts are built)

`App/DesignSystem/Typography.swift` (new):

```swift
import CoreText
import SwiftUI
import UIKit

enum OverpassRole: Hashable {
    case readingXL, readingL, readingUnit, verdict, wordmark, navInline,
         amount, amountTotal, instrument, instrumentStrong

    var size: CGFloat { switch self {
        case .readingXL: 56; case .readingL: 44; case .readingUnit: 20; case .verdict: 22
        case .wordmark: 34; case .navInline, .amount, .amountTotal: 17
        case .instrument, .instrumentStrong: 13 } }
    var style: UIFont.TextStyle { switch self {
        case .readingXL, .readingL, .wordmark: .largeTitle; case .readingUnit: .title3
        case .verdict: .title2; case .navInline: .headline; case .amount, .amountTotal: .body
        case .instrument, .instrumentStrong: .footnote } }
    var weight: CGFloat { switch self {
        case .readingUnit, .amount, .instrument: 500; case .wordmark: 700; default: 600 } }
    var tracking: CGFloat { switch self {
        case .readingXL: -0.5; case .readingL: -0.4; case .wordmark: -0.3
        case .instrument, .instrumentStrong: 0.2; default: 0 } }
}

@MainActor
enum Typography {
    static let postScriptName = "Overpass-Regular"
    private static let wghtAxis = NSNumber(value: 0x7767_6874) // 'wght'
    private static var cache: [String: UIFont] = [:]

    /// Called first thing in HeadroomApp.init.
    static func register() {
        guard let url = Bundle.main.url(forResource: "Overpass-Variable", withExtension: "ttf") else {
            assertionFailure("Overpass-Variable.ttf missing from the bundle"); return
        }
        CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil) // already-registered is fine
    }

    static func uiFont(_ role: OverpassRole, size: DynamicTypeSize = .large, boldText: Bool = false) -> UIFont {
        let key = "\(role)-\(size)-\(boldText)"
        if let font = cache[key] { return font }
        let descriptor = UIFontDescriptor(fontAttributes: [
            .name: postScriptName,
            UIFontDescriptor.AttributeName(rawValue: kCTFontVariationAttribute as String):
                [wghtAxis: role.weight + (boldText ? 100 : 0)],
            .featureSettings: [[kCTFontOpenTypeFeatureTag: "tnum", kCTFontOpenTypeFeatureValue: 1]],
        ])
        let traits = UITraitCollection(preferredContentSizeCategory: UIContentSizeCategory(size))
        let font = UIFontMetrics(forTextStyle: role.style)
            .scaledFont(for: UIFont(descriptor: descriptor, size: role.size), compatibleWith: traits)
        cache[key] = font
        return font
    }
}

struct OverpassModifier: ViewModifier {
    let role: OverpassRole
    @Environment(\.dynamicTypeSize) private var size
    @Environment(\.legibilityWeight) private var legibility
    func body(content: Content) -> some View {
        content
            .font(Font(Typography.uiFont(role, size: size, boldText: legibility == .bold) as CTFont))
            .tracking(role.tracking)
    }
}

extension View {
    func overpass(_ role: OverpassRole) -> some View { modifier(OverpassModifier(role: role)) }
}
```

Glyph sizing reads `Typography.uiFont(role, ...).capHeight` with the same environment values, so glyphs grow with Dynamic Type and Bold Text.

**Required tests** in `AppTests/TypographyTests.swift`:

1. `UIFont(name: "Overpass-Regular", size: 17) != nil` after `register()`.
2. With `.amount`, the widths of "0", "1" and "7" are equal (tnum is on).
3. The width of "$505" at `.readingL` is greater than the same string with wght 400 (the variation axis is applied).
4. The width of "\u{2212}" equals the width of "+".

### 3.6 Money formatting

- `Money.formatted` is unchanged: "-$750". It stays for editable text, existing tests, and engine sentences that already use it.
- `Money.displayText` (new):
  - "−$750" with U+2212 for negatives.
  - `displayText(signed: true)` gives "+$800" for positives.
  - `displayText(forceCents: true)` gives "$45.00".
- `Money.spokenText` (new): "minus $750", "plus $800", "$700". VoiceOver reads these as "minus 750 dollars" and so on.
- **Column rule:** in any column where one row has cents, every row in that column shows cents. The view decides with `amounts.contains { $0.cents % 100 != 0 }` and passes `forceCents`.
- `MoneyInput` also accepts a leading U+2212 wherever it accepts "-" (paste safety).
- **Dates:** new engine sentences join weekday, month and day with U+00A0 ("Fri Oct 2"), so a date never breaks across lines. They use `LocalDate.shortTextNoBreak` (new). Existing strings keep `shortText`.

---

## 4. Shape, surface, spacing, glyphs

### 4.1 Rules

- **Result has no boxes.** Verdict, reading, chart and ledger sit directly on Paper.
- **Custom surfaces** (Plate, 20 pt continuous radius) exist only for the question field and the chart selection callout.
- **Native lists and forms** keep the system inset-grouped geometry.
- **Capsules** for every button and both what-if controls.
- **Glass** only on the control layer: tab bar, toolbars, Result what-if bar, and prominent buttons. Sheets drop `themedList()` so the iOS 26 sheet glass shows at partial height.
- **Stroke weights:**
  - 2.5 pt: With line
  - 2 pt: Ask gauge path
  - 1.5 pt: datum, clearance line, Without line
  - 1 pt: purchase rule, $0 rule, ticks, selection rule
  - system hairline: ledger row dividers
- **Double rule:** two 1 px Ink lines 2 pt apart, exactly as wide as the amount column. Used only above the ledger total, where it means "sum".
- **Margins:** remove every hard-coded `.padding(.horizontal, Theme.Space.xl)`.
  - Scrolling screens use `.scenePadding(.horizontal)` on the content stack, so content lines up with the large title and with inset list rows.
  - **Check:** in a screenshot, the reading's left edge sits within 1 pt of the "H" in "Headroom" on the default iPhone simulator and the Pro Max simulator. If not, use `.padding(.horizontal)`.
- **Vertical rhythm:** 4 / 8 / 16 / 24 / 32 (`Theme.Space`).
- **Touch targets:** at least 44 x 44 pt, with the frame and `.contentShape(.rect)` inside the button label.
- **Remove** `surfaceCard()` from `Theme.swift` once no caller remains (end of step 9).

### 4.2 Glyphs (`App/DesignSystem/Glyphs.swift`, new; all `accessibilityHidden(true)`)

**`DimensionTick: Shape`**
- One line from (minX, maxY) to (maxX, minY).
- Drawn at 9 x 9 pt, 1.5 pt stroke, round cap.

**`DatumRule: View`**
- A horizontal `Path`, stroked 1.5 pt Ink with `StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: [6, 3])`.
- Height 2 pt. Width set by the caller.

**`LowRing: View`**
- `Circle().fill(Theme.canvas).overlay(Circle().strokeBorder(tint, lineWidth: 2))`.
- 11 pt, or 12 pt with Bold Text.

**`ClearanceGlyph(kind: .above | .below | .belowZero, tint:, height:)`**
- `height` = the paired reading font's `capHeight`. Width = `height * 0.34`.
- `.above`:
  - Dashed stub 1.5 pt at the bottom, the full glyph width, dash [3, 2].
  - Vertical 1.5 pt line from the bottom to the top at the horizontal center.
  - A `DimensionTick` of `width * 0.6` at each end.
- `.below`: same, with the stub at the top.
- `.belowZero`: like `.below`, with a solid stub instead of a dashed one.
- Aligned so its bottom sits on the text baseline: `.alignmentGuide(.firstTextBaseline) { $0[.bottom] }`.

**`VerdictGlyph(kind:)`** in a 26 x 20 unit box, scaled to `capHeight * 1.3` tall. Stroke is 2 pt (2.5 pt with Bold Text), round caps and joins, in the status tint.
- `.stays`: dashed datum at y = 15. Step `M1,4 H9 V9 H17 V6 H25`, which stays above the datum.
- `.dips`: dashed datum at y = 12. Step `M1,4 H9 V18 H17 V9 H25`, which dips through the datum.
- `.belowZero`: solid line at y = 12. Step `M1,4 H9 V19 H25`.
- `.needsInfo`: dashed datum at y = 12 only.

**`SectionDrawing: View`** (empty state, static) in a 320 x 112 design box, `aspectRatio(320/112, .fit)`, max height 140 pt.
- Ink 2.5 pt path `M0,24 H64 V48 H136 V72 H200 V40 H264 V16 H320`.
- Datum at y = 96.
- `LowRing` (Evergreen) at (152, 72).
- Clearance line at x = 160 from y = 96 up to y = 72, Evergreen 1.5 pt, with a slash tick at each end.

---

## 5. Screens

### 5.1 Ask (home)

```
+--------------------------------------------+
| Headroom                                   | large title (SF; Overpass only if gate 14a)
|                                            |
| Spending room today                        | SF subheadline, Graphite
| [C^] $505                                  | ClearanceGlyph above (Evergreen) + .readingXL Ink; id spendingRoom
| Spend up to this today and stay at or      | SF subheadline, Graphite
| above your $200 floor through Fri Nov 27.  |
|                                            |
|  ___                                       | RoomGauge, 150 pt
|     |_____________                         |  path Ink 2 pt, stepEnd, 2 points per day
|                   |__(o)                   |  LowRing at the low
|                       /                    |
|                       |   (clearance, Evergreen)
|                       /                    |
| - - - - - - - - - - - - - - - Floor $200   |  datum; label .instrument Graphite
| ''''''''''''''''''''''''''''''''''''''''''' |  day ruler, Rule
| Today   Oct 1                      Oct 20  |  .instrument Graphite
| (o) Lowest $705 on Tue Oct 13              | SF footnote, Ink
|                                            |
| Ask about a purchase                       | SF headline, header
| +----------------------------------------+ |
| | Can I buy a $700 laptop next Friday?   | | Plate r20; SF title3; own placeholder, wraps
| |                                ( Ask ) | | glassProminent capsule, only with text; id check
| +----------------------------------------+ |
| Include a price and a day.                 | SF footnote, Graphite
| Enter details instead                      | plain button, Evergreen, full-width 44 pt row
|                                            |
| Coming up                                  | SF headline, header
| Groceries                           -$100  | SF body + .amount
| Tue Sep 29                   Balance $900  | SF footnote Graphite + .instrument Graphite
| -------------------------------------------- hairline
| Paycheck                            +$800  |
| Thu Oct 1                  Balance $1,700  |
| Rent                                -$750  |
| Fri Oct 2                    Balance $950  |
| Groceries                           -$100  |
| Tue Oct 6                    Balance $850  |
| Phone                                -$45  |
| Fri Oct 9                    Balance $805  |
| Groceries                           -$100  |
| (o) Tue Oct 13, your lowest  Balance $705  |
+--------------------------------------------+
|   [Ask]          [Plan]        [Settings]  | Liquid Glass tab bar
+--------------------------------------------+
```

**Components**

- `NavigationStack`, `.navigationTitle("Headroom")`.
- `ScrollView` with `.scrollDismissesKeyboard(.interactively)`.
- `VStack(alignment: .leading, spacing: 32)` containing: reading block, gauge block, ask block, coming-up block.
- **Reading block:** `VStack(spacing: 4)` with `.accessibilityElement(children: .combine)`. This is the same structure as today, which is how the UI test finds `staticTexts["spendingRoom"]`.
  - The glyph and "$505" sit in `HStack(alignment: .firstTextBaseline, spacing: 8)`.
  - `.accessibilityIdentifier("spendingRoom")` stays on the "$505" `Text`.
  - The figure uses `.contentTransition(reduceMotion ? .identity : .numericText(value: Double(room.cents)))`.
- **Gauge block:** `RoomGauge(detail:)` (section 6.6), then the caption row. The gauge is its own accessibility element with identifier `roomGauge`.
- **Question field:**
  - `TextField("Question", text: $question, axis: .vertical)` with no prompt, `.lineLimit(1...6)`, SF `.title3`.
  - Placeholder: a `Text` overlay in Graphite, multiline, shown when `question.isEmpty`, `.allowsHitTesting(false)`, `.accessibilityHidden(true)`. It always wraps, so it never truncates at XL.
  - `.accessibilityHint("For example, can I buy a $700 laptop next Friday?")`.
  - Container: `.padding(16)`, `.frame(minHeight: 96, alignment: .topLeading)`, Plate, 20 pt continuous radius. With Increase Contrast, add a 1 pt Graphite stroke.
- **Ask button:**
  - Sits in the field container's bottom-trailing corner.
  - `.buttonStyle(.glassProminent)`, `.controlSize(.regular)`, label `.foregroundStyle(Theme.onAccent)`.
  - `.opacity(hasText ? 1 : 0)`, `.disabled(!hasText || isReading)`, `.allowsHitTesting(hasText)`, `.accessibilityHidden(!hasText)`.
  - `.accessibilityIdentifier("check")` stays.
  - Fade animation: `.easeOut(duration: 0.15)`, or none under Reduce Motion.
- **Keyboard visibility:**
  - `@FocusState var questionFocused`.
  - `ScrollViewReader`: `.onChange(of: questionFocused) { if $1 { proxy.scrollTo("askField", anchor: .bottom) } }` and the same on `question` changes while focused.
  - This keeps the Ask button above the keyboard. The smoke test taps `check` right after typing.
- **Return key:**
  - Keep `.submitLabel(.go)` and `.onSubmit(ask)`.
  - Also `.onChange(of: question) { _, new in if new.hasSuffix("\n") { question.removeLast(); ask() } }`.
  - `ask()` starts with `guard !isReading, confirm == nil`, so it runs exactly once. It sets `questionFocused = false` before presenting the sheet.
- **Enter details instead:** `Button { ... } label: { Text("Enter details instead").frame(maxWidth: .infinity, minHeight: 44, alignment: .leading).contentShape(.rect) }`.
- **Coming up:** `ComingUpList(entries:)` (new file). Entries come from `CashEngine.register(detail.points, through: detail.low.date)`.
  - Rows use `AnyLayout`: `HStackLayout(alignment: .firstTextBaseline)`, or `VStackLayout(alignment: .leading)` when `dynamicTypeSize.isAccessibilitySize`.
  - At most 6 rows. Beyond that, a plain button "Show 3 more before Tue Oct 13" expands in place.
  - The last entry is the lowest day. Its meta line starts with a `LowRing` glyph (status tint) and reads "Tue Oct 13, your lowest".
  - Each row is one accessibility element: "Groceries, Tuesday, September 29, minus $100, balance $900".

**Exact copy**

| Element | Copy |
|---|---|
| Title | "Headroom" |
| Reading label | "Spending room today" |
| Caption (`Explainer.roomCaption`) | "Spend up to this today and stay at or above your $200 floor through Fri Nov 27." |
| Gauge in-plot labels | "Floor $200"; axis "Today", "Oct 1", "Oct 20" |
| Gauge caption | "Lowest $705 on Tue Oct 13" |
| Gauge VoiceOver | label "Balance ahead"; value (`Explainer.roomSummary`) "Starts at $1,000 today. Lowest $705 on Tue Oct 13, which is $505 above your $200 floor. Checked through Fri Nov 27." |
| Section | "Ask about a purchase" |
| Placeholder | "Can I buy a $700 laptop next Friday?" |
| Helper | "Include a price and a day." |
| Button | "Ask"; while reading "Reading" with `sparkles` `.symbolEffect(.pulse)` (off under Reduce Motion); VoiceOver label "Reading your question" |
| Link | "Enter details instead" |
| Section | "Coming up" |
| Row meta | "Tue Sep 29" + "Balance $900"; lowest row "Tue Oct 13, your lowest" |
| Expand | "Show {n} more before {Tue Oct 13}" |

**States**

| State | What shows |
|---|---|
| Room available | As drawn above |
| Room is $0, low below floor | Reading "$0" with `ClearanceGlyph(.below)` in Amber. Caption "Your balance already dips below your $200 floor on Tue Oct 13, before any purchase." Gauge draws the below variant in Amber, hanging from the datum to the low, with a 16% Amber fill between. |
| Room is $0, low exactly at floor | Caption "Your balance reaches your $200 floor on Tue Oct 13, so there is no room to spend today." No clearance line; the ring sits on the datum. |
| Room is $0, low below $0 | Caption "Your balance already goes below $0 on Tue Oct 13, before any purchase." Brick, measured from the $0 rule. |
| Stale balance (only missing item is today's confirmation) | Replaces reading and gauge; Coming up hidden. "Is your balance still $1,000?" (SF title3 semibold), then "Last confirmed Fri Sep 25. Headroom only answers with today's balance." (SF subheadline Graphite). Buttons "Yes" (glassProminent, onAccent label) and "Change it" (glass). "Yes" keeps today's logic: it asks about items scheduled today first. |
| Needs info | `VerdictGlyph(.needsInfo)` (Graphite) + "Add a few details first" (`.verdict`), each `Explainer.text(for:)` line (SF subheadline Graphite), then "Open Plan" (glass). No card. Coming up hidden. |
| Reading (on-device AI) | Ask button shows "Reading" with the pulse and is disabled. The field stays editable. |
| Empty plan | `EmptyStateView` (5.6), same condition as today |
| Protected data unavailable | 5.7 |
| Error | None on this screen. Parse problems surface on the Confirm sheet. |

### 5.2 Confirm details (sheet)

```
+--------------------------------------------+
|                  -----                     |
| (x)         Confirm details        (Check) | glass toolbar; Check = role .confirm, id confirmCheck
|                                            |
| "Can I buy a $700 laptop next Friday?"     | SF body, Ink; read spans dotted-underlined (Graphite)
|            ....   ......  ...........      |
| Read on this iPhone.                       | SF footnote, Graphite
|                                            |
| Purchase                                   | header, Graphite
| +----------------------------------------+ |
| | Item                            laptop | | TextField, trailing
| | Price                             $700 | | CurrencyField, id price
| | Date                     [ Oct 2, 2026 ]| | compact DatePicker, labels hidden
| | Friday                                 | | wide weekday under "Date", SF footnote Graphite
| +----------------------------------------+ |
| Paid from checking. Make sure these match  | footer, Graphite
| what you meant.                            |
+--------------------------------------------+
```

**Components**

- `NavigationStack` > `Form` with system background. No `themedList()` and no `.listRowBackground`.
- `.presentationDetents([.medium, .large])` (unchanged).
- **Section 1 (only when opened from a question):**
  - A quote `Text(AttributedString)` inside curly quotes U+201C and U+201D.
  - Spans from `QuestionSpans.find(in:parsed:today:timeZone:)` (new; section 10, step 10) get `.underlineStyle = Text.LineStyle(pattern: .dot, color: Theme.textSecondary)`.
  - Then the source line.
  - `.listRowBackground(Color.clear)`, `.listRowInsets(EdgeInsets())`.
- **Section 2 "Purchase":**
  - Item `TextField` (prompt "Laptop"). The value stays exactly as read, so it matches the underlined word in the quote.
  - `CurrencyField(label: "Price", text:, identifier: "price")`.
  - Date row: `LabeledContent { DatePicker("Date", selection:, displayedComponents: .date).labelsHidden() } label: { VStack(alignment: .leading) { Text("Date"); Text(weekdayName).font(.footnote).foregroundStyle(Theme.textSecondary) } }`. `weekdayName` is `LocalDate(draft.date).weekdayName`, which gives "Friday".
- **Keyboard:** `@FocusState`, and `ToolbarItemGroup(placement: .keyboard) { Spacer(); Button("Done") { focus = nil } }`.
- **Errors:**
  - Footer shows `Label(errors.joined(separator: " "), systemImage: "exclamationmark.circle")` in Brick.
  - `.onChange(of: showErrors) { if $1 { AccessibilityNotification.Announcement(errors.joined(separator: " ")).post() } }`.
- `ConfirmRequest` gains `question: String?`. It is nil for "Enter details instead", which hides section 1.

**Exact copy**

| Element | Copy |
|---|---|
| Title | "Confirm details" (was "Check this purchase") |
| Confirm button | "Check". This is the only "Check" in the app, and it runs the engine. |
| Source line, built-in reader | "Read on this iPhone." |
| Source line, on-device AI | "Read on this iPhone with on-device AI." |
| AI fallback note (`AIReader`) | "Read without on-device AI this time. Look over each field." |
| Section header | "Purchase" |
| Rows | "Item", "Price", "Date" |
| Footer | "Paid from checking. Make sure these match what you meant." |
| Errors (existing strings) | "Enter a price, like 700 or 49.99." / "Pick today or a later date." / "Pick a date on or before Mon Oct 26. Headroom checks purchases up to 30 days out." |
| Keyboard | "Done" |

**States**

| State | What shows |
|---|---|
| From question | Quote plus source line |
| Enter details | No quote, fields empty |
| AI fallback | Note line under the quote |
| Invalid | Errors footer, announced |
| No span found | That part of the quote is plain, with no underline and no guess |

### 5.3 Result

```
+--------------------------------------------+
| (<)                Laptop                  | inline title (displayName)
|              $700 on Fri Oct 2             | .navigationSubtitle, live
|                                            |
| [V:dips] Dips below your floor             | VerdictGlyph Amber + .verdict; id verdict; header
| [Cv] $195 below your $200 floor            | ClearanceGlyph below Amber + .readingL + .readingUnit
| Spending $700 on Fri Oct 2 takes checking  | SF body, Ink; id chartSummary
| down to $5 on Tue Oct 13.                  |
|                                            |
| Earliest date that stays above your floor  | SF footnote, Graphite
| ( Try Fri Oct 16 )                         | .bordered, capsule, Evergreen; id tryEarliestDate
|                                            |
| Laptop, Oct 2                        $1,500| purchase label top; staff on the trailing edge
|  __  :                                  -  |
| |  |_:________                      $1,000 |
| |    :        |______________           -  | Without, Rule 1.5
| |    :__                          $500   - |
| - - -:- |- - - - - - - - - - Floor $200 -- | datum, Ink dash 6/3
|      :  |_/////_|    (With, Ink 2.5)       | 16% Amber fill below the datum
|      :        (o)  |                   $0  | ring at the low; clearance line beside it
|      :      $5, Oct 13                     | .instrumentStrong on a Paper pad
| ''''''''''''''''''''''''''''''''''''''''''' | day ruler
| Today Oct 1                         Oct 23 |
|                                            |
| == With laptop     -- Without laptop       | legend: real line swatches, SF footnote
| [//] Below your floor Tue Oct 6 to Thu     | SF footnote Ink, 16x10 tinted swatch
|      Oct 15                                |
| Checked through Fri Nov 27. The lowest     | SF footnote Graphite
| point is in view.                          |
|                                            |
| What moves your balance by Tue Oct 13      | SF headline, header
| Checking today                     $1,000  | SF body + .amount
| -------------------------------------------| hairline between every row
| Paycheck, Oct 1                     +$800  |
| Rent, Oct 2                         -$750  |
| Laptop, Oct 2                       -$700  |
| Groceries, 3 times                  -$300  |
| Phone, Oct 9                         -$45  |
|                                  ========  | double rule, amount column width
| (o) Lowest point, Tue Oct 13           $5  | LowRing + SF body semibold + .amountTotal
| Next income: Paycheck +$800 on Thu Oct 15  | SF footnote Graphite
|                                            |
| How this is calculated                  >  | DisclosureGroup on Paper, tint accent
+--------------------------------------------+
| ( [cal] Fri Oct 2 )      ( $  700 )        | .safeAreaBar(edge: .bottom), glass capsules
+--------------------------------------------+
|   [Ask]          [Plan]        [Settings]  |
+--------------------------------------------+
```

**Components**

- `ScrollView`, then a `VStack(alignment: .leading, spacing: 24)`:
  1. verdict + reading + sentence + warning (spacing 8)
  2. earliest-fit block
  3. chart block
  4. ledger
  5. assumptions
- `.navigationTitle(displayName)` (unchanged), `.navigationBarTitleDisplayMode(.inline)`.
- `.navigationSubtitle(Explainer.purchaseLine(purchase))`, giving "$700 on Fri Oct 2".
- `.scrollEdgeEffectStyle(.soft, for: .top)`, `.background(Theme.canvas.ignoresSafeArea())`.
- **`StatusLabel(status:, title:)`** (verdict): `VerdictGlyph` + `Text` in `.verdict`, `.accessibilityElement(children: .combine)`, `.accessibilityAddTraits(.isHeader)`, `.accessibilityIdentifier("verdict")`.
- **`ReadingLockup(reading:)`:**
  - `ViewThatFits(in: .horizontal)`: first `HStack(alignment: .firstTextBaseline, spacing: 8) { glyph; figure; words }`; otherwise `VStack(alignment: .leading) { HStack { glyph; figure }; words }`.
  - One combined accessibility element.
  - Figure uses `.contentTransition(.numericText(value:))`, or `.identity` under Reduce Motion.
- **Sentence:** `Text(Explainer.purchaseSentence(a))`, SF body, Ink, `.fixedSize(horizontal: false, vertical: true)`, `.accessibilityIdentifier("chartSummary")`.
- **Baseline warning** (`Explainer.baselineWarningText`): `Label(text, systemImage: "exclamationmark.circle")`, SF subheadline medium, Amber.
- **Earliest fit:**
  - When `Explainer.earliestFitDate(a)` returns a date: the footnote label, then `Button(Explainer.tryLabel(date, today:)) { purchase.date = date }` with `.buttonStyle(.bordered)`, `.buttonBorderShape(.capsule)`, `.tint(Theme.accent)`, id `tryEarliestDate`.
  - When it is nil and `Explainer.earliestFitNote(a)` is non-nil: that note in SF footnote Graphite.
  - Hidden when the verdict already fits.
- **`CashChart(analysis:, peel:, measured:, selectedDay:)`** (section 6), then `ChartLegend`, the below-floor line, and the caption.
- **Ledger:** `LedgerView(ledger: Explainer.ledger(a))`.
  - A `Grid`. The amount column uses `.gridColumnAlignment(.trailing)`.
  - Rows are separated by `Divider()` with `.gridCellColumns(2)`.
  - The double rule is a `GridRow { Color.clear.gridCellUnsizedAxes([.horizontal, .vertical]); DoubleRule().frame(height: 4).gridCellUnsizedAxes(.horizontal) }`.
  - At accessibility sizes, rows become VStacks (label, then amount).
  - Each row's VoiceOver label: "Rent, October 2, minus $750".
- **Assumptions:** `DisclosureGroup("How this is calculated")` with the existing `Explainer.assumptions`, footnote Graphite, no card.
- **What-if bar:** `.safeAreaBar(edge: .bottom) { WhatIfBar(...) }`.
  - `GlassEffectContainer { HStack(spacing: 8) { dateCapsule; priceCapsule } }`.
  - Each capsule has `.glassEffect(.regular.interactive(), in: .capsule)` and is at least 44 pt tall.
  - Uses `ViewThatFits`, stacking vertically at accessibility sizes.
  - **Date capsule:**
    - `Button { showDate = true } label: { Label(purchase.date.shortText, systemImage: "calendar") }`.
    - Popover: `DatePicker("Purchase date", selection: dateBinding, in: today...today+30, displayedComponents: .date).datePickerStyle(.graphical).padding().presentationCompactAdaptation(.popover)`.
    - VoiceOver label "Purchase date, {Friday, October 2}", hint "Opens a calendar". id `whatIfDate`.
  - **Price capsule:**
    - `CurrencyField(label: "Price", text: $priceText)`, compact variant with no label shown. The identifier defaults to "Price", as today.
    - Invalid price shows under the bar: "Enter a price, like 700 or 49.99." in Brick with `exclamationmark.circle`.
  - **Price commit:** on submit, on focus loss, or after a 400 ms pause: `.task(id: priceText) { try? await Task.sleep(for: .milliseconds(400)); commit() }`. This replaces commit-on-every-keystroke, so the verdict and haptic never flip mid-typing.
  - Keyboard toolbar: "Done".
- **Haptic:** `.sensoryFeedback(trigger: status) { _, new in switch new { case .fits: .success; case .crossesFloor: .warning; case .goesNegative: .error; case .needsInfo: nil } }`. It still fires only on a verdict change, as today.
- **Announcement:** `.onChange(of: status) { AccessibilityNotification.Announcement(headline + ". " + reading.figure + " " + reading.words + ".").post() }`.

**Exact copy (engine-owned; section 9)**

| Verdict | Headline | Reading | Sentence |
|---|---|---|---|
| Fits, room > 0 | "Stays above your floor" | "$198" + "above your $200 floor" | "Spending $700 on Fri Oct 16 leaves checking at $398 on Tue Nov 10, its lowest point." |
| Fits, room = 0 | "Stays at your floor" | "$0" + "above your $200 floor" | same pattern |
| Crosses floor | "Dips below your floor" | "$195" + "below your $200 floor" | "Spending $700 on Fri Oct 2 takes checking down to $5 on Tue Oct 13." |
| Goes negative | "Takes checking below $0" | "$95" + "below $0" | "Spending $300 on Sat Oct 24 takes checking down to −$95 on Sun Nov 1." |
| Plan already below floor | "Already dips below your floor" | gap, "below your $200 floor" | existing `summary`: "Without this purchase, your balance drops to $100 on Tue Sep 29, which is $100 below your $200 floor. This purchase adds $20 to the shortfall." |
| Plan already below $0 | "Checking already goes below $0" | gap, "below $0" | existing `summary` text |
| Needs info | "Add a few details first" | none | engine lines + "Confirm balance" |

| Element | Copy |
|---|---|
| Subtitle | "$700 on Fri Oct 2" |
| Baseline warning | "Before this purchase, your balance drops to $150 on Mon Sep 28, below your $200 floor." |
| Earliest fit | "Earliest date that stays above your floor" + "Try Fri Oct 16" (or "Try today") |
| No fit | "No date in the next 30 days leaves room for $700." / "Your plan dips below your floor even without this purchase." |
| Chart | "Laptop, Oct 2" / "Floor $200" / "$5, Oct 13" / axis "Today", "Oct 1", "Oct 23" / staff "$0", "$500", "$1,000", "$1,500" |
| Legend | "With laptop" / "Without laptop" (uses `purchase.item` as stored) |
| Below-floor line | "Below your floor Tue Oct 6 to Thu Oct 15" (several spans joined with ", and "; one day reads "Below your floor on Tue Oct 6") |
| Caption | "Checked through Fri Nov 27. The lowest point is in view." |
| Ledger | "What moves your balance by Tue Oct 13" / "Checking today" / reasons / "Everything else, 4 items" (only when there are more than 5 groups) / "Lowest point, Tue Oct 13" |
| Next income | "Next income: Paycheck +$800 on Thu Oct 15" (existing) |
| Bar | "Fri Oct 2", "$700", "Purchase date", "Done" |

**States**

| State | What shows |
|---|---|
| Analyzed | As above |
| Needs info | Verdict glyph (needs info) + "Add a few details first" + engine lines. Plus a glassProminent "Confirm balance" when the balance is missing or stale (existing logic). No chart or ledger. The what-if bar stays, as today. |
| Price invalid | Error under the bar. The last valid price stays analyzed. |
| Loading | None. The engine is synchronous. |

### 5.4 Plan

```
+--------------------------------------------+
| Plan                                       | large title
| Checking                                   | header, Graphite
| +----------------------------------------+ |
| | Balance                      $1,000  > | | SF body + .amount Ink + tertiary chevron
| | Confirmed today                        | | SF footnote Graphite
| |----------------------------------------| |
| | Floor                          $200  > | |
| | Keep at least this much                | |
| +----------------------------------------+ |
| The lowest balance you want to keep. $0 is |
| fine.                                      |
| Income                                     |
| | Paycheck                      +$800  > | | Ink, not Evergreen
| | Every 2 weeks, next Thu Oct 1          | |
| | + Add income                           | | Evergreen (a control)
| Bills                                      |
| | Rent                          -$750  > | |
| | Monthly on the 2nd                     | |
| | Phone                          -$45  > | |
| | Streaming                      -$12  > | |
| | Groceries                     -$100  > | |
| | + Add bill                             | |
| Include a weekly amount for groceries and  |
| transport.                                 |
+--------------------------------------------+
```

**Components**

- Native `List` (insetGrouped) with `.themedList()` so Paper is the canvas.
- Delete the dead container-level `.listRowBackground(Theme.surface)`. System rows are `#FFFFFF` / `#1C1C1E`, which equals Plate.
- Balance and Floor merge into one "Checking" section.
- Every header and footer goes through `.sectionText()` (Graphite, section 10, step 3). `Section("Income")` becomes a header closure.
- Editable rows get a trailing `Image(systemName: "chevron.forward").font(.footnote.weight(.semibold)).foregroundStyle(.tertiary).accessibilityHidden(true)`.
- Amounts: `MoneyText(.amount)` in Ink. Income keeps "+".
- Label and amount rows use `AnyLayout` and stack at accessibility sizes.
- Swipe to delete, the sheets, and the confirmation dialogs are unchanged.

**Exact copy**

| Element | Copy |
|---|---|
| Section | "Checking" |
| Balance row | "Balance". Meta: "Confirmed today" / "Last confirmed Fri Sep 25" (Amber with `clock` glyph) / "Not added yet". Empty value "Add" (Evergreen). |
| Floor row | "Floor". Meta "Keep at least this much". Empty value "Choose" (Evergreen). |
| Section footer | Save failure first, Brick with `exclamationmark.circle`: "Your last change was not saved. Make it again." Then "The lowest balance you want to keep. $0 is fine." |
| Income / Bills | "Income", "Add income", "Bills", "Add bill", footer "Include a weekly amount for groceries and transport." |
| Balance sheet | Title "Confirm balance" (was "Checking balance"); confirm `Button("Confirm", role: .confirm)`; rest unchanged |
| Floor sheet | Title "Floor" (was "Cash floor"); field "Keep at least"; footer unchanged |
| Event editor | Unchanged copy; only colors change |

**States:** empty values (Add / Choose), stale balance meta (Amber plus glyph plus words), save failure, and swipe-delete confirmations as today.

### 5.5 Settings

```
+--------------------------------------------+
| Settings                                   |
| | Lock with Face ID                 [on] | |
| Asks for Face ID or your passcode when you |
| come back to Headroom.                     |
| | Read questions with on-device AI  [on] | |
| Uses Apple's on-device model to read your  |
| question. It never leaves this iPhone, and |
| prices always come from the digits you     |
| type.                                      |
| Privacy                                    |
| | [iphone]  Headroom never sends your    | | icons Graphite: not tappable
| |           plan anywhere.               | |
| | [wifi.slash]   Works without internet  | |
| | [lock.shield]  Unreadable while your   | |
| |                iPhone is locked        | |
| Headroom has no accounts and no analytics. |
| Your plan is included in your iPhone       |
| backups.                                   |
| | Try the sample plan                    | |
| | Delete everything                      | | destructive
| The sample plan replaces your current plan.|
| | Acknowledgments                      > | |
| | Version                          0.1.0 | |
| Headroom gives estimates from the plan you |
| enter. It is not financial advice.         |
+--------------------------------------------+
```

**Components:** plain native `List` with `.themedList()`, all SF. Header and footer text goes through `.sectionText()`. Privacy `Label` icons are `.foregroundStyle(Theme.textSecondary)`. "Acknowledgments" pushes `AcknowledgmentsView` (new), which shows "Overpass typeface" and "SIL Open Font License 1.1", then the bundled `Overpass-OFL.txt` in SF footnote inside a ScrollView.

**Exact copy**

| Element | Copy |
|---|---|
| Lock toggle | "Lock with Face ID" / "Lock with Touch ID" / "Lock with Optic ID" / "Lock with passcode", from `lock.biometry` |
| Lock footer | "Asks for Face ID or your passcode when you come back to Headroom." with the same name. Passcode-only: "Asks for your passcode when you come back to Headroom." Unavailable: the existing reason. |
| AI toggle and footer | Unchanged |
| Privacy rows | "Headroom never sends your plan anywhere." / "Works without internet" / "Unreadable while your iPhone is locked" |
| Privacy footer | "Headroom has no accounts and no analytics. Your plan is included in your iPhone backups." |
| Data | "Try the sample plan" (was "Load the sample plan"); "Delete everything" (was "Delete all data"); footer "The sample plan replaces your current plan." |
| Dialogs | "Replace your plan with the sample plan?" with `Button("Replace plan", role: .destructive)`. "Delete your plan, balance, and settings from this iPhone?" with `Button("Delete everything", role: .destructive)`. |
| About | "Acknowledgments", "Version", footer unchanged |

### 5.6 Empty state (first launch)

```
+--------------------------------------------+
| Headroom                                   |
|                                            |
|  _______                                   | SectionDrawing, static, accessibilityHidden
|         |_________          ______         |
|                   |_(o)___|                |
|                     /                      | clearance, Evergreen
|                     |                      |
|                     /                      |
|  - - - - - - - - - - - - - - - - - - - -   | datum
|                                            |
| See a purchase before you make it          | .verdict (Overpass 600 22)
| Add your balance, paychecks, and bills.    | SF body, Graphite
| Then ask what a purchase does to checking. |
|                                            |
| ( Set up your plan )                       | glassProminent, .large, hugging, onAccent label
| Try the sample plan                        | plain button, Evergreen, 44 pt row
|                                            |
| [lock] Headroom never sends your plan      | SF footnote, Graphite
| anywhere.                                  |
+--------------------------------------------+
```

**Copy**

- "See a purchase before you make it"
- "Add your balance, paychecks, and bills. Then ask what a purchase does to checking."
- "Set up your plan" (was "Set up my plan")
- "Try the sample plan" (the UI test finds this label)
- "Headroom never sends your plan anywhere."

**Behavior:** the drawing is static with no numbers, so there is no Reduce Motion handling. There is exactly one prominent button.

### 5.7 Lock cover, privacy snapshot, and unavailable state

```
+--------------------------------------------+
|                                            |
|                                            |  top of block at 40% of height
| Headroom                                   | .wordmark, Ink, leading on the title margin
| - - - - - - - - - - - - - - - - - - - - -  | DatumRule, full width
|                                            |
| Locked. Unlock to see your plan.           | SF body, Graphite (locked only)
| ( [faceid] Unlock with Face ID )           | glassProminent, .large, onAccent (locked only)
|                                            |
+--------------------------------------------+
```

**Behavior (`RootView`)**

- The cover shows while `lock.isLocked || scenePhase != .active` (unchanged condition).
- **Insertion is instant; removal fades.** Use `.transition(.asymmetric(insertion: .identity, removal: .opacity))` with `.animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: covered)`. The app-switcher snapshot must never capture a half-faded cover.
- The TabView gets `.accessibilityHidden(covered)`. The cover gets `.accessibilityAddTraits(.isModal)`.
- The button label and symbol come from `lock.biometry`: `faceid` / `touchid` / `opticid` / `lock` for passcode.
- Retry stays manual, which avoids Face ID loops (existing `AppLock` logic).

**Copy:** "Headroom" / "Locked. Unlock to see your plan." / "Unlock with Face ID" / "Unlock with Touch ID" / "Unlock with Optic ID" / "Unlock with passcode". The app switcher (not locked) shows the wordmark and datum only.

**Protected data unavailable (inside Ask):** a `DatumRule` 120 pt wide replaces `lock.fill`, then "Unlock your iPhone to open your plan" (SF title3 semibold) and "Your plan is protected while the phone is locked. It opens as soon as you unlock." (SF body Graphite). This copy is unchanged.

---

## 6. Chart spec (Swift Charts)

### 6.1 Engine data (HeadroomCore, tested)

**Path, `ChartPath.points(_ days: [DayPoint]) -> [ChartPoint]`** with `ChartPoint { x: Double; amount: Money }`.
- For day index i it emits `(i, low)` and then `(i + 0.5, close)`.
- After the last day it appends `(n, last.close)`.
- The x axis is a day index from today, not a `Date`. No DST, no time zones. Labels map index to `today.adding(days:)`.
- Result: paydays rise on their real date, rent drops on its date, the last day draws a run and not a spike, and the drawn minimum is still exactly the engine's `low`.
- `baseline` and `withPurchase` produce identical x arrays, which the peel animation needs.

**Window, `ChartWindow.end(today:horizon:including:) -> LocalDate`** = `min(horizon, max(today + 20, max(including) + 7))`.
- Result includes: `purchase.date`, `purchaseLow.date`, `baselineLow.date`, and the earliest-fit date when the "Try" button shows.
- Ask includes: `low.date`.
- Why the lowest point is always in view: before the purchase date, the With path equals the baseline and the whole window starts at today. From the purchase date on, With = baseline - price, so both lines reach their minimum on `purchaseLow.date`.
- The chart draws `days.prefix(windowDays + 1)`.

**Y domain, `ChartScale.domain(values:floor:lowLabelBelow:topRatio:) -> ClosedRange<Int>`** in cents.
- `lo = min(values + [floor, 0])`, `hi = max(values + [floor])`, `range = max(hi - lo, 10_000)`.
- Bottom pad: `max(range * 16 / 100, 10_000)` when the low label sits below the ring, otherwise `max(range * 6 / 100, 5_000)`.
- Top pad: `max(range * topRatio / 100, 5_000)`. topRatio is 14 on Result (room for the purchase label) and 8 on Ask.

**Staff, `ChartScale.staff(domain:) -> [Money]`.**
- Step: the smallest of $50, $100, $200, $250, $500, $1,000, $2,000, $2,500, $5,000, $10,000, $20,000, $25,000, $50,000, and so on, that gives at most 4 intervals across `hi - lo`.
- Values: every multiple of the step inside the domain, including $0.

**Day marks, `ChartScale.dayMarks(today:end:) -> [LocalDate]`.**
- Today, every first-of-month inside the range, and `end`.
- Drop a month start closer than 3 days to today or to `end`.
- The view labels today as "Today" and the rest with `monthDayText`. At accessibility sizes, only today and end are labeled.

**Below-floor spans, `Explainer.belowFloorSpans(_ days:, floor:) -> [ClosedRange<LocalDate>]`:** contiguous runs where `low < floor`. They are computed over the full horizon, so a later dip is still stated in words.

### 6.2 Result chart marks (`App/Result/CashChart.swift`), back to front

Definitions:
- `status` = `ResultStatus(a)`, `tint` = `status.tint`.
- `datum` = `floor.cents`, or `0` when the verdict is goesNegative.
- `lowX = Double(today.days(until: purchaseLow.date)) + 0.25`.
- `withShown[i] = base[i] + (with[i] - base[i]) * peel`, using integer cents rounded. Here `peel` is 0 or 1, and Charts animates between the two states (section 7).

1. **Below-floor area.** Drawn only when any `withShown < floor`.
   - `AreaMark(x: .value("Day", p.x), yStart: .value("Low", min(p.cents, floor)), yEnd: .value("Floor", floor), series: .value("Area", "below"))`
   - `.interpolationMethod(.stepEnd)`, `.foregroundStyle(tint.opacity(0.16))`.
   - If gate 14b passes, use `HatchStyle.paint(tint)` over the 16% fill instead: a 6 x 6 pt tile with a 1 pt line at 45 degrees in `tint`, rendered once with `ImageRenderer`.
2. **$0 rule.** `RuleMark(y: .value("Zero", 0))`, `Theme.chartBaseline`, 1 pt solid, always drawn. Its label comes from the staff.
3. **Without line.** `LineMark(x:, y:, series: .value("Line", "without"))`, `Theme.chartBaseline`, `StrokeStyle(lineWidth: 1.5, lineJoin: .round)`, `.stepEnd`.
4. **With line.** `LineMark(series: "with")`, `Theme.textPrimary`, `StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)`, `.stepEnd`. It is Ink in every verdict and never the accent.
5. **Datum.** `RuleMark(y: .value("Floor", floor))`, `Theme.textPrimary`, `StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: [6, 3])`.
   - `.annotation(position: .top, alignment: .trailing, spacing: 3) { Text("Floor \(floor.displayText)").overpass(.instrument).foregroundStyle(Theme.textSecondary).padding(.horizontal, 3).background(Theme.canvas) }`.
   - It sits at the trailing end, clear of the purchase rule. This fixes the "Floo|r" collision.
6. **Purchase rule.** `RuleMark(x: .value("Buy", Double(purchaseIndex)))`, `Theme.textSecondary`, `StrokeStyle(lineWidth: 1, dash: [2, 3])`.
   - Label: an invisible `PointMark(x: purchaseIndex, y: domain.upperBound).symbolSize(0)` with `.annotation(position: .bottomTrailing, spacing: 2, overflowResolution: .init(x: .fit(to: .chart), y: .disabled)) { "Laptop, Oct 2" }` in `.instrument` Graphite on a Paper pad.
   - The label text is `Explainer.purchaseMarker(purchase)`, which capitalizes the first letter.
7. **Clearance mark** (`ClearanceMarks: ChartContent`, shared with the Ask gauge):

```swift
struct ClearanceMarks: ChartContent {
    let x: Double, datum: Int, low: Int, tint: Color, measured: Bool
    var body: some ChartContent {
        let tip = measured ? low : datum
        RuleMark(x: .value("Day", x), yStart: .value("Datum", datum), yEnd: .value("Low", tip))
            .foregroundStyle(tint).lineStyle(StrokeStyle(lineWidth: 1.5)).offset(x: 8)
        PointMark(x: .value("Day", x), y: .value("Datum", datum))
            .symbol { DimensionTick().stroke(tint, style: .init(lineWidth: 1.5, lineCap: .round)).frame(width: 9, height: 9) }
            .offset(x: 8)
        PointMark(x: .value("Day", x), y: .value("Low", tip))
            .symbol { DimensionTick().stroke(tint, style: .init(lineWidth: 1.5, lineCap: .round)).frame(width: 9, height: 9) }
            .offset(x: 8)
    }
}
```

   - The line sits 8 pt to the right of the ring, on the flat low segment. When `low == datum`, the mark is omitted and the ring sits on the datum.
8. **Low ring.** `PointMark(x: lowX, y: purchaseLow.cents).symbol { LowRing(tint: tint) }.opacity(measured ? 1 : 0)`.
   - Label `"$5, Oct 13"` (`Explainer.lowMarker(a)`) in `.instrumentStrong`, Ink, on a 2 pt Paper pad.
   - Placed on the side away from the floor: `.annotation(position: low < floor ? .bottom : .top, spacing: 5, overflowResolution: .init(x: .fit(to: .chart), y: .disabled))`.
   - The Y bottom pad reserves room for it.
9. **Selection (6.4).** `RuleMark(x: selectedX)` in Ink 1 pt, with a callout annotation.

### 6.3 Axes, scale, legend, size

- **X axis:**

```swift
.chartXAxis {
    AxisMarks(values: dayIndices) { _ in
        AxisTick(centered: true, length: 3, stroke: .init(lineWidth: 1)).foregroundStyle(Theme.chartBaseline)
    }
    AxisMarks(values: labeledIndices) { v in
        AxisTick(length: 7, stroke: .init(lineWidth: 1)).foregroundStyle(Theme.chartBaseline)
        AxisValueLabel(anchor: .top) { Text(label(v)).overpass(.instrument).foregroundStyle(Theme.textSecondary) }
    }
}
```

  No gridlines. At accessibility sizes, day ticks drop to weekly.
- **Y axis (staff):**

```swift
.chartYAxis {
    AxisMarks(position: .trailing, values: staff.map(\.cents)) { v in
        AxisTick(length: 7, stroke: .init(lineWidth: 1)).foregroundStyle(Theme.chartBaseline)
        AxisValueLabel { Text(Money(cents: v.as(Int.self)!).displayText).overpass(.instrument).foregroundStyle(Theme.textSecondary) }
    }
}
```

  No gridlines.
- **Scales:** `.chartXScale(domain: 0...Double(windowDays + 1))` and `.chartYScale(domain: ChartScale.domain(...))`.
- **Legend:** `.chartLegend(.hidden)`. `ChartLegend` below the chart is an HStack (VStack at accessibility sizes):
  - `Capsule().fill(Theme.textPrimary).frame(width: 24, height: 2.5)` with "With laptop"
  - `Capsule().fill(Theme.chartBaseline).frame(width: 24, height: 1.5)` with "Without laptop"
  - Both in SF footnote Graphite.
- **Below-floor line:** a 16 x 10 `RoundedRectangle(cornerRadius: 2)` swatch in `tint.opacity(0.16)` with a 1 pt `tint` stroke, followed by `Explainer.belowFloorText(a)` in SF footnote Ink. Shown only when non-nil.
- **Caption:** `Explainer.chartCaption(a)` in SF footnote Graphite.
- **Size:** `@ScaledMetric(relativeTo: .body) var plotHeight: CGFloat = 260`, applied as `.frame(height: min(max(plotHeight, 220), 360))`. Plus `.padding(.top, 4)`.
- **Animation:** `.animation(reduceMotion ? nil : .smooth(duration: 0.3), value: purchase)` (existing pattern).

### 6.4 Selection (read any day)

- `@State var selectedX: Double?`, `.chartXSelection(value: $selectedX)`.
- A long press followed by a drag, so vertical scrolling and back-swipe keep working:

```swift
.chartGesture { proxy in
    LongPressGesture(minimumDuration: 0.3)
        .sequenced(before: DragGesture(minimumDistance: 0))
        .onChanged { value in
            if case .second(true, let drag?) = value { proxy.selectXValue(at: drag.location.x) }
        }
        .onEnded { _ in selectedX = nil }
}
```

- The day is `Int(selectedX)`, clamped to the window.
- **Callout:** Plate background, 20 pt continuous radius, 12 pt padding, `.annotation(position: .top, overflowResolution: .init(x: .fit(to: .chart), y: .fit(to: .chart)))`. Contents:
  - The date `shortText` in SF footnote semibold.
  - That day's `withPurchase` lines: name in SF footnote, amount in `.instrument`, "−$750".
  - "With laptop $250" and "Without laptop $950": both closes, from engine `close`.
- **Haptic:** `.sensoryFeedback(.selection, trigger: selectedDay)`.
- There is no drag cursor, and the selection never changes the purchase date.

### 6.5 Chart accessibility

- Keep `.accessibilityElement(children: .ignore)`, `.accessibilityLabel("Balance chart")` and `.accessibilityIdentifier("chart")`.
- Value: `Explainer.summary(a) + " " + (Explainer.belowFloorText(a) ?? "") + " Checked through " + checkedThrough.spokenText + "."`
- Add `.accessibilityChartDescriptor(CashChartDescriptor(analysis:, windowDays:))` (new, `AXChartDescriptorRepresentable`):
  - Title "Balance with and without {item}", summary as above.
  - X axis: `AXNumericDataAxisDescriptor` "Day", range 0...windowDays, `valueDescriptionProvider` giving `today.adding(days: Int($0)).spokenText`.
  - Y axis: dollars, `valueDescriptionProvider` giving `Money(cents: Int(($0 * 100).rounded())).spokenText`. Double is used only for audio values.
  - Series: `AXDataSeriesDescriptor(name: "With laptop", isContinuous: true, dataPoints: daily lows)` and "Without laptop".
  - Audio Graph works through the rotor.

### 6.6 Ask gauge (`App/Ask/RoomGauge.swift`)

- **Data:** `RoomDetail.points` (baseline), windowed with `ChartWindow.end(including: [low.date])`. `ChartScale.domain(lowLabelBelow: false, topRatio: 8)`.
- **Marks:**
  - Path `LineMark` in Ink 2 pt `.stepEnd`.
  - Datum with "Floor $200" trailing label.
  - `ClearanceMarks(x: lowX, datum: floor, low: low, tint: status tint, measured: true)`.
  - `LowRing` at the low, with no in-plot label.
  - $0 rule only when the path goes below $0.
- **Axes:** X uses the same ruler as Result (window end label, for example "Oct 20"). Y axis hidden. No legend, no selection, no animation.
- **Caption row:** `LowRing` glyph + "Lowest $705 on Tue Oct 13" (SF footnote Ink). At accessibility sizes, "Floor $200." moves here from the plot.
- **Size:** `@ScaledMetric(relativeTo: .body) var height: CGFloat = 150`, clamped 130...200.
- **Accessibility:** one element: `.accessibilityElement(children: .ignore)`, label "Balance ahead", value `Explainer.roomSummary(detail)`, id `roomGauge`.

---

## 7. Motion

### 7.1 The one orchestrated moment: "the measurement" (Result, first appearance)

This answers the user's Check tap.

| Time | What happens |
|---|---|
| 0 ms | Verdict, reading, sentence, ledger, Without line, datum and purchase rule are already in place. The With line lies on the Without line (`peel = 0`). Clearance is at the datum (`measured = false`). |
| 0 to 450 ms | `withAnimation(.easeOut(duration: 0.45)) { peel = 1 }`. The With line peels down from the Without line at the purchase date by exactly the price. Every frame lies between two engine states, because with = baseline - price from the purchase date on. The below-floor fill grows with it. |
| 450 to 750 ms | `withAnimation(.easeOut(duration: 0.3)) { measured = true }`. The dimension line extends from the datum to the low with its tick riding the tip, like a caliper opening. The ring and its label fade in (`opacity` bound to `measured`). |

- Driven by `.task(id: purchase)` with `@State var hasPlayed = false`.
- Numbers never count up. The reading is set before the motion starts.
- The verdict haptic still fires only on a verdict change, not on first appearance (existing behavior).
- Nothing else in the app moves without a user action. Ask gauge, empty-state drawing and Plan are static.

### 7.2 Responses to actions

| Action | Response |
|---|---|
| "Try Fri Oct 16", date popover change, committed price | Chart morphs with `.smooth(duration: 0.3)` (existing `.animation(value: purchase)`). Set `measured = false` without animation, wait 300 ms, then `withAnimation(.easeOut(duration: 0.3)) { measured = true }`: the measurement replays, shortened, showing what changed. The reading figure rolls with `.numericText(value:)`. The nav subtitle updates. The verdict glyph cross-fades. |
| Verdict changes | `.success` (stays above), `.warning` (dips), `.error` (below $0). VoiceOver announcement. |
| Chart selection | `.selection` haptic per whole day. Callout follows the finger with no easing. |
| Question gains text | Ask capsule fades in, `.easeOut(0.15)` |
| On-device AI reading | `sparkles` `.pulse` (existing) |
| Unlock | Cover fades out, 0.2 s. It appears instantly. |
| Plan edits | Ask reading rolls with `.numericText` when you return |

### 7.3 Reduce Motion

- `peel = 1` and `measured = true` immediately, with no animations.
- The chart swaps paths without easing.
- `.contentTransition(.identity)` for amounts. The verdict glyph swaps instantly.
- Ask capsule appears and disappears instantly. The cover shows and hides instantly.
- The sparkles pulse is off. The static word "Reading" stays.
- Haptics and VoiceOver announcements are unchanged, because they are not motion.
- System navigation and sheet transitions follow the system setting.

---

## 8. Accessibility checklist

- [ ] **Contrast.** Every text pair in section 2.2 is at least 4.5:1 in light and dark. Every meaningful graphic in 2.3 is at least 3:1. List headers and footers go through Graphite (`.sectionText()`). Nothing uses system secondaryLabel on Paper.
- [ ] **Increase Contrast.** HC colorsets per 2.1. A 1 pt stroke on the question field and the what-if capsules.
- [ ] **Status never by color alone.** Verdict glyph shape + headline words + tint. In the chart, also the mark direction (above or below the datum), the ring, and the "Below your floor..." text line (plus hatch if gated in).
- [ ] **Verdict glyphs** are `.monochrome` tint, never hierarchical.
- [ ] **Dynamic Type:**
  - Every Overpass role scales through `UIFontMetrics`.
  - Readings use `lineLimit(1)` and `minimumScaleFactor(0.5)`, so "$12,345" never wraps mid-number.
  - Label and value rows (ledger, Plan, Coming up) switch to `VStackLayout` at accessibility sizes.
  - The reading lockup and the what-if bar use `ViewThatFits`.
  - Chart and gauge heights are `@ScaledMetric` with clamps. X labels reduce to Today and the end.
  - The gauge floor label moves to the caption.
  - The question placeholder wraps (custom overlay).
- [ ] **Screenshot passes** in light and dark at default, xLarge, AX3 (`xcrun simctl ui booted content_size accessibility-extra-large`) and AX5 (`accessibility-extra-extra-extra-large`).
- [ ] **Bold Text:** Overpass wght +100. Glyph strokes 2 to 2.5 pt. Ring 11 to 12 pt.
- [ ] **VoiceOver structure:**
  - `.isHeader` on the verdict, "Ask about a purchase", "Coming up", "What moves your balance by ...".
  - The Ask reading is one element (id `spendingRoom` inside, as today). The gauge is one element with a full sentence.
  - The Result reading is one element. The sentence is its own static text (`chartSummary`).
- [ ] **Announcements:** on verdict change (headline + reading), on Confirm and sheet validation errors, and on the Result price error.
- [ ] **Chart:** summary value + `AXChartDescriptor` with two continuous series (Audio Graph).
- [ ] **Money and dates:**
  - `Money.spokenText` in every amount's `accessibilityLabel`, which says "minus" and "plus" explicitly.
  - Full dates (`LocalDate.spokenText`, "Tuesday, October 13") in row, gauge, date-capsule and descriptor labels.
- [ ] **CurrencyField:** "$" is `.accessibilityHidden(true)`. The field has `.accessibilityLabel(label)` and `.accessibilityValue(MoneyInput.parse(text).map(\.spokenText) ?? "empty")`.
- [ ] **Privacy:** TabView `.accessibilityHidden(covered)`. Cover `.isModal`. Cover insertion is never animated.
- [ ] **Touch targets:** every tap target is at least 44 x 44: "Enter details instead", "Try the sample plan", "Show n more", the Ask capsule, the what-if capsules, and "Try Fri Oct 16".
- [ ] **Reduce Motion** per 7.3.
- [ ] **Decorative glyphs** are `accessibilityHidden`.

---

## 9. Engine additions and copy changes (HeadroomCore)

Everything here is pure and deterministic, and each item has tests (section 11). The engine math does not change.

**`Money.swift`**
- `displayText` / `displayText(signed:forceCents:)` (U+2212).
- `spokenText`.

**`LocalDate.swift`**
- `shortTextNoBreak` ("Fri\u{00A0}Oct\u{00A0}2").
- `weekdayName` ("Friday").
- `spokenText` ("Friday, October 2"), using new full-name arrays.

**`Analysis.swift`**
- `public struct RoomDetail { room: Money; through: LocalDate; low: Low; floor: Money; start: Money; points: [DayPoint] }`
- `public enum RoomDetailOutcome { case needsInfo([MissingInfo]); case room(RoomDetail) }`
- `CashEngine.roomDetail(_:today:)`, which reuses `planMissing`, `project` and `lowest`.
- `spendingRoom` is unchanged.

**`Charting.swift`** (new): `ChartPoint`, `ChartPath.points`, `ChartWindow.end`, `ChartScale.domain`, `ChartScale.staff`, `ChartScale.dayMarks`.

**`Register.swift`** (new)
- `public struct RegisterEntry { name; amount (signed Money); date; balanceAfter: Money; isIncome }`
- `CashEngine.register(_ days: [DayPoint], through: LocalDate) -> [RegisterEntry]`.
- The opening balance for day 0 is `first.low + sum(money-out lines)`.
- Lines are applied in engine order (out, then in).
- On the `through` day only money-out lines are included, matching `reasons`.

**`Explainer.swift`**

- `headline(_:)` becomes, in the same branch order:
  1. `baselineLowFromPurchaseDate < 0`: "Checking already goes below $0"
  2. below floor: "Already dips below your floor"
  3. `.fits(room == 0)`: "Stays at your floor"
  4. `.fits`: "Stays above your floor"
  5. `.crossesFloor`: "Dips below your floor"
  6. `.goesNegative`: "Takes checking below $0"
- `summary(_:)`: only the goesNegative second sentence changes, to "That's {by} below $0." The rest, including `formatted` hyphens, stays exact.
- `baselineWarningText(_:)`: "your plan goes to" and "your plan drops to" both become "your balance drops to", with `displayText`.
- New, all using `displayText` and `shortTextNoBreak`:
  - `reading(_:) -> Reading { amount; words; kind }`
  - `purchaseSentence(_:)` (returns `summary(a)` for the plan-already-short cases)
  - `purchaseLine(_ p: Purchase)` ("$700 on Fri Oct 2")
  - `purchaseMarker(_ p:)` ("Laptop, Oct 2")
  - `lowMarker(_:)` ("$5, Oct 13")
  - `earliestFitDate(_:) -> LocalDate?` (nil when the verdict fits, when there is no fit, or when the fit date equals the purchase date)
  - `tryLabel(_:today:)` ("Try Fri Oct 16" / "Try today")
  - `belowFloorSpans(_:floor:)`, `belowFloorText(_:)`
  - `chartWindowEnd(_:)`, `chartCaption(_:)`
  - `ledger(_:) -> Ledger { start; rows (max 5, same grouping and order as reasons); remainder: Reason? ("Everything else, N items"); end: Low }`
  - `ledgerHeading(_:)`
  - `roomCaption(_ d: RoomDetail)`, `roomSummary(_ d: RoomDetail)`
- `reasons(_:)` keeps `prefix(5)` and its exact tested output. `ledger` shares a new private `groupedMovements(_:)` helper.

**`App/Ask/AIReader.swift`:** the fallback note becomes "Read without on-device AI this time. Look over each field."

---

## 10. Implementation checklist (ordered; the app stays shippable after every step)

**Always kept:**
- confirm-before-calculate
- stale-balance question and today's-items logic
- AppLock rules
- on-device AI reading with its fallback
- swipe to delete and destructive dialogs
- `numericText` transitions
- Reduce Motion gating
- the verdict-change haptic trigger
- `-uiTestSamplePlan` / `-uiTestEmptyPlan`
- the identifiers `spendingRoom`, `question`, `check`, `confirmCheck`, `price`, `verdict`, `chartSummary`, `chart`

Run `swift test --package-path Packages/HeadroomCore` and the full Xcode test plan after every step.

1. **Engine (no UI change).** `Packages/HeadroomCore/Sources/HeadroomCore/`:
   - `Money.swift`, `LocalDate.swift`, `Analysis.swift`: the section 9 additions.
   - New `Charting.swift` and `Register.swift`.
   - `Explainer.swift`: the section 9 changes.
   - Tests: update the literals listed in 11.2; add `ChartingTests.swift`, `RegisterTests.swift`, new cases in `ExplainerTests.swift`, `MoneyTests.swift`, `LocalDateTests.swift`, `AnalysisTests.swift` (11.3).
2. **Assets and fonts.**
   - `App/Resources/Assets.xcassets`: set new values in `Canvas`, `Surface`, `TextPrimary`, `TextSecondary`, `ChartBaseline`, `AccentColor`, `Warning`, `Danger` (2.1). Add "High Contrast" appearances. Add `OnAccent.colorset`.
   - Add `App/Resources/Fonts/Overpass-Variable.ttf` (byte-identical to `ofl/overpass/Overpass[wght].ttf`; check the SHA-256) and `App/Resources/Fonts/Overpass-OFL.txt`. The synced folder bundles them automatically.
   - New `App/DesignSystem/Typography.swift` (3.5).
   - `App/HeadroomApp.swift`: call `Typography.register()` first in `init()`.
   - New `AppTests/TypographyTests.swift`.
3. **Design system.**
   - `Theme.swift`:
     - add `static let onAccent = Color(.onAccent)`
     - change `money(_:weight:)` to forward to Overpass roles (`.amount`, `.amountTotal`)
     - add `extension View { func sectionText() -> some View { font(nil).foregroundStyle(Theme.textSecondary) } }` for headers and footers
     - keep `themedList()`
     - keep `surfaceCard()` until step 9, then delete it
   - New `Glyphs.swift` (4.2), with `HatchStyle` stubbed to return the flat fill.
   - `MoneyText.swift`: `.overpass(role)`, `displayText(signed:forceCents:)`, `.accessibilityLabel(spokenText)`, `.contentTransition(reduceMotion ? .identity : .numericText(value: Double(money.cents)))`.
   - `CurrencyField.swift`: `HStack(spacing: 0)`. "$" in `.overpass(.amount)`, Ink when text is non-empty and Graphite for the "0.00" prompt, `.accessibilityHidden(true)`. Field accessibility label and value per section 8. The `identifier ?? label` default is unchanged. Add a `compact: Bool` variant for the what-if bar (no `LabeledContent`).
   - `StatusLabel.swift`: replace `ResultStatus.symbol` with `glyph: VerdictGlyph.Kind` (tint unchanged). Body is `HStack(alignment: .firstTextBaseline) { VerdictGlyph; Text(title).overpass(.verdict) }`, `.combine`, `.isHeader`, id `verdict`. `ResultStatusTests` stays green (it only tests `init`).
4. **Shared chart pieces.**
   - New `App/Result/ChartMarks.swift`: `ClearanceMarks`, `ChartLegend`, `BelowFloorLine`, the day-ruler axis builder, the staff builder.
   - New `App/Result/CashChartDescriptor.swift`.
5. **Result chart.** Rewrite `App/Result/CashChart.swift` per 6.2 to 6.5. It takes `peel`, `measured` and `selectedX` bindings. The identifier `chart` and the summary label stay.
6. **Result screen.** `App/Result/ResultView.swift`:
   - Remove `keyFigures`, `figureRow` and every `surfaceCard()`.
   - Add the verdict, `ReadingLockup`, sentence (`chartSummary`), warning, earliest-fit block, chart block, `LedgerView` (new `App/Result/LedgerView.swift`) and assumptions.
   - Add `.safeAreaBar` `WhatIfBar` (new `App/Result/WhatIfBar.swift`) with the date popover and the debounced price.
   - Add `navigationSubtitle`, `scrollEdgeEffectStyle`, the semantic haptic, the announcement, and the section 7 `.task(id: purchase)` sequence.
   - Replace `statusKey` with `status: ResultStatus?`.
7. **Ask gauge and reading.**
   - New `App/Ask/RoomGauge.swift`.
   - `App/Ask/AskView.swift`:
     - `roomSection` switches on `CashEngine.roomDetail`.
     - The reading block keeps its structure and id.
     - Add the gauge and caption, the room-zero variants, and open stale and needs-info states (no `surfaceCard`).
     - "Update" becomes "Change it".
     - Remove `.padding(.horizontal, Theme.Space.xl)` and use `.scenePadding(.horizontal)`.
8. **Ask question and Coming up.**
   - `AskView.askSection`: custom placeholder, `.title3`, the Ask capsule inside the field (id `check`), `@FocusState` with `ScrollViewReader` scroll, the Return handling and re-entrancy guard, helper line, and "Enter details instead" as a 44 pt row.
   - Rename `check()` to `ask()` internally; the identifier stays.
   - `ConfirmRequest` gains `question`.
   - New `App/Ask/ComingUpList.swift`.
9. **Empty state.** `App/Ask/EmptyStateView.swift`: `SectionDrawing` replaces the symbol. Headline in `.verdict`. "Set up your plan" is glassProminent and hugging with the onAccent label. "Try the sample plan" becomes a plain 44 pt button. Then delete `surfaceCard()` from `Theme.swift`.
10. **Confirm sheet.**
    - `App/Ask/ConfirmCard.swift` per 5.2: remove `themedList()` and `.listRowBackground`, add quote, source line, weekday label, keyboard toolbar, error glyph and announcement. Title "Confirm details".
    - New `App/Ask/QuestionSpans.swift`: `find(in text:, parsed:, today:, timeZone:) -> [ReadSpan]`, where `ReadSpan { field: .item/.price/.date; range: Range<String.Index> }`.
      - Price: the single `QuestionParser.moneyTokens` match range in the original text, only when exactly one exists.
      - Date: the `NSDataDetector` first match on a copy of the text with the money token replaced by equal-length spaces, so indices stay aligned.
      - Item: each word of `parsed.item`, as a case-insensitive range outside the other spans.
      - Anything not found gets no underline.
      - `QuestionParser.parse` is **not touched**, so `QuestionParserTests` stay green.
    - `App/Ask/AIReader.swift`: note text (9).
    - New `AppTests/QuestionSpansTests.swift`.
11. **Plan and sheets.**
    - `App/Plan/PlanView.swift` per 5.4: merged Checking section, `.sectionText()`, chevrons, Ink income, AnyLayout rows. Remove the container `.listRowBackground`.
    - `ConfirmBalanceSheet.swift`: title "Confirm balance", `Button("Confirm", role: .confirm)`, remove `themedList()` and `.listRowBackground`, `.sectionText()`, error glyph and announcement.
    - `FloorSheet.swift`: title "Floor", same sheet cleanup.
    - `EventEditor.swift`: same sheet cleanup and error glyph; copy unchanged.
12. **Settings, lock, root.**
    - `App/Settings/AppLock.swift`:
      - Add `enum Biometry { case faceID, touchID, opticID, none }`.
      - Add a protocol requirement `func biometry() -> Biometry` with a default `extension Authenticator { func biometry() -> Biometry { .none } }`, so `StubAuthenticator` compiles unchanged.
      - `DeviceAuthenticator` reads `LAContext().biometryType` after `canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics)`.
      - `AppLock.biometry` exposes it.
    - `App/Settings/SettingsView.swift` per 5.5. New `App/Settings/AcknowledgmentsView.swift`.
    - `App/RootView.swift`:
      - Ask tab `systemImage: "chart.line.flattrend.xyaxis"`.
      - `PrivacyCover` per 5.7 (wordmark, `DatumRule`, biometry label).
      - TabView `.accessibilityHidden(covered)`, asymmetric transition.
    - Do **not** add `tabBarMinimizeBehavior` (section 12).
13. **CI.** Add two steps to `.github/workflows/ci.yml`:

```bash
# No en or em dashes, or middle dots, in UI code or engine strings
if grep -rnE $'\xE2\x80\x93|\xE2\x80\x94|\xC2\xB7' App Packages/HeadroomCore/Sources --include=*.swift; then
  echo "::error::Dash or middle dot in UI text."; exit 1; fi
# Overpass is only built in Typography.swift
if grep -rnE '"Overpass|CTFontManager|kCTFontVariationAttribute' App --include=*.swift | grep -v 'App/DesignSystem/Typography.swift'; then
  echo "::error::Overpass used outside Typography.swift."; exit 1; fi
```

    Today's code passes the dash grep (checked).
14. **Gated steps.** Each has a written pass condition. Any failure means keep the fallback.
    - **14a, nav titles.** In `HeadroomApp.init`, set `UINavigationBar.appearance().largeTitleTextAttributes = [.font: Typography.uiFont(.wordmark)]` and `titleTextAttributes = [.font: Typography.uiFont(.navInline)]`. Change the properties only, never `standardAppearance`, so Liquid Glass stays.
      - Pass requires: large to inline collapse and expand on Ask, Plan and Settings in light and dark with no jump, clip, or revert to SF under the scroll edge; and a runtime Dynamic Type change from Control Center rescales titles without relaunch.
      - Fail: delete the two lines and keep system titles.
    - **14b, hatch.** Render `AreaMark.foregroundStyle(HatchStyle.paint(tint))` in the simulator, light and dark.
      - Pass requires the 45 degree lines to be visible and to scroll or animate with the mark.
      - Fail: keep the flat 16% fill.
15. **Docs and screenshots.**
    - Regenerate `build/shots-light`, `shots-dark`, `shots-xl`, and add `shots-ax3` and `shots-ax5` from the SmokeTests attachments. Update `docs/screenshots/*` (README images; `0-empty.png` is stale today).
    - `README.md`: new verdict names in "How it works".
    - `docs/DESIGN.md`, rewritten rules:
      - Type: Overpass for readings, SF for instructions.
      - Icons: SF Symbols plus the Shape glyphs in `Glyphs.swift`.
      - Tokens table (2.1).
      - Surfaces: the question field and callout only; Result has no cards.
      - Kept: "Glass only on the control layer", "Nothing smaller than footnote", the zero-dash rule.
      - Pre-flight adds AX3/AX5 and Increase Contrast checks.

---

## 11. Tests

### 11.1 Unchanged and still passing

- All of `AnalysisTests`, `ProjectionTests`, `ScheduleTests` and `MoneyTests` (`formatted` still "-$450").
- `LocalDateTests`.
- `ExplainerTests` except the literals below (including `reasons` prefix(5) and the `nextIncomeText` strings).
- `AppLockTests`, `DateBridgeTests`, `EventDraftTests`, `MoneyInputTests`, `PlanStoreTests`, `QuestionParserTests`, `SamplePlanTests`, `ScheduleTextTests`, `ResultStatusTests`, `OnDeviceModelTests`.
- `SmokeTests` with **no edits**:
  - `staticTexts["spendingRoom"]` keeps the combined structure.
  - `question`, then `check`: the capsule appears once text exists, and scroll-to-field keeps it above the keyboard.
  - `confirmCheck`.
  - `verdict`.
  - `chartSummary` is a static text.
  - `swipeUp` on the Result scroll view.
  - `tabBars.buttons["Plan"]`: the tab bar is never minimized.
  - `buttons["Try the sample plan"]`.

### 11.2 String literals updated because their copy is deliberately rewritten

Seven literals change. No test is removed or loosened.

| Test | Old | New |
|---|---|---|
| `ExplainerTests.workedExample` | "Would cross your cash floor" | "Dips below your floor" |
| `ExplainerTests.planAlreadyShort` | "Your plan is already below your floor" | "Already dips below your floor" |
| `ExplainerTests.headlines` | "Fits your cash floor" | "Stays above your floor" |
| `ExplainerTests.headlines` | "Known bills exceed projected cash" | "Takes checking below $0" |
| `ExplainerReviewFixTests.warningBeforePurchaseNegative` | "Before this purchase, your plan goes to -$450 on Mon Sep 28." | "Before this purchase, your balance drops to \u{2212}$450 on Mon Sep 28." |
| `ExplainerReviewFixTests.warningBeforePurchaseBelowFloor` | "Before this purchase, your plan drops to $80 on Mon Sep 28, below your $100 floor." | "Before this purchase, your balance drops to $80 on Mon Sep 28, below your $100 floor." |
| `InterpreterTests` (fallback note) | "On-device AI could not read this, so the built-in parser did." | "Read without on-device AI this time. Look over each field." |

`ExplainerTests.headlines` still expects `summary(negative)` to contain "-$200 on Sun Nov 1". That remains true, because `summary` keeps `formatted`.

### 11.3 New tests

Fixtures: `samplePlanP1()`, today Sat Sep 26 2026, laptop $700 on Fri Oct 2, unless noted. Expected values were hand-computed. Below, "NBSP" means that test literals use "\u{00A0}" between weekday, month and day.

- **`ChartingTests`**
  - `ChartPath.points(baseline).count == 2 * days + 1`.
  - Min of `amount` equals `baselineLow.amount`.
  - The P1 paycheck on Wed Sep 30 (index 4) rises at x = 4.5.
  - Last x equals the day count.
  - `ChartWindow.end` gives Thu Oct 22 for the analysis (Mon Oct 12 low, Thu Oct 15 fit) and Mon Oct 19 for `roomDetail`. The window always contains `purchaseLow.date` and `baselineLow.date`.
  - `ChartScale.domain` includes floor and 0.
  - `staff` has at most 5 values and contains 0.
  - `dayMarks(today, Oct 22)` is [Sep 26, Oct 1, Oct 22].
- **`RegisterTests`**
  - The P1 register through Mon Oct 12 has 6 entries with `balanceAfter` [900, 1700, 950, 850, 805, 705] dollars.
  - The last `balanceAfter` equals `roomDetail.low.amount`.
- **Room detail** (`AnalysisTests`)
  - `roomDetail.room == spendingRoom` room for P1, workedExamplePlan and rentAndPayPlan.
  - P1 low is $705 on Mon Oct 12; `start` is $1,000.
- **`ExplainerTests` additions**
  - `purchaseSentence`, P1: "Spending $700 on Fri Oct 2 takes checking down to $5 on Mon Oct 12." (NBSP)
  - `purchaseSentence`, workedExample book $20 today: "Spending $20 on Sat Sep 26 leaves checking at $830 on Mon Oct 5, its lowest point." (NBSP)
  - `purchaseSentence`, rentAndPay(900) desk $300 Oct 24: "Spending $300 on Sat Oct 24 takes checking down to \u{2212}$200 on Sun Nov 1." (NBSP)
  - `reading` for P1: $195, "below your $200 floor".
  - `belowFloorText` for P1: "Below your floor Mon Oct 5 to Wed Oct 14". (NBSP)
  - `earliestFitDate` for P1 is Thu Oct 15; `tryLabel` is "Try Thu Oct 15". (NBSP)
  - `ledger` reconciles: `start + rows + remainder == end.amount` for every fixture (P1: 1,000 + 800 - 750 - 700 - 300 - 45 = 5).
  - A plan with 7 movement groups yields a remainder labeled "Everything else, N items".
  - `roomCaption` for P1: "Spend up to this today and stay at or above your $200 floor through Wed Nov 25." (NBSP; horizon is today + 61).
- **`copyRules`** also scans every new function's output. It still bans U+2013 and U+2014, and asserts U+2212 and U+00A0 are allowed.
- **`MoneyTests`:** `displayText` and `spokenText` for -$450, $800 signed, and $45 with forceCents.
- **`LocalDateTests`:** `spokenText` and `weekdayName`.
- **`AppTests/TypographyTests`** (3.5).
- **`AppTests/QuestionSpansTests`:** "Can I buy a $700 laptop next Friday?" gives spans for "$700", "laptop" and "next Friday". Two amounts give no price span.
- **`AppLockTests`:** the default `biometry()` returns `.none`.
- **Optional UI test** `testEarliestDateButtonChangesTheVerdict`: tap `tryEarliestDate`, then assert the `verdict` label contains "Stays above your floor".

---

## 12. Deliberately not done, and why

1. **Draggable purchase cursor on the chart.** It competes with vertical scroll and back-swipe, and it was the largest single build risk. The date changes through the docked bar and the one-tap "Try" button. Long-press selection reads any day.
2. **Custom SF Symbol templates** (8 sets with 3 weight masters each). Replaced by Shape glyphs sized from font metrics. The Ask tab uses `chart.line.flattrend.xyaxis`. A custom "step over datum" tab symbol can follow once one template is drawn properly.
3. **`tabBarMinimizeBehavior(.onScrollDown)`.** After the smoke test scrolls Result, a minimized tab bar would hide the "Plan" button it taps. The what-if bar already floats above the tab bar.
4. **Range picker or horizontal chart scrolling.** A user-toggled window rescales Y and changes how severe the same dip looks. The fixed decision window always contains the lowest point, and the caption says so.
5. **In-chart dimension text** ("$195 below floor" beside the line). The reading above carries the number, keyed by the same glyph. Removing it keeps the busiest corner of the plot readable.
6. **Double Rule's worked sum on home, paper tint and serif.** The sum stacked $705 over $200 to $505 with no operator, which ledger convention reads as addition. The tinted paper and book serif sit next to the cream-serif and broadsheet tells. Only its register, sentence, glyph-as-Shape and NBSP ideas were taken.
7. **Forecast Low's weather frame, week columns and headroom fill.** The metaphor comes from another domain and adds chart chrome. Only its windowed Y domain, peel motion and below-floor words were taken.
8. **Docking the question in a bottom compose bar.** That would demote asking below the drawing. The question stays under the gauge, where it reads as "does this fit in that gap", and scroll-to-field keeps the Ask button above the keyboard.
9. **Count-up or animated numbers on appear.** A counting money figure is a gimmick. Numbers roll only when a user action changes them.
10. **A clearance mark on Plan, or a floor glyph in Plan rows.** Balance minus floor is not clearance, and the mark keeps one meaning. The Plan row glyph was the "one accessory" removed.
11. **Measured sheet detents.** A Form's content height cannot be measured reliably. The quote and source line fill the `.medium` detent instead.
12. **Capitalizing the item in `PurchaseDraft`.** The Item row shows the words exactly as read, matching the underlined word in the quote. Labels that start a phrase capitalize (title, "Laptop, Oct 2", ledger). The engine sentence avoids the item name, so there are no article or casing errors.
13. **Renaming the Ask tab** to Today or Forecast. "Ask" names the product's job, and the UI tests and muscle memory depend on it.
14. **Overpass italic, cut static instances, or named-instance font names.** The unmodified repo file is shipped, and weights come from the `wght` axis.
15. **Localized date formats.** The engine's English month and weekday arrays stay. Localization is a separate project.
16. **Any change to engine math, the 61-day horizon, the 30-day purchase range, or `Explainer.reasons` output.** Every new number comes from new pure functions built on the same projection.