import 'dart:async';

import 'package:flutter/material.dart';

import 'LineDetailScreen.dart';
import '../services/api_service.dart';
import '../l10n/app_localizations.dart';
import '../services/instruction_formatter.dart';
import '../services/transit_modes.dart';
import '../theme/app_theme.dart';
import '../widgets/error_state.dart';

/// "What does line 65 actually do?"
///
/// A rider standing at a stop watching a bus go past has a different
/// question from the one the trip planner answers. They don't want a
/// journey; they want to know whether *that* vehicle goes where they're
/// going. This screen is the table of contents for the network.
///
/// Search matches the number **and** the corridor, because roughly 300
/// microbus routes in the Cairo feed carry no number at all -- searching
/// only numbers would make a third of the network unreachable.
class LinesScreen extends StatefulWidget {
  final VoidCallback? onGoHome;
  const LinesScreen({super.key, this.onGoHome});

  @override
  State<LinesScreen> createState() => _LinesScreenState();
}

class _LinesScreenState extends State<LinesScreen> {
  // Now includes metro, monorail and LRT. The browser has always been able
  // to show them -- the backend returns every route -- but with no chip for
  // them a rider could only reach a rail line by typing its name, which is
  // the opposite of what a browser is for.
  static const List<String?> _filters = TransitModes.browsableFilters;

  final ApiService _api = ApiService();
  final TextEditingController _searchController = TextEditingController();

  Timer? _debounce;
  String _query = '';
  String? _vehicleFilter;
  // The language of the last load ATTEMPT, successful or not. It used to
  // be assigned only inside the success branch, which meant a failed
  // first load left it empty -- and didChangeDependencies below guards on
  // it being non-empty, so switching language after a failure did nothing
  // at all. That is exactly what a rider sees when the backend is down:
  // the language toggle appears dead until they tap Retry.
  String _loadedLang = '';

  bool _loading = true;
  // A FLAG, not a translated sentence. This used to hold
  // AppLocalizations.of(context).linesLoadFailed, captured at the moment
  // the request failed -- so the error text stayed frozen in whichever
  // language was active when it broke. Switching to English left an
  // Arabic error on screen until something forced a refetch. The string
  // is now resolved in build(), which reruns on every locale change.
  bool _failed = false;
  List<Map<String, dynamic>> _routes = const [];

  @override
  void initState() {
    super.initState();
    // Post-frame, not inline: _load() reads Localizations.localeOf(context),
    // and an inherited-widget lookup in initState throws.
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Switching language has to re-query rather than just re-render: the
    // stop names in each row come from the backend already localized.
    final lang = Localizations.localeOf(context).languageCode;
    if (_loadedLang.isNotEmpty && _loadedLang != lang) _load();
  }

  void _onSearchChanged(String value) {
    // Rebuild immediately so the clear button appears on the first
    // keystroke rather than 350ms later with the results.
    setState(() {});
    _debounce?.cancel();
    // 350ms: long enough that typing "Maadi" is one request rather than
    // five, short enough that it still feels like live search.
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() => _query = value.trim());
      _load();
    });
  }

  Future<void> _load() async {
    final lang = _langCode();
    setState(() {
      _loading = true;
      _failed = false;
      // Recorded up front, so a failed attempt still counts as "we tried
      // this language" and a later switch re-triggers the load.
      _loadedLang = lang;
    });
    try {
      final results = await _api.searchRoutes(
        query: _query,
        vehicleType: _vehicleFilter,
        lang: lang,
        // Used to be 60, which silently truncated every browse view --
        // "All" (1,090 routes network-wide as of Sept 2026) and even a
        // single mode filter like microbus (590 routes) both blew past
        // it, so most of the network was simply never in the response to
        // scroll to. The backend already builds and sorts its full match
        // list before slicing to `limit` (see /api/routes in main.py), so
        // this isn't adding real request cost -- it's just no longer
        // discarding results the backend already computed.
        limit: 2000,
      );
      if (!mounted) return;
      setState(() {
        _routes = results;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  String _langCode() {
    if (!mounted) return 'en';
    return Localizations.localeOf(context).languageCode == 'ar' ? 'ar' : 'en';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (widget.onGoHome != null) ...[
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                        onPressed: widget.onGoHome,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        l10n.linesTitle,
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold, color: context.textPrimary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(l10n.linesTapHint,
                    style: TextStyle(fontSize: 13, color: context.textSecondary)),
                const SizedBox(height: 14),
                TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (v) {
                    _debounce?.cancel();
                    setState(() => _query = v.trim());
                    _load();
                  },
                  decoration: InputDecoration(
                    hintText: l10n.linesSearchHint,
                    prefixIcon: const Icon(Icons.search, color: AppColors.primaryTeal),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close),
                            tooltip: l10n.clearHistoryLabel,
                            onPressed: () {
                              _searchController.clear();
                              _debounce?.cancel();
                              setState(() => _query = '');
                              _load();
                            },
                          ),
                    filled: true,
                    fillColor: context.fieldFill,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _filters.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final value = _filters[i];
                final selected = _vehicleFilter == value;
                return ChoiceChip(
                  label: Text(value == null
                      ? l10n.linesFilterAll
                      : InstructionFormatter.vehicleTypeLabel(l10n, value)),
                  selected: selected,
                  onSelected: (_) {
                    setState(() => _vehicleFilter = value);
                    _load();
                  },
                  selectedColor: AppColors.primaryTeal.withValues(alpha: 0.18),
                  labelStyle: TextStyle(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                    color: selected ? AppColors.primaryTeal : context.textSecondary,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(child: _buildBody(l10n)),
        ],
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_failed) return ErrorState(message: l10n.linesLoadFailed, onRetry: _load);
    if (_routes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            _query.isEmpty ? l10n.linesSearchPrompt : l10n.linesNoResults,
            textAlign: TextAlign.center,
            style: TextStyle(color: context.textSecondary, fontSize: 14),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      itemCount: _routes.length,
      itemBuilder: (context, i) => _RouteCard(
        route: _routes[i],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LineDetailScreen(
              routeId: _routes[i]['route_id'] as String,
              fallbackTitle: _titleFor(_routes[i], l10n),
            ),
          ),
        ),
      ),
    );
  }

  String _titleFor(Map<String, dynamic> route, AppLocalizations l10n) {
    final number = route['number'];
    if (number != null && number.toString().trim().isNotEmpty) return number.toString();
    final description = (route['description'] ?? '').toString();
    if (description.isNotEmpty) return description;
    return InstructionFormatter.vehicleTypeLabel(l10n, route['vehicle_type'] as String?);
  }
}

class _RouteCard extends StatelessWidget {
  final Map<String, dynamic> route;
  final VoidCallback onTap;

  const _RouteCard({required this.route, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final number = (route['number'] ?? '').toString().trim();
    final description = (route['description'] ?? '').toString().trim();
    final vehicle = InstructionFormatter.vehicleTypeLabel(l10n, route['vehicle_type'] as String?);
    final headway = route['typical_headway_min'];
    final stopCount = InstructionFormatter.asNum(route['stop_count'])?.toInt() ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      color: context.surfaceCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // The number badge. Unnumbered microbus corridors get the
              // vehicle icon instead of an empty box -- and the badge is
              // tinted by mode, so a rail line is distinguishable from a
              // bus at a glance while scrolling a list of a thousand.
              Container(
                constraints: const BoxConstraints(minWidth: 54, maxWidth: 84, minHeight: 54),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: TransitModes.color(route['vehicle_type'] as String?)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: number.isEmpty
                    ? Icon(TransitModes.icon(route['vehicle_type'] as String?),
                        color: TransitModes.color(route['vehicle_type'] as String?),
                        size: 24)
                    : Text(
                        number,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: number.length > 6 ? 11.5 : (number.length > 4 ? 12.5 : 14),
                            height: 1.15,
                            color: TransitModes.color(
                                route['vehicle_type'] as String?)),
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      description.isEmpty ? vehicle : description,
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15, color: context.textPrimary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 10,
                      runSpacing: 2,
                      children: [
                        _meta(context, Icons.commit_rounded, l10n.linesStopCount(stopCount)),
                        if (headway != null)
                          _meta(context, Icons.schedule_rounded,
                              l10n.linesEveryMinutes(_formatHeadway(headway))),
                        _meta(context, Icons.payments_outlined,
                            _fareForRoute(route, Localizations.localeOf(context).languageCode == 'ar')),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: context.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  // Metro/LRT/monorail/apm ranges below are band descriptions, not a
  // single number, so they have nowhere to plug a real figure into and
  // stay as static text (kept in sync with raptor_engine.BANDED_FARE_TIERS
  // by hand -- same as LineDetailScreen._detailedFareText). Bus and
  // minibus are flat per-boarding fares, and the backend now sends the
  // real current one as `route['fare_egp']` (see lookups.py
  // search_routes) -- this used to hardcode '10 EGP'/'14 EGP' here
  // instead of reading it, which is exactly why this card could show a
  // different, stale fare than the one the detail screen showed for the
  // same route: the detail screen already read the real value, this
  // card never did.
  static String _fareForRoute(Map<String, dynamic> route, bool isArabic) {
    final mode = (route['vehicle_type'] as String? ?? 'bus').toLowerCase();
    final number = (route['number'] ?? '').toString().toLowerCase();
    final desc = (route['description'] ?? '').toString().toLowerCase();
    final fare = InstructionFormatter.asNum(route['fare_egp'])?.round();

    if (mode == 'metro' || mode.contains('subway')) {
      return isArabic ? '10 - 20 ج.م' : '10 - 20 EGP';
    } else if (mode == 'lrt') {
      return isArabic ? '10 - 20 ج.م' : '10 - 20 EGP';
    } else if (mode == 'monorail') {
      return isArabic ? '20 - 80 ج.م' : '20 - 80 EGP';
    } else if (mode == 'minibus') {
      final n = fare ?? 20;
      return isArabic ? '$n ج.م' : '$n EGP';
    } else if (mode == 'microbus') {
      // Distance-based, not a single number (MICROBUS_FARE_PER_KM in
      // raptor_engine.py) -- the minimum is the one part that's a fixed
      // constant (MICROBUS_MIN_FARE), which was raised 5 -> 10 on the
      // backend without this range ever being updated to match.
      return isArabic ? '10 - 15 ج.م' : '10 - 15 EGP';
    } else if (mode == 'apm') {
      return isArabic ? 'مجاناً' : 'Free';
    } else {
      final isAC = number.contains('mm') ||
          number.contains('m') && (number.startsWith('m') || number.startsWith('م')) ||
          desc.contains('مواصلات مصر') ||
          desc.contains('مكيف');
      if (isAC) {
        return isArabic ? '17 - 20 ج.م' : '17 - 20 EGP';
      }
      // Fallback only (fare_egp missing/null) -- matches
      // FLAT_FARE_BY_VEHICLE['bus'] in raptor_engine.py (20 EGP) and
      // LineDetailScreen's matching fallback, so the two screens can't
      // disagree on a route where the real value didn't come through.
      final n = fare ?? 20;
      return isArabic ? '$n ج.م' : '$n EGP';
    }
  }

  static String _formatHeadway(dynamic value) {
    final n = InstructionFormatter.asNum(value)?.toDouble() ?? 0.0;
    return n == n.roundToDouble() ? n.round().toString() : n.toStringAsFixed(1);
  }

  Widget _meta(BuildContext context, IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: context.textSecondary),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 12, color: context.textSecondary)),
      ],
    );
  }
}
