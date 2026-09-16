<!--
  Drafted from what the app's code actually does (auth providers, ads,
  analytics, crash reporting, push notifications, location use, backend
  API calls) -- not a generic template. Still: this is a starting point,
  not legal advice, and you should have someone review it before you rely
  on it for App Store / Play Store submission, especially the sections on
  Egypt's Personal Data Protection Law (No. 151 of 2020) and, if you ever
  get users outside Egypt, GDPR/CCPA obligations neither store requires
  today but may later.

  Contact email and effective date are filled in. Still open: a
  company/developer legal name, if one is ever registered.

  THIS FILE IS THE SOURCE, NOT THE PUBLISHED PAGE. build_site.py renders
  it (and DATA_DELETION.md) into public/, which Firebase Hosting serves
  at https://guidy-19e46.web.app/privacy. Edit the markdown, re-run the
  script, redeploy -- never hand-edit the HTML, the next build discards
  it. Both stores and AdMob all just need that URL to be stable and
  publicly reachable.
-->

# Privacy Policy for Guidy

**Effective date:** 8 September 2026

Guidy ("we", "our", "the app") is a public transportation routing app for
Greater Cairo, covering the metro, monorail, light rail, buses and
microbuses. This policy explains what data the app collects, why, and
who it's shared with.

## Data we collect

**Location.** Guidy uses your device's location, with your permission, to
find nearby stops and to calculate routes from where you are. We ask only
for foreground location: the app has no background-location permission on
either platform, so it cannot see where you are once you have left it.

**Live position while you are riding.** This one deserves more than a
line, because it is the least obvious thing the app does. Guidy has no
vehicle-tracking hardware and no feed from any operator — the only source
of real-time information about where a bus actually is, is the phones of
the people on it. So while you are actively riding a leg of a trip you
have started in the app, and only then, your phone sends its position to
our server about every eight seconds. Those reports are what let the app
tell the next rider which of several routes along the same corridor is
the one actually approaching.

What is sent is a coordinate, the route and direction you are on, and a
session identifier your phone generates for that one ride. Your account
identifier is not attached and is never sent — the server has no way to
connect a stream of positions to a person, only to a ride in progress.
The positions are held in memory on the server, never written to disk,
and are discarded 90 seconds after they stop arriving; ending or
completing the leg clears the session immediately. Reporting stops the
moment you stop riding, and does not happen while you are walking, while
the app is in the background, or when you are not on a trip at all.

**Searches you type.** When you search for a place, what you type is sent
to the Google Places API to fetch suggestions, along with a rough
location so the suggestions are nearby ones. This is Google's service and
is covered by [Google's Privacy Policy](https://policies.google.com/privacy).

**Account information.** If you create an account or sign in, we collect
what your chosen sign-in method provides:
- Email/password sign-in: your email address.
- Google Sign-In: your name, email, and profile photo, as permitted by
  your Google account settings.
- Guest mode: no personal information at all — just a temporary,
  anonymous account identifier so you can use the app without creating
  an account. This identifier isn't linked to your name or email.

Authentication is handled by Firebase Authentication (Google).

**Usage and diagnostic data.** We use Firebase Analytics to understand
how the app is used (e.g. which screens are opened, which features are
used) and Firebase Crashlytics to collect crash reports and error logs
so we can fix bugs. Both are Google services and are subject to
[Google's Privacy Policy](https://policies.google.com/privacy).

**Push notification token.** If you allow notifications, we obtain a
device token (via Firebase Cloud Messaging) used to deliver
notifications to your device. We do not currently send any notification
content beyond what's needed for basic app functionality.

**Advertising data.** Guidy shows banner ads, and an occasional ad when
the app is opened, served by Google AdMob. AdMob may
collect device identifiers and other data to serve and measure ads,
including the advertising identifier (IDFA on iOS, subject to your App
Tracking Transparency choice; AAID on Android). If you decline tracking
permission on iOS, or opt out of ads personalization on Android, you'll
still see ads, but they won't be personalized to you. See
[Google's Partner Policy](https://policies.google.com/technologies/partner-sites)
for how Google uses this data.

**Route corrections you send us.** If you report that a route is wrong,
or that you know a better one (trip details → "Something wrong with this
route?"), we store what you write along with the itinerary you were
looking at: the lines and stops in it, their coordinates, the start and
destination you searched for, and your account identifier — including
the anonymous one, if you are using the app as a guest. We use these
reports to correct the underlying transit data for everyone, which is
the only reason we ask for them. They are stored in Firebase Cloud
Firestore (Google) and are readable only by us; no other user of the app
can read, list or download them. Please don't put personal details in
the comment box — it is there to describe the route, not to contact us.

**Route and trip data.** Origin/destination coordinates and computed
routes are sent to our backend to calculate directions and fares. We do
not sell this data or use it for purposes beyond providing the route
you requested.

## Data that never leaves your phone

Your saved places and your recent searches are stored only in your
device's own app storage. They are not uploaded to us, not synced between
your devices, and not readable by us. Uninstalling the app removes them.

## Data we don't collect

We don't access your contacts, photos, microphone, or camera. We don't
track your location when the app isn't in use, and we don't have the
permission that would let us.

## Who we share data with

- **Google** (Firebase services, AdMob, Google Sign-In, Google Maps) —
  as described above, under Google's own privacy policy.
- We do not sell your personal data to third parties.

## Your choices

- You can decline location permission; route search will require
  manually entering a starting point instead of using your current
  location.
- Live position reporting happens only while you are riding a leg of a
  trip you started in the app. Leaving the trip screen, or not starting
  navigation in the first place, stops it. There is no separate setting
  because there is no state to switch off: nothing is reported when you
  are not riding.
- You can decline notification permission at any time in your device
  settings.
- On iOS, you can decline App Tracking Transparency; you'll still see
  ads, just not personalized ones.
- You can delete your account and associated data at any time from the
  app: Settings → Account → Delete Account. This permanently deletes
  your Firebase account and can't be undone. Route corrections you sent
  us are the one thing this does not remove — see Data retention below.

## Children's privacy

Guidy is not directed at children under 13 (or the minimum age defined
by applicable local law), and we do not knowingly collect personal data
from children. If you believe a child has provided us with personal
data, contact us at the email below and we'll remove it.

## Data retention

We retain account data for as long as your account is active, and
diagnostic/analytics data for the retention periods set by Firebase
Analytics and Crashlytics (see Google's documentation for current
defaults). Deleting your account removes it from Firebase
Authentication immediately.

Live positions are the shortest-lived thing here: memory only, never
written to disk, and dropped 90 seconds after they stop arriving.

Route corrections are the exception, and we would rather say so plainly
than bury it: they are kept after account deletion, because a report
saying "this bus no longer stops here" is still true and still useful
once the person who sent it has gone, and we have no way to act on it
otherwise. If you want yours removed as well, email us at the address
below and we will delete them.

## Changes to this policy

We may update this policy as the app changes. We'll update the
effective date above when we do.

## Contact

Questions about this policy or your data: guidygroup@gmail.com
