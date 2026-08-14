import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// 设计系统：Modern Clean
/// 灵感来源：Apple Fitness / Things 3 / Streaks
/// 单一主色调 Indigo，清爽留白，柔和阴影
class AppTheme {
  AppTheme._();

  // ---- 主色调 ----
  static const Color kIndigo = Color(0xFF5856D6);
  static const Color kIndigoLight = Color(0xFF7B79F0);
  static const Color kIndigoDark = Color(0xFF3D3B8F);

  // ---- 功能色 ----
  static const Color kSuccess = Color(0xFF34C759);
  static const Color kWarning = Color(0xFFFF9500);
  static const Color kDanger = Color(0xFFFF3B30);
  static const Color kInfo = Color(0xFF5AC8FA);

  // ---- 浅色模式 ----
  static const Color kBgLight = Color(0xFFF2F2F7);
  static const Color kCardLight = Color(0xFFFFFFFF);
  static const Color kTextLight = Color(0xFF1C1C1E);
  static const Color kSecondaryTextLight = Color(0xFF8E8E93);
  static const Color kSeparatorLight = Color(0xFFE5E5EA);

  // ---- 深色模式 ----
  static const Color kBgDark = Color(0xFF000000);
  static const Color kCardDark = Color(0xFF1C1C1E);
  static const Color kTextDark = Color(0xFFF2F2F7);
  static const Color kSecondaryTextDark = Color(0xFF8E8E93);
  static const Color kSeparatorDark = Color(0xFF38383A);

  // ---- 兼容旧代码的别名（逐步废弃） ----
  static const Color kLuminaBlack = kTextLight;
  static const Color kLuminaBg = kBgLight;
  static const Color kLuminaSurface = kCardLight;
  static const Color kLuminaSurfaceLow = Color(0xFFF2F2F7);
  static const Color kLuminaSurfaceHigh = Color(0xFFE5E5EA);
  static const Color kLuminaText = kTextLight;
  static const Color kLuminaMuted = kSecondaryTextLight;
  static const Color kLuminaOutline = kSeparatorLight;
  static const Color kLuminaLime = kIndigo;
  static const Color kLuminaLimeDim = kIndigoDark;
  static const Color kLuminaBgDark = kBgDark;
  static const Color kLuminaSurfaceDark = kCardDark;
  static const Color kLuminaSurfaceLowDark = Color(0xFF2C2C2E);
  static const Color kLuminaTextDark = kTextDark;
  static const Color kLuminaMutedDark = kSecondaryTextDark;
  static const Color kSystemBlue = kIndigo;
  static const Color kSystemGreen = kSuccess;
  static const Color kSystemIndigo = kIndigo;
  static const Color kSystemOrange = kWarning;
  static const Color kSystemPink = kDanger;
  static const Color kSystemPurple = kIndigo;
  static const Color kSystemRed = kDanger;
  static const Color kSystemTeal = kInfo;
  static const Color kSystemYellow = kWarning;
  static const Color kSystemBlueDark = kIndigoLight;
  static const Color kSystemGreenDark = kSuccess;
  static const Color kSystemOrangeDark = kWarning;
  static const Color kSystemRedDark = kDanger;
  static const Color kSystemPurpleDark = kIndigoLight;
  static const Color kSystemYellowDark = kWarning;
  static const Color kPrimary = kIndigo;
  static const Color kPrimaryDark = kIndigoLight;
  static const Color kAccent = kIndigo;
  static const Color kDanger = kDanger;
  static const Color kWarn = kWarning;
  static const Color kPurple = kIndigo;
  static const Color kGroupedBgLight = kBgLight;
  static const Color kGroupedBgDark = kBgDark;
  static const Color kCardBgLight = kCardLight;
  static const Color kCardBgDark = kCardDark;

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: kIndigo,
      brightness: Brightness.light,
    ).copyWith(
      primary: kIndigo,
      secondary: kIndigoLight,
      error: kDanger,
      surface: kCardLight,
      onSurface: kTextLight,
      outline: kSeparatorLight,
    );
    return _base(scheme, Brightness.light);
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: kIndigo,
      brightness: Brightness.dark,
    ).copyWith(
      primary: kIndigoLight,
      secondary: kIndigo,
      error: kDanger,
      surface: kCardDark,
      onSurface: kTextDark,
      outline: kSeparatorDark,
    );
    return _base(scheme, Brightness.dark);
  }

  static CupertinoThemeData cupertinoTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return CupertinoThemeData(
      brightness: brightness,
      primaryColor: isDark ? kIndigoLight : kIndigo,
      scaffoldBackgroundColor: isDark ? kBgDark : kBgLight,
      barBackgroundColor: isDark
          ? const Color(0xF01C1C1E)
          : const Color(0xF0F2F2F7),
      textTheme: CupertinoTextThemeData(
        primaryColor: isDark ? kIndigoLight : kIndigo,
        textStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: isDark ? kTextDark : kTextLight,
          decoration: TextDecoration.none,
        ),
        navLargeTitleTextStyle: TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          color: isDark ? kTextDark : kTextLight,
          decoration: TextDecoration.none,
        ),
        navTitleTextStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: isDark ? kTextDark : kTextLight,
          decoration: TextDecoration.none,
        ),
        actionTextStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: isDark ? kIndigoLight : kIndigo,
          decoration: TextDecoration.none,
        ),
      ),
    );
  }

  static ThemeData _base(ColorScheme scheme, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: isDark ? kBgDark : kBgLight,
      brightness: brightness,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      ),
      textTheme: const TextTheme().copyWith(
        displayLarge: TextStyle(fontSize: 40, fontWeight: FontWeight.w800, letterSpacing: -1.0),
        displayMedium: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -0.8),
        titleLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.5),
        titleMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
        titleSmall: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(fontSize: 17, fontWeight: FontWeight.w400, height: 1.5),
        bodyMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, height: 1.5),
        bodySmall: TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
        labelLarge: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        labelMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        labelSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: isDark ? kCardDark : kCardLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? kSeparatorDark : kSeparatorLight,
        thickness: 0.5,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? kCardDark : kTextLight,
        contentTextStyle: TextStyle(color: isDark ? kTextDark : Colors.white, fontSize: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
