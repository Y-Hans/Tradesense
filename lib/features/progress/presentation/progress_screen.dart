import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:design_system/design_system.dart';
import 'progress_controller.dart';
import '../domain/progress_state.dart';

class ProgressScreen extends ConsumerWidget {
  ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(progressControllerProvider);

    return AppScaffold(
      showBackButton: false,
      title: 'Progress',
      body: asyncState.when(
        data: (state) => _buildBody(context, ref, state),
        loading: () => Center(
          child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
        ),
        error: (error, stack) => EmptyState(
          icon: Icons.error_outline,
          title: 'Error loading progress',
          description: error.toString(),
          primaryAction: PrimaryButton(
            text: 'Try again',
            onPressed: () => ref.read(progressControllerProvider.notifier).refresh(),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, ProgressState state) {
    return RefreshIndicator(
      color: Theme.of(context).colorScheme.primary,
      backgroundColor: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
      onRefresh: () => ref.read(progressControllerProvider.notifier).refresh(),
      child: ListView(
        padding: EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(
            'Weekly Overview',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: AppCard(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    children: [
                      ScoreRing(
                        score: state.overallDisciplineScore,
                        size: 64,
                        color: AppColors.primaryCyan,
                      ),
                      SizedBox(height: AppSpacing.sm),
                      Text(
                        'Discipline',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppCard(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    children: [
                      ScoreRing(
                        score: state.winRatePercentage,
                        size: 64,
                        color: AppColors.successGreen,
                      ),
                      SizedBox(height: AppSpacing.sm),
                      Text(
                        'Win Rate',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppCard(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    children: [
                      Text(
                        state.profitFactor.toStringAsFixed(2),
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      SizedBox(height: AppSpacing.md),
                      Text(
                        'Profit Factor',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.xxl),
          Text(
            'Top Mistakes Detected',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.lg),
          if (state.topMistakes.isEmpty)
            AppCard(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Center(
                child: Text('No prominent mistake patterns detected yet.'),
              ),
            )
          else
            ...state.topMistakes.map((mistake) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: AppCard(
                  hasBorder: true,
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mistake.name,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          SizedBox(height: AppSpacing.xs),
                          Text(
                            'Occurred ${mistake.frequency} times',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey,
                                ),
                          ),
                        ],
                      ),
                      Text(
                        '-\$${mistake.impactCost.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppColors.errorRed,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
