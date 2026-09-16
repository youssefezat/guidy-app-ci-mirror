import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  /// The backend's `nearest_hubs` for a coverage failure, or null. Naming
  /// the closest point the network actually reaches is the difference
  /// between "this app is broken" and "this app doesn't go there yet",
  /// and it gives the rider somewhere to aim for on their own.
  final Map<String, dynamic>? nearestHubs;

  /// Shown only where reporting makes sense (a failed route calculation).
  /// Retry alone is a dead end here: retrying an uncovered trip returns
  /// the identical failure, so the only useful action left is telling us
  /// what is missing.
  final VoidCallback? onReportMissing;

  const ErrorState({
    super.key,
    required this.message,
    required this.onRetry,
    this.nearestHubs,
    this.onReportMissing,
  });

  String? _hubsLine(AppLocalizations l10n) {
    final hubs = nearestHubs;
    if (hubs == null) return null;
    final origin = (hubs['from_origin'] as Map?)?['name'] as String?;
    final destination = (hubs['from_destination'] as Map?)?['name'] as String?;
    if (origin == null || destination == null) return null;
    return l10n.nearestHubsHint(origin, destination);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 48, color: context.textSecondary),
            const SizedBox(height: 16),
            Text(
              l10n.somethingWentWrongTitle,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: TextStyle(fontSize: 13, color: context.textSecondary),
              textAlign: TextAlign.center,
            ),
            if (_hubsLine(l10n) case final String hubs) ...[
              const SizedBox(height: 10),
              Text(
                hubs,
                style: TextStyle(fontSize: 13, color: context.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.retryButton),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryTeal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            if (onReportMissing != null) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: onReportMissing,
                icon: const Icon(Icons.add_road_rounded, size: 18),
                label: Text(l10n.reportMissingRouteButton),
                style: TextButton.styleFrom(foregroundColor: AppColors.primaryTeal),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
