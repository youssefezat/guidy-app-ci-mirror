import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:guidy_app/screens/LocationSearchScreen.dart';
import 'package:guidy_app/services/search_history_service.dart';
import 'package:guidy_app/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SearchHistoryService.clear();
  });

  Widget buildSearchScreen({
    Map<String, dynamic>? initialStart,
    Map<String, dynamic>? initialEnd,
    Locale locale = const Locale('en'),
  }) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      home: LocationSearchScreen(
        initialStartLocation: initialStart,
        initialEndLocation: initialEnd,
      ),
    );
  }

  group('LocationSearchScreen Widget Tests', () {
    testWidgets('renders input fields and map pin option cleanly', (tester) async {
      await tester.pumpWidget(buildSearchScreen());
      await tester.pumpAndSettle();

      // Find text fields for start and destination
      expect(find.byType(TextField), findsNWidgets(2));

      // Map pin tile exists
      expect(find.byIcon(Icons.pin_drop), findsOneWidget);
      expect(find.text('Drop pin for pickup location'), findsOneWidget);
    });

    testWidgets('populates initial locations when provided and displays Find Routes button', (tester) async {
      final start = {'name': 'Ramses Station', 'lat': 30.06, 'lon': 31.25};
      final end = {'name': 'Tahrir Square', 'lat': 30.04, 'lon': 31.23};

      await tester.pumpWidget(buildSearchScreen(initialStart: start, initialEnd: end));
      await tester.pumpAndSettle();

      // Displayed as hint text in the fields
      expect(find.text('Ramses Station'), findsOneWidget);
      expect(find.text('Tahrir Square'), findsOneWidget);

      // Find Routes button should be visible when both endpoints are selected
      expect(find.text('Find Routes'), findsOneWidget);
    });

    testWidgets('clearing destination resets end location and hides Find Routes button', (tester) async {
      final start = {'name': 'Ramses Station', 'lat': 30.06, 'lon': 31.25};
      final end = {'name': 'Tahrir Square', 'lat': 30.04, 'lon': 31.23};

      await tester.pumpWidget(buildSearchScreen(initialStart: start, initialEnd: end));
      await tester.pumpAndSettle();

      expect(find.text('Find Routes'), findsOneWidget);

      final closeButton = find.byIcon(Icons.close);
      expect(closeButton, findsOneWidget);

      await tester.tap(closeButton);
      await tester.pumpAndSettle();

      // With end cleared, Find Routes button is removed
      expect(find.text('Find Routes'), findsNothing);
      expect(find.text('Tahrir Square'), findsNothing);
    });

    testWidgets('shows recent searches from SearchHistoryService and clears on demand', (tester) async {
      await SearchHistoryService.addSearch('Cairo Festival City', 30.02, 31.40);
      await SearchHistoryService.addSearch('Maadi Grand Mall', 29.96, 31.28);

      await tester.pumpWidget(buildSearchScreen());
      await tester.pumpAndSettle();

      expect(find.text('RECENT'), findsOneWidget);
      expect(find.text('Cairo Festival City'), findsOneWidget);
      expect(find.text('Maadi Grand Mall'), findsOneWidget);

      // Clear history button works
      final clearBtn = find.text('Clear');
      expect(clearBtn, findsOneWidget);

      await tester.tap(clearBtn);
      await tester.pumpAndSettle();

      expect(find.text('Cairo Festival City'), findsNothing);
      expect(find.text('RECENT'), findsNothing);
    });

    testWidgets('pasting bare coordinates into search field handles resolution', (tester) async {
      await tester.pumpWidget(buildSearchScreen());
      await tester.pumpAndSettle();

      final firstTextField = find.byType(TextField).first;
      await tester.enterText(firstTextField, '30.0444, 31.2357');
      await tester.pumpAndSettle();

      // MapsLinkParser recognizes it as coordinates and handles it safely without crashing
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders properly in Arabic locale without layout overflow', (tester) async {
      tester.view.physicalSize = const Size(390 * 2.5, 844 * 2.5);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildSearchScreen(locale: const Locale('ar')));
      await tester.pumpAndSettle();

      expect(find.byType(LocationSearchScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
