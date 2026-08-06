import 'package:flutter/material.dart';
import 'package:design_system/design_system.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../learning/application/domain_event_learning_adapter.dart';

class AppShell extends ConsumerWidget {
  final Widget child;

  const AppShell({
    super.key,
    required this.child,
  });

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/markets')) return 1;
    if (location.startsWith('/portfolio')) return 2;
    if (location.startsWith('/missions')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0; // Home / Today
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/markets');
        break;
      case 2:
        context.go('/portfolio');
        break;
      case 3:
        context.go('/missions');
        break;
      case 4:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize learning adapter to listen to domain events globally
    ref.watch(domainEventLearningAdapterProvider);

    return AppScaffold(
      showBackButton: false,
      body: child,
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _calculateSelectedIndex(context),
        onTap: (index) => _onItemTapped(index, context),
        items: const [
          NavItemData(
            label: 'Home',
            icon: Icon(Icons.home_outlined, color: AppColors.textSecondary),
            activeIcon: Icon(Icons.home, color: AppColors.primaryCyan),
          ),
          NavItemData(
            label: 'Markets',
            icon: Icon(Icons.show_chart_outlined, color: AppColors.textSecondary),
            activeIcon: Icon(Icons.show_chart, color: AppColors.primaryCyan),
          ),
          NavItemData(
            label: 'Portfolio',
            icon: Icon(Icons.account_balance_wallet_outlined, color: AppColors.textSecondary),
            activeIcon: Icon(Icons.account_balance_wallet, color: AppColors.primaryCyan),
          ),
          NavItemData(
            label: 'Missions',
            icon: Icon(Icons.emoji_events_outlined, color: AppColors.textSecondary),
            activeIcon: Icon(Icons.emoji_events, color: AppColors.primaryCyan),
          ),
          NavItemData(
            label: 'Profile',
            icon: Icon(Icons.person_outline, color: AppColors.textSecondary),
            activeIcon: Icon(Icons.person, color: AppColors.primaryCyan),
          ),
        ],
      ),
    );
  }
}
