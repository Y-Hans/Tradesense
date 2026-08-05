import 'package:flutter/material.dart';
import '../../tokens/colors.dart';
import '../../tokens/spacing.dart';

/// A chip used for tags like "Anxiety", "Plan matched", etc.
/// Typically outlined rather than filled.
///
/// Example usage:
/// ```dart
/// TagChip(
///   label: 'Anxiety tag',
/// )
/// ```
class TagChip extends StatelessWidget {
  /// The text label to display
  final String label;

  /// Optional callback when the tag is deleted/removed
  final VoidCallback? onDeleted;

  /// Whether this tag is currently selected
  final bool isSelected;

  const TagChip({
    super.key,
    required this.label,
    this.onDeleted,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primaryCyan.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(AppSpacing.radiusRound),
        border: Border.all(
          color: isSelected ? AppColors.primaryCyan : AppColors.border,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isSelected ? AppColors.primaryCyan : AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
          ),
          if (onDeleted != null) ...[
            const SizedBox(width: AppSpacing.xs),
            GestureDetector(
              onTap: onDeleted,
              child: Icon(
                Icons.close,
                size: 14,
                color: isSelected ? AppColors.primaryCyan : AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
