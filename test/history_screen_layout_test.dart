import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guidy_app/screens/HistoryScreen.dart';
import 'package:guidy_app/services/trip_history_service.dart';
import 'package:guidy_app/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await TripHistoryService.clearHistory();

    // Add sample trips: one fastest with long numbers, one cheapest with high savings
    await TripHistoryService.recordTrip(
      startName: 'Helwan Station Long Name Across Town',
      endName: 'Sadat (Tahrir Square Interlocking Station)',
      pathData: {'distance_km': 28.5},
      option: {
        'time': 45,
        'fare_egp': 15,
        'mode': 'metro',
        'route': 'Line 1',
        'ride_hail_comparison': {'fare_egp': 220, 'duration_min': 90},
      },
      chosenProfile: 'fastest',
    );

    await TripHistoryService.recordTrip(
      startName: 'Maadi Corniche Expressway Near Military Hospital',
      endName: 'Ramses Central Railway Terminal Hub',
      pathData: {'distance_km': 18.0},
      option: {
        'time': 65,
        'fare_egp': 10,
        'mode': 'bus',
        'route': 'CTA 1073',
        'ride_hail_comparison': {'fare_egp': 135, 'duration_min': 80},
      },
      chosenProfile: 'cheapest',
    );
  });

  testWidgets('HistoryScreen cards render without overflow on tight screens (English)', (tester) async {
    tester.view.physicalSize = const Size(320 * 2.0, 640 * 2.0);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('en'),
        home: HistoryScreen(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(Card), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('HistoryScreen cards render without overflow on Arabic locale and device width', (tester) async {
    tester.view.physicalSize = const Size(393 * 2.75, 873 * 2.75);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('ar'),
        home: HistoryScreen(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(Card), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
