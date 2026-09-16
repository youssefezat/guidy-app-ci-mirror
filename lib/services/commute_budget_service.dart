/// User commuter category for Egyptian transit subscriptions.
enum CommuterType {
  public,
  student,
  senior,
}

/// Information about a Cairo Metro subscription tier.
class MetroSubscriptionTier {
  final String stageName;
  final String stageNameEn;
  final int minStations;
  final int maxStations;
  final int monthlyPublicPrice;
  final int quarterlyPublicPrice;
  final int quarterlyStudentPrice;
  final int quarterlySeniorPrice;

  const MetroSubscriptionTier({
    required this.stageName,
    this.stageNameEn = '',
    required this.minStations,
    required this.maxStations,
    required this.monthlyPublicPrice,
    required this.quarterlyPublicPrice,
    required this.quarterlyStudentPrice,
    required this.quarterlySeniorPrice,
  });

  String localizedStageName(bool isArabic) {
    if (isArabic || stageNameEn.isEmpty) return stageName;
    return stageNameEn;
  }

  int monthlyEquivalent(CommuterType type) {
    switch (type) {
      case CommuterType.public:
        return monthlyPublicPrice;
      case CommuterType.student:
        return (quarterlyStudentPrice / 3).round();
      case CommuterType.senior:
        return (quarterlySeniorPrice / 3).round();
    }
  }
}

/// Service calculating commute expenses and Cairo Metro subscription savings.
class CommuteBudgetService {
  static const List<MetroSubscriptionTier> tiers = [
    MetroSubscriptionTier(
      stageName: 'مرحلة واحدة (منطقة واحدة)',
      stageNameEn: 'Stage 1 (1 zone, up to 9 stations)',
      minStations: 1,
      maxStations: 9,
      monthlyPublicPrice: 390,
      quarterlyPublicPrice: 1050,
      quarterlyStudentPrice: 150,
      quarterlySeniorPrice: 525,
    ),
    MetroSubscriptionTier(
      stageName: 'مرحلتين (منطقتين)',
      stageNameEn: 'Stage 2 (2 zones, 10-16 stations)',
      minStations: 10,
      maxStations: 16,
      monthlyPublicPrice: 440,
      quarterlyPublicPrice: 1200,
      quarterlyStudentPrice: 200,
      quarterlySeniorPrice: 600,
    ),
    MetroSubscriptionTier(
      stageName: 'ثلاث أو أربع مراحل',
      stageNameEn: 'Stage 3 (3-4 zones, 17-23 stations)',
      minStations: 17,
      maxStations: 23,
      monthlyPublicPrice: 510,
      quarterlyPublicPrice: 1380,
      quarterlyStudentPrice: 250,
      quarterlySeniorPrice: 690,
    ),
    MetroSubscriptionTier(
      stageName: 'أكثر من أربع مراحل (كل الخطوط)',
      stageNameEn: 'Stage 4 (All lines, 24+ stations)',
      minStations: 24,
      maxStations: 99,
      monthlyPublicPrice: 600,
      quarterlyPublicPrice: 1620,
      quarterlyStudentPrice: 300,
      quarterlySeniorPrice: 810,
    ),
  ];

  /// Returns official single ticket fare in EGP for a given number of metro stations.
  /// Official Cairo Metro tariff:
  /// - 1 to 9 stations: 10 EGP
  /// - 10 to 16 stations: 12 EGP
  /// - 17 to 23 stations: 15 EGP
  /// - 24+ stations: 20 EGP
  static int singleTicketFareForStations(int stations) {
    if (stations <= 9) return 10;
    if (stations <= 16) return 12;
    if (stations <= 23) return 15;
    return 20;
  }

  /// Finds the subscription tier for a given number of metro stations.
  static MetroSubscriptionTier tierForStations(int stations) {
    for (final tier in tiers) {
      if (stations <= tier.maxStations) return tier;
    }
    return tiers.last;
  }

  /// Calculates total monthly commute trips for a given number of commute days per week.
  static int monthlyTrips(int daysPerWeek) {
    final clamped = daysPerWeek.clamp(1, 7);
    return (clamped * 4.4 * 2).round(); // round trips
  }

  /// Calculates single-ticket monthly cost.
  static int monthlySingleTicketCost({
    required int singleTripFareEgp,
    required int daysPerWeek,
  }) {
    final trips = monthlyTrips(daysPerWeek);
    return trips * singleTripFareEgp;
  }

