import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'places_coords_policy.dart';

class SearchHistoryService {
  static const String _prefsKey = 'guidy_search_history';
  static const int _maxEntries = 5;

  /// Entries older than the Places retention window are dropped on read,
  /// coordinates and all. See PlacesCoordsPolicy for why. Nothing is lost
  /// that a rider would miss -- a search from over a month ago is not a
  /// "recent" search by any reading of the word.
  static Future<List<Map<String, dynamic>>> getRecent() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final List<dynamic> decoded = json.decode(raw);
      final all = decoded.cast<Map<String, dynamic>>();
      final kept = all.where((e) => !PlacesCoordsPolicy.isExpired(e['at'])).toList();
      // Rewrite only when something actually aged out, so an ordinary
      // read stays a read.
      if (kept.length != all.length) {
        await prefs.setString(_prefsKey, json.encode(kept));
      }
      return kept;
    } catch (_) {
      return [];
    }
  }

  static Future<void> addSearch(String name, double lat, double lon) async {
    final current = await getRecent();
    // De-dupe by name, then push the fresh entry to the front.
    current.removeWhere((e) => e['name'] == name);
    current.insert(0, {
      'name': name,
      'lat': lat,
      'lon': lon,
      'at': DateTime.now().millisecondsSinceEpoch,
    });
    final trimmed = current.take(_maxEntries).toList();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, json.encode(trimmed));
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }
}
