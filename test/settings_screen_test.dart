import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:guidy_app/screens/SettingsScreen.dart';
import 'package:guidy_app/services/theme_controller.dart';
import 'package:guidy_app/services/locale_controller.dart';
import 'package:guidy_app/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildSettingsScreen({VoidCallback? onGoHome, Locale locale = const Locale('en')}) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      home: SettingsScreen(onGoHome: onGoHome),
    );
  }

  group('SettingsScreen Widget Tests', () {
    testWidgets('renders all section headers and core items cleanly', (tester) async {
      tester.view.physicalSize = const Size(400 * 2.0, 1200 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildSettingsScreen());
      await tester.pumpAndSettle();

      // Verify app bar title
      expect(find.text('Settings'), findsOneWidget);

      // Section labels
      expect(find.text('ACCOUNT'), findsOneWidget);
      expect(find.text('PREFERENCES'), findsOneWidget);
      expect(find.text('SUPPORT'), findsOneWidget);

      // Core actions
      expect(find.text('Dark Mode'), findsOneWidget);
      expect(find.text('Language'), findsOneWidget);
      expect(find.text('Contact Us'), findsOneWidget);
      expect(find.text('Rate Guidy'), findsOneWidget);
      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.text('Log Out'), findsOneWidget);
      expect(find.text('Delete Account'), findsOneWidget);

      // Scroll down to version badge at the bottom
      await tester.scrollUntilVisible(find.text('v1.0.0'), 100);
      expect(find.text('v1.0.0'), findsOneWidget);
    });

    testWidgets('shows back button when onGoHome is provided and triggers callback', (tester) async {
      var homeClicked = false;
      await tester.pumpWidget(buildSettingsScreen(onGoHome: () => homeClicked = true));
      await tester.pumpAndSettle();

      final backButton = find.byIcon(Icons.arrow_back);
      expect(backButton, findsOneWidget);

      await tester.tap(backButton);
      await tester.pumpAndSettle();

      expect(homeClicked, isTrue);
    });

    testWidgets('does not show back button when onGoHome is null', (tester) async {
      await tester.pumpWidget(buildSettingsScreen(onGoHome: null));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_back), findsNothing);
    });

    testWidgets('Dark Mode toggle interacts with themeController', (tester) async {
      themeController.value = ThemeMode.system;
      await tester.pumpWidget(buildSettingsScreen());
      await tester.pumpAndSettle();

      final switchFinder = find.byType(Switch);
      expect(switchFinder, findsOneWidget);

      // Tap switch -> flips to dark
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();
      expect(themeController.value, equals(ThemeMode.dark));

      // Tap switch -> flips to light
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();
      expect(themeController.value, equals(ThemeMode.light));
    });

    testWidgets('Language item displays current language name', (tester) async {
      await tester.pumpWidget(buildSettingsScreen());
      await tester.pumpAndSettle();

      // In English locale, should show English or Arabic depending on controller
      final langLabel = localeController.isArabic ? 'العربية' : 'English';
      expect(find.text(langLabel), findsOneWidget);
    });

    testWidgets('renders cleanly in Arabic locale without overflow', (tester) async {
      tester.view.physicalSize = const Size(390 * 2.5, 844 * 2.5);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildSettingsScreen(locale: const Locale('ar')));
      await tester.pumpAndSettle();

      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
