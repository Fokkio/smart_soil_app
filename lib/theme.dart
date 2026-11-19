import 'package:flutter/material.dart';

/// Colour tokens taken from the revised UI mockup (smart_soil_ui_final_revised.svg).
class AppColors {
  static const ink = Color(0xFF17211C);
  static const muted = Color(0xFF68736D);
  static const hint = Color(0xFF9AA39E);
  static const green = Color(0xFF2F7D4A);
  static const dark = Color(0xFF123D2D);
  static const darkText = Color(0xFFE4F0E7);
  static const darkMuted = Color(0xFFA9C9B3);
  static const light = Color(0xFFEAF4EC);
  static const line = Color(0xFFE5EAE6);
  static const bg = Color(0xFFF8FAF8);
  static const amber = Color(0xFFD49717);
  static const amberText = Color(0xFF8A6210);
  static const amberBg = Color(0xFFFFF5DD);
  static const amberSoft = Color(0xFFFFF8E8);
  static const red = Color(0xFFC84A43);
  static const redBg = Color(0xFFFDECEA);
  static const blue = Color(0xFF3478B8);
  static const blueBg = Color(0xFFEDF5FB);
  static const grey = Color(0xFFF0F2F0);
  static const mapBg = Color(0xFFE3EEE5);
  static const mapPlot = Color(0xFFF4F9F5);
  static const mapRoad = Color(0xFFCFE0D3);
  static const chatBg = Color(0xFFF3F7F4);
}

/// Text styles used across screens.
class TS {
  static const h1 = TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.ink, height: 1.25);
  static const h2 = TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.ink);
  static const h3 = TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink);
  static const title = TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink);
  static const body = TextStyle(fontSize: 13, color: AppColors.ink, height: 1.45);
  static const small = TextStyle(fontSize: 12, color: AppColors.muted, height: 1.4);
  static const tiny = TextStyle(fontSize: 11, color: AppColors.muted, height: 1.4);
  static const label = TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.muted);
  static const value = TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.ink);
  static const link = TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.green);
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.green,
    primary: AppColors.green,
    surface: AppColors.bg,
  );
  final radius = BorderRadius.circular(12);
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.bg,
    dividerColor: AppColors.line,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bg,
      foregroundColor: AppColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.ink),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.green,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: radius),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.green,
        backgroundColor: Colors.white,
        minimumSize: const Size.fromHeight(46),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        side: const BorderSide(color: AppColors.line),
        shape: RoundedRectangleBorder(borderRadius: radius),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.green,
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      hintStyle: const TextStyle(color: AppColors.hint, fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: radius, borderSide: const BorderSide(color: AppColors.line)),
      enabledBorder: OutlineInputBorder(borderRadius: radius, borderSide: const BorderSide(color: AppColors.line)),
      focusedBorder: OutlineInputBorder(borderRadius: radius, borderSide: const BorderSide(color: AppColors.green, width: 1.5)),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}
