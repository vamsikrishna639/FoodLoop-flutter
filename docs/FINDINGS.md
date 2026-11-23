# FoodLoop: Screenshot Pass Findings

Date: 2026-11-23. This is plan step 3 in `PROGRESS.md`.

**Status (end of 2026-11-23):** F1–F36 are fixed (commits `84e9c17`,
`cba4c99`, `f51310d`, `892550a` and the final check) except:
- **F14: not a bug.** Re-measured on `admin-assign-1440-paper`: the dialog
  spans x 480–960, centred in the 1440 viewport. The original coordinates were
  wrong.
- **F11 (gallery part):** token cards in the gallery's 768 grid still differ in
  height when one title wraps. The gallery is a debug-only screen, so this is
  accepted.
- **F34:** not reproduced in the final screenshots (`final-*`); no code cause
  found.

The final check screenshots are `docs/screenshots/final-*` (7 screens, 360 and
1440, both modes).

## How the screenshots were taken

- **App build:** a debug web build (`flutter run -d web-server`). Debug builds
  draw Flutter's yellow-and-black overflow stripes and log "RenderFlex
  overflowed" errors; release builds do neither.
- **Data:** the backend ran on a fresh `npm run seed`.
- **Browser:** the Playwright MCP, at 360×800, 768×1024 and 1440×900, in paper
  and chalkboard modes.
- **Sign-in:** each role's JWT was placed in `localStorage`, then the app opened
  each route directly.
- **Taps:** forms, dialogs and tabs were opened by turning on Flutter's
  accessibility tree and clicking the named buttons. Each snackbar was triggered
  from its gallery button.
- **Files:** 194 PNGs in `docs/screenshots/`, named `screen-width-mode.png`
  (for example `donor-board-768-chalkboard.png`). `gallery-pN-…` files are the
  lower pages of the gallery, scrolled down one screen at a time.
- **Review:** I looked at every screenshot. Near-identical screens shared by all
  roles (alerts, profile) were reviewed side by side.

| Group | Screens |
|---|---|
| Public | `onboarding`, `login`, `register`, `gallery` (plus `gallery-p2`…`p7`), `pending` |
| Recipient | `recipient-feed`, `recipient-detail`, `recipient-requests`, `recipient-alerts`, `recipient-profile` |
| Donor | `donor-board`, `donor-postform` (sheet or dialog), `donor-listings`, `donor-alerts`, `donor-profile` |
| Volunteer | `volunteer-pickups`, `volunteer-delivered` (Delivered tab), `volunteer-alerts`, `volunteer-profile` |
| Admin | `admin-overview`, `admin-assign` (sheet or dialog), `admin-approvals`, `admin-listings`, `admin-alerts`, `admin-profile` |
| Feedback | `slip-done`, `slip-error`, `slip-note` |

**Limits.** Flutter web draws everything on a canvas, so a "full page"
screenshot is just the viewport. Except for the gallery, each screen was
captured at the top only; content below the fold was not seen. The shots were
taken between about 1:50 PM and 3:30 PM, so countdowns differ between files,
and Veg Grilled Sandwiches had expired ("pickup closed") in the later shots.

---

## Headline results

- **Overflow errors: none.** I saw no overflow stripes in any screenshot, and
  neither the browser console nor the `flutter run` output logged an overflow or
  exception.
- **The contrast fixes from `e5d3c43` work on screen.** DONE, NOT DONE and NOTE
  all read clearly in both modes (`slip-*`). The sidebar and rail "Post food"
  button is legible (`donor-board-1440-*`, `donor-board-768-*`).
- **One regression from that same commit (F1).**
- **The biggest concept problem is chalkboard mode (F2).** The always-dark
  "chalkboard" surfaces are almost the same colour as the dark page, so the
  donor board, the sidebar and the login/onboarding panels lose their identity.

Severity: **High** means broken or clearly wrong, visible on most screens.
**Medium** means noticeable layout, contrast or concept problems. **Low** means
polish.

---

## High

**F1. The "TOKEN" caption clips to "TOKI" on every token card.** *(Regression from bug-5 fix, `e5d3c43`)*
- **Fixed.** The caption now takes its natural width and the rule fills the
  rest (a `LayoutBuilder` caps the caption at the block width).
- At `monoSmall` (11.5px), "TOKEN" plus the 4px gap and the rule don't fit the
  ticket block's 54px inner width, so the `Flexible` clips the word.
- It happens at every width, in both modes, on every TokenCard: feed, detail,
  listings, gallery.
- See `recipient-feed-*`, `donor-listings-*`, `gallery-*`.
- To fix it: drop the rule, shorten the tracking, or enlarge the block. Then
  re-check DESIGN.md 6.

**F2. In chalkboard mode the "always dark" board surfaces disappear.**
- `board` `#232927` on the chalkboard page `#1F2422` is close to 1:1.
- Affected:
  - The donor's "Today's Surplus" block: only its brown frame still shows. This
    was the donor screen's hero (`donor-board-*-chalkboard`).
  - The desktop sidebar and the tablet rail. The activity rail is set apart only
    by a hairline (`*-1440-chalkboard`, `*-768-chalkboard`).
  - The left panel of the login, register and onboarding split layout
    (`login-1440-chalkboard`, `onboarding-1440-chalkboard`).
  - The dark brand bar on phone and tablet login and register
    (`login-360-chalkboard`).
- The gallery's own caption says "The board stays dark in both themes", but in
  practice it no longer stands out.
- To fix it, the board needs its own treatment in dark mode, such as a lighter
  slate, a stronger frame, or chalk dust.
- **Fixed with option B.** `board` is now a per-theme palette token:
  `#232927` on paper, `#2F3B34` green slate on the chalkboard page. Checked at
  360 and 1440 on the donor board, login and onboarding in both modes.
- The two options that were compared:
  - **A** (`docs/screenshots/f2-option-a.png`): keep the board colour; a
    lighter wooden frame (`#6B5236`) and a 1.5px chalk edge (`#6A736E`, 3.22:1
    against the page) on the board, sidebar, rail and login/onboarding panel.
    Text on the board is unchanged (chalk 12.11, chalkSoft 5.90).
  - **B** (`docs/screenshots/f2-option-b.png`): in chalkboard mode only, the
    board becomes a green slate `#2F3B34` (1.35:1 against the page). Text on
    the board: chalk 9.56, chalkSoft 4.66 (the lowest, still at least 4.5),
    turmeric 6.47.

**F3. The same event shows different times in Alerts and in the Activity rail.**
- "Farhan Sheikh requested 5 boxes of Chicken Biryani" reads "59 min ago" in
  Alerts, but "21 min ago" in the Activity rail on the same screenshot
  (`donor-alerts-1440-paper`).
- The notification `createdAt` and the activity timestamp disagree. This is
  either the seed script or the activity source.
- **Fixed.** The cause was the seed data. Farhan's 5-box claim had no
  `createdAt`, so it took the time the seed ran, while its notification was
  hard-coded to 38 minutes earlier. The activity feed (which reads the claim's
  `createdAt`) and the real API were correct. The seed now gives every claim a
  time, and the "requested" notifications read their claim's `createdAt`.

---

## Medium: contrast and accessibility

**F4. The register role slips have no visible edge.** They are tap targets, but
their only boundary is the decorative `line` colour (1.23:1 on paper). DESIGN.md
1.4 says `line` is never the only boundary of a control, and WCAG 1.4.11 asks for
3:1. See `register-*`.

**F5. Role stamps are red.** RECIPIENT, DONOR, VOLUNTEER and ADMIN in Profile
use the same chilli red as REJECTED, so a role reads like an error. On the
Approvals screen the same RECIPIENT stamp is ink, so the two screens are
inconsistent. See `*-profile-*` and `admin-approvals-*`.

