import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../l10n/app_localizations.dart';
import '../services/ad_service.dart';

/// Real AdMob banner (standard 320x50), refreshed on a timer.
///
/// REFRESH INTERVAL
///
/// AdMob's custom refresh range is **30–150 seconds**. Anything faster is
/// not offered in the console and, done in code, is the textbook pattern
/// behind an "invalid traffic" serving limit — Google counts impressions
/// the rider had no chance to see. 30 seconds is therefore the floor, and
/// [_refreshInterval] is clamped to it rather than trusted.
///
/// IMPORTANT — pick ONE refresh mechanism. If automatic refresh is also
/// enabled for this ad unit in the AdMob console, the unit refreshes twice
/// per cycle: once server-side and once from this timer. That is worse than
/// either alone. Using this widget's timer means **turning automatic
/// refresh off** for the banner unit in the console.
///
/// The timer stops whenever the app is not in the foreground. A banner that
/// keeps cycling in the background bills impressions nobody saw, which is
/// the same invalid-traffic problem arriving by a quieter route.
class BannerAdPlaceholder extends StatefulWidget {
  const BannerAdPlaceholder({super.key});

  /// Requested refresh interval. Clamped to AdMob's 30-second minimum.
  static const Duration refreshInterval = Duration(seconds: 30);

  @override
  State<BannerAdPlaceholder> createState() => _BannerAdPlaceholderState();
}

class _BannerAdPlaceholderState extends State<BannerAdPlaceholder>
    with WidgetsBindingObserver {
  static const Duration _admobMinimumRefresh = Duration(seconds: 30);

  /// Breathing room above the ad. Several screens put a primary button
  /// directly above this slot (Sign in, Get started, Find routes), and
  /// AdMob names close proximity to interactive elements as "one of the
  /// biggest causes of accidental clicks" -- which is what gets an account
  /// flagged, not the placement itself.
  static const double _separationAbove = 8;

  Duration get _refreshInterval =>
      BannerAdPlaceholder.refreshInterval < _admobMinimumRefresh
          ? _admobMinimumRefresh
          : BannerAdPlaceholder.refreshInterval;

  BannerAd? _bannerAd;
  bool _isLoaded = false;
  bool _failed = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    final isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);
    if (isMobile) {
      WidgetsBinding.instance.addObserver(this);
      _loadAd(initial: true);
    } else {
      _failed = true;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _scheduleRefresh();
    } else {
      _refreshTimer?.cancel();
    }
  }

  void _scheduleRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer(_refreshInterval, _refreshAd);
  }

  void _loadAd({bool initial = false}) {
    final ad = BannerAd(
      adUnitId: AdService.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() {
            _bannerAd = ad as BannerAd;
            _isLoaded = true;
            _failed = false;
          });
          _scheduleRefresh();
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (!mounted) return;
          if (initial) setState(() => _failed = true);
          // A failed refresh keeps the ad already on screen and tries again
          // next cycle, rather than collapsing the slot and shifting the
          // layout under the rider's thumb.
          _scheduleRefresh();
        },
      ),
    );
    ad.load();
  }

  /// Loads a replacement before retiring the current one. Disposing the ad
  /// that an [AdWidget] is still rendering tears down the platform view
  /// underneath it, so the swap only happens once the new ad is ready.
  void _refreshAd() {
    if (!mounted) return;
    final BannerAd? outgoing = _bannerAd;

    final next = BannerAd(
      adUnitId: AdService.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() {
            _bannerAd = ad as BannerAd;
            _isLoaded = true;
          });
          outgoing?.dispose();
          _scheduleRefresh();
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _scheduleRefresh();
        },
      ),
    );
    next.load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);
    if (!isMobile || _failed) {
      // No ad to show and no point reserving space on desktop or for a broken one.
      return const SizedBox.shrink();
    }

    if (!_isLoaded || _bannerAd == null) {
      final l10n = AppLocalizations.of(context);
      return Container(
        width: double.infinity,
        height: 50,
        margin: const EdgeInsets.only(top: _separationAbove),
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.black12),
            bottom: BorderSide(color: Colors.black12),
          ),
        ),
        child: Text(
          l10n.adPlaceholderLabel,
          style: const TextStyle(color: Colors.black38, fontSize: 11, fontWeight: FontWeight.w500),
        ),
      );
    }

    return Container(
      width: double.infinity,
      height: _bannerAd!.size.height.toDouble(),
      margin: const EdgeInsets.only(top: _separationAbove),
      alignment: Alignment.center,
      color: Colors.white,
      child: SizedBox(
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      ),
    );
  }
}
