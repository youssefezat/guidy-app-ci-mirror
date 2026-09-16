import 'package:flutter/material.dart';
import 'HomeScreen.dart';
import 'LinesScreen.dart';
import 'MetroScreen.dart';
import 'HistoryScreen.dart';
import 'SettingsScreen.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../widgets/banner_ad_placeholder.dart';

class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  int _selectedIndex = 2; // Home in the center by default

  void _goToHome() {
    if (mounted) setState(() => _selectedIndex = 2);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final List<Widget> tabs = [
      LinesScreen(onGoHome: _goToHome),
      MetroScreen(onGoHome: _goToHome),
      const HomeScreen(), // Middle / Main Menu!
      HistoryScreen(onGoHome: _goToHome),
      SettingsScreen(onGoHome: _goToHome),
    ];

    return PopScope(
      canPop: _selectedIndex == 2,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _selectedIndex != 2) {
          setState(() => _selectedIndex = 2);
        }
      },
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: IndexedStack(index: _selectedIndex, children: tabs),
        ),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) => setState(() => _selectedIndex = index),
              backgroundColor: context.surfaceCard,
              indicatorColor: AppColors.primaryTeal.withValues(alpha: 0.15),
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.alt_route_outlined),
                  selectedIcon: const Icon(Icons.alt_route, color: AppColors.primaryTeal),
                  label: l10n.navLines,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.subway_outlined),
                  selectedIcon: const Icon(Icons.subway, color: AppColors.primaryTeal),
                  label: l10n.navMetro,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.home_outlined),
                  selectedIcon: const Icon(Icons.home_rounded, color: AppColors.primaryTeal),
                  label: l10n.navHome,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.history_outlined),
                  selectedIcon: const Icon(Icons.history, color: AppColors.primaryTeal),
                  label: l10n.navHistory,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.settings_outlined),
                  selectedIcon: const Icon(Icons.settings, color: AppColors.primaryTeal),
                  label: l10n.navSettings,
                ),
              ],
            ),
            const BannerAdPlaceholder(),
          ],
        ),
      ),
    );
  }
}