**F6. The nav badge number is 10.5px**, below the 11.5px `monoSmall` minimum.
Its colours pass. See the bell badge in every shell screenshot.

**F7. The phone sheets leave the bottom nav undimmed.** The "Who collects it?"
sheet opens above the bottom nav, and the nav stays at full brightness and looks
tappable while the sheet is open (`admin-assign-360-*`). Check the post-food
sheet the same way. In `donor-postform-360-*` the sheet covers the bar.

**F8. The Quantity field's "20" is ambiguous.** On paper it is placeholder grey;
in chalkboard mode it looks like a real value. You can't tell whether 20 is
pre-filled. See `donor-postform-*`.

## Medium: layout and spacing

**F9. Tablet (768) reuses the phone layout on the entry screens.**
- Onboarding stretches the phone slides, leaving a void of about 560px between
  the copy and the dots (`onboarding-768-*`).
- Login and register are a left-aligned phone form with the right side empty.
  The split layout with the menu board starts only at desktop width
  (`login-768-*`, `register-768-*`).

**F10. The 768 rail's main action has no label.** It is a red square with only
an icon ("+" or search). Every other rail item has a label
(`donor-board-768-*`, `recipient-feed-768-*`).

**F11. Receipts in two-column rows don't line up.** The second receipt starts
about 32px lower than the first, so the torn top edges don't align
(`recipient-requests-768-*`, `recipient-requests-1440-*`). Token cards in the
768 grid also have uneven heights, so the stubs and perforations don't line up
across a row (`gallery-768-*`).

**F12. On phones, wrapped receipt values push their labels down.** When a value
wraps ("Main Block Canteen, / Counter 2"), the label and its dotted leader sit on
the second line, so "From ……" floats below the value's first line
(`volunteer-pickups-360-*`, `volunteer-delivered-360-*`).

**F13. Helper text doesn't line up with labels.** Helper text sits about 20px in
from the field edge while labels are flush, for example "So a volunteer or
canteen can reach you" and "At least 6 characters" (`register-768-*`,
`register-1440-*`). Text-button links are also indented by the button's padding
relative to the content above them: "Can't do this run"
(`volunteer-pickups-*`) and "Create an account" (`login-*`), whose baseline is
also about 1px off from the text beside it.

**F14. The 1440 dialogs are off-centre.** The "Who collects it?" dialog sits at
about x=1233–1606, over the right side and the activity rail, instead of in the
centre of the viewport or the main column (`admin-assign-1440-*`).

**F15. The tablet side panel has no edge, and its action is hidden.** The listing
detail panel next to the slips is a bare column with no surface or edge, and its
request action is below the fold (`recipient-feed-768-*`).

**F16. Orphaned words in headings and subtitles.** "Main Block Canteen, Counter"
wraps, leaving "2" alone on the next line (`recipient-feed-1440-*`). The
Approvals subtitle wraps "in." alone (`admin-approvals-768-*`,
`admin-approvals-1440-*`). The Pickups subtitle wraps "step." alone
(`volunteer-pickups-768-*`, `volunteer-pickups-1440-*`).

**F17. Raised centre button and bottom bar on phones.**
- The raised button covers content at rest: the first request card on the donor
  board, and the "You asked for…" line on the detail page.
- Check that each scroll view's bottom padding covers the bar plus the button's
  overhang.
- See `donor-board-360-*` and `recipient-detail-360-*`.

## Medium: generic or off-concept

**F18. Alerts is the most template-like screen.** It is a plain divided list
with a red dot; only the mono overlines carry the concept. It could be a docket
spike of printed slips instead. At 1440 it also repeats most of what the
Activity rail beside it already shows (`*-alerts-*`).

**F19. Login and register on phone and tablet have no Canteen Token element.**
Only the desktop split panel has the menu-board list (`login-360-*`,
`login-768-*`).

