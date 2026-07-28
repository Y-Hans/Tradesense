import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color background = Color(0xFF0F172A); // Slate 900
  static const Color surface = Color(0xFF1E293B); // Slate 800
  static const Color card = Color(0xFF334155); // Slate 700
  static const Color primary = Color(0xFF6366F1); // Indigo 500
  static const Color accent = Color(0xFF8B5CF6); // Violet 500

  // Core Financial Colors
  static const Color profit = Color(0xFF10B981); // Emerald 500
  static const Color loss = Color(0xFFEF4444); // Red 500
  static const Color discipline = Color(0xFFF59E0B); // Amber 500 (Gold)
  static const Color riskLow = Color(0xFF10B981);
  static const Color riskModerate = Color(0xFFF59E0B);
  static const Color riskHigh = Color(0xFFF97316);
  static const Color riskExtreme = Color(0xFFEF4444);

  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color outline = Color(0xFF262D3D);
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surface,
        error: AppColors.loss,
      ),
      textTheme:
          GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.outfit(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 32),
        headlineMedium: GoogleFonts.outfit(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 24),
        titleLarge: GoogleFonts.outfit(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 20),
        bodyLarge:
            GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 16),
        bodyMedium:
            GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 14),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
      ),
    );
  }
}
