import 'package:flutter_test/flutter_test.dart';
import 'package:guidy_app/services/commute_budget_service.dart';

void main() {
  test('CommuteBudgetService tier mapping', () {
    expect(CommuteBudgetService.tierForStations(5).minStations, equals(1));
    expect(CommuteBudgetService.tierForStations(5).maxStations, equals(9));
    expect(CommuteBudgetService.tierForStations(12).minStations, equals(10));
    expect(CommuteBudgetService.tierForStations(12).maxStations, equals(16));
    expect(CommuteBudgetService.tierForStations(20).maxStations, equals(23));
    expect(CommuteBudgetService.tierForStations(30).minStations, equals(24));
  });

  test('CommuteBudgetService monthly trips calculation', () {
    // 5 days a week * 4.4 weeks * 2 trips/day = ~44 trips
    final trips = CommuteBudgetService.monthlyTrips(5);
    expect(trips, equals(44));
  });

  test('CommuteBudgetService single ticket fares and subscription savings', () {
    expect(CommuteBudgetService.singleTicketFareForStations(5), equals(10));
    expect(CommuteBudgetService.singleTicketFareForStations(12), equals(12));
    expect(CommuteBudgetService.singleTicketFareForStations(20), equals(15));
    expect(CommuteBudgetService.singleTicketFareForStations(30), equals(20));

    // 5 days/week, 12 EGP ticket (10-16 stations, Stage 2 sub = 440 EGP)
    final singleCost = CommuteBudgetService.monthlySingleTicketCost(
      singleTripFareEgp: 12,
      daysPerWeek: 5,
    );
    expect(singleCost, equals(44 * 12)); // 528 EGP

    final savingsPublic = CommuteBudgetService.calculateMonthlySavings(
      metroSingleFareEgp: 12,
      metroStationsCount: 14,
      daysPerWeek: 5,
      commuterType: CommuterType.public,
    );
    // 528 - 440 = 88 EGP savings
    expect(savingsPublic, equals(88));

    final savingsStudent = CommuteBudgetService.calculateMonthlySavings(
      metroSingleFareEgp: 12,
      metroStationsCount: 14,
      daysPerWeek: 5,
      commuterType: CommuterType.student,
    );
    // Student subscription is 200 EGP quarterly (~67 EGP/month) -> 528 - 67 = 461 EGP savings
    expect(savingsStudent, greaterThan(400));
  });

  test('MetroSubscriptionTier localizedStageName bilingual support', () {
    final stage1 = CommuteBudgetService.tierForStations(5);
    expect(stage1.localizedStageName(true), contains('مرحلة واحدة'));
    expect(stage1.localizedStageName(false), contains('Stage 1'));

    final stage2 = CommuteBudgetService.tierForStations(14);
    expect(stage2.localizedStageName(true), contains('مرحلتين'));
    expect(stage2.localizedStageName(false), contains('Stage 2'));
  });
}