**F20. The request and approval cards are plain bordered rectangles.** They are
the only cards on their screens that aren't a slip or a receipt
(`donor-board-*`, `admin-approvals-*`, "Needs a volunteer" on
`admin-overview-*`).

**F21. The admin feature block is a generic white panel.** It holds the large
112 and the chart. The asymmetric "one big block plus supporting blocks" layout
isn't visible above the fold at 1440: the "Right now" receipt sits below it
(`admin-overview-*`).

**F22. On the recipient phone screen, the raised "Browse" action repeats the
selected "Counter" tab.** The recipient is already on the browse screen, so the
signature action does nothing new there (`recipient-*-360-*`).

**F23. The post-food form is a stock Material form.** Only the mono date pickers
and the "Print token" button carry the concept (`donor-postform-*`).

## Low: copy, data and consistency

**F24. Time formats are mixed.**
- Relative times are written "28 min ago" next to "1 h ago", while clocks use
  "1h 44m".
- The board meta mixes "24M LEFT" with "3:35 PM".
- In Alerts, day headers are followed by each row repeating the full date.
- See the activity rail, `donor-board-*` and `*-alerts-*`.

**F25. "NEW REQUEST · NEW"** prints "NEW" twice on each unread donor alert
(`donor-alerts-*`).

**F26. The two requests for 6 and 8 packets against 12 left both offer Approve,
with no hint that only one can succeed.** The backend blocks the second
(`donor-board-*`).

**F27. Repeated names.**
- The donor's own listings print "Main Block Canteen" on every slip
  (`donor-listings-*`).
- The donor profile shows the same name as the title and again as "From"
  (`donor-profile-*`).

**F28. Listing explanations don't match the actions.**
- "…so it stays on record" really means "can't be deleted", but that isn't said.
- The admin "All listings" subtitle says "Remove anything", yet those cards only
  offer Edit.
- See `donor-listings-*` and `admin-listings-*`.

**F29. "Chalkboard mode" subtitle.** It describes the current theme ("Warm paper
with ink text") rather than what the switch does (`*-profile-*`).

**F30. "Component gallery" is linked from every user's Profile.** It is a
developer screen (`*-profile-*`).

**F31. Small volunteer-screen items.**
- The recipient's phone number isn't tap-to-call.
- The subtitle is missing at 360 but shown at 768 and 1440.
- The tab chips wrap to two rows at 360.
- The "1 RUN ON" caption in the assign dialog is unclear.
- See `volunteer-pickups-*` and `admin-assign-*`.

**F32. Volunteer ImpactNumber.** DESIGN.md's typography table mentions a 64px
volunteer ImpactNumber, but none appears on the pickups screen at any width.
Either the doc or the screen is wrong.

**F33. Requests stat line.** "48 PORTIONS RECEIVED SO FAR" sits under the filter
chips like a filter caption, though it's a stat (`recipient-requests-*`).

**F34. Stray mark under a stub in chalkboard mode.** A white dash about 8px long
sits just below the first stub on `donor-listings-360-chalkboard` and is not in
paper mode. The cause is unknown; it needs a closer look.

**F35. Phone numbers have no digit grouping** ("9000000003").

**F36. Illustrations are reused.** The error state "That did not go through"
uses the same slip illustration as onboarding and the admin empty Alerts, so an
error looks like an empty state (`gallery-p*`, `admin-alerts-*`).

## Capture artefacts (not bugs)

- Hover outlines or tints on single cards and rows in
  `gallery-1440-chalkboard` and `donor-alerts-1440-paper`. The mouse was parked
  over them during the capture.
- `gallery-p7` overlaps `p6` because the last scroll reached the end of the
  page.

## What already works well

- The pending screen (timer and account receipt), the volunteer pickup slips,
  the recipient receipts, the listing detail with its food-safety note, and the
  donor board in paper mode are strongly on-concept.
- All stamps render correctly, including the DELIVERED double border and the
  crossed-out EXPIRED.
- No overflow at any width.
