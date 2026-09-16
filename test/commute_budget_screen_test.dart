import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guidy_app/screens/CommuteBudgetScreen.dart';
import 'package:guidy_app/services/commute_budget_service.dart';
import 'package:guidy_app/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildBudgetScreen({
    int initialSingleFare = 12,
    int initialStationsCount = 14,
    Locale locale = const Locale('en'),
  }) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      home: CommuteBudgetScreen(
        initialSingleFareEgp: initialSingleFare,
        initialStationsCount: initialStationsCount,
      ),
    );
  }

  group('CommuteBudgetScreen Widget Tests', () {
    testWidgets('renders header banner with initial monthly ticket calculation and trips badge', (tester) async {
      tester.view.physicalSize = const Size(400 * 2.0, 1000 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildBudgetScreen(initialSingleFare: 12, initialStationsCount: 14));
      await tester.pumpAndSettle();

      // Title in AppBar
      expect(find.text('Commute Cost Calculator'), findsOneWidget);

      // Hero banner
      expect(find.text('Transit Budget & Metro Pass Savings'), findsOneWidget);

      // Default: 5 days/week = 44 trips * 12 EGP = 528 EGP
      expect(find.text('528'), findsOneWidget);
      expect(find.text('44 trips'), findsOneWidget);
      expect(find.text('EGP / month'), findsOneWidget);
    });

    testWidgets('renders commuter category SegmentedButton and switches between types', (tester) async {
      tester.view.physicalSize = const Size(600 * 2.0, 1400 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildBudgetScreen());
      await tester.pumpAndSettle();

      expect(find.byType(SegmentedButton<CommuterType>), findsOneWidget);
      expect(find.text('General Public'), findsOneWidget);
      expect(find.text('Students (90% discount)'), findsOneWidget);

      // Tap on Students segment
      await tester.tap(find.text('Students (90% discount)'));
      await tester.pumpAndSettle();

      // Scroll to savings card to ensure it's visible
      await tester.scrollUntilVisible(
        find.text('Monthly Pass Savings'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      // Student pass provides huge monthly savings
      expect(find.textContaining('Save'), findsWidgets);
    });

    testWidgets('adjusting days per week slider updates trips count and monthly costs', (tester) async {
      tester.view.physicalSize = const Size(450 * 2.0, 1400 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildBudgetScreen(initialSingleFare: 12));
      await tester.pumpAndSettle();

      expect(find.text('528'), findsOneWidget);
      expect(find.text('44 trips'), findsOneWidget);

      // Locate slider
      final sliderFinder = find.byType(Slider);
      expect(sliderFinder, findsOneWidget);

      // Drag slider all the way to the right (7 days)
      await tester.drag(sliderFinder, const Offset(300, 0));
      await tester.pumpAndSettle();

      // 7 days/week = (7 * 4.4 * 2) = ~62 trips * 12 EGP = 744 EGP
      expect(find.text('744'), findsOneWidget);
      expect(find.text('62 trips'), findsOneWidget);
    });

    testWidgets('tapping stage chips updates selected stage and calculation', (tester) async {
      tester.view.physicalSize = const Size(450 * 2.0, 1400 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildBudgetScreen(initialSingleFare: 12, initialStationsCount: 14));
      await tester.pumpAndSettle();

      // Tap Stage 4 chip (24+ stops, 20 EGP)
      final stage4Finder = find.text('Stage 4 (24+ stops)');
      expect(stage4Finder, findsOneWidget);

      await tester.tap(stage4Finder);
      await tester.pumpAndSettle();

      // 44 trips * 20 EGP = 880 EGP
      expect(find.text('880'), findsOneWidget);
      expect(find.textContaining('Stage 4'), findsWidgets);
    });

    testWidgets('renders metro subscription offices list and route buttons', (tester) async {
      tester.view.physicalSize = const Size(450 * 2.0, 2000 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildBudgetScreen());
      await tester.pumpAndSettle();

      // Scroll to offices section
      final headerFinder = find.text('Metro Subscription Offices');
      await tester.scrollUntilVisible(
        headerFinder,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      // Check section header
      expect(headerFinder, findsOneWidget);
      expect(find.text('Tap "Route Here" to get live transit directions to any office:'), findsOneWidget);

      // Check known office names (e.g. Attaba, Sadat)
      expect(find.text('Attaba'), findsOneWidget);
      expect(find.text('Sadat (Tahrir)'), findsOneWidget);

      // Route Here buttons are present
      expect(find.text('Route Here'), findsWidgets);
    });

    testWidgets('back button pops the screen', (tester) async {
      tester.view.physicalSize = const Size(400 * 2.0, 800 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CommuteBudgetScreen()),
                  );
                },
                child: const Text('Open Budget'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Budget'));
      await tester.pumpAndSettle();

      expect(find.byType(CommuteBudgetScreen), findsOneWidget);

      // Tap back button
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.byType(CommuteBudgetScreen), findsNothing);
    });

    testWidgets('renders properly in Arabic locale without layout overflow', (tester) async {
      tester.view.physicalSize = const Size(390 * 2.5, 844 * 2.5);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildBudgetScreen(locale: const Locale('ar')));
      await tester.pumpAndSettle();

      expect(find.text('حاسبة مصاريف المواصلات'), findsOneWidget);
      final officesFinder = find.text('مكاتب الاشتراكات في محطات المترو');
      await tester.scrollUntilVisible(
        officesFinder,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(officesFinder, findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
