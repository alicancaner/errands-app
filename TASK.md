# TASK.md

Task log for the Errands app (todo-geo-app). Plan: `docs/plans/2026-07-04-todo-geo-app.md`.

## Active

- [ ] Task 0.5: Sideload Hello World (Gate C)

## Upcoming (from plan)
- [ ] Milestone 1: Capability probes (Gates D–F)
- [ ] Milestone 2: Phase 1 product (Gates G–I)

## Completed

- [x] 2026-07-04 — Task 0.1: Repo scaffolding; public repo https://github.com/alicancaner/errands-app
- [x] 2026-07-04 — Task 0.2: Hello World app skeleton (XcodeGen, SwiftUI)
- [x] 2026-07-04 — Task 0.3: CI workflow producing unsigned .ipa — GATE A PASSED (run 28714178715, green; .ipa verified: Payload/Errands.app, bundle id com.alican.errands)
- [x] 2026-07-04 — Task 0.4: AltServer + AltStore setup — GATE B PASSED (user confirms AltStore main screen, "expires in 7 days"). Root-caused -22411: stale anisette machine identity; fixed via iTunes sign-in after renaming incompatible iTunes Library.itl left by a previous newer iTunes.

## Discovered During Work (Milestone 0)

- This PC previously had a newer iTunes (likely MS Store) — leftovers caused both the stale anisette cache (-22411) and the unreadable iTunes Library.itl. Renamed library file kept as backup in OneDrive\Music\iTunes.
- Legacy standalone iCloud installer (v7.18/7.21) verified working URL recorded in docs/SETUP-ALTSTORE.md; Apple no longer links it publicly.

## Discovered During Work
