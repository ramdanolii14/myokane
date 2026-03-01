import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/app_settings.dart';

// Light color scheme
class LightColors {
  static const bg = Color(0xFFF8FAFC);
  static const surface = Color(0xFFFFFFFF);
  static const surface2 = Color(0xFFF1F5F9);
  static const border = Color(0xFFE2E8F0);
  static const textPrimary = Color(0xFF0F172A);
  static const textMuted = Color(0xFF94A3B8);
}

// Dark color scheme
class DarkColors {
  static const bg = Color(0xFF0D0F14);
  static const surface = Color(0xFF161A24);
  static const surface2 = Color(0xFF1E2332);
  static const border = Color(0xFF252B3B);
  static const textPrimary = Color(0xFFE2E8F0);
  static const textMuted = Color(0xFF64748B);
}

// Always fixed
const incomeColor = Color(0xFF34D399);
const expenseColor = Color(0xFFFB7185);

class AppTheme {
  final bool isDark;
  final Color accent;

  AppTheme({required this.isDark, required this.accent});

  Color get bg => isDark ? DarkColors.bg : LightColors.bg;
  Color get surface => isDark ? DarkColors.surface : LightColors.surface;
  Color get surface2 => isDark ? DarkColors.surface2 : LightColors.surface2;
  Color get border => isDark ? DarkColors.border : LightColors.border;
  Color get textPrimary =>
      isDark ? DarkColors.textPrimary : LightColors.textPrimary;
  Color get textMuted => isDark ? DarkColors.textMuted : LightColors.textMuted;

  Color get cardGradientStart =>
      isDark ? const Color(0xFF1a2744) : const Color(0xFFEFF6FF);
  Color get cardGradientEnd =>
      isDark ? const Color(0xFF0e1929) : const Color(0xFFDBEAFE);
  Color get cardBorder =>
      isDark ? const Color(0xFF1e3a5a) : const Color(0xFFBFDBFE);

  ThemeData toThemeData() {
    final textTheme = GoogleFonts.nunitoTextTheme(
      isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
    );
    return ThemeData(
      brightness: isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme(
        brightness: isDark ? Brightness.dark : Brightness.light,
        primary: accent,
        onPrimary: isDark ? const Color(0xFF0D0F14) : Colors.white,
        secondary: accent.withOpacity(0.7),
        onSecondary: Colors.white,
        surface: surface,
        onSurface: textPrimary,
        error: expenseColor,
        onError: Colors.white,
      ),
      textTheme: textTheme,
      appBarTheme:
          AppBarTheme(backgroundColor: bg, elevation: 0, centerTitle: false),
      useMaterial3: true,
    );
  }
}

AppTheme buildAppTheme(AppSettings settings) =>
    AppTheme(isDark: settings.isDark, accent: settings.accentColor);
