// lib/utils/app_theme.dart
import 'package:flutter/material.dart';

class AppColors {
  // Warm cream + deep teal palette — playful but trustworthy
  static const Color bg          = Color(0xFFFDF8F2);       // warm cream
  static const Color bgCard      = Color(0xFFFFFFFF);
  static const Color teal        = Color(0xFF2D9B8A);       // primary teal
  static const Color tealLight   = Color(0xFFE0F5F2);
  static const Color tealDark    = Color(0xFF1D7A6C);
  static const Color coral       = Color(0xFFFF6B6B);       // alert/danger
  static const Color coralLight  = Color(0xFFFFEEEE);
  static const Color amber       = Color(0xFFFFB347);       // warning
  static const Color amberLight  = Color(0xFFFFF3E0);
  static const Color mint        = Color(0xFF4ECDC4);       // safe/online
  static const Color lavender    = Color(0xFF9B8FD4);       // community
  static const Color lavenderLight = Color(0xFFF0EEFF);
  static const Color textDark    = Color(0xFF1A2332);
  static const Color textMid     = Color(0xFF5A6A7A);
  static const Color textLight   = Color(0xFF9AABB8);
  static const Color divider     = Color(0xFFEEF2F5);
  static const Color shadow      = Color(0x14000000);
}

class AppTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.bg,
      primaryColor: AppColors.teal,
      fontFamily: 'Nunito',
      colorScheme: ColorScheme.light(
        primary: AppColors.teal,
        secondary: AppColors.mint,
        surface: AppColors.bgCard,
        error: AppColors.coral,
        onPrimary: Colors.white,
        onSurface: AppColors.textDark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.textDark,
          fontSize: 22,
          fontWeight: FontWeight.w800,
          fontFamily: 'Nunito',
        ),
        iconTheme: IconThemeData(color: AppColors.teal),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.teal,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            fontFamily: 'Nunito',
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        shadowColor: AppColors.shadow,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.divider,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.teal, width: 2),
        ),
      ),
    );
  }
}

// ── Spacing / radius helpers ────────────────────────────────────────────────
class Sp {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}