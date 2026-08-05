import 'package:flutter/material.dart';
import '../../tokens/colors.dart';
import '../../tokens/spacing.dart';

/// A base card component used across the application.
/// Provides consistent elevation, background color, and border radius.
///
/// Example usage:
/// ```dart
/// AppCard(
///   child: Padding(
///     padding: EdgeInsets.all(AppSpacing.lg),
///     child: Text('Card Content'),
///   ),
/// )
/// ```
class AppCard extends StatelessWidget {
  /// The content of the card
  final Widget child;

  /// Optional padding for the content. Defaults to zero if not provided,
  /// meaning you must pad the inner content yourself.
  final EdgeInsetsGeometry padding;

  /// Optional background color. Defaults to [AppColors.surface].
  final Color? color;

  /// Whether the card should have an active glow/border (e.g. for selection)
  final bool isActive;

  /// Whether the card should show a subtle border
  final bool hasBorder;

  /// Action when the card is tapped
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.color,
    this.isActive = false,
    this.hasBorder = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardBg = color ?? theme.cardTheme.color ?? theme.colorScheme.surface;
    final activeColor = theme.colorScheme.primary;
    final borderColor = isActive 
        ? activeColor 
        : (hasBorder ? theme.dividerColor : Colors.transparent);

    Widget cardContent = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: activeColor.withValues(alpha: 0.2),
                  blurRadius: 8,
                  spreadRadius: 0,
                )
              ]
            : null,
      ),
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          onTap: onTap,
          child: cardContent,
        ),
      );
    }

    return cardContent;
  }
}
