import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guidy_app/l10n/app_localizations.dart';
import 'package:guidy_app/services/instruction_formatter.dart';


void main() {
  // ──────────────────────────────────────────────────────────────────────
  // asNum — pure logic, no localization needed
  // ──────────────────────────────────────────────────────────────────────
  group('asNum', () {
    test('null returns null', () {
      expect(InstructionFormatter.asNum(null), isNull);
    });

    test('int returns int', () {
      expect(InstructionFormatter.asNum(42), equals(42));
    });

    test('double returns double', () {
      expect(InstructionFormatter.asNum(3.14), equals(3.14));
    });

    test('valid numeric string returns num', () {
      expect(InstructionFormatter.asNum('20'), equals(20));
      expect(InstructionFormatter.asNum(' 3.5 '), equals(3.5));
    });

    test('invalid string returns null', () {
      expect(InstructionFormatter.asNum('abc'), isNull);
      expect(InstructionFormatter.asNum(''), isNull);
    });

    test('non-string non-num returns null', () {
      expect(InstructionFormatter.asNum(true), isNull);
    });
  });

  // ──────────────────────────────────────────────────────────────────────
  // Tests that need AppLocalizations
  // ──────────────────────────────────────────────────────────────────────
  group('InstructionFormatter with localization', () {
    late AppLocalizations l10n;

    setUp(() async {
      l10n = await AppLocalizations.delegate.load(const Locale('en'));
    });

    // ── iconKey ──────────────────────────────────────────────────────────
    group('iconKey', () {
      test('walk actions return "walk"', () {
        for (final action in [
          'walk_to_station',
          'walk_to_transfer',
          'continue_walk',
          'walk_to_destination',
        ]) {
          expect(InstructionFormatter.iconKey({'action': action}), 'walk');
        }
      });

      test('transfer returns "transfer"', () {
        expect(InstructionFormatter.iconKey({'action': 'transfer'}), 'transfer');
      });

      test('arrive returns "arrive"', () {
        expect(InstructionFormatter.iconKey({'action': 'arrive'}), 'arrive');
      });

      test('board returns vehicle_type', () {
        expect(
          InstructionFormatter.iconKey({'action': 'board', 'vehicle_type': 'metro'}),
          'metro',
        );
      });

      test('board with null vehicle_type defaults to bus', () {
        expect(InstructionFormatter.iconKey({'action': 'board'}), 'bus');
      });
    });

    // ── routeTierLabel ──────────────────────────────────────────────────
    group('routeTierLabel', () {
      test('maps all known tiers', () {
        final knownTiers = [
          'Recommended', 'Fastest', 'Regular', 'Cheapest',
          'Alternative', 'Walk', 'Partial',
        ];
        for (final tier in knownTiers) {
          final label = InstructionFormatter.routeTierLabel(l10n, tier);
          expect(label, isNotEmpty, reason: '$tier should produce a non-empty label');
          // Known tiers should NOT return the raw tier string unchanged
          // (they should be localized)
        }
      });

      test('unknown tier returns raw string', () {
        expect(InstructionFormatter.routeTierLabel(l10n, 'SomeFutureTier'), 'SomeFutureTier');
      });
    });

    // ── fareText ────────────────────────────────────────────────────────
    group('fareText', () {
      test('numeric fare_total_egp formats as EGP', () {
        final text = InstructionFormatter.fareText(l10n, {'fare_total_egp': 15});
        expect(text, contains('15'));
      });

      test('zero fare shows free', () {
        final text = InstructionFormatter.fareText(l10n, {'fare_total_egp': 0});
        expect(text, equals(l10n.fareFree));
      });

      test('string fare is parsed', () {
        final text = InstructionFormatter.fareText(l10n, {'fare_total_egp': '20'});
        expect(text, contains('20'));
      });

      test('walk option is free', () {
        final text = InstructionFormatter.fareText(l10n, {'vehicle_type': 'walk'});
        expect(text, equals(l10n.fareFree));
      });

      test('fallback to price string', () {
        final text = InstructionFormatter.fareText(l10n, {'price': '10 EGP'});
        expect(text, equals('10 EGP'));
      });

      test('null everything returns dash', () {
        final text = InstructionFormatter.fareText(l10n, {});
        expect(text, equals('-'));
      });

      test('fare_egp is used as fallback key', () {
        final text = InstructionFormatter.fareText(l10n, {'fare_egp': 8});
        expect(text, contains('8'));
      });
    });

    // ── title ───────────────────────────────────────────────────────────
    group('title', () {
      test('known actions return non-empty strings', () {
        final actions = [
          'walk_to_station', 'walk_to_transfer', 'continue_walk',
          'board', 'transfer', 'arrive', 'walk_to_destination',
        ];
        for (final a in actions) {
          final t = InstructionFormatter.title(l10n, {'action': a, 'vehicle_type': 'bus'});
          expect(t, isNotEmpty, reason: 'title for "$a" should not be empty');
        }
      });

      test('unknown action returns empty string', () {
        expect(InstructionFormatter.title(l10n, {'action': 'unknown'}), isEmpty);
      });
    });

    // ── subtitle ────────────────────────────────────────────────────────
    group('subtitle', () {
      test('walk_to_station includes station name', () {
        final sub = InstructionFormatter.subtitle(l10n, {
          'action': 'walk_to_station',
          'station': 'Sadat',
          'distance_m': 200,
        });
        expect(sub, contains('Sadat'));
      });

      test('board returns route label', () {
        final sub = InstructionFormatter.subtitle(l10n, {
          'action': 'board',
          'vehicle_type': 'bus',
          'route_number': '27',
        });
        expect(sub, contains('27'));
      });

      test('arrive includes station', () {
        final sub = InstructionFormatter.subtitle(l10n, {
          'action': 'arrive',
          'station': 'Tahrir',
        });
        expect(sub, contains('Tahrir'));
      });

      test('unknown action returns empty string', () {
        expect(InstructionFormatter.subtitle(l10n, {'action': 'xyz'}), isEmpty);
      });
    });

    // ── optionSummary ───────────────────────────────────────────────────
    group('optionSummary', () {
      test('walk option returns walk label', () {
        final summary = InstructionFormatter.optionSummary(l10n, {'vehicle_type': 'walk'});
        expect(summary, equals(InstructionFormatter.vehicleTypeLabel(l10n, 'walk')));
      });

      test('with route_number includes number', () {
        final summary = InstructionFormatter.optionSummary(l10n, {
          'vehicle_type': 'bus',
          'route_number': '302',
        });
        expect(summary, contains('302'));
      });

      test('with description only', () {
        final summary = InstructionFormatter.optionSummary(l10n, {
          'vehicle_type': 'microbus',
          'route_description': 'Nahda City',
        });
        expect(summary, contains('Nahda City'));
      });

      test('null vehicle_type returns walk label', () {
        final summary = InstructionFormatter.optionSummary(l10n, {});
        expect(summary, equals(InstructionFormatter.vehicleTypeLabel(l10n, 'walk')));
      });
    });

    // ── errorMessage ────────────────────────────────────────────────────
    group('errorMessage', () {
      test('maps known error codes', () {
        expect(InstructionFormatter.errorMessage(l10n, {'error_code': 'network'}),
            equals(l10n.serverUnreachable));
        expect(InstructionFormatter.errorMessage(l10n, {'error_code': 'outside_coverage'}),
            equals(l10n.errorOutsideCoverage));
        expect(InstructionFormatter.errorMessage(l10n, {'error_code': 'outside_service_hours'}),
            equals(l10n.errorNoServiceThisHour));
        expect(InstructionFormatter.errorMessage(l10n, {'error_code': 'no_coverage'}),
            equals(l10n.errorNoRouteFound));
        expect(InstructionFormatter.errorMessage(l10n, {'error_code': 'no_route_found'}),
            equals(l10n.errorNoRouteFound));
      });

      test('unknown code with error string returns the string', () {
        expect(InstructionFormatter.errorMessage(l10n, {'error': 'Something broke'}),
            equals('Something broke'));
      });

      test('unknown code with no error string returns generic message', () {
        expect(InstructionFormatter.errorMessage(l10n, {}),
            equals(l10n.routeCalculationFailed));
      });
    });
  });
}
