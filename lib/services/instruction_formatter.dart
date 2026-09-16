import '../l10n/app_localizations.dart';
import 'transit_modes.dart';

/// Turns the backend's structured instruction/option data into localized
/// display text. This replaced an earlier approach that tried to
/// pattern-match pre-formatted English sentences from the backend via
/// regex -- fragile, and the reason turn-by-turn text used to silently
/// stay in English. Now the backend sends separate fields (action,
/// vehicle_type, route_number, route_description, station) and this
/// class is the only place that turns them into a sentence, in
/// whichever language the app is currently in.
class InstructionFormatter {
  /// Delegates to [TransitModes] so the label, the icon and the colour for
  /// a vehicle_type all come from one table. Kept as a method here because
  /// several screens already call it by this name.
  static String vehicleTypeLabel(AppLocalizations l10n, String? vehicleType) =>
      TransitModes.label(l10n, vehicleType);

  /// The route-identifying part of a "board"/"transfer" instruction:
  /// prefers a real route number ("Bus 27") over a generic vehicle-type
  /// + corridor description ("Microbus towards Nahda City") when no
  /// number is available in the source data.
  static String _routeLabel(AppLocalizations l10n, Map<String, dynamic> instr) {
    final vehicleLabel = vehicleTypeLabel(l10n, instr['vehicle_type']);
    final routeNumber = instr['route_number'];
    final routeDescription = instr['route_description'];

    if (routeNumber != null && routeNumber.toString().isNotEmpty) {
      return l10n.instrBoardWithNumber(vehicleLabel, routeNumber.toString());
    }
    if (routeDescription != null && routeDescription.toString().isNotEmpty) {
      return l10n.instrBoardGeneral(vehicleLabel, routeDescription.toString());
    }
    return vehicleLabel;
  }

  static String title(AppLocalizations l10n, Map<String, dynamic> instr) {
    final action = instr['action'];
    switch (action) {
      case 'walk_to_station':
        return l10n.instrWalkToStationTitle;
      case 'walk_to_transfer':
        return l10n.instrWalkToTransferTitle;
      case 'continue_walk':
        return l10n.instrContinueWalkTitle;
      case 'board':
        return l10n.instrBoardTitleWithVehicle(vehicleTypeLabel(l10n, instr['vehicle_type']));
      case 'transfer':
        return l10n.instrTransferTitle;
      case 'arrive':
        return l10n.instrArriveTitle;
      case 'walk_to_destination':
        return l10n.instrWalkToDestinationTitle;
      default:
        return '';
    }
  }

  static String subtitle(AppLocalizations l10n, Map<String, dynamic> instr) {
    final action = instr['action'];
    final station = instr['station']?.toString() ?? '';
    switch (action) {
      case 'walk_to_station':
        return l10n.instrWalkToStationSubtitle((instr['distance_m'] ?? 0).toString(), station);
      case 'walk_to_transfer':
        return l10n.instrWalkToTransferSubtitle(station);
      case 'continue_walk':
        return l10n.instrContinueWalkSubtitle;
      case 'board':
      case 'transfer':
        return _routeLabel(l10n, instr);
      case 'arrive':
        return l10n.instrArriveSubtitle(station);
      case 'walk_to_destination':
        return l10n.instrWalkToDestinationSubtitle((instr['distance_m'] ?? 0).toString());
      default:
        return '';
    }
  }

  /// Icon-selection key ("walk" / "transfer" / "arrive" / vehicle type)
  /// so screens don't each re-derive this from raw strings.
  static String iconKey(Map<String, dynamic> instr) {
    final action = instr['action'];
    if (action == 'walk_to_station' || action == 'walk_to_transfer' || action == 'continue_walk' || action == 'walk_to_destination') {
      return 'walk';
    }
    if (action == 'transfer') return 'transfer';
    if (action == 'arrive') return 'arrive';
    return instr['vehicle_type']?.toString() ?? 'bus';
  }

