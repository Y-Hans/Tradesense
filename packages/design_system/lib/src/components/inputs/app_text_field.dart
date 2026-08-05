import 'package:flutter/material.dart';
import '../../tokens/colors.dart';
import '../../tokens/spacing.dart';

/// A stylized text input field for the application.
/// 
/// Example usage:
/// ```dart
/// AppTextField(
///   hintText: 'Enter trade notes...',
///   controller: myController,
/// )
/// ```
class AppTextField extends StatelessWidget {
  /// The controller for the text field
  final TextEditingController? controller;

  /// Hint text shown when the field is empty
  final String? hintText;

  /// Optional label shown above the field
  final String? labelText;

  /// Optional prefix icon
  final Widget? prefixIcon;

  /// Optional suffix icon
  final Widget? suffixIcon;

  /// Whether the text should be obscured (e.g. for passwords)
  final bool obscureText;

  /// The keyboard type to use
  final TextInputType? keyboardType;

  /// Error text to show below the field
  final String? errorText;
  
  /// Number of lines for the field. Defaults to 1.
  final int maxLines;

  const AppTextField({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.errorText,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (labelText != null) ...[
          Text(
            labelText!,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: Theme.of(context).textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textDisabled,
                ),
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            errorText: errorText,
          ),
        ),
      ],
    );
  }
}
