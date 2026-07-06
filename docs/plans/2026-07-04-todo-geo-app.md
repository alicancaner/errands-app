# Errands App (todo-geo-app) Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** A personal, $0-forever iPhone app: add errands by voice, get speed-aware reminders near any matching store branch anywhere, all data on-device.

**Architecture:** Native Swift/SwiftUI app with pure logic isolated in a cross-platform Swift package (`ErrandKit`) so unit tests run locally on Windows. App is assembled and built unsigned on GitHub Actions macOS runners (free, public repo), sideloaded to the user's iPhone 13 via AltStore/AltServer on their Windows PC with a free Apple ID. Voice entry rides on the Shortcuts app (Back Tap / "Hey Siri, errand" → dictation → App Intent). Geofencing with a two-ring speed-aware system and direction-biased region selection; iOS does the watching.

**Tech Stack:** Swift 6 / SwiftUI, SwiftData, CoreLocation (region monitoring + significant-location-change), MapKit (`MKLocalSearch`), CoreMotion (`CMMotionActivityManager`), UserNotifications, App Intents, XcodeGen (project generation on CI), GitHub Actions (macos runner), AltStore/AltServer.

**Design doc:** `DESIGN.md` (project root) — approved 2026-07-04.

---

## Ground rules for this plan

1. **GATES ARE HARD STOPS.** Every milestone ends in a gate. Do not start work past a gate until the gate is verified with observed evidence (CI output, screenshot, user confirmation). If a gate fails, stop and re-plan — do not build around it.
2. **Executor context:** Claude Code runs on the user's **Windows** machine. There is no Mac and no Xcode. All iOS building happens on CI. All on-phone/on-PC actions are done by the **user**, who is non-technical — steps marked **📱 USER** must be given to them as explicit tap-by-tap instructions at execution time.
3. **One bundle ID forever:** `com.alican.errands`. Free Apple IDs are limited to 10 App IDs per 7 days — never create a second bundle ID. The probe builds and the real app are the SAME app, evolved.
4. **$0 check at every step.** If any step ever asks for payment, the step is wrong — stop.
5. **Public GitHub repo** (required for unlimited free macOS CI minutes). The repo contains only code — never the user's tasks, locations, or Apple ID.
6. **TDD for all pure logic** (parser, region selection, cooldowns) — runs locally via Swift for Windows. iOS-framework-dependent code (location engine, UI) is verified through probe builds and field gates instead, with logic pushed down into `ErrandKit` wherever possible.

---

## Milestone 0 — Prove the $0 pipeline (Gates A–C)

*Nothing app-specific. A Hello World must travel the full path: Windows → GitHub → CI build → .ipa → AltStore → running on the iPhone. This is the "does the free tier actually exist" test the user demanded.*

### Task 0.1: Repo scaffolding

