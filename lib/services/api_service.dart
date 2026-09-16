import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'reference_cache.dart';

class ApiService {
  static const String _prefKey = 'active_api_base_url';

  static const String _envBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  /// Default candidate endpoints in priority order:
  /// 1. Built-in environment definition (if any passed at build time via --dart-define)
  /// 2. Current development machine Wi-Fi / Ethernet LAN IP (192.168.1.9)
  /// 3. ADB reverse tunnel / device loopback (127.0.0.1)
  /// 4. Android Emulator host alias (10.0.2.2)
  /// 5. Windows Mobile Hotspot IP (192.168.137.1)
  static final List<String> defaultCandidates = [
    if (_envBaseUrl.isNotEmpty) _envBaseUrl,
    'http://192.168.1.9:8000/api',
    'http://127.0.0.1:8000/api',
    'http://10.0.2.2:8000/api',
    'http://192.168.137.1:8000/api',
  ];

  static String _activeBaseUrl = _envBaseUrl.isNotEmpty
      ? _envBaseUrl
      : 'http://192.168.1.9:8000/api';

  static Future<String>? _discoveryFuture;
  static bool _initialized = false;

  /// Dynamic baseUrl that always reflects the currently working endpoint.
  static String get baseUrl => _activeBaseUrl;

  /// Manually override or set active base URL (e.g. for testing).
  @visibleForTesting
  static void setBaseUrlForTesting(String url) {
    _activeBaseUrl = url;
  }

