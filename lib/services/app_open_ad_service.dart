import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_service.dart';

/// Shows a full-screen ad when a rider comes back to Guidy after being away
/// for a while.
///
/// WHY THIS IS AN APP OPEN AD AND NOT AN INTERSTITIAL
///
/// The obvious way to build "show an ad when they come back" is to fire an
/// interstitial on resume. AdMob explicitly forbids that:
///
///   "Do not place interstitial ads on app load and when exiting apps as
///    interstitials should only be placed in between pages of app content."
///
/// Interstitials are for logical breaks *inside* content — finishing a
/// flow, moving between pages. An ad that appears because the rider
/// unlocked their phone is not a break in content, it is an app open, and
/// Google publishes a separate format for exactly this case. Using the
/// wrong one risks the account, not just the placement.
///
/// WHY IT MEASURES BACKGROUND TIME, NOT SCREEN LOCK
///
/// An app cannot observe the phone's lock screen, and it does not run while
/// the screen is off. What it can observe is its own lifecycle: note the
/// time on the way out, compare on the way back. That covers a locked
/// screen, but also switching apps or taking a call — which is what you
/// actually want, since all three mean the rider left and returned.
class AppOpenAdService with WidgetsBindingObserver {
  AppOpenAdService._();
  static final AppOpenAdService instance = AppOpenAdService._();

  /// How long the rider must have been away before returning earns an ad.
  /// A short window here is the difference between a monetised return and
  /// an ad every time someone glances at a notification.
  static const Duration minimumTimeAway = Duration(minutes: 15);

  /// Google expires a cached app open ad after four hours; showing a stale
  /// one fails, so it is reloaded instead.
  static const Duration _adValidity = Duration(hours: 4);

  AppOpenAd? _ad;
  DateTime? _loadedAt;
  DateTime? _leftAt;
  bool _isShowing = false;
  bool _isLoading = false;
  bool _started = false;

  /// Called once from main(). Registers the lifecycle observer and warms
  /// the first ad. Nothing shows on this first launch — `_leftAt` is null
  /// until the rider actually leaves, so a cold start never triggers one.
  void initialize() {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ad?.dispose();
    _ad = null;
    _started = false;
  }

  bool get _isAdAvailable =>
      _ad != null && _loadedAt != null && DateTime.now().difference(_loadedAt!) < _adValidity;

  void _load() {
    if (_isLoading || _isAdAvailable) return;
    _isLoading = true;
    AppOpenAd.load(
      adUnitId: AdService.appOpenAdUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _ad = ad;
          _loadedAt = DateTime.now();
          _isLoading = false;
        },
        onAdFailedToLoad: (error) {
          // No fill and network failures are routine. Stay quiet and try
          // again the next time the rider leaves.
          debugPrint('App open ad failed to load: $error');
          _isLoading = false;
        },
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        // Showing the ad itself backgrounds the app. Without this guard the
        // clock would restart behind the ad and the next resume — dismissing
        // it — would look like another return.
        if (!_isShowing) _leftAt = DateTime.now();
      case AppLifecycleState.resumed:
        _maybeShowOnReturn();
      case AppLifecycleState.inactive:
        break;
    }
  }

  void _maybeShowOnReturn() {
    if (_isShowing) return;

    final left = _leftAt;
    if (left == null) return; // cold start, not a return
    final away = DateTime.now().difference(left);
    _leftAt = null;

    if (away < minimumTimeAway) {
      // Back too soon to monetise. Take the opportunity to top up the cache
      // so the next qualifying return has an ad ready.
      _load();
      return;
    }

    if (!_isAdAvailable) {
      _load();
      return;
    }

    final ad = _ad!;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) => _isShowing = true,
      onAdDismissedFullScreenContent: (ad) {
        _isShowing = false;
        ad.dispose();
        _ad = null;
        _loadedAt = null;
        _load();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('App open ad failed to show: $error');
        _isShowing = false;
        ad.dispose();
        _ad = null;
        _loadedAt = null;
        _load();
      },
    );
    _ad = null;
    ad.show();
  }
}
