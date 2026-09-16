import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../services/api_service.dart';
import 'TripRecapScreen.dart';
import '../l10n/app_localizations.dart';
import '../services/locale_controller.dart';
import '../services/instruction_formatter.dart';
import '../services/transit_modes.dart';
import '../services/analytics_service.dart';
import '../theme/app_theme.dart';
import '../widgets/banner_ad_placeholder.dart';
import '../widgets/error_state.dart';
import '../services/route_report_service.dart';

class RouteOptionsScreen extends StatefulWidget {
  final double startLat;
  final double startLon;
  final String startName;  
  final double endLat;
  final double endLon;
  final String endName;
  final Map<String, dynamic>? initialData;
  
  const RouteOptionsScreen({
    super.key, 
    required this.startLat, 
    required this.startLon,
    required this.startName, 
    required this.endLat, 
    required this.endLon,
    required this.endName,
    this.initialData,
  });

  @override
  State<RouteOptionsScreen> createState() => _RouteOptionsScreenState();
}

class _RouteOptionsScreenState extends State<RouteOptionsScreen> {
  final ApiService _apiService = ApiService();
  late Future<Map<String, dynamic>> _optionsFuture;
  bool _excludeMetro = false;
  bool _minWalk = false;
  bool _minTransfers = false;
  bool _showComparison = false;
  String? _customSelectedVehicle;
  String? _customSelectedLineKey;
  String? _customCustomRouteNumber;
  final TextEditingController _customRouteController = TextEditingController();

  num? _asNum(dynamic val) => InstructionFormatter.asNum(val);

  @override
  void initState() {
    super.initState();
    _optionsFuture = widget.initialData != null
        ? Future.value(widget.initialData!)
        : _fetchOptions();
  }

  @override
  void dispose() {
    _customRouteController.dispose();
    super.dispose();
  }

  void _retry() {
    setState(() => _optionsFuture = _fetchOptions());
  }

  void _toggleExcludeMetro(bool value) {
    setState(() {
      _excludeMetro = value;
      _optionsFuture = _fetchOptions();
    });
  }

  void _toggleMinWalk(bool value) {
    setState(() {
      _minWalk = value;
      _optionsFuture = _fetchOptions();
    });
  }

  void _toggleMinTransfers(bool value) {
    setState(() {
      _minTransfers = value;
      _optionsFuture = _fetchOptions();
    });
  }

  /// Lets a rider describe a route the engine doesn't have.
  ///
  /// This is the only channel that produces data about coverage HOLES.
  /// Every other report describes a route we already know; a hole leaves
  /// no itinerary to attach a complaint to, so without this the riders
  /// best placed to tell us what is missing -- the ones who just watched
  /// the app fail -- have no way to.
  Future<void> _reportMissingRoute({
    String? failureCode,
    int? uncoveredM,
    String? lastCoveredStop,
  }) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final controller = TextEditingController();

