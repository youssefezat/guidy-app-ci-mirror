import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

/// One place that knows what each vehicle_type looks like.
///
/// This exists because adding the monorail, the LRT and the airport
/// shuttle meant touching FOUR separate copies of the same switch --
/// TripRecapScreen._vehicleIcon, TripRecapScreen._stepIcon,
/// MapScreen._stepIcon and RouteOptionsScreen's inline one -- each of
/// which silently fell through to a bus icon for anything it didn't
/// recognise. Three of the four would have kept showing a bus for the
/// monorail and nobody would have seen an error, because a `default:`
/// branch is not a compile failure.
///
/// The backend is the source of these strings; they arrive as
/// `vehicle_type` on every instruction and route. Keep this list in step
/// with AGENCY_VEHICLE_TYPES / ROUTE_TYPE_VEHICLE_TYPES in
/// raptor_engine.py.
class TransitModes {
  TransitModes._();

  /// Rail modes, in the order they should appear in a filter row.
  static const List<String> rail = ['metro', 'monorail', 'lrt'];

  /// Every mode the Lines browser offers as a filter chip, `null` first
  /// for "all". The airport shuttle is deliberately absent: it is four
  /// stops inside one airport, and giving it equal billing with the metro
  /// in a city-wide browser would be misleading about what it is.
  static const List<String?> browsableFilters = [
    null, 'bus', 'minibus', 'microbus', 'metro', 'monorail', 'lrt',
  ];

  static IconData icon(String? vehicleType) {
    switch (vehicleType) {
      case 'metro':
        return Icons.directions_subway;
      // Flutter's stable channel has no `Icons.monorail` -- verified
      // against packages/flutter/lib/src/material/icons.dart, where every
      // other icon named here is present and that one is not. `tram` is
      // used instead: a single elevated car is the closest available
      // reading of a straddle-beam monorail, and it stays visually
      // distinct from the metro's `directions_subway`, which matters
      // because the two meet at Cairo Stadium. `directions_transit` was
      // the obvious alternative and was rejected -- Material draws it as
      // the same train front as `directions_subway`, so the metro and the
      // monorail would have been indistinguishable in an itinerary.
      case 'monorail':
        return Icons.tram;
      case 'lrt':
        return Icons.train;
      case 'tram':
        return Icons.directions_railway;
      case 'apm':
        return Icons.local_airport;
      case 'minibus':
        return Icons.directions_bus_filled;
      case 'microbus':
        return Icons.airport_shuttle;
      case 'walk':
        return Icons.directions_walk;
      case 'transfer':
        return Icons.swap_horiz;
      case 'arrive':
        return Icons.flag;
      default:
        return Icons.directions_bus;
    }
  }

  /// Matches _get_route_color in raptor_engine.py. The monorail and the
  /// LRT are deliberately NOT the metro's blue: they meet the metro at
  /// Adly Mansour and Cairo Stadium, and a rider looking at an itinerary
  /// has to be able to tell which of the three they are boarding.
  static Color color(String? vehicleType) {
    switch (vehicleType) {
      case 'metro':
        return AppColors.primaryTeal;
      case 'monorail':
        return const Color(0xFF9C6DC2);
      case 'lrt':
        return const Color(0xFF4DA89B);
      case 'tram':
        return const Color(0xFFC2A76D);
      case 'apm':
        return const Color(0xFF8895A0);
      case 'minibus':
        return const Color(0xFFD4A373);
      case 'microbus':
        return const Color(0xFFC77DFF);
      case 'walk':
        return const Color(0xFF83C5BE);
      default:
        return const Color(0xFFE29578);
    }
  }

  static String colorHex(String? vehicleType) {
    final c = color(vehicleType);
    return '#${c.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
  }

  static String label(AppLocalizations l10n, String? vehicleType) {
    switch (vehicleType) {
      case 'bus':
        return l10n.vehicleBus;
      case 'minibus':
        return l10n.vehicleMinibus;
      case 'microbus':
        return l10n.vehicleMicrobus;
      case 'metro':
        return l10n.vehicleMetro;
      case 'monorail':
        return l10n.vehicleMonorail;
      case 'lrt':
        return l10n.vehicleLrt;
      case 'tram':
        return l10n.vehicleTram;
      case 'apm':
        return l10n.vehicleAirportShuttle;
      case 'walk':
        return l10n.vehicleWalk;
      default:
        return l10n.vehicleBus;
    }
  }

  /// True for modes that run on their own right of way and are boarded at
  /// a named station -- used where the UI needs to say "station" rather
  /// than "stop", and to pick a station icon over a kerbside one.
  static bool isRail(String? vehicleType) =>
      vehicleType == 'metro' ||
      vehicleType == 'monorail' ||
      vehicleType == 'lrt' ||
      vehicleType == 'tram' ||
      vehicleType == 'apm';
}
