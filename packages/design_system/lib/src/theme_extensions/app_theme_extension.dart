import 'package:flutter/material.dart';

import '../tokens/colors.dart';

/// Custom theme extension for TradeSense specific design tokens
/// that don't fit into standard ThemeData.
class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  final LinearGradient primaryGradient;
  final Color successGreen;
  final Color warningOrange;

  const AppThemeExtension({
    required this.primaryGradient,
    required this.successGreen,
    required this.warningOrange,
  });

  @override
  ThemeExtension<AppThemeExtension> copyWith({
    LinearGradient? primaryGradient,
    Color? successGreen,
    Color? warningOrange,
  }) {
    return AppThemeExtension(
      primaryGradient: primaryGradient ?? this.primaryGradient,
      successGreen: successGreen ?? this.successGreen,
      warningOrange: warningOrange ?? this.warningOrange,
    );
  }

  @override
  ThemeExtension<AppThemeExtension> lerp(
      covariant ThemeExtension<AppThemeExtension>? other, double t) {
    if (other is! AppThemeExtension) {
      return this;
    }
    return AppThemeExtension(
      primaryGradient: LinearGradient.lerp(primaryGradient, other.primaryGradient, t)!,
      successGreen: Color.lerp(successGreen, other.successGreen, t)!,
      warningOrange: Color.lerp(warningOrange, other.warningOrange, t)!,
    );
  }

  static const AppThemeExtension instance = AppThemeExtension(
    primaryGradient: AppColors.primaryGradient,
    successGreen: AppColors.successGreen,
    warningOrange: AppColors.warningOrange,
  );
}
