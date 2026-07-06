# Design: Location control v2 — "know your places" (Task 2.9)

**Date:** 2026-07-05 · **Status:** approved by user · **Origin:** user feedback
while running the Gate J test (docs/TEST-2.8-LOCATIONS.md).

## The two problems (user-reported, on-phone)

1. **Branches are indistinguishable.** "buy a Spain jersey from adidas or nike
   or puma" matches many branches, but every card just says "Adidas" — no
   address, no distance, no way to tell which pin on the map is which card.
   Root cause: `MKLocalSearch` returns a full address with every result;
   `StoreResolver` discards it (`CachedCandidate` keeps only name/lat/lon).

2. **Wrong matches can't be corrected.** "pick up Furfur's medication from his
   vet in Yaletown" matched two wrong vets. Expected — Gate F proved category
   descriptors are the weak path — but there is no way to attach the RIGHT
   place to the errand.

## Decisions (each confirmed with the user)

| Question | Decision |
|---|---|
| Branch identification | Street address + distance-from-me on every card, sorted nearest-first; map pins tappable and linked to cards (pin↔card selection); actions stay on the cards only |
| Fixing wrong matches | Search-and-pin only (NO store-phrase editing) |
| Pin vs auto-matches | Coexist — pins are added alongside automatic matches; wrong guesses are silenced with the existing global exclude |
| Pin lifespan | Saved places with nicknames — pinning also saves the place to a global place book; future errands whose store phrase mentions the nickname attach it automatically |

## Design

### 1. Telling branches apart

- `CachedCandidate` gains `address: String?` (from `MKMapItem.placemark`).
  Optional → old cached rows keep decoding; addresses appear after each
  errand's next automatic re-resolve.
- Branch cards show name + address + distance from current position, sorted
  nearest-first. Distance comes from the engine's last known location.
- `Map(selection:)` with tagged `Marker`s: tapping a pin highlights and
  scrolls to its card; tapping a card highlights its pin. Toggles remain on
  cards only — no duplicate controls in map popups.

### 2. Pinning the right place (search-and-pin)

- "Add a location" button on `ErrandDetailView` opens a sheet: search field →
  `MKLocalSearch` results (name, address, distance) → tap one → nickname
  prompt (pre-filled with the place name, e.g. "Furfur's vet") → save.
- Saving does two things: attaches the place to THIS errand and creates a
  `SavedPlace` in the global place book.

### 3. Data model

- New `@Model SavedPlace`: `nickname`, `name`, `address`, `lat`, `lon`,
  `createdAt`. Global, in the shared container.
- `Errand` gains `pinned: [CachedCandidate]` — a VALUE COPY, stored separately
  from the disposable `candidates` cache, so re-resolves/replans can never
  wash a pin away, and deleting a SavedPlace later doesn't rip it out of
  errands where it's already pinned.
- Replan unions `pinned + candidates` per errand (deduped by storeKey).
  Pinned branches show a pin badge; they can be un-pinned; reminder toggles
  and the global exclude apply to them like any branch.

### 4. Nickname matching (the place book paying off)

- At resolve time, each store phrase is checked against saved-place nicknames:
  whole-word, case-insensitive overlap ("his vet" matches nickname "Furfur's
  vet" via the word "vet"; "vet" never matches "velvet"). Matching places are
  attached automatically alongside search results.
- The matcher is pure logic → lives in ErrandKit (`SavedPlaceMatcher`), TDD
  like UtteranceParser.

### 5. Managing saved places

- "Saved places" screen behind a bookmark icon next to the wrench on the main
  screen: list, rename nickname, delete. Deleting stops future auto-attaching
  only.

### 6. Unchanged

Global exclude list, reminder toggles, two-ring machinery, 20-slot planner,
one bundle ID, $0. Pure Phase-1 UI/data work — no field-test gate evidence
needed to build; Gate J (Task 2.8 mechanics) proceeds independently on the
current build.

## Testing

- ErrandKit TDD: `SavedPlaceMatcher` (whole-word nickname matching: match,
  no-substring-match, case-insensitivity, multi-word nicknames).
- Engine/UI verified via CI build + on-phone script (Gate K:
  docs/TEST-2.9-PLACES.md — pin Furfur's real vet, see address/distance on
  cards, pin survives replans and relaunch, future "his vet" errand
  auto-attaches).
