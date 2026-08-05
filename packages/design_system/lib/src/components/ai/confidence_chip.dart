import 'package:flutter/material.dart';
import '../../tokens/colors.dart';
import '../../tokens/spacing.dart';

/// A small indicator for the AI's confidence level.
///
/// Example usage:
/// ```dart
/// ConfidenceChip(
///   confidence: 0.92,
/// )
/// ```
class ConfidenceChip extends StatelessWidget {
  /// Confidence level between 0.0 and 1.0
  final double confidence;

  const ConfidenceChip({
    super.key,
    required this.confidence,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (confidence * 100).round();
    
    // Determine color based on confidence
    Color color;
    if (confidence >= 0.8) {
      color = AppColors.successGreen;
    } else if (confidence >= 0.5) {
      color = AppColors.warningOrange;
    } else {
      color = AppColors.errorRed;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.bar_chart,
            size: 12,
            color: color,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            '$percentage% match',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
          ),
        ],
      ),
    );
  }
}
