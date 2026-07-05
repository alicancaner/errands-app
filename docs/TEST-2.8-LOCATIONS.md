# Task 2.8 Check — Manual Location Control (Gate J)

You asked for this one: the 20 tripwire slots are precious, and only you know
"I'll never go to THAT branch." From this build, every errand row opens a
detail screen where you can see exactly which places matched, kick out the
useless ones, and choose per branch whether it may remind you while driving,
while walking, or both. Your choices are remembered forever — excluding a
branch once silences it for every future errand too.

## Step 1 — Sideload

As usual: plug the iPhone in via USB → Shift-click the AltServer tray icon →
**Sideload .ipa** → pick `Errands.ipa` from the project folder.

## Step 2 — Open an errand's detail screen

1. Open Errands. You need at least one open errand with stores tagged — if
   the list is empty, add one by voice (Back Tap) or use the text field,
   e.g. **"buy lentils from walmart"**.
2. Tap the errand row itself (not the swipe buttons). A detail screen opens.
3. You should see:
   - The errand title and its store tags at the top.
   - A **map** with a marker on every matched branch (blue = active).
     If it says "not resolved yet", give it a minute — it needs a location
     fix and a map search — then come back.
   - Below the map, **one row per branch** with three switches:
     **Use this location**, **Remind when driving**, **Remind when walking**.

## Step 3 — Exclude a branch and watch its rings vanish

1. Pick a branch you'd never actually go to. Note its name.
2. Flip **Use this location** OFF (or: swipe the row left / press and hold →
   **Exclude this location** — same thing, one gesture).
3. Its map marker should turn **gray**, and the two reminder switches go dim.
4. Now tap Back, then the **wrench icon** (top right) → Diagnostics.
5. Look at the **Planted tripwires** map and tap **Replan now**. Within a
   minute or so (leave and re-enter the screen if needed), the excluded
   branch's circle should be **gone** — and it must STAY gone no matter how
   many times you tap Replan now. That's the whole point: the exclusion
   outlives every replan.
6. Also in Diagnostics: a new **Excluded locations** section should list the
   branch you just excluded.

## Step 4 — Reminder switches survive a relaunch

1. Go back to the errand's detail screen.
2. On a branch that's still active, flip **Remind when walking** OFF (leave
   driving ON).
3. Now force-quit Errands: swipe up from the bottom and hold → swipe the
   Errands card away. Reopen the app.
4. Return to the errand's detail screen. Expect: the excluded branch is
   still excluded (gray), and that walking switch is still OFF. Nothing
   forgot anything.

## Step 5 — Bring the branch back from Diagnostics

1. Wrench icon → Diagnostics → **Excluded locations**.
2. Tap **Include again** next to your excluded branch.
3. It disappears from the excluded list. Back on the tripwires map, after a
   Replan now (and a little patience), its blue circle should be **back**.

Why this lives in Diagnostics too: if you exclude a branch and later finish
(or delete) the errand, the detail screen is gone — this list is how you'd
ever un-exclude it.

## Step 6 — Bonus quick action (optional)

In Diagnostics, in the region list under the map (the rows saying
"outer · 1750 m"): press and hold any row → **Exclude this location**. This
is for the moment you spot a ring on the map and think "that branch is 26 km
away, why is it using a slot?" — you can kill it right there.

## Step 7 — Report back (this is Gate J)

- Did the excluded branch's rings disappear after Replan now — and stay
  gone across several replans?
- After force-quit + reopen: exclusion still shown, walking switch still OFF?
- Did "Include again" bring the rings back?
- Anything confusing about the three switches or where things live?
