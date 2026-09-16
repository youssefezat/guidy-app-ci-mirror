import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'instruction_formatter.dart';

num? _asNum(dynamic val) => InstructionFormatter.asNum(val);

/// Represents a recorded commuter trip in the user's history with calculated
/// savings in money, time, and carbon emissions.
class TripHistoryEntry {
  final String id;
  final String startName;
  final String endName;
  final double? startLat;
  final double? startLon;
  final double? endLat;
  final double? endLon;
  final DateTime timestamp;
  final List<String> transitModes;
  final String? primaryMode;
  final String? routeNumber;
  final int transitFareEgp;
  final int transitDurationMin;
  final int transitDistanceMeters;
  final double rideHailFareEgp;
  final double moneySavedEgp;
  final int timeSavedMin;
  final double co2SavedKg;
  final Map<String, dynamic> pathData;
  final Map<String, dynamic>? option;
  final String chosenProfile; // 'Fastest', 'Cheapest', 'Alternative', etc.
  final bool isCompleted;

  TripHistoryEntry({
    required this.id,
    required this.startName,
    required this.endName,
    this.startLat,
    this.startLon,
    this.endLat,
    this.endLon,
    DateTime? timestamp,
    List<String>? transitModes,
    this.primaryMode,
    this.routeNumber,
    required this.transitFareEgp,
    required this.transitDurationMin,
    required this.transitDistanceMeters,
    required this.rideHailFareEgp,
    required this.moneySavedEgp,
    required this.timeSavedMin,
    required this.co2SavedKg,
    required this.pathData,
    this.option,
    String? chosenProfile,
    this.isCompleted = true,
  })  : timestamp = timestamp ?? DateTime.now(),
        transitModes = transitModes ?? const [],
        chosenProfile = chosenProfile ??
            option?['type']?.toString() ??
            pathData['type']?.toString() ??
            pathData['option']?['type']?.toString() ??
            'Fastest';

  Map<String, dynamic> toJson() => {
        'id': id,
        'start_name': startName,
        'end_name': endName,
        'start_lat': startLat,
        'start_lon': startLon,
        'end_lat': endLat,
        'end_lon': endLon,
        'timestamp': timestamp.toIso8601String(),
        'transit_modes': transitModes,
        'primary_mode': primaryMode,
        'route_number': routeNumber,
        'transit_fare_egp': transitFareEgp,
        'transit_duration_min': transitDurationMin,
        'transit_distance_meters': transitDistanceMeters,
        'ride_hail_fare_egp': rideHailFareEgp,
        'money_saved_egp': moneySavedEgp,
        'time_saved_min': timeSavedMin,
        'co2_saved_kg': co2SavedKg,
        'path_data': pathData,
        'option': option,
        'chosen_profile': chosenProfile,
        'is_completed': isCompleted,
      };

  factory TripHistoryEntry.fromJson(Map<String, dynamic> json) {
    final modes = (json['transit_modes'] as List?)?.map((e) => e.toString()).toList() ?? [];
    return TripHistoryEntry(
      id: (json['id'] ?? '').toString(),
      startName: (json['start_name'] ?? '').toString(),
      endName: (json['end_name'] ?? '').toString(),
      startLat: _asNum(json['start_lat'])?.toDouble(),
      startLon: _asNum(json['start_lon'])?.toDouble(),
      endLat: _asNum(json['end_lat'])?.toDouble(),
      endLon: _asNum(json['end_lon'])?.toDouble(),
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      transitModes: modes,
      primaryMode: json['primary_mode']?.toString(),
      routeNumber: json['route_number']?.toString(),
      transitFareEgp: _asNum(json['transit_fare_egp'])?.toInt() ?? 10,
      transitDurationMin: _asNum(json['transit_duration_min'])?.toInt() ?? 30,
      transitDistanceMeters: _asNum(json['transit_distance_meters'])?.toInt() ?? 10000,
      rideHailFareEgp: _asNum(json['ride_hail_fare_egp'])?.toDouble() ?? 80.0,
      moneySavedEgp: _asNum(json['money_saved_egp'])?.toDouble() ?? 70.0,
      timeSavedMin: _asNum(json['time_saved_min'])?.toInt() ?? 15,
      co2SavedKg: _asNum(json['co2_saved_kg'])?.toDouble() ?? 1.15,
      pathData: json['path_data'] is Map ? Map<String, dynamic>.from(json['path_data']) : {},
      option: json['option'] is Map ? Map<String, dynamic>.from(json['option']) : null,
      chosenProfile: json['chosen_profile']?.toString() ??
          (json['option'] is Map ? json['option']['type']?.toString() : null) ??
          'Fastest',
      isCompleted: json['is_completed'] as bool? ?? true,
    );
  }
}

