import 'package:flutter/material.dart';

import 'MetroStationPickerScreen.dart';
import 'RailNetworkMapScreen.dart';
import '../services/api_service.dart';
import '../l10n/app_localizations.dart';
import '../services/instruction_formatter.dart';
import '../theme/app_theme.dart';
import '../widgets/error_state.dart';
import '../widgets/metro_report_sheet.dart';

/// "Get me there on the metro only."
///
/// Deliberately not the trip planner. The planner finds the best trip
/// using everything available and will happily put a rider on a microbus;
/// this answers the narrower question a rider asks when the surface
/// network is gridlocked, or when they simply want the certainty of a
/// train. Three lines, 84 stations, five interchanges.
///
/// The fare shown here comes from the same banding function the planner
/// uses, so the two can never quote different numbers for the same ride.
class MetroScreen extends StatefulWidget {
  final VoidCallback? onGoHome;
  const MetroScreen({super.key, this.onGoHome});

  @override
  State<MetroScreen> createState() => _MetroScreenState();
}

class _MetroScreenState extends State<MetroScreen> {
  final ApiService _api = ApiService();

  List<Map<String, dynamic>> _stations = const [];
  String _loadedLang = '';
  bool _loadingStations = true;
  // A FLAG, not a translated sentence. This held the result of
  // AppLocalizations.of(context) captured at the moment the request
  // failed, so the message stayed frozen in whichever language was active
  // when it broke -- switch to English and an Arabic error sat there until
  // something forced a refetch. build() resolves the wording now, and
  // build() reruns on every locale change.
  bool _stationsFailed = false;

  Map<String, dynamic>? _from;
  Map<String, dynamic>? _to;

