import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Lumina Mono 视觉系统：黑白灰极简 + 荧光绿强调 + 超圆角软卡片
class AppTheme {
  AppTheme._();

  // 参考稿核心色
  static const Color kLuminaBlack = Color(0xFF1B1B1B);
  static const Color kLuminaBg = Color(0xFFF9F9FB);
  static const Color kLuminaSurface = Color(0xFFFFFFFF);
  static const Color kLuminaSurfaceLow = Color(0xFFF3F3F5);
  static const Color kLuminaSurfaceHigh = Color(0xFFE8E8EA);
  static const Color kLuminaText = Color(0xFF1A1C1D);
  static const Color kLuminaMuted = Color(0xFF4C4546);
  static const Color kLuminaOutline = Color(0xFFCFC4C5);
  static const Color kLuminaLime = Color(0xFFC6F341);
  static const Color kLuminaLimeDim = Color(0xFFAAD622);

  // 深色模式
  static const Color kLuminaBgDark = Color(0xFF111111);
  static const Color kLuminaSurfaceDark = Color(0xFF1B1B1B);
  static const Color kLuminaSurfaceLowDark = Color(0xFF242424);
  static const Color kLuminaTextDark = Color(0xFFF0F0F2);
  static const Color kLuminaMutedDark = Color(0xFFB8B8BA);

  // 兼容旧代码的别名
  static const Color kSystemBlue = kLuminaBlack;
  static const Color kSystemGreen = Color(0xFF4F6600);
  static const Color kSystemIndigo = kLuminaBlack;
  static const Color kSystemOrange = Color(0xFFFF9500);
  static const Color kSystemPink = Color(0xFFFF2D55);
  static const Color kSystemPurple = Color(0xFF527AFF);
  static const Color kSystemRed = Color(0xFFBA1A1A);
  static const Color kSystemTeal = Color(0xFF527AFF);
  static const Color kSystemYellow = kLuminaLime;
  static const Color kSystemBlueDark = kLuminaLime;
  static const Color kSystemGreenDark = kLuminaLime;
  static const Color kSystemOrangeDark = Color(0xFFFF9F0A);
  static const Color kSystemRedDark = Color(0xFFFF453A);
  static const Color kSystemPurpleDark = Color(0xFFB6C4FF);
  static const Color kSystemYellowDark = kLuminaLime;
  static const Color kPrimary = kLuminaBlack;
  static const Color kPrimaryDark = kLuminaLime;
  static const Color kAccent = kLuminaLime;
  static const Color kDanger = kSystemRed;
  static const Color kWarn = kSystemOrange;
  static const Color kPurple = kSystemPurple;

  static const Color kGroupedBgLight = kLuminaBg;
  static const Color kGroupedBgDark = kLuminaBgDark;
  static const Color kCardBgLight = kLuminaSurface;
  static const Color kCardBgDark = kLuminaSurfaceDark;

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: kLuminaBlack,
      brightness: Brightness.light,
    ).copyWith(
      primary: kLuminaBlack,
      secondary: kLuminaLime,
      error: kSystemRed,
      surface: kLuminaSurface,
      onSurface: kLuminaText,
      outline: kLuminaOutline,
    );
    return _base(scheme, Brightness.light);
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: kLuminaLime,
      brightness: Brightness.dark,
    ).copyWith(
      primary: kLuminaLime,
      secondary: kLuminaLime,
      error: kSystemRedDark,
      surface: kLuminaSurfaceDark,
      onSurface: kLuminaTextDark,
    );
    return _base(scheme, Brightness.dark);
  }

  /// Cupertino 主题数据（与 Material 主题同步）
  static CupertinoThemeData cupertinoTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return CupertinoThemeData(
      brightness: brightness,
      primaryColor: isDark ? kLuminaLime : kLuminaBlack,
      scaffoldBackgroundColor: isDark ? kGroupedBgDark : kGroupedBgLight,
      barBackgroundColor: isDark
          ? const Color(0xE61B1B1B)
          : const Color(0xF0F9F9FB),
      textTheme: CupertinoTextThemeData(
        primaryColor: isDark ? kLuminaLime : kLuminaBlack,
        textStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: isDark ? kLuminaTextDark : kLuminaText,
          decoration: TextDecoration.none,
        ),
        navLargeTitleTextStyle: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: isDark ? kLuminaTextDark : kLuminaText,
          decoration: TextDecoration.none,
        ),
        navTitleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: isDark ? kLuminaTextDark : kLuminaText,
          decoration: TextDecoration.none,
        ),
        actionTextStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: isDark ? kLuminaLime : kLuminaBlack,
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
      scaffoldBackgroundColor: isDark ? kGroupedBgDark : kGroupedBgLight,
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
        displayLarge: TextStyle(fontSize: 40, fontWeight: FontWeight.w700, letterSpacing: -0.8),
        displayMedium: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -0.6),
        titleLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
        titleMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
        titleSmall: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w400, height: 1.6),
        bodyMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, height: 1.5),
        bodySmall: TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
        labelLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        labelMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.6),
        labelSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: isDark ? kCardBgDark : kCardBgLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      dividerTheme: DividerThemeData(
        color: isDark
            ? const Color(0x38545458)
            : const Color(0x493C3C43),
        thickness: 0.5,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? kLuminaSurfaceLowDark
            : kLuminaSurfaceLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? kLuminaSurfaceLowDark : kLuminaBlack,
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }
}
