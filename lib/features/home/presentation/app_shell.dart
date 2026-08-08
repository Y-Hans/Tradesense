import 'package:cryptoedu/shared/widgets/bitcoin_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/app_providers.dart';
import '../../../app/theme/app_theme.dart' hide AppColors;
import 'package:design_system/design_system.dart';
import '../../coach/data/coach_repository.dart';

/// ───────────────────────────────────────────────
///  APP SHELL (GROWW INSPIRED) ───────────────────
///  Standard 4-tab bottom navigation shell without
///  complex FAB mechanics. Clean and simple.
/// ───────────────────────────────────────────────

class AppShell extends ConsumerWidget {
  const AppShell({
    super.key,
    required this.child,
  });

  final Widget child;

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/markets')) return 1;
    if (location.startsWith('/portfolio')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0; // Dashboard
  }

  void _onDestinationSelected(BuildContext context, int index) {
    final int currentIndex = _calculateSelectedIndex(context);
    if (index != currentIndex) {
      HapticFeedback.selectionClick();
    }
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
        context.go('/profile');
        break;
    }
  }

  void _showCoachBottomSheet(BuildContext context, WidgetRef ref, String location) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.background.withValues(alpha: 0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.psychology, color: AppColors.primaryCyan),
                  const SizedBox(width: 12),
                  Text(
                    'AI Coach Insights',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.primaryCyan,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              FutureBuilder<String>(
                future: ref.read(coachRepositoryProvider).getInsights(location),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: AdaptiveLoader());
                  }
                  if (snapshot.hasError) {
                    return Text('Error loading insights.',
                        style: TextStyle(color: AppColors.errorRed));
                  }
                  return Text(
                    snapshot.data ?? 'No insights right now.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textPrimary,
                        ),
                  );
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.push('/coach');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryCyan.withValues(alpha: 0.2),
                    foregroundColor: AppColors.primaryCyan,
                  ),
                  child: const Text('Open Full Chat'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.path;
    final showCoach = location == '/' || location.startsWith('/trade');
    return AppScaffold(
      showBackButton: false,
      body: child,
      floatingActionButton: showCoach
          ? FloatingActionButton(
              onPressed: () => _showCoachBottomSheet(context, ref, location),
              backgroundColor: AppColors.surface,
              child: const Icon(Icons.psychology, color: AppColors.primaryCyan),
            )
          : null,
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _calculateSelectedIndex(context),
        onTap: (index) => _onDestinationSelected(context, index),
        items: const [
          NavItemData(
            label: 'Dashboard',
            icon: Icon(Icons.dashboard_outlined, color: AppColors.textSecondary),
            activeIcon: Icon(Icons.dashboard_rounded, color: AppColors.primaryCyan),
          ),
          NavItemData(
            label: 'Markets',
            icon: Icon(Icons.show_chart_outlined, color: AppColors.textSecondary),
            activeIcon: Icon(Icons.show_chart_rounded, color: AppColors.primaryCyan),
          ),
          NavItemData(
            label: 'Portfolio',
            icon: Icon(Icons.account_balance_wallet_outlined, color: AppColors.textSecondary),
            activeIcon: Icon(Icons.account_balance_wallet_rounded, color: AppColors.primaryCyan),
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
