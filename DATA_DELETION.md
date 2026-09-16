<!--
  Required because the app uses Facebook Login. Meta requires every app
  that accesses Facebook user data to provide either a Data Deletion
  Callback URL (a live API endpoint) or a Data Deletion Instructions URL
  (this page) in the Facebook Developer dashboard -- without one, Facebook
  Login won't pass App Review at all.

  This is the instructions-page route, which is the right call here: Guidy
  already has real in-app account deletion (Settings -> Delete Account,
  see account_service.dart), so there's no need to build a separate
  signed-request API callback just to satisfy this -- pointing Meta at a
  page that accurately describes the existing flow is sufficient and much
  less work.

  Setup, once this is published at https://guidy-19e46.web.app/data-deletion:
  developers.facebook.com -> your app -> Facebook Login -> Settings ->
  User Data Deletion -> paste this URL into "Data Deletion Instructions
  URL". Meta may fetch and check this page during App Review, so it needs
  to be live at that URL before you submit, not just committed here.
-->

# Data Deletion Instructions

If you'd like Guidy to delete your account and associated data:

1. Open the Guidy app.
2. Go to **Settings**.
3. Under **Account**, tap **Delete Account**.
4. Confirm. If you're prompted to sign in again first, that's a routine
   Firebase security check before a permanent deletion — it isn't an
   extra step you can skip.

This permanently deletes your account. It can't be undone. Guidy's
routing backend doesn't store any separate copy of your account data, so
for everything the app knows about you, this is the complete deletion
process.

**One exception, stated plainly.** If you ever reported that a route was
wrong or suggested a better one, those reports are kept after your
account is deleted. They are what we use to correct the transit data for
everyone, and a report about a bus route stays true regardless of who
sent it. If you want yours deleted too, email the address at the bottom
of this page with the email address on your account and we will remove
them.

**Signed in with Facebook and can't open the app anymore, or want to
revoke access without deleting your Guidy account?** You can also remove
Guidy's access directly from Facebook: Facebook **Settings & Privacy** →
**Settings** → **Security and Login** → **Apps and Websites** → find
**Guidy** → **Remove**. Note that this only revokes Facebook's connection
to your Guidy account; it doesn't delete the Guidy account itself. Use
the in-app deletion above for that.

Questions about this process: guidygroup@gmail.com
