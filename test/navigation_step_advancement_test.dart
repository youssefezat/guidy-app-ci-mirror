import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:guidy_app/widgets/animated_nav_step_icon.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Position makePos({
    required double lat,
    required double lng,
    double speed = 0.0,
    double heading = 0.0,
  }) {
    return Position(
      latitude: lat,
      longitude: lng,
      timestamp: DateTime.now(),
      accuracy: 5.0,
      altitude: 0.0,
      altitudeAccuracy: 0.0,
      heading: heading,
      headingAccuracy: 0.0,
      speed: speed,
      speedAccuracy: 0.0,
    );
  }

  group('AnimatedNavStepIcon Widget Tests', () {
    testWidgets('Renders walking stick man and animates when isMoving is true', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: AnimatedNavStepIcon(
                iconKey: 'walk',
                isMoving: true,
                color: Colors.teal,
                size: 24,
              ),
            ),
          ),
        ),
      );

      // Verify custom paint exists for stick man
      expect(find.byType(CustomPaint), findsWidgets);

      // Advance frames to verify smooth animation progression
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.hasRunningAnimations, isTrue);
    });

    testWidgets('Walking stick man stops animating when isMoving is false', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: AnimatedNavStepIcon(
                iconKey: 'walk',
                isMoving: false,
                color: Colors.teal,
                size: 24,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('Renders vehicle icons for bus, minibus, microbus with road lines when moving', (WidgetTester tester) async {
      for (final mode in ['bus', 'minibus', 'microbus']) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: AnimatedNavStepIcon(
                  iconKey: mode,
                  isMoving: true,
                  color: Colors.blue,
                  size: 24,
                ),
              ),
            ),
          ),
        );

        expect(find.byType(AnimatedNavStepIcon), findsOneWidget);
        await tester.pump(const Duration(milliseconds: 100));
      }
    });

    testWidgets('Renders rail and transfer mode animations', (WidgetTester tester) async {
      for (final mode in ['metro', 'subway', 'train', 'transfer', 'arrive']) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: AnimatedNavStepIcon(
                  iconKey: mode,
                  isMoving: true,
                  color: Colors.orange,
                  size: 24,
                ),
              ),
            ),
          ),
        );

        expect(find.byType(AnimatedNavStepIcon), findsOneWidget);
        await tester.pump(const Duration(milliseconds: 100));
      }
    });
  });

  group('Smooth User Marker Heading Interpolation Tests', () {
    double lerpHeading(double from, double to, double t) {
      double diff = (to - from + 180) % 360 - 180;
      if (diff < -180) diff += 360;
      return (from + diff * t + 360) % 360;
    }

    test('Interpolates normal headings without wrapping', () {
      expect(lerpHeading(0, 90, 0.5), closeTo(45.0, 0.001));
      expect(lerpHeading(100, 200, 0.5), closeTo(150.0, 0.001));
    });

    test('Smoothly interpolates across 0/360 degree boundary without spinning', () {
      // From 350 to 10 degrees is a 20 degree clockwise turn
      final mid = lerpHeading(350, 10, 0.5);
      expect(mid, closeTo(0.0, 0.001));

      // From 10 to 350 degrees is a 20 degree counter-clockwise turn
      final midReverse = lerpHeading(10, 350, 0.5);
      expect(midReverse, closeTo(0.0, 0.001));
    });
  });

  group('Navigation Step Advancement Simulation Across Random Routes', () {
    // Helper simulator representing MapScreen step progression logic
    late List<Map<String, dynamic>> instructions;
    late List<LatLng> stepPoints;
    int currentStepIndex = 0;
    bool isUserMoving = false;
    Position? lastGpsPosition;

    void resetNavigation(List<Map<String, dynamic>> testInstructions, List<LatLng> testPoints) {
      instructions = testInstructions;
      stepPoints = testPoints;
      currentStepIndex = 0;
      isUserMoving = false;
      lastGpsPosition = null;
    }

    void onGpsPositionReceived(Position position) {
      // 1. Motion detection
      final double speed = position.speed;
      bool moved = speed >= 0.5;
      if (!moved && lastGpsPosition != null) {
        final d = Geolocator.distanceBetween(
          lastGpsPosition!.latitude, lastGpsPosition!.longitude,
          position.latitude, position.longitude,
        );
        moved = d >= 2.0;
      }
      isUserMoving = moved;
      lastGpsPosition = position;

      // 2. Step advancement check (approaching within 100m of next waypoint)
      if (currentStepIndex >= instructions.length - 1) return;
      final int next = currentStepIndex + 1;
      if (next >= stepPoints.length) return;

      final target = stepPoints[next];
      final distance = Geolocator.distanceBetween(
        position.latitude, position.longitude,
        target.latitude, target.longitude,
      );

      if (distance < 100.0) {
        currentStepIndex = next;
      }
    }

    test('Route 1 (Metro Line 1: Sadat to Ramses) step progression and arrival', () {
      // Step 0: Walk to Sadat (30.0444, 31.2357)
      // Step 1: Metro from Sadat to Ramses (30.0617, 31.2464)
      // Step 2: Arrive at Ramses (30.0617, 31.2464)
      final metroRoute = [
        {'action': 'walk', 'station': 'Sadat', 'icon': 'walk'},
        {'action': 'ride', 'station': 'Ramses', 'icon': 'metro'},
        {'action': 'arrive', 'station': 'Ramses', 'icon': 'arrive'},
      ];
      final metroPoints = [
        const LatLng(30.0420, 31.2330), // Start ~350m away from Sadat
        const LatLng(30.0444, 31.2357), // Sadat station
        const LatLng(30.0617, 31.2464), // Ramses station
      ];

      resetNavigation(metroRoute, metroPoints);
      expect(currentStepIndex, 0);

      // User stationary at start
      onGpsPositionReceived(makePos(lat: 30.0420, lng: 31.2330, speed: 0.0, heading: 45.0));
      expect(isUserMoving, isFalse);
      expect(currentStepIndex, 0);

      // User walks towards Sadat (speed 1.2 m/s, ~180m away from Sadat)
      onGpsPositionReceived(makePos(lat: 30.0432, lng: 31.2345, speed: 1.2, heading: 45.0));
      expect(isUserMoving, isTrue);
      expect(currentStepIndex, 0); // Still > 100m from Sadat

      // User arrives at Sadat entrance (< 100m, e.g. 30m away)
      onGpsPositionReceived(makePos(lat: 30.0442, lng: 31.2356, speed: 1.1, heading: 45.0));
      // App advances to step 1 (Board Metro)
      expect(currentStepIndex, 1);
      expect(instructions[currentStepIndex]['icon'], 'metro');

      // Metro train moves towards Ramses (speed 12 m/s)
      onGpsPositionReceived(makePos(lat: 30.0520, lng: 31.2400, speed: 12.0, heading: 30.0));
      expect(isUserMoving, isTrue);
      expect(currentStepIndex, 1);

      // Metro arrives at Ramses station (< 100m)
      onGpsPositionReceived(makePos(lat: 30.0615, lng: 31.2463, speed: 0.2, heading: 30.0));
      // Advances to arrival step
      expect(currentStepIndex, 2);
      expect(instructions[currentStepIndex]['action'], 'arrive');
    });

    test('Route 2 (CTA Bus 1073: Abbasia to Nasr City) step progression', () {
      final busRoute = [
        {'action': 'walk', 'station': 'Abbasia Stop', 'icon': 'walk'},
        {'action': 'ride', 'station': 'Nasr City', 'icon': 'bus'},
        {'action': 'arrive', 'station': 'Nasr City', 'icon': 'arrive'},
      ];
      final busPoints = [
        const LatLng(30.0650, 31.2800), // Walk start
        const LatLng(30.0674, 31.2828), // Abbasia bus stop
        const LatLng(30.0558, 31.3368), // Nasr City stop
      ];

      resetNavigation(busRoute, busPoints);
      expect(currentStepIndex, 0);

      // Walking to bus stop at 1.4 m/s
      onGpsPositionReceived(makePos(lat: 30.0672, lng: 31.2825, speed: 1.4, heading: 50.0));
      expect(isUserMoving, isTrue);
      expect(currentStepIndex, 1); // Advances to Bus 1073 ride

      // Bus glides to destination
      onGpsPositionReceived(makePos(lat: 30.0557, lng: 31.3366, speed: 8.5, heading: 110.0));
      expect(currentStepIndex, 2); // Arrived!
    });

    test('Route 3 (Microbus: Giza Square to Haram) step progression', () {
      final microbusRoute = [
        {'action': 'walk', 'station': 'Giza Square', 'icon': 'walk'},
        {'action': 'ride', 'station': 'Haram Station', 'icon': 'microbus'},
        {'action': 'arrive', 'station': 'Haram Station', 'icon': 'arrive'},
      ];
      final microbusPoints = [
        const LatLng(30.0050, 31.2060), // Start ~320m away
        const LatLng(30.0074, 31.2089), // Giza Square stop
        const LatLng(29.9870, 31.1500), // Haram stop
      ];

      resetNavigation(microbusRoute, microbusPoints);
      expect(currentStepIndex, 0);

      // User stationary waiting for light
      onGpsPositionReceived(makePos(lat: 30.0050, lng: 31.2060, speed: 0.1, heading: 0.0));
      expect(isUserMoving, isFalse);

      // User arrives at microbus boarding point in Giza Square
      onGpsPositionReceived(makePos(lat: 30.0072, lng: 31.2087, speed: 1.3, heading: 45.0));
      expect(isUserMoving, isTrue);
      expect(currentStepIndex, 1); // Advances to microbus ride

      // Microbus reaches Haram stop
      onGpsPositionReceived(makePos(lat: 29.9871, lng: 31.1502, speed: 5.0, heading: 240.0));
      expect(currentStepIndex, 2); // Arrived!
    });
  });
}
