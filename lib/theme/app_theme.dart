import 'package:flutter/material.dart';

/// 应用主题：多邻国清新柔和配色 + iOS 液态玻璃质感
class AppTheme {
  AppTheme._();

  static const Color kPrimary = Color(0xFF58CC02); // 多邻国绿
  static const Color kPrimaryDark = Color(0xFF3FA800);
  static const Color kAccent = Color(0xFF1CB0F6); // 多邻国蓝
  static const Color kDanger = Color(0xFFFF4B4B);
  static const Color kWarn = Color(0xFFFFC800);
  static const Color kPurple = Color(0xFFCE82FF);

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: kPrimary,
      brightness: Brightness.light,
    ).copyWith(
      primary: kPrimary,
      secondary: kAccent,
      error: kDanger,
      surface: const Color(0xFFF7F9FC),
    );
    return _base(scheme, Brightness.light);
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: kPrimary,
      brightness: Brightness.dark,
    ).copyWith(
      primary: kPrimary,
      secondary: kAccent,
      error: kDanger,
      surface: const Color(0xFF121622),
    );
    return _base(scheme, Brightness.dark);
  }

  static ThemeData _base(ColorScheme scheme, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: isDark ? const Color(0xFF0E1117) : const Color(0xFFEEF2F8),
      brightness: brightness,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
      textTheme: const TextTheme().copyWith(
        titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        titleMedium: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
      ),
      cardTheme: CardTheme(
        elevation: 0,
        color: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: isDark ? const Color(0xFF1A1F2B) : Colors.white,
        selectedItemColor: kPrimary,
        unselectedItemColor: isDark ? Colors.white54 : Colors.black45,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
        type: BottomNavigationBarType.fixed,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
