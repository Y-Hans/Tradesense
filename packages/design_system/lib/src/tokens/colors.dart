import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Backgrounds
  static const Color background = Color(0xFF0F1218); // Deep Navy/Black
  static const Color surface = Color(0xFF1A1E26); // Elevated Dark Blue

  // Accents
  static const Color primaryCyan = Color(0xFF00E5FF);
  static const Color secondaryPurple = Color(0xFFB388FF);
  
  // Status
  static const Color successGreen = Color(0xFF00E676);
  static const Color warningOrange = Color(0xFFFFAB40);
  static const Color errorRed = Color(0xFFFF5252);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFA0AAB2); // Muted grey/blue
  static const Color textDisabled = Color(0xFF5C6570);

  // Borders
  static const Color border = Color(0xFF2C3240);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryCyan, secondaryPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
