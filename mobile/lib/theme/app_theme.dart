import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Brand Palette: Hijau Aqua / Teal Solid
  static const Color primary = Color(0xFF0D9488); // Hijau Aqua / Teal
  static const Color primaryDark = Color(0xFF0F766E); // Deep Aqua
  static const Color primaryLight = Color(0xFFCCFBF1); // Soft Aqua Tint
  static const Color primarySubtle = Color(0xFFF0FDFA); // Subtle Aqua Background
  static const Color dark = Color(0xFF0F172A); // Slate 900
  static const Color slate = Color(0xFF334155);
  static const Color muted = Color(0xFF64748B);
  static const Color mutedLight = Color(0xFF94A3B8);
  static const Color bgLight = Color(0xFFF8FAF9);
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color surfaceWhite = Color(0xFFFFFFFF);

  // Solid Accent Colors
  static const Color cardAqua = Color(0xFFF0FDFA);
  static const Color cardAquaBorder = Color(0xFF99F6E4);
  static const Color aquaAccent = Color(0xFF0D9488);

  static const Color cardWarm = Color(0xFFF8FAFC);
  static const Color cardWarmBorder = Color(0xFFE2E8F0);
  static const Color warmAccent = Color(0xFF0D9488);

  static const Color cardIndigo = Color(0xFFF0FDFA);
  static const Color cardIndigoBorder = Color(0xFFCCFBF1);
  static const Color indigoAccent = Color(0xFF0D9488);

  static const Color cardEmerald = Color(0xFFECFDF5);
  static const Color emeraldAccent = Color(0xFF0D9488);
  static const Color emeraldDot = Color(0xFF10B981);
}

class AppTheme {
  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme();

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.bgLight,
      colorScheme: ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.primaryLight,
        surface: AppColors.surfaceWhite,
        onSurface: AppColors.dark,
        outline: AppColors.borderLight,
      ),
      textTheme: baseTextTheme.copyWith(
        headlineLarge: GoogleFonts.plusJakartaSans(
          fontSize: 26,
          fontWeight: FontWeight.w800,
          color: AppColors.dark,
          letterSpacing: -0.5,
        ),
        headlineMedium: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.dark,
          letterSpacing: -0.3,
        ),
        titleLarge: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.dark,
        ),
        titleMedium: GoogleFonts.plusJakartaSans(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.dark,
        ),
        bodyLarge: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.slate,
        ),
        bodyMedium: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.normal,
          color: AppColors.muted,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: AppColors.dark,
          letterSpacing: -0.5,
        ),
        iconTheme: const IconThemeData(color: AppColors.dark),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.surfaceWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.borderLight, width: 1),
        ),
      ),
    );
  }
}
