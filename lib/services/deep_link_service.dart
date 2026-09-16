import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app_links/app_links.dart';
import '../l10n/app_localizations.dart';
import '../screens/LocationSearchScreen.dart';
import 'maps_link_parser.dart';

/// Handles the app being opened via an external Google Maps link or
/// geo: URI -- see android/app/src/main/AndroidManifest.xml for the
/// intent-filters that make this reachable, and README_DEEP_LINKS.md for
/// what does and doesn't actually work here and why (short version:
/// Android can be told to offer Guidy as an option for maps.google.com
/// links, but can't be told to make Guidy the *automatic* handler,
/// because that requires owning the domain in the link -- which nobody
/// but Google does for google.com).
///
/// Known simplification: if the person isn't signed in yet when a link
/// arrives, this silently does nothing rather than queuing the link to
/// replay after sign-in. Revisit if that turns out to matter in
/// practice -- for now it avoids the complexity of persisting a pending
/// destination across the auth flow for what should be a rare timing
/// case (opening a shared link before ever having opened the app).
class DeepLinkService {
  static final AppLinks _appLinks = AppLinks();
  static StreamSubscription<Uri>? _subscription;

  static void initialize(GlobalKey<NavigatorState> navigatorKey) {
    // Already-running app: link tapped while Guidy is in the background/foreground.
    _subscription = _appLinks.uriLinkStream.listen((uri) {
      _handleIncomingUri(uri, navigatorKey);
    }, onError: (err) {
      debugPrint('[DeepLink] stream error: $err');
    });

    // Cold start: app launched fresh BY tapping the link.
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) _handleIncomingUri(uri, navigatorKey);
    });
  }

  static Future<void> _handleIncomingUri(Uri uri, GlobalKey<NavigatorState> navigatorKey) async {
    if (FirebaseAuth.instance.currentUser == null) {
      debugPrint('[DeepLink] received a link before sign-in, ignoring: $uri');
      return;
    }

    final parsed = await MapsLinkParser.parse(uri.toString());
    if (parsed == null) {
      debugPrint('[DeepLink] could not parse coordinates from: $uri');
      return;
    }

    final navState = navigatorKey.currentState;
    final navContext = navState?.context;
    // `mounted` matters here, not just null: parsing the link was an await,
    // and the navigator can be gone by the time it returns.
    if (navState == null || navContext == null || !navContext.mounted) return;

    // This runs outside any widget's build, so the navigator's own context
    // is the only place to read localizations from. Without it the fallback
    // place name for an unresolvable pin came back in English.
    final l10n = AppLocalizations.of(navContext);
    final String lang = Localizations.localeOf(navContext).languageCode;

    final name = parsed.name ??
        await MapsLinkParser.reverseGeocodeName(parsed.lat, parsed.lon,
            fallbackLabel: l10n.pinnedLocation, lang: lang);

    navState.push(MaterialPageRoute(
      builder: (_) => LocationSearchScreen(
        initialEndLocation: {'name': name, 'full_name': name, 'lat': parsed.lat, 'lon': parsed.lon},
      ),
    ));
  }

  static void dispose() {
    _subscription?.cancel();
  }
}
