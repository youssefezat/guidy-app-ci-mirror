import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import '../l10n/app_localizations.dart';
import '../services/commute_budget_service.dart';
import '../theme/app_theme.dart';
import 'RouteOptionsScreen.dart';

/// Screen allowing commuters to calculate monthly transit expenses and
/// compare them with Cairo Metro commuter subscriptions.
class CommuteBudgetScreen extends StatefulWidget {
  final int initialSingleFareEgp;
  final int initialStationsCount;

  const CommuteBudgetScreen({
    super.key,
    this.initialSingleFareEgp = 12,
    this.initialStationsCount = 14,
  });

  @override
  State<CommuteBudgetScreen> createState() => _CommuteBudgetScreenState();
}

class _CommuteBudgetScreenState extends State<CommuteBudgetScreen> {
  late int _singleTripFare;
  late int _stationsCount;
  int _daysPerWeek = 5;
  CommuterType _commuterType = CommuterType.public;
  bool _routingOffice = false;

  @override
  void initState() {
    super.initState();
    _singleTripFare = widget.initialSingleFareEgp;
    _stationsCount = widget.initialStationsCount;
  }

  Future<void> _routeToOffice(MetroSubscriptionOffice office, bool isArabic) async {
    if (_routingOffice) return;
    setState(() => _routingOffice = true);

    double startLat = 30.0444; // Default to Cairo center (Tahrir)
    double startLon = 31.2357;
    String startName = isArabic ? 'موقعي الحالي' : 'My Current Location';

    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 4),
        ),
      );
      startLat = pos.latitude;
      startLon = pos.longitude;
    } catch (_) {
      try {
        final last = await Geolocator.getLastKnownPosition();
        if (last != null) {
          startLat = last.latitude;
          startLon = last.longitude;
        }
      } catch (_) {}
    } finally {
      if (mounted) {
        setState(() => _routingOffice = false);
      }
    }

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RouteOptionsScreen(
          startLat: startLat,
          startLon: startLon,
          startName: startName,
          endLat: office.lat,
          endLon: office.lon,
          endName: isArabic
              ? 'مكتب اشتراكات مترو ${office.stationNameAr}'
              : 'Metro Subscription Office (${office.stationNameEn})',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = context.isDark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    final monthlyTrips = CommuteBudgetService.monthlyTrips(_daysPerWeek);
    final monthlyTicketCost = CommuteBudgetService.monthlySingleTicketCost(
      singleTripFareEgp: _singleTripFare,
      daysPerWeek: _daysPerWeek,
    );

    final tier = CommuteBudgetService.tierForStations(_stationsCount);
    final subCostPerMonth = tier.monthlyEquivalent(_commuterType);
    final monthlySavings = CommuteBudgetService.calculateMonthlySavings(
      metroSingleFareEgp: _singleTripFare,
      metroStationsCount: _stationsCount,
      daysPerWeek: _daysPerWeek,
      commuterType: _commuterType,
    );
    final savingsPercent = monthlyTicketCost > 0
        ? ((monthlySavings / monthlyTicketCost) * 100).round()
        : 0;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.budgetTitle,
          style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Header Hero Banner
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: AppColors.brandGradient,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 28),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.budgetScreenHeader,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  l10n.budgetSingleTicketsMonthly,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '$monthlyTicketCost',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isArabic ? 'ج.م / شهرياً' : 'EGP / month',
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        isArabic ? '$monthlyTrips مشوار' : '$monthlyTrips trips',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // How it Works Educational Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2630) : const Color(0xFFEBF5FB),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primaryTeal.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline_rounded, color: AppColors.primaryTeal, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.budgetHowItWorksTitle,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: context.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.budgetHowItWorksBody,
                        style: TextStyle(fontSize: 12, color: context.textSecondary, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Commuter Type Segmented Selector
          Text(
            l10n.budgetCommuterCategory,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: context.textSecondary),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<CommuterType>(
              segments: [
                ButtonSegment(
                  value: CommuterType.public,
                  label: Text(l10n.subTierPublic, style: const TextStyle(fontSize: 12)),
                  icon: const Icon(Icons.person_rounded, size: 16),
                ),
                ButtonSegment(
                  value: CommuterType.student,
                  label: Text(l10n.subTierStudents, style: const TextStyle(fontSize: 12)),
                  icon: const Icon(Icons.school_rounded, size: 16),
                ),
                ButtonSegment(
                  value: CommuterType.senior,
                  label: Text(l10n.subTierElderly, style: const TextStyle(fontSize: 12)),
                  icon: const Icon(Icons.elderly_rounded, size: 16),
                ),
              ],
              selected: {_commuterType},
              onSelectionChanged: (set) {
                HapticFeedback.selectionClick();
                setState(() => _commuterType = set.first);
              },
            ),
          ),

          const SizedBox(height: 20),

          // Commute Routine (Days per week)
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          l10n.commuteDaysPerWeek,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: context.textPrimary),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryTeal.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          isArabic
                              ? '$_daysPerWeek ${_daysPerWeek == 1 ? 'يوم' : (_daysPerWeek == 2 ? 'يومين' : (_daysPerWeek <= 10 ? 'أيام' : 'يوم'))}'
                              : '$_daysPerWeek ${_daysPerWeek == 1 ? 'day' : 'days'}',
                          style: const TextStyle(
                            color: AppColors.primaryTeal,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.budgetRoutineTrips('$monthlyTrips'),
                    style: TextStyle(fontSize: 12, color: context.textSecondary),
                  ),
                  Slider(
                    value: _daysPerWeek.toDouble(),
                    min: 1,
                    max: 7,
                    divisions: 6,
                    activeColor: AppColors.primaryTeal,
                    label: isArabic ? '$_daysPerWeek أيام' : '$_daysPerWeek days',
                    onChanged: (val) {
                      setState(() => _daysPerWeek = val.round());
                    },
                  ),
                  const Divider(height: 20),
                  Text(
                    l10n.budgetStageHeader,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: context.textPrimary),
                  ),
                  const SizedBox(height: 10),
                  // Stage Selection Grid
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildStageChip(
                        title: isArabic ? 'مرحلة 1 (من 1 لـ 9 محطات)' : 'Stage 1 (1-9 stops)',
                        fare: '10 ${isArabic ? 'ج.م' : 'EGP'}',
                        isSelected: _stationsCount <= 9,
                        onTap: () => setState(() {
                          _stationsCount = 8;
                          _singleTripFare = 10;
                        }),
                      ),
                      _buildStageChip(
                        title: isArabic ? 'مرحلة 2 (من 10 لـ 16 محطة)' : 'Stage 2 (10-16 stops)',
                        fare: '12 ${isArabic ? 'ج.م' : 'EGP'}',
                        isSelected: _stationsCount >= 10 && _stationsCount <= 16,
                        onTap: () => setState(() {
                          _stationsCount = 14;
                          _singleTripFare = 12;
                        }),
                      ),
                      _buildStageChip(
                        title: isArabic ? 'مرحلة 3 (من 17 لـ 23 محطة)' : 'Stage 3 (17-23 stops)',
                        fare: '15 ${isArabic ? 'ج.م' : 'EGP'}',
                        isSelected: _stationsCount >= 17 && _stationsCount <= 23,
                        onTap: () => setState(() {
                          _stationsCount = 20;
                          _singleTripFare = 15;
                        }),
                      ),
                      _buildStageChip(
                        title: isArabic ? 'مرحلة 4 (24+ محطة)' : 'Stage 4 (24+ stops)',
                        fare: '20 ${isArabic ? 'ج.م' : 'EGP'}',
                        isSelected: _stationsCount >= 24,
                        onTap: () => setState(() {
                          _stationsCount = 25;
                          _singleTripFare = 20;
                        }),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Metro Subscription Savings Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: monthlySavings > 0
                  ? const Color(0xFF2ECC71).withValues(alpha: isDark ? 0.2 : 0.12)
                  : Colors.blueGrey.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: monthlySavings > 0
                    ? const Color(0xFF2ECC71).withValues(alpha: 0.4)
                    : Colors.blueGrey.withValues(alpha: 0.25),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      monthlySavings > 0 ? Icons.savings_rounded : Icons.info_outline_rounded,
                      color: monthlySavings > 0 ? const Color(0xFF2ECC71) : context.textSecondary,
                      size: 26,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isArabic ? 'مقارنة التوفير مع الاشتراك' : 'Monthly Pass Savings',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: context.textPrimary,
                        ),
                      ),
                    ),
                    if (monthlySavings > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2ECC71),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isArabic ? 'وفر $monthlySavings ج.م' : 'Save $monthlySavings EGP',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                // Side-by-side cost boxes
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.black26 : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isArabic ? 'التذاكر اليومية' : 'Daily Tickets',
                              style: TextStyle(fontSize: 11.5, color: context.textSecondary),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '$monthlyTicketCost ${isArabic ? 'ج.م' : 'EGP'}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: context.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2ECC71).withValues(alpha: isDark ? 0.3 : 0.18),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isArabic ? 'اشتراك المترو' : 'Metro Pass',
                              style: const TextStyle(fontSize: 11.5, color: Color(0xFF1E824C), fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '$subCostPerMonth ${isArabic ? 'ج.م' : 'EGP'}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E824C),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  isArabic
                      ? 'المرحلة المقترحة لمشوارك: ${tier.localizedStageName(true)}'
                      : 'Recommended stage: ${tier.localizedStageName(false)}',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimary,
                  ),
                ),
                if (monthlySavings > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    isArabic
                        ? 'أنت توفر $monthlySavings ج.م كل شهر (أرخص بنسبة $savingsPercent٪ من التذاكر العادية)!'
                        : 'You save $monthlySavings EGP every month ($savingsPercent% cheaper than paper tickets)!',
                    style: const TextStyle(
                      color: Color(0xFF2A9D8F),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Interactive Metro Offices Section
          _buildOfficesSection(context, isDark, isArabic),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildStageChip({
    required String title,
    required String fare,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryTeal.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primaryTeal : Colors.grey.withValues(alpha: 0.3),
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppColors.primaryTeal : context.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              fare,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? AppColors.primaryTeal : context.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfficesSection(BuildContext context, bool isDark, bool isArabic) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.location_city_rounded, color: AppColors.primaryTeal, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isArabic ? 'مكاتب الاشتراكات في محطات المترو' : 'Metro Subscription Offices',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: context.textPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          isArabic
              ? 'اضغط على "احسب طريقك" لتخطيط رحلتك والذهاب للمكتب مباشرة:'
              : 'Tap "Route Here" to get live transit directions to any office:',
          style: TextStyle(fontSize: 12.5, color: context.textSecondary),
        ),
        const SizedBox(height: 12),
        ...CommuteBudgetService.subscriptionOffices.map((office) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2630) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.primaryTeal.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.subway_rounded, color: AppColors.primaryTeal, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        office.localizedName(isArabic),
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: context.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        office.localizedLines(isArabic),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.primaryTeal,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        office.localizedHours(isArabic),
                        style: TextStyle(fontSize: 11, color: context.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _routingOffice
                      ? null
                      : () => _routeToOffice(office, isArabic),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTeal,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.navigation_rounded, size: 15),
                  label: Text(
                    isArabic ? 'احسب طريقك' : 'Route Here',
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
