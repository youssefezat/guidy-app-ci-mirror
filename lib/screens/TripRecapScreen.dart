import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'MapScreen.dart';
import 'RailNetworkMapScreen.dart';
import 'CommuteBudgetScreen.dart';
import '../l10n/app_localizations.dart';
import '../services/instruction_formatter.dart';
import '../services/metro_ticket_advisor.dart';
import '../services/transit_modes.dart';
import '../services/trip_sharing_service.dart';
import '../services/saved_trips_service.dart';
import '../services/trip_history_service.dart';
import '../widgets/quick_commute_report_sheet.dart';
import '../theme/app_theme.dart';
import '../widgets/banner_ad_placeholder.dart';

class TripRecapScreen extends StatefulWidget {
  final Map<String, dynamic> option;
  final Map<String, dynamic> pathData;
  final String startName;
  final String endName;

  const TripRecapScreen({
    super.key,
    required this.option,
    required this.pathData,
    required this.startName,
    required this.endName,
  });

  @override
  State<TripRecapScreen> createState() => _TripRecapScreenState();
}

class _TripRecapScreenState extends State<TripRecapScreen> {
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _initSavedStatusAndCache();
  }

  Future<void> _initSavedStatusAndCache() async {
    final saved = await SavedTripsService.isTripSaved(widget.startName, widget.endName);
    if (mounted) setState(() => _isSaved = saved);
    await SavedTripsService.cacheActiveTrip(
      startName: widget.startName,
      endName: widget.endName,
      pathData: widget.pathData,
      option: widget.option,
    );
  }

  Future<void> _toggleSaveTrip() async {
    HapticFeedback.mediumImpact();
    final l10n = AppLocalizations.of(context);
    if (_isSaved) {
      await SavedTripsService.removeTripByEndpoints(widget.startName, widget.endName);
      if (mounted) {
        setState(() => _isSaved = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.tripRemovedToast),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      await SavedTripsService.saveTrip(
        startName: widget.startName,
        endName: widget.endName,
        pathData: widget.pathData,
        option: widget.option,
      );
      if (mounted) {
        setState(() => _isSaved = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.tripSavedToast),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  IconData _stepIcon(String iconKey) => TransitModes.icon(iconKey);

  Color _stepColor(String iconKey) {
    switch (iconKey) {
      case 'walk':
        return const Color(0xFF2A9D8F);
      case 'transfer':
        return const Color(0xFFE76F51);
      case 'arrive':
        return const Color(0xFF264653);
      case 'bus':
        return const Color(0xFF457B9D);
      default:
        return TransitModes.color(iconKey);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final option = widget.option;
    final pathData = widget.pathData;
    final startName = widget.startName;
    final endName = widget.endName;
    final List<dynamic> instructions = option['instructions'] ?? [];
    final int? fareTotalEgp = option['fare_total_egp'] is int ? option['fare_total_egp'] : null;
    final bool hasFareBreakdown = instructions.any((i) => i['fare_egp'] != null);
    final bool hasMetro = instructions.any((i) => i['vehicle_type'] == 'metro');

    return Scaffold(
      bottomNavigationBar: const BannerAdPlaceholder(),
      appBar: AppBar(
        title: Text(l10n.tripRecapTitle, style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(_isSaved ? Icons.bookmark_rounded : Icons.bookmark_add_outlined),
            color: _isSaved ? AppColors.primaryTeal : null,
            tooltip: l10n.saveTripTooltip,
            onPressed: _toggleSaveTrip,
          ),
          IconButton(
            icon: const Icon(Icons.calculate_outlined),
            tooltip: l10n.budgetTitle,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CommuteBudgetScreen(
                    initialSingleFareEgp: fareTotalEgp ?? 12,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: l10n.shareTripTooltip,
            onPressed: () {
              TripSharingService.shareTrip(
                context: context,
                destinationName: widget.endName,
                transitMode: widget.option['vehicle_type'],
                durationMinutes: '${widget.option['time']}',
                lang: isAr ? 'ar' : 'en',
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.map_outlined),
            tooltip: l10n.railMapTitle,
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const RailNetworkMapScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.campaign_outlined),
            tooltip: l10n.quickReportTitle,
            onPressed: () => _openReport(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // --- Header: route + summary stats ---
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primaryTeal, AppColors.deepPetrol],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryTeal.withValues(alpha: 0.25),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Origin & Destination chain
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Color(0xFF34D399),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              startName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsetsDirectional.only(start: 4, top: 3, bottom: 3),
                        child: Container(
                          width: 2,
                          height: 14,
                          color: Colors.white38,
                        ),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Icon(Icons.place_rounded, size: 14, color: Color(0xFFF87171)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              endName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _headerStat(
                              Icons.access_time_rounded,
                              l10n.durationMinutes('${option['time']}'),
                              l10n.statDuration,
                            ),
                            Container(width: 1, height: 28, color: Colors.white24),
                            _headerStat(
                              Icons.payments_outlined,
                              InstructionFormatter.fareText(l10n, option),
                              l10n.statFare,
                            ),
                            if (option['distance_m'] != null) ...[
                              Container(width: 1, height: 28, color: Colors.white24),
                              _headerStat(
                                Icons.straighten_rounded,
                                l10n.distanceKm((option['distance_m'] / 1000).toStringAsFixed(1)),
                                l10n.statDistance,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                if (hasMetro) ...[
                  Builder(builder: (ctx) {
                    final metroStops = (option['metro_stops'] as int?) ?? 6;
                    final advice = MetroTicketAdvisor.calculate(stationCount: metroStops > 0 ? metroStops + 1 : 6);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: advice.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: advice.color.withValues(alpha: 0.35)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: advice.color, shape: BoxShape.circle),
                            child: const Icon(Icons.confirmation_number_outlined, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.metroTicketTitle,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: context.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  advice.adviceText(Localizations.localeOf(context).languageCode),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: context.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
                Text(
                  l10n.tripStepsLabel.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: context.textSecondary,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 14),

                // --- Connected vertical transit timeline ---
                ...instructions.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final step = entry.value as Map<String, dynamic>;
                  final prevStep = idx > 0 ? (instructions[idx - 1] as Map<String, dynamic>) : null;
                  final nextStep = idx < instructions.length - 1 ? (instructions[idx + 1] as Map<String, dynamic>) : null;

                  return _buildTimelineStep(
                    context: context,
                    l10n: l10n,
                    isAr: isAr,
                    index: idx,
                    totalSteps: instructions.length,
                    step: step,
                    nextStep: nextStep,
                    prevStep: prevStep,
                  );
                }),

                if (hasFareBreakdown) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.fieldFill,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(l10n.fareTotalLabel, style: TextStyle(fontWeight: FontWeight.bold, color: context.textPrimary)),
                        Text(
                          fareTotalEgp != null ? l10n.fareEgp('$fareTotalEgp') : InstructionFormatter.fareText(l10n, option),
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryTeal, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(l10n.fareEstimateNote, style: TextStyle(color: context.textSecondary, fontSize: 11), textAlign: TextAlign.center),
                const SizedBox(height: 12),

                // The feed is stitched from open data of uneven quality and
                // none of it is verified against what runs today. Riders are
                // the only people who know when a leg is wrong, so the way to
                // say so sits under the trip they are doubting rather than
                // buried in Settings.
                Center(
                  child: TextButton.icon(
                    onPressed: () => _openReport(context),
                    icon: Icon(Icons.flag_outlined, size: 16, color: context.textSecondary),
                    label: Text(
                      l10n.reportEntryPoint,
                      style: TextStyle(color: context.textSecondary, fontSize: 12.5),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),

          // --- Start navigation button ---
          Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
            decoration: BoxDecoration(
              color: context.surfaceCard,
              border: Border(
                top: BorderSide(
                  color: context.isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
                  width: 1,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: context.isDark ? 0.3 : 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  final mapData = Map<String, dynamic>.from(pathData);
                  mapData['option'] = widget.option;
                  if (widget.option['type'] != null) {
                    mapData['type'] = widget.option['type'];
                  }
                  TripHistoryService.recordTrip(
                    startName: widget.startName,
                    endName: widget.endName,
                    pathData: mapData,
                    option: widget.option,
                    chosenProfile: widget.option['type']?.toString(),
                    isCompleted: true,
                  );
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MapScreen(pathData: mapData)));
                },
                icon: const Icon(Icons.navigation_rounded, color: Colors.white, size: 20),
                label: Text(l10n.startNavigationButton, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openReport(BuildContext context) {
    QuickCommuteReportSheet.show(
      context,
      routeData: widget.pathData,
      steps: widget.option['instructions'] as List<dynamic>?,
    );
  }

  // Same idea as MapScreen's live boarding-options row, but shown ahead
  // of time (before the rider taps "start navigation") so it's clear
  // from the trip preview that this leg isn't a single fixed bus --
  // several routes cover the same corridor and any of them work. No
  // live GPS state to show yet at this point (the rider hasn't started
  // riding), so this is just the list of substitutable routes; a real
  // ETA only appears once they're on the live-tracked MapScreen.
  Widget _buildBoardingOptions(BuildContext context, Map<String, dynamic> step) {
    final l10n = AppLocalizations.of(context);
    final List options = step['boarding_options'] ?? [];
    if (options.length < 2) return const SizedBox.shrink();

    final labels = options.where((o) => o['is_primary'] != true).map((o) {
      // vehicle_type arrives as a raw backend token ('bus', 'microbus'),
      // not a display word -- printing it straight was how "Microbus 302"
      // stayed English on an Arabic screen.
      final base = InstructionFormatter.optionSummary(l10n, Map<String, dynamic>.from(o));
      // No live ETA to show before the trip even starts, but the
      // schedule-derived typical headway (see raptor_engine.py's
      // route_typical_headway_min) is still a useful "how often does
      // this actually run" hint at this stage.
      final headway = o['typical_headway_min'];
      if (base.isEmpty) return '';
      if (headway != null) {
        final h = InstructionFormatter.asNum(headway)?.round() ?? 0;
        return h > 0 ? l10n.routeEveryMinutes(base, '$h') : base;
      }
      return base;
    }).where((s) => s.isNotEmpty).toList();

    if (labels.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.swap_horiz_rounded, size: 14, color: context.textSecondary),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              l10n.alsoWorksLabel(labels.join(l10n.listSeparator)),
              style: TextStyle(color: context.textSecondary, fontSize: 11.5, fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerStat(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }

  Widget _buildTimelineStep({
    required BuildContext context,
    required AppLocalizations l10n,
    required bool isAr,
    required int index,
    required int totalSteps,
    required Map<String, dynamic> step,
    required Map<String, dynamic>? nextStep,
    required Map<String, dynamic>? prevStep,
  }) {
    final isFirst = index == 0;
    final isLast = index == totalSteps - 1;
    final action = (step['action'] ?? '').toString();
    final iconKey = InstructionFormatter.iconKey(step);
    final color = _stepColor(iconKey);
    final isWalk = action.contains('walk');
    final isArrive = action == 'arrive';
    final fare = step['fare_egp'];
    final station = step['station']?.toString();
    final waitMin = step['wait_min'];
    final dist = InstructionFormatter.asNum(step['distance_m'])?.round();
    final isDark = context.isDark;

    // Top connector line
    Color topColor = Colors.grey.withValues(alpha: isDark ? 0.35 : 0.4);
    bool topDashed = true;
    if (prevStep != null) {
      final prevIconKey = InstructionFormatter.iconKey(prevStep);
      final prevAction = (prevStep['action'] ?? '').toString();
      if (!prevAction.contains('walk') && prevAction != 'arrive') {
        topColor = _stepColor(prevIconKey);
        topDashed = false;
      }
    }

    // Bottom connector line
    Color bottomColor = Colors.grey.withValues(alpha: isDark ? 0.35 : 0.4);
    bool bottomDashed = true;
    if (!isWalk && !isArrive) {
      bottomColor = color;
      bottomDashed = false;
    }

    // Node widget
    Widget nodeWidget;
    if (isFirst && isWalk) {
      nodeWidget = Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: AppColors.primaryTeal.withValues(alpha: isDark ? 0.2 : 0.12),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.primaryTeal, width: 2.5),
        ),
        child: Center(
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.primaryTeal,
              shape: BoxShape.circle,
            ),
          ),
        ),
      );
    } else if (isArrive || isLast) {
      nodeWidget = Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: const Color(0xFFE63946).withValues(alpha: isDark ? 0.25 : 0.12),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE63946), width: 2.5),
        ),
        child: const Center(
          child: Icon(Icons.place_rounded, size: 16, color: Color(0xFFE63946)),
        ),
      );
    } else if (!isWalk) {
      nodeWidget = Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.35),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Icon(_stepIcon(iconKey), size: 18, color: Colors.white),
        ),
      );
    } else {
      nodeWidget = Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: context.surfaceCard,
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.grey.withValues(alpha: isDark ? 0.5 : 0.4),
            width: 2,
          ),
        ),
        child: Center(
          child: Icon(
            Icons.directions_walk_rounded,
            size: 13,
            color: context.textSecondary,
          ),
        ),
      );
    }

    final title = InstructionFormatter.title(l10n, step);
    final subtitle = InstructionFormatter.subtitle(l10n, step);

    final card = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: context.textPrimary,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: isWalk ? context.textSecondary : color,
                          fontSize: 12.5,
                          fontWeight: isWalk ? FontWeight.normal : FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (fare != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: AppColors.primaryTeal.withValues(alpha: isDark ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    l10n.fareEgp('$fare'),
                    style: const TextStyle(
                      color: AppColors.primaryTeal,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ] else if (isWalk && dist != null && dist > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.directions_walk_rounded, size: 11, color: context.textSecondary),
                      const SizedBox(width: 3),
                      Text(
                        l10n.walkMetersBadge(dist.toString()),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: context.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          if (station != null && station.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 14, color: AppColors.primaryTeal),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    station,
                    style: TextStyle(
                      color: context.textPrimary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (waitMin != null && (InstructionFormatter.asNum(waitMin) ?? 0) > 0) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.hourglass_empty_rounded, size: 12, color: context.textSecondary),
                const SizedBox(width: 4),
                Text(
                  isAr ? 'حوالي $waitMin دقيقة انتظار' : '~$waitMin min wait',
                  style: TextStyle(color: context.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ],
          _buildBoardingOptions(context, step),
        ],
      ),
    );

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 38,
            child: Column(
              children: [
                if (!isFirst)
                  CustomPaint(
                    size: const Size(38, 12),
                    painter: _TimelineConnectorPainter(
                      color: topColor,
                      isDashed: topDashed,
                      strokeWidth: topDashed ? 2.2 : 3.5,
                    ),
                  )
                else
                  const SizedBox(height: 6),
                nodeWidget,
                if (!isLast)
                  Expanded(
                    child: CustomPaint(
                      size: const Size(38, double.infinity),
                      painter: _TimelineConnectorPainter(
                        color: bottomColor,
                        isDashed: bottomDashed,
                        strokeWidth: bottomDashed ? 2.2 : 3.5,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: card,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineConnectorPainter extends CustomPainter {
  final Color color;
  final bool isDashed;
  final double strokeWidth;

  _TimelineConnectorPainter({
    required this.color,
    this.isDashed = false,
    this.strokeWidth = 3.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final x = size.width / 2;
    if (!isDashed) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      return;
    }

    const dashHeight = 4.0;
    const dashSpace = 4.0;
    double startY = 0.0;
    while (startY < size.height) {
      final endY = (startY + dashHeight).clamp(0.0, size.height);
      canvas.drawLine(Offset(x, startY), Offset(x, endY), paint);
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _TimelineConnectorPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.isDashed != isDashed ||
      oldDelegate.strokeWidth != strokeWidth;
}
