# Task 2.4/2.5 Check — Real Errand List + First Reminders Build

The app has grown up: the main screen is now your actual errand list, not the
probe menu. Behind the scenes it also got its "location engine" — the part
that quietly plants tripwires around matching stores. This test only checks
the list; the tripwire behavior gets its own bench test after the voice flow
lands (Gate G).

The probes did NOT go away — they moved behind the little wrench icon (top
right corner), under "Diagnostics".

## Step 1 — Sideload

As usual: plug the iPhone in via USB → Shift-click the AltServer tray icon →
**Sideload .ipa** → pick `Errands.ipa` from the project folder
(`C:\Users\alica\python_projects\todo-geo-app`).

## Step 2 — Add an errand by typing

(Typing is temporary — the voice path connects to this same list in the next
build.)

1. Open Errands. You should see an **Add errand** box, a **To do** section,
   and a wrench icon top right.
2. Tap the text box and type exactly: **buy lentils from walmart or city market**
3. Tap **done** on the keyboard.
4. Expect: a new row "**buy lentils**" with small gray text under it:
   "**walmart · city market**" — that means the sentence-splitting brain
   (the same one the voice flow will use) parsed it correctly.

## Step 3 — Complete and delete

1. Swipe the new row **left-to-right** (drag it toward the right edge) → a
   green **Done** button appears → tap it (or swipe all the way).
2. The row moves to a **Done** section, crossed out.
3. Swipe it right-to-left → red **Delete** → don't tap it yet.

## Step 4 — The real test: does it survive a restart?

1. Add one more errand, e.g. **pick up prescription at walgreens**.
2. Close the app COMPLETELY: swipe up from the bottom and hold → app cards
   appear → flick the Errands card up and away.
3. Reopen Errands.
4. Expect: your errand is still there, exactly as you left it (and the
   completed one still shows under Done). That proves the app now has a real
   memory (a small database on the phone), not just whatever was on screen.

## Step 5 — Report back

- Did the typed sentence split into title + stores correctly?
- Did complete / undo / delete behave?
- Did everything survive the full close-and-reopen?
- If location or notification permission popups appeared at any point, what
  did they say? (Not expected — you granted them during the probes — but
  worth noting.)
