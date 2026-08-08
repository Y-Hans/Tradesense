import 'package:cryptoedu/shared/widgets/bitcoin_loader.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../intelligence/providers/score_providers.dart';

class DisciplineMeterScreen extends ConsumerWidget {
  const DisciplineMeterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scoreAsync = ref.watch(portfolioScoresProvider);

    return AppScaffold(
      title: 'Discipline Score',
      body: scoreAsync.when(
        data: (scores) => _buildContent(context, scores.disciplineScore),
        loading: () => const Center(
          child: AdaptiveLoader(),
        ),
        error: (err, _) => EmptyState(
          icon: Icons.error_outline,
          title: 'Could not calculate score',
          description: 'Place a virtual trade to generate your discipline score.',
          primaryAction: PrimaryButton(
            text: 'Retry',
            onPressed: () => ref.invalidate(portfolioScoresProvider),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, int score) {
    final rating = _getRating(score);
    final ratingColor = _getRatingColor(score);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Score card
          AppCard(
            isActive: true,
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              children: [
                StatusChip(label: rating, type: _statusType(score)),
                const SizedBox(height: AppSpacing.xl),
                ScoreRing(score: score, size: 120, color: ratingColor),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  '$score / 100',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        color: ratingColor,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Discipline Score',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // AI context card
          const AIInsightCard(
            title: 'What does this score mean?',
            content:
                'Your discipline score measures trading behaviour quality independent of profit/loss. High discipline means you follow risk rules consistently — using stop-losses, controlling position sizes, and avoiding over-trading.',
          ),

          const SizedBox(height: AppSpacing.xl),

          // Breakdown
          Text(
            'Score Components',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: const [
                _ComponentRow(
                  label: 'Risk Management Adherence',
                  weight: '30%',
                  description: 'Stop-loss usage and position sizing compliance',
                ),
                Divider(height: AppSpacing.xl),
                _ComponentRow(
                  label: 'Position Sizing Discipline',
                  weight: '25%',
                  description: 'Trade size relative to total portfolio equity',
                ),
                Divider(height: AppSpacing.xl),
                _ComponentRow(
                  label: 'Stop-Loss Usage',
                  weight: '20%',
                  description: 'Percentage of trades with stop-loss protection',
                ),
                Divider(height: AppSpacing.xl),
                _ComponentRow(
                  label: 'Portfolio Concentration',
                  weight: '15%',
                  description: 'Diversification across multiple positions',
                ),
                Divider(height: AppSpacing.xl),
                _ComponentRow(
                  label: 'Trading Frequency',
                  weight: '10%',
                  description: 'Avoiding over-trading and impulsive entries',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getRating(int score) {
    if (score >= 85) return 'Excellent Process';
    if (score >= 70) return 'Good Discipline';
    if (score >= 50) return 'Room to Improve';
    return 'Needs Attention';
  }

  Color _getRatingColor(int score) {
    if (score >= 85) return AppColors.successGreen;
    if (score >= 70) return AppColors.primaryCyan;
    if (score >= 50) return AppColors.warningOrange;
    return AppColors.errorRed;
  }

  StatusType _statusType(int score) {
    if (score >= 85) return StatusType.success;
    if (score >= 70) return StatusType.neutral;
    if (score >= 50) return StatusType.warning;
    return StatusType.error;
  }
}

class _ComponentRow extends StatelessWidget {
  final String label;
  final String weight;
  final String description;

  const _ComponentRow({
    required this.label,
    required this.weight,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: AppColors.primaryCyan.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: Text(
            weight,
            style: const TextStyle(
              color: AppColors.primaryCyan,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