/// Aggregate metrics for cumulative user transit savings.
class TripHistoryStats {
  final double totalMoneySavedEgp;
  final int totalTimeSavedMinutes;
  final double fastestTimeSavedMin;
  final double cheapestMoneySavedEgp;
  final int fastestTripsCount;
  final int cheapestTripsCount;
  final int totalTrips;
  final double totalDistanceKm;
  final double totalCo2SavedKg;

  const TripHistoryStats({
    required this.totalMoneySavedEgp,
    required this.totalTimeSavedMinutes,
    this.fastestTimeSavedMin = 0,
    this.cheapestMoneySavedEgp = 0,
    this.fastestTripsCount = 0,
    this.cheapestTripsCount = 0,
    required this.totalTrips,
    required this.totalDistanceKm,
    required this.totalCo2SavedKg,
  });

  static const empty = TripHistoryStats(
    totalMoneySavedEgp: 0,
    totalTimeSavedMinutes: 0,
    fastestTimeSavedMin: 0,
    cheapestMoneySavedEgp: 0,
    fastestTripsCount: 0,
    cheapestTripsCount: 0,
    totalTrips: 0,
    totalDistanceKm: 0,
    totalCo2SavedKg: 0,
  );
}

/// Service managing persistent storage and analytics for user trips.
class TripHistoryService {
  static const String _storageKey = 'guidy_trip_history_v1';
  static DateTime? _lastLoggedAt;
  static String? _lastLoggedRouteKey;

  /// Notifier that increments whenever history changes (new trip, delete, clear).
  /// Screens listen to this to instantly update their UI.
  static final ValueNotifier<int> changeNotifier = ValueNotifier<int>(0);