  bool _planning = false;
  // Same fix, but this one has two distinct messages, so a bool won't do.
  // Symbolic value in, wording out at render time.
  _PlanError? _planError;
  Map<String, dynamic>? _plan;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadStations());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final lang = Localizations.localeOf(context).languageCode;
    if (_loadedLang.isNotEmpty && _loadedLang != lang) {
      // Station names come from the backend already localized, so a
      // language switch has to refetch rather than just rebuild. The
      // chosen stations survive it -- they're keyed by stop_id.
      _loadStations(refreshSelection: true);
    }
  }

  Future<void> _loadStations({bool refreshSelection = false}) async {
    if (!mounted) return;
    final lang = Localizations.localeOf(context).languageCode == 'ar' ? 'ar' : 'en';
    setState(() {
      _loadingStations = true;
      _stationsFailed = false;
      // Recorded on the ATTEMPT, not the success. It used to be assigned
      // only in the success branch below, so a failed first load left it
      // empty -- and didChangeDependencies guards on it being non-empty.
      // The language toggle silently stopped working after any failure,
      // which is precisely what a rider sees when the backend is down.
      _loadedLang = lang;
    });
    try {
      final stations = await _api.fetchMetroStations(lang: lang);
      if (!mounted) return;
      setState(() {
        _stations = stations;
        _loadingStations = false;
        if (refreshSelection) {
          _from = _reselect(_from);
          _to = _reselect(_to);
          _plan = null;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingStations = false;
        _stationsFailed = true;
      });
    }
  }

  Map<String, dynamic>? _reselect(Map<String, dynamic>? previous) {
    if (previous == null) return null;
    for (final s in _stations) {
      if (s['stop_id'] == previous['stop_id']) return s;
    }
    return previous;
  }

  Future<void> _pick({required bool isFrom}) async {
    final l10n = AppLocalizations.of(context);
    final selected = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => MetroStationPickerScreen(
          stations: _stations,
          title: isFrom ? l10n.metroFromLabel : l10n.metroToLabel,
          excludeStopId: (isFrom ? _to : _from)?['stop_id'] as String?,
        ),
      ),
    );
    if (selected == null || !mounted) return;
    setState(() {
      if (isFrom) {
        _from = selected;
      } else {
        _to = selected;
      }
      _plan = null;
      _planError = null;
    });
  }

  void _swap() {
    setState(() {
      final tmp = _from;
      _from = _to;
      _to = tmp;
      _plan = null;
      _planError = null;
    });
  }

  Future<void> _submit() async {
    final from = _from, to = _to;
    if (from == null || to == null) return;
    if (from['stop_id'] == to['stop_id']) {
      setState(() => _planError = _PlanError.sameStation);
      return;
    }

    setState(() {
      _planning = true;
      _planError = null;
      _plan = null;
    });

    final lang = Localizations.localeOf(context).languageCode == 'ar' ? 'ar' : 'en';
    final result = await _api.planMetro(
      fromStop: from['stop_id'] as String,
      toStop: to['stop_id'] as String,
      lang: lang,
    );
    if (!mounted) return;

    if (result['success'] == true) {
      setState(() {
        _plan = result;
        _planning = false;
      });
    } else {
      setState(() {
        _planning = false;
        // Deliberately ignores the server's own wording: the only two ways
        // this fails are "same station" (already caught above) and "no
        // metro-only path", and the app can say both in the rider's language.
        _planError = _PlanError.noPath;
      });
    }
  }

  String _planErrorText(AppLocalizations l10n) {
    switch (_planError!) {
      case _PlanError.sameStation:
        return l10n.metroSameStationError;
      case _PlanError.noPath:
        return l10n.metroNoPathError;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (_loadingStations) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_stationsFailed) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: ErrorState(
            message: l10n.metroStationsLoadFailed, onRetry: _loadStations),
      );
    }

    final canSubmit = _from != null && _to != null && !_planning;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (widget.onGoHome != null) ...[
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                  onPressed: widget.onGoHome,
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.metroTitle,
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold, color: context.textPrimary)),
                    const SizedBox(height: 4),
                    Text(l10n.metroSubtitle,
                        style: TextStyle(fontSize: 13, color: context.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ActionChip(
                avatar: const Icon(Icons.map_outlined, size: 16, color: Colors.white),
                backgroundColor: AppColors.primaryTeal,
                label: Text(
                  l10n.metroNetworkMapButton,
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RailNetworkMapScreen()),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 18),
          _pickerCard(l10n, canSubmit),
          if (_planError != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.gold),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(_planErrorText(l10n),
                        style: TextStyle(fontSize: 13, color: context.textPrimary)),
                  ),
                ],
              ),
            ),
          ],
          if (_plan != null) ...[
            const SizedBox(height: 18),
            _summary(l10n, _plan!),
            const SizedBox(height: 14),
            ..._legWidgets(l10n, _plan!),
          ],
        ],
      ),
    );
  }

  Widget _pickerCard(AppLocalizations l10n, bool canSubmit) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceCard,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    _stationField(l10n, isFrom: true),
                    const SizedBox(height: 10),
                    _stationField(l10n, isFrom: false),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: l10n.metroSwapTooltip,
                onPressed: (_from == null && _to == null) ? null : _swap,
                icon: const Icon(Icons.swap_vert_rounded, color: AppColors.primaryTeal),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: canSubmit ? _submit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryTeal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _planning
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(l10n.metroPlanButton,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stationField(AppLocalizations l10n, {required bool isFrom}) {
    final station = isFrom ? _from : _to;
    final label = isFrom ? l10n.metroFromLabel : l10n.metroToLabel;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _pick(isFrom: isFrom),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: context.fieldFill,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(isFrom ? Icons.trip_origin : Icons.place_rounded,
                size: 18, color: AppColors.primaryTeal),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(fontSize: 11, color: context.textSecondary)),
                  const SizedBox(height: 2),
                  Text(
                    station == null
                        ? l10n.metroPickStation
                        : (station['name'] ?? '').toString(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: station == null ? context.textSecondary : context.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: context.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _summary(AppLocalizations l10n, Map<String, dynamic> plan) {
    final changes = InstructionFormatter.asNum(plan['interchange_count'])?.toInt() ?? 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryTeal, AppColors.deepPetrol],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: _summaryStat(l10n.statDuration,
                    l10n.durationMinutes('${InstructionFormatter.asNum(plan['time_min'])?.toInt() ?? 0}')),
              ),
              Expanded(
                child: _summaryStat(
                    l10n.statFare, l10n.fareEgp(_formatNumber(plan['fare_egp'] ?? 0))),
              ),
              Expanded(
                child: _summaryStat(l10n.tripStepsLabel,
                    l10n.linesStopCount(InstructionFormatter.asNum(plan['total_stops'])?.toInt() ?? 0)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            changes == 0 ? l10n.metroNoChanges : l10n.metroChangesCount(changes),
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _summaryStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
      ],
    );
  }

  /// One card per line ridden, with a change marker between them. The
  /// "towards" line is the important one -- it's what's on the platform
  /// sign, and it's the only thing telling a rider which side to stand on.
  List<Widget> _legWidgets(AppLocalizations l10n, Map<String, dynamic> plan) {
    final legs = List<Map<String, dynamic>>.from(plan['legs'] ?? const []);
    final widgets = <Widget>[];

    for (int i = 0; i < legs.length; i++) {
      final leg = legs[i];
      final line = Map<String, dynamic>.from(leg['line'] ?? const {});
      final stops = List<Map<String, dynamic>>.from(leg['stops'] ?? const []);
      final towards = leg['towards'];

      if (i > 0) {
        final previousStop = stops.isNotEmpty ? (stops.first['name'] ?? '').toString() : '';
        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              const Icon(Icons.swap_calls_rounded, size: 18, color: AppColors.gold),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.metroChangeAt(previousStop),
                      style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: context.textPrimary),
                    ),
                    Text(
                      l10n.metroChangeTo((line['name'] ?? l10n.vehicleMetro).toString()),
                      style: TextStyle(fontSize: 12, color: context.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ));
      }

      widgets.add(Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.surfaceCard,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.subway_rounded, size: 18, color: AppColors.primaryTeal),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    (line['name'] ?? l10n.vehicleMetro).toString(),
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold, color: context.textPrimary),
                  ),
                ),
                Text(l10n.metroRideStops(InstructionFormatter.asNum(leg['num_stops'])?.toInt() ?? 0),
                    style: TextStyle(fontSize: 12, color: context.textSecondary)),
              ],
            ),
            if (towards != null && towards.toString().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(l10n.linesDirectionTowards(towards.toString()),
                  style: TextStyle(fontSize: 13, color: context.textSecondary)),
            ],
            const SizedBox(height: 12),
            ...List.generate(stops.length, (index) {
              final isEnd = index == 0 || index == stops.length - 1;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Container(
                      width: isEnd ? 10 : 7,
                      height: isEnd ? 10 : 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isEnd ? AppColors.primaryTeal : Colors.transparent,
                        border: Border.all(color: AppColors.primaryTeal, width: 2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        (stops[index]['name'] ?? '').toString(),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isEnd ? FontWeight.w600 : FontWeight.normal,
                          color: isEnd ? context.textPrimary : context.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ));
    }

    widgets.add(
      Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 20),
        child: Center(
          child: TextButton.icon(
            onPressed: () {
              MetroReportSheet.show(
                context,
                metroPlan: plan,
              );
            },
            icon: Icon(Icons.flag_outlined, size: 16, color: context.textSecondary),
            label: Text(
              l10n.reportAnIssueWithMetro,
              style: TextStyle(color: context.textSecondary, fontSize: 12.5),
            ),
          ),
        ),
      ),
    );

    return widgets;
  }

  static String _formatNumber(dynamic value) {
    final n = InstructionFormatter.asNum(value)?.toDouble() ?? 0.0;
    return n == n.roundToDouble() ? n.round().toString() : n.toStringAsFixed(1);
  }
}

/// The two ways a metro-only plan can fail. Kept symbolic so the wording is
/// chosen at render time in the current locale, rather than baked in at the
/// moment the failure happened.
enum _PlanError { sameStation, noPath }
