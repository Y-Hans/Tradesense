import 'package:flutter/material.dart';
import '../../tokens/colors.dart';
import '../../tokens/spacing.dart';

enum StatusType { success, warning, error, neutral }

/// A small pill-shaped indicator for statuses like "Reviewed", "Pending", etc.
///
/// Example usage:
/// ```dart
/// StatusChip(
///   label: 'Reviewed',
///   type: StatusType.success,
/// )
/// ```
class StatusChip extends StatelessWidget {
  /// The text label to display
  final String label;

  /// The type of status, which determines the color
  final StatusType type;

  /// Optional icon to display before the text
  final IconData? icon;

  const StatusChip({
    super.key,
    required this.label,
    this.type = StatusType.neutral,
    this.icon,
  });

  Color _getColor(BuildContext context) {
    switch (type) {
      case StatusType.success:
        return AppColors.successGreen;
      case StatusType.warning:
        return AppColors.warningOrange;
      case StatusType.error:
        return AppColors.errorRed;
      case StatusType.neutral:
        return Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 12,
              color: color,
            ),
            SizedBox(width: AppSpacing.xs),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
          ),
        ],
      ),
    );
  }
}
