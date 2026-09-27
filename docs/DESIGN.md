# Design

Headroom is a native iOS app, so Apple's Human Interface Guidelines are the base. On top of that sit the portable rules from [taste-skill](https://github.com/Leonxlnx/taste-skill) by Leonxlnx (its anti-slop color, type, copy, and state rules, plus the mobile and fintech guidance from its mobile variant). The skill itself says native mobile is outside its web scope and points to Apple's HIG, which is why the HIG comes first.

## Design read

Native iOS personal-finance utility for students, calm and trust-first. Apple HIG + iOS 26 Liquid Glass + SF Pro with rounded tabular numerals + one accent color.

## Dials

| Dial | Value | Why |
|---|---|---|
| DESIGN_VARIANCE | 4 | Native patterns, left-aligned, one strong focal number per screen |
| MOTION_INTENSITY | 3 | Native transitions only; numbers roll when they change |
| VISUAL_DENSITY | 3 | Airy; a money app should feel calm, not like a cockpit |

## Tokens (`App/DesignSystem/Theme.swift`, `App/Resources/Assets.xcassets`)

| Token | Light | Dark | Use |
|---|---|---|---|
| Accent (Evergreen) | `#1F6E54` | `#34A07A` | Every interactive element and the "fits" state |
| Canvas | `#F4F5F7` | `#0E0F11` | Screen background (cool off-white / off-black) |
| Surface | `#FCFCFD` | `#181A1D` | Content cards and list rows |
| Text primary | `#111315` | `#F1F2F4` | Body and titles |
| Text secondary | `#5A6068` | `#A3A9B1` | Captions and labels |
| Warning (amber) | `#9A6400` | `#E3A640` | "Would cross your cash floor" only |
| Danger (brick) | `#A8402D` | `#EF7B64` | "Known bills exceed projected cash" only |
| Chart baseline | `#9AA1A9` | `#5E656D` | The "without purchase" line |

All text colors meet WCAG AA against Canvas and Surface in both modes.

## Rules

- **Structure:** Liquid Glass tab bar (Ask, Plan, Settings), `NavigationStack`, sheets for editors. Glass only on the navigation and control layer; content sits on solid surfaces. No box-in-box, no stat-card grids, no three equal cards.
- **Color:** one accent. Status is always icon plus words, never color alone.
- **Type:** SF Pro with Dynamic Type. Money in SF Rounded with tabular digits. One large number per screen. Hierarchy through weight and color. Nothing smaller than footnote.
- **Shape lock:** 20 pt continuous corners for surfaces, capsules for buttons, native rows for inputs.
- **States:** composed empty state, inline errors under fields, a reading placeholder while on-device AI runs, needs-info screens that say exactly what to fix.
- **Motion:** numeric content transitions, chart eases between values, a light haptic when the verdict changes. All off under Reduce Motion.
- **Copy:** short and specific. Zero em or en dashes in UI text (the engine's strings are tested for it). At most one middle dot per line. No filler verbs. Button labels of one to three words, one label per intent.
- **Icons:** SF Symbols only.
- **Accessibility:** AA contrast in both modes, VoiceOver labels on the chart and verdict, layouts hold at XL Dynamic Type.

## Pre-flight before shipping

- [ ] Zero em or en dashes in any UI string
- [ ] One accent color everywhere
- [ ] Only the 20 pt radius and capsules
- [ ] Checked in light and dark
- [ ] XL Dynamic Type still readable
- [ ] VoiceOver reads the verdict and the chart summary
- [ ] Reduce Motion turns off transitions
- [ ] Empty, needs-info, and error states present
