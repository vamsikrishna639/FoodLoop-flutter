# FoodLoop: Progress and Handover

Last updated: 2026-11-23. This file records where the project stands, so a new
session can continue without redoing the audit. The brief is `PROMPT.md`. The
design source of truth is `DESIGN.md`.

---

## 1. Status of PROMPT.md stages

Audit method: read every backend file and the frontend widgets, theme, router
and screens; ran `flutter analyze` (no issues) and `node --check` on all backend
files (clean). The UI has **not** been run or screenshotted yet.

### Stage 1: design system and setup (done)

| Item | Status | Where |
|---|---|---|
| DESIGN.md (Flutter) | Done, checked against code this session | `DESIGN.md` |
| Theme tokens and ThemeExtension | Done, matches DESIGN.md exactly | `frontend/lib/core/theme/tokens.dart`, `frontend/lib/core/theme/app_theme.dart` |
| Signature widgets (all 8, plus skeleton, empty state, slip snackbar) | Done | `frontend/lib/widgets/` |
| Component gallery | Done, route `/gallery` | `frontend/lib/screens/common/gallery_screen.dart` |
| Backend scaffold, Mongo connection, `{success, message, data}`, central error handler | Done | `backend/src/app.js`, `backend/src/config/db.js`, `backend/src/utils/apiResponse.js`, `backend/src/middleware/errorHandler.js` |
| JWT + bcrypt auth, role and approval middleware | Done | `backend/src/controllers/authController.js`, `backend/src/middleware/auth.js` |
| Seed script | Done | `backend/seed/seed.js` (`npm run seed`) |
| Login, register, pending screens | Done | `frontend/lib/screens/auth/` |
| ResponsiveShell (bottom bar with raised action / rail / menu-board sidebar + activity rail) | Done | `frontend/lib/widgets/responsive_shell.dart` |
| go_router with role-based redirects | Done | `frontend/lib/core/router/app_router.dart` |

### Stage 2: food listings (done)

- Listing CRUD, validation, date rules, expiry sweep:
  `backend/src/controllers/foodController.js`, `backend/src/routes/foodRoutes.js`,
  `backend/src/utils/listingStatus.js`
- Recipient feed (search, filter chips, side panel on wide screens):
  `frontend/lib/screens/recipient/feed_screen.dart`
- Listing detail (food-safety note, capped stepper, Hero on phones):
  `frontend/lib/screens/recipient/listing_detail.dart`
- Donor post form (date-time pickers) and manage screen:
  `frontend/lib/screens/donor/listing_form.dart`,
  `frontend/lib/screens/donor/manage_listings_screen.dart`

### Stage 3: claim workflow (done)

- Atomic reservation (`findOneAndUpdate` with `$expr` + `$inc`), approve, reject
  and cancel, rule 7 (one open request), notifications:
  `backend/src/controllers/claimController.js`
- Transition tables: `backend/src/utils/transitions.js`
- Stamp drop animation (used only on approve, with haptic):
  `frontend/lib/widgets/stamp_drop.dart`, used in `frontend/lib/screens/donor/request_queue.dart`
- My Requests with ReceiptTimeline: `frontend/lib/screens/recipient/my_requests_screen.dart`

### Stage 4: volunteers, notifications, dashboards (done)

- Pickup assignment and status: `backend/src/controllers/pickupController.js`
- Notifications: `backend/src/controllers/notificationController.js`,
  `frontend/lib/screens/common/alerts_screen.dart`
- Dashboard and activity feed: `backend/src/controllers/dashboardController.js`,
  `frontend/lib/widgets/activity_rail.dart`
- Admin overview (ImpactNumber feature block, 7-day chart), approvals (table on
  desktop, cards on mobile), assign dialog or sheet:
  `frontend/lib/screens/admin/`, `frontend/lib/widgets/deliveries_chart.dart`
- Volunteer pickups: `frontend/lib/screens/volunteer/pickups_screen.dart`

### Stage 5: testing and polish (mostly missing)

| Item | Status |
|---|---|
| Postman collection with negative tests (over-allocation, wrong role, invalid transition), 80 requests | **Done.** Passed 2026-11-23 on a fresh seed: 80 requests, 231 assertions, 0 failures. `backend/postman/FoodLoop.postman_collection.json`, `npm run test:api` (needs the backend running) |
| Playwright screenshots at 360, 768, 1440 px, paper and chalkboard modes | **Captured, not fixed.** `docs/screenshots/`, `docs/FINDINGS.md` |
| Dark mode visual check | **Done** as part of the screenshots (see F2 in `docs/FINDINGS.md`) |
| `/impeccable audit` and `/impeccable polish` | **Missing** (the only critique file in `.impeccable/critique/` is about an old JSX page, not this app) |
| review-animations | **Missing** |
| Root `README.md` (setup, test logins, demo script) | **Missing** (the root README is the one line from the GitHub repo) |
| `frontend/README.md` and pubspec `description` | Still the Flutter defaults ("A new Flutter project.") |

