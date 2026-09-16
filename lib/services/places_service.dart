import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Google Places Autocomplete (New), replacing the previous Nominatim
/// (OpenStreetMap) search -- see PLACES_COST_NOTES.md for the full
/// reasoning. The short version: Google bills Places by the SESSION, not
/// the keystroke, but only if you actually use session tokens correctly.
/// Get that wrong (omit the token, reuse it, or request the wrong Place
/// Details fields) and every keystroke becomes a separate billable
/// request instead of one cheap session -- this class exists specifically
/// to make that mistake hard to make by accident.
///
/// The pattern, end to end:
/// 1. [startSession] once, when the person starts a fresh search (not on
///    every keystroke -- reusing a token across an entire search is what
///    makes the session model cheap).
/// 2. [autocomplete] on each debounced keystroke, passing that same
///    token. These calls fold into the free "Autocomplete Session Usage"
///    SKU as long as the session is later terminated properly by step 3.
/// 3. [getPlaceDetails] exactly once, when the person taps a suggestion,
///    passing the same token. This is the ONE call that actually costs
///    money -- and only beyond the first 10,000 free per month at the
///    Essentials tier ($5/1,000 after that, as of this writing). This
///    call also terminates the session: generate a fresh token before
///    starting the next search.
///
/// If a search is abandoned (person clears the field, navigates away, or
/// the screen is disposed without a selection), just call [startSession]
/// again for the next search -- there's nothing to "cancel". An
/// un-terminated session's Autocomplete calls bill individually rather
/// than as a session, which is a real cost, but it's the cost of a user
/// not finding what they wanted, not a bug to work around.
class PlacesService {
  static const String _apiKeyAndroid = String.fromEnvironment(
    'MAPS_API_KEY_ANDROID',
    defaultValue: 'AREDACTED-PLACES-ANDROID-KEY-0000000000',
  );
  static const String _apiKeyIOS = String.fromEnvironment(
    'MAPS_API_KEY_IOS',
    defaultValue: 'AREDACTED-PLACES-IOS-KEY-00000000000000',
  );
  static String get _apiKey => Platform.isAndroid ? _apiKeyAndroid : _apiKeyIOS;

  // When the Maps API key has an "Android apps" restriction in Cloud
  // Console, Google identifies the calling app via two special headers
  // (X-Android-Package / X-Android-Cert). The native Maps SDK
  // (google_maps_flutter) attaches these automatically at the OS level,
  // but a plain http.post/http.get call -- which is all this class makes
  // -- does not get them for free. Without setting them explicitly here,
  // every request shows up to Google as identifying no app at all and
  // gets rejected with "Requests from this Android client application
  // <empty> are blocked", regardless of how correctly the key itself is
  // configured.
  //
  // Package name is stable across debug/release (it's the applicationId
  // in android/app/build.gradle.kts). The certificate fingerprint is NOT
  // -- debug and release builds are signed with different keys, so they
  // have different SHA-1s. ANDROID_CERT_SHA1 below must match whichever
  // build is actually running: the debug keystore's fingerprint for
  // local dev (get it via `keytool -list -v -keystore
  // %USERPROFILE%\.android\debug.keystore -alias androiddebugkey
  // -storepass android -keypass android`, colons stripped), or the
  // release signing key's fingerprint for a release build. Cloud
  // Console's "Android apps" restriction accepts multiple package+SHA-1
  // pairs under one key, so add the release fingerprint there as an
  // ADDITIONAL entry (not a replacement) once a release keystore exists,
  // and pass the matching value here via --dart-define at build time.
  static const String _androidPackageName = 'com.guidy.guidy_app';
  static const String _androidCertSha1 = String.fromEnvironment(
    'ANDROID_CERT_SHA1',
    defaultValue: '10353F98C4901BABC759A03AD2181CCA42DC1505',
  );

  // Same story on iOS: an "iOS apps" key restriction checks this header,
  // which the native Maps SDK sends by itself but a raw HTTP call does not.
  // Must match PRODUCT_BUNDLE_IDENTIFIER in ios/Runner.xcodeproj.
  static const String _iosBundleId = 'com.guidy.guidyApp';

