import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primary = Color(0xFF00C853);
  static const Color primaryDark = Color(0xFF00A846);
  static const Color primaryLight = Color(0xFF69F0AE);
  static const Color background = Color(0xFF050D0A);
  static const Color surface = Color(0xFF0D1F15);
  static const Color surfaceLight = Color(0xFF132A1C);
  static const Color card = Color(0xFF0F2318);
  static const Color cardBorder = Color(0xFF1E4D2E);
  static const Color haram = Color(0xFFEF4444);
  static const Color haramLight = Color(0xFFFF6B6B);
  static const Color doubtful = Color(0xFFEAB308);
  static const Color doubtfulLight = Color(0xFFFBBF24);
  static const Color textPrimary = Color(0xFFF0FDF4);
  static const Color textSecondary = Color(0xFF86EFAC);
  static const Color textMuted = Color(0xFF4B7B5C);
  static const Color glass = Color(0x1A00C853);
  static const Color glassBorder = Color(0x2600C853);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: primaryLight,
        background: background,
        surface: surface,
        onPrimary: Colors.white,
        onBackground: textPrimary,
        onSurface: textPrimary,
        error: haram,
      ),
      scaffoldBackgroundColor: background,
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: GoogleFonts.outfit(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: primary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        hintStyle: GoogleFonts.outfit(color: textMuted),
        labelStyle: GoogleFonts.outfit(color: textSecondary),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600),
          elevation: 0,
        ),
      ),
      cardTheme: CardTheme(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: cardBorder),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: primary,
        unselectedItemColor: textMuted,
        elevation: 0,
      ),
      dividerColor: cardBorder,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
    );
  }
}
