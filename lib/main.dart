import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Updated import paths to point to your screens folder
import 'screens/AuthGate.dart';
import 'screens/SignInScreen.dart';
import 'screens/SignUpScreen.dart';
import 'screens/MainNavigator.dart';
import 'screens/OnboardingScreen.dart';
import 'services/api_service.dart';
import 'services/locale_controller.dart';
import 'services/theme_controller.dart';
import 'services/analytics_service.dart';
import 'services/notification_service.dart';
import 'services/tracking_service.dart';
import 'services/deep_link_service.dart';
import 'services/app_open_ad_service.dart';
import 'theme/app_theme.dart';
import 'widgets/animated_splash.dart';
import 'l10n/app_localizations.dart';
import 'firebase_options.dart';

/// Lets DeepLinkService push a screen from outside the widget tree (the
/// incoming-link listener isn't itself a widget with a BuildContext).
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  // Everything -- including WidgetsFlutterBinding.ensureInitialized() and
  // runApp -- runs inside the SAME zone created by runZonedGuarded. Doing
  // the binding init before/outside this call (as this used to) trips
  // Flutter's "Zone mismatch" assertion on every launch: the binding
  // is initialized in the root zone while runApp then runs in a
  // different (guarded) zone, which is exactly the inconsistency
  // BindingBase.debugCheckZone warns about. It's non-fatal in debug mode,
  // but it's still a real bug -- zone-specific state (like this error
  // handler) can silently attach to the wrong zone depending on timing.
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    final bool isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);

    // Initialize Firebase Safely
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e) {
      debugPrint("Firebase initialized natively or caught an options error: $e");
    }

    final bool isFirebaseReady = Firebase.apps.isNotEmpty;

    // Crashlytics: route all uncaught Flutter framework errors there. Only
    // active on real mobile devices/builds with initialized Firebase.
    if (!kDebugMode && isFirebaseReady && isMobile) {
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
    }

    // Load saved preferences before the first frame so the app doesn't flash
    // in the wrong language/theme. Theme defaults to following the device's
    // system setting until the person overrides it in Settings.
    await localeController.loadSavedLocale();
    await themeController.loadSavedTheme();
    unawaited(ApiService.init());

    // Push notification permission + token setup (mobile-only).
    if (isMobile && isFirebaseReady) {
      await NotificationService.initialize();
    }

    // App Tracking Transparency (iOS only, no-op elsewhere) -- must be
    // resolved before MobileAds initializes below, and after the
    // notification prompt above, since iOS can't show two native
    // permission dialogs at the same time. See tracking_service.dart.
    if (isMobile) {
      await TrackingService.requestAuthorization();
      try {
        await MobileAds.instance.initialize();
      } catch (e) {
        debugPrint('MobileAds initialization error: $e');
      }
    }

    runApp(const GuidyApp());

    // After runApp so navigatorKey.currentState is available by the time a
    // link actually arrives (cold-start links are still handled correctly
    // -- DeepLinkService checks getInitialLink() too, it just can't act on
    // it until the navigator exists).
    DeepLinkService.initialize(navigatorKey);

    // Full-screen ad when a rider returns after being away a while (mobile-only).
    if (isMobile) {
      try {
        AppOpenAdService.instance.initialize();
      } catch (e) {
        debugPrint('AppOpenAdService initialization error: $e');
      }
    }
  }, (error, stack) {
    if (!kDebugMode && Firebase.apps.isNotEmpty) {
      try {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      } catch (_) {
        debugPrint('Uncaught error: $error\n$stack');
      }
    } else {
      debugPrint('Uncaught zone error: $error\n$stack');
    }
  });
}

/// Decides whether to show the first-run onboarding carousel or go
/// straight to AuthGate, based on whether onboarding has been seen before.
class StartupGate extends StatefulWidget {
  const StartupGate({super.key});

  @override
  State<StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<StartupGate> {
  // Created ONCE, in initState. It used to be built inline in build(), which
  // meant every rebuild started a fresh future -- and GuidyApp rebuilds on
  // any locale or theme change, so toggling dark mode replayed the whole
  // launch sequence. A FutureBuilder whose future is constructed in build()
  // is nearly always this bug; it just had nothing visible to give it away
  // while the loading state was a blank SizedBox.
  late final Future<bool> _startup = _resolve();

  Future<bool> _resolve() async {
    // Both, not one after the other: the animation and the disk read overlap,
    // so the splash costs its own duration and not a millisecond more. On a
    // slow first launch SharedPreferences is the long pole and the animation
    // is free; on a warm one the animation is, and it gets to finish instead
    // of flashing half-played.
    final splash = Future<void>.delayed(AnimatedSplash.duration);
    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool(OnboardingScreen.prefsKey) ?? false;
    await splash;
    return hasSeenOnboarding;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _startup,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const AnimatedSplash();
        }
        final hasSeenOnboarding = snapshot.data!;
        return hasSeenOnboarding ? const AuthGate() : const OnboardingScreen();
      },
    );
  }
}

class GuidyApp extends StatelessWidget {
  const GuidyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: localeController,
      builder: (context, locale, _) {
        return ValueListenableBuilder<ThemeMode>(
          valueListenable: themeController,
          builder: (context, mode, _) {
            return MaterialApp(
              navigatorKey: navigatorKey,
              title: 'Guidy Transit',
              debugShowCheckedModeBanner: false,
              locale: locale,
              supportedLocales: const [
                Locale('en'),
                Locale('ar', 'EG'),
              ],
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              theme: AppTheme.light(locale),
              darkTheme: AppTheme.dark(locale),
              // Follows the device's system setting until the person flips
              // the Dark Mode switch in Settings, which sets an explicit
              // override (see ThemeController).
              themeMode: mode,
              navigatorObservers: [AnalyticsService.observer],
              // StartupGate decides onboarding vs. AuthGate; AuthGate then
              // makes the signed-in-vs-not routing decision as before.
              home: const StartupGate(),
              routes: {
                '/home': (context) => const MainNavigator(),
                '/signin': (context) => const SignInScreen(),
                '/signup': (context) => const SignUpScreen(),
              },
            );
          },
        );
      },
    );
  }
}
