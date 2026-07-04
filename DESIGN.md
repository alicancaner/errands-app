# Your Errand App — Design (2026-07-04)

*A to-do app for one person: add tasks by voice, get reminded when you're near a matching store — any branch, anywhere. Total cost: $0, forever.*

## Decisions already made (from our conversation)

- **You want your own custom app** — not an existing product. Building it.
- **$0 forever.** No Apple developer fee, no subscriptions. The app gets installed through the free "sideloading" route (details in section 5).
- **"Any Walmart, anywhere"** — including cities you travel to. The app finds store branches dynamically; nothing is pre-pinned.
- Your hardware: iPhone 13 (no Apple Intelligence — so no on-device AI; we don't need it), Windows PC, no Mac.

## 1. What gets built

One iPhone app (written in Swift, Apple's own language — the most reliable choice for location features), plus a tiny Siri shortcut that acts as its voice doorbell. No server, no account, no internet service holding your data.

## 2. Adding a task

You double-tap the **back of your phone** (a real iPhone 13 feature called Back Tap) or say **"Hey Siri, errand."** The phone starts listening immediately — no unlocking, no opening an app. You say *"buy lentils from Walmart."* Done, pocket the phone.

Behind the scenes the app pulls out "buy lentils" and "Walmart." If you name several stores — *"Walmart or City Market or Aria"* — it tags all three. If you name **no** store, it asks you right then: *"Where from?"* — and you answer by voice.

Store names don't need to be exact: "the Persian market" gets checked against Apple Maps' real search engine (the same one inside the Maps app), which handles sloppy, natural phrasing.

## 3. Getting reminded

The app keeps a rolling watchlist. Wherever you happen to be — home, or a city you've never visited — it asks Apple Maps "any Walmarts near here?" for each store on your open tasks, and plants invisible tripwires (geofences) around the closest matches. **iOS itself watches the tripwires**, the same way it does for Apple's own Reminders — your battery is not drained by constant GPS.

**Speed-aware timing (two-ring system):** each store gets a big outer ring (~1.5–2 km) and, when needed, a small inner ring (~250 m). Crossing the outer ring wakes the app for a few seconds; it asks the phone's built-in motion chip (the same one Apple Maps uses) whether you're **driving or walking**. Driving → buzz immediately, 1–2 km out, with time to take the exit. Walking → stay silent and plant the small inner ring; buzz only when you're a few hundred meters away on foot. This also absorbs iOS's tripwire-detection delay (up to ~a minute), which at highway speed would otherwise mean getting buzzed after you've already passed the store. Adds one extra permission toggle ("Motion & Fitness") on first run.

As you travel, the tripwires quietly re-plant themselves around your new surroundings. When you're driving, the re-planting is **direction-biased**: most of the 20 tripwires go to stores in the cone ahead of you, not behind you.

**Look-ahead heads-up while driving (Phase 2):** once the foundation above is proven in the field, the app gains a "drive mode." When it notices you've started driving, it checks your position every ~500 m (coarse, small battery cost, only during drives), projects a corridor ~5–8 km ahead along your direction of travel, and checks whether any store tagged to an open task sits in it — optionally confirming road distance via Apple Maps. If so, a soft heads-up: *"A Walmart is ~4 km ahead — buy lentils, in case you want to stop."* Anti-spam logic prevents the same store from buzzing repeatedly in one drive. Honest limit: the app sees your heading, not your route — on highways it guesses well; in city grids it will sometimes flag a store you weren't heading toward, or miss one around a bend. That's why this tier is phrased as "in case you want to," separate from the confident "you're here" buzz. Deliberately NOT built: telling the app your destination before leaving — rejected because the user shouldn't have to do work.

**Privacy:** your location never leaves the phone. The only thing that touches the internet is the map search ("Walmart near me"), which goes to Apple — identical to typing it into the Maps app yourself.

## 4. The list itself

Open the app and there's a plain list: every task, which stores it's tied to, swipe to mark done. Completing a task removes its tripwires.

## 5. How it gets on your phone — the $0 machinery

- The app's code lives on GitHub (a free code-hosting site), whose free service builds it into an installable app.
- On your Windows PC we install **AltServer**, a small free helper. One-time setup: it signs the app with your regular Apple ID and installs it to your phone over USB.
- After that, whenever your phone is on your home WiFi, AltServer silently renews Apple's 7-day permission slip.
- **Your only maintenance:** the PC must be on, at home, at least once a week while your phone is on the same WiFi.
- **The accepted weakness:** away from home 7+ days and the app goes to sleep (your list is safe) until you're back on home WiFi.

## 6. What could go wrong — honestly

1. **Checkpoint #1, before anything else is built:** confirming background location works under the free signing method. I'm confident it does, but it gets tested first.
2. Finding stores in a brand-new area needs an internet connection as you move. With no signal, new tripwires can't be planted (already-planted ones still fire).
3. The buzz happens ~1.5–2 km out when driving, ~250 m when walking (see the two-ring system in section 3).
4. Apple caps tripwires at 20 at a time per app, and your tasks can imply more matching store locations than that. So the app plays musical chairs: every time you've moved a meaningful distance, it re-picks the 20 most relevant nearby store locations and swaps tripwires accordingly. A bug here fails *silently* (you pass a store, no buzz, nothing looks wrong) — which is why it gets tested hardest and why the app has a diagnostics screen showing the currently planted tripwires.

## 7. Building and testing

I write all the code, plus automated tests for the sentence-understanding part (those run free on GitHub too). Location behavior gets tested in the real world: the app includes a hidden diagnostics screen showing its current tripwires, so if you drive past a Walmart and nothing buzzes, we can see exactly why.

## 8. Build order

- **Phase 1:** voice-add, task list, Apple Maps store matching, tripwires with the two-ring speed-aware system, direction-biased juggling, diagnostics screen, the $0 install pipeline. Then 1–2 weeks of real-world driving/walking to confirm reminders fire reliably.
- **Phase 2:** drive-mode look-ahead heads-up ("a Walmart is ~4 km ahead"), built on the proven foundation.

---

**Status: awaiting your approval before any code is written.**