**Files:**
- Create: `.gitignore` (Swift/Xcode template)
- Create: `README.md` (one paragraph: what this is, pointer to DESIGN.md)
- Create: `TASK.md` (per user's global CLAUDE.md conventions; log tasks/dates here)

**Steps:**
1. `git init`, initial commit with `DESIGN.md`, `docs/plans/`, scaffolding files.
2. Run `gh auth status`. If not authenticated or no GitHub account exists → **📱 USER checkpoint:** create free GitHub account / run `gh auth login`.
3. Create **public** repo: `gh repo create errands-app --public --source . --push`.
4. Commit message: `chore: scaffold repo`.

### Task 0.2: Hello World app skeleton (buildable without Xcode)

**Files:**
- Create: `project.yml` (XcodeGen spec)
- Create: `App/Sources/ErrandsApp.swift`
- Create: `App/Sources/ContentView.swift`
- Create: `App/Info.plist`

**`project.yml` (complete):**

```yaml
name: Errands
options:
  bundleIdPrefix: com.alican
  deploymentTarget:
    iOS: "17.0"
targets:
  Errands:
    type: application
    platform: iOS
    sources: [App/Sources]
    info:
      path: App/Info.plist
      properties:
        CFBundleDisplayName: Errands
        UILaunchScreen: {}
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.alican.errands
        CODE_SIGNING_ALLOWED: "NO"
        CODE_SIGN_IDENTITY: ""
```

**`ErrandsApp.swift` / `ContentView.swift`:** minimal SwiftUI app showing the text `Errands v0.1 — pipeline works`.

**Step:** Commit: `feat: hello world app skeleton (XcodeGen)`.

### Task 0.3: CI workflow that produces an unsigned .ipa

**Files:**
- Create: `.github/workflows/build.yml`

**Complete workflow:**

```yaml
name: Build IPA
on:
  push: { branches: [main] }
  workflow_dispatch: {}
jobs:
  build:
    runs-on: macos-15
    steps:
      - uses: actions/checkout@v4
      - name: Install XcodeGen
        run: brew install xcodegen
      - name: Generate project
        run: xcodegen generate
      - name: Build (unsigned)
        run: |
          xcodebuild -project Errands.xcodeproj -scheme Errands \
            -configuration Release -sdk iphoneos \
            -derivedDataPath build \
            CODE_SIGNING_ALLOWED=NO CODE_SIGN_IDENTITY="" archive \
            -archivePath build/Errands.xcarchive
      - name: Package IPA
        run: |
          mkdir -p Payload
          cp -r build/Errands.xcarchive/Products/Applications/Errands.app Payload/
          zip -r Errands.ipa Payload
      - name: Upload artifact
        uses: actions/upload-artifact@v4
        with: { name: Errands-ipa, path: Errands.ipa }
```

**Steps:**
1. Commit + push: `ci: unsigned ipa build`.
2. Watch run: `gh run watch`. If archive flags are wrong for unsigned builds (a known fiddly area), iterate here — this is exactly the cheap place to burn attempts.

> ### 🚦 GATE A — CI produces `Errands.ipa`
> **Evidence:** green run, downloadable artifact (`gh run download`). Verify the .ipa contains `Payload/Errands.app` with an `Info.plist` naming `com.alican.errands`.
> **If it fails permanently:** macOS runners or unsigned archiving unavailable → re-plan (this kills the $0 route; there is no fallback that stays at $0 without a Mac).

### Task 0.4: AltServer on the PC, AltStore on the phone

**📱 USER (with my tap-by-tap help at execution time):**
1. On the PC: install iTunes and iCloud **from Apple's website, not the Microsoft Store** (AltServer requirement); install AltServer from altstore.io.
2. Plug iPhone into PC via USB once; AltServer → "Install AltStore" → sign in with Apple ID (app-specific password if prompted; 2FA is supported).
3. On the phone: trust the developer profile (Settings → General → VPN & Device Management).

> ### 🚦 GATE B — AltStore app opens on the iPhone
> **Evidence:** user confirms AltStore launches. This proves free-Apple-ID signing works end-to-end for this Apple ID and phone.
> **If it fails:** troubleshoot AltServer (common: iTunes from MS Store, firewall); fallback tool: Sideloadly (same free-signing mechanism).

### Task 0.5: Sideload Hello World

**Steps:**
1. Download `Errands.ipa` from CI onto the PC (`gh run download`).
2. **📱 USER:** AltStore on phone → My Apps → `+` → pick `Errands.ipa` (shared to phone; simplest reliable path: AltServer → Sideload .ipa from the PC while phone is plugged in / on same WiFi).
3. Launch it.

> ### 🚦 GATE C — "Errands v0.1 — pipeline works" on the iPhone screen
> **Evidence:** user confirmation/screenshot. The entire $0 pipeline is now proven. Also record the date — 7 days from now, GATE I (auto-refresh) becomes checkable for free.
> **Commit:** tag `v0.1-pipeline`.

---

## Milestone 1 — Capability probes (Gates D–F)

*Still no product code. Each probe validates one risky iOS-capability assumption under FREE signing, in the same app, one screen per probe.*

### Task 1.1: Probe — background geofencing under free signing (the #1 risk from DESIGN.md §6)

**Files:**
- Modify: `App/Info.plist` properties (in `project.yml`): add `NSLocationAlwaysAndWhenInUseUsageDescription`, `NSLocationWhenInUseUsageDescription`, `UIBackgroundModes: [location]`
- Create: `App/Sources/Probes/GeofenceProbeView.swift`
- Create: `App/Sources/Probes/GeofenceProbe.swift` (CLLocationManager delegate singleton)

**Behavior (complete spec):**
- Button "Request Always permission" → standard two-step CoreLocation flow.
- Button "Plant tripwire here (300 m)" → `CLCircularRegion` centered on current location, `notifyOnEntry=true`, `notifyOnExit=true`; store planted time in `UserDefaults`.
- On `didEnterRegion`/`didExitRegion` → fire a local notification with timestamp (request `UNUserNotificationCenter` permission on this screen too).
- On-screen log of the last 20 events (persisted).

**Steps:** implement → push → CI → sideload → **📱 USER test:** plant at home, walk to end of street (out >400 m), walk back, with the app closed (swiped away is fine — region monitoring relaunches terminated apps; verify this claim here too).

> ### 🚦 GATE D — Exit + entry notifications received with app not running
> **Evidence:** two notifications with plausible timestamps; event log shows the events.
> **If it fails:** check permission state on diagnostics; if free-signing forbids background location (unexpected), re-plan — this would force a major design change.

### Task 1.2: Probe — Shortcut → App Intent handoff without opening the app

**Files:**
- Create: `App/Sources/Probes/AddTextIntent.swift` — `AppIntent` with a `@Parameter(title: "Text") var text: String`, `openAppWhenRun = false`, appends text + timestamp to an app-group-free local store (UserDefaults is fine for the probe).
- Create: `App/Sources/Probes/IntentLogView.swift` — lists received texts.

**Steps:**
1. Implement → push → CI → sideload.
2. **📱 USER:** build the shortcut (tap-by-tap recipe provided at execution time): Shortcuts app → `+` → action **Dictate Text** → action **AddText** (our intent) with Dictated Text as input → name it **"Errand"**. Then Settings → Accessibility → Touch → Back Tap → Double Tap → Errand.
3. Test: double-tap back of phone → say "testing one two three" → open app → text is there. Also test via "Hey Siri, Errand".

> ### 🚦 GATE E — Dictated text lands in the app, app never opened during capture
> **If dictation-to-intent is clunky:** acceptable fallback is the shortcut showing a brief banner; unacceptable is having to unlock/open the app — that violates the founding requirement.

### Task 1.3: Probe — MKLocalSearch + motion activity

**Files:**
- Create: `App/Sources/Probes/SearchProbeView.swift` — text field, searches `MKLocalSearch` with `naturalLanguageQuery`, region = 20 km around current location; lists name/address/distance.
- Create: `App/Sources/Probes/MotionProbeView.swift` — requests Motion & Fitness permission, displays live `CMMotionActivityManager` state (walking/automotive/stationary + confidence).

**📱 USER test:** search "walmart", "city market", "persian market" → real results with sensible distances. Walk around the room / (later) check in car for motion states.

> ### 🚦 GATE F — Fuzzy place search returns correct nearby stores; motion states are sane
> **Evidence:** user reads back the top results; "persian market" finds Aria (or explains what it found — informs matching tolerances).
> **Commit:** tag `v0.2-probes`. **All risky assumptions are now proven. Product code may begin.**

---

## Milestone 2 — Phase 1 product (Gates G–I)

### Task 2.0: Local Swift toolchain on Windows (for fast TDD)

**Steps:**
1. Install Swift for Windows (swift.org toolchain via winget). Verify: `swift --version`.
2. Create package: `ErrandKit/Package.swift` (library + test target, **Foundation-only** — no CoreLocation/UIKit imports, ever; coordinates are plain `struct GeoPoint { let lat, lon: Double }`).
3. Verify `swift test` runs an empty test suite locally.
4. Add a CI job step running `swift test` on the package too (belt and braces).
5. Commit: `feat: ErrandKit package + local test toolchain`.

> **Mini-gate:** if Swift-on-Windows install fails, fallback = run `swift test` on CI only (slower loop, same rigor). Do not skip TDD.

### Task 2.1: Utterance parser (TDD in ErrandKit)

**Files:** `ErrandKit/Sources/ErrandKit/UtteranceParser.swift`, `ErrandKit/Tests/ErrandKitTests/UtteranceParserTests.swift`

**Contract:** `parse("buy lentils from walmart")` → `ParsedErrand(title: "buy lentils", storePhrases: ["walmart"])`.

**Test cases (write ALL as failing tests first, then implement minimally, red→green one at a time):**
- Expected: `"buy lentils from walmart"` → title `buy lentils`, stores `[walmart]`
- Multi-store: `"buy lentils from walmart or city market or aria"` → 3 stores (split on `or`/`and`/commas)
- `"pick up prescription at walgreens"` → `at` works like `from`
- No store: `"buy lentils"` → stores `[]` (caller then triggers the "where from?" follow-up)
- Edge: `"buy coffee from the persian market"` → store phrase keeps `the persian market` intact (article preserved for fuzzy search)
- Edge: store word inside title: `"buy a walmart gift card from target"` → title `buy a walmart gift card`, stores `[target]` (only the LAST from/at clause is the store clause)
- Failure: empty/whitespace utterance → throws `ParseError.empty`

**Steps per skill:** write failing tests → `swift test` (FAIL) → minimal impl → `swift test` (PASS) → commit `feat: utterance parser`.

### Task 2.2: Region-selection "juggling" algorithm (TDD in ErrandKit)

**Files:** `ErrandKit/Sources/ErrandKit/RegionPlanner.swift`, tests mirror.

**Contract (pure function):**
```swift
plan(candidates: [StoreCandidate],   // all resolved branches for all open errands
     position: GeoPoint, heading: Double?, isDriving: Bool,
     insideOuterRingOf: Set<StoreID>, cap: Int = 20) -> [PlannedRegion]
```
- Nearest-first selection up to `cap`.
- Two-ring: every selected store gets an OUTER region (1,750 m); stores currently inside their outer ring also get an INNER region (250 m) — inner regions count against the cap.
- Direction bias: when `isDriving` and heading is known, score = distance penalized by angular deviation from heading (stores behind ≈ deprioritized, never fully excluded).
- Determinism: stable ordering for equal scores (by StoreID) so tests are exact.

**Test cases:** cap enforcement at 20; two-ring pairing; a store 1 km AHEAD beats a store 600 m BEHIND when driving; no heading → pure nearest; empty candidates → empty plan; 40 candidates → exactly 20 regions.

**Commit:** `feat: region planner with two-ring + direction bias`.

### Task 2.3: Notification policy (TDD in ErrandKit)

**Files:** `ErrandKit/Sources/ErrandKit/NotificationPolicy.swift` + tests.

**Contract:** given an entry event (store, ring, isDriving, history) decide `notifyNow / plantInner / suppress`:
- Outer ring + driving → notify.
- Outer ring + walking/stationary → plantInner.
- Inner ring → notify.
- Same store+errand notified < 2 h ago → suppress (cooldown).
- Errand completed → suppress everywhere.

**Commit:** `feat: notification policy`.

### Task 2.4: Data model + list UI

**Files:** `App/Sources/Model/Errand.swift` (SwiftData: title, storePhrases, resolved candidates cache with lat/lon+name+expiry, createdAt, completedAt), `App/Sources/Views/ErrandListView.swift` (list, swipe-to-complete, delete; shows tagged stores per errand). Replace probe UI as the main screen; move probes under a hidden "Diagnostics" section.

**Verification:** CI build + sideload; **📱 USER:** add a dummy errand via a temporary text field, complete it, relaunch — persistence holds.
**Commit:** `feat: errand model + list UI`.

### Task 2.5: Location engine (the integration heart)

**Files:** `App/Sources/Engine/LocationEngine.swift`, `App/Sources/Engine/StoreResolver.swift` (MKLocalSearch wrapper: phrase + region → candidates, cached with expiry, re-resolved when the user has moved > 10 km from cache anchor).

**Wiring (all decisions delegated to ErrandKit — engine stays thin):**
- Start significant-location-change monitoring at launch; each wake → refresh stale candidates → `RegionPlanner.plan` → diff against currently monitored regions → start/stop monitoring accordingly.
- `didEnterRegion` → snapshot motion state (`CMMotionActivityManager`) → `NotificationPolicy.decide` → act (notify via UNUserNotificationCenter / plant inner / nothing).
- Completing an errand → immediate re-plan.

**Commit:** `feat: location engine`.

### Task 2.6: Voice flow, final

**Files:** `App/Sources/Intents/AddErrandIntent.swift` — parses via `UtteranceParser`; when `storePhrases` is empty, the intent prompts **"Where from?"** via `requestValueDialog` (works through Siri/Shortcuts by voice). Persist through SwiftData, trigger candidate resolution + re-plan in the background.

**📱 USER:** update the "Errand" shortcut to call AddErrand.
**Verification:** full voice round-trip: Back Tap → "buy lentils from walmart or city market" → errand appears, tagged, candidates resolved.
**Commit:** `feat: voice add flow`.

### Task 2.7: Diagnostics screen

**Files:** `App/Sources/Views/DiagnosticsView.swift` — map with currently planted regions (circles, ring type), event log (wakes, plans, entries, notifications, suppressions), permission statuses, candidate cache ages. This is the debugging lifeline for field failures (DESIGN.md §7).
**Commit:** `feat: diagnostics screen`.

> ### 🚦 GATE G — Bench test (same day, controlled)
> **📱 USER script:** add errand by voice tagged to a store ~1 km away → diagnostics shows planted outer ring there → drive toward it → driving buzz arrives ~1.5 km out; separately, walk-test the inner ring at a nearby store. Iterate here until solid.

> ### 🚦 GATE H — Field week
> Normal life for 7–14 days with a written checklist: ≥5 voice adds (incl. one "where from?" follow-up, one multi-store, one sloppy store name), ≥3 driving reminders, ≥1 walking reminder, ≥1 reminder in a part of town never visited since install. Every miss gets diagnosed via the diagnostics log before any Phase 2 work.

> ### 🚦 GATE I — The 7-day leash renews itself
> AltStore auto-refresh has occurred at least once without the user doing anything (phone on home WiFi, AltServer running). Check AltStore → My Apps → expiry date moved forward.
> **Commit:** tag `v1.0-phase1`.

---

## Milestone 2.5 — Manual location control (Task 2.8, added 2026-07-05)

*User-requested after the Milestone 2 build. Motivation: the 20 tripwire slots are precious, and only the user knows "I'll never go to THAT branch" or "I'd only ever walk there." Deleting a tripwire by hand can't work — the next replan would resurrect it — so control must be a **persistent per-branch preference that every replan consults**: exclude the branch entirely, or keep it but silence driving/walking reminders selectively (removing a single ring would break the two-ring machinery: the outer ring is also what plants the inner one).*

*Scope notes: preferences are **global per store branch** (keyed by the engine's StoreID `"lat,lon|name"`), not per errand — "never that Walmart" should hold for every future errand. This milestone needs NO Gate G/H evidence (pure logic + UI, testable locally/CI/on-phone); Phase 2 still waits on Gate H.*

### Task 2.8.1: RegionPlanner exclusions (TDD in ErrandKit)

**Files:**
- Modify: `ErrandKit/Sources/ErrandKit/RegionPlanner.swift`
- Modify: `ErrandKit/Tests/ErrandKitTests/RegionPlannerTests.swift`

**Contract:** `plan(...)` gains `excluding: Set<StoreID> = []`. Excluded stores never receive regions — even when nearest — and their slots go to the next-best candidates. The default value keeps all existing call sites and tests compiling unchanged.

**Test cases (each: write failing test → `swift test` FAIL → minimal code → `swift test` PASS):**
- Excluded nearest store absent from plan; next candidates fill the cap instead.
- Excluding every candidate → empty plan.
- Excluded store gets no INNER ring either, even when listed in `insideOuterRingOf`.

**Implementation sketch:** filter `candidates` with `!excluding.contains($0.id)` before scoring.

**Commit:** `feat: region planner exclusions`.

### Task 2.8.2: NotificationPolicy reminder modes (TDD in ErrandKit)

**Files:**
- Modify: `ErrandKit/Sources/ErrandKit/NotificationPolicy.swift`
- Modify: `ErrandKit/Tests/ErrandKitTests/NotificationPolicyTests.swift`

**Contract:** `decide(...)` gains `remindWhenDriving: Bool = true, remindWhenWalking: Bool = true`. Two new rules AFTER the completed/cooldown checks, BEFORE the ring logic:
- `isDriving && !remindWhenDriving` → `.suppress`
- `!isDriving && !remindWhenWalking` → `.suppress` (this also prevents pointless inner-ring planting on outer entry)

**Test cases:**
- outer + driving + remindWhenDriving=false → suppress
- outer + walking + remindWhenWalking=false → suppress (NOT plantInner)
- inner + walking + remindWhenWalking=false → suppress
- inner + driving with walking-off but driving-on → notifyNow (toggles are independent)
- (defaults: all 9 existing tests stay green untouched)

**Commit:** `feat: per-location reminder modes in policy`.

### Task 2.8.3: StorePreference model + engine wiring

**Files:**
- Create: `App/Sources/Model/StorePreference.swift`
- Modify: `App/Sources/Model/AppDatabase.swift` (schema gains the new model)
- Modify: `App/Sources/Engine/LocationEngine.swift`

**Model (complete):**

```swift
import SwiftData

/// The user's standing decision about one store branch, keyed by the
/// engine's StoreID ("lat,lon|name"). Global — outlives any single errand.
@Model
final class StorePreference {
    var storeKey: String
    var name: String
    var excluded: Bool
    var remindWhenDriving: Bool
    var remindWhenWalking: Bool

    init(storeKey: String, name: String) {
        self.storeKey = storeKey
        self.name = name
        self.excluded = false
        self.remindWhenDriving = true
        self.remindWhenWalking = true
    }
}
```

**Engine wiring (all thin):**
- `AppDatabase`: `ModelContainer(for: Errand.self, StorePreference.self)`.
- Expose the key format: make `storeID(for:)` internal (`static func storeKey(for candidate: CachedCandidate) -> StoreID`) so views key preferences identically.
- `replan`: fetch `StorePreference` where `excluded == true` → `Set<StoreID>` → pass as `excluding:`.
- `handleEntry`: fetch the preference for the entered storeID (if any) → pass its toggles into `decide(...)`.

**Verification:** `swift test` still green locally; push → CI green.
**Commit:** `feat: store preferences honored by engine`.

### Task 2.8.4: Per-errand location UI + excluded list

**Files:**
- Create: `App/Sources/Views/ErrandDetailView.swift`
- Modify: `App/Sources/Views/ErrandListView.swift` (rows navigate to the detail view)
- Modify: `App/Sources/Views/DiagnosticsView.swift` (new "Excluded locations" section, with un-exclude)

**ErrandDetailView behavior (complete spec):**
- Title + store phrases at top; "not resolved yet" placeholder when candidates are empty.
- Map (`MapCircle`-free; plain `Marker`s) of every matched branch — excluded branches tinted gray, active ones blue.
- One row per matched branch: name + three toggles — **"Use this location"** (inverse of `excluded`), **"Remind when driving"**, **"Remind when walking"** (the reminder toggles disabled while excluded).
- Quick action (user request 2026-07-05): swipe / long-press on a branch row → **"Exclude this location"** — one gesture instead of opening toggles.
- Any toggle change: upsert the `StorePreference` for that storeKey, save, then `LocationEngine.shared.requestReplan()` — the change takes effect on the spot.

**Diagnostics additions:**
- "Excluded locations" section listing all `excluded == true` preferences with an "Include again" button (flips the pref, then replans). Without this, a branch excluded from a completed (gone) errand could never be brought back.
- Quick action on the planted-regions list rows: long-press → **"Exclude this location"** — the natural moment is spotting a useless ring on the map ("that branch is 26 km away"). Requires `MonitoredRegionInfo` to carry its `storeKey`.

**Verification:** push → CI green → download .ipa → verify new strings in binary → copy to project root.
**Commit:** `feat: per-errand location management UI`.

### Task 2.8.5: Hand-off to user

Write `docs/TEST-2.8-LOCATIONS.md` (PROBE style): sideload → open an errand → see its branches on the map → exclude one → watch its rings vanish from the Diagnostics map after "Replan now" → relaunch app → toggles persisted → re-include from Diagnostics.

> ### 🚦 GATE J — Manual location control verified on-phone
> **Evidence (user confirmation):** an excluded branch's rings disappear and STAY gone across replans; reminder toggles persist across relaunch; re-including restores the rings.

---

## Milestone 2.6 — Location control v2: "know your places" (Task 2.9, added 2026-07-05)

*From user feedback during the Gate J test. Design: `docs/plans/2026-07-05-location-ui-v2-design.md` (user-approved). Two problems: (1) matched branches are indistinguishable — no address/distance, pins not linked to cards; (2) wrong matches ("his vet in Yaletown" → two wrong vets) can't be corrected. Fix: show address + distance per branch with pin↔card selection; add search-and-pin backed by a global place book (`SavedPlace` with nicknames) whose nicknames auto-attach to future errands. Pins coexist with auto-matches; wrong guesses use the existing exclude. Pure Phase-1 UI/data work — no gate evidence needed to start; runs independently of Gates G–J.*

*Executor notes: swipe-file style/conventions from Tasks 2.8.x just above. `swift test` runs from `ErrandKit/`; app-side code compiles only on CI (SourceKit "No such module" on Windows is noise). CI: push to main → `gh run list --commit <sha> --json databaseId` (poll a few seconds) → `gh run watch <id> --exit-status`. Verify each .ipa's strings before copying to root; strings ≤15 UTF-8 bytes are register-packed and invisible to string search — verify with type names (`AddLocationSheet`, `SavedPlacesView`) and longer literals.*

### Task 2.9.1: SavedPlaceMatcher (TDD in ErrandKit)

**Files:**
- Create: `ErrandKit/Sources/ErrandKit/SavedPlaceMatcher.swift`
- Create: `ErrandKit/Tests/ErrandKitTests/SavedPlaceMatcherTests.swift`

**Contract:** `SavedPlaceMatcher.matches(nickname:phrase:)` — true when any *significant word* (≥ 3 letters, so "Furfur's" → "furfur" but the stray "s" is ignored) of the nickname appears as a **whole word** in the phrase, case-insensitive. Whole-word means "vet" never matches inside "velvet". Tokenize by splitting on everything non-alphanumeric.

**Step 1 — Write the failing tests (complete file):**

```swift
import XCTest
@testable import ErrandKit

final class SavedPlaceMatcherTests: XCTestCase {

    // Expected use — the Furfur's vet scenario from the design doc
    func testNicknameWordInPhraseMatches() {
        XCTAssertTrue(SavedPlaceMatcher.matches(
            nickname: "Furfur's vet", phrase: "his vet in yaletown"
        ))
    }

    func testWholeWordOnlyVetDoesNotMatchVelvet() {
        XCTAssertFalse(SavedPlaceMatcher.matches(
            nickname: "Furfur's vet", phrase: "buy velvet gloves"
        ))
    }

    func testCaseInsensitive() {
        XCTAssertTrue(SavedPlaceMatcher.matches(
            nickname: "ADIDAS Robson", phrase: "adidas"
        ))
    }

    func testShortNoiseWordsIgnored() {
        // "s" (from Furfur's) and "in" must never be match anchors.
        XCTAssertFalse(SavedPlaceMatcher.matches(
            nickname: "Furfur's vet", phrase: "s in the park"
        ))
    }

    func testMultiWordNicknameAnyWordMatches() {
        XCTAssertTrue(SavedPlaceMatcher.matches(
            nickname: "Yaletown Animal Hospital", phrase: "the animal hospital"
        ))
    }

    // Edge / failure cases
    func testEmptyPhraseNeverMatches() {
        XCTAssertFalse(SavedPlaceMatcher.matches(nickname: "Furfur's vet", phrase: ""))
    }

    func testNicknameWithNoSignificantWordsNeverMatches() {
        XCTAssertFalse(SavedPlaceMatcher.matches(nickname: "a b", phrase: "a b c"))
    }
}
```

**Step 2 — Run: `swift test` from `ErrandKit/`. Expected: compile FAILURE (`cannot find 'SavedPlaceMatcher'`) — that is the red state.**

**Step 3 — Minimal implementation (complete file):**

```swift
import Foundation

/// Decides whether a saved place's nickname is mentioned by a store phrase —
/// the "place book pays off" rule: any significant word of the nickname
/// appearing as a whole word in the phrase counts as a mention.
public enum SavedPlaceMatcher {

    /// Words shorter than this never anchor a match ("s", "in", "a").
    static let minWordLength = 3

    /// True when `phrase` mentions `nickname` (whole-word, case-insensitive).
    public static func matches(nickname: String, phrase: String) -> Bool {
        let nicknameWords = significantWords(of: nickname)
        guard !nicknameWords.isEmpty else { return false }
        let phraseWords = Set(significantWords(of: phrase))
        return nicknameWords.contains { phraseWords.contains($0) }
    }

    /// Lowercased alphanumeric words of length >= minWordLength.
    static func significantWords(of text: String) -> [String] {
        text.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.count >= minWordLength }
    }
}
```

**Step 4 — Run: `swift test`. Expected: all suites PASS (52 tests total = 45 + 7).**

**Step 5 — Commit:** `feat: saved-place nickname matcher`

### Task 2.9.2: Candidate addresses

**Files:**
- Modify: `App/Sources/Model/Errand.swift` — `CachedCandidate` gains `var address: String?`
- Modify: `App/Sources/Engine/StoreResolver.swift` — capture `item.placemark.title` (the human-readable one-line address) into `address:` when building each `CachedCandidate`

`address` is optional, so previously cached rows keep decoding (they show no address until their next re-resolve — expected, documented in the user test).

**Verification:** app-side only — compiles on CI (bundled into Task 2.9.3's push).
**Commit:** `feat: cache branch street addresses`

### Task 2.9.3: SavedPlace model, Errand.pinned, engine union

**Files:**
- Create: `App/Sources/Model/SavedPlace.swift`
- Modify: `App/Sources/Model/AppDatabase.swift` — schema gains `SavedPlace.self`
- Modify: `App/Sources/Model/Errand.swift` — new stored property `var pinned: [CachedCandidate]`, initialized `[]` in `init`
- Modify: `App/Sources/Engine/LocationEngine.swift`

**SavedPlace (complete):**

```swift
import Foundation
import SwiftData

/// One place the user taught the app ("Furfur's vet"). Global place book:
/// future errands whose store phrase mentions the nickname attach it
/// automatically. Deleting a SavedPlace stops future attaching only — value
/// copies already pinned onto errands survive.
@Model
final class SavedPlace {
    var nickname: String
    var name: String
    var address: String?
    var lat: Double
    var lon: Double
    var createdAt: Date

    init(nickname: String, name: String, address: String?, lat: Double, lon: Double) {
        self.nickname = nickname
        self.name = name
        self.address = address
        self.lat = lat
        self.lon = lon
        self.createdAt = .now
    }

    var asCandidate: CachedCandidate {
        CachedCandidate(name: name, lat: lat, lon: lon, address: address)
    }
}
```

**LocationEngine changes (all thin, decisions stay in ErrandKit):**
- New internal helper used by BOTH `replan` and `handleEntry` and later the detail view — the single definition of "which branches count for this errand":

```swift
/// candidates (auto) + pinned (manual) + nickname-matched saved places,
/// deduped by storeKey. Pins and saved places are immune to cache refreshes.
static func effectiveBranches(for errand: Errand, savedPlaces: [SavedPlace]) -> [CachedCandidate] {
    var seen = Set<StoreID>()
    var result: [CachedCandidate] = []
    let matched = savedPlaces.filter { place in
        errand.storePhrases.contains { SavedPlaceMatcher.matches(nickname: place.nickname, phrase: $0) }
    }.map(\.asCandidate)
    for candidate in errand.pinned + matched + errand.candidates {
        let key = storeKey(for: candidate)
        if seen.insert(key).inserted { result.append(candidate) }
    }
    return result
}
```

- `replan`: fetch all `SavedPlace` once; build `byID` from `effectiveBranches(for:savedPlaces:)` instead of `errand.candidates`.
- `handleEntry`: fetch all `SavedPlace` once; the errand-matches-store test becomes `effectiveBranches(for: errand, savedPlaces: savedPlaces).contains { Self.storeKey(for: $0) == storeID }`.
- New published state for the distance labels: `@Published private(set) var lastKnownLocation: CLLocation?` — set from `manager.location` in `configure(container:)` and updated at the top of `didUpdateLocations`.

**Verification:** `swift test` still green locally; push → CI green (this push carries 2.9.2 + 2.9.3).
**Commit:** `feat: saved places and pinned branches in engine`

### Task 2.9.4: ErrandDetailView v2 — addresses, distances, pin↔card selection

**Files:**
- Modify: `App/Sources/Views/ErrandDetailView.swift`

**Behavior (complete spec):**
- Branch list becomes `effectiveBranches` (auto + pinned + place-book), **sorted nearest-first** by distance from `engine.lastKnownLocation` (unsorted at the end when location unknown).
- Each card: name (headline) + address (caption, when known) + distance ("850 m" below 1 km, else "2.3 km") + the existing three toggles. Pinned/place-book branches get a `pin.fill` badge next to the name and an **Unpin** swipe/context action instead of Exclude (unpin = remove the value copy from `errand.pinned`, save, replan). Auto branches keep the Exclude quick action.
- **Pin↔card selection:** `@State private var selectedKey: StoreID?`; the map becomes `Map(selection: $selectedKey)` with each `Marker` `.tag(storeKey)`; wrap the List content in `ScrollViewReader`; `.onChange(of: selectedKey)` → `withAnimation { proxy.scrollTo(selectedKey) }`; each card `.id(storeKey)` + subtle background highlight when selected; tapping a card sets `selectedKey` (which also highlights its pin).
- Marker tint: gray excluded, orange pinned/place-book, blue auto.
- Toolbar button **"Add a location"** (`plus.magnifyingglass`) presents the Task 2.9.5 sheet.

**Verification:** compiles on CI (bundled into Task 2.9.5's push).
**Commit:** `feat: branch cards with address, distance, linked map selection`

### Task 2.9.5: AddLocationSheet + SavedPlacesView

**Files:**
- Create: `App/Sources/Views/AddLocationSheet.swift`
- Create: `App/Sources/Views/SavedPlacesView.swift`
- Modify: `App/Sources/ContentView.swift` — bookmark toolbar icon (left of the wrench) → `SavedPlacesView`

**AddLocationSheet (complete spec):**
- Search `TextField` ("Name of the place, e.g. Yaletown Animal Hospital") with `.onSubmit` → one `MKLocalSearch` (reuse the 20 km-region pattern from `StoreResolver.resolve`, but inline — this is UI code, results are NOT cached).
- Result rows: name + address + distance from `engine.lastKnownLocation`; tapping one shows a nickname alert (`TextField` pre-filled with the place name, prompt "What do you call this place? e.g. Furfur's vet").
- Confirm → (1) append the value copy to `errand.pinned`, (2) insert a `SavedPlace`, (3) `try? context.save()`, (4) `LocationEngine.shared.requestReplan()`, (5) dismiss. Empty nickname → fall back to the place name.
- States: idle hint text, "Searching…" progress, "No places found — try the exact name" empty state.

**SavedPlacesView (complete spec):**
- `@Query(sort: \SavedPlace.nickname)` list: nickname (headline), name + address (caption).
- Swipe delete (footer explains: stops future auto-attaching; already-pinned errands keep it). Tap → rename-nickname alert. Renaming or deleting → save + `requestReplan()`.
- Empty state: "No saved places yet. Pin one from any errand's Add a location."

**Verification:** push → CI green → download .ipa → verify strings (`AddLocationSheet`, `SavedPlacesView`, `SavedPlace`, "No places found") → copy `Errands.ipa` to project root.
**Commit:** `feat: search-and-pin sheet and saved places screen`

### Task 2.9.6: Hand-off to user

Write `docs/TEST-2.9-PLACES.md` (PROBE style, tap-by-tap): sideload → open the jersey errand → cards show addresses + distances, nearest first → tap a map pin, watch its card highlight/scroll → open the Furfur errand → Add a location → search the vet's real name → pin it, nickname "Furfur's vet" → wrong vets excluded via the existing quick action → Replan now in Diagnostics → pinned ring present, wrong-vet rings gone → force-quit + relaunch → pin still there → add a fresh errand "buy treats from his vet" by voice → the saved place attaches by itself (this is the payoff moment) → Saved places screen: rename, delete. Update `TASK.md`.

**Commit:** `docs: Gate K user test script`

> ### 🚦 GATE K — Place book verified on-phone
> **Evidence (user confirmation):** addresses + distances identify branches; pin↔card selection works both directions; a pinned place survives replans and relaunch; a NEW voice errand mentioning the nickname auto-attaches the saved place; deleting the saved place stops future attaching without touching existing pins.

---

## Milestone 3 — Phase 2: drive-mode look-ahead (plan later, deliberately)

Per DESIGN.md §8, Phase 2 (temporary drive-mode coarse tracking, 5–8 km corridor projection, optional MKDirections road-distance check, "heads-up" notification tier) is **not planned in detail here on purpose**: its parameters (corridor width/length, wake cadence, anti-spam rules) should be tuned with real Phase 1 field data. After GATE H/I pass, write `docs/plans/<date>-phase2-lookahead.md` with the same gate discipline.

---

## Standing risks & their assigned gates

| Assumption | Gate | If wrong |
|---|---|---|
| Free CI can build unsigned .ipa | A | Project not feasible at $0 — stop |
| Free Apple ID sideloading works on this PC/phone | B–C | Try Sideloadly; else stop |
| Background geofencing under free signing | D | Major re-design needed |
| Shortcut→intent without opening app | E | Voice UX degrades — renegotiate UX |
| MKLocalSearch fuzzy quality | F | Add category search / tune phrases |
| Windows Swift toolchain | 2.0 | TDD via CI instead (slower, same rigor) |
| AltStore weekly auto-refresh | I | User does manual weekly refresh (1 tap) |
