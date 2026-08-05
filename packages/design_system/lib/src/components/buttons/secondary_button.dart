import 'package:flutter/material.dart';
import '../../tokens/colors.dart';
import '../../tokens/spacing.dart';

/// A secondary action button with a dark background and a subtle border.
///
/// Example usage:
/// ```dart
/// SecondaryButton(
///   text: 'Import trades',
///   onPressed: () => print('Pressed'),
/// )
/// ```
class SecondaryButton extends StatelessWidget {
  /// The text displayed on the button
  final String text;

  /// Callback when the button is pressed. If null, the button is in a disabled state.
  final VoidCallback? onPressed;

  /// Whether the button is in a loading state
  final bool isLoading;

  /// Optional icon to display before the text
  final Widget? icon;

  /// Whether this button represents an error/destructive action
  final bool isDestructive;

  /// Create a SecondaryButton
  const SecondaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.isDestructive = false,
  });

  bool get _isDisabled => onPressed == null || isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color getTextColor() {
      if (_isDisabled) return isDark ? AppColors.textDisabled : Colors.grey.shade400;
      if (isDestructive) return AppColors.errorRed;
      return theme.colorScheme.onSurface;
    }

    final textColor = getTextColor();
    final borderColor = isDestructive
        ? AppColors.errorRed.withValues(alpha: 0.5)
        : (isDark ? AppColors.border : theme.dividerColor);
    final buttonBg = isDark ? AppColors.background : theme.colorScheme.surface;

    return Material(
      color: buttonBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: BorderSide(
          color: _isDisabled ? borderColor.withValues(alpha: 0.5) : borderColor,
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        onTap: _isDisabled ? null : onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.lg,
            horizontal: AppSpacing.xl,
          ),
          alignment: Alignment.center,
          child: isLoading
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(textColor),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      IconTheme(
                        data: IconThemeData(color: textColor, size: 20),
                        child: icon!,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                    Text(
                      text,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: textColor,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
