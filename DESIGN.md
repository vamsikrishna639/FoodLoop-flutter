# FoodLoop Design System — "Canteen Token"

FoodLoop borrows the physical language of an Indian college canteen: paper token
slips, chalkboard menus, rubber stamps and printed receipts. Every food listing is
a **token slip**, every status is a **stamp**, every history is a **receipt**, and
the donor's posting area is a **chalkboard**.

This document is the single source of truth for the UI of the **Flutter**
frontend (Android and Web). It is implemented in:

| File | What it holds |
|---|---|
| `frontend/lib/core/theme/tokens.dart` | `FlSpace`, `FlRadius`, `FlMotion` constants and the `FoodLoopTokens` `ThemeExtension` (custom colours and text styles) |
| `frontend/lib/core/theme/app_theme.dart` | The two `ThemeData` objects (`AppTheme.paper`, `AppTheme.chalkboard`). The only file with raw palette colours (the one other `Color(0x…)` use is the black, alpha-only ink mask inside `StatusStamp`, which carries no hue) |
| `frontend/lib/core/responsive/breakpoints.dart` | Breakpoints, gutters, max content width |
| `frontend/lib/widgets/` | The signature components (section 6) |

Widgets never hard-code a colour, a font size or a duration. They read them from
the theme: `context.fl.chilliDeep` for custom tokens, `context.text.titleLarge`
for Material text styles, `FlSpace.lg`, `FlRadius.slip` and `FlMotion.base` for
the constants.

How this document was produced: the concept, palette and fonts are a fixed brief.
The `ui-ux-pro-max` skill was used to complete the system (states, scales,
accessibility rules, chart guidance) and to check it. Its generic style
suggestion (Swiss minimalism, Outfit / Work Sans, a red-on-pink palette) was
rejected because the brief takes priority. Its accessibility rules were kept, and
they changed three things in the palette (see "Contrast findings" in 1.4).

**Skill translation note.** `impeccable` and Emil Kowalski's skills use web
(HTML/CSS/React) examples. Their principles (hierarchy, typography, spacing,
colour, easing, duration, restraint) are applied here with Flutter APIs:
`ThemeData`, `ColorScheme`, `TextTheme`, `ThemeExtension`, `CustomClipper`,
`CustomPainter`, `AnimationController`, implicit animations, `Hero` and
`PageRouteBuilder`. No CSS or web code goes into the Flutter project.

---

## 1. Colors

### 1.1 Light theme — "paper"

| Token (`context.fl.…`) | Hex | Use |
|---|---|---|
| `paper` | `#F6F1E7` | App background (`scaffoldBackgroundColor`) |
| `surface` | `#FBF8F2` | Token slips, receipts, sheets, dialogs |
| `surfaceSunken` | `#EFE8DA` | Token stubs, input fills, table headers |
| `ink` | `#1E1B16` | Primary text, primary icon, ink buttons |
| `inkSoft` | `#6B6255` | Secondary text, captions |
| `line` | `#E3DACB` | Dividers, card outlines (decorative) |
| `perforation` | `#CFC4B2` | Perforation dots, dotted leaders (decorative) |
| `controlBorder` | `#8C8272` | Input and control outlines (must be 3:1) |
| `chilli` | `#D9472B` | Brand accent: large display, stamp borders, rings, urgency marks |
| `chilliDeep` | `#B93A21` | Chilli used as **text** or as a **button fill** |
| `onChilli` | `#FBF8F2` | Label colour on a `chilliDeep` button |
| `leaf` | `#2F6B3F` | Success, delivered, impact, veg marker |
| `onLeaf` | `#FBF8F2` | Label colour on a `leaf` fill |
| `turmeric` | `#E8A33D` | Highlight fill, "closing soon" ring. Never text on paper |
| `turmericDeep` | `#8A5A0B` | Turmeric used as **text** or a stamp |
| `onTurmeric` | `#1E1B16` | Ink text on a turmeric fill |
| `stampGrey` | `#6B6255` | EXPIRED and CANCELLED stamps |

