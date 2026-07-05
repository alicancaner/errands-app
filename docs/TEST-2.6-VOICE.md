# Task 2.6/2.7 Check — Voice Add + Diagnostics

This is the big one: the voice path now feeds your REAL errand list, and the
app got its "flight recorder" — a Diagnostics screen showing exactly what it
is watching and why. After this test, only the bench test (Gate G) stands
between you and using the app for real.

## Step 1 — Sideload

As usual: plug the iPhone in via USB → Shift-click the AltServer tray icon →
**Sideload .ipa** → pick `Errands.ipa` from the project folder.

## Step 2 — Open the app once (do not skip)

Open Errands and just look at it for a second. This matters: iPhones only
tell Shortcuts about a new app action AFTER the app has been opened once.
If you skip this, the next step won't find "Add Errand".

## Step 3 — Rewire your "Errand" shortcut

Your shortcut currently calls the old probe action ("Add Text"). Point it at
the real one:

1. Open the **Shortcuts** app → find your **Errand** shortcut → tap the
   **⋯** (three dots) on its card to edit it.
2. You'll see two blocks: **Dictate Text**, then **Add Text**.
3. Remove the **Add Text** block: tap the **✕** on that block (keep
   Dictate Text!).
4. Tap **Add Action** (or the search bar at the bottom) → type **Errands** →
   under the Errands app, pick **Add Errand**.
5. The new block should say something like "Add Errand with **Text**". If the
   blue **Text** token doesn't already say "Dictated Text": tap it → a
   variable picker appears → choose **Dictated Text**.
6. Tap **Done** (top right).

## Step 4 — Voice round trip #1 (store named)

1. Double-tap the **back of your phone** (your Back Tap trigger).
2. When it listens, say: **"buy lentils from walmart or city market"**
3. Expect a small confirmation like "Added: buy lentils — walmart, city
   market" (a banner or Siri speaking — either is fine; the app must NOT
   open).
4. Open Errands → the errand should be in **To do**, tagged
   "walmart · city market".

## Step 5 — Voice round trip #2 (the "Where from?" follow-up)

1. Say **"Hey Siri, Errand"** (or Back Tap again).
2. Say just: **"buy stamps"** — deliberately naming no store.
3. Expect it to ask you **"Where from?"** — answer by voice: **"the post
   office"**.
4. Open Errands → "buy stamps" should be tagged "the post office".

## Step 6 — Tour the new Diagnostics screen

1. In Errands, tap the **wrench icon** (top right).
2. **Planted tripwires** map: after a minute or two (it needs a location fix
   and a map search), you should see blue circles appear around real store
   locations near you — those are your walmart/city market tripwires. Tap
   **Replan now** if it looks empty, wait a bit, leave and re-enter the
   screen.
3. **Region slots**: shows how many of the 20 iOS slots are used.
4. **Permissions**: Location should say "Always ✓", the others "Allowed ✓".
5. **Store caches**: each errand with how many branches it found and when
   that search expires.
6. **Engine log**: lines like "Wake at …", "Resolved N branches…",
   "Planned N regions…".
7. **Raw dictated utterances**: the EXACT sentences you spoke in steps 4–5,
   word for word. This list is the whole point of the field week — it teaches
   us how you really phrase things.

## Step 7 — Report back

- Did both voice adds land correctly (titles + stores)?
- Did "Where from?" ask and accept your answer?
- Did the app stay closed during both adds?
- What does the Diagnostics map show (circles where you'd expect)?
- Read me 2–3 lines from the Engine log and the utterance list.
- Anything that felt clunky about the voice flow.
