import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/trip_history_service.dart';
import '../services/transit_modes.dart';
import '../theme/app_theme.dart';
import 'LocationSearchScreen.dart';
import 'MapScreen.dart';
import 'TripRecapScreen.dart';

/// Screen displaying user commute history, calculated savings in money and time
/// compared to Cairo taxi/ride-hailing, avoided CO2 emissions, and repeatable routes.
class HistoryScreen extends StatefulWidget {
  final VoidCallback? onGoHome;
  const HistoryScreen({super.key, this.onGoHome});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<TripHistoryEntry> _allTrips = [];
  bool _isLoading = true;
  String _timeFilter = 'all'; // 'all', 'this_week', 'this_month'
  String? _modeFilter; // null, 'metro', 'bus', 'microbus'

  @override
  void initState() {
    super.initState();
    _loadHistory();
    TripHistoryService.changeNotifier.addListener(_loadHistory);
  }

  @override
  void dispose() {
    TripHistoryService.changeNotifier.removeListener(_loadHistory);
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final trips = await TripHistoryService.getHistory();
    if (mounted) {
      setState(() {
        _allTrips = trips;
        _isLoading = false;
      });
    }
  }

  List<TripHistoryEntry> get _filteredTrips {
    final now = DateTime.now();
    return _allTrips.where((trip) {
      // Time filter
      if (_timeFilter == 'this_week') {
        final diff = now.difference(trip.timestamp);
        if (diff.inDays > 7) return false;
      } else if (_timeFilter == 'this_month') {
        final diff = now.difference(trip.timestamp);
        if (diff.inDays > 30) return false;
      }

      // Mode filter
      if (_modeFilter != null) {
        final match = trip.transitModes.any((m) => m.toLowerCase().contains(_modeFilter!)) ||
            (trip.primaryMode != null && trip.primaryMode!.toLowerCase().contains(_modeFilter!));
        if (!match) return false;
      }

      return true;
    }).toList();
  }