The non-veg marker uses `chilliDeep`.

### 1.2 Dark theme — "chalkboard"

| Token | Hex | Use |
|---|---|---|
| `paper` | `#1F2422` | App background (slate) |
| `surface` | `#272D2A` | Token slips, receipts, sheets |
| `surfaceSunken` | `#1A1F1D` | Stubs, input fills |
| `ink` | `#ECE8DF` | Primary text (chalk white) |
| `inkSoft` | `#A9A397` | Secondary text |
| `line` | `#3A423E` | Dividers |
| `perforation` | `#4B544F` | Perforation dots, leaders |
| `controlBorder` | `#7C857F` | Input outlines |
| `chilli` | `#F0674B` | Brightened accent; also safe as text here |
| `chilliDeep` | `#F0674B` | Same as `chilli` in dark |
| `onChilli` | `#1E1B16` | Button label on chilli in dark |
| `leaf` | `#6FBF83` | Brightened green |
| `onLeaf` | `#1E1B16` | Label on a leaf fill |
| `turmeric` | `#F2B65A` | Brightened turmeric; safe as text here |
| `turmericDeep` | `#F2B65A` | Same as `turmeric` in dark |
| `stampGrey` | `#8E958F` | EXPIRED and CANCELLED stamps |

### 1.3 Chalkboard block (same in both themes)

The donor's "Today's Surplus" block and the desktop sidebar are always dark.

| Token | Hex |
|---|---|
| `board` | `#232927` |
| `boardFrame` | `#3A2E22` (wooden frame edge) |
| `chalk` | `#ECE8DF` |
| `chalkSoft` | `#A9A397` |
| `chalkLine` | `#3A423E` |

### 1.4 Contrast findings (WCAG AA)

Measured ratios; text needs 4.5:1 and non-text 3:1.

| Pair | Ratio | Result |
|---|---|---|
| ink on paper | 15.25 | pass |
| inkSoft on paper / surface / sunken | 5.32 / 5.65 / 4.92 | pass |
| **chilli `#D9472B` on paper** | **3.82** | **fails for text** → use `chilliDeep` for text |
| **white on chilli `#D9472B`** | **4.30** | **fails for button labels** → button fill is `chilliDeep` |
| chilliDeep on paper; surface on chilliDeep | 5.06; 5.37 | pass |
| leaf on paper; surface on leaf | 5.66; 6.01 | pass |
| **turmeric on paper** | **1.92** | **fails** → turmeric is a fill only; text uses `turmericDeep` (5.26) |
| ink on turmeric | 7.96 | pass (turmeric chips carry ink text) |
| line / perforation on paper | 1.23 / 1.53 | decorative only, never the sole boundary of a control |
| controlBorder on paper | 3.36 | pass for control outlines |
| chalk on slate; inkSoft on dark surface | 12.88; 5.60 | pass |
| dark chilli / leaf / turmeric on dark surface | 4.51 / 6.32 / 7.77 | pass |
| ink on dark chilli (button label) | 5.51 | pass |

Rules that follow:
- `chilli` is the *brand* red. Anything a user must **read** in red uses `chilliDeep`.
- Turmeric never carries meaning as text on paper.
- Status is never colour-only: stamps always contain a word, the deadline ring
  always has a time label, veg markers have a shape and a semantic label.

### 1.5 How the tokens reach the code (Flutter)

1. `app_theme.dart` holds one private `_Palette` per theme (paper and chalkboard).
   Raw hex values exist only there.
2. `_build()` turns a palette into a `ThemeData` (Material 3, `useMaterial3`):
   a `ColorScheme`, a `TextTheme`, and component themes (buttons, inputs, chips,
   bottom sheets, dialogs, snackbars, tooltips, switches, page transitions).
