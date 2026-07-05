# TASK.md

Task log for the Errands app (todo-geo-app). Plan: `docs/plans/2026-07-04-todo-geo-app.md`.

## Active

- [ ] Milestone 2: Phase 1 product (Gates G–I) — next: Task 2.3 notification policy

## Upcoming (from plan)
- [ ] 2026-07-11 or later: GATE I becomes checkable (7 days after Gate C — verify AltStore auto-refreshed the app)

## Completed

- [x] 2026-07-04 — Task 0.1: Repo scaffolding; public repo https://github.com/alicancaner/errands-app
- [x] 2026-07-04 — Task 0.2: Hello World app skeleton (XcodeGen, SwiftUI)
- [x] 2026-07-04 — Task 0.3: CI workflow producing unsigned .ipa — GATE A PASSED (run 28714178715, green; .ipa verified: Payload/Errands.app, bundle id com.alican.errands)
- [x] 2026-07-04 — Task 0.4: AltServer + AltStore setup — GATE B PASSED (user confirms AltStore main screen, "expires in 7 days"). Root-caused -22411: stale anisette machine identity; fixed via iTunes sign-in after renaming incompatible iTunes Library.itl left by a previous newer iTunes.
- [x] 2026-07-04 — Task 0.5: Sideload Hello World — GATE C PASSED (user confirms "Errands v0.1 — pipeline works" on iPhone). MILESTONE 0 COMPLETE; tagged v0.1-pipeline. Gate I checkable from 2026-07-11. Windows sideload path: Shift-click AltServer tray icon → "Sideload .ipa".
- [x] 2026-07-04 — Task 1.1: geofence probe (200 m tripwire) — GATE D PASSED (user walked out+back with app swiped away; both EXIT and ENTER notifications received, events in log). Observation: exit detection prompt, entry detection noticeably delayed — factor into notification-policy tuning.
- [x] 2026-07-04 — Task 1.2: Add Text intent probe — GATE E PASSED (dictated text landed in Intent Log via Back Tap double-tap AND via "Hey Siri, Errand"; app never opened during capture).
- [x] 2026-07-05 — Task 2.0: Swift 6.3.2 toolchain installed on Windows (winget); ErrandKit Foundation-only package created; `swift test` verified locally; CI test job added. Note: fresh terminals needed after install — Claude works around stale env vars by reloading SDKROOT/Path per command.
- [x] 2026-07-05 — Task 2.1: UtteranceParser (TDD, 8 tests red→green): last from/at clause = store clause, or/and/comma multi-store split, articles preserved, ParseError.empty.
- [x] 2026-07-05 — Task 2.2: RegionPlanner (TDD, 8 tests red→green): nearest-first, cap 20, two-ring outer 1750 m / inner 250 m, driving direction bias (max 2x distance penalty at 180°), deterministic StoreID tie-break.
- [x] 2026-07-05 — Task 1.3: search + motion probes — GATE F PASSED. Search: "walmart" → correct nearby branches; "persian" → true category matches (Shamshiri, Bahar bakery, Persian grill — names without "persian" in them), BUT "persian market" does NOT find Arya Market (Apple POI lacks a Persian category tag for it) → real app must search by the store NAME the user says (strong path), not category descriptors (weak path). Motion: sustained walking detected within 10–20 m and visible in coprocessor history query; hand-held idle = "(none)" with high confidence (expected); treat none/unknown as "not driving". MILESTONE 1 COMPLETE; tagged v0.2-probes.

## Discovered During Work (Milestone 0)

- This PC previously had a newer iTunes (likely MS Store) — leftovers caused both the stale anisette cache (-22411) and the unreadable iTunes Library.itl. Renamed library file kept as backup in OneDrive\Music\iTunes.
- Legacy standalone iCloud installer (v7.18/7.21) verified working URL recorded in docs/SETUP-ALTSTORE.md; Apple no longer links it publicly.

## Discovered During Work