  Future<void> _confirmClearHistory() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.clearHistoryAction),
        content: Text(l10n.clearHistoryConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: Text(l10n.clearHistoryAction, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await TripHistoryService.clearHistory();
      await _loadHistory();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.clearHistorySuccess),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showSavingsInfoDialog() {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: context.surfaceCard,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryTeal.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.savings_rounded, color: AppColors.primaryTeal, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.savingsCalculationInfoTitle,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: context.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                l10n.savingsCalculationInfo,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: context.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTeal,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    MaterialLocalizations.of(context).okButtonLabel,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openTrip(TripHistoryEntry trip) {
    if (trip.pathData.isNotEmpty && trip.option != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TripRecapScreen(
            option: trip.option!,
            pathData: trip.pathData,
            startName: trip.startName,
            endName: trip.endName,
          ),
        ),
      );
    } else if (trip.pathData.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MapScreen(pathData: trip.pathData),
        ),
      );
    } else {
      // Re-plan trip with endpoints
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LocationSearchScreen(
            initialStartLocation: trip.startLat != null && trip.startLon != null
                ? {'name': trip.startName, 'lat': trip.startLat!, 'lon': trip.startLon!}
                : null,
          ),
        ),
      );
    }
  }

  Future<void> _deleteTrip(TripHistoryEntry trip) async {
    final l10n = AppLocalizations.of(context);
    final removed = await TripHistoryService.deleteTrip(trip.id);
    if (removed) {
      setState(() {
        _allTrips.removeWhere((t) => t.id == trip.id);
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.tripDeletedToast),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  String _formatTimeSaved(AppLocalizations l10n, int minutes) {
    if (minutes < 60) {
      return l10n.minsSavedShort('$minutes');
    }
    final hours = minutes ~/ 60;
    final remainingMins = minutes % 60;
    if (remainingMins == 0) {
      return '$hours h';
    }
    return l10n.hoursMinsSavedShort('$hours', '$remainingMins');
  }

  String _formatDate(DateTime dt, bool isArabic) {
    final now = DateTime.now();
    final difference = now.difference(dt);

    if (difference.inDays == 0 && now.day == dt.day) {
      final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final period = dt.hour >= 12 ? (isArabic ? 'م' : 'PM') : (isArabic ? 'ص' : 'AM');
      final minute = dt.minute.toString().padLeft(2, '0');
      return isArabic ? 'اليوم، $hour:$minute $period' : 'Today, $hour:$minute $period';
    } else if (difference.inDays == 1 || (difference.inDays == 0 && now.day != dt.day)) {
      return isArabic ? 'أمس' : 'Yesterday';
    } else if (difference.inDays < 7) {
      return isArabic ? 'منذ ${difference.inDays} أيام' : '${difference.inDays} days ago';
    } else {
      return '${dt.day}/${dt.month}/${dt.year}';
    }
  }

  String _localizedLocation(String name, bool isArabic) {
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final filtered = _filteredTrips;
    final stats = TripHistoryService.getStats(_allTrips);

    return Scaffold(
      appBar: AppBar(
        leading: (Navigator.canPop(context) || widget.onGoHome != null)
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    widget.onGoHome?.call();
                  }
                },
              )
            : null,
        title: Text(
          l10n.historyTitle,
          style: TextStyle(
            color: context.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            tooltip: l10n.savingsCalculationInfoTitle,
            onPressed: _showSavingsInfoDialog,
          ),
          if (_allTrips.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: l10n.clearHistoryAction,
              onPressed: _confirmClearHistory,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadHistory,
              color: AppColors.primaryTeal,
              child: _allTrips.isEmpty
                  ? _buildEmptyState(l10n, isArabic)
                  : ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 30),
                      children: [
                        // --- Top Savings Pills ---
                        _buildTopSavingsPills(context, l10n, stats, isArabic),

                        const SizedBox(height: 8),

                        // --- Filter Chips ---
                        _buildFilterRow(l10n),

                        const SizedBox(height: 12),

                        // --- Trip List Header ---
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  '${l10n.navHistory} (${filtered.length})',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: context.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // --- Trip Cards ---
                        if (filtered.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(40.0),
                            child: Center(
                              child: Text(
                                l10n.linesNoResults,
                                style: TextStyle(color: context.textSecondary),
                              ),
                            ),
                          )
                        else
                          ...filtered.map((trip) => _buildTripCard(context, l10n, trip, isArabic)),
                      ],
                    ),
            ),
    );
  }

  Widget _buildTopSavingsPills(
    BuildContext context,
    AppLocalizations l10n,
    TripHistoryStats stats,
    bool isArabic,
  ) {
    final isDark = context.isDark;
    final moneySavedStr = stats.totalMoneySavedEgp.toStringAsFixed(0);
    final timeSavedMin = stats.totalTimeSavedMinutes;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Money Saved Pill
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF00B277).withValues(alpha: isDark ? 0.18 : 0.10),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0xFF00B277).withValues(alpha: isDark ? 0.40 : 0.25),
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00B277).withValues(alpha: 0.20),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.savings_rounded,
                      color: Color(0xFF00B277),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isArabic ? 'وفّرت فلوس' : 'Money Saved',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: context.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(
                            l10n.moneySavedPill(moneySavedStr),
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF00B277),
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Time Saved Pill
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.brandAmber.withValues(alpha: isDark ? 0.18 : 0.10),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.brandAmber.withValues(alpha: isDark ? 0.40 : 0.25),
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.brandAmber.withValues(alpha: 0.20),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.bolt_rounded,
                      color: AppColors.brandAmber,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isArabic ? 'وفّرت وقت' : 'Time Saved',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: context.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(
                            _formatTimeSaved(l10n, timeSavedMin),
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w900,
                              color: context.accentAmber,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow(AppLocalizations l10n) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Time filters
          ChoiceChip(
            label: Text(l10n.filterAll),
            selected: _timeFilter == 'all' && _modeFilter == null,
            onSelected: (_) {
              setState(() {
                _timeFilter = 'all';
                _modeFilter = null;
              });
            },
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: Text(l10n.filterThisWeek),
            selected: _timeFilter == 'this_week',
            onSelected: (selected) {
              setState(() => _timeFilter = selected ? 'this_week' : 'all');
            },
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: Text(l10n.filterThisMonth),
            selected: _timeFilter == 'this_month',
            onSelected: (selected) {
              setState(() => _timeFilter = selected ? 'this_month' : 'all');
            },
          ),
          const SizedBox(width: 12),
          Container(height: 20, width: 1, color: context.textSecondary.withValues(alpha: 0.3)),
          const SizedBox(width: 12),
          // Mode filters
          FilterChip(
            avatar: const Icon(Icons.subway_outlined, size: 16),
            label: Text(l10n.filterMetro),
            selected: _modeFilter == 'metro',
            onSelected: (selected) {
              setState(() => _modeFilter = selected ? 'metro' : null);
            },
          ),
          const SizedBox(width: 8),
          FilterChip(
            avatar: const Icon(Icons.directions_bus_outlined, size: 16),
            label: Text(l10n.filterBus),
            selected: _modeFilter == 'bus',
            onSelected: (selected) {
              setState(() => _modeFilter = selected ? 'bus' : null);
            },
          ),
          const SizedBox(width: 8),
          FilterChip(
            avatar: const Icon(Icons.airport_shuttle_outlined, size: 16),
            label: Text(l10n.filterMicrobus),
            selected: _modeFilter == 'microbus',
            onSelected: (selected) {
              setState(() => _modeFilter = selected ? 'microbus' : null);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTripCard(
    BuildContext context,
    AppLocalizations l10n,
    TripHistoryEntry trip,
    bool isArabic,
  ) {
    final isDark = context.isDark;
    final primaryMode = trip.primaryMode ?? (trip.transitModes.isNotEmpty ? trip.transitModes.first : 'bus');
    final primaryColor = TransitModes.color(primaryMode);

    final profile = trip.chosenProfile.toLowerCase();
    final isFastest = profile.contains('fastest') || profile.contains('أسرع') || profile.contains('fast');
    final isCheapest = profile.contains('cheapest') || profile.contains('أوفر') || profile.contains('ارخص') || profile.contains('cheap');
    final isCustomized = profile.contains('custom') || profile.contains('تفصيل') || profile.contains('فصّل');

    final distanceKm = (trip.transitDistanceMeters / 1000).toStringAsFixed(1);
    final fareStr = '${trip.transitFareEgp} ${isArabic ? "ج.م" : "EGP"}';
    final durationStr = '${trip.transitDurationMin} ${isArabic ? "دقيقة" : "min"}';

    return Dismissible(
      key: Key(trip.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: AlignmentDirectional.centerEnd,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        color: Colors.redAccent,
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 28),
      ),
      onDismissed: (_) => _deleteTrip(trip),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: isDark ? 0 : 2,
        color: context.surfaceCard,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _openTrip(trip),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Date/Time + Profile / Mode Badges
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              _formatDate(trip.timestamp, isArabic),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: context.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Choice Tag
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: isFastest
                                  ? AppColors.brandAmber.withValues(alpha: isDark ? 0.25 : 0.15)
                                  : isCheapest
                                      ? const Color(0xFF00B277).withValues(alpha: isDark ? 0.25 : 0.15)
                                      : isCustomized
                                          ? AppColors.transitBlue.withValues(alpha: isDark ? 0.25 : 0.15)
                                          : Colors.blueGrey.withValues(alpha: isDark ? 0.25 : 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isFastest
                                  ? (isArabic ? '⚡ أسرع' : '⚡ Fastest')
                                  : isCheapest
                                      ? (isArabic ? '💰 أوفر' : '💰 Cheapest')
                                      : isCustomized
                                          ? (isArabic ? '🛠️ سكة مفصّلة' : '🛠️ Customized')
                                          : (isArabic ? '🔄 سكة بديلة' : '🔄 Alternative'),
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: isFastest
                                    ? context.accentAmber
                                    : isCheapest
                                        ? const Color(0xFF00B277)
                                        : isCustomized
                                            ? AppColors.transitBlue
                                            : context.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: isDark ? 0.25 : 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(TransitModes.icon(primaryMode), size: 14, color: primaryColor),
                          if (trip.routeNumber != null && trip.routeNumber!.isNotEmpty) ...[
                            const SizedBox(width: 4),
                            Text(
                              trip.routeNumber!,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Corridor: Start ➔ End
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 3.0),
                      child: Column(
                        children: [
                          const Icon(Icons.circle, size: 10, color: Color(0xFF00B277)),
                          Container(width: 2, height: 26, color: context.textSecondary.withValues(alpha: 0.3)),
                          const Icon(Icons.location_on, size: 14, color: Colors.redAccent),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _localizedLocation(trip.startName, isArabic),
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                              color: context.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 14),
                          Text(
                            _localizedLocation(trip.endName, isArabic),
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                              color: context.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Extensive Details Container
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? const Color(0xFF243242) : Colors.black12,
                      width: 0.8,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          // Duration
                          Expanded(
                            child: Row(
                              children: [
                                Icon(Icons.schedule_rounded, size: 14, color: context.textSecondary),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isArabic ? 'المدة' : 'Duration',
                                        style: TextStyle(fontSize: 10, color: context.textSecondary),
                                      ),
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: AlignmentDirectional.centerStart,
                                        child: Text(
                                          durationStr,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: context.textPrimary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Distance
                          Expanded(
                            child: Row(
                              children: [
                                Icon(Icons.straighten_rounded, size: 14, color: context.textSecondary),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isArabic ? 'المسافة' : 'Distance',
                                        style: TextStyle(fontSize: 10, color: context.textSecondary),
                                      ),
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: AlignmentDirectional.centerStart,
                                        child: Text(
                                          '$distanceKm ${isArabic ? "كم" : "km"}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: context.textPrimary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Fare Paid
                          Expanded(
                            child: Row(
                              children: [
                                Icon(Icons.confirmation_number_outlined, size: 14, color: const Color(0xFF00B277)),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l10n.tripDetailFarePaid,
                                        style: TextStyle(fontSize: 10, color: context.textSecondary),
                                      ),
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: AlignmentDirectional.centerStart,
                                        child: Text(
                                          fareStr,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF00B277),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      if (trip.moneySavedEgp > 0 || trip.timeSavedMin > 0) ...[
                        const SizedBox(height: 10),
                        const Divider(height: 1),
                        const SizedBox(height: 10),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isNarrow = constraints.maxWidth < 240;
                            final moneyBadge = trip.moneySavedEgp > 0
                                ? Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF00B277).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.savings_rounded, size: 13, color: Color(0xFF00B277)),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            '+${trip.moneySavedEgp.toStringAsFixed(0)} ${isArabic ? "ج.م وفرت (باختيار الأوفر)" : "EGP saved (Cheapest)"}',
                                            style: const TextStyle(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF00B277),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : null;

                            final timeBadge = trip.timeSavedMin > 0
                                ? Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.brandAmber.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.bolt_rounded, size: 13, color: AppColors.brandAmber),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            '+${trip.timeSavedMin} ${isArabic ? "دقيقة وفرت (باختيار الأسرع)" : "min saved (Fastest)"}',
                                            style: TextStyle(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.bold,
                                              color: context.accentAmber,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : null;

                            if (moneyBadge != null && timeBadge != null) {
                              if (isNarrow) {
                                return Column(
                                  children: [
                                    SizedBox(width: double.infinity, child: moneyBadge),
                                    const SizedBox(height: 6),
                                    SizedBox(width: double.infinity, child: timeBadge),
                                  ],
                                );
                              }
                              return Row(
                                children: [
                                  Expanded(child: moneyBadge),
                                  const SizedBox(width: 6),
                                  Expanded(child: timeBadge),
                                ],
                              );
                            }
                            return moneyBadge ?? timeBadge ?? const SizedBox.shrink();
                          },
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Bottom Row: Mode chips & "View Trip Details"
                if (trip.transitModes.isNotEmpty) ...[
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: trip.transitModes.map((m) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: TransitModes.color(m).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(TransitModes.icon(m), size: 11, color: TransitModes.color(m)),
                            const SizedBox(width: 3),
                            Text(
                              TransitModes.label(l10n, m),
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                                color: TransitModes.color(m),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                ],
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.tripDetailOpenRecap,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryTeal,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Icon(
                        isArabic ? Icons.arrow_back_ios_rounded : Icons.arrow_forward_ios_rounded,
                        size: 11,
                        color: AppColors.primaryTeal,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n, bool isArabic) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primaryTeal.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.directions_transit_filled_rounded,
                size: 64,
                color: AppColors.primaryTeal,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.emptyHistoryTitle,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: context.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.emptyHistorySubtitle,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: context.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LocationSearchScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.explore_outlined, color: Colors.white),
                label: Text(
                  l10n.planTripButton,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
