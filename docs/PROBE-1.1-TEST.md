# Gate D Test — Background Geofencing Probe (Task 1.1)

This is the single most important test of the whole project: it proves iOS will
wake our app and deliver a notification when you cross a location boundary,
**even when the app is completely closed**, under a free Apple ID.

## Step 1 — Install the new version on the phone

1. Plug the iPhone into the PC with the USB cable (or be on the same WiFi with AltServer running).
2. On the PC: **Shift-click** the AltServer icon in the system tray (bottom-right, near the clock).
3. Click **Sideload .ipa** → pick the file `Errands.ipa` from this project folder.
4. Wait for "Installation Succeeded". The Errands app on the phone is now v0.2.

## Step 2 — Set up permissions (one time, in the app)

1. Open **Errands** on the phone → tap **Geofence Probe**.
2. Tap **Request notification permission** → tap **Allow**.
3. Tap **Request Always permission** → iOS asks about location → choose **Allow While Using App**.
4. Tap **Request Always permission** a *second* time → choose **Change to Always Allow**.
   - The screen should now show: `Location: Always ✓`
   - If iOS doesn't show the second popup: Settings → Privacy & Security → Location Services → Errands → tap **Always**.

## Step 3 — Plant the tripwire at home

1. Stand anywhere at home. In the app, tap **Plant tripwire here (300 m)**.
2. The event log should show a line like `Planted 300 m tripwire at 39.xxxxx, -108.xxxxx`.
3. Now **close the app completely**: swipe up from the bottom and hold → swipe the Errands card up and away. (Yes, really — the test is whether iOS revives it.)

## Step 4 — The walk

1. Walk away from home in a straight line, at least **500 m** (about 6–7 minutes of walking). Phone in your pocket is fine — do NOT open the app.
2. Somewhere past ~300–400 m you should get a notification: **"EXITED tripwire"**.
   - It may lag 1–3 minutes after actually crossing — that's normal for geofencing.
3. Turn around and walk home.
4. On the way back you should get: **"ENTERED tripwire"**.

## Step 5 — Report back

Open the app → Geofence Probe → check the event log shows the EXIT and ENTER
events with timestamps. Then tell Claude either:

- ✅ "Gate D passed — got both notifications" (mention roughly when each arrived), or
- ❌ what happened instead (no notifications? only one? app log empty?) — include what the
  Location line says on the probe screen.

**Do not worry if it fails** — this probe exists exactly to find that out cheaply.
