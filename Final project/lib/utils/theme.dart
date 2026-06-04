import 'package:flutter/material.dart';

class AppColors {
  static const Color primary      = Color(0xFF1D9E75);
  static const Color primaryDark  = Color(0xFF085041);
  static const Color primaryLight = Color(0xFFE1F5EE);
  static const Color accent       = Color(0xFFD85A30);
  static const Color accentLight  = Color(0xFFFAECE7);
  static const Color amber        = Color(0xFFBA7517);
  static const Color amberLight   = Color(0xFFFAEEDA);
  static const Color blue         = Color(0xFF378ADD);
  static const Color blueLight    = Color(0xFFE6F1FB);
  static const Color gray50       = Color(0xFFF1EFE8);
  static const Color gray100      = Color(0xFFD3D1C7);
  static const Color gray400      = Color(0xFF888780);
  static const Color gray800      = Color(0xFF444441);
}

class AppTheme {
  static ThemeData get light => _build(false);
  static ThemeData get dark  => _build(true);

  static ThemeData _build(bool isDark) {
    final bg       = isDark ? const Color(0xFF121212) : const Color(0xFFF8F7F4);
    final surface  = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final onSurface= isDark ? Colors.white : AppColors.gray800;
    final border   = isDark ? const Color(0x30FFFFFF) : const Color(0x14000000);
    final fillColor= isDark ? const Color(0xFF2A2A2A) : AppColors.gray50;

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: surface,
        brightness: isDark ? Brightness.dark : Brightness.light,
      ),
      scaffoldBackgroundColor: bg,
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: onSurface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        shadowColor: const Color(0x18000000),
        titleTextStyle: TextStyle(
          fontSize: 17, fontWeight: FontWeight.w600,
          color: onSurface, letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0, color: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: border, width: 0.5),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: fillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        hintStyle: const TextStyle(color: AppColors.gray400, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary, foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: border, thickness: 0.5, space: 0,
      ),
    );
  }
}