  static Map<String, String> get _androidIdentityHeaders => Platform.isAndroid
      ? {'X-Android-Package': _androidPackageName, 'X-Android-Cert': _androidCertSha1}
      : Platform.isIOS
          ? {'X-Ios-Bundle-Identifier': _iosBundleId}
          : {};

  static const String _autocompleteUrl = 'https://places.googleapis.com/v1/places:autocomplete';
  static const String _placeDetailsBaseUrl = 'https://places.googleapis.com/v1/places';

  // Essentials-tier fields ONLY. Google bills the entire Place Details
  // request at whichever tier the highest-priced requested field belongs
  // to -- adding a single Pro or Enterprise field (rating, openingHours,
  // photos, phone number, website, etc.) here would silently upgrade
  // every request from ~$5/1,000 to $17+/1,000. Guidy only needs a name
  // and coordinates, so there's no reason to ever add to this mask.
  static const String _essentialsFieldMask = 'id,location,formattedAddress,displayName';

  // Bias (not restrict) toward Greater Cairo -- improves result relevance
  // so people find what they want in fewer keystrokes, which indirectly
  // reduces both request volume and abandoned (unbilled-as-session)
  // searches. A bias still allows results outside the circle; a hard
  // restriction would not, which matters for anyone searching a location
  // just outside this box (6th of October City, New Cairo, etc.)
  static const double _cairoLat = 30.05;
  static const double _cairoLon = 31.25;
  // Google's hard cap is 50,000m -- 60,000 got every request rejected with
  // a 400 INVALID_ARGUMENT ("Radius must be between 0 and 50,000 meters"),
  // which is why Autocomplete looked completely dead regardless of query.
  static const double _biasRadiusMeters = 50000;

  /// Call once per fresh search (e.g. when a previously-empty field gets
  /// its first keystroke). Never reuse the returned token across two
  /// different searches -- Google treats a reused token as no token at
  /// all, which reverts every Autocomplete call in that "session" to
  /// individual per-request billing.
  /// Below this, no request leaves the device. The old floor was two
  /// characters; in Cairo a two-letter query returns noise the rider
  /// scrolls straight past, and every one of them is a billable request
  /// inside the session. Three is still short enough for real Arabic
  /// queries -- "مصر" is exactly three.
  static const int minQueryLength = 3;

  static bool isQueryTooShort(String query) => query.trim().length < minQueryLength;

  /// Memory only, and short, on purpose. Autocomplete responses carry
  /// place text and Place Details carries coordinates, and Maps Platform
  /// Service Terms §14.3 caps cached Places latitude/longitude at 30
  /// days. Nothing here survives an app restart, which puts it far inside
  /// that limit without needing a policy to enforce it.
  static const Duration _cacheTtl = Duration(hours: 6);

  /// Bounded so a long-running process cannot accumulate every query a
  /// rider has ever typed. Oldest entries go first.
  static const int _maxCacheEntries = 60;

  static final Map<String, _Cached<List<Map<String, dynamic>>>> _autocompleteCache = {};
  static final Map<String, _Cached<Map<String, double>>> _detailsCache = {};

  /// Requests currently in the air, keyed the same way as the cache. A
  /// second identical query joins the first rather than starting its own.
  static final Map<String, Future<List<Map<String, dynamic>>>> _inFlight = {};

  static void _remember<T>(Map<String, _Cached<T>> cache, String key, T value) {
    if (cache.length >= _maxCacheEntries) cache.remove(cache.keys.first);
    cache[key] = _Cached<T>(value);
  }

