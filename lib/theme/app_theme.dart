import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// 设计系统：Duolingo Vibrant
/// 灵感来源：Duolingo（标志性 3D 立体按钮、鲜艳色块、游戏化）
/// 主色 #58CC02（Duo Green），辅以橙/蓝/红/紫鲜艳功能色
class AppTheme {
  AppTheme._();

  // ===== Duolingo 主色板 =====
  static const Color kDuoGreen = Color(0xFF58CC02);
  static const Color kDuoGreenDark = Color(0xFF58A700); // 3D 立体底边
  static const Color kDuoGreenLight = Color(0xFF89E219);

  // ===== 鲜艳功能色 =====
  static const Color kDuoBlue = Color(0xFF1CB0F6);
  static const Color kDuoBlueDark = Color(0xFF1899D6);
  static const Color kDuoOrange = Color(0xFFFF9600);
  static const Color kDuoOrangeDark = Color(0xFFE08600);
  static const Color kDuoRed = Color(0xFFFF4B4B);
  static const Color kDuoRedDark = Color(0xFFEA2B2B);
  static const Color kDuoPurple = Color(0xFFCE82FF);
  static const Color kDuoPurpleDark = Color(0xFFA560E8);
  static const Color kDuoYellow = Color(0xFFFFC800);
  static const Color kDuoYellowDark = Color(0xFFE0B100);

  // ===== 浅色模式中性色 =====
  static const Color kBgLight = Color(0xFFFFFFFF);
  static const Color kBgSecondaryLight = Color(0xFFF7F7F7);
  static const Color kCardLight = Color(0xFFFFFFFF);
  static const Color kTextLight = Color(0xFF3C3C3C);
  static const Color kSecondaryTextLight = Color(0xFF777777);
  static const Color kSeparatorLight = Color(0xFFE5E5E5);

  // ===== 深色模式中性色 =====
  static const Color kBgDark = Color(0xFF131F24);
  static const Color kBgSecondaryDark = Color(0xFF1B2A31);
  static const Color kCardDark = Color(0xFF1F2D34);
  static const Color kTextDark = Color(0xFFFFFFFF);
  static const Color kSecondaryTextDark = Color(0xFFAFAFAF);
  static const Color kSeparatorDark = Color(0xFF37474F);

  // ===== 兼容旧代码的别名（统一映射到 Duolingo 色板） =====
  // 主色别名
  static const Color kIndigo = kDuoGreen;
  static const Color kIndigoLight = kDuoGreenLight;
  static const Color kIndigoDark = kDuoGreenDark;
  static const Color kPrimary = kDuoGreen;
  static const Color kPrimaryDark = kDuoGreenLight;
  static const Color kAccent = kDuoGreen;
  static const Color kPurple = kDuoPurple;

  // 功能色别名
  static const Color kSuccess = kDuoGreen;
  static const Color kWarning = kDuoOrange;
  static const Color kDanger = kDuoRed;
  static const Color kInfo = kDuoBlue;
  static const Color kWarn = kDuoOrange;

  // System 色别名
  static const Color kSystemBlue = kDuoBlue;
  static const Color kSystemGreen = kDuoGreen;
  static const Color kSystemIndigo = kDuoGreen;
  static const Color kSystemOrange = kDuoOrange;
  static const Color kSystemPink = kDuoRed;
  static const Color kSystemPurple = kDuoPurple;
  static const Color kSystemRed = kDuoRed;
  static const Color kSystemTeal = kDuoBlue;
  static const Color kSystemYellow = kDuoYellow;
  static const Color kSystemBlueDark = kDuoBlue;
  static const Color kSystemGreenDark = kDuoGreen;
  static const Color kSystemOrangeDark = kDuoOrange;
  static const Color kSystemRedDark = kDuoRed;
  static const Color kSystemPurpleDark = kDuoPurple;
  static const Color kSystemYellowDark = kDuoYellow;

  // Lumina 旧别名
  static const Color kLuminaBlack = kTextLight;
  static const Color kLuminaBg = kBgLight;
  static const Color kLuminaSurface = kCardLight;
  static const Color kLuminaSurfaceLow = kBgSecondaryLight;
  static const Color kLuminaSurfaceHigh = kSeparatorLight;
  static const Color kLuminaText = kTextLight;
  static const Color kLuminaMuted = kSecondaryTextLight;
  static const Color kLuminaOutline = kSeparatorLight;
  static const Color kLuminaLime = kDuoGreen;
  static const Color kLuminaLimeDim = kDuoGreenDark;
  static const Color kLuminaBgDark = kBgDark;
  static const Color kLuminaSurfaceDark = kCardDark;
  static const Color kLuminaSurfaceLowDark = kBgSecondaryDark;
  static const Color kLuminaTextDark = kTextDark;
  static const Color kLuminaMutedDark = kSecondaryTextDark;

  // 其他别名
  static const Color kGroupedBgLight = kBgLight;
  static const Color kGroupedBgDark = kBgDark;
  static const Color kCardBgLight = kCardLight;
  static const Color kCardBgDark = kCardDark;

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: kDuoGreen,
      brightness: Brightness.light,
    ).copyWith(
      primary: kDuoGreen,
      secondary: kDuoBlue,
      error: kDuoRed,
      surface: kCardLight,
      onSurface: kTextLight,
      outline: kSeparatorLight,
    );
    return _base(scheme, Brightness.light);
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: kDuoGreen,
      brightness: Brightness.dark,
    ).copyWith(
      primary: kDuoGreen,
      secondary: kDuoBlue,
      error: kDuoRed,
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
      primaryColor: kDuoGreen,
      scaffoldBackgroundColor: isDark ? kBgDark : kBgLight,
      barBackgroundColor: isDark
          ? const Color(0xF01F2D34)
          : const Color(0xF0FFFFFF),
      textTheme: CupertinoTextThemeData(
        primaryColor: kDuoGreen,
        textStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: isDark ? kTextDark : kTextLight,
          decoration: TextDecoration.none,
        ),
        navLargeTitleTextStyle: TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
          color: isDark ? kTextDark : kTextLight,
          decoration: TextDecoration.none,
        ),
        navTitleTextStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: isDark ? kTextDark : kTextLight,
          decoration: TextDecoration.none,
        ),
        actionTextStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: kDuoGreen,
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
          fontWeight: FontWeight.w700,
        ),
      ),
      textTheme: const TextTheme().copyWith(
        displayLarge: TextStyle(fontSize: 40, fontWeight: FontWeight.w800, letterSpacing: -1.0),
        displayMedium: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -0.8),
        titleLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5),
        titleMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        titleSmall: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        bodyLarge: TextStyle(fontSize: 17, fontWeight: FontWeight.w500, height: 1.5),
        bodyMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, height: 1.5),
        bodySmall: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        labelLarge: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        labelMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        labelSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
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
        fillColor: isDark ? kBgSecondaryDark : kBgSecondaryLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? kCardDark : kTextLight,
        contentTextStyle: TextStyle(color: isDark ? kTextDark : Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