3. Everything Material cannot hold (the accents, the chalkboard colours, the mono
   and impact text styles) lives in the `FoodLoopTokens` `ThemeExtension`, read
   with `context.fl`. Its `lerp` swaps instantly at the halfway point, so the
   two themes never blend into muddy in-between colours.
4. `ThemeProvider` (provider package) holds the paper / chalkboard choice and
   passes it to `MaterialApp.theme` and `darkTheme`. The toggle is in Profile
   and settings. The choice is saved, so it is restored on app start.
5. The slip snackbar is ink-coloured (dark on paper, light on the chalkboard), so
   its DONE / NOT DONE marks use the opposite theme's accents to stay above 4.5:1.

---

## 2. Typography

Loaded with the `google_fonts` package.

| Family | Role | Flutter call |
|---|---|---|
| **Bricolage Grotesque** | Display and headings | `GoogleFonts.bricolageGrotesque` |
| **Instrument Sans** | Body and UI | `GoogleFonts.instrumentSans` |
| **JetBrains Mono** | Token numbers, times, quantities, receipts, stamps | `GoogleFonts.jetBrainsMono` (tabular figures on) |

Inter, Roboto, Poppins and Montserrat are not used.

The scale is deliberately steep: the jump from body (16) to headline (32) to
impact number (72–96) is what makes screens look editorial instead of uniform.

| Style | Where it lives | Font | Size / line height | Weight | Tracking | Use |
|---|---|---|---|---|---|---|
| `impact` | `context.fl.impact` | Bricolage | 72 default / 0.95; the screen passes its own size (96 admin feature block, 64 volunteer, 44 small figures) | 800 | -2.0 | ImpactNumber |
| `displayLarge` | `TextTheme` | Bricolage | 56 / 1.0 | 800 | -1.5 | Onboarding headline |
| `displayMedium` | `TextTheme` | Bricolage | 44 / 1.05 | 700 | -1.0 | Screen hero titles (desktop) |
| `displaySmall` | `TextTheme` | Bricolage | 36 / 1.1 | 700 | -0.8 | Screen titles (mobile) |
| `headlineMedium` | `TextTheme` | Bricolage | 28 / 1.15 | 700 | -0.5 | Section titles |
| `headlineSmall` | `TextTheme` | Bricolage | 22 / 1.2 | 700 | -0.3 | Token title, dialog title |
| `titleLarge` | `TextTheme` | Bricolage | 19 / 1.25 | 600 | -0.2 | Card titles |
| `titleMedium` | `TextTheme` | Instrument | 16 / 1.35 | 600 | 0 | List titles, field labels |
| `titleSmall` | `TextTheme` | Instrument | 14 / 1.35 | 600 | 0.1 | Small headings |
| `bodyLarge` | `TextTheme` | Instrument | 16 / 1.5 | 400 | 0 | Body |
| `bodyMedium` | `TextTheme` | Instrument | 14 / 1.5 | 400 | 0 | Secondary body |
| `bodySmall` | `TextTheme` | Instrument | 12.5 / 1.45 | 400 | 0.1 | Captions (`inkSoft`) |
| `labelLarge` | `TextTheme` | Instrument | 15 / 1.2 | 600 | 0.1 | Buttons |
| `labelMedium` | `TextTheme` | Instrument | 13 / 1.2 | 600 | 0.2 | Chips, nav labels |
| `labelSmall` | `TextTheme` | Instrument | 12.5 / 1.2 | 600 | 0.3 | Small labels (`inkSoft`) |
| `monoLarge` | `context.fl` | JetBrains | 18 / 1.3 | 700 | 0 | Token number |
| `mono` | `context.fl` | JetBrains | 13.5 / 1.4 | 500 | 0 | Quantities, times, receipt rows |
| `monoSmall` | `context.fl` | JetBrains | 11.5 / 1.3 | 500 | 0.6 | Captions under numbers, overlines (uppercase) |
| `stamp` | `context.fl` | JetBrains | 12 / 1.0 | 800 | 1.6 | Stamp text (uppercase) |