  static String startSession() {
    final rand = Random.secure();
    // Manual UUID v4 -- avoids pulling in the `uuid` package for
    // something this small. Format/version bits per RFC 4122.
    final bytes = List<int>.generate(16, (_) => rand.nextInt(256));
    bytes[6] = (bytes[6] & 0x0F) | 0x40;
    bytes[8] = (bytes[8] & 0x3F) | 0x80;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}';
  }

  /// Returns predictions WITHOUT coordinates -- Autocomplete (New)
  /// deliberately doesn't return lat/lon, that's what makes the session
  /// model cheap (you're not paying for geometry on every candidate the
  /// person doesn't pick). Call [getPlaceDetails] with the chosen
  /// prediction's placeId to resolve actual coordinates.
  static Future<List<Map<String, dynamic>>> autocomplete(String query, String sessionToken) async {
    if (isQueryTooShort(query)) return const [];
    final key = query.trim().toLowerCase();

    final cached = _autocompleteCache[key];
    if (cached != null && cached.isFresh) return cached.value;

    // Backspacing over a word re-asks for prefixes already answered, and
    // two fields on the same screen can ask at once. Either way, one
    // request.
    final pending = _inFlight[key];
    if (pending != null) return pending;

    final request = _fetchAutocomplete(query, sessionToken);
    _inFlight[key] = request;
    try {
      final results = await request;
      // An empty list is usually a network failure rather than "no such
      // place", and caching that would hide real results for six hours.
      if (results.isNotEmpty) _remember(_autocompleteCache, key, results);
      return results;
    } finally {
      _inFlight.remove(key);
    }
  }

  static Future<List<Map<String, dynamic>>> _fetchAutocomplete(
      String query, String sessionToken) async {

    final bool queryIsArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(query);

    try {
      final response = await http.post(
        Uri.parse(_autocompleteUrl),
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': _apiKey,
          ..._androidIdentityHeaders,
        },
        body: json.encode({
          'input': query,
          'sessionToken': sessionToken,
          'languageCode': queryIsArabic ? 'ar' : 'en',
          'includedRegionCodes': ['eg'],
          'locationBias': {
            'circle': {
              'center': {'latitude': _cairoLat, 'longitude': _cairoLon},
              'radius': _biasRadiusMeters,
            }
          },
        }),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) {
        debugPrint('Places Autocomplete error: ${response.statusCode} ${response.body}');
        return [];
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      final suggestions = (data['suggestions'] as List?) ?? [];

      return suggestions
          .map((s) => s['placePrediction'])
          .where((p) => p != null)
          .map<Map<String, dynamic>>((p) => {
                'name': p['structuredFormat']?['mainText']?['text'] ?? p['text']?['text'] ?? '',
                'full_name': p['text']?['text'] ?? '',
                'placeId': p['placeId'],
              })
          .toList();
    } catch (e) {
      debugPrint('Network error during Places Autocomplete: $e');
      return [];
    }
  }

  /// The one call per search that actually costs money -- see the class
  /// doc comment. Returns null on any failure so the caller can show a
  /// clear "couldn't get that location" message rather than silently
  /// producing a location with no coordinates.
  static Future<Map<String, double>?> getPlaceDetails(String placeId, String sessionToken) async {
    final cached = _detailsCache[placeId];
    if (cached != null && cached.isFresh) return cached.value;
    final coords = await _fetchPlaceDetails(placeId, sessionToken);
    if (coords != null) _remember(_detailsCache, placeId, coords);
    return coords;
  }

  static Future<Map<String, double>?> _fetchPlaceDetails(
      String placeId, String sessionToken) async {
    try {
      final response = await http.get(
        Uri.parse('$_placeDetailsBaseUrl/$placeId?sessionToken=$sessionToken'),
        headers: {
          'X-Goog-Api-Key': _apiKey,
          'X-Goog-FieldMask': _essentialsFieldMask,
          ..._androidIdentityHeaders,
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) {
        debugPrint('Place Details error: ${response.statusCode} ${response.body}');
        return null;
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      final location = data['location'] as Map<String, dynamic>?;
      if (location == null) return null;

      final lat = location['latitude'] is num ? (location['latitude'] as num).toDouble() : double.tryParse(location['latitude']?.toString() ?? '');
      final lon = location['longitude'] is num ? (location['longitude'] as num).toDouble() : double.tryParse(location['longitude']?.toString() ?? '');
      if (lat == null || lon == null) return null;
      return {
        'lat': lat,
        'lon': lon,
      };
    } catch (e) {
      debugPrint('Network error fetching Place Details: $e');
      return null;
    }
  }
}

class _Cached<T> {
  _Cached(this.value) : storedAt = DateTime.now();

  final T value;
  final DateTime storedAt;

  bool get isFresh =>
      DateTime.now().difference(storedAt) < PlacesService._cacheTtl;
}
