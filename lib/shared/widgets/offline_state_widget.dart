import 'package:flutter/material.dart';
import '../../app/theme/app_theme.dart';

/// A reusable, presentation-focused network-aware state widget.
///
/// Used across feature screens (AI Coach, Markets, Portfolio, Asset Detail)
/// to provide consistent messaging when features depend on live connectivity.
/// Totally domain-agnostic with flexible slots for [action] and [footer].
class OfflineStateWidget extends StatelessWidget {
  final String message;
  final String? title;
  final IconData icon;
  final Widget? action;
  final Widget? footer;
  final bool compact;

  OfflineStateWidget({
    super.key,
    required this.message,
    this.title,
    this.icon = Icons.wifi_off_rounded,
    this.action,
    this.footer,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (compact) {
      return Card(
        color: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Theme.of(context).dividerColor, width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(icon, color: AppColors.discipline, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      message,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              if (footer != null) ...[
                SizedBox(height: 8),
                footer!,
              ],
            ],
          ),
        ),
      );
    }

    return Card(
      color: Theme.of(context).colorScheme.surface,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).dividerColor, width: 1),
      ),
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.discipline.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 40,
                  color: AppColors.discipline,
                ),
              ),
              SizedBox(height: 16),
              if (title != null && title!.isNotEmpty) ...[
                Text(
                  title!,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
              ],
              Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              if (footer != null) ...[
                const SizedBox(height: 12),
                footer!,
              ],
              if (action != null) ...[
                const SizedBox(height: 20),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
