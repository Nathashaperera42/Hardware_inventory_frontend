import 'package:flutter/material.dart';

class AppColors {
  // ── Purple brand palette ───────────────────────────────────────────────────
  static const primary     = Color(0xFF7C3AED); // violet-600
  static const primaryDark = Color(0xFF6D28D9); // violet-700

  // Sidebar
  static const sidebar       = Color(0xFF2E1065); // violet-950
  static const sidebarActive = Color(0xFF7C3AED); // same as primary

  // Dashboard banner gradient
  static const bannerStart = Color(0xFF7C3AED);
  static const bannerEnd   = Color(0xFF4F46E5); // indigo-600

  // Surfaces
  static const scaffold = Color(0xFFF5F3FF); // very-light-violet tint
  static const surface  = Colors.white;
  static const border   = Color(0xFFE4E2FF); // light violet border

  // Text
  static const textPrimary = Color(0xFF1E1B4B); // indigo-950
  static const textMuted   = Color(0xFF6B7280);

  // Semantic
  static const good = Color(0xFF059669); // emerald-600
  static const low  = Color(0xFFF59E0B); // amber-500
  static const out  = Color(0xFFDC2626); // red-600

  static const Map<String, Color> statusColors = {
    'Good Stock' : good,
    'Low Stock'  : low,
    'Out of Stock': out,
  };
}

class AppTheme {
  static ThemeData light() {
    const cs = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.primaryDark,
      onSecondary: Colors.white,
      error: AppColors.out,
      onError: Colors.white,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: AppColors.scaffold,
      fontFamily: 'Inter',

      // Cards
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
      ),

      // Inputs
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: AppColors.primary, width: 1.8),
        ),
        labelStyle:
            const TextStyle(color: AppColors.textMuted, fontSize: 14),
        hintStyle:
            const TextStyle(color: AppColors.textMuted, fontSize: 14),
      ),

      // Elevated buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(
              fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),

      // Outlined buttons
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(
              fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),

      // Text buttons
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),

      // DataTable
      dataTableTheme: DataTableThemeData(
        headingTextStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 12,
          color: AppColors.textMuted,
          letterSpacing: 0.4,
        ),
        dataTextStyle: const TextStyle(
          fontSize: 14,
          color: AppColors.textPrimary,
        ),
        dividerThickness: 1,
        decoration: const BoxDecoration(color: Colors.transparent),
      ),
    );
  }
}