---

## 2. Completed this session

### Git

- Root `.gitignore`: `node_modules/`, `backend/.env`, `frontend/build/`,
  `frontend/.dart_tool/`, `.DS_Store`, plus the machine-local
  `.claude/settings.local.json` and `.impeccable/config.local.json`.
  `frontend/.gitignore` is unchanged.
- Branch renamed to `main`. Remote `origin` =
  https://github.com/vamsikrishna639/FoodLoop-flutter.git, upstream tracking set.
- Commits on `main` (all pushed):
  - `e2e0419` Initial commit: FoodLoop backup with DESIGN.md (the backup exactly as it was)
  - `8c9cfcb` Merge with the remote's one-line README (unrelated histories)
  - `e33e423` docs: align DESIGN.md with the widget code as built
- Verified: `backend/.env` and `node_modules` are not tracked; `backend/.env.example` is.

### DESIGN.md checked against `frontend/lib/widgets/` (document-only fixes, no app code changed)

The palette, type scale, spacing, radii, breakpoints and the stamp drop
already matched. These corrections were made:

1. Stagger cap is 6 items (`FadeUp.maxStaggered`), not 8. FadeUp is a 200ms fade plus an 8px rise.
2. `FlMotion.slow` (280ms) is used only for the onboarding slide change.
3. Page transitions: every go_router page is an opacity-only cross-fade (200ms in, 120ms back), including the phone detail page; the Hero rides on it. FadeForwards only affects routes pushed outside go_router.
4. Focus ring: 2px ink drawn on the element's edge with no offset; on the dark board it is 3px turmeric, not chalk.
5. Loading state: the label is replaced by a loading label with dots that print one by one, in the button font (not a mono ticker).
6. FlButton has only ink, accent and outline variants. There is no underlined text variant; low-emphasis actions use a themed `TextButton`.
7. Buttons have a minimum height of 48. Only the form date-time pickers are 52.
8. Elevation values corrected to the real shadows (slip blur sigma 6; raised action blur 10 at 16%; snackbar 0,10 / 24 / 18%; dialogs and sheets use Material elevation).
9. TokenCard: no compact variant exists. The ticket block shows two initials in Bricolage (not one mono initial), with a "TOKEN" caption. Documented the selected state, the stub that grows with text size, the image fallback, and that there is no Hero under reduced motion.
10. PortionMeter: circles for plates, squares for boxes and packets; kg always shows the 10-segment bar; the "N / total UNIT LEFT" line is always printed.
11. DeadlineClock: updates every 20 seconds (every second in the last minute); LEFT, CLOSING or HURRY caption; 4% minimum ring sliver.
12. StatusStamp: added COMPLETED (leaf) and `StatusStamp.custom` for role stamps; the uneven ink is described as a ShaderMask.
13. ReceiptTimeline: teeth are about 12px wide and 6px deep; documented the header, the optional stamp beside the title, and the footer.
14. Chalkboard: the underline is a wavy turmeric line (not chalk); 6px frame; ChalkItem layout described.
15. ImpactNumber: no breakpoint scaling; the caller passes the size (96 admin, 64 volunteer, 44 small). Uses `en_IN` digit grouping, an optional suffix, and FittedBox.
16. VegMarker: mixed shows two markers side by side (not a split marker); optional label.
17. Slip snackbar: added the NOTE variant, 4-second duration, 420px width on wide screens, live region.
18. Layout: there is no shared sheet-or-dialog helper. Each form opener checks `context.isMobile`; tablet gets dialogs as well as desktop. The 1320px max width includes the sidebar.
19. The one `Color(0x…)` outside `app_theme.dart` is the alpha-only stamp ink mask.

---

## 3. Known bugs

All five contrast bugs from the first audit are fixed (2026-11-23). Ratios use
the WCAG relative-luminance formula, and DESIGN.md 1.4 lists them.

| # | Bug | Fix | Now |
|---|---|---|---|
| 1 | Snackbar DONE mark, chalkboard mode (1.48:1) | New `slipDone` token = paper `turmericDeep` `#8A5A0B` in chalkboard (paper mode keeps turmeric) | 4.84 |
| 2 | Snackbar NOT DONE mark, chalkboard mode (2.55:1) | New `slipError` token = paper `chilliDeep` `#B93A21` | 4.65 |
| 3 | Snackbar NOT DONE mark, paper mode (3.99:1) | `slipError` = chalkboard `chilli` `#F0674B` | 5.51 |
| 4 | Sidebar / rail "Post food" label, paper mode (3.99:1) | `_SideAction` uses `chilliDeep` fill and `onChilli` label and icon, as the accent button does | 5.37 paper, 5.51 chalkboard; hover 6.01 / 4.78 |
| 5 | "TOKEN" caption at 8px | `monoSmall` size, in `ink` (the food-type tone fails on its tint at this size: chilli 3.87 on the dark tint), `ExcludeSemantics`, clips instead of overflowing | 8.94 – 13.71 |

