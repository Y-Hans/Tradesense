import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../intelligence/providers/score_providers.dart';

class RiskMeterScreen extends ConsumerWidget {
  const RiskMeterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scoreAsync = ref.watch(portfolioScoresProvider);

    return AppScaffold(
      title: 'Risk Score',
      body: scoreAsync.when(
        data: (scores) => _buildContent(context, scores.riskScore),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryCyan),
        ),
        error: (err, _) => EmptyState(
          icon: Icons.error_outline,
          title: 'Could not calculate risk',
          description: 'Place a virtual trade to generate your risk score.',
          primaryAction: PrimaryButton(
            text: 'Retry',
            onPressed: () => ref.invalidate(portfolioScoresProvider),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, int score) {
    final riskLevel = _getRiskLevel(score);
    final riskColor = _getRiskColor(score);

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
                StatusChip(label: riskLevel, type: _statusType(score)),
                const SizedBox(height: AppSpacing.xl),
                ScoreRing(score: score, size: 120, color: riskColor),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  '$score / 100',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        color: riskColor,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Portfolio Risk Score',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // AI context card
          AIInsightCard(
            title: 'Understanding your risk',
            content: _getRiskExplanation(score),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Breakdown
          Text(
            'Risk Components',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: const [
                _RiskComponentRow(
                  label: 'Concentration Risk',
                  weight: '40%',
                  description: 'Single asset as % of total equity',
                ),
                Divider(height: AppSpacing.xl),
                _RiskComponentRow(
                  label: 'Position Sizing',
                  weight: '30%',
                  description: 'Trade size as % of portfolio equity',
                ),
                Divider(height: AppSpacing.xl),
                _RiskComponentRow(
                  label: 'Asset Volatility',
                  weight: '20%',
                  description: '24-hour price swing percentage',
                ),
                Divider(height: AppSpacing.xl),
                _RiskComponentRow(
                  label: 'Stop-Loss Behaviour',
                  weight: '10%',
                  description: 'Presence of protective stop-loss orders',
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Guidance card
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.lightbulb_outline,
                        color: AppColors.warningOrange, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Text('How to reduce risk',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            )),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                _GuidanceItem(
                  icon: Icons.check_circle_outline,
                  color: AppColors.successGreen,
                  text: 'Always set a stop-loss on every trade',
                ),
                const SizedBox(height: AppSpacing.sm),
                _GuidanceItem(
                  icon: Icons.check_circle_outline,
                  color: AppColors.successGreen,
                  text: 'Keep single positions below 25% of equity',
                ),
                const SizedBox(height: AppSpacing.sm),
                _GuidanceItem(
                  icon: Icons.check_circle_outline,
                  color: AppColors.successGreen,
                  text: 'Diversify across 3+ assets when possible',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getRiskLevel(int score) {
    if (score <= 30) return 'Low Risk';
    if (score <= 60) return 'Moderate Risk';
    if (score <= 80) return 'High Risk';
    return 'Extreme Risk';
  }

  Color _getRiskColor(int score) {
    if (score <= 30) return AppColors.successGreen;
    if (score <= 60) return AppColors.warningOrange;
    if (score <= 80) return AppColors.errorRed;
    return const Color(0xFFCC0000);
  }

  StatusType _statusType(int score) {
    if (score <= 30) return StatusType.success;
    if (score <= 60) return StatusType.warning;
    return StatusType.error;
  }

  String _getRiskExplanation(int score) {
    if (score <= 30) {
      return 'Your portfolio has low risk exposure. You are using appropriate position sizes and your concentration is well-diversified.';
    }
    if (score <= 60) {
      return 'Moderate risk. Consider adding stop-loss orders to reduce exposure. Your position sizing is within acceptable limits.';
    }
    if (score <= 80) {
      return 'High risk detected. Your portfolio concentration or position sizes are elevated. Reduce exposure before entering new trades.';
    }
    return 'Extreme risk. Immediate action recommended: reduce position sizes, set stop-losses, and review portfolio concentration.';
  }
}

class _RiskComponentRow extends StatelessWidget {
  final String label;
  final String weight;
  final String description;

  const _RiskComponentRow({
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
            color: AppColors.warningOrange.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: Text(
            weight,
            style: const TextStyle(
              color: AppColors.warningOrange,
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

class _GuidanceItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _GuidanceItem({
    required this.icon,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}
