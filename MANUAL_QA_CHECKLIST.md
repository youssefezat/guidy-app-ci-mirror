# Guidy Manual QA Checklist

Everything in `test_routing_engine.py` runs automatically and is already
verified passing. Everything in this file requires a real device, a
Flutter toolchain, or account access none of which were available in the
sandbox this was written in -- so none of it has actually been run yet.
Treat every box as unchecked until you've personally done it.

Suggested order: Section 1 first (nothing else matters if it doesn't
build), then 2-3 in either order, then 4-7 as time allows before
submission.

---

## 1. Does it even build?

- [ ] `flutter pub get` completes with no errors
- [ ] `flutter analyze` — zero errors (warnings are fine to triage separately)
- [ ] `flutter build apk --debug` succeeds
- [ ] `flutter build ios --debug --no-codesign` succeeds (needs a Mac)
- [ ] App launches on an Android emulator/device without an immediate crash
- [ ] App launches on an iOS simulator/device without an immediate crash

This is the single highest-value thing to check first — nothing else in
this list matters if the app doesn't compile. See the note in the last
conversation turn about why this specifically hasn't been verified yet.

## 2. Auth flows

- [ ] Email/password sign up → account created, lands in the app
- [ ] Email/password sign up with an already-used email → clear error, not a crash
- [ ] Email/password sign in with correct credentials
- [ ] Email/password sign in with wrong password → clear error
- [ ] Google Sign-In completes and lands in the app
- [ ] Google Sign-In cancelled midway (back button on the picker) → returns cleanly to sign-in screen, no crash
- [ ] Facebook Login completes and lands in the app
- [ ] Facebook Login cancelled midway → returns cleanly, no crash
- [ ] **Continue as Guest** → lands in the app with no account (requires Anonymous auth enabled in Firebase console first — see note below)
- [ ] Guest session persists across an app restart (don't get signed out just from closing the app)
- [ ] Settings screen shows "Guest" (not a blank/null email) when signed in anonymously
- [ ] Sign out → returns to sign-in screen, no residual state from the previous session
- [ ] **Delete Account** (email user) → prompts for password, deletes, returns to sign-in
- [ ] **Delete Account** (Google user) → re-triggers Google picker, deletes, returns to sign-in
- [ ] **Delete Account** (Facebook user) → re-triggers Facebook login, deletes, returns to sign-in
- [ ] **Delete Account** (guest user) → deletes directly, no reauth prompt, returns to sign-in
- [ ] Delete Account confirmation dialog can be cancelled without deleting anything
- [ ] After deleting an account, trying to sign back in with the same email/Google/Facebook creates a genuinely new account (old data is gone)

> **Before testing guest login:** Firebase Console → Authentication →
> Sign-in method → Anonymous must be turned on. It's off by default on a
> new project. If you skip this, the guest button will fail with a
> Firebase error — that's expected until it's enabled, not a bug.

## 3. Routing / core functionality

- [ ] Search a start location by name, results appear
- [ ] Search a location that doesn't exist (gibberish) → "No places found" message, not stale recent-search history and not a blank screen
- [ ] Recent searches show up when the search field is empty
- [ ] "Clear history" actually clears recent searches
- [ ] Pick start + destination → get at least one route option
- [ ] Route with a metro leg shows the metro icon/color correctly
- [ ] Route with a bus leg shows the bus icon/color correctly
- [ ] Route with a microbus/minibus leg shows correctly
- [ ] Multi-leg route with a transfer displays all legs in order, not collapsed or out of order
- [ ] Fare total displayed matches the sum you'd expect from the individual legs shown
- [ ] Tapping a route option shows full turn-by-turn instructions
- [ ] Map view shows the actual route path, not just start/end pins
- [ ] Requesting a route with start = destination doesn't crash or show a nonsense result
- [ ] Denying location permission still lets you search/pick a start point manually
- [ ] Trip recap / summary screen shows correct fare, time, and distance after selecting a route

## 4. Localization (English / Arabic)

- [ ] Switching to Arabic in Settings actually changes visible text app-wide, not just some screens
- [ ] Switching language does NOT require an app restart to take effect
- [ ] **Font actually changes with language** — Arabic should render in Almarai, English in Nunito Sans. Compare visually against the brand PDF; if everything still looks like the system default font, the `google_fonts` wiring didn't take effect and needs investigating.
- [ ] Back button icon points the correct direction in Arabic (right, not left) — this was a specific bug fixed this session, worth confirming visually
- [ ] Forward/continue arrow on the route summary card mirrors correctly in Arabic
- [ ] No leftover English text visible anywhere in the Arabic UI (check Settings, auth screens, trip recap, empty states)
- [ ] No text visibly clipped/overflowing in Arabic (Arabic strings are sometimes longer or shorter than their English counterparts — check auth screens and any card with two pieces of text side by side)
- [ ] Station and route names in Arabic display real Arabic names (not English fallback) for metro stations at minimum

## 5. Visual / branding

- [ ] App icon on the home screen is the new Guidy "G" mark, not the Flutter default — check both platforms, since this was just changed and never seen on an actual device
- [ ] App icon looks correct (not stretched, cropped, or showing a white box) at actual home-screen size, not just in Xcode/Android Studio's preview
- [ ] In-app colors match the brand palette (blue/navy primary, orange accents) — spot check a few screens against the brand PDF
- [ ] Dark mode: colors still look intentional, not just "the same UI but darker" — check contrast on buttons and input fields
- [ ] Map dark-mode style (if enabled) doesn't clash with the rest of dark mode

## 6. Ads / tracking / notifications

- [ ] Banner ad displays in its slot (test ad ID is fine at this stage — real IDs come later per the launch checklist)
- [ ] iOS: App Tracking Transparency prompt appears once, early in the flow, not repeatedly
- [ ] iOS: Declining ATT still shows ads (non-personalized), doesn't break the ad slot
- [ ] iOS: ATT prompt and the notification permission prompt don't visually collide (one should fully resolve before the other appears — this was specifically fixed this session by adding a missing `await`)
- [ ] Notification permission prompt appears and, if granted, a device token is obtained without error (check debug logs)
- [ ] Denying notification permission doesn't break anything else in the app

## 7. Backend / deployment (once the domain is live)

- [ ] `curl https://your-domain.com/api/health` returns success over real HTTPS
- [ ] App successfully hits the real backend (not the old dev LAN IP) after updating `API_BASE_URL`
- [ ] Rate limiting kicks in as expected under rapid repeated requests (shouldn't lock out normal usage)
- [ ] OSRM is actually reachable in production, not silently falling back to straight-line walking estimates for every request (check backend logs for OSRM connection warnings)
- [ ] Backend survives a restart / redeploy without losing the GTFS data mount

---

## Bugs found while running this list

Keep a running log here (or wherever you track issues) as you go —
specifically note which section/checkbox surfaced each one, since that
maps directly back to a part of the app that hasn't been touched by any
automated check.
