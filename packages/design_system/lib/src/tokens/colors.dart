import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Backgrounds
  static const Color background = Color(0xFF0B0E14); // Obsidian
  static const Color surface = Color(0xFF161B22); // Surface cards

  // Accents
  static const Color primaryCyan = Color(0xFF00E5FF);
  static const Color secondaryPurple = Color(0xFFB388FF);
  
  // Status
  static const Color successGreen = Color(0xFF00D09C); // Buy green
  static const Color warningOrange = Color(0xFFFFAB40);
  static const Color errorRed = Color(0xFFFF4D4D); // Sell red

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFA0AAB2); // Muted grey/blue
  static const Color textDisabled = Color(0xFF5C6570);

  // Light Theme Text
  static const Color textPrimaryLight = Color(0xFF1A202C);
  static const Color textSecondaryLight = Color(0xFF2D3748);
  static const Color textDisabledLight = Color(0xFF718096);

  // Borders
  static const Color border = Color(0xFF2C3240);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryCyan, secondaryPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
