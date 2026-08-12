import 'package:flutter/material.dart';
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
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.format_quote,
              size: 12,
              color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey,
            ),
            SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey,
                    decoration: onTap != null ? TextDecoration.underline : TextDecoration.none,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
