# Gate F Test — Store Search + Motion (Task 1.3)

Two small probes, both testable from the couch (plus one later check in the car).

- **Search Probe** answers: when you say "persian market", can Apple's map
  search find the actual store near you? This powers the whole
  "remind me near any matching branch" idea.
- **Motion Probe** answers: does the phone reliably know walking vs. driving
  vs. sitting still? This decides how far ahead reminders should fire.

## Step 1 — Sideload

As usual: Shift-click AltServer tray icon → **Sideload .ipa** →
`Errands.ipa` from the project folder.

## Step 2 — Search Probe

1. Open Errands → **Search Probe**.
2. Type **walmart** → tap **Search**. Expect a list of real Walmart branches,
   nearest first, with sensible distances (km).
3. Try **city market** → real City Market branches?
4. Try **persian market** → does it find the Persian/Middle-Eastern grocery
   you actually go to (Aria)? If it finds something else or nothing, note
   exactly what it listed — that tells us how much fuzziness the real app
   must add.

## Step 3 — Motion Probe

1. Open Errands → **Motion Probe** → tap **Start motion updates**.
2. A popup asks about **Motion & Fitness** → tap **Allow**.
3. Sit still a moment → Activity should say **stationary**.
4. Walk around the room/house with the phone → within ~10–30 seconds it
   should switch to **walking** (confidence medium/high).
5. (Whenever you next drive somewhere, open this screen as a passenger-style
   glance: it should say **driving**. Not needed today.)

## Step 4 — Report back

- What the top 2–3 results were for each search (names + rough distances) —
  especially what "persian market" returned.
- What the Motion Probe showed sitting vs. walking.
