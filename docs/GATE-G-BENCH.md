# GATE G — Bench Test (controlled, same-day)

Everything is built. This test answers one question in a controlled way,
before trusting the app in daily life: **do the reminders actually buzz at
the right distance, both driving and walking?**

No sideload needed — you already have the right build.

## Part 1 — The driving buzz

**Setup (at home, 2 minutes):**

1. Add an errand by voice (Back Tap), tagged to a store roughly 1–3 km away
   that you can drive to — e.g. *"buy milk from city market"*.
2. Open Errands → wrench icon → check the map: you should see a blue circle
   (the big outer ring, 1.75 km across its radius) around that store. If the
   map looks empty, tap **Replan now**, wait ~30 seconds, leave and re-enter
   the screen.
3. **Close the app completely** (swipe up and flick it away). This is the
   honest test — the reminders must work with the app dead.
4. Lock the phone, put it in your pocket.

**The drive:**

5. Drive toward the store the way you normally would.
6. **Expected:** somewhere around 1–2 km from the store, your phone buzzes
   with "buy milk — City Market is nearby". Note roughly where you were when
   it buzzed (street or landmark is fine).
7. You do NOT need to actually stop at the store. Drive past or turn around.

**Note:** iOS can take up to a minute to notice you crossed a ring, so at
city speeds the buzz may come a little "late" (closer to the store than
1.75 km). That's expected — it's why the ring is planted so wide.

## Part 2 — The walking buzz (inner ring)

1. Add an errand by voice for a store you can walk to (or walk near), e.g. a
   nearby pharmacy or market.
2. Same drill: check the ring exists on the map, close the app fully.
3. Walk toward the store — phone in pocket is fine.
4. **Expected behavior, two stages:**
   - Crossing the big ring while walking: **silence** (deliberately — a
     buzz 1.7 km out on foot would be useless). Behind the scenes it plants
     a small orange 250 m ring — if you're curious, the wrench map will
     show it afterwards.
   - Getting within a few hundred meters: **buzz**.
5. Note roughly how far from the store you were when it buzzed.

## Part 3 — Completing kills the tripwires

1. After a buzz, open the app and swipe the errand to **Done**.
2. Check the wrench map: that store's rings should disappear (tap Replan
   now if they linger for more than a minute).

## If anything doesn't buzz

Don't troubleshoot in the field — just open the wrench screen right away
and read me:

- The **Engine log** lines from around that time (wakes? ENTER events?
  suppressions?).
- Whether the store's ring was actually on the map, and where its circle
  sits versus where the store really is.
- The **Permissions** section (Location must say "Always ✓").

That log exists precisely for this moment — a miss with a log is progress,
not failure.

## Report back

- Where the driving buzz arrived (roughly how far from the store).
- Whether walking stayed silent at the big ring and buzzed close-in.
- Whether completing the errand removed its rings.
- Anything odd (double buzzes, buzzes for the wrong store, etc.).
