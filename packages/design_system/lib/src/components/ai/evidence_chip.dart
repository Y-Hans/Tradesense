import 'package:flutter/material.dart';
import '../../tokens/colors.dart';
import '../../tokens/spacing.dart';

/// A chip used to reference specific journal entries or data points that the AI is citing.
///
/// Example usage:
/// ```dart
/// EvidenceChip(
///   label: 'Trade #401',
///   onTap: () => goToTrade(401),
/// )
/// ```
class EvidenceChip extends StatelessWidget {
  /// The label for the evidence
  final String label;

  /// Callback when the evidence is tapped
  final VoidCallback? onTap;

  const EvidenceChip({
    super.key,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.format_quote,
              size: 12,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    decoration: onTap != null ? TextDecoration.underline : TextDecoration.none,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
