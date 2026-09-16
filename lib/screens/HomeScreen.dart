import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'LocationSearchScreen.dart';
import 'LocationPickerScreen.dart';
import 'SavedPlacesScreen.dart';
import 'CommuteBudgetScreen.dart';
import 'TripRecapScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/account_service.dart';
import '../services/trip_history_service.dart';
import '../services/transit_modes.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _currentLocationData;
  List<TripHistoryEntry> _recentTrips = [];
  AppLocalizations? _l10n;
  String? _userName;
  StreamSubscription<User?>? _userSub;

  @override
  void initState() {
    super.initState();
    _fetchCurrentLocationQuietly();
    _loadRecentTrips();
    _loadUserName();
    TripHistoryService.changeNotifier.addListener(_loadRecentTrips);
    try {
      _userSub = FirebaseAuth.instance.userChanges().listen((_) {
        _loadUserName();
      });
    } catch (_) {
      // Resilient fallback for testing or offline environments
    }
  }

  @override
  void dispose() {
    TripHistoryService.changeNotifier.removeListener(_loadRecentTrips);
    _userSub?.cancel();
    super.dispose();
  }

  Future<void> _loadUserName() async {
    final name = await AccountService.getUserFirstName();
    if (mounted && name != _userName) {
      setState(() => _userName = name);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _l10n = AppLocalizations.of(context);
    _loadRecentTrips();
  }

  Future<void> _loadRecentTrips() async {
    final trips = await TripHistoryService.getHistory();
    if (mounted) {
      setState(() => _recentTrips = trips);
    }
  }

  // Just resolves the person's current position to prefill the search
  // screen's start field. Uses Geolocator only (device GPS/OS location
  // services) -- no Google Maps API call is involved here, so this is free
  // regardless of Maps Platform billing.
  Future<void> _fetchCurrentLocationQuietly() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (mounted) {
        setState(() {
          _currentLocationData = {
            'name': _l10n?.myCurrentLocation ?? 'Current Location',
            'lat': position.latitude,
            'lon': position.longitude,
          };
        });
      }
    } catch (_) {
      // Silent -- the search screen falls back to asking for location itself.
    }
  }

  Future<void> _openSearchScreen() async {
    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => LocationSearchScreen(
          initialStartLocation: _currentLocationData,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.ease;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(position: animation.drive(tween), child: child);
        },
      ),
    );
    _loadRecentTrips();
  }

  // STANDARD TAP: Routes to the location
  Future<void> _handleQuickRoute(String key, String label) async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    String? savedData = prefs.getString(key);
    final l10n = AppLocalizations.of(context);

    if (savedData == null) {
      await Navigator.push(context, MaterialPageRoute(builder: (context) => LocationPickerScreen(saveKey: key)));
    } else {
      var parts = savedData.split('|');
      String name = parts[0];
      double lat = double.parse(parts[1]);
      double lon = double.parse(parts[2]);

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.routingTo(name))));

      try {
        Position position = await Geolocator.getCurrentPosition(
          locationSettings: LocationSettings(accuracy: LocationAccuracy.high),
        );
        if (mounted) {
          Navigator.push(context, MaterialPageRoute(
            builder: (context) => LocationSearchScreen(
              initialStartLocation: {'name': l10n.myCurrentLocation, 'lat': position.latitude, 'lon': position.longitude},
              initialEndLocation: {'name': name, 'lat': lat, 'lon': lon},
            ),
          ));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.gpsRequiredToRoute)));
        }
      }
    }
  }

  // LONG PRESS: Overwrites the saved location
  Future<void> _resetQuickRoute(String key, String displayLabel) async {
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.resettingLocation(displayLabel))));
    await Navigator.push(context, MaterialPageRoute(builder: (context) => LocationPickerScreen(saveKey: key)));
  }

  // Picks the right greeting for the current hour, personalized with the
  // user's name if signed in (e.g. via registration or Google Sign-In).
  String _greeting(AppLocalizations l10n) {
    return AccountService.formatGreeting(l10n, name: _userName);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: false,
            floating: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            toolbarHeight: 0,
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // HERO CARD -- subdued lower gold gradient with brand navy base
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: AppColors.heroCardGradient,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.directions_bus_filled_rounded, color: Colors.white, size: 26),
                          const SizedBox(width: 8),
                          const Text('Guidy', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _greeting(l10n),
                        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(l10n.appTagline, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // SEARCH BAR
                GestureDetector(
                  onTap: _openSearchScreen,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: context.surfaceCard,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: context.isDark ? 0.3 : 0.06), blurRadius: 12, offset: const Offset(0, 4))],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: AppColors.primaryTeal, size: 26),
                        const SizedBox(width: 14),
                        Text(l10n.whereTo, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: context.textPrimary)),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                Text(
                  l10n.quickDestinationsLabel.toUpperCase(),
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.textSecondary, letterSpacing: 0.6),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(child: _buildQuickAccessCard(context, Icons.home_rounded, "Home", l10n.quickAccessHome)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildQuickAccessCard(context, Icons.work_rounded, "Work", l10n.quickAccessWork)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          await Navigator.push(context, MaterialPageRoute(builder: (context) => const SavedPlacesScreen()));
                          _loadRecentTrips();
                        },
                        child: _quickAccessCardBody(context, Icons.bookmark_rounded, l10n.quickAccessSaved),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // COMMUTE BUDGET & METRO SUBSCRIPTION BANNER
                _buildBudgetCalculatorCard(context, l10n),

                const SizedBox(height: 24),

                // RECENT TRIPS SECTION (Replaces Saved Commutes)
                _buildRecentTripsSection(context, l10n),
              ]),
            ),
          ),
        ],
            ),
          ),
        ],
      ),
    );
  }

  // `storageKey` is the stable English key used for SharedPreferences /
  // routing lookups; `displayLabel` is the localized text shown on screen.
  Widget _buildQuickAccessCard(BuildContext context, IconData icon, String storageKey, String displayLabel) {
    return GestureDetector(
      onTap: () => _handleQuickRoute(storageKey, displayLabel),
      onLongPress: () => _resetQuickRoute(storageKey, displayLabel),
      child: _quickAccessCardBody(context, icon, displayLabel),
    );
  }

  Widget _quickAccessCardBody(BuildContext context, IconData icon, String displayLabel) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: context.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: context.isDark ? 0.3 : 0.05), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primaryTeal, size: 26),
          const SizedBox(height: 8),
          Text(
            displayLabel,
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: context.textPrimary),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetCalculatorCard(BuildContext context, AppLocalizations l10n) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CommuteBudgetScreen()),
        );
        _loadRecentTrips();
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: context.surfaceCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primaryTeal.withValues(alpha: 0.3), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: context.isDark ? 0.3 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.brandAmber.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.calculate_rounded, color: context.accentAmber, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.budgetTitle,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.budgetSubtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: context.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.primaryTeal),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTripsSection(BuildContext context, AppLocalizations l10n) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.history_rounded, size: 20, color: AppColors.primaryTeal),
                const SizedBox(width: 8),
                Text(
                  l10n.recentTripsTitle,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: context.textPrimary),
                ),
              ],
            ),
            if (_recentTrips.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryTeal.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_recentTrips.length}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryTeal),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          l10n.recentTripsSubtitle,
          style: TextStyle(fontSize: 12, color: context.textSecondary),
        ),
        const SizedBox(height: 12),
        if (_recentTrips.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.surfaceCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.directions_bus_outlined, color: AppColors.primaryTeal, size: 26),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    l10n.noRecentTripsYet,
                    style: TextStyle(fontSize: 12, color: context.textSecondary, height: 1.4),
                  ),
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: 146,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _recentTrips.length > 8 ? 8 : _recentTrips.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final trip = _recentTrips[index];
                return _buildRecentTripCard(context, l10n, trip, isArabic);
              },
            ),
          ),
      ],
    );
  }

  String _localizeLocation(String name, bool isArabic) {
    final trimmed = name.trim();
    final lower = trimmed.toLowerCase();
    if (lower == 'current location' || lower == 'my current location' ||
        trimmed == 'موقعي الحالي' || trimmed == 'الموقع الحالي') {
      return isArabic ? 'موقعي الحالي' : 'My Current Location';
    }
    if (lower == 'origin' || trimmed == 'نقطة الانطلاق' || trimmed == 'نقطة البداية') {
      return isArabic ? 'نقطة الانطلاق' : 'Origin';
    }
    if (lower == 'destination' || trimmed == 'الوجهة' || trimmed == 'نقطة الوصول') {
      return isArabic ? 'الوجهة' : 'Destination';
    }
    if (isArabic && lower.startsWith('station ')) {
      return 'محطة ${trimmed.substring(8)}';
    } else if (!isArabic && trimmed.startsWith('محطة ')) {
      return '${trimmed.substring(5)} Station';
    }
    return trimmed;
  }

  Widget _buildRecentTripCard(BuildContext cardContext, AppLocalizations l10n, TripHistoryEntry trip, bool isArabic) {
    final fareStr = '${trip.transitFareEgp} ${isArabic ? "ج.م" : "EGP"}';
    final durationStr = '${trip.transitDurationMin} ${isArabic ? "دقيقة" : "min"}';
    final primaryMode = trip.primaryMode ?? (trip.transitModes.isNotEmpty ? trip.transitModes.first : 'bus');

    return GestureDetector(
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => TripRecapScreen(
              option: trip.option ?? (trip.pathData['option'] is Map ? Map<String, dynamic>.from(trip.pathData['option']) : <String, dynamic>{}),
              pathData: trip.pathData,
              startName: _localizeLocation(trip.startName, isArabic),
              endName: _localizeLocation(trip.endName, isArabic),
            ),
          ),
        );
        _loadRecentTrips();
      },
      child: Container(
        width: 260,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardContext.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: cardContext.isDark ? 0.3 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(color: AppColors.primaryTeal.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: TransitModes.color(primaryMode).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(TransitModes.icon(primaryMode), size: 14, color: TransitModes.color(primaryMode)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    trip.routeNumber != null && trip.routeNumber!.isNotEmpty
                        ? '${TransitModes.label(l10n, primaryMode)} • ${trip.routeNumber}'
                        : TransitModes.label(l10n, primaryMode),
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: cardContext.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00B277).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    fareStr,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF00B277)),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${_localizeLocation(trip.startName, isArabic)} ➔ ${_localizeLocation(trip.endName, isArabic)}',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: cardContext.textPrimary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Icon(Icons.schedule_rounded, size: 13, color: cardContext.textSecondary),
                const SizedBox(width: 4),
                Text(
                  durationStr,
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: cardContext.textSecondary),
                ),
                if (trip.moneySavedEgp > 0) ...[
                  const SizedBox(width: 8),
                  Text('•', style: TextStyle(color: cardContext.textSecondary, fontSize: 10)),
                  const SizedBox(width: 8),
                  Text(
                    '+${trip.moneySavedEgp.toStringAsFixed(0)} ${isArabic ? "ج.م وفرت (أوفر)" : "EGP saved"}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF00B277)),
                  ),
                ] else if (trip.timeSavedMin > 0) ...[
                  const SizedBox(width: 8),
                  Text('•', style: TextStyle(color: cardContext.textSecondary, fontSize: 10)),
                  const SizedBox(width: 8),
                  Text(
                    '+${trip.timeSavedMin} ${isArabic ? "د وفرت (أسرع)" : "min saved"}',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: cardContext.accentAmber),
                  ),
                ],
                const Spacer(),
                const Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.primaryTeal),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
