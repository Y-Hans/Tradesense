import 'package:flutter/material.dart';
import '../../tokens/colors.dart';
import '../../tokens/spacing.dart';
import '../cards/app_card.dart';

/// A card to display an AI insight or coach observation.
/// Features a distinct glowing border to signify AI origin.
///
/// Example usage:
/// ```dart
/// AIInsightCard(
///   title: 'Observation',
///   content: 'You tend to exit trades early when in profit.',
/// )
/// ```
class AIInsightCard extends StatelessWidget {
  /// The title of the insight
  final String title;
  
  /// The main content/message of the insight
  final String content;
  
  /// Optional action button Widget (e.g. "Review trades")
  final Widget? action;

  /// Whether the card is currently generating/loading
  final bool isLoading;

  const AIInsightCard({
    super.key,
    required this.title,
    required this.content,
    this.action,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      isActive: true, // Gives it the primary cyan border/glow
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome, // Placeholder for AI asterisk
                color: AppColors.primaryCyan,
                size: 20,
              ),
              SizedBox(width: AppSpacing.sm),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.primaryCyan,
                    ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          if (isLoading)
            SizedBox(
              height: 40,
              child: Center(
                child: LinearProgressIndicator(
                  color: AppColors.primaryCyan,
                  backgroundColor: Theme.of(context).dividerColor,
                ),
              ),
            )
          else
            Text(
              content,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    height: 1.5,
                  ),
            ),
          if (action != null && !isLoading) ...[
            const SizedBox(height: AppSpacing.lg),
            action!,
          ],
        ],
      ),
    );
  }
}
