import 'package:flutter/material.dart';
import '../../tokens/colors.dart';
import '../../tokens/spacing.dart';
import '../cards/app_card.dart';

/// A card offering a specific action suggested by the AI Coach.
///
/// Example usage:
/// ```dart
/// AIActionCard(
///   title: 'Exit script drill',
///   description: 'Practice your exit rules for the next 5 trades.',
///   onAccept: () => acceptDrill(),
/// )
/// ```
class AIActionCard extends StatelessWidget {
  final String title;
  final String description;
  final VoidCallback onAccept;
  final VoidCallback? onDismiss;
  
  const AIActionCard({
    super.key,
    required this.title,
    required this.description,
    required this.onAccept,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final secondaryTextColor = isDark ? AppColors.textSecondary : const Color(0xFF64748B);
    final btnBg = isDark ? AppColors.surface : theme.colorScheme.surface;
    final primaryColor = theme.colorScheme.primary;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.psychology,
                color: AppColors.secondaryPurple,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Coach Intervention',
                style: theme.textTheme.labelLarge?.copyWith(
                      color: AppColors.secondaryPurple,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            description,
            style: theme.textTheme.bodyMedium?.copyWith(
                  color: secondaryTextColor,
                ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (onDismiss != null)
                TextButton(
                  onPressed: onDismiss,
                  child: Text(
                    'Dismiss',
                    style: TextStyle(color: secondaryTextColor),
                  ),
                ),
              const SizedBox(width: AppSpacing.md),
              ElevatedButton(
                onPressed: onAccept,
                style: ElevatedButton.styleFrom(
                  backgroundColor: btnBg,
                  foregroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    side: BorderSide(color: primaryColor),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                ),
                child: const Text('Add to focus'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
