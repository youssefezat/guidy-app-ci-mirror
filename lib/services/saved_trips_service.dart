import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'instruction_formatter.dart';

/// Represents a saved commuter trip with complete offline routing data.
class SavedTrip {
  final String id;
  final String label;
  final String startName;
  final String endName;
  final double? startLat;
  final double? startLon;
  final double? endLat;
  final double? endLon;
  final Map<String, dynamic> pathData;
  final Map<String, dynamic>? option;
  final DateTime savedAt;
  final DateTime lastUsedAt;

  SavedTrip({
    required this.id,
    required this.label,
    required this.startName,
    required this.endName,
    this.startLat,
    this.startLon,
    this.endLat,
    this.endLon,
    required this.pathData,
    this.option,
    DateTime? savedAt,
    DateTime? lastUsedAt,
  })  : savedAt = savedAt ?? DateTime.now(),
        lastUsedAt = lastUsedAt ?? DateTime.now();

  SavedTrip copyWith({
    String? label,
    DateTime? lastUsedAt,
  }) {
    return SavedTrip(
      id: id,
      label: label ?? this.label,
      startName: startName,
      endName: endName,
      startLat: startLat,
      startLon: startLon,
      endLat: endLat,
      endLon: endLon,
      pathData: pathData,
      option: option,
      savedAt: savedAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'start_name': startName,
        'end_name': endName,
        'start_lat': startLat,
        'start_lon': startLon,
        'end_lat': endLat,
        'end_lon': endLon,
        'path_data': pathData,
        'option': option,
        'saved_at': savedAt.toIso8601String(),
        'last_used_at': lastUsedAt.toIso8601String(),
      };

  factory SavedTrip.fromJson(Map<String, dynamic> json) {
    return SavedTrip(
      id: (json['id'] ?? '').toString(),
      label: (json['label'] ?? '').toString(),
      startName: (json['start_name'] ?? '').toString(),
      endName: (json['end_name'] ?? '').toString(),
      startLat: InstructionFormatter.asNum(json['start_lat'])?.toDouble(),
      startLon: InstructionFormatter.asNum(json['start_lon'])?.toDouble(),
      endLat: InstructionFormatter.asNum(json['end_lat'])?.toDouble(),
      endLon: InstructionFormatter.asNum(json['end_lon'])?.toDouble(),
      pathData: json['path_data'] is Map ? Map<String, dynamic>.from(json['path_data']) : {},
      option: json['option'] is Map ? Map<String, dynamic>.from(json['option']) : null,
      savedAt: json['saved_at'] != null ? DateTime.tryParse(json['saved_at']) : null,
      lastUsedAt: json['last_used_at'] != null ? DateTime.tryParse(json['last_used_at']) : null,
    );
  }
}

/// Service managing persistent storage of commuter trips in SharedPreferences.
class SavedTripsService {
  static const String _storageKey = 'saved_commute_trips';
  static const String _activeCacheKey = 'active_commute_trip_cache';