Rules: body text is never below 12.5; numbers that change (countdowns, counters)
use mono with tabular figures (`FontFeature.tabularFigures()`) so they do not
shift; text wraps before it truncates, and titles truncate at two lines
(`maxLines: 2`, `TextOverflow.ellipsis`). Layouts must still work when the user
raises the system text size.

---

## 3. Spacing, radii, elevation

**Spacing** (`FlSpace`, 4-point rhythm): `xxs 2`, `xs 4`, `sm 8`, `md 12`, `lg 16`,
`xl 24`, `xxl 32`, `xxxl 48`, `huge 72`.
Page gutters (`Breakpoints.gutter`): 16 mobile, 24 tablet, 40 desktop.
Section gap: 32 mobile, 48 desktop.

**Radii** (`FlRadius`) vary by object, on purpose. A uniform radius is what makes
UIs look templated:

| Token | Value | Object |
|---|---|---|
| `sharp` | 2 | Receipts, chalkboard, table cells (printed things are square) |
| `stamp` | 4 | Stamps, veg markers, mono chips, tooltips |
| `control` | 6 | Buttons, inputs |
| `slip` | 10 | Token slips |
| `sheet` | 20 | Bottom sheet top corners, dialogs |
| `pill` | 999 | Filter chips, user chip |
| `notch` | 9 | Radius of the semicircle cut-outs on a token slip |

**Elevation** is ink and paper, not blur. There are three levels:

| Level | Treatment (`BoxDecoration`) | Use |
|---|---|---|
| 0 flat | 1px `line` border, no shadow | Slips, receipts, tables at rest |
| 1 lifted | border plus a short soft shadow offset 0,4 in `ink` at 10–16% (slips paint it with `MaskFilter.blur` sigma 6 so it follows the notches; the raised nav action uses a `BoxShadow` blur 10 at 16%) | Hovered or selected slip, raised nav action |
| 2 floating | Snackbar slip: `BoxShadow` offset 0,10, blur 24, `ink` at 18%. Dialogs and bottom sheets use Material's own elevation with the `ink` shadow colour from the `ColorScheme` | Dialogs, sheets, snackbar slips |

No glassmorphism (no `BackdropFilter` blur), no glows, no gradients except the
faint chalk dust on the board.

---

## 4. Motion

Motion must confirm an action, show where something came from, or draw attention
to a change. If it does none of these it is removed.

| Token (`FlMotion`) | Value | Use |
|---|---|---|
| `fast` | 120ms | Press feedback, hover, chip colour, side-panel swap, page fade back |
| `base` | 200ms | Most transitions: page fade in (and the Hero that rides on it), `FadeUp` items, `FadeIn` |
| `slow` | 280ms | Onboarding slide change (its only use) |
| `stagger` | 40ms per item; items after the 6th start together (`FadeUp.maxStaggered`) | First-load list entrance only (`FadeUp`: 200ms fade plus an 8px rise) |
| `count` | 900ms | ImpactNumber count-up |
| `stampDrop` | 420ms | The approve stamp (signature moment, used once) |
| `easeOut` | `Cubic(0.23, 1, 0.32, 1)` | Default: things arriving |
| `easeInOut` | `Cubic(0.77, 0, 0.175, 1)` | Things moving from one place to another |
| `stampCurve` | `Cubic(0.2, 0.9, 0.3, 1.15)` | Stamp settle with a very small overshoot |

- No bouncy springs on everyday UI. Exits are faster than entrances.
- Press feedback (`Pressable` widget) scales to 0.98 on slips and buttons, with
  no layout shift.
- Animate only transform and opacity (`Transform`, `FadeTransition`,
  `AnimatedOpacity`). Never animate layout-affecting size on lists.
