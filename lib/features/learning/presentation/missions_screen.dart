import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/app_providers.dart';

// Integration Point (Learning Module):
// Real mission data will come from a dedicated learning/gamification provider.
// Currently missions are derived from real portfolio activity.

@immutable
class _Mission {
  final String title;
  final String description;
  final String xpReward;
  final IconData icon;
  final bool Function(dynamic portfolio, List<dynamic> trades) isCompleted;

  const _Mission({
    required this.title,
    required this.description,
    required this.xpReward,
    required this.icon,
    required this.isCompleted,
  });
}

class MissionsScreen extends ConsumerWidget {
  const MissionsScreen({super.key});

  static final List<_Mission> _missions = [
    _Mission(
      title: 'First Virtual Trade',
      description: 'Execute a market buy order with your virtual wallet.',
      xpReward: '+100 XP',
      icon: Icons.rocket_launch_outlined,
      isCompleted: (portfolio, trades) => trades.isNotEmpty,
    ),
    _Mission(
      title: 'Stop-Loss Protection',
      description: 'Set a stop-loss order on any crypto position.',
      xpReward: '+250 XP',
      icon: Icons.shield_outlined,
      isCompleted: (portfolio, trades) =>
          trades.any((t) => t.stopLossPriceInr != null),
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final portfolioAsync = ref.watch(portfolioProvider);
    final tradingRepo = ref.watch(tradingRepositoryProvider);

    return AppScaffold(
      showBackButton: false,
      title: 'Missions',
      body: FutureBuilder<List<dynamic>>(
        future: tradingRepo.getTradeHistory(),
        builder: (context, tradeSnapshot) {
          return portfolioAsync.when(
            data: (portfolio) {
              final trades = tradeSnapshot.data ?? [];
              final completedCount = _missions
                  .where((m) => m.isCompleted(portfolio, trades))
                  .length;
              final totalXp = completedCount * 175; // Average XP

              return ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  // XP summary card
                  AppCard(
                    isActive: true,
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.emoji_events,
                              color: AppColors.warningOrange,
                              size: 28,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              '$totalXp XP',
                              style: Theme.of(context)
                                  .textTheme
                                  .displaySmall
                                  ?.copyWith(
                                    color: AppColors.warningOrange,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          '$completedCount of ${_missions.length} missions complete',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        ClipRRect(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusRound),
                          child: LinearProgressIndicator(
                            value: completedCount / _missions.length,
                            backgroundColor: AppColors.border,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.warningOrange,
                            ),
                            minHeight: 8,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xxl),

                  Text(
                    'Beginner Missions',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Mission cards
                  ..._missions.map((mission) {
                    final done = mission.isCompleted(portfolio, trades);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _MissionCard(
                        mission: mission,
                        isCompleted: done,
                      ),
                    );
                  }),

                  const SizedBox(height: AppSpacing.xxl),

                  // AI tip card
                  const AIInsightCard(
                    title: 'Coach Tip',
                    content:
                        'Missions are designed to build disciplined trading habits. Focus on process quality, not profit. Each mission teaches a fundamental risk management concept.',
                  ),

                  const SizedBox(height: AppSpacing.xxl),

                  // Quick action
                  PrimaryButton(
                    text: 'Go to Markets',
                    onPressed: () => context.go('/markets'),
                    icon: const Icon(Icons.show_chart),
                  ),
                ],
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primaryCyan),
            ),
            error: (_, __) => const EmptyState(
              icon: Icons.error_outline,
              title: 'Could not load missions',
              description: 'Please try again later.',
            ),
          );
        },
      ),
    );
  }
}

class _MissionCard extends StatelessWidget {
  final _Mission mission;
  final bool isCompleted;

  const _MissionCard({required this.mission, required this.isCompleted});

  @override
  Widget build(BuildContext context) {
    final iconColor =
        isCompleted ? AppColors.successGreen : AppColors.primaryCyan;
    final badgeColor =
        isCompleted ? AppColors.successGreen : AppColors.warningOrange;

    return AppCard(
      hasBorder: true,
      isActive: isCompleted,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: iconColor.withValues(alpha: 0.12),
            ),
            child: Icon(
              isCompleted ? Icons.check_circle : mission.icon,
              color: iconColor,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        mission.title,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  decoration: isCompleted
                                      ? TextDecoration.none
                                      : null,
                                ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.12),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: Text(
                        mission.xpReward,
                        style: TextStyle(
                          color: badgeColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  mission.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                if (isCompleted) ...[
                  const SizedBox(height: AppSpacing.sm),
                  const StatusChip(
                    label: '✓ Completed',
                    type: StatusType.success,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