  /// Returns all saved commuter trips ordered by recency.
  static Future<List<SavedTrip>> getSavedTrips() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      final list = decoded
          .whereType<Map>()
          .map((m) => SavedTrip.fromJson(Map<String, dynamic>.from(m)))
          .toList();
      list.sort((a, b) => b.lastUsedAt.compareTo(a.lastUsedAt));
      return list;
    } catch (_) {
      return [];
    }
  }

  /// Saves or updates a commuter trip.
  static Future<SavedTrip> saveTrip({
    String? id,
    String? label,
    required String startName,
    required String endName,
    double? startLat,
    double? startLon,
    double? endLat,
    double? endLon,
    required Map<String, dynamic> pathData,
    Map<String, dynamic>? option,
  }) async {
    final trips = await getSavedTrips();
    final tripId = id ?? DateTime.now().millisecondsSinceEpoch.toString();
    final tripLabel = (label != null && label.trim().isNotEmpty)
        ? label.trim()
        : '$startName ➔ $endName';

    final newTrip = SavedTrip(
      id: tripId,
      label: tripLabel,
      startName: startName,
      endName: endName,
      startLat: startLat,
      startLon: startLon,
      endLat: endLat,
      endLon: endLon,
      pathData: pathData,
      option: option,
      savedAt: DateTime.now(),
      lastUsedAt: DateTime.now(),
    );

    final existingIndex = trips.indexWhere((t) => t.id == tripId || (t.startName == startName && t.endName == endName));
    if (existingIndex >= 0) {
      trips[existingIndex] = newTrip;
    } else {
      trips.insert(0, newTrip);
    }

    await _persistTrips(trips);
    return newTrip;
  }

  /// Removes a saved trip by its unique ID.
  static Future<bool> removeTrip(String id) async {
    final trips = await getSavedTrips();
    final beforeCount = trips.length;
    trips.removeWhere((t) => t.id == id);
    if (trips.length != beforeCount) {
      await _persistTrips(trips);
      return true;
    }
    return false;
  }

  /// Removes a trip matching start and end destination names.
  static Future<bool> removeTripByEndpoints(String startName, String endName) async {
    final trips = await getSavedTrips();
    final beforeCount = trips.length;
    trips.removeWhere((t) => t.startName == startName && t.endName == endName);
    if (trips.length != beforeCount) {
      await _persistTrips(trips);
      return true;
    }
    return false;
  }

  /// Checks if a route between start and end is already saved.
  static Future<bool> isTripSaved(String startName, String endName) async {
    final trips = await getSavedTrips();
    return trips.any((t) => t.startName == startName && t.endName == endName);
  }

  /// Marks a saved trip as used to keep it at the top of recents.
  static Future<void> touchTrip(String id) async {
    final trips = await getSavedTrips();
    final idx = trips.indexWhere((t) => t.id == id);
    if (idx >= 0) {
      trips[idx] = trips[idx].copyWith(lastUsedAt: DateTime.now());
      await _persistTrips(trips);
    }
  }

  /// Automatically caches the latest opened trip so it can be viewed offline even if not explicitly bookmarked.
  static Future<void> cacheActiveTrip({
    required String startName,
    required String endName,
    required Map<String, dynamic> pathData,
    Map<String, dynamic>? option,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = {
      'start_name': startName,
      'end_name': endName,
      'path_data': pathData,
      'option': option,
      'cached_at': DateTime.now().toIso8601String(),
    };
    await prefs.setString(_activeCacheKey, jsonEncode(payload));
  }

  /// Retrieves the cached active trip payload.
  static Future<Map<String, dynamic>?> getCachedActiveTrip() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_activeCacheKey);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
    } catch (_) {
      return null;
    }
  }

  /// Syncs locally saved trips with the user's Firestore account.
  /// Pushes local trips to `users/{uid}/saved_trips` and pulls down any existing cloud trips.
  static Future<void> syncWithCloud(User user) async {
    if (user.isAnonymous) return;
    try {
      final firestore = FirebaseFirestore.instance;
      final tripsCollection = firestore.collection('users').doc(user.uid).collection('saved_trips');

      // 1. Fetch cloud trips
      final snapshot = await tripsCollection.get();
      final cloudTrips = <String, SavedTrip>{};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        cloudTrips[doc.id] = SavedTrip.fromJson(data);
      }

      // 2. Fetch local trips
      final localTrips = await getSavedTrips();
      final localMap = {for (var t in localTrips) t.id: t};

      // 3. Upload local trips that are not in cloud
      final batch = firestore.batch();
      bool hasUploads = false;
      for (final local in localTrips) {
        if (!cloudTrips.containsKey(local.id)) {
          final docRef = tripsCollection.doc(local.id);
          batch.set(docRef, local.toJson(), SetOptions(merge: true));
          hasUploads = true;
        }
      }
      if (hasUploads) {
        await batch.commit();
      }

      // 4. Merge any cloud trips back into local storage
      bool hasNewLocal = false;
      for (final entry in cloudTrips.entries) {
        if (!localMap.containsKey(entry.key)) {
          localTrips.add(entry.value);
          hasNewLocal = true;
        }
      }
      if (hasNewLocal) {
        localTrips.sort((a, b) => b.lastUsedAt.compareTo(a.lastUsedAt));
        await _persistTrips(localTrips);
      }
    } catch (e) {
      debugPrint("Error syncing saved trips with cloud: $e");
    }
  }

  static Future<void> _persistTrips(List<SavedTrip> trips) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(trips.map((t) => t.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }
}
