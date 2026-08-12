import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:design_system/design_system.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({
    super.key,
    required this.navigationShell,
  });

  void _onItemTapped(int index, BuildContext context) {
    if (index != navigationShell.currentIndex) {
      HapticFeedback.selectionClick();
    }
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      showBackButton: false,
      body: navigationShell,
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => _onItemTapped(index, context),
        items: [
          NavItemData(
            label: 'Home',
            icon: Icon(Icons.home_outlined, color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey),
            activeIcon: Icon(Icons.home, color: AppColors.primaryCyan),
          ),
          NavItemData(
            label: 'Markets',
            icon: Icon(Icons.show_chart_outlined, color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey),
            activeIcon: Icon(Icons.show_chart, color: AppColors.primaryCyan),
          ),
          NavItemData(
            label: 'Portfolio',
            icon: Icon(Icons.account_balance_wallet_outlined, color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey),
            activeIcon: Icon(Icons.account_balance_wallet, color: AppColors.primaryCyan),
          ),
          NavItemData(
            label: 'Coach',
            icon: Icon(Icons.psychology_outlined, color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey),
            activeIcon: Icon(Icons.psychology, color: AppColors.primaryCyan),
          ),
          NavItemData(
            label: 'Missions',
            icon: Icon(Icons.emoji_events_outlined, color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey),
            activeIcon: Icon(Icons.emoji_events, color: AppColors.primaryCyan),
          ),
          NavItemData(
            label: 'Profile',
            icon: Icon(Icons.person_outline, color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey),
            activeIcon: const Icon(Icons.person, color: AppColors.primaryCyan),
          ),
        ],
      ),
    );
  }
}