    final text = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.reportMissingRouteTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.reportMissingRouteIntro,
                style: TextStyle(fontSize: 13, color: dialogContext.textSecondary)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 3,
              maxLength: RouteReportService.maxCommentLength,
              decoration: InputDecoration(
                hintText: l10n.reportMissingRouteHint,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancelButton),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: Text(l10n.reportSubmit),
          ),
        ],
      ),
    );

    controller.dispose();
    if (text == null) return;
    if (text.trim().isEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.reportCommentRequired)));
      return;
    }

    final outcome = await RouteReportService.submitMissingRoute(
      startLat: widget.startLat,
      startLon: widget.startLon,
      endLat: widget.endLat,
      endLon: widget.endLon,
      startName: widget.startName,
      endName: widget.endName,
      comment: text,
      locale: localeController.isArabic ? 'ar' : 'en',
      failureCode: failureCode,
      uncoveredM: uncoveredM,
      lastCoveredStop: lastCoveredStop,
    );

    if (!mounted) return;
    messenger.showSnackBar(SnackBar(content: Text(switch (outcome) {
      RouteReportOutcome.sent => l10n.reportSent,
      RouteReportOutcome.queuedOffline => l10n.reportQueued,
      RouteReportOutcome.notSignedIn => l10n.reportSignInRequired,
      RouteReportOutcome.failed => l10n.reportFailed,
    })));
  }

  Future<Map<String, dynamic>> _fetchOptions() async {
    try {
      final data = await _apiService.fetchRoute(
        widget.startLat, 
        widget.startLon, 
        widget.endLat, 
        widget.endLon,
        lang: localeController.isArabic ? 'ar' : 'en',
        excludeMetro: _excludeMetro,
        minWalk: _minWalk,
        minTransfers: _minTransfers,
      );
      AnalyticsService.logRouteCalculated(success: data['success'] != false);
      return data;
    } catch (e) {
      AnalyticsService.logRouteCalculated(success: false);
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      bottomNavigationBar: const BannerAdPlaceholder(),
      backgroundColor: context.surfaceCard,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.routeOptionsTitle, style: TextStyle(color: context.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
            Text(l10n.tripRouteHeading(widget.startName, widget.endName), style: TextStyle(color: context.textSecondary, fontSize: 12)),
          ],
        ),
        backgroundColor: context.surfaceCard,
        iconTheme: IconThemeData(color: context.textPrimary),
        elevation: 0,
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                FilterChip(
                  label: Text(
                    l10n.excludeMetro,
                    style: TextStyle(
                      fontSize: 12,
                      color: _excludeMetro ? AppColors.primaryTeal : context.textPrimary,
                    ),
                  ),
                  selected: _excludeMetro,
                  selectedColor: AppColors.primaryTeal.withValues(alpha: 0.15),
                  checkmarkColor: AppColors.primaryTeal,
                  avatar: Icon(
                    Icons.subway_rounded,
                    size: 16,
                    color: _excludeMetro ? AppColors.primaryTeal : context.textSecondary,
                  ),
                  onSelected: _toggleExcludeMetro,
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: Text(
                    l10n.filterMinWalk,
                    style: TextStyle(
                      fontSize: 12,
                      color: _minWalk ? AppColors.primaryTeal : context.textPrimary,
                    ),
                  ),
                  selected: _minWalk,
                  selectedColor: AppColors.primaryTeal.withValues(alpha: 0.15),
                  checkmarkColor: AppColors.primaryTeal,
                  avatar: Icon(
                    Icons.directions_walk,
                    size: 16,
                    color: _minWalk ? AppColors.primaryTeal : context.textSecondary,
                  ),
                  onSelected: _toggleMinWalk,
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: Text(
                    l10n.filterMinTransfers,
                    style: TextStyle(
                      fontSize: 12,
                      color: _minTransfers ? AppColors.primaryTeal : context.textPrimary,
                    ),
                  ),
                  selected: _minTransfers,
                  selectedColor: AppColors.primaryTeal.withValues(alpha: 0.15),
                  checkmarkColor: AppColors.primaryTeal,
                  avatar: Icon(
                    Icons.swap_calls,
                    size: 16,
                    color: _minTransfers ? AppColors.primaryTeal : context.textSecondary,
                  ),
                  onSelected: _toggleMinTransfers,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<bool>(
                segments: [
                  ButtonSegment<bool>(
                    value: false,
                    icon: const Icon(Icons.format_list_bulleted_rounded, size: 16),
                    label: Text(l10n.viewModeList, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                  ButtonSegment<bool>(
                    value: true,
                    icon: const Icon(Icons.compare_arrows_rounded, size: 16),
                    label: Text(l10n.viewModeCompare, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ],
                selected: {_showComparison},
                onSelectionChanged: (Set<bool> selected) {
                  setState(() => _showComparison = selected.first);
                },
                style: const ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<Map<String, dynamic>>(
        future: _optionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primaryTeal));
          } else if (snapshot.hasError || snapshot.data!['success'] == false) {
            final String errorMsg = snapshot.hasError
                ? l10n.serverUnreachable
                : InstructionFormatter.errorMessage(l10n, snapshot.data!);

            return ErrorState(
              message: errorMsg,
              onRetry: _retry,
              nearestHubs: snapshot.data?['nearest_hubs'] as Map<String, dynamic>?,
              onReportMissing: () => _reportMissingRoute(
                failureCode: snapshot.data?['error_code'] as String?,
              ),
            );
          }

          final data = snapshot.data!;
          final List rawOptions = data['options'] ?? [];
          // Exclude Alternative route card as it is replaced by the interactive route customizer
          final List options = rawOptions.where((o) => (o as Map)['type'] != 'Alternative').toList();
          final List partialMatches =
              options.where((o) => (o as Map)['partial'] == true).toList();
          final Map<String, dynamic>? partial = partialMatches.isEmpty
              ? null
              : Map<String, dynamic>.from(partialMatches.first as Map);

          if (_showComparison) {
            return _buildComparisonMatrixView(
              context: context,
              l10n: l10n,
              data: data,
              options: options,
              partial: partial,
            );
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(l10n.availableRoutes, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: context.textPrimary)),
              const SizedBox(height: 12),

              // Single route disclaimer if this is genuinely the only known transit route
              if (data['is_only_route'] == true || options.where((o) => (o as Map)['type'] != 'Walk').length == 1) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.blueGrey.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.primaryTeal),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          l10n.onlyRouteDisclaimer,
                          style: TextStyle(fontSize: 12, color: context.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // A partial option must never be able to read as a complete
              // one. The card below it looks like every other route card,
              // so the fact that it stops short is stated here, above it,
              // in the rider's own units -- not left to be inferred from a
              // suspiciously long final walking step.
              if (partial != null) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline_rounded, size: 18, color: Colors.orange),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n.partialUncoveredNotice(
                                l10n.distanceKm((((_asNum(partial['uncovered_m']) ?? 0) / 1000).toStringAsFixed(1))),
                              ),
                              style: TextStyle(fontSize: 13, color: context.textPrimary),
                            ),
                          ),
                        ],
                      ),
                      if (partial['last_covered_stop'] != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          l10n.partialLastCoveredStop(partial['last_covered_stop'].toString()),
                          style: TextStyle(fontSize: 12, color: context.textSecondary),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: TextButton.icon(
                          onPressed: () => _reportMissingRoute(
                            failureCode: 'partial',
                            uncoveredM: _asNum(partial['uncovered_m'])?.round(),
                            lastCoveredStop: partial['last_covered_stop']?.toString(),
                          ),
                          icon: const Icon(Icons.add_road_rounded, size: 18),
                          label: Text(l10n.reportMissingRouteButton),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primaryTeal,
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
              ],
              
              ...options.map((option) {
                String vehicleType = option['vehicle_type'] ?? 'bus';

                // Was an inline switch that returned a bus icon for
                // anything it didn't list, so a monorail option would have
                // been drawn as a bus with no error raised anywhere.
                final IconData transportIcon = TransitModes.icon(vehicleType);
                final Color cardColor = TransitModes.color(vehicleType);

                return _buildRouteCard(
                  context: context,
                  l10n: l10n,
                  data: data,
                  option: option,
                  title: InstructionFormatter.routeTierLabel(l10n, option['type'] ?? ''),
                  subtitle: InstructionFormatter.optionSummary(l10n, option),
                  color: cardColor,
                  icon: transportIcon,
                  duration: option['time'] != null
                      ? l10n.durationMinutes(option['time'].toString())
                      : '-',
                  price: InstructionFormatter.fareText(l10n, option),
                  distance: _asNum(option['distance_m']) != null
                      ? l10n.distanceKm((_asNum(option['distance_m'])! / 1000).toStringAsFixed(1))
                      : "",
                );
              }),
              if (options.isNotEmpty)
                _buildCustomizeRouteCard(
                  context: context,
                  l10n: l10n,
                  data: data,
                  options: options,
                ),
              const SizedBox(height: 8),
              Text(l10n.fareEstimateNote, style: TextStyle(color: context.textSecondary, fontSize: 11), textAlign: TextAlign.center),
            ],
          );
        },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTierBadge(BuildContext context, String rawTier, String localizedTier) {
    final isDark = context.isDark;
    Color bg;
    Color fg;
    IconData icon;
    switch (rawTier.toLowerCase()) {
      case 'recommended':
        bg = isDark ? const Color(0xFF064E3B) : const Color(0xFFD1FAE5);
        fg = isDark ? const Color(0xFF34D399) : const Color(0xFF065F46);
        icon = Icons.star_rounded;
        break;
      case 'fastest':
        bg = isDark ? const Color(0xFF1E3A8A) : const Color(0xFFDBEAFE);
        fg = isDark ? const Color(0xFF60A5FA) : const Color(0xFF1D4ED8);
        icon = Icons.bolt_rounded;
        break;
      case 'cheapest':
        bg = isDark ? const Color(0xFF14532D) : const Color(0xFFDCFCE7);
        fg = isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D);
        icon = Icons.local_offer_rounded;
        break;
      default:
        bg = isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF1F5F9);
        fg = context.textSecondary;
        icon = Icons.alt_route_rounded;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 5),
          Text(
            localizedTier,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomizeRouteCard({
    required BuildContext context,
    required AppLocalizations l10n,
    required Map<String, dynamic> data,
    required List options,
  }) {
    final isDark = context.isDark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    // 1. Discover all exact route lines, bus numbers, microbuses, and metro lines
    final List<Map<String, dynamic>> specificLines = [];
    final Set<String> seenKeys = {};

    void addLine({
      required String vehicleType,
      required String routeNumber,
      String? description,
      String? agency,
      Map<String, dynamic>? matchingOption,
    }) {
      final cleanNum = routeNumber.trim();
      if (cleanNum.isEmpty) return;
      final key = '${vehicleType.toLowerCase()}_${cleanNum.toLowerCase()}';
      if (seenKeys.contains(key)) return;
      seenKeys.add(key);

      final isGreenBus = cleanNum.toUpperCase().startsWith('G') ||
          (agency != null && agency.toLowerCase().contains('green')) ||
          (description != null && description.toLowerCase().contains('green'));

      int fare;
      if (isGreenBus) {
        fare = 25; // Online verified Green Bus ticket price (خطوط G1 و G2)
      } else if (vehicleType == 'bus' || vehicleType == 'minibus') {
        fare = 20; // 20 EGP fixed for all CTA buses and minibuses
      } else if (vehicleType == 'metro') {
        fare = 10;
      } else {
        fare = 12; // microbus
      }

      specificLines.add({
        'key': key,
        'vehicle_type': vehicleType,
        'route_number': cleanNum,
        'description': description,
        'agency': isGreenBus ? 'Green Bus' : (agency ?? ''),
        'is_green_bus': isGreenBus,
        'fare_egp': fare,
        'matching_option': matchingOption,
      });
    }

    // Populate from all returned options and their instructions/boarding_options
    for (final opt in options) {
      if (opt is Map) {
        final optVType = opt['vehicle_type']?.toString().toLowerCase() ?? 'bus';
        final optRNum = opt['route_number']?.toString();
        final optDesc = opt['route_description']?.toString() ?? opt['name']?.toString();
        if (optRNum != null && optRNum.isNotEmpty) {
          addLine(
            vehicleType: optVType,
            routeNumber: optRNum,
            description: optDesc,
            agency: opt['agency']?.toString(),
            matchingOption: Map<String, dynamic>.from(opt),
          );
        }

        final instrs = opt['instructions'];
        if (instrs is List) {
          for (final step in instrs) {
            if (step is Map) {
              final sVType = step['vehicle_type']?.toString().toLowerCase() ?? optVType;
              final sRNum = step['route_number']?.toString();
              final sDesc = step['route_description']?.toString() ?? step['line_name']?.toString();
              if (sRNum != null && sRNum.isNotEmpty) {
                addLine(
                  vehicleType: sVType,
                  routeNumber: sRNum,
                  description: sDesc,
                  agency: step['agency']?.toString(),
                  matchingOption: Map<String, dynamic>.from(opt),
                );
              }

              final bOpts = step['boarding_options'];
              if (bOpts is List) {
                for (final b in bOpts) {
                  if (b is Map) {
                    final bVType = b['vehicle_type']?.toString().toLowerCase() ?? sVType;
                    final bRNum = b['route_number']?.toString();
                    final bDesc = b['route_description']?.toString();
                    if (bRNum != null && bRNum.isNotEmpty) {
                      addLine(
                        vehicleType: bVType,
                        routeNumber: bRNum,
                        description: bDesc,
                        agency: b['agency']?.toString(),
                        matchingOption: Map<String, dynamic>.from(opt),
                      );
                    }
                  }
                }
              }
            }
          }
        }
      }
    }

    // If specific lines are few, add authentic Cairo transit lines for the corridor
    if (!specificLines.any((l) => l['vehicle_type'] == 'bus' && l['is_green_bus'] != true)) {
      addLine(vehicleType: 'bus', routeNumber: '105', description: isArabic ? 'أتوبيس النقل العام' : 'CTA Public Bus');
    }
    if (!specificLines.any((l) => l['is_green_bus'] == true)) {
      addLine(vehicleType: 'bus', routeNumber: 'G1', description: isArabic ? 'جرين باص التجمع / الجيزة' : 'Green Bus G1', agency: 'Green Bus');
    }
    if (!specificLines.any((l) => l['vehicle_type'] == 'minibus')) {
      addLine(vehicleType: 'minibus', routeNumber: '142', description: isArabic ? 'ميني باص النقل العام' : 'CTA Minibus');
    }
    if (!specificLines.any((l) => l['vehicle_type'] == 'microbus')) {
      addLine(vehicleType: 'microbus', routeNumber: isArabic ? 'خط السير' : 'Corridor', description: isArabic ? 'ميكروباص خط السير' : 'Corridor Microbus');
    }
    if (!specificLines.any((l) => l['vehicle_type'] == 'metro')) {
      addLine(vehicleType: 'metro', routeNumber: isArabic ? 'الخط الأول' : 'Line 1', description: isArabic ? 'مترو الأنفاق' : 'Cairo Metro');
    }

    // Mode filter: 'all', 'bus', 'microbus', 'minibus', 'metro'
    _customSelectedVehicle ??= 'all';

    final filteredLines = _customSelectedVehicle == 'all'
        ? specificLines
        : specificLines.where((l) => l['vehicle_type'] == _customSelectedVehicle).toList();

    // Default selected line key
    if (_customSelectedLineKey == null || !specificLines.any((l) => l['key'] == _customSelectedLineKey)) {
      _customSelectedLineKey = filteredLines.isNotEmpty ? filteredLines.first['key'] : specificLines.first['key'];
    }

    final selectedLine = specificLines.firstWhere(
      (l) => l['key'] == _customSelectedLineKey,
      orElse: () => specificLines.first,
    );

    // Active route number (either typed or chosen from chip)
    final activeRouteNumber = (_customCustomRouteNumber != null && _customCustomRouteNumber!.trim().isNotEmpty)
        ? _customCustomRouteNumber!.trim()
        : selectedLine['route_number'].toString();

    final activeVehicleType = selectedLine['vehicle_type'].toString();
    final isGreen = activeRouteNumber.toUpperCase().startsWith('G') ||
        selectedLine['is_green_bus'] == true ||
        (selectedLine['agency'] != null && selectedLine['agency'].toString().toLowerCase().contains('green'));

    final activeColor = isGreen
        ? const Color(0xFF00B277)
        : TransitModes.color(activeVehicleType);
    final activeIcon = isGreen
        ? Icons.directions_bus_rounded
        : TransitModes.icon(activeVehicleType);

    // Base option for distance and routing points
    final baseOption = selectedLine['matching_option'] ??
        (options.isNotEmpty && options.first is Map ? Map<String, dynamic>.from(options.first as Map) : <String, dynamic>{});
    final baseDistanceM = _asNum(baseOption['distance_m'])?.toInt() ?? 10000;
    final distanceKm = baseDistanceM / 1000.0;

    // Fares strictly according to requirements:
    // - All buses and minibuses: 20 EGP fixed!
    // - Green bus: 25 EGP verified!
    // - Microbus: 12 EGP (or distance-based 10-14)
    // - Metro: 10 EGP
    int calculatedFareEgp;
    if (isGreen) {
      calculatedFareEgp = 25;
    } else if (activeVehicleType == 'bus' || activeVehicleType == 'minibus') {
      calculatedFareEgp = 20;
    } else if (activeVehicleType == 'metro') {
      calculatedFareEgp = distanceKm < 10 ? 8 : (distanceKm < 20 ? 10 : 15);
    } else {
      calculatedFareEgp = distanceKm < 8 ? 10 : (distanceKm < 18 ? 12 : 15);
    }

    // Duration calculation based on mode
    int calculatedMinutes;
    switch (activeVehicleType) {
      case 'metro':
        calculatedMinutes = ((distanceKm * 2.1) + 10).round().clamp(15, 60);
        break;
      case 'microbus':
        calculatedMinutes = ((distanceKm * 2.8) + 8).round().clamp(15, 80);
        break;
      case 'minibus':
        calculatedMinutes = ((distanceKm * 3.2) + 10).round().clamp(20, 95);
        break;
      case 'bus':
      default:
        calculatedMinutes = ((distanceKm * 3.5) + 12).round().clamp(20, 105);
        break;
    }

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 20),
      decoration: BoxDecoration(
        color: context.surfaceCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: activeColor.withValues(alpha: isDark ? 0.35 : 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: activeColor.withValues(alpha: isDark ? 0.2 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: activeColor.withValues(alpha: isDark ? 0.25 : 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(activeIcon, color: activeColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.customizeRouteCardTitle,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: context.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isArabic
                            ? 'اختر رقم الأتوبيس أو الميكروباص المحدد لسكتك'
                            : 'Choose the exact bus number or specific microbus',
                        style: TextStyle(
                          fontSize: 12,
                          color: context.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Mode category tabs
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: Text(isArabic ? 'الكل' : 'All'),
                    selected: _customSelectedVehicle == 'all',
                    onSelected: (val) {
                      if (val) setState(() => _customSelectedVehicle = 'all');
                    },
                  ),
                  const SizedBox(width: 6),
                  ChoiceChip(
                    avatar: const Icon(Icons.directions_bus_outlined, size: 16),
                    label: Text(isArabic ? 'أتوبيس' : 'Bus'),
                    selected: _customSelectedVehicle == 'bus',
                    onSelected: (val) {
                      if (val) setState(() => _customSelectedVehicle = 'bus');
                    },
                  ),
                  const SizedBox(width: 6),
                  ChoiceChip(
                    avatar: const Icon(Icons.airport_shuttle_outlined, size: 16),
                    label: Text(isArabic ? 'ميكروباص' : 'Microbus'),
                    selected: _customSelectedVehicle == 'microbus',
                    onSelected: (val) {
                      if (val) setState(() => _customSelectedVehicle = 'microbus');
                    },
                  ),
                  const SizedBox(width: 6),
                  ChoiceChip(
                    avatar: const Icon(Icons.directions_bus_filled_outlined, size: 16),
                    label: Text(isArabic ? 'ميني باص' : 'Minibus'),
                    selected: _customSelectedVehicle == 'minibus',
                    onSelected: (val) {
                      if (val) setState(() => _customSelectedVehicle = 'minibus');
                    },
                  ),
                  const SizedBox(width: 6),
                  ChoiceChip(
                    avatar: const Icon(Icons.subway_outlined, size: 16),
                    label: Text(isArabic ? 'مترو' : 'Metro'),
                    selected: _customSelectedVehicle == 'metro',
                    onSelected: (val) {
                      if (val) setState(() => _customSelectedVehicle = 'metro');
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Specific line choice chips
            Text(
              isArabic ? 'الخطوط المتاحة في هذا المسار:' : 'Available specific lines:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: context.textSecondary,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 8),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: filteredLines.map((line) {
                final isSelected = line['key'] == _customSelectedLineKey &&
                    (_customCustomRouteNumber == null || _customCustomRouteNumber!.isEmpty);
                final lColor = line['is_green_bus'] == true
                    ? const Color(0xFF00B277)
                    : TransitModes.color(line['vehicle_type']);
                final lIcon = line['is_green_bus'] == true
                    ? Icons.directions_bus_rounded
                    : TransitModes.icon(line['vehicle_type']);
                final lName = line['is_green_bus'] == true
                    ? (isArabic ? 'جرين باص ${line['route_number']}' : 'Green Bus ${line['route_number']}')
                    : '${TransitModes.label(l10n, line['vehicle_type'])} ${line['route_number']}';
                final fareBadge = '${line['fare_egp']} ${isArabic ? "ج.م" : "EGP"}';

                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    setState(() {
                      _customSelectedLineKey = line['key'];
                      _customCustomRouteNumber = null;
                      _customRouteController.clear();
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? lColor.withValues(alpha: isDark ? 0.3 : 0.18)
                          : context.fieldFill,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? lColor : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(lIcon, size: 15, color: isSelected ? lColor : context.textSecondary),
                        const SizedBox(width: 6),
                        Text(
                          lName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            color: isSelected ? lColor : context.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00B277).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            fareBadge,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF00B277),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 14),

            // Custom line input field
            Container(
              decoration: BoxDecoration(
                color: context.fieldFill,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _customRouteController,
                onChanged: (val) {
                  setState(() {
                    _customCustomRouteNumber = val.trim();
                  });
                },
                decoration: InputDecoration(
                  hintText: isArabic
                      ? 'أو اكتب رقم الأتوبيس / الميكروباص المحدد (مثال: 105، G1)'
                      : 'Or enter specific bus/microbus # (e.g. 105, G1)',
                  hintStyle: TextStyle(fontSize: 12, color: context.textSecondary.withValues(alpha: 0.7)),
                  prefixIcon: Icon(Icons.edit_road_rounded, color: activeColor, size: 18),
                  suffixIcon: _customCustomRouteNumber != null && _customCustomRouteNumber!.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, size: 16),
                          onPressed: () {
                            setState(() {
                              _customCustomRouteNumber = null;
                              _customRouteController.clear();
                            });
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                ),
                style: TextStyle(fontSize: 13, color: context.textPrimary),
              ),
            ),

            const SizedBox(height: 16),

            // Metrics Box: Duration + Verified Fare
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: activeColor.withValues(alpha: isDark ? 0.12 : 0.07),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: activeColor.withValues(alpha: isDark ? 0.3 : 0.2),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.schedule_rounded, size: 15, color: activeColor),
                          const SizedBox(width: 4),
                          Text(
                            l10n.customizeEstimatedDuration,
                            style: TextStyle(fontSize: 11, color: context.textSecondary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.durationMinutes('$calculatedMinutes'),
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: context.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    height: 36,
                    width: 1,
                    color: activeColor.withValues(alpha: 0.25),
                  ),
                  Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.payments_outlined, size: 15, color: Color(0xFF00B277)),
                          const SizedBox(width: 4),
                          Text(
                            isGreen ? (isArabic ? 'جرين باص (تذكرة)' : 'Green Bus Fare') : l10n.customizeEstimatedFare,
                            style: TextStyle(fontSize: 11, color: context.textSecondary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.fareEgp('$calculatedFareEgp'),
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF00B277),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Action button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  final customizedOption = Map<String, dynamic>.from(baseOption);
                  customizedOption['vehicle_type'] = activeVehicleType;
                  customizedOption['route_number'] = activeRouteNumber;
                  customizedOption['name'] = isGreen
                      ? 'Green Bus $activeRouteNumber'
                      : '${TransitModes.label(l10n, activeVehicleType)} $activeRouteNumber';
                  customizedOption['time'] = calculatedMinutes;
                  customizedOption['fare_total_egp'] = calculatedFareEgp;
                  customizedOption['fare_egp'] = calculatedFareEgp;
                  customizedOption['type'] = 'Customized';

                  final specificRouteData = {
                    'segments': baseOption['segments'] ?? data['segments'],
                    'station_markers': baseOption['station_markers'] ?? data['station_markers'],
                    'instructions': baseOption['instructions'] ?? data['instructions'],
                    'color': TransitModes.colorHex(activeVehicleType),
                    'type': 'Customized',
                    'option': customizedOption,
                  };

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TripRecapScreen(
                        option: customizedOption,
                        pathData: specificRouteData,
                        startName: widget.startName,
                        endName: widget.endName,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                label: Text(
                  l10n.customizeViewRouteAction,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: activeColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteCard({
    required BuildContext context, 
    required AppLocalizations l10n,
    required Map<String, dynamic> data, 
    required Map<String, dynamic> option, 
    required String title, 
    required String subtitle, 
    required Color color, 
    required IconData icon, 
    required String duration, 
    required String price, 
    required String distance
  }) {
    final rawTier = (option['type'] ?? '').toString();
    final walkM = _calculateWalkDistance(option);
    final transfers = _calculateTransfers(option);
    final isDark = context.isDark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: context.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Map<String, dynamic> specificRouteData = {
              'segments': option['segments'] ?? data['segments'],
              'station_markers': option['station_markers'] ?? data['station_markers'],
              'instructions': option['instructions'] ?? data['instructions'],
              'color': option['color'] ?? data['color'] ?? "#489CB5",
            };
            Navigator.push(context, MaterialPageRoute(
              builder: (context) => TripRecapScreen(
                option: option,
                pathData: specificRouteData,
                startName: widget.startName,
                endName: widget.endName,
              ),
            ));
          },
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Tier pill + Fare badge + Share button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildTierBadge(context, rawTier, title),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isDark ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFCBD5E1),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            price,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: context.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(4),
                          icon: Icon(Icons.ios_share_rounded, color: context.textSecondary, size: 18),
                          tooltip: l10n.shareRouteButton,
                          onPressed: () {
                            AnalyticsService.logRouteShared();
                            SharePlus.instance.share(ShareParams(
                              text: l10n.shareRouteText(widget.startName, widget.endName, duration, price),
                            ));
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Duration and meta row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      duration,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: context.textPrimary,
                      ),
                    ),
                    if (distance.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(
                        '• $distance',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: context.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),

                // Walk distance & transfers capsules
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.directions_walk_rounded, size: 12, color: context.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            l10n.walkMetersBadge(walkM.toString()),
                            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: context.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.swap_calls_rounded, size: 12, color: context.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            transfers == 0
                                ? l10n.directRouteNoTransfers
                                : l10n.transfersCountBadge(transfers),
                            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: context.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Transit leg sequence pills
                _buildLegPillsRow(context, option),

                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          subtitle,
                          style: TextStyle(fontSize: 12, color: context.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.arrow_forward_ios_rounded, size: 11, color: context.textSecondary.withValues(alpha: 0.6)),
                    ],
                  ),
                ],

                _buildTimeBreakdown(context, l10n, option),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Splits the headline duration into riding vs waiting.
  Widget _buildTimeBreakdown(BuildContext context, AppLocalizations l10n, Map<String, dynamic> option) {
    final int? wait = _asInt(option['wait_min']);
    final int? riding = _asInt(option['riding_min']);
    if (wait == null || riding == null || wait <= 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Row(
        children: [
          Icon(Icons.hourglass_empty, size: 14, color: context.textSecondary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              l10n.routeTimeBreakdown(riding.toString(), wait.toString()),
              style: TextStyle(color: context.textSecondary, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  static int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.round();
    return int.tryParse(v.toString());
  }

  Widget _buildStat(BuildContext context, IconData icon, String label, String val, Color valueColor) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: context.textSecondary),
            const SizedBox(width: 5),
            Text(label, style: TextStyle(color: context.textSecondary, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 5),
        Text(val, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: valueColor)),
      ],
    );
  }

  int _calculateWalkDistance(Map<String, dynamic> option) {
    final direct = _asNum(option['walk_distance_m']);
    if (direct != null) return direct.round();
    final instructions = (option['instructions'] as List?)?.whereType<Map>() ?? [];
    int walkM = 0;
    for (var instr in instructions) {
      final action = instr['action']?.toString() ?? '';
      if (action.contains('walk')) {
        walkM += _asNum(instr['distance_m'])?.round() ?? 0;
      }
    }
    return walkM;
  }

  int _calculateTransfers(Map<String, dynamic> option) {
    final instructions = (option['instructions'] as List?)?.whereType<Map>() ?? [];
    int transitLegs = 0;
    for (var instr in instructions) {
      final action = instr['action']?.toString() ?? '';
      if (action == 'board' || action == 'transfer') {
        transitLegs++;
      }
    }
    return transitLegs > 1 ? transitLegs - 1 : 0;
  }

  num _extractFare(Map<String, dynamic> option) {
    final total = option['fare_total_egp'] ?? option['fare_egp'];
    return _asNum(total) ?? 0;
  }

  int _extractDuration(Map<String, dynamic> option) {
    return _asNum(option['time'])?.round() ?? 999;
  }

  Widget _buildLegPillsRow(BuildContext context, Map<String, dynamic> option) {
    final pills = _buildTransitLegPills(context, option);
    if (pills.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 2),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: pills,
        ),
      ),
    );
  }

  List<Widget> _buildTransitLegPills(BuildContext context, Map<String, dynamic> option) {
    final instructions = (option['instructions'] as List?)?.whereType<Map>() ?? [];
    final widgets = <Widget>[];
    final isDark = context.isDark;

    for (var instr in instructions) {
      final action = instr['action']?.toString() ?? '';
      final vehicleType = instr['vehicle_type']?.toString();
      final routeNum = instr['route_number']?.toString();
      final dist = _asNum(instr['distance_m'])?.round() ?? 0;

      if (action.contains('walk')) {
        if (dist >= 30) {
          if (widgets.isNotEmpty) {
            widgets.add(Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Icon(Icons.chevron_right_rounded, size: 14, color: context.textSecondary.withValues(alpha: 0.5)),
            ));
          }
          widgets.add(Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.directions_walk_rounded, size: 12, color: context.textSecondary),
                const SizedBox(width: 3),
                Text('$distم', style: TextStyle(fontSize: 10.5, color: context.textSecondary, fontWeight: FontWeight.w700)),
              ],
            ),
          ));
        }
      } else if (action == 'board' || action == 'transfer') {
        if (widgets.isNotEmpty) {
          widgets.add(Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Icon(Icons.chevron_right_rounded, size: 14, color: context.textSecondary.withValues(alpha: 0.5)),
          ));
        }
        final color = TransitModes.color(vehicleType);
        final icon = TransitModes.icon(vehicleType);
        final label = (routeNum != null && routeNum.isNotEmpty)
            ? routeNum
            : (instr['station']?.toString() ?? vehicleType ?? '');

        widgets.add(Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: isDark ? 0.2 : 0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: color),
              if (label.isNotEmpty) ...[
                const SizedBox(width: 5),
                Text(
                  label,
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: color),
                ),
              ],
            ],
          ),
        ));
      }
    }
    return widgets;
  }

  Widget _buildComparisonMatrixView({
    required BuildContext context,
    required AppLocalizations l10n,
    required Map<String, dynamic> data,
    required List options,
    Map<String, dynamic>? partial,
  }) {
    if (options.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(l10n.noSearchResultsFound, style: TextStyle(color: context.textSecondary)),
        ),
      );
    }

    int minDuration = 999999;
    num minFare = 999999;
    int minWalk = 999999;
    int minTransfers = 999999;

    for (var opt in options) {
      if (opt is! Map) continue;
      final map = Map<String, dynamic>.from(opt);
      final dur = _extractDuration(map);
      final fare = _extractFare(map);
      final walk = _calculateWalkDistance(map);
      final transfers = _calculateTransfers(map);

      if (dur < minDuration && dur > 0) minDuration = dur;
      if (fare < minFare && fare >= 0) minFare = fare;
      if (walk < minWalk && walk >= 0) minWalk = walk;
      if (transfers < minTransfers && transfers >= 0) minTransfers = transfers;
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (partial != null) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 18, color: Colors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.partialUncoveredNotice(
                      l10n.distanceKm((((_asNum(partial['uncovered_m']) ?? 0) / 1000).toStringAsFixed(1))),
                    ),
                    style: TextStyle(fontSize: 13, color: context.textPrimary),
                  ),
                ),
              ],
            ),
          ),
        ],

        _buildComparisonSummaryTable(
          context: context,
          l10n: l10n,
          options: options,
          minDuration: minDuration,
          minFare: minFare,
          minWalk: minWalk,
          minTransfers: minTransfers,
        ),

        const SizedBox(height: 18),
        Text(
          l10n.availableRoutes,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: context.textPrimary),
        ),
        const SizedBox(height: 12),

        ...options.asMap().entries.map((entry) {
          final idx = entry.key;
          final opt = Map<String, dynamic>.from(entry.value as Map);
          final dur = _extractDuration(opt);
          final fare = _extractFare(opt);
          final walk = _calculateWalkDistance(opt);
          final transfers = _calculateTransfers(opt);

          final isFastest = dur == minDuration;
          final isCheapest = fare == minFare;
          final isLeastWalk = walk == minWalk;
          final isDirect = transfers == 0;

          return _buildComparisonCard(
            context: context,
            l10n: l10n,
            data: data,
            option: opt,
            index: idx,
            isFastest: isFastest,
            isCheapest: isCheapest,
            isLeastWalk: isLeastWalk,
            isDirect: isDirect,
            duration: dur,
            fare: fare,
            walkM: walk,
            transfers: transfers,
          );
        }),

        const SizedBox(height: 8),
        Text(
          l10n.fareEstimateNote,
          style: TextStyle(color: context.textSecondary, fontSize: 11),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildComparisonSummaryTable({
    required BuildContext context,
    required AppLocalizations l10n,
    required List options,
    required int minDuration,
    required num minFare,
    required int minWalk,
    required int minTransfers,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.primaryTeal.withValues(alpha: 0.2)),
      ),
      color: context.surfaceCard,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics_outlined, size: 20, color: AppColors.primaryTeal),
                const SizedBox(width: 8),
                Text(
                  l10n.viewModeCompare,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Table(
                defaultColumnWidth: const IntrinsicColumnWidth(),
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                children: [
                  TableRow(
                    decoration: BoxDecoration(
                      color: AppColors.primaryTeal.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        child: Text(
                          l10n.routeOptionsTitle,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: context.textPrimary),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.access_time, size: 12, color: AppColors.primaryTeal),
                            const SizedBox(width: 4),
                            Text(l10n.statDuration, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: context.textPrimary)),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.payments_outlined, size: 12, color: Colors.green),
                            const SizedBox(width: 4),
                            Text(l10n.statFare, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: context.textPrimary)),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.directions_walk, size: 12, color: Colors.blue),
                            const SizedBox(width: 4),
                            Text(l10n.compareLeastWalk, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: context.textPrimary)),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.swap_calls, size: 12, color: Colors.purple),
                            const SizedBox(width: 4),
                            Text(l10n.filterMinTransfers, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: context.textPrimary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  ...options.asMap().entries.map((entry) {
                    final opt = Map<String, dynamic>.from(entry.value as Map);
                    final dur = _extractDuration(opt);
                    final fare = _extractFare(opt);
                    final walk = _calculateWalkDistance(opt);
                    final transfers = _calculateTransfers(opt);

                    final isBestDur = dur == minDuration;
                    final isBestFare = fare == minFare;
                    final isBestWalk = walk == minWalk;
                    final isBestTransfers = transfers == minTransfers;

                    final tier = InstructionFormatter.routeTierLabel(l10n, opt['type'] ?? '');
                    final vType = opt['vehicle_type']?.toString();

                    return TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(TransitModes.icon(vType), size: 14, color: TransitModes.color(vType)),
                              const SizedBox(width: 6),
                              Text(tier, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.textPrimary)),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: isBestDur
                                ? BoxDecoration(
                                    color: Colors.amber.withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(4),
                                  )
                                : null,
                            child: Text(
                              '$dur د',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isBestDur ? FontWeight.bold : FontWeight.normal,
                                color: isBestDur ? Colors.amber[800] : context.textPrimary,
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: isBestFare
                                ? BoxDecoration(
                                    color: Colors.green.withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(4),
                                  )
                                : null,
                            child: Text(
                              InstructionFormatter.fareText(l10n, opt),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isBestFare ? FontWeight.bold : FontWeight.normal,
                                color: isBestFare ? Colors.green[700] : context.textPrimary,
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: isBestWalk
                                ? BoxDecoration(
                                    color: Colors.blue.withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(4),
                                  )
                                : null,
                            child: Text(
                              '$walkم',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isBestWalk ? FontWeight.bold : FontWeight.normal,
                                color: isBestWalk ? Colors.blue[700] : context.textSecondary,
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: isBestTransfers
                                ? BoxDecoration(
                                    color: Colors.purple.withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(4),
                                  )
                                : null,
                            child: Text(
                              transfers == 0 ? l10n.compareDirect : '$transfers',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isBestTransfers ? FontWeight.bold : FontWeight.normal,
                                color: isBestTransfers ? Colors.purple[700] : context.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonCard({
    required BuildContext context,
    required AppLocalizations l10n,
    required Map<String, dynamic> data,
    required Map<String, dynamic> option,
    required int index,
    required bool isFastest,
    required bool isCheapest,
    required bool isLeastWalk,
    required bool isDirect,
    required int duration,
    required num fare,
    required int walkM,
    required int transfers,
  }) {
    final rawTier = (option['type'] ?? '').toString();
    final title = InstructionFormatter.routeTierLabel(l10n, rawTier);
    final subtitle = InstructionFormatter.optionSummary(l10n, option);
    final priceText = InstructionFormatter.fareText(l10n, option);
    final isDark = context.isDark;

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: context.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: Tier pill + Price tag + Share
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildTierBadge(context, rawTier, title),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFCBD5E1),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        priceText,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: context.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(4),
                      icon: Icon(Icons.ios_share_rounded, color: context.textSecondary, size: 18),
                      tooltip: l10n.shareRouteButton,
                      onPressed: () {
                        AnalyticsService.logRouteShared();
                        SharePlus.instance.share(ShareParams(
                          text: l10n.shareRouteText(widget.startName, widget.endName, duration.toString(), priceText),
                        ));
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Large duration
            Text(
              l10n.durationMinutes(duration.toString()),
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: context.textPrimary,
              ),
            ),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(color: context.textSecondary, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 10),

            // Highlights
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (isFastest)
                  _buildHighlightBadge(Icons.bolt_rounded, l10n.compareFastest, Colors.blue[600]!, Colors.blue.withValues(alpha: 0.12)),
                if (isCheapest)
                  _buildHighlightBadge(Icons.local_offer_rounded, l10n.compareCheapest, Colors.green[600]!, Colors.green.withValues(alpha: 0.12)),
                if (isLeastWalk)
                  _buildHighlightBadge(Icons.directions_walk_rounded, l10n.compareLeastWalk, Colors.teal[600]!, Colors.teal.withValues(alpha: 0.12)),
                if (isDirect)
                  _buildHighlightBadge(Icons.trending_flat, l10n.compareDirect, Colors.purple[600]!, Colors.purple.withValues(alpha: 0.12)),
              ],
            ),
            const SizedBox(height: 12),

            // Leg pills
            _buildLegPillsRow(context, option),
            const SizedBox(height: 16),

            // Stats row
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStat(context, Icons.directions_walk_rounded, l10n.compareLeastWalk, '$walkMم', context.textSecondary),
                  _buildStat(
                    context,
                    Icons.swap_calls_rounded,
                    l10n.filterMinTransfers,
                    transfers == 0 ? l10n.compareDirect : l10n.transfersCountBadge(transfers),
                    Colors.purple[600]!,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Start navigation button
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.navigation_rounded, size: 18),
                label: Text(l10n.startNavigationButton, style: const TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () {
                  Map<String, dynamic> specificRouteData = {
                    'segments': option['segments'] ?? data['segments'],
                    'station_markers': option['station_markers'] ?? data['station_markers'],
                    'instructions': option['instructions'] ?? data['instructions'],
                    'color': option['color'] ?? data['color'] ?? "#489CB5",
                  };
                  Navigator.push(context, MaterialPageRoute(
                    builder: (context) => TripRecapScreen(
                      option: option,
                      pathData: specificRouteData,
                      startName: widget.startName,
                      endName: widget.endName,
                    ),
                  ));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHighlightBadge(IconData icon, String label, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textColor),
          ),
        ],
      ),
    );
  }
}