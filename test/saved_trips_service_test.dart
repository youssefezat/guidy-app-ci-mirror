import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:guidy_app/services/saved_trips_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('SavedTripsService save, get, and check trip', () async {
    expect(await SavedTripsService.isTripSaved('Maadi', 'Dokki'), isFalse);

    final saved = await SavedTripsService.saveTrip(
      startName: 'Maadi',
      endName: 'Dokki',
      pathData: {
        'instructions': [
          {'action': 'walk', 'distance_m': 300},
          {'action': 'board', 'station': 'Sadat', 'line': 'Line 2'}
        ],
        'duration_minutes': 35,
      },
    );

    expect(saved.id, isNotEmpty);
    expect(saved.startName, equals('Maadi'));
    expect(saved.endName, equals('Dokki'));
    expect(await SavedTripsService.isTripSaved('Maadi', 'Dokki'), isTrue);

    final all = await SavedTripsService.getSavedTrips();
    expect(all.length, equals(1));
    expect(all.first.startName, equals('Maadi'));
    expect(all.first.pathData['duration_minutes'], equals(35));

    final removed = await SavedTripsService.removeTrip(saved.id);
    expect(removed, isTrue);
    expect(await SavedTripsService.isTripSaved('Maadi', 'Dokki'), isFalse);
    expect((await SavedTripsService.getSavedTrips()).isEmpty, isTrue);
  });

  test('SavedTripsService automatic active trip cache', () async {
    expect(await SavedTripsService.getCachedActiveTrip(), isNull);

    await SavedTripsService.cacheActiveTrip(
      startName: 'Ramses',
      endName: 'Giza',
      pathData: {'color': '#489CB5'},
    );

    final cached = await SavedTripsService.getCachedActiveTrip();
    expect(cached, isNotNull);
    expect(cached!['start_name'], equals('Ramses'));
    expect(cached['end_name'], equals('Giza'));
    expect(cached['path_data']['color'], equals('#489CB5'));
  });

  test('SavedTripsService removeTripByEndpoints and touchTrip', () async {
    final trip = await SavedTripsService.saveTrip(
      startName: 'Heliopolis',
      endName: 'Zamalek',
      pathData: {'instructions': []},
    );

    expect(await SavedTripsService.isTripSaved('Heliopolis', 'Zamalek'), isTrue);
    await SavedTripsService.touchTrip(trip.id);

    final removed = await SavedTripsService.removeTripByEndpoints('Heliopolis', 'Zamalek');
    expect(removed, isTrue);
    expect(await SavedTripsService.isTripSaved('Heliopolis', 'Zamalek'), isFalse);
  });
}
