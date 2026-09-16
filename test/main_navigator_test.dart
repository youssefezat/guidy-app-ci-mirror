import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:guidy_app/screens/MainNavigator.dart';
import 'package:guidy_app/screens/HomeScreen.dart';
import 'package:guidy_app/screens/SettingsScreen.dart';
import 'package:guidy_app/screens/LinesScreen.dart';
import 'package:guidy_app/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildNavigator({Locale locale = const Locale('en')}) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      home: const MainNavigator(),
    );
  }

  group('MainNavigator & HomeScreen Widget Tests', () {
    testWidgets('renders NavigationBar with all 5 destinations and defaults to Home', (tester) async {
      tester.view.physicalSize = const Size(400 * 2.0, 800 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildNavigator());
      await tester.pumpAndSettle();

      // Verify 5 NavigationBar destinations exist
      final navDestinations = find.byType(NavigationDestination);
      expect(navDestinations, findsNWidgets(5));

      // Navigation labels in English using widgetWithText
      expect(find.widgetWithText(NavigationDestination, 'Lines'), findsOneWidget);
      expect(find.widgetWithText(NavigationDestination, 'Metro'), findsOneWidget);
      expect(find.widgetWithText(NavigationDestination, 'Home'), findsOneWidget);
      expect(find.widgetWithText(NavigationDestination, 'Trips'), findsOneWidget);
      expect(find.widgetWithText(NavigationDestination, 'Settings'), findsOneWidget);

      // Default index is 2 (HomeScreen)
      final indexedStack = tester.widget<IndexedStack>(find.byType(IndexedStack));
      expect(indexedStack.index, equals(2));
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('switching tabs via NavigationBar changes the active IndexedStack index', (tester) async {
      tester.view.physicalSize = const Size(400 * 2.0, 800 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildNavigator());
      await tester.pumpAndSettle();

      // Tap Settings (index 4)
      await tester.tap(find.widgetWithText(NavigationDestination, 'Settings'));
      await tester.pumpAndSettle();

      var indexedStack = tester.widget<IndexedStack>(find.byType(IndexedStack));
      expect(indexedStack.index, equals(4));
      expect(find.byType(SettingsScreen), findsOneWidget);

      // Tap Lines (index 0)
      await tester.tap(find.widgetWithText(NavigationDestination, 'Lines'));
      await tester.pumpAndSettle();

      indexedStack = tester.widget<IndexedStack>(find.byType(IndexedStack));
      expect(indexedStack.index, equals(0));
      expect(find.byType(LinesScreen), findsOneWidget);

      // Tap Home (index 2) to return
      await tester.tap(find.widgetWithText(NavigationDestination, 'Home'));
      await tester.pumpAndSettle();

      indexedStack = tester.widget<IndexedStack>(find.byType(IndexedStack));
      expect(indexedStack.index, equals(2));
    });

    testWidgets('onGoHome in Settings returns to Home tab (index 2)', (tester) async {
      tester.view.physicalSize = const Size(400 * 2.0, 800 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildNavigator());
      await tester.pumpAndSettle();

      // Switch to Settings tab
      await tester.tap(find.widgetWithText(NavigationDestination, 'Settings'));
      await tester.pumpAndSettle();

      expect(tester.widget<IndexedStack>(find.byType(IndexedStack)).index, equals(4));

      // Tap back button on Settings screen
      final backBtn = find.byIcon(Icons.arrow_back);
      expect(backBtn, findsOneWidget);
      await tester.tap(backBtn);
      await tester.pumpAndSettle();

      // Should return to Home tab
      expect(tester.widget<IndexedStack>(find.byType(IndexedStack)).index, equals(2));
    });

    testWidgets('renders cleanly in Arabic locale without layout overflow', (tester) async {
      tester.view.physicalSize = const Size(390 * 2.5, 844 * 2.5);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildNavigator(locale: const Locale('ar')));
      await tester.pumpAndSettle();

      expect(find.byType(MainNavigator), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
