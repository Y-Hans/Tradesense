import 'package:flutter/material.dart';
import '../../tokens/colors.dart';
import '../../tokens/spacing.dart';

/// A reusable empty/error state component.
///
/// Example usage:
/// ```dart
/// EmptyState(
///   icon: Icons.book,
///   title: 'Start your trading journal',
///   description: 'Log your first trade so TradeSense can begin...',
///   primaryAction: PrimaryButton(text: 'Log first trade', onPressed: () {}),
///   secondaryAction: SecondaryButton(text: 'Import trades', onPressed: () {}),
/// )
/// ```
class EmptyState extends StatelessWidget {
  final IconData? icon;
  final Widget? customGraphic;
  final String title;
  final String description;
  final Widget? primaryAction;
  final Widget? secondaryAction;

  const EmptyState({
    super.key,
    this.icon,
    this.customGraphic,
    required this.title,
    required this.description,
    this.primaryAction,
    this.secondaryAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (customGraphic != null)
            customGraphic!
          else if (icon != null)
            Icon(
              icon,
              size: 64,
              color: AppColors.textSecondary,
            ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            description,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          if (primaryAction != null || secondaryAction != null) ...[
            const SizedBox(height: AppSpacing.xxl),
            if (primaryAction != null)
              SizedBox(
                width: double.infinity,
                child: primaryAction!,
              ),
            if (primaryAction != null && secondaryAction != null)
              const SizedBox(height: AppSpacing.md),
            if (secondaryAction != null)
              SizedBox(
                width: double.infinity,
                child: secondaryAction!,
              ),
          ],
        ],
      ),
    );
  }
}