- **Stamp drop** (`StampDrop` widget): the APPROVED stamp starts at scale 1.9,
  opacity 0, rotated an extra -10°, and lands at scale 1 and the stamp's own -6°
  (`FlMotion.stampDrop` with `stampCurve`), with `HapticFeedback.lightImpact()`
  on mobile. Used only when a donor approves a claim.
- **Hero:** the TokenCard flies to the listing detail on phones. On tablet and
  desktop the detail opens in a side panel instead, which swaps tokens with a
  120ms fade only (it is switched often).
- **Stagger:** list items fade up on first load only, not on every rebuild.
- **Reduced motion:** read with `MediaQuery.disableAnimations`, through two
  helpers so no widget decides on its own:
  - `FlMotion.of(context, d)` returns zero when reduced motion is on. Use it for
    anything that MOVES or SCALES: the stagger rise, the count-up, the Hero
    flight, the press scale, bottom-sheet slides and the stamp's fall and turn.
  - `FlMotion.fade(context, d)` caps a pure opacity fade at `fast` (120ms).
    Reduced motion means gentler, not none: a short fade still tells the eye that
    something changed. List items fade in together, page and panel cross-fades
    stay, and the APPROVED stamp fades in at rest.
- **Frequency:** things tapped many times a day (navigation tabs, radio choices)
  change instantly; the page cross-fade is their only motion. Filter chips change
  colour only.
- **Page transitions:** every `go_router` page, including the phone listing
  detail, is a `CustomTransitionPage` with an opacity-only cross-fade (200ms in,
  120ms back, `easeOut`). Because it only fades, it stays under reduced motion.
  The phone Hero flies on top of that route. The theme also sets
  `FadeForwardsPageTransitionsBuilder` for Android, which only affects routes
  pushed outside `go_router`.
- Use `FlMotion.topLeft` / `topRight` as the `layoutBuilder` of an
  `AnimatedSwitcher` so a narrower new child does not start in the centre and
  jump.

---

## 5. Component states

Every interactive component defines all of these states.

| State | Treatment |
|---|---|
| Default | As specified |
| Hover (web, desktop) | Slip lifts to elevation 1 and the outline darkens to `controlBorder`; buttons darken about 10%; cursor becomes `SystemMouseCursors.click` |
| Pressed | `Pressable` scales to 0.98 on slips and buttons (transform only, off under reduced motion) |
| Focused | `Pressable` draws a 2px `ink` ring on the element's own edge (no offset), in front of the content so it is never clipped. On the dark board (sidebar, rail) the ring is 3px `turmeric`. Inputs show a 2px ink edge instead. Never removed; keyboard users must see it |
| Disabled | Buttons become a sunken paper slot (`surfaceSunken` fill, `controlBorder` outline, `inkSoft` label), never a faded fill. The Admin role slip is 60% opacity with "Not here" printed on it |
| Loading | Button keeps its size and colour and is disabled; the label is replaced by a short loading label whose three dots print one by one ("Signing in.", "..", "..."), in the button's own font. The dots stay still under reduced motion |
| Error | `chilliDeep` border, a small mono message in `chilliDeep` below the field with a warning icon, announced by a semantic label |
| Selected | Ink fill with paper text for chips; a stamp-style check for role slips |

Minimum tap target is 48×48 logical pixels (`minimumSize` in the button themes,
`ConstrainedBox` on icon buttons). Targets are at least 8 apart.

### Buttons (`FlButton`)
- **Primary (ink):** `ink` fill, `paper` label. The default action on most screens.
- **Accent (chilli):** `chilliDeep` fill, `onChilli` label. Reserved for the
  single most important action on a screen (Request food, Post food).
- **Outline:** 1.5px `ink` border, ink label.
- `FlButton` has exactly these three variants. Low-emphasis actions use a plain
  Material `TextButton`, themed with an ink label, a 48×48 minimum and no
  underline.
