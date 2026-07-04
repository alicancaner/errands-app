# One-Time Setup: AltServer (PC) + AltStore (iPhone)

This is Task 0.4 from the plan — the only one-time manual setup in the whole project.
Everything here is free. When you're done, the AltStore app should open on your iPhone
(that's Gate B). Do the steps in order.

## Part 1 — On your Windows PC

1. **Install iTunes — from Apple's website, NOT the Microsoft Store.**
   - Go to: https://support.apple.com/en-us/106372 (Apple's "Download iTunes for Windows" page)
   - Under "Windows", look for the link to download iTunes **directly from Apple**
     (64-bit installer, a file like `iTunes64Setup.exe`). Do **not** click any button
     that opens the Microsoft Store — AltServer cannot work with the Store version.
   - Run the installer, accept defaults. You do NOT need to open iTunes or sign in.

2. **Install iCloud for Windows — the standalone version, NOT the Microsoft Store one.**
   - ✅ Already handled: Claude downloaded `iCloudSetup.exe` (v7.21, the last standalone
     version Apple made) directly from Apple's server into your **Downloads** folder and
     verified its digital signature is **Valid — signed by Apple Inc.**
   - Double-click `iCloudSetup.exe` in Downloads, accept defaults. You do NOT need to
     open iCloud or sign in to it.
   - (For the record, the working Apple URL is:
     https://secure-appldnld.apple.com/windows/061-91601-20200323-974a39d0-41fc-4761-b571-318b7d9205ed/iCloudSetup.exe )

3. **Install AltServer.**
   - Go to https://altstore.io and click the **Windows** download (it's a small zip:
     `AltInstaller.zip`).
   - Open the zip → run `setup.exe` → finish the installer.
   - Start **AltServer** (Start menu → type "AltServer"). It runs quietly as a small
     diamond icon in the system tray (bottom-right corner of your screen, near the
     clock — you may need to click the `^` arrow to see hidden icons).

## Part 2 — Connect the iPhone (cable needed once)

4. Plug your iPhone 13 into the PC with a USB cable.
5. If the phone shows **"Trust This Computer?"** → tap **Trust**, enter your phone passcode.
6. If iTunes pops up asking anything, you can close it (but leave AltServer running).

## Part 3 — Install AltStore onto the phone

7. Click the **AltServer diamond icon** in the system tray (bottom-right).
8. Click **Install AltStore** → choose your iPhone from the list.
9. It asks for your **Apple ID email and password** — enter them.
   - This is sent to Apple only (AltServer uses it to make Apple issue a free signing
     certificate). It is not stored anywhere public and never touches GitHub.
   - If your Apple ID uses two-factor authentication, a code prompt may appear on
     your phone — approve it and type the code.
10. Wait for the "AltStore installed" notification on the PC.

## Part 4 — Trust the app on the phone

11. On the iPhone: **Settings → General → VPN & Device Management**
    (on some iOS versions it's just "Device Management").
12. Under "Developer App", tap your Apple ID email → tap **Trust** → **Trust** again.
13. Go to the home screen and open the **AltStore** app.

## ✅ Gate B check

**AltStore opens on your iPhone without an error message.** Tell Claude "AltStore opens"
(a screenshot is even better) and we move on to putting the Errands app on your phone.

## If something goes wrong (common fixes)

- **AltServer says it can't find the device** → make sure iTunes was the Apple-website
  version, not the Microsoft Store one. Uninstall Store versions of iTunes/iCloud
  (Settings → Apps) and reinstall from Apple's site.
- **"Could not connect" errors** → Windows Firewall may be blocking AltServer: when the
  firewall prompt appears, click **Allow access**.
- **Apple ID sign-in fails repeatedly** → tell Claude; there's a fallback tool
  (Sideloadly) that uses the same free mechanism.
