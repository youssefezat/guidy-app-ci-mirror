import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import 'AuthGate.dart';
import '../widgets/banner_ad_placeholder.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  static const String prefsKey = 'guidy_onboarding_seen';

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _index = 0;

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(OnboardingScreen.prefsKey, true);
    if (mounted) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const AuthGate()));
    }
  }

  void _next(int pageCount) {
    if (_index == pageCount - 1) {
      _finish();
    } else {
      _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.ease);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pages = [
      (icon: Icons.alt_route_rounded, title: l10n.onboardingTitle1, body: l10n.onboardingBody1),
      (icon: Icons.payments_rounded, title: l10n.onboardingTitle2, body: l10n.onboardingBody2),
      (icon: Icons.shield_outlined, title: l10n.onboardingTitle3, body: l10n.onboardingBody3),
    ];

    return Scaffold(
      bottomNavigationBar: const BannerAdPlaceholder(),
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: TextButton(
                  onPressed: _finish,
                  child: Text(l10n.onboardingSkip, style: TextStyle(color: context.textSecondary)),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: pages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  final page = pages[i];
                  // This page used to be a bare Column, which overflowed
                  // (the yellow-and-black stripe) as soon as the phone was
                  // turned sideways: landscape leaves this Expanded roughly
                  // 250px, and a 120px badge plus 32 + title + 12 + body
                  // needs more than that.
                  //
                  // Two changes fix it together. The badge and the gaps
                  // shrink when height is tight, and the whole page becomes
                  // scrollable with a minimum height equal to the space
                  // available — so it still centres normally, and scrolls
                  // instead of overflowing when it can't.
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final bool tight = constraints.maxHeight < 420;
                      final double badge = tight ? 76 : 120;
                      final double gap = tight ? 18 : 32;

                      return SingleChildScrollView(
                        padding: EdgeInsets.symmetric(horizontal: 32, vertical: tight ? 12 : 0),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight - (tight ? 24 : 0),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: badge,
                                height: badge,
                                decoration: const BoxDecoration(
                                  gradient: AppColors.brandGradient,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(page.icon, color: Colors.white, size: badge * 0.47),
                              ),
                              SizedBox(height: gap),
                              Text(page.title,
                                  style: TextStyle(
                                      fontSize: tight ? 19 : 22,
                                      fontWeight: FontWeight.bold,
                                      color: context.textPrimary),
                                  textAlign: TextAlign.center),
                              const SizedBox(height: 12),
                              Text(page.body,
                                  style: TextStyle(
                                      fontSize: tight ? 14 : 15,
                                      color: context.textSecondary,
                                      height: 1.4),
                                  textAlign: TextAlign.center),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(pages.length, (i) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: i == _index ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i == _index ? AppColors.primaryTeal : context.textSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _next(pages.length),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTeal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    _index == pages.length - 1 ? l10n.onboardingGetStarted : l10n.onboardingNext,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