- Minimum height 48 for every button (`minimumSize` in the button themes), radius
  `FlRadius.control`, label `labelLarge`. Tappable pickers in forms (the
  date-time fields) are 52 tall.

### Inputs
`InputDecorationTheme`: sunken fill `surfaceSunken`, 1px `controlBorder`, radius
`FlRadius.control`, 16px text (so phones do not zoom in on web), a visible label
above the field (never placeholder-only), helper or error text below. Validation
runs on blur and on submit, and on every change while a field shows an error.
Password fields have a show/hide toggle with a semantic label.

---

## 6. Signature components

All live in `frontend/lib/widgets/` and are shown on the component gallery
screen (`/gallery`).

### TokenCard (`token_card.dart`, `paper_shapes.dart`)
The food listing. A slip of `surface` paper with:
- A semicircle notch cut from each side. A `CustomClipper` (a `Path` with two
  arcs of radius `FlRadius.notch`) clips the slip, and a matching
  `CustomPainter` draws the 1px outline so the outline follows the notches. The
  notches sit on the perforation line.
- **Top:** a 68px ticket block on the left; beside it the veg marker (with its
  label), the StatusStamp in the top-right corner (it wraps below the marker on
  very narrow cards), the title (`headlineSmall`, max 2 lines) and the donor name.
- **Perforation:** a dotted line in `perforation`.
- **Stub:** `surfaceSunken`, with the token number (`monoLarge`, e.g. `#FL-0042`),
  PortionMeter and DeadlineClock. Completed and expired tokens show no clock (the
  stamp already says so) and print their title in `inkSoft`. The stub is 84px tall
  and grows with the system text size (up to 132), so the notches always sit on
  the perforation.
- **Ticket block, with no image** (the normal case): a printed square tinted with
  the food-type colour (`leaf`, `chilliDeep` or `turmericDeep` at 12%, with a 45%
  border), a small "TOKEN" caption rule, and the dish's two initials ("CB" for
  Chicken Biryani) in Bricolage `headlineMedium`. A photo replaces it when
  `imageUrl` is set; a slow or broken image falls back to the printed block.
- **Selected** (the token open in the side panel): an `ink` outline and the lifted
  shadow.
- Wrapped in `Hero` (tag from the listing id) for the phone detail transition.
  There is no Hero under reduced motion.

### PortionMeter (`portion_meter.dart`)
A row of small 12px icons, one per portion: circles (plates) when the unit is
plates, rounded squares (boxes) for boxes and packets. A free portion is an
outline; a reserved one is inked in solid. Up to 12 portions are drawn as icons.
Above 12, and always for `kg` (a weight, not a count), it shows a 10-segment bar
instead. The mono line "18 / 20 PLATES LEFT" is printed under the icons or the
bar in every case. It always carries a `Semantics` label such as "18 of 20 plates
left". An `onDark` variant draws in chalk for the chalkboard.

### DeadlineClock (`deadline_clock.dart`)
A 40px circular ring (`CustomPainter`) like a kitchen timer, with a knob tick at
12 o'clock. Beside it are the time left in mono ("3h 05m", "45m", "50s") and a
one-word caption under it: LEFT, CLOSING (under 1 hour) or HURRY (under 15
minutes). The ring is full at 6 hours or more and never drops below a 4% sliver.
Ink by default, turmeric under 1 hour, chilli under 15 minutes (the text uses
`turmericDeep` / `chilliDeep` on paper), and a crossed-out EXPIRED stamp after.
It updates every 20 seconds, every second in the last minute, and stops once
expired. An `onDark` variant draws in chalk.

