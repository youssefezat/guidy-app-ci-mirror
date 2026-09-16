import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guidy_app/screens/RouteReportScreen.dart';
import 'package:guidy_app/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final mockOption = {
    'time': 35,
    'fare_total_egp': 15,
    'instructions': [
      {
        'action': 'walk_to_station',
        'distance_m': 300,
        'station': 'Dokki Station',
        'vehicle_type': 'walk',
      },
      {
        'action': 'board',
        'vehicle_type': 'metro',
        'route_number': 'Line 2',
        'route_description': 'Shubra - El Mounib',
        'station': 'Dokki Station',
        'fare_egp': 10,
      },
      {
        'action': 'board',
        'vehicle_type': 'bus',
        'route_number': '102',
        'route_description': 'Attaba to Nasr City',
        'station': 'Attaba Station',
        'fare_egp': 5,
      },
    ],
  };

  Widget buildReportScreen({
    Map<String, dynamic>? option,
    String startName = 'Dokki Square',
    String endName = 'Abbassiya',
    Locale locale = const Locale('en'),
  }) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      home: RouteReportScreen(
        option: option ?? mockOption,
        startName: startName,
        endName: endName,
      ),
    );
  }

  group('RouteReportScreen Widget Tests', () {
    testWidgets('renders instructions list, reason chips, comment input, and submit button', (tester) async {
      tester.view.physicalSize = const Size(400 * 2.0, 1000 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildReportScreen());
      await tester.pumpAndSettle();

      expect(find.text('Report this route'), findsOneWidget);
      expect(find.text('WHICH PART IS WRONG?'), findsOneWidget);
      expect(find.text('Select all'), findsOneWidget);

      // Verify instruction steps are rendered with checkboxes
      expect(find.byType(Checkbox), findsNWidgets(3));

      // Verify reason chips header
      expect(find.text('WHAT\'S THE PROBLEM?'), findsOneWidget);
      expect(find.byType(ChoiceChip), findsWidgets);

      // Verify comment box and submit button
      expect(find.text('TELL US MORE'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Send report'), findsOneWidget);
    });

    testWidgets('tapping individual step selects and deselects it', (tester) async {
      tester.view.physicalSize = const Size(400 * 2.0, 1000 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildReportScreen());
      await tester.pumpAndSettle();

      final firstCheckbox = tester.widget<Checkbox>(find.byType(Checkbox).first);
      expect(firstCheckbox.value, isFalse);

      // Tap first step
      await tester.tap(find.byType(Checkbox).first);
      await tester.pumpAndSettle();

      final updatedCheckbox = tester.widget<Checkbox>(find.byType(Checkbox).first);
      expect(updatedCheckbox.value, isTrue);

      // Tap again to deselect
      await tester.tap(find.byType(Checkbox).first);
      await tester.pumpAndSettle();

      final deselectedCheckbox = tester.widget<Checkbox>(find.byType(Checkbox).first);
      expect(deselectedCheckbox.value, isFalse);
    });

    testWidgets('Select all button selects all steps and reveals whole route note', (tester) async {
      tester.view.physicalSize = const Size(400 * 2.0, 1000 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildReportScreen());
      await tester.pumpAndSettle();

      expect(find.text('You\'ve selected every step, so this goes in as a report about the whole route.'), findsNothing);

      // Tap 'Select all'
      await tester.tap(find.text('Select all'));
      await tester.pumpAndSettle();

      // All checkboxes are now true
      for (final element in tester.widgetList<Checkbox>(find.byType(Checkbox))) {
        expect(element.value, isTrue);
      }

      // Button toggles to 'Clear'
      expect(find.text('Clear'), findsOneWidget);
      expect(find.text('You\'ve selected every step, so this goes in as a report about the whole route.'), findsOneWidget);

      // Tap 'Clear'
      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();

      for (final element in tester.widgetList<Checkbox>(find.byType(Checkbox))) {
        expect(element.value, isFalse);
      }
      expect(find.text('Select all'), findsOneWidget);
      expect(find.text('You\'ve selected every step, so this goes in as a report about the whole route.'), findsNothing);
    });

    testWidgets('selecting "I know a better way" updates comment hint text', (tester) async {
      tester.view.physicalSize = const Size(400 * 2.0, 1200 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildReportScreen());
      await tester.pumpAndSettle();

      // Default hint
      expect(find.text('Optional — anything that helps us check it.'), findsOneWidget);

      // Tap 'I know a better way'
      await tester.tap(find.text('I know a better way'));
      await tester.pumpAndSettle();

      // Hint updates to required prompt
      expect(find.text('Which route would you take instead?'), findsOneWidget);
    });

    testWidgets('validation: tapping submit with no steps selected shows error', (tester) async {
      tester.view.physicalSize = const Size(400 * 2.0, 1200 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildReportScreen());
      await tester.pumpAndSettle();

      expect(find.text('Pick at least one step to report.'), findsNothing);

      await tester.tap(find.text('Send report'));
      await tester.pumpAndSettle();

      expect(find.text('Pick at least one step to report.'), findsOneWidget);
    });

    testWidgets('validation: tapping submit with step selected but no reason shows error', (tester) async {
      tester.view.physicalSize = const Size(400 * 2.0, 1200 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildReportScreen());
      await tester.pumpAndSettle();

      // Select first step
      await tester.tap(find.byType(Checkbox).first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Send report'));
      await tester.pumpAndSettle();

      expect(find.text('Pick what\'s wrong with it.'), findsOneWidget);
    });

    testWidgets('validation: tapping submit with "I know a better way" and empty comment shows error', (tester) async {
      tester.view.physicalSize = const Size(400 * 2.0, 1200 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildReportScreen());
      await tester.pumpAndSettle();

      // Select step and reason
      await tester.tap(find.byType(Checkbox).first);
      await tester.tap(find.text('I know a better way'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Send report'));
      await tester.pumpAndSettle();

      expect(find.text('Please tell us a bit more so we can act on it.'), findsOneWidget);
    });

    testWidgets('validation error clears when typing in comment field', (tester) async {
      tester.view.physicalSize = const Size(400 * 2.0, 1200 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildReportScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Checkbox).first);
      await tester.tap(find.text('I know a better way'));
      await tester.tap(find.text('Send report'));
      await tester.pumpAndSettle();

      expect(find.text('Please tell us a bit more so we can act on it.'), findsOneWidget);

      // Type in comment field
      await tester.enterText(find.byType(TextField), 'Take microbus from Dokki instead');
      await tester.pumpAndSettle();

      // Error message should be dismissed
      expect(find.text('Please tell us a bit more so we can act on it.'), findsNothing);
    });

    testWidgets('renders cleanly in Arabic locale without layout overflow', (tester) async {
      tester.view.physicalSize = const Size(390 * 2.5, 844 * 2.5);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildReportScreen(locale: const Locale('ar')));
      await tester.pumpAndSettle();

      expect(find.byType(RouteReportScreen), findsOneWidget);
      expect(find.text('ابعت البلاغ'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
