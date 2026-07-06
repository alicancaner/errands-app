# Task 2.9 Check — Know Your Places (Gate K)

This build fixes the two things you hit during the last test: branch cards
you couldn't tell apart, and wrong matches you couldn't correct. Every branch
card now shows its **street address** and **how far away it is**, nearest
first, and tapping a map pin finds its card for you. And when the app guesses
wrong ("his vet" → two wrong vets), you can now **search for the right place
yourself, pin it, and give it a nickname** — the app remembers it forever in
a **place book**, so any future errand that mentions the nickname attaches it
automatically.

One heads-up: branches matched **before** this build won't show an address
until the app refreshes them on its own (up to a day, or when you move far).
Fresh errands show addresses right away.

## Step 1 — Sideload

As usual: plug the iPhone in via USB → Shift-click the AltServer tray icon →
**Sideload .ipa** → pick `Errands.ipa` from the project folder.

## Step 2 — Telling branches apart

1. Add an errand that matches many branches if you don't have one, e.g.
   **"buy a Spain jersey from adidas or nike or puma"** (voice or text field).
2. Tap the errand row to open its detail screen.
3. Expect on each branch card: the **name**, the **street address** under it,
   and a distance like **"850 m away"** or **"2.3 km away"** — with the whole
   list sorted **nearest first**.
4. Tap any **pin on the map**. Expect: the list scrolls to that branch's card
   and the card is briefly tinted — no more guessing which pin is which card.
5. Tap a **card**. Expect: its map pin highlights.

## Step 3 — Pin the right place (Furfur's vet)

1. Add the errand that went wrong last time, e.g.
   **"pick up Furfur's medication from his vet in Yaletown"**.
2. Open its detail screen. The wrong vets will likely be there again — that's
   expected, we're about to fix it for good.
3. Tap the **magnifying-glass-with-plus icon** (top right) → **Add a location**.
4. In the search field, type the vet's **real name** (the actual clinic name)
   and hit Search.
5. Tap the right result (check its address and distance!). A box pops up
   asking **"What do you call this place?"** — type **Furfur's vet** → Save.
6. Back on the detail screen: the pinned place appears as a card with an
   **orange pin badge**, and its map marker is **orange**.
7. Now silence the wrong vets the usual way: swipe each wrong branch left →
   **Exclude** (they turn gray).

## Step 4 — The pin survives everything

1. Wrench icon → Diagnostics → **Replan now**. Expect on the tripwires map:
   a ring on the **pinned vet**, and **no rings** on the excluded wrong vets.
   Tap Replan now a few more times — the pin must never disappear.
2. Force-quit Errands (swipe up and hold → swipe the card away) and reopen.
3. Back to the errand's detail screen. Expect: the pinned vet is still there,
   orange badge and all.

## Step 5 — The payoff: the place book remembers

1. Add a **brand-new** errand by voice: **"buy treats from his vet"**.
2. Open the new errand's detail screen. Expect: **Furfur's vet is already
   attached** — orange badge, no searching, no pinning. The app matched the
   word "vet" in what you said against the nickname you saved. This is the
   whole feature paying off.

## Step 6 — Managing your place book

1. Go back to the main list. Next to the wrench there's now a **bookmark
   icon** — tap it. **Saved places** lists everything you've pinned.
2. Tap **Furfur's vet** → rename it (e.g. "Furfur's clinic") → Save.
3. Swipe it left → **Delete**. Expect: it stops attaching to FUTURE errands,
   but the errands where you already pinned it **keep** it — check the treats
   errand: the vet must still be there.

## Step 7 — Report back (this is Gate K)

- Could you tell branches apart by address + distance, nearest first?
- Did pin↔card tapping work in **both** directions?
- Did the pinned vet survive several Replan nows AND a force-quit?
- Did "buy treats from his vet" attach the saved place **by itself**?
- After deleting the saved place: no future attaching, existing pin kept?
- Anything confusing about pinning, nicknames, or the bookmark screen?