### StatusStamp (`status_stamp.dart`)
Uppercase mono text (`fl.stamp`) in a 2px rounded rectangle border
(`FlRadius.stamp`), rotated -6° by default (`Transform.rotate`; the angle and a
`scale` can be passed). The uneven ink is a `ShaderMask` with a diagonal
alpha-only gradient (100% / 82% / 100% / 77% / 95%). Colours: AVAILABLE `leaf`,
RESERVED `turmericDeep`, PENDING `inkSoft`, APPROVED `leaf`, REJECTED
`chilliDeep`, CANCELLED `stampGrey`, ASSIGNED `ink`, PICKED UP `ink`, DELIVERED
`leaf` with a double border, COMPLETED `leaf` (a listing that has been fully
handed out), EXPIRED `stampGrey` crossed out with a diagonal line.
`StatusStamp.custom` prints any word as a stamp (for example the role stamp
"DONOR" in Profile).

### StampDrop (`stamp_drop.dart`)
The signature animation wrapper (section 4). Wraps a StatusStamp. Used only for
claim approval.

### ReceiptTimeline (`receipt_timeline.dart`)
A printed receipt on `surface`: zigzag torn top and bottom edges (a
`CustomClipper`; each tooth is about 12px wide and 6px deep) with a 1px `line`
outline painted along the zigzag. At the top are the title (`titleLarge`) and a
mono line with the receipt type and token number ("REQUEST RECEIPT  #FL-0003"),
with an optional StatusStamp beside the title so a long title wraps instead of
running under it. Then come a dashed rule and the rows: mono text, with dotted
leaders between label and time ("Requested ........ 12:40 PM"). The current step
can be bold. Steps that have not happened yet are printed in `inkSoft` with
"--:--". An optional uppercase footer sits under a second rule.

### Chalkboard (`chalkboard.dart`)
Always-dark `board` surface (radius `sharp`) with a 6px wooden frame
(`boardFrame`). The heading is in `headlineMedium` chalk, with an optional
trailing action beside it and a hand-drawn wavy underline in `turmeric` (160px)
under it. An optional uppercase mono caption (a date or a count) sits below the
underline, never as a label above the heading. Items are listed like a menu
board (`ChalkItem`): the dish name in `titleLarge` chalk (up to 62% of the line,
with an optional small note under it), a dotted chalk leader, and the quantity in
bold mono at the right edge.

### ImpactNumber (`impact_number.dart`)
A very large Bricolage number with a small uppercase mono caption. Counts up from
0 (`TweenAnimationBuilder`, `FlMotion.count`) the first time a figure appears in a
session; on later visits it starts from the value it last showed, so it stands
still, or counts only what was added. No count-up under reduced motion. Numbers
use Indian digit grouping (`en_IN`: 1,24,000), can carry a smaller suffix (" kg"),
and shrink to fit (`FittedBox`) rather than overflow on narrow screens.

### VegMarker (`veg_marker.dart`)
The Indian food marking: a green square outline with a green dot (veg), a red
square outline with a red (`chilliDeep`) triangle (non-veg). Mixed shows both
markers side by side. It can print its label ("VEG", in `monoSmall`) beside the
marker, and has a `Semantics` label ("Veg food").

### Slip snackbar (`slip_snackbar.dart`)
Feedback appears as a small printed slip: `ink` background, mono text, and a small
boxed word (DONE, NOT DONE, or NOTE for plain information) so the result never
depends on colour. Shown through a floating `SnackBar` with a transparent
background (set in the theme) for 4 seconds; a fixed 420px wide on screens 600px
and wider. It is a live region, so screen readers announce it.

### SkeletonToken (`skeleton_token.dart`)
A loader in the exact shape of a TokenCard (same notches and stub height) with a
slow opacity pulse (1.1s, 45% to 100%, static when reduced motion is on). No
spinners for content.

