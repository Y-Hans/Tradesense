import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ───────────────────────────────────────────────
///  CRYPTOEDU GROWW DESIGN TOKENS ───────────────
///  Clean, legible, and professional FinTech UI.
/// ───────────────────────────────────────────────

class AppColors {
  AppColors._();

  /// ── Base Canvas (Light Default) ────────────────
  static const Color background = Color(0xFFFFFFFF); // Clean White
  static const Color surface    = Color(0xFFF7F9FC); // Light Gray Surface
  static const Color card       = Color(0xFFFFFFFF); // White Card
  
  /// ── Primary Accents ──────────────────────────
  static const Color primary    = Color(0xFF00D09C); // Groww Mint Green
  static const Color secondary  = Color(0xFF5E72E4); // Soft Blue for secondary
  
  /// ── Sentiment / Signal Colors ────────────────
  static const Color profit     = Color(0xFF00D09C); // Mint Green
  static const Color loss       = Color(0xFFEB5757); // Soft Crimson
  static const Color warning    = Color(0xFFFF9F0A); // Warning Orange
  static const Color discipline = Color(0xFF5E72E4); // Discipline / Soft Blue
  static const Color accent     = Color(0xFF00B8D9); // Accent Cyan
  
  /// ── Borders & UI Elements ────────────────────
  static const Color border     = Color(0xFFE2E8F0); // Light Border
  static const Color disabled   = Color(0xFFCBD5E0); // Disabled Gray
  
  /// ── Typography ───────────────────────────────
  static const Color textPrimary   = Color(0xFF1A202C); // Dark Gray/Black
  static const Color textSecondary = Color(0xFF4A5568); // Medium Gray
  static const Color textMuted     = Color(0xFF718096); // Light Gray

  /// ── Legacy Aliases (DO NOT REMOVE, PREVENTS BREAKAGES) ─
  static const Color oledBlack    = background;
  static const Color oledSurface  = surface;
  static const Color oledCard     = card;
  static const Color electricCyan = secondary;
  static const Color cyberGold    = warning;
  static const Color alert        = loss;
  static const Color outline      = border;
  
  /// ── Missing UI Overhaul Tokens ─────────────────
  static const Color crimsonSpark = Color(0xFFFF3366);
  static const Color neonEmerald  = Color(0xFF00D09C);
  static const Color oledObsidian = Color(0xFF0B0E14);
  static const Color auroraEmerald = Color(0xFF00D09C);
  static const Color auroraCyan   = Color(0xFF00E5FF);
  static const Color auroraIndigo = Color(0xFF5E72E4);
  static const Color auroraViolet = Color(0xFFB388FF);
  static const Color auroraBase   = Color(0xFF0B0E14);
}

class AppGradients {
  AppGradients._();
  
  static const LinearGradient electricToGold = LinearGradient(
    colors: [AppColors.secondary, AppColors.warning],
  );
  
  static const LinearGradient oledSurfaceGradient = LinearGradient(
    colors: [AppColors.surface, AppColors.background],
  );

  static const LinearGradient auroraDrift = LinearGradient(
    colors: [AppColors.auroraCyan, AppColors.auroraIndigo],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient specular({Offset? focal}) {
    final begin = focal != null ? Alignment(-focal.dx, -focal.dy) : Alignment.topLeft;
    final end = focal != null ? Alignment(focal.dx, focal.dy) : Alignment.bottomRight;
    return LinearGradient(
      colors: [Colors.white.withValues(alpha: 0.8), Colors.white.withValues(alpha: 0.1)],
      begin: begin,
      end: end,
    );
  }

  static LinearGradient glassSurface({bool hovered = false}) {
    return LinearGradient(
      colors: [
        Colors.white.withValues(alpha: hovered ? 0.15 : 0.1), 
        Colors.white.withValues(alpha: hovered ? 0.1 : 0.05)
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
}

class AppShadows {
  AppShadows._();
  
  static final List<BoxShadow> cyanGlow = [
    BoxShadow(
      color: AppColors.secondary.withValues(alpha: 0.1),
      blurRadius: 10,
      spreadRadius: 1,
    )
  ];
  
  static final List<BoxShadow> cardFloat = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 12,
      offset: const Offset(0, 4),
    )
  ];
}

class AppSpacing {
  AppSpacing._();
  static const double xs   = 4;
  static const double sm   = 8;
  static const double md   = 12;
  static const double lg   = 16;
  static const double xl   = 20;
  static const double xxl  = 24;
  static const double xxxl = 32;
  static const double pageGutter = 16.0;
}

class AppRadii {
  AppRadii._();
  static const double sm    = 8;
  static const double md    = 12;
  static const double card  = 16;
  static const double round = 999;
}

class AppTheme {
  static const _cardRadius = BorderRadius.all(Radius.circular(AppRadii.card));

  // ── HELPER FOR TEXT THEME ─────────────────────────────
  static TextTheme _buildTextTheme(Color primaryText, Color secondaryText, Color mutedText) {
    return GoogleFonts.interTextTheme().apply(
      bodyColor: primaryText,
      displayColor: primaryText,
    ).copyWith(
      displayLarge: GoogleFonts.outfit(
        color: primaryText, fontWeight: FontWeight.w700, fontSize: 32, letterSpacing: -0.5,
      ),
      displayMedium: GoogleFonts.outfit(
        color: primaryText, fontWeight: FontWeight.w600, fontSize: 28, letterSpacing: -0.5,
      ),
      headlineLarge: GoogleFonts.outfit(
        color: primaryText, fontWeight: FontWeight.w600, fontSize: 24, letterSpacing: -0.5,
      ),
      headlineMedium: GoogleFonts.outfit(
        color: primaryText, fontWeight: FontWeight.w600, fontSize: 20, letterSpacing: -0.3,
      ),
      titleLarge: GoogleFonts.inter(
        color: primaryText, fontWeight: FontWeight.w600, fontSize: 18, letterSpacing: -0.2,
      ),
      titleMedium: GoogleFonts.inter(
        color: primaryText, fontWeight: FontWeight.w600, fontSize: 16,
      ),
      bodyLarge: GoogleFonts.inter(
        color: primaryText, fontSize: 16, fontWeight: FontWeight.w400,
      ),
      bodyMedium: GoogleFonts.inter(
        color: secondaryText, fontSize: 14,
      ),
      labelLarge: GoogleFonts.inter(
        color: primaryText, fontWeight: FontWeight.w600, fontSize: 14,
      ),
      labelMedium: GoogleFonts.inter(
        color: mutedText, fontWeight: FontWeight.w500, fontSize: 12,
      ),
    );
  }

  // ──────────────────────────────────────────────────────
  // 1. LIGHT THEME (White / Mint)
  // ──────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    const bgColor = Color(0xFFFFFFFF);
    const surfaceColor = Color(0xFFF7F9FC);
    const cardColor = Color(0xFFFFFFFF);
    const primaryColor = Color(0xFF00D09C);
    const borderColor = Color(0xFFE2E8F0);
    const textColor = Color(0xFF1A202C);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: bgColor,
      canvasColor: bgColor,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        onPrimary: Colors.white,
        secondary: Color(0xFF5E72E4),
        onSecondary: Colors.white,
        surface: surfaceColor,
        onSurface: textColor,
        surfaceContainerHighest: cardColor,
        error: Color(0xFFEB5757),
        onError: Colors.white,
        outline: borderColor,
      ),
      textTheme: _buildTextTheme(textColor, const Color(0xFF4A5568), const Color(0xFF718096)),
      cardTheme: const CardThemeData(
        color: cardColor,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: _cardRadius,
          side: BorderSide(color: borderColor, width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bgColor,
        foregroundColor: textColor,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w600, fontSize: 20, color: textColor),
        iconTheme: IconThemeData(color: textColor),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: bgColor,
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        height: 64,
        indicatorColor: primaryColor.withValues(alpha: 0.15),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => GoogleFonts.inter(
            color: states.contains(WidgetState.selected) ? primaryColor : const Color(0xFF718096),
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected) ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected) ? primaryColor : const Color(0xFF718096),
            size: 24,
          ),
        ),
      ),
      dividerColor: borderColor,
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryColor,
        linearTrackColor: surfaceColor,
      ),
    );
  }

  // ──────────────────────────────────────────────────────
  // 2. DARK THEME (Black / Glowing Mint)
  // ──────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    const bgColor = Color(0xFF0B0E14);
    const surfaceColor = Color(0xFF121722);
    const cardColor = Color(0xFF1A202C);
    const primaryColor = Color(0xFF00D09C);
    const borderColor = Color(0xFF2D3748);
    const glowingBorderColor = Color(0xFF00D09C); // Subtle glow on cards in image
    const textColor = Color(0xFFFFFFFF);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgColor,
      canvasColor: bgColor,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        onPrimary: bgColor,
        secondary: Color(0xFF00B8D9),
        onSecondary: bgColor,
        surface: surfaceColor,
        onSurface: textColor,
        surfaceContainerHighest: cardColor,
        error: Color(0xFFEB5757),
        onError: textColor,
        outline: borderColor,
        outlineVariant: glowingBorderColor, // Used for special glowing borders if needed
      ),
      textTheme: _buildTextTheme(textColor, const Color(0xFFA0AEC0), const Color(0xFF718096)),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: _cardRadius,
          side: BorderSide(color: glowingBorderColor.withValues(alpha: 0.3), width: 1.5),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bgColor,
        foregroundColor: textColor,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w600, fontSize: 20, color: textColor),
        iconTheme: IconThemeData(color: textColor),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceColor,
        elevation: 0,
        height: 64,
        indicatorColor: primaryColor.withValues(alpha: 0.15),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => GoogleFonts.inter(
            color: states.contains(WidgetState.selected) ? primaryColor : const Color(0xFF718096),
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected) ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected) ? primaryColor : const Color(0xFF718096),
            size: 24,
          ),
        ),
      ),
      dividerColor: borderColor,
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryColor,
        linearTrackColor: surfaceColor,
      ),
    );
  }

  // ──────────────────────────────────────────────────────
  // 3. SPECIAL THEME (Deep Stock Green / Neon)
  // ──────────────────────────────────────────────────────
  static ThemeData get specialTheme {
    const bgColor = Color(0xFF03170E);
    const surfaceColor = Color(0xFF0A2318);
    const cardColor = Color(0xFF102A1F);
    const primaryColor = Color(0xFF00E5FF);
    const borderColor = Color(0xFF1E3A2F);
    const textColor = Color(0xFFFFFFFF);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgColor,
      canvasColor: bgColor,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        onPrimary: bgColor,
        secondary: Color(0xFF5E5CE6),
        onSecondary: bgColor,
        surface: surfaceColor,
        onSurface: textColor,
        surfaceContainerHighest: cardColor,
        error: Color(0xFFFF3366),
        onError: textColor,
        outline: borderColor,
      ),
      textTheme: _buildTextTheme(textColor, const Color(0xFFA0AABF), const Color(0xFF3E4659)),
      cardTheme: const CardThemeData(
        color: cardColor,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: _cardRadius,
          side: BorderSide(color: borderColor, width: 1.5),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bgColor,
        foregroundColor: textColor,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w600, fontSize: 20, color: textColor),
        iconTheme: IconThemeData(color: textColor),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceColor,
        elevation: 0,
        height: 64,
        indicatorColor: primaryColor.withValues(alpha: 0.22),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => GoogleFonts.inter(
            color: states.contains(WidgetState.selected) ? textColor : const Color(0xFFA0AABF),
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected) ? primaryColor : const Color(0xFFA0AABF),
            size: 24,
          ),
        ),
      ),
      dividerColor: borderColor,
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryColor,
        linearTrackColor: surfaceColor,
      ),
    );
  }
}
