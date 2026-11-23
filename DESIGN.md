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
| `frontend/lib/core/theme/app_theme.dart` | The two `ThemeData` objects (`AppTheme.paper`, `AppTheme.chalkboard`). The only file with raw hex colours |
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
| `impact` | `context.fl.impact` | Bricolage | 72 (scale up to 88 tablet / 96 desktop in the widget) / 0.95 | 800 | -2.0 | ImpactNumber |
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
| 1 lifted | border plus a short soft `BoxShadow` (offset 0,4; blur 10; `ink` at 10%) | Hovered slip (web and desktop), raised nav action |
| 2 floating | `BoxShadow` (offset 0,12; blur 32; `ink` at 14%) | Dialogs, sheets, snackbar slips |

No glassmorphism (no `BackdropFilter` blur), no glows, no gradients except the
faint chalk dust on the board.

---

## 4. Motion

Motion must confirm an action, show where something came from, or draw attention
to a change. If it does none of these it is removed.

| Token (`FlMotion`) | Value | Use |
|---|---|---|
| `fast` | 120ms | Press feedback, hover |
| `base` | 200ms | Most transitions: fades, chip selection |
| `slow` | 280ms | Page and Hero transitions, sheets |
| `stagger` | 40ms per item, capped at 8 items | First-load list entrance only (`FadeUp`) |
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
- **Page transitions:** `FadeForwardsPageTransitionsBuilder` on Android; custom
  `PageRouteBuilder` only for the Hero detail page.
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
| Focused | 2px `ink` outline with a 2px offset (chalk on the board). Inputs show a 2px ink edge instead. Never removed; keyboard users must see it |
| Disabled | Buttons become a sunken paper slot (`surfaceSunken` fill, `controlBorder` outline, `inkSoft` label), never a faded fill. The Admin role slip is 60% opacity with "Not here" printed on it |
| Loading | Button keeps its width; the label is replaced by a small mono "..." ticker and the button is disabled |
| Error | `chilliDeep` border, a small mono message in `chilliDeep` below the field with a warning icon, announced by a semantic label |
| Selected | Ink fill with paper text for chips; a stamp-style check for role slips |

Minimum tap target is 48×48 logical pixels (`minimumSize` in the button themes,
`ConstrainedBox` on icon buttons). Targets are at least 8 apart.

### Buttons (`FlButton`)
- **Primary (ink):** `ink` fill, `paper` label. The default action on most screens.
- **Accent (chilli):** `chilliDeep` fill, `onChilli` label. Reserved for the
  single most important action on a screen (Request food, Post food).
- **Outline:** 1.5px `ink` border, ink label.
- **Text:** ink label with an underline on hover.
- Height 48 (52 on mobile primary actions), radius `FlRadius.control`, label
  `labelLarge`.

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
- **Top:** veg marker, title (`headlineSmall`), donor name, StatusStamp in the
  top-right corner.
- **Perforation:** a dotted line in `perforation`.
- **Stub:** `surfaceSunken`, with the token number (`monoLarge`, e.g. `#FL-0042`),
  PortionMeter and DeadlineClock.
- **With no image** (the normal case): the top section shows a "ticket block", a
  food-type tinted panel with a large mono initial of the dish. A photo is the
  exception, so an empty `imageUrl` never leaves a hole.
- A compact variant drops the ticket block for dense lists.
- Wrapped in `Hero` (tag from the listing id) for the phone detail transition.

### PortionMeter (`portion_meter.dart`)
A row of small plate icons that fill as portions are reserved. Up to 12 portions
are drawn as icons; above that it collapses to mono text "18 / 20 left" with a
thin segmented bar. Always carries a `Semantics` label such as "18 of 20 plates
left".

### DeadlineClock (`deadline_clock.dart`)
A circular ring (`CustomPainter`) like a kitchen timer, with the time left in
mono beside or inside it. The ring spans up to 6 hours. Ink by default, turmeric
under 1 hour, chilli under 15 minutes, and a crossed-out EXPIRED stamp after.
Updates once a minute (once a second in the last minute).

### StatusStamp (`status_stamp.dart`)
Uppercase mono text in a rounded rectangle border (`FlRadius.stamp`), rotated -6°
(`Transform.rotate`), with slightly uneven opacity. Colours: AVAILABLE `leaf`,
RESERVED `turmericDeep`, PENDING `inkSoft`, APPROVED `leaf`, REJECTED
`chilliDeep`, CANCELLED `stampGrey`, ASSIGNED `ink`, PICKED UP `ink`, DELIVERED
`leaf` with a double border, EXPIRED `stampGrey` crossed out.

### StampDrop (`stamp_drop.dart`)
The signature animation wrapper (section 4). Wraps a StatusStamp. Used only for
claim approval.

### ReceiptTimeline (`receipt_timeline.dart`)
A printed receipt: zigzag torn top and bottom edges (a `CustomClipper` with a
12px tooth), mono text, dotted leaders between label and time ("Requested
........ 12:40 PM"). Steps that have not happened yet are printed in `inkSoft`
with "--:--".

### Chalkboard (`chalkboard.dart`)
Always-dark `board` surface with a thin wooden frame (`boardFrame`), a
chalk-underlined heading (any date or count sits beside or below the heading,
never as a label above it), and items listed like a menu board: dish name,
dotted leader, quantity in mono.

### ImpactNumber (`impact_number.dart`)
A very large Bricolage number with a small uppercase mono caption. Counts up from
0 (`TweenAnimationBuilder`, `FlMotion.count`) the first time a figure appears in a
session; on later visits it starts from the value it last showed, so it stands
still, or counts only what was added. No count-up under reduced motion.

### VegMarker (`veg_marker.dart`)
The Indian food marking: a green square outline with a green dot (veg), a red
square outline with a red triangle (non-veg), and a split marker for mixed. Has a
`Semantics` label.

### Slip snackbar (`slip_snackbar.dart`)
Feedback appears as a small printed slip: `ink` background, mono text, and a small
boxed word (DONE / NOT DONE) so the result never depends on colour. Shown through
a `SnackBar` with a transparent background (set in the theme).

### SkeletonToken (`skeleton_token.dart`)
A loader in the exact shape of a TokenCard with a slow opacity pulse (static when
reduced motion is on). No spinners for content.

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
| `desktop` | `> 1024` | Menu-board sidebar (248): logo, nav, user chip | Main area plus a right activity rail (304); max content width 1320 (`Breakpoints.maxContent`), left-aligned; dialogs (`showDialog`) instead of sheets |

Rules:
- Use `MediaQuery.sizeOf` or `LayoutBuilder`, never `MediaQuery.of`, so screens
  rebuild only when the size changes.
- Gutters: 16 / 24 / 40 (`Breakpoints.gutter`).
- Use `SafeArea`; the bottom bar respects the system inset.
- No overflow errors at 360, 768 or 1440 px wide. Prefer `Wrap`, `Flexible`,
  `Expanded` and `maxLines` over fixed widths.
- Dialogs on desktop, bottom sheets on mobile (one helper chooses by size).

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