### EmptyState (`empty_state.dart`)
A simple illustration drawn with Flutter shapes (`CustomPainter` or icons: an
empty plate, a clear counter, a blank slip), a warm specific line of copy ("The
counter's clear. Check back after lunch service."), and one action. Error states
use the same layout with a retry button.

### Other shared widgets
`FadeUp` and `FadeIn` (first-load entrance), `Pressable` (press scale),
`FilterTag` (filter chips), `QuantityStepper` (capped at available),
`BrandMark`, `PageFrame`, `ActivityRail` (desktop right rail), `DeliveriesChart`.

---

## 7. Layout

One `ResponsiveShell` (`responsive_shell.dart`), three breakpoints, mobile first.
`Breakpoints.of(context)` returns a `ScreenSize`; `context.isMobile` and
`context.isDesktop` are shortcuts.

| `ScreenSize` | Width | Navigation | Content |
|---|---|---|---|
| `mobile` | `< 600` | Bottom bar (68px) with a raised centre action ("Post food" for donor, "Browse" for recipient) | One column; forms are bottom sheets (`showModalBottomSheet`) |
| `tablet` | `600–1024` | Dark navigation rail (92px), icons over labels | Two columns; detail opens as a side panel next to the list |
| `desktop` | `> 1024` | Menu-board sidebar (248): logo, nav, user chip | Main area plus a right activity rail (304); sidebar, content and rail together are at most 1320 wide (`Breakpoints.maxContent`), left-aligned; dialogs (`showDialog`) instead of sheets |

Rules:
- Use `MediaQuery.sizeOf` or `LayoutBuilder`, never `MediaQuery.of`, so screens
  rebuild only when the size changes.
- Gutters: 16 / 24 / 40 (`Breakpoints.gutter`).
- Use `SafeArea`; the bottom bar respects the system inset.
- No overflow errors at 360, 768 or 1440 px wide. Prefer `Wrap`, `Flexible`,
  `Expanded` and `maxLines` over fixed widths.
- Bottom sheets on mobile, dialogs on tablet and desktop. Each form's opener
  (the listing form, the volunteer-assignment form) checks `context.isMobile` to
  choose.

Screens differ on purpose:
- **Recipient feed ("Today's Counter")** — a counter of token slips under a large title.
- **Donor dashboard** — a chalkboard block above a queue of requests.
- **Volunteer** — receipt-led pickup cards with one large action.
- **Admin** — asymmetric: one large impact block, a chart, then a table on
  desktop (cards on mobile).

Never four identical stat cards in a row. Never centred-everything.

---

## 8. Charts (`fl_chart`)

The 7-day deliveries chart (`DeliveriesChart`, `BarChart` from `fl_chart`) is
styled with theme tokens, not the library defaults: `leaf` bars with square tops
(`BorderRadius.zero`), today's bar in `chilli`, mono axis labels
(`context.fl.monoSmall`), dotted `perforation` grid lines, and the value printed
directly above each bar so the chart does not depend on colour or hover. Chart
animation is off (or `FlMotion.base`, and zero under reduced motion). A
`Semantics` label gives screen readers a text summary of the seven values.

---

## 9. Accessibility checklist

- Text contrast 4.5:1, non-text 3:1, in both themes (table in 1.4).
- Tap targets 48×48 minimum.
- Every icon-only control has a tooltip and a `Semantics` label.
- Status is always a word as well as a colour.
- Focus is visible on every control; focus order follows visual order.
- Text scales with the system setting; layouts wrap instead of clipping.
- Reduced motion is respected (`MediaQuery.disableAnimations`).

## 10. Banned

Purple or blue gradients, glassmorphism, neon glows, stock-illustration heroes,
four identical stat cards with an icon in a coloured circle, default Material
blue, uniform 8px radius everywhere, emoji as icons, centred-everything layouts.
Inter, Roboto, Poppins and Montserrat.

## 11. Verification

After each screen is built: run `flutter analyze` (and the Dart MCP) and fix
every warning; run the Flutter web build and take Playwright screenshots at 360,
768 and 1440 px wide, in both paper and chalkboard modes; check overflow,
spacing, contrast and that the screen still reads as "Canteen Token".