  /// Initializes the working baseUrl from SharedPreferences and triggers background discovery.
  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUrl = prefs.getString(_prefKey);
      if (savedUrl != null && savedUrl.isNotEmpty) {
        _activeBaseUrl = savedUrl;
      }
    } catch (e) {
      debugPrint('[ApiService] Error reading saved base URL: $e');
    }
    // Probe candidates in background without blocking app startup
    unawaited(discoverWorkingBaseUrl());
  }

  /// Discovers which candidate base URL is reachable and updates [baseUrl].
  static Future<String> discoverWorkingBaseUrl({Duration timeout = const Duration(milliseconds: 1500)}) async {
    if (_discoveryFuture != null) return _discoveryFuture!;

    _discoveryFuture = _performDiscovery(timeout);
    try {
      final winner = await _discoveryFuture!;
      return winner;
    } finally {
      _discoveryFuture = null;
    }
  }

  static Future<String> _performDiscovery(Duration timeout) async {
    final candidates = <String>[];

    void addCandidate(String? url) {
      if (url != null && url.trim().isNotEmpty && !candidates.contains(url.trim())) {
        candidates.add(url.trim());
      }
    }

    // 1. Current active URL
    addCandidate(_activeBaseUrl);

    // 2. Saved in SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      addCandidate(prefs.getString(_prefKey));
    } catch (_) {}

    // 3. Default candidates
    for (final c in defaultCandidates) {
      addCandidate(c);
    }

    // Quick test on activeBaseUrl first
    if (candidates.isNotEmpty) {
      final activeOk = await _pingCandidate(candidates.first, timeout);
      if (activeOk) {
        return candidates.first;
      }
    }

    // Probe remaining candidates concurrently
    final futures = candidates.map((url) async {
      final ok = await _pingCandidate(url, timeout);
      return ok ? url : null;
    });

    final results = await Future.wait(futures);
    for (final match in results) {
      if (match != null) {
        _activeBaseUrl = match;
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_prefKey, match);
        } catch (_) {}
        debugPrint('[ApiService] Auto-discovered working base URL: $match');
        return match;
      }
    }

    return _activeBaseUrl;
  }

  static Future<bool> _pingCandidate(String candidateUrl, Duration timeout) async {
    try {
      final uri = Uri.parse('$candidateUrl/health');
      final resp = await http.get(uri).timeout(timeout);
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Executes an API request with automatic fallback: if it fails with a network exception,
  /// discovers a working candidate URL and retries the action once.
  static Future<T> _withNetworkFallback<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on SocketException catch (_) {
      await discoverWorkingBaseUrl();
      return await action();
    } on http.ClientException catch (_) {
      await discoverWorkingBaseUrl();
      return await action();
    } on TimeoutException catch (_) {
      await discoverWorkingBaseUrl();
      return await action();
    }
  }

  Future<bool> checkBackendReachable() async {
    try {
      if (await _pingCandidate(_activeBaseUrl, const Duration(seconds: 2))) {
        return true;
      }
      final discovered = await discoverWorkingBaseUrl(timeout: const Duration(seconds: 2));
      return await _pingCandidate(discovered, const Duration(seconds: 2));
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> fetchRoute(
    double startLat, 
    double startLon, 
    double endLat, 
    double endLon, {
    String lang = 'en',
    bool excludeMetro = false,
    bool minWalk = false,
    bool minTransfers = false,
  }) async {
    try {
      return await _withNetworkFallback(() async {
        final metroParam = excludeMetro ? '&exclude_metro=true' : '';
        final walkParam = minWalk ? '&min_walk=true' : '';
        final transferParam = minTransfers ? '&min_transfers=true' : '';
        final response = await http.get(
          Uri.parse('$baseUrl/route?start_lat=$startLat&start_lon=$startLon&end_lat=$endLat&end_lon=$endLon&lang=$lang$metroParam$walkParam$transferParam'),
        ).timeout(const Duration(seconds: 15));

        final decoded = _tryDecode(response.body);

        if (response.statusCode == 200) {
          return decoded ?? {'success': false, 'error_code': 'server_error'};
        }
        final error = _errorFrom(decoded);
        final detail = decoded?['detail'];
        return {
          'success': false,
          'error_code': error.$1,
          'error': error.$2,
          'nearest_hubs': detail is Map ? detail['nearest_hubs'] : null,
        };
      });
    } catch (e) {
      // No English prose thrown from here: the screens turn a code into a
      // localized message. A raw exception string used to end up rendered
      // verbatim on an Arabic screen, "Exception:" prefix and all.
      return {'success': false, 'error_code': 'network'};
    }
  }

  /// (code, message) out of an error body, whichever shape it arrived in.
  (String?, String?) _errorFrom(Map<String, dynamic>? decoded) {
    final detail = decoded?['detail'];
    if (detail is Map) {
      return (detail['code'] as String?, detail['message'] as String?);
    }
    if (detail is String) return (null, detail);
    final error = decoded?['error'];
    return (decoded?['error_code'] as String?, error is String ? error : null);
  }

  Map<String, dynamic>? _tryDecode(String body) {
    try {
      return json.decode(body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> fetchStations() async {
    return await _withNetworkFallback(() async {
      final response = await http.get(Uri.parse('$baseUrl/stations'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['stations']);
      }
      throw Exception('Failed to load stations');
    });
  }

  // --- Live position reporting -------------------------------------
  // Crowdsourced vehicle tracking: while a rider is actively riding a
  // transit leg, the app periodically reports their GPS against that
  // leg's route_id/direction_id (see live_tracking_service.dart). The
  // backend uses these reports to attach a real-time ETA to every
  // interchangeable route on a leg instead of just picking one -- see
  // main.py's /api/live/position and raptor_engine.py's
  // _find_equivalent_routes(). Failures here are swallowed rather than
  // thrown: a dropped position report should never interrupt or error
  // out someone's in-progress trip, it just means one less live data
  // point this round.
  Future<void> reportLivePosition({
    required String sessionId,
    required String routeId,
    required String directionId,
    required double lat,
    required double lon,
  }) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/live/position'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'session_id': sessionId,
          'route_id': routeId,
          'direction_id': directionId,
          'lat': lat,
          'lon': lon,
        }),
      ).timeout(const Duration(seconds: 5));
    } catch (e) {
      // Best-effort -- see doc comment above.
    }
  }

  // --- Lookup tools -------------------------------------------------
  // These sit beside the trip planner rather than inside it: the browser
  // answers "what does line 65 actually do?" and the metro planner answers
  // "how do I get there on the metro only?". Both are served by
  // lookups.py, which reads the same GTFS structures the planner uses, so
  // a stop order or a metro fare shown here can never disagree with the
  // one shown on a planned trip.

  /// Search lines by number *or* by where they go. The second half matters:
  /// roughly 300 microbus routes in the feed have no number at all, only a
  /// corridor name, so a number-only search would hide them entirely.
  Future<List<Map<String, dynamic>>> searchRoutes({
    String query = '',
    String? vehicleType,
    String lang = 'en',
    int limit = 40,
  }) async {
    final params = <String, String>{
      'q': query,
      'lang': lang,
      'limit': '$limit',
      'vehicle_type': ?vehicleType,
    };

    // Only the unfiltered browse views are cached.
    final cacheKey =
        query.isEmpty ? 'routes_${vehicleType ?? 'all'}_${lang}_$limit' : null;
    if (cacheKey != null) {
      final cached = await ReferenceCache.read(cacheKey);
      if (cached != null) return List<Map<String, dynamic>>.from(cached as List);
    }

    try {
      return await _withNetworkFallback(() async {
        final uri = Uri.parse('$baseUrl/routes').replace(queryParameters: params);
        final response = await http.get(uri).timeout(const Duration(seconds: 10));
        final decoded = _tryDecode(response.body);
        if (response.statusCode == 200 && decoded != null) {
          final routes = List<Map<String, dynamic>>.from(decoded['routes'] ?? const []);
          if (cacheKey != null) await ReferenceCache.write(cacheKey, routes);
          return routes;
        }
        throw Exception(decoded?['detail'] ?? 'Failed to load lines.');
      });
    } catch (e) {
      if (cacheKey != null) {
        final stale = await ReferenceCache.readStale(cacheKey);
        if (stale != null) return List<Map<String, dynamic>>.from(stale as List);
      }
      throw Exception('Could not reach the Guidy server.');
    }
  }

  /// Every direction of one line, each as an ordered stop list.
  Future<Map<String, dynamic>> fetchRouteDetail(String routeId, {String lang = 'en'}) async {
    final cacheKey = 'route_detail_${routeId}_$lang';
    final cached = await ReferenceCache.read(cacheKey);
    if (cached != null) return Map<String, dynamic>.from(cached as Map);

    try {
      return await _withNetworkFallback(() async {
        final uri = Uri.parse('$baseUrl/routes/${Uri.encodeComponent(routeId)}?lang=$lang');
        final response = await http.get(uri).timeout(const Duration(seconds: 10));
        final decoded = _tryDecode(response.body);
        if (response.statusCode == 200 && decoded != null) {
          await ReferenceCache.write(cacheKey, decoded, persist: false);
          return decoded;
        }
        throw Exception(decoded?['detail'] ?? 'Failed to load that line.');
      });
    } catch (e) {
      final stale = await ReferenceCache.readStale(cacheKey);
      if (stale != null) return Map<String, dynamic>.from(stale as Map);
      throw Exception('Could not reach the Guidy server.');
    }
  }

  Future<List<Map<String, dynamic>>> fetchMetroStations({String lang = 'en'}) async {
    final cacheKey = 'metro_stations_$lang';
    final cached = await ReferenceCache.read(cacheKey);
    if (cached != null) return List<Map<String, dynamic>>.from(cached as List);

    try {
      return await _withNetworkFallback(() async {
        final uri = Uri.parse('$baseUrl/metro/stations?lang=$lang');
        final response = await http.get(uri).timeout(const Duration(seconds: 10));
        final decoded = _tryDecode(response.body);
        if (response.statusCode == 200 && decoded != null) {
          final stations = List<Map<String, dynamic>>.from(decoded['stations'] ?? const []);
          await ReferenceCache.write(cacheKey, stations);
          return stations;
        }
        throw Exception(decoded?['detail'] ?? 'Failed to load metro stations.');
      });
    } catch (e) {
      final stale = await ReferenceCache.readStale(cacheKey);
      if (stale != null) return List<Map<String, dynamic>>.from(stale as List);
      throw Exception('Could not reach the Guidy server.');
    }
  }

  /// Metro-only plan between two stations. Returns the backend's own
  /// `detail` message on 404 rather than a generic failure, because the
  /// useful cases -- same station, or two stations with no metro-only
  /// connection -- are worth saying out loud.
  Future<Map<String, dynamic>> planMetro({
    required String fromStop,
    required String toStop,
    String lang = 'en',
  }) async {
    try {
      return await _withNetworkFallback(() async {
        final uri = Uri.parse('$baseUrl/metro/plan').replace(queryParameters: {
          'from_stop': fromStop,
          'to_stop': toStop,
          'lang': lang,
        });
        final response = await http.get(uri).timeout(const Duration(seconds: 10));
        final decoded = _tryDecode(response.body);
        if (response.statusCode == 200 && decoded != null) return decoded;
        return {
          'success': false,
          'error': decoded?['detail'] ?? decoded?['error'] ?? 'Failed to plan that metro trip.',
        };
      });
    } catch (e) {
      return {'success': false, 'error': 'Could not reach the Guidy server.'};
    }
  }

  Future<void> endLiveSession(String sessionId) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/live/end'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'session_id': sessionId}),
      ).timeout(const Duration(seconds: 5));
    } catch (e) {
      // Best-effort -- see doc comment above.
    }
  }
}