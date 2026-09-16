import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/instruction_formatter.dart';
import '../services/route_report_service.dart';
import '../services/transit_modes.dart';
import '../theme/app_theme.dart';

/// Lets a rider tell us a planned route is wrong, or that they know a
/// better one.
///
/// The feed behind this app is stitched together from open data of very
/// uneven quality -- several hundred microbus corridors carry no route
/// number at all, and nothing in it is verified against what actually runs
/// today. Riders are the only people who know when a leg is wrong. This
/// screen is the one place they can say so, and it deliberately captures
/// the GTFS identity of each leg (see RouteReportService) so a report is a
/// lookup rather than a complaint.
///
/// Selection is per step because "the 381 doesn't stop there any more" and
/// "this whole trip is nonsense" are different reports and want different
/// fixes. Selecting every step is recorded as the second kind.
class RouteReportScreen extends StatefulWidget {
  final Map<String, dynamic> option;
  final String startName;
  final String endName;

  const RouteReportScreen({
    super.key,
    required this.option,
    required this.startName,
    required this.endName,
  });

  @override
  State<RouteReportScreen> createState() => _RouteReportScreenState();
}

class _RouteReportScreenState extends State<RouteReportScreen> {
  final Set<int> _selected = {};
  final TextEditingController _comment = TextEditingController();
  RouteReportReason? _reason;
  bool _sending = false;

  /// Set only after a failed submit attempt, so the form doesn't scold the
  /// rider about empty fields before they've tried anything.
  String? _validationError;

  List<dynamic> get _steps => (widget.option['instructions'] as List?) ?? const [];

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  /// "I know a better way" and "something else" are useless without words:
  /// the reason chip alone says nothing actionable. The rest are
  /// self-describing, so a comment there stays optional.
  bool get _commentRequired =>
      _reason == RouteReportReason.betterRouteKnown || _reason == RouteReportReason.other;

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);

    if (_selected.isEmpty) {
      setState(() => _validationError = l10n.reportSelectSomething);
      return;
    }
    if (_reason == null) {
      setState(() => _validationError = l10n.reportPickReason);
      return;
    }
    if (_commentRequired && _comment.text.trim().isEmpty) {
      setState(() => _validationError = l10n.reportCommentRequired);
      return;
    }

    setState(() {
      _validationError = null;
      _sending = true;
    });

    final outcome = await RouteReportService.submit(
      option: widget.option,
      stepIndexes: _selected,
      reason: _reason!,
      comment: _comment.text,
      startName: widget.startName,
      endName: widget.endName,
      locale: Localizations.localeOf(context).languageCode,
    );

    if (!mounted) return;
    setState(() => _sending = false);

    final message = switch (outcome) {
      RouteReportOutcome.sent => l10n.reportSent,
      RouteReportOutcome.queuedOffline => l10n.reportQueued,
      RouteReportOutcome.notSignedIn => l10n.reportSignInRequired,
      RouteReportOutcome.failed => l10n.reportFailed,
    };

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );

    // A queued report is a delivered report from the rider's side -- it is
    // sitting in Firestore's outbox and will go out on its own. Keeping
    // them on the form to "try again" would only produce duplicates.
    if (outcome == RouteReportOutcome.sent || outcome == RouteReportOutcome.queuedOffline) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final allSelected = _steps.isNotEmpty && _selected.length == _steps.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.reportTitle,
          style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              children: [
                Text(
                  l10n.reportIntro,
                  style: TextStyle(color: context.textSecondary, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 20),

                // --- Which steps ---
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.reportWhichPart.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: context.textSecondary,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _steps.isEmpty
                          ? null
                          : () => setState(() {
                                if (allSelected) {
                                  _selected.clear();
                                } else {
                                  _selected
                                    ..clear()
                                    ..addAll(List.generate(_steps.length, (i) => i));
                                }
                              }),
                      child: Text(allSelected ? l10n.reportClearSelection : l10n.reportSelectAll),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                ..._steps.asMap().entries.map((e) => _stepTile(context, l10n, e.key, e.value as Map<String, dynamic>)),

                // Says out loud what selecting everything means, so the
                // rider knows they are filing "this whole trip is wrong"
                // rather than six separate step complaints.
                if (allSelected) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.info_outline, size: 15, color: context.textSecondary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          l10n.reportWholeRouteNote,
                          style: TextStyle(color: context.textSecondary, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 24),

                // --- Why ---
                Text(
                  l10n.reportReasonLabel.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: context.textSecondary,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final r in RouteReportReason.values)
                      ChoiceChip(
                        label: Text(_reasonLabel(l10n, r)),
                        selected: _reason == r,
                        onSelected: (_) => setState(() => _reason = r),
                        showCheckmark: false,
                        selectedColor: AppColors.primaryTeal,
                        backgroundColor: context.fieldFill,
                        labelStyle: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _reason == r ? Colors.white : context.textPrimary,
                        ),
                        side: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
                      ),
                  ],
                ),

                const SizedBox(height: 24),

                // --- Free text ---
                Text(
                  l10n.reportCommentLabel.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: context.textSecondary,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _comment,
                  minLines: 4,
                  maxLines: 7,
                  // Matches firestore.rules, so nothing a rider types here
                  // can be rejected by the server once it reaches signal.
                  maxLength: RouteReportService.maxCommentLength,
                  textCapitalization: TextCapitalization.sentences,
                  style: TextStyle(color: context.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: _reason == RouteReportReason.betterRouteKnown
                        ? l10n.reportCommentHintBetterRoute
                        : l10n.reportCommentHintGeneral,
                    hintStyle: TextStyle(color: context.textSecondary, fontSize: 13),
                    filled: true,
                    fillColor: context.fieldFill,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (_) {
                    if (_validationError != null) setState(() => _validationError = null);
                  },
                ),

                if (_validationError != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.error_outline, size: 16, color: Color(0xFFE76F51)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _validationError!,
                          style: const TextStyle(color: Color(0xFFE76F51), fontSize: 12.5),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
              ],
            ),
          ),

          // --- Send ---
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: context.surfaceCard,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: context.isDark ? 0.3 : 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _sending ? null : _submit,
                icon: _sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send_rounded, color: Colors.white),
                label: Text(
                  l10n.reportSubmit,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                  disabledBackgroundColor: AppColors.primaryTeal.withValues(alpha: 0.6),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _toggle(int index) => setState(() {
        if (!_selected.remove(index)) _selected.add(index);
        // Clear the "you didn't pick anything" nag the moment they do.
        _validationError = null;
      });

  Widget _stepTile(BuildContext context, AppLocalizations l10n, int index, Map<String, dynamic> step) {
    final iconKey = InstructionFormatter.iconKey(step);
    final checked = _selected.contains(index);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: context.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _toggle(index),
          child: Container(
            padding: const EdgeInsets.fromLTRB(8, 10, 14, 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: checked ? AppColors.primaryTeal : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Checkbox(
                  value: checked,
                  onChanged: (_) => _toggle(index),
                  activeColor: AppColors.primaryTeal,
                  visualDensity: VisualDensity.compact,
                ),
                Icon(TransitModes.icon(iconKey), size: 18, color: context.textSecondary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        InstructionFormatter.title(l10n, step),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: context.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        InstructionFormatter.subtitle(l10n, step),
                        style: TextStyle(color: context.textSecondary, fontSize: 12.5),
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

  String _reasonLabel(AppLocalizations l10n, RouteReportReason r) => switch (r) {
        RouteReportReason.routeDoesNotExist => l10n.reportReasonRouteDoesNotExist,
        RouteReportReason.wrongStop => l10n.reportReasonWrongStop,
        RouteReportReason.badTiming => l10n.reportReasonBadTiming,
        RouteReportReason.wrongFare => l10n.reportReasonWrongFare,
        RouteReportReason.betterRouteKnown => l10n.reportReasonBetterRoute,
        RouteReportReason.other => l10n.reportReasonOther,
      };
}