Files: `frontend/lib/core/theme/tokens.dart`, `frontend/lib/core/theme/app_theme.dart`,
`frontend/lib/widgets/slip_snackbar.dart`, `frontend/lib/widgets/responsive_shell.dart`,
`frontend/lib/widgets/token_card.dart`. `flutter analyze` and the Dart MCP are clean.
These were checked by calculation only. The screenshot pass (plan step 3) is the visual check.

---

## 4. Remaining plan (in this order)

1. ~~Backend check~~ (done: all pass).
2. ~~Fix contrast bugs 1–5~~ (done).
3. **Screenshots:** captured 2026-11-23, 194 PNGs in `docs/screenshots/`, findings in `docs/FINDINGS.md` (F1-F36, nothing fixed yet; waiting for the user's review). Notes for re-running: re-seed first (`npm run test:api` adds test data), then `flutter build web` (or `flutter run -d web-server`), start
   the backend, and use the Playwright MCP to screenshot every screen at 360, 768
   and 1440 px in paper and chalkboard modes, logged in as each role. Fix overflow,
   spacing and contrast. **Pause and show the user the results before fixing.**
   Commit and push.
4. **`/impeccable audit` and `/impeccable polish`** across the whole app; fix the
   findings. Commit and push.
5. **review-animations** on the app; fix the findings. Commit and push.
6. **Root `README.md`:** setup for MongoDB, the backend (`.env` from
   `.env.example`, `npm install`, `npm run seed`, `npm run dev`) and Flutter
   (`flutter pub get`, `flutter run -d chrome`, the `API_BASE_URL` override,
   `10.0.2.2` on the Android emulator); the test logins; a demo script for one full
   donor → recipient → volunteer → delivered flow. Commit and push.
7. **Tidy** `frontend/README.md` and the `description` in `frontend/pubspec.yaml`.
   Commit and push.

---

## 5. Environment notes

- **MongoDB** runs locally at `mongodb://127.0.0.1:27017/foodloop` (see
  `backend/.env.example`). It was reachable and seeded at the start of this session.
- **Backend** is in `backend/` (renamed from `reference-backend`). Express 5,
  Mongoose 9. Scripts: `start`, `dev`, `seed`, `create-admin`, `test:api`. Port 5000.
- **Frontend** is in `frontend/`. It imports `package:material_ui/material_ui.dart`
  (not `flutter/material.dart`). API base URL is in `frontend/lib/core/config.dart`:
  `localhost:5000` on web, `10.0.2.2:5000` on Android, overridable with
  `--dart-define=API_BASE_URL=...`.
- **Test logins** (all use password `password123`), from `backend/seed/seed.js`:

  | Role | Email | Notes |
  |---|---|---|
  | Admin | admin@foodloop.test | |
  | Donor | canteen@foodloop.test | Main Block Canteen |
  | Recipient | ananya@foodloop.test | Asha Night Shelter |
  | Recipient | farhan@foodloop.test | Boys Hostel C Mess |
  | Volunteer | kiran@foodloop.test | NSS Unit 2 |
  | Volunteer | meera@foodloop.test | NSS Unit 2 |
  | Pending recipient | rohit@foodloop.test | Shows the waiting screen |

- **MCP servers:** Playwright (`npx @playwright/mcp@latest`) and Dart
  (`dart mcp-server`) are configured in `.mcp.json` (project scope). A fresh
  session must approve them. At the end of this session both timed out while
  connecting, so check they start (`npx @playwright/mcp@latest`, `dart mcp-server`)
  if they fail again. Since `ae52c9b` Playwright runs through `cmd /c npx -y`,
  and `.claude/settings.json` sets `MCP_TIMEOUT` to 120000. Both connected after that.
- **Android:** VS Code shows a Gradle/Java build error. It is an Android build
  issue and has not been looked at. Web is the target for screenshots.
- **git push:** Git Credential Manager handles GitHub sign-in. One push in this
  session waited about 2 minutes on it before completing by itself.

---

## 6. Working rules (from the user)

- Commit and push after each step, with a clear message.
- Never force-push.
- Never commit `backend/.env`.
- After the screenshot pass, pause and show the results before fixing anything.
- Keep `DESIGN.md` in sync with the code.
- If a push is rejected or asks for credentials, stop and report the error
  instead of working around it.