  /// Retrieves all recorded trips sorted newest first.
  static Future<List<TripHistoryEntry>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      final list = decoded
          .whereType<Map>()
          .map((m) => TripHistoryEntry.fromJson(Map<String, dynamic>.from(m)))
          .toList();
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return list;
    } catch (e) {
      debugPrint("Error reading trip history: $e");
      return [];
    }
  }

  /// Records a new trip to history.
  /// Prevents double-logging if invoked repeatedly within 10 seconds for the same corridor.
  static Future<TripHistoryEntry?> recordTrip({
    required String startName,
    required String endName,
    double? startLat,
    double? startLon,
    double? endLat,
    double? endLon,
    required Map<String, dynamic> pathData,
    Map<String, dynamic>? option,
    String? chosenProfile,
    bool isCompleted = true,
  }) async {
    final now = DateTime.now();
    final routeKey = '$startName->$endName';

    // Duplicate debouncer: ignore if the exact same start-end was logged within 10s
    if (_lastLoggedRouteKey == routeKey &&
        _lastLoggedAt != null &&
        now.difference(_lastLoggedAt!).inSeconds < 10) {
      return null;
    }

    _lastLoggedAt = now;
    _lastLoggedRouteKey = routeKey;

    // Extract metrics from option / pathData
    final duration = _asNum(option?['time'])?.toInt() ?? 35;
    final fare = _asNum(option?['fare_total_egp'])?.toInt() ??
        _asNum(option?['fare_egp'])?.toInt() ??
        12;
    final distance = _asNum(option?['distance_m'])?.toInt() ?? 12000;

    // Extract transit modes
    final List<String> modes = [];
    final instructions = (option?['instructions'] as List?) ?? (pathData['instructions'] as List?) ?? [];
    for (final step in instructions) {
      if (step is Map && step['icon'] != null) {
        final icon = step['icon'].toString().toLowerCase();
        if (icon != 'walk' && icon != 'transfer' && icon != 'arrive' && !modes.contains(icon)) {
          modes.add(icon);
        }
      }
    }
    if (modes.isEmpty && option?['vehicle_type'] != null) {
      modes.add(option!['vehicle_type'].toString().toLowerCase());
    }
    if (modes.isEmpty) {
      modes.add('bus');
    }

    final primaryMode = option?['vehicle_type']?.toString() ?? modes.first;
    final routeNumber = option?['route_number']?.toString() ?? option?['name']?.toString();

    final resolvedProfile = chosenProfile ??
        option?['type']?.toString() ??
        pathData['type']?.toString() ??
        pathData['option']?['type']?.toString() ??
        'Fastest';

    final profLower = resolvedProfile.toLowerCase();
    final isFastest = profLower.contains('fastest') || profLower.contains('أسرع') || profLower.contains('fast');
    final isCheapest = profLower.contains('cheapest') || profLower.contains('أوفر') || profLower.contains('ارخص') || profLower.contains('cheap');

    int timeSaved = 0;
    double moneySaved = 0.0;

    // Relative calculation based on user's specific choice among available routes
    final rawOptions = (pathData['options'] as List?) ?? (pathData['all_options'] as List?);
    if (rawOptions != null && rawOptions.length > 1) {
      final otherDurations = rawOptions
          .whereType<Map>()
          .where((o) => o != option)
          .map((o) => _asNum(o['time'])?.toInt())
          .whereType<int>()
          .toList();
      final otherFares = rawOptions
          .whereType<Map>()
          .where((o) => o != option)
          .map((o) => _asNum(o['fare_total_egp'] ?? o['fare_egp'])?.toDouble())
          .whereType<double>()
          .toList();

      if (isFastest && otherDurations.isNotEmpty) {
        final maxOther = otherDurations.reduce((a, b) => a > b ? a : b);
        timeSaved = (maxOther - duration).clamp(3, 60);
      }
      if (isCheapest && otherFares.isNotEmpty) {
        final maxOther = otherFares.reduce((a, b) => a > b ? a : b);
        moneySaved = (maxOther - fare).clamp(2.0, 50.0);
      }
    }

    // Meaningful fallbacks if standalone single option was taken
    if (isFastest && timeSaved == 0) {
      timeSaved = 15;
    }
    if (isCheapest && moneySaved == 0.0) {
      moneySaved = 10.0;
    }

    final co2Saved = ((distance / 1000.0) * 0.115 * 10).round() / 10.0;

    final entry = TripHistoryEntry(
      id: now.millisecondsSinceEpoch.toString(),
      startName: startName,
      endName: endName,
      startLat: startLat,
      startLon: startLon,
      endLat: endLat,
      endLon: endLon,
      timestamp: now,
      transitModes: modes,
      primaryMode: primaryMode,
      routeNumber: routeNumber,
      transitFareEgp: fare,
      transitDurationMin: duration,
      transitDistanceMeters: distance,
      rideHailFareEgp: 0.0,
      moneySavedEgp: moneySaved,
      timeSavedMin: timeSaved,
      co2SavedKg: co2Saved,
      pathData: pathData,
      option: option,
      chosenProfile: resolvedProfile,
      isCompleted: isCompleted,
    );

    final history = await getHistory();
    history.insert(0, entry);

    // Limit history to 100 trips to keep storage compact
    final trimmed = history.take(100).toList();
    await _persistHistory(trimmed);

    // Sync in background if authenticated
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && !user.isAnonymous) {
        syncWithCloud(user);
      }
    } catch (_) {
      // Firebase not initialized in unit tests or offline
    }

    return entry;
  }

  /// Deletes a trip by its ID.
  static Future<bool> deleteTrip(String id) async {
    final history = await getHistory();
    final beforeCount = history.length;
    history.removeWhere((e) => e.id == id);
    if (history.length != beforeCount) {
      await _persistHistory(history);
      return true;
    }
    return false;
  }

  /// Carbon emissions saved by choosing transit over private driving (0.115 kg CO2 / km).
  static double calculateCo2SavedKg({required int distanceMeters}) {
    return ((distanceMeters / 1000.0) * 0.115 * 10).round() / 10.0;
  }

  /// Clears all trip history.
  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    changeNotifier.value++;
  }

  /// Calculates aggregated totals for all or filtered entries.
  static TripHistoryStats getStats(List<TripHistoryEntry> entries) {
    if (entries.isEmpty) return TripHistoryStats.empty;

    int fastestTime = 0;
    double cheapestMoney = 0;
    int fastestCount = 0;
    int cheapestCount = 0;
    double totalDistance = 0;
    double totalCo2 = 0;

    for (final e in entries) {
      totalDistance += (e.transitDistanceMeters / 1000.0);
      totalCo2 += e.co2SavedKg;

      final profile = e.chosenProfile.toLowerCase();
      if (profile.contains('fastest') || profile.contains('أسرع') || profile.contains('fast')) {
        fastestTime += e.timeSavedMin;
        fastestCount++;
      } else if (profile.contains('cheapest') || profile.contains('أوفر') || profile.contains('ارخص') || profile.contains('cheap')) {
        cheapestMoney += e.moneySavedEgp;
        cheapestCount++;
      } else {
        if (e.timeSavedMin > 0) fastestTime += e.timeSavedMin;
        if (e.moneySavedEgp > 0) cheapestMoney += e.moneySavedEgp;
      }
    }

    return TripHistoryStats(
      totalMoneySavedEgp: (cheapestMoney * 10).round() / 10.0,
      totalTimeSavedMinutes: fastestTime,
      fastestTimeSavedMin: fastestTime.toDouble(),
      cheapestMoneySavedEgp: (cheapestMoney * 10).round() / 10.0,
      fastestTripsCount: fastestCount,
      cheapestTripsCount: cheapestCount,
      totalTrips: entries.length,
      totalDistanceKm: (totalDistance * 10).round() / 10.0,
      totalCo2SavedKg: (totalCo2 * 10).round() / 10.0,
    );
  }

  /// Seeds realistic Cairo commuter sample trips for demo / first-run preview.
  static Future<List<TripHistoryEntry>> seedSampleTrips() async {
    final now = DateTime.now();
    final samples = [
      TripHistoryEntry(
        id: 'sample_1',
        startName: 'Helwan',
        endName: 'Sadat (Tahrir)',
        startLat: 29.8492,
        startLon: 31.3342,
        endLat: 30.0444,
        endLon: 31.2357,
        timestamp: now.subtract(const Duration(hours: 3)),
        transitModes: ['metro'],
        primaryMode: 'metro',
        routeNumber: 'Line 1',
        transitFareEgp: 10,
        transitDurationMin: 42,
        transitDistanceMeters: 28500,
        rideHailFareEgp: 215.0,
        moneySavedEgp: 205.0,
        timeSavedMin: 45,
        co2SavedKg: 3.3,
        pathData: {},
        chosenProfile: 'Fastest',
        isCompleted: true,
      ),
      TripHistoryEntry(
        id: 'sample_2',
        startName: 'Maadi',
        endName: 'Ramses',
        startLat: 29.9602,
        startLon: 31.2569,
        endLat: 30.0649,
        endLon: 31.2447,
        timestamp: now.subtract(const Duration(days: 1, hours: 2)),
        transitModes: ['metro'],
        primaryMode: 'metro',
        routeNumber: 'Line 1',
        transitFareEgp: 10,
        transitDurationMin: 28,
        transitDistanceMeters: 14200,
        rideHailFareEgp: 135.0,
        moneySavedEgp: 125.0,
        timeSavedMin: 30,
        co2SavedKg: 1.6,
        pathData: {},
        chosenProfile: 'Cheapest',
        isCompleted: true,
      ),
      TripHistoryEntry(
        id: 'sample_3',
        startName: 'Abbas El Akkad (Nasr City)',
        endName: 'New Cairo (AUC)',
        startLat: 30.0571,
        startLon: 31.3412,
        endLat: 30.0194,
        endLon: 31.4988,
        timestamp: now.subtract(const Duration(days: 2, hours: 5)),
        transitModes: ['bus'],
        primaryMode: 'bus',
        routeNumber: 'MM M5',
        transitFareEgp: 15,
        transitDurationMin: 38,
        transitDistanceMeters: 19800,
        rideHailFareEgp: 175.0,
        moneySavedEgp: 160.0,
        timeSavedMin: 22,
        co2SavedKg: 2.3,
        pathData: {},
        chosenProfile: 'Cheapest',
        isCompleted: true,
      ),
      TripHistoryEntry(
        id: 'sample_4',
        startName: 'Kit Kat',
        endName: 'Adly Mansour',
        startLat: 30.0664,
        startLon: 31.2132,
        endLat: 30.1478,
        endLon: 31.4019,
        timestamp: now.subtract(const Duration(days: 4, hours: 1)),
        transitModes: ['metro'],
        primaryMode: 'metro',
        routeNumber: 'Line 3',
        transitFareEgp: 15,
        transitDurationMin: 45,
        transitDistanceMeters: 24500,
        rideHailFareEgp: 220.0,
        moneySavedEgp: 205.0,
        timeSavedMin: 50,
        co2SavedKg: 2.8,
        pathData: {},
        chosenProfile: 'Fastest',
        isCompleted: true,
      ),
    ];

    await _persistHistory(samples);
    return samples;
  }

  /// Cloud sync with Firestore users/{uid}/trip_history
  static Future<void> syncWithCloud(User user) async {
    if (user.isAnonymous) return;
    try {
      final firestore = FirebaseFirestore.instance;
      final coll = firestore.collection('users').doc(user.uid).collection('trip_history');

      final snapshot = await coll.limit(50).get();
      final cloudEntries = <String, TripHistoryEntry>{};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        cloudEntries[doc.id] = TripHistoryEntry.fromJson(data);
      }

      final localEntries = await getHistory();
      final localMap = {for (var t in localEntries) t.id: t};

      // Upload local to cloud
      final batch = firestore.batch();
      bool hasUploads = false;
      for (final local in localEntries) {
        if (!cloudEntries.containsKey(local.id)) {
          final docRef = coll.doc(local.id);
          batch.set(docRef, local.toJson(), SetOptions(merge: true));
          hasUploads = true;
        }
      }
      if (hasUploads) {
        await batch.commit();
      }

      // Merge cloud into local
      bool hasNew = false;
      for (final entry in cloudEntries.entries) {
        if (!localMap.containsKey(entry.key)) {
          localEntries.add(entry.value);
          hasNew = true;
        }
      }
      if (hasNew) {
        localEntries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        await _persistHistory(localEntries);
      }
    } catch (e) {
      debugPrint("Error syncing trip history with cloud: $e");
    }
  }

  static Future<void> _persistHistory(List<TripHistoryEntry> history) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(history.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }
}
