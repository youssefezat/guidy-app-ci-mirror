import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:guidy_app/services/trip_history_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('TripHistoryService calculations', () {
    test('choice-based savings calculates relative time saved for Fastest choice', () async {
      final trip = await TripHistoryService.recordTrip(
        startName: 'Helwan',
        endName: 'Sadat',
        chosenProfile: 'Fastest',
        pathData: {
          'options': [
            {'time': 35, 'fare_total_egp': 15, 'type': 'Fastest'},
            {'time': 55, 'fare_total_egp': 10, 'type': 'Cheapest'},
          ],
        },
        option: {'time': 35, 'fare_total_egp': 15, 'type': 'Fastest', 'distance_m': 28000},
      );

      expect(trip, isNotNull);
      // Saved 55 - 35 = 20 minutes by choosing Fastest
      expect(trip!.timeSavedMin, equals(20));
      expect(trip.transitFareEgp, equals(15));
    });

    test('choice-based savings calculates relative money saved for Cheapest choice', () async {
      final trip = await TripHistoryService.recordTrip(
        startName: 'Maadi',
        endName: 'Ramses',
        chosenProfile: 'Cheapest',
        pathData: {
          'options': [
            {'time': 30, 'fare_total_egp': 25, 'type': 'Fastest'},
            {'time': 45, 'fare_total_egp': 10, 'type': 'Cheapest'},
          ],
        },
        option: {'time': 45, 'fare_total_egp': 10, 'type': 'Cheapest', 'distance_m': 15000},
      );

      expect(trip, isNotNull);
      // Saved 25 - 10 = 15 EGP by choosing Cheapest
      expect(trip!.moneySavedEgp, equals(15.0));
      expect(trip.transitDurationMin, equals(45));
    });

    test('calculateCo2SavedKg computes carbon reduction based on 0.115 kg/km', () {
      final co2 = TripHistoryService.calculateCo2SavedKg(distanceMeters: 20000);
      expect(co2, equals(2.3)); // 20 * 0.115 = 2.3 kg
    });
  });

  group('TripHistoryService persistence and CRUD', () {
    test('recordTrip saves trip and getHistory retrieves it ordered newest first', () async {
      expect(await TripHistoryService.getHistory(), isEmpty);

      final entry1 = await TripHistoryService.recordTrip(
        startName: 'Helwan',
        endName: 'Sadat',
        pathData: {
          'color': '#489CB5',
          'options': [
            {'time': 40, 'fare_total_egp': 10, 'type': 'Fastest'},
            {'time': 60, 'fare_total_egp': 8, 'type': 'Cheapest'},
          ],
        },
        option: {
          'time': 40,
          'fare_total_egp': 10,
          'distance_m': 28000,
          'vehicle_type': 'metro',
          'type': 'Fastest',
        },
      );

      expect(entry1, isNotNull);
      expect(entry1!.startName, equals('Helwan'));
      expect(entry1.endName, equals('Sadat'));
      expect(entry1.transitFareEgp, equals(10));
      expect(entry1.timeSavedMin, equals(20));

      final history = await TripHistoryService.getHistory();
      expect(history.length, equals(1));
      expect(history.first.id, equals(entry1.id));
    });

    test('recordTrip debounces rapid duplicate calls for the same corridor', () async {
      final trip1 = await TripHistoryService.recordTrip(
        startName: 'Maadi',
        endName: 'Tahrir',
        pathData: {},
      );
      expect(trip1, isNotNull);

      // Second immediate call with identical corridor
      final trip2 = await TripHistoryService.recordTrip(
        startName: 'Maadi',
        endName: 'Tahrir',
        pathData: {},
      );
      expect(trip2, isNull);

      final history = await TripHistoryService.getHistory();
      expect(history.length, equals(1));
    });

    test('deleteTrip and clearHistory work as expected', () async {
      final trip = await TripHistoryService.recordTrip(
        startName: 'Giza',
        endName: 'Ramses',
        pathData: {},
      );
      expect(trip, isNotNull);

      expect((await TripHistoryService.getHistory()).isNotEmpty, isTrue);

      final deleted = await TripHistoryService.deleteTrip(trip!.id);
      expect(deleted, isTrue);
      expect((await TripHistoryService.getHistory()).isEmpty, isTrue);

      // Test clearHistory
      await TripHistoryService.recordTrip(
        startName: 'Nasr City',
        endName: 'New Cairo',
        pathData: {},
      );
      expect((await TripHistoryService.getHistory()).length, equals(1));
      await TripHistoryService.clearHistory();
      expect((await TripHistoryService.getHistory()).isEmpty, isTrue);
    });

    test('getStats aggregates savings accurately and tracks choice-based metrics', () async {
      final samples = await TripHistoryService.seedSampleTrips();
      expect(samples.length, equals(4));

      final stats = TripHistoryService.getStats(samples);
      expect(stats.totalTrips, equals(4));
      expect(stats.totalMoneySavedEgp, equals(285.0));
      expect(stats.totalTimeSavedMinutes, equals(95));
      expect(stats.totalDistanceKm, greaterThan(70.0));
      expect(stats.totalCo2SavedKg, greaterThan(8.0));

      // Choice-based metric assertions
      expect(stats.fastestTripsCount, equals(2));
      expect(stats.cheapestTripsCount, equals(2));
      // Fastest trips: sample_1 (45 min) + sample_4 (50 min) = 95 min saved
      expect(stats.fastestTimeSavedMin, equals(95.0));
      // Cheapest trips: sample_2 (125 EGP) + sample_3 (160 EGP) = 285 EGP saved
      expect(stats.cheapestMoneySavedEgp, equals(285.0));
    });

    test('TripHistoryEntry JSON serialization preserves all fields including chosenProfile', () {
      final now = DateTime.now();
      final entry = TripHistoryEntry(
        id: 'test_123',
        startName: 'Dokki',
        endName: 'Abbassiya',
        startLat: 30.038,
        startLon: 31.212,
        endLat: 30.068,
        endLon: 31.282,
        timestamp: now,
        transitModes: ['metro', 'bus'],
        primaryMode: 'metro',
        routeNumber: 'Line 3',
        transitFareEgp: 15,
        transitDurationMin: 32,
        transitDistanceMeters: 11000,
        rideHailFareEgp: 135.0,
        moneySavedEgp: 120.0,
        timeSavedMin: 25,
        co2SavedKg: 1.3,
        pathData: {'key': 'val'},
        option: {'opt': 1, 'type': 'Fastest'},
        chosenProfile: 'Fastest',
        isCompleted: true,
      );

      final json = entry.toJson();
      final reconstructed = TripHistoryEntry.fromJson(json);

      expect(reconstructed.id, equals('test_123'));
      expect(reconstructed.startName, equals('Dokki'));
      expect(reconstructed.endName, equals('Abbassiya'));
      expect(reconstructed.transitModes, equals(['metro', 'bus']));
      expect(reconstructed.primaryMode, equals('metro'));
      expect(reconstructed.routeNumber, equals('Line 3'));
      expect(reconstructed.transitFareEgp, equals(15));
      expect(reconstructed.moneySavedEgp, equals(120.0));
      expect(reconstructed.timeSavedMin, equals(25));
      expect(reconstructed.chosenProfile, equals('Fastest'));
      expect(reconstructed.pathData['key'], equals('val'));
      expect(reconstructed.option?['opt'], equals(1));
    });
  });
}