  static String routeTierLabel(AppLocalizations l10n, String tier) {
    switch (tier) {
      case 'Recommended':
        return l10n.routeTierRecommended;
      case 'Fastest':
        return l10n.routeTierFastest;
      case 'Regular':
        return l10n.routeTierRegular;
      case 'Cheapest':
        return l10n.routeTierCheapest;
      case 'Alternative':
        return l10n.routeTierAlternative;
      case 'Walk':
        return l10n.routeTierWalk;
      // Not a tier like the others: this is what the engine returns when
      // it could not reach the destination at all and fell back to the
      // closest stop it can reach. Labelled so the card cannot be
      // mistaken for a complete route -- the accompanying banner in
      // RouteOptionsScreen says exactly what is missing.
      case 'Partial':
        return l10n.routeTierPartial;
      default:
        return tier;
    }
  }

  static String crowdLabel(AppLocalizations l10n, String traffic) {
    switch (traffic) {
      case 'Low':
        return l10n.crowdLow;
      case 'Medium':
        return l10n.crowdMedium;
      case 'High':
        return l10n.crowdHigh;
      default:
        return traffic;
    }
  }

  /// Short summary used on the route-option card, e.g. "Minibus 302" or
  /// "Microbus towards Nahda City" or just "Walk" for a walking-only option.
  static String optionSummary(AppLocalizations l10n, Map<String, dynamic> option) {
    final vehicleType = option['vehicle_type'];
    if (vehicleType == 'walk' || vehicleType == null) {
      return vehicleTypeLabel(l10n, 'walk');
    }
    final vehicleLabel = vehicleTypeLabel(l10n, vehicleType);
    final routeNumber = option['route_number'];
    if (routeNumber != null && routeNumber.toString().isNotEmpty) {
      return l10n.instrBoardWithNumber(vehicleLabel, routeNumber.toString());
    }
    final routeDesc = option['route_description'] ?? option['routeDescription'];
    if (routeDesc != null && routeDesc.toString().trim().isNotEmpty) {
      final desc = routeDesc.toString().trim();
      if (desc.toLowerCase().startsWith(vehicleLabel.toLowerCase())) {
        return desc;
      }
      return '$vehicleLabel • $desc';
    }
    return vehicleLabel;
  }

  /// The fare on a route option, localized.
  ///
  /// The backend also sends a pre-formatted `price` string ("20 EGP",
  /// "Free"), which is English whatever language the app is in -- it was
  /// the reason a fare stayed in English on an otherwise Arabic screen.
  /// Safely converts dynamic values (num, string representations of numbers) to num.
  static num? asNum(dynamic val) {
    if (val == null) return null;
    if (val is num) return val;
    if (val is String) return num.tryParse(val.trim());
    return null;
  }

  /// Prefer the numbers and format them here; fall back to that string
  /// only if an older backend is on the other end and sends neither.
  static String fareText(AppLocalizations l10n, Map<String, dynamic> option) {
    final total = option['fare_total_egp'] ?? option['fare_egp'];
    if (total != null) {
      final n = asNum(total);
      if (n != null) {
        return n == 0 ? l10n.fareFree : l10n.fareEgp(_trimZero(n));
      }
    }
    if (option['vehicle_type'] == 'walk') return l10n.fareFree;
    return option['price']?.toString() ?? '-';
  }

  /// Turns the backend's stable error `code` into a localized sentence.
  ///
  /// The server also sends an English `message`. That is a fallback for a
  /// code this build doesn't know yet, not the normal path -- showing it is
  /// how English sentences appeared on Arabic screens.
  static String errorMessage(AppLocalizations l10n, Map<String, dynamic> data) {
    switch (data['error_code']) {
      case 'network':
        return l10n.serverUnreachable;
      case 'outside_coverage':
        return l10n.errorOutsideCoverage;
      case 'outside_service_hours':
        return l10n.errorNoServiceThisHour;
      case 'no_coverage':
      case 'no_route_found':
        return l10n.errorNoRouteFound;
    }
    final message = data['error'];
    if (message is String && message.isNotEmpty) return message;
    return l10n.routeCalculationFailed;
  }

  static String _trimZero(num n) =>
      n == n.roundToDouble() ? n.round().toString() : n.toString();
}
