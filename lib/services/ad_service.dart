import 'dart:io' show Platform;

/// Ad unit IDs read from secrets.properties (via
/// `flutter run --dart-define-from-file=secrets.properties`), with
/// Google's official public TEST ad unit IDs as the compile-time default
/// if that flag isn't passed -- so `flutter run` still works out of the
/// box during development, it just always serves test ads until you
/// build with the dart-define-from-file flag pointed at a real
/// secrets.properties containing your production IDs.
class AdService {
  static const String _testBannerAndroid = 'ca-app-pub-3940256099942544/6300978111';
  static const String _testBannerIOS = 'ca-app-pub-3940256099942544/2934735716';

  static const String _bannerAndroid = String.fromEnvironment(
    'ADMOB_BANNER_AD_UNIT_ID_ANDROID',
    defaultValue: _testBannerAndroid,
  );
  static const String _bannerIOS = String.fromEnvironment(
    'ADMOB_BANNER_AD_UNIT_ID_IOS',
    defaultValue: _testBannerIOS,
  );

  static String get bannerAdUnitId => Platform.isAndroid ? _bannerAndroid : _bannerIOS;

  // --- App open -----------------------------------------------------------
  // Shown when a rider returns after being away (see app_open_ad_service.dart).
  // The unit IDs were already collected in secrets.properties and marked
  // "not yet wired into any code" -- this wires them.
  static const String _testAppOpenAndroid = 'ca-app-pub-3940256099942544/9257395921';
  static const String _testAppOpenIOS = 'ca-app-pub-3940256099942544/5575463023';

  static const String _appOpenAndroid = String.fromEnvironment(
    'ADMOB_APP_OPEN_AD_UNIT_ID_ANDROID',
    defaultValue: _testAppOpenAndroid,
  );
  static const String _appOpenIOS = String.fromEnvironment(
    'ADMOB_APP_OPEN_AD_UNIT_ID_IOS',
    defaultValue: _testAppOpenIOS,
  );

  static String get appOpenAdUnitId => Platform.isAndroid ? _appOpenAndroid : _appOpenIOS;

  /// True if this build is still using Google's public test IDs (i.e.
  /// secrets.properties wasn't passed via --dart-define-from-file, or
  /// its AdMob values were left as the example placeholders). Useful for
  /// a debug-only banner/log so it's obvious a build isn't ad-ready yet.
  static bool get isUsingTestAds => bannerAdUnitId == _testBannerAndroid || bannerAdUnitId == _testBannerIOS;
}
