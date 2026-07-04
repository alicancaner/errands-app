# Gate E Test — Shortcut → App Intent (Task 1.2)

This probe tests the voice-entry path: double-tap the back of the phone →
speak → the text lands inside the Errands app, **without the app ever opening**.

## Step 1 — Sideload the new version

Same as always: iPhone plugged in → Shift-click the AltServer tray icon →
**Sideload .ipa** → pick `Errands.ipa` from the project folder.
Then **open the Errands app once** and close it again (this registers the new
"Add Text" action with iOS — required before Shortcuts can see it).

## Step 2 — Build the "Errand" shortcut (one time)

1. Open the **Shortcuts** app (pre-installed; icon is two overlapping squares on blue).
2. Tap **+** (top-right) to create a new shortcut.
3. Tap **Add Action** → in the search box type **Dictate Text** → tap **Dictate Text**.
4. Tap **Add Action** again (or the ⊕/search bar below the first action) → search **Errands**
   → you should see **Add Text** (our app's action) → tap it.
5. Make sure the "Text" slot of **Add Text** contains the blue token **Dictated Text**.
   (Shortcuts usually wires this automatically. If the slot is empty: tap it →
   tap **Dictated Text** in the variable bar above the keyboard.)
6. Tap the name at the top ("New Shortcut") → **Rename** → call it exactly: **Errand** → tap **Done**.

## Step 3 — Hook it to Back Tap (one time)

1. **Settings** → **Accessibility** → **Touch** → scroll to the bottom → **Back Tap**.
2. Tap **Double Tap** → scroll down to the SHORTCUTS list → pick **Errand**.

## Step 4 — Test it

1. Go to the home screen (Errands app closed).
2. **Double-tap the back of the phone** (two firm taps with a fingertip, near the Apple logo).
3. A dictation UI should appear → say: **"testing one two three"** → it should stop
   listening when you pause (or tap Done).
4. **The Errands app must NOT open during this.** A small banner/checkmark is OK.
5. Now open Errands → **Intent Log** → your words should be listed with a timestamp.
6. Repeat once via Siri: say **"Hey Siri, Errand"** → speak when prompted → check the log again.

## Step 5 — Report back

- ✅ "Gate E passed" — text arrived both ways, app never opened during capture, or
- ❌ what actually happened (Add Text action not listed in Shortcuts? App opened
  during capture? Text missing from the log? Dictation didn't start?).
