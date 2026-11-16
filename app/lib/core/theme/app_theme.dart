import 'package:flutter/material.dart';
import 'colors.dart';
import 'spacing.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: ItqanColors.void_,
      colorScheme: const ColorScheme.dark(
        primary: ItqanColors.gold,
        secondary: ItqanColors.goldLight,
        surface: ItqanColors.onyx,
        error: ItqanColors.error,
        onPrimary: ItqanColors.void_,
        onSecondary: ItqanColors.void_,
        onSurface: ItqanColors.snow,
        onError: ItqanColors.void_,
      ),
      cardTheme: CardThemeData(
        color: ItqanColors.onyx,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ItqanRadius.lg),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: ItqanColors.void_,
        foregroundColor: ItqanColors.snow,
        elevation: 0,
        centerTitle: true,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: ItqanColors.obsidian,
        selectedItemColor: ItqanColors.gold,
        unselectedItemColor: ItqanColors.mist,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ItqanColors.charcoal,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ItqanRadius.md),
          borderSide: BorderSide.none,
        ),
      ),
      dividerColor: ItqanColors.charcoal,
      iconTheme: const IconThemeData(color: ItqanColors.silver),
    );
  }

  /// Vibrant, elegant Light Theme inspired by Ngaji AI (Emerald, Mint, and Warm Gold)
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: ItqanColors.lightBackground,
      colorScheme: const ColorScheme.light(
        primary: ItqanColors.ngajiEmerald,
        secondary: ItqanColors.ngajiGold,
        surface: ItqanColors.lightSurface,
        error: ItqanColors.mistakeIncorrect,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: ItqanColors.lightTextPrimary,
        onError: Colors.white,
      ),
      cardTheme: CardThemeData(
        color: ItqanColors.lightCard,
        elevation: 1.5,
        shadowColor: ItqanColors.ngajiEmerald.withOpacity(0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ItqanRadius.lg),
          side: const BorderSide(color: ItqanColors.lightBorder, width: 1.2),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: ItqanColors.lightBackground,
        foregroundColor: ItqanColors.lightTextPrimary,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: ItqanColors.lightTextPrimary),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: ItqanColors.ngajiEmerald,
        unselectedItemColor: Color(0xFF64748B),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: ItqanColors.ngajiEmerald,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ItqanRadius.md),
          borderSide: const BorderSide(color: ItqanColors.lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ItqanRadius.md),
          borderSide: const BorderSide(color: ItqanColors.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ItqanRadius.md),
          borderSide: const BorderSide(color: ItqanColors.ngajiEmerald, width: 1.8),
        ),
      ),
      dividerColor: ItqanColors.lightDivider,
      iconTheme: const IconThemeData(color: ItqanColors.lightTextSecondary),
    );
  }
}
