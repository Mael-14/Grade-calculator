import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// GradeGenie design system – colours, typography, and component themes.
class AppTheme {
  AppTheme._();

  // ── Brand Colours ─────────────────────────────────────────────────
  static const Color primary = Color(0xFF4A6CF7);
  static const Color primaryLight = Color(0xFFE8EDFF);
  static const Color accent = Color(0xFF6C63FF);
  static const Color background = Color(0xFFF5F7FF);
  static const Color surface = Colors.white;
  static const Color textDark = Color(0xFF1E2432);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFFBBF24);
  static const Color error = Color(0xFFEF4444);
  static const Color cardBorder = Color(0xFFE5E7EB);

  // ── Gradients ─────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF4A6CF7), Color(0xFF6C63FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient softGradient = LinearGradient(
    colors: [Color(0xFFE8EDFF), Color(0xFFF5F7FF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ── Border Radius ─────────────────────────────────────────────────
  static final BorderRadius radiusSm = BorderRadius.circular(8);
  static final BorderRadius radiusMd = BorderRadius.circular(12);
  static final BorderRadius radiusLg = BorderRadius.circular(16);
  static final BorderRadius radiusXl = BorderRadius.circular(24);

  // ── Shadows ───────────────────────────────────────────────────────
  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: primary.withValues(alpha: 0.08),
      blurRadius: 20,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 10,
      offset: const Offset(0, 2),
    ),
  ];

  // ── ThemeData ─────────────────────────────────────────────────────
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      surface: surface,
      error: error,
    ),
    textTheme: GoogleFonts.interTextTheme().copyWith(
      headlineLarge: GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: textDark,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: textDark,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textDark,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: textDark,
      ),
      bodyLarge: GoogleFonts.inter(fontSize: 16, color: textDark),
      bodyMedium: GoogleFonts.inter(fontSize: 14, color: textMuted),
      bodySmall: GoogleFonts.inter(fontSize: 12, color: textMuted),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: radiusMd),
        textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        side: const BorderSide(color: primary),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: radiusMd),
      ),
    ),
    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: radiusMd,
        side: const BorderSide(color: cardBorder, width: 1),
      ),
      margin: EdgeInsets.zero,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: surface,
      foregroundColor: textDark,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textDark,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: background,
      border: OutlineInputBorder(
        borderRadius: radiusMd,
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  );
}