  /// Calculates net monthly savings from subscribing to Cairo Metro.
  static int calculateMonthlySavings({
    required int metroSingleFareEgp,
    required int metroStationsCount,
    required int daysPerWeek,
    CommuterType commuterType = CommuterType.public,
  }) {
    final ticketCost = monthlySingleTicketCost(
      singleTripFareEgp: metroSingleFareEgp,
      daysPerWeek: daysPerWeek,
    );
    final tier = tierForStations(metroStationsCount);
    final subCost = tier.monthlyEquivalent(commuterType);
    final savings = ticketCost - subCost;
    return savings > 0 ? savings : 0;
  }

  /// Major metro offices issuing commuter smart cards (structured with coordinates).
  static const List<MetroSubscriptionOffice> subscriptionOffices = [
    MetroSubscriptionOffice(
      stationNameAr: 'العتبة',
      stationNameEn: 'Attaba',
      linesAr: 'الخط الثاني والثالث',
      linesEn: 'Lines 2 & 3',
      lat: 30.0526,
      lon: 31.2468,
    ),
    MetroSubscriptionOffice(
      stationNameAr: 'الشهداء',
      stationNameEn: 'Al-Shohadaa (Ramses)',
      linesAr: 'الخط الأول والثاني',
      linesEn: 'Lines 1 & 2',
      lat: 30.0617,
      lon: 31.2497,
    ),
    MetroSubscriptionOffice(
      stationNameAr: 'أنور السادات',
      stationNameEn: 'Sadat (Tahrir)',
      linesAr: 'الخط الأول والثاني',
      linesEn: 'Lines 1 & 2',
      lat: 30.0444,
      lon: 31.2357,
    ),
    MetroSubscriptionOffice(
      stationNameAr: 'عدلي منصور',
      stationNameEn: 'Adly Mansour',
      linesAr: 'الخط الثالث والقطار الخفيف LRT',
      linesEn: 'Line 3 & LRT Capital Train',
      lat: 30.1478,
      lon: 31.4218,
    ),
    MetroSubscriptionOffice(
      stationNameAr: 'جامعة القاهرة',
      stationNameEn: 'Cairo University',
      linesAr: 'الخط الثاني والثالث',
      linesEn: 'Lines 2 & 3',
      lat: 30.0267,
      lon: 31.2012,
    ),
    MetroSubscriptionOffice(
      stationNameAr: 'حلوان',
      stationNameEn: 'Helwan',
      linesAr: 'الخط الأول',
      linesEn: 'Line 1',
      lat: 29.8490,
      lon: 31.3340,
    ),
    MetroSubscriptionOffice(
      stationNameAr: 'شبرا الخيمة',
      stationNameEn: 'Shubra El-Kheima',
      linesAr: 'الخط الثاني',
      linesEn: 'Line 2',
      lat: 30.1226,
      lon: 31.2450,
    ),
    MetroSubscriptionOffice(
      stationNameAr: 'عين شمس',
      stationNameEn: 'Ain Shams',
      linesAr: 'الخط الأول',
      linesEn: 'Line 1',
      lat: 30.1311,
      lon: 31.3197,
    ),
    MetroSubscriptionOffice(
      stationNameAr: 'الجيزة',
      stationNameEn: 'Giza',
      linesAr: 'الخط الثاني',
      linesEn: 'Line 2',
      lat: 30.0107,
      lon: 31.2071,
    ),
  ];

  /// Major metro offices issuing commuter smart cards (string titles for backwards compatibility).
  static const List<String> metroOffices = [
    'العتبة (الخط الثاني والثالث)',
    'الشهداء (الخط الأول والثاني)',
    'عدلي منصور (الخط الثالث والقطار الخفيف)',
    'أنور السادات (الخط الأول والثاني)',
    'جامعة القاهرة (الخط الثاني والثالث)',
    'حلوان (الخط الأول)',
    'شبرا الخيمة (الخط الثاني)',
  ];
}

/// A Cairo Metro subscription office location with coordinates and operating hours.
class MetroSubscriptionOffice {
  final String stationNameAr;
  final String stationNameEn;
  final String linesAr;
  final String linesEn;
  final double lat;
  final double lon;
  final String hoursAr;
  final String hoursEn;

  const MetroSubscriptionOffice({
    required this.stationNameAr,
    required this.stationNameEn,
    required this.linesAr,
    required this.linesEn,
    required this.lat,
    required this.lon,
    this.hoursAr = 'من 7:00 ص إلى 4:00 م يومياً',
    this.hoursEn = '7:00 AM – 4:00 PM daily',
  });

  String localizedName(bool isArabic) => isArabic ? stationNameAr : stationNameEn;
  String localizedLines(bool isArabic) => isArabic ? linesAr : linesEn;
  String localizedHours(bool isArabic) => isArabic ? hoursAr : hoursEn;
}
