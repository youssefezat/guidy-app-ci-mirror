import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guidy_app/l10n/app_localizations.dart';
import 'package:guidy_app/screens/RailNetworkMapScreen.dart';

void main() {
  Widget createTestWidget({bool initialRealMap = false}) {
    return MaterialApp(
      locale: const Locale('ar'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: RailNetworkMapScreen(initialRealMap: initialRealMap),
    );
  }

  group('RailNetworkMapScreen Widget Tests', () {
    testWidgets('renders schematic tab, controls, and switches to station directory',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(initialRealMap: false));
      await tester.pumpAndSettle();

      // Verify AppBar title and tabs
      expect(find.text('خريطة شبكة قطارات ومترو القاهرة'), findsOneWidget);
      expect(find.text('مخطط الشبكة التخطيطي'), findsOneWidget);
      expect(find.text('دليل المحطات'), findsOneWidget);

      // Verify InteractiveViewer is present
      expect(find.byType(InteractiveViewer), findsOneWidget);

      // Verify zoom in / out / reset FABs exist
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.byIcon(Icons.remove), findsOneWidget);
      expect(find.byIcon(Icons.restore), findsOneWidget);
      expect(find.byIcon(Icons.center_focus_strong_rounded), findsOneWidget);

      // Test tapping zoom in and zoom out
      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.remove));
      await tester.pump();

      // Tap the "دليل المحطات" tab
      await tester.tap(find.text('دليل المحطات'));
      await tester.pumpAndSettle();

      // Verify directory search field and interchange chips
      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.text('السادات'), findsWidgets);
      expect(find.text('الشهداء'), findsWidgets);
    });

    testWidgets('filtering stations by query in directory view',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Switch to directory tab
      await tester.tap(find.text('دليل المحطات'));
      await tester.pumpAndSettle();

      // Enter search query
      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);
      await tester.enterText(searchField, 'حلوان');
      await tester.pumpAndSettle();

      // Verify Helwan station is present in results
      expect(find.text('حلوان'), findsWidgets);
    });

    testWidgets('tapping receipt icon opens official Fares and Pass Guide sheet',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap the receipt IconButton in the AppBar
      final receiptBtn = find.widgetWithIcon(IconButton, Icons.receipt_long_rounded);
      expect(receiptBtn, findsOneWidget);
      await tester.tap(receiptBtn);
      await tester.pumpAndSettle();

      // Verify Fares & Pass Guide modal title and stage fares
      expect(find.text('دليل تذاكر واشتراكات النقل السككي'), findsOneWidget);
      expect(find.text('10 ج.م'), findsWidgets);
      expect(find.text('12 ج.م'), findsWidgets);
      expect(find.text('15 ج.م'), findsWidgets);
      expect(find.text('20 ج.م'), findsWidgets);
      expect(find.text('فتح حاسبة الاشتراكات'), findsOneWidget);
    });
  });
}
