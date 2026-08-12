import 'package:flutter/material.dart';
import '../../tokens/colors.dart';
import '../../tokens/spacing.dart';

/// A primary action button with a gradient background, used for the main call to action.
///
/// Example usage:
/// ```dart
/// PrimaryButton(
///   text: 'Log first trade',
///   onPressed: () => print('Pressed'),
///   isLoading: false,
/// )
/// ```
class PrimaryButton extends StatelessWidget {
  /// The text displayed on the button
  final String text;

  /// Callback when the button is pressed. If null, the button is in a disabled state.
  final VoidCallback? onPressed;

  /// Whether the button is in a loading state. Displays a spinner if true.
  final bool isLoading;

  /// Optional icon to display before the text
  final Widget? icon;

  /// Create a PrimaryButton
  PrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  bool get _isDisabled => onPressed == null || isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = _isDisabled
        ? (isDark ? Theme.of(context).disabledColor : Colors.grey.shade400)
        : Colors.white;
    final disabledBg = isDark ? Theme.of(context).colorScheme.surface : Colors.grey.shade300;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        gradient: _isDisabled ? null : AppColors.primaryGradient,
        color: _isDisabled ? disabledBg : null,
      ),
      child: Material(
        color: Colors.transparent,
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
                        SizedBox(width: AppSpacing.sm),
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
      ),
    );
  }
}
