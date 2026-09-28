# Design

Headroom is a native iOS app, so Apple's Human Interface Guidelines are the base. On top of that sit the portable rules from [taste-skill](https://github.com/Leonxlnx/taste-skill) by Leonxlnx (its anti-slop color, type, copy, and state rules, plus the mobile and fintech guidance from its mobile variant). The skill itself says native mobile is outside its web scope and points to Apple's HIG, which is why the HIG comes first.

The full redesign spec, with every measurement and the reasoning behind it, is in [REDESIGN-SPEC.md](REDESIGN-SPEC.md). This page is the short version: the rules to keep.

## The idea: Datum

Headroom is drawn as a surveyor's section drawing of the weeks ahead. Your balance is the profile, your cash floor is the datum (a dashed line, the same one in the app icon), and the app measures one thing: **clearance**, the distance between your lowest projected balance and your floor.

That distance is dimensioned the way a draftsman would: a vertical line with a 45 degree slash tick at each end. It is drawn at true scale in the chart, and the same mark sits beside the big number, so you can see why the number is what it is.

| Mark | Means, everywhere |
|---|---|
| Ring | The lowest point |
| Dashed rule | Your floor |
| Vertical line with slash ticks | Clearance, measured to the floor (to $0 when below $0) |
| Solid thin rule | $0 |

The clearance mark only ever measures from the low to the floor. Plan does not get one, because balance minus floor is not clearance.

## Type

- **Overpass** for readings: every amount in a column or on its own, the big readings ("$505", "$195 below your $200 floor"), chart labels, the verdict line, and titles. Overpass is the libre cut of Highway Gothic, the lettering on low-clearance road signs, which tell drivers how much headroom they have. It ships as the unmodified variable font from Google Fonts under the SIL Open Font License 1.1 and is credited in Settings > Acknowledgments. Weights come from the `wght` axis, and every run asks for tabular figures.
- **SF Pro** for instructions: every sentence, caption, list label, footer, button, and system control.
- Overpass never sits inside an SF sentence. Amounts inside sentences stay SF.
- Fonts are built in one place, `App/DesignSystem/Typography.swift`. CI fails if Overpass is built anywhere else.
- Every role scales with Dynamic Type, and Bold Text adds 100 to every Overpass weight. Nothing is smaller than footnote (13 pt).
- Money shows a true minus sign (U+2212) and a non-breaking space inside dates, so "Tue Oct 13" never splits across lines.

## Tokens (`App/DesignSystem/Theme.swift`, `App/Resources/Assets.xcassets`)

| Name | Token | Light | Dark | Use |
|---|---|---|---|---|
| Paper | `Theme.canvas` | `#F3F5F6` | `#000000` | Every screen background |
| Plate | `Theme.surface` | `#FFFFFF` | `#1C1C1E` | The question field and the chart callout only |
| Ink | `Theme.textPrimary` | `#101417` | `#F2F4F5` | Text, every figure, the balance path, the datum |
| Graphite | `Theme.textSecondary` | `#525B64` | `#A1A9B1` | Secondary text, chart labels, list headers and footers |
| Rule | `Theme.chartBaseline` | `#78818A` | `#6F7880` | The without-purchase line and ruler ticks. Never text |
| Evergreen | `Theme.accent` | `#1F6E54` | `#4CB891` | Things you can tap, and "stays above your floor" |
| Amber | `Theme.warning` | `#8F5D00` | `#E5A843` | "Dips below your floor", and a stale balance |
| Brick | `Theme.danger` | `#A33E2B` | `#F07F68` | "Takes checking below $0", and field errors |
| On Accent | `Theme.onAccent` | `#FFFFFF` | `#000000` | Labels on prominent Evergreen buttons |

With Increase Contrast on, Graphite, Rule, Evergreen, and Amber switch to darker (light) or lighter (dark) variants, and the question field and what-if capsules gain a 1 pt outline.

Every text pair meets WCAG AA (4.5:1) in light and dark, and every meaningful graphic meets 3:1. `AppTests/ContrastTests.swift` checks the one computed fill ("Try Fri Oct 16").

## Rules

- **Structure:** Liquid Glass tab bar (Ask, Plan, Settings), `NavigationStack`, sheets for editors.
- **Glass only on the control layer:** the tab bar, toolbars, the what-if bar on Result, and prominent buttons. Sheets show the system glass at partial height.
- **Surfaces:** Plate exists only for the question field and the chart callout. Result has no cards: the verdict, reading, chart, and ledger sit directly on Paper. Plan and Settings use native inset-grouped lists.
- **Shapes:** capsules for every button, 20 pt continuous corners for the two Plate surfaces, and the system geometry for lists and forms.
- **Color:** one accent. Status is always a glyph shape plus words plus tint, never color alone. The only status fill is the hatched below-floor area in the chart.
- **Icons:** SF Symbols, plus the Shape glyphs in `App/DesignSystem/Glyphs.swift` (the clearance mark, verdict glyphs, datum rule, low ring, and the empty-state drawing). Glyphs are sized from the font's cap height and hidden from VoiceOver.
- **Touch targets:** at least 44 x 44 pt.
- **Motion:** one orchestrated moment. When a result first appears, the with-purchase line peels down from the without line by exactly the price, then the clearance mark opens like a caliper. Every frame lies between two real engine states. Anything else moves only in answer to a tap. Reduce Motion shows the finished drawing at once.
- **Copy:** short and specific. Zero em or en dashes and no middle dots in any Swift source (CI checks). No filler verbs. Button labels of one to three words, one label per intent.
- **Privacy:** the lock cover and app-switcher snapshot sit in their own window above every sheet, and show only the wordmark and datum.

## Verdicts

| Verdict | Glyph | Tint |
|---|---|---|
| Stays above your floor | A step that stays above the datum | Evergreen |
| Stays at your floor | Same | Evergreen |
| Dips below your floor | A step that dips through the datum | Amber |
| Takes checking below $0 | A step that drops below a solid $0 line | Brick |
| Already dips below your floor, or Checking already goes below $0 | For a plan that is short even without the purchase. The glyph and tint follow what the purchase does | Amber or Brick |
| Add a few details first | The datum alone | Graphite |

## Pre-flight before shipping

- [ ] Zero em or en dashes and no middle dots in any Swift source (CI)
- [ ] Overpass built only in `Typography.swift` (CI)
- [ ] One accent color everywhere
- [ ] Only capsules and the 20 pt radius
- [ ] Checked in light and dark
- [ ] Checked at default, XXXL, AX3, and AX5 Dynamic Type (`xcrun simctl ui booted content_size accessibility-extra-large`, then `accessibility-extra-extra-extra-large`)
- [ ] Checked with Increase Contrast and Bold Text
- [ ] VoiceOver reads the verdict, the reading, and the chart summary, and amounts say "minus" and "plus"
- [ ] Reduce Motion shows the finished drawing with no transitions
- [ ] Empty, stale balance, needs-info, and error states present
