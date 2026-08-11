import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Apple 原生风格主题：iOS 系统配色 + SF Pro 字体风格 + Cupertino 组件
class AppTheme {
  AppTheme._();

  // iOS 系统配色（浅色）
  static const Color kSystemBlue = Color(0xFF007AFF);
  static const Color kSystemGreen = Color(0xFF34C759);
  static const Color kSystemIndigo = Color(0xFF5856D6);
  static const Color kSystemOrange = Color(0xFFFF9500);
  static const Color kSystemPink = Color(0xFFFF2D55);
  static const Color kSystemPurple = Color(0xFFAF52DE);
  static const Color kSystemRed = Color(0xFFFF3B30);
  static const Color kSystemTeal = Color(0xFF5AC8FA);
  static const Color kSystemYellow = Color(0xFFFFCC00);

  // iOS 系统配色（深色）
  static const Color kSystemBlueDark = Color(0xFF0A84FF);
  static const Color kSystemGreenDark = Color(0xFF30D158);
  static const Color kSystemOrangeDark = Color(0xFFFF9F0A);
  static const Color kSystemRedDark = Color(0xFFFF453A);
  static const Color kSystemPurpleDark = Color(0xFFBF5AF2);
  static const Color kSystemYellowDark = Color(0xFFFFD60A);

  // 兼容旧代码的别名
  static const Color kPrimary = kSystemBlue;
  static const Color kPrimaryDark = kSystemBlueDark;
  static const Color kAccent = kSystemTeal;
  static const Color kDanger = kSystemRed;
  static const Color kWarn = kSystemOrange;
  static const Color kPurple = kSystemPurple;

  // iOS 背景色
  static const Color kGroupedBgLight = Color(0xFFF2F2F7);
  static const Color kGroupedBgDark = Color(0xFF000000);
  static const Color kCardBgLight = Color(0xFFFFFFFF);
  static const Color kCardBgDark = Color(0xFF1C1C1E);

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: kSystemBlue,
      brightness: Brightness.light,
    ).copyWith(
      primary: kSystemBlue,
      secondary: kSystemTeal,
      error: kSystemRed,
      surface: kCardBgLight,
      onSurface: const Color(0xFF000000),
    );
    return _base(scheme, Brightness.light);
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: kSystemBlueDark,
      brightness: Brightness.dark,
    ).copyWith(
      primary: kSystemBlueDark,
      secondary: kSystemTeal,
      error: kSystemRedDark,
      surface: kCardBgDark,
      onSurface: const Color(0xFFFFFFFF),
    );
    return _base(scheme, Brightness.dark);
  }

  /// Cupertino 主题数据（与 Material 主题同步）
  static CupertinoThemeData cupertinoTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return CupertinoThemeData(
      brightness: brightness,
      primaryColor: isDark ? kSystemBlueDark : kSystemBlue,
      scaffoldBackgroundColor: isDark ? kGroupedBgDark : kGroupedBgLight,
      barBackgroundColor: isDark
          ? const Color(0xE6161616)
          : const Color(0xF0F9F9F9),
      textTheme: CupertinoTextThemeData(
        primaryColor: isDark ? kSystemBlueDark : kSystemBlue,
        textStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w400,
          color: isDark ? Colors.white : Colors.black,
        ),
        navLargeTitleTextStyle: TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : Colors.black,
        ),
        navTitleTextStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : Colors.black,
        ),
        actionTextStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w400,
          color: isDark ? kSystemBlueDark : kSystemBlue,
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
        displayLarge: TextStyle(fontSize: 34, fontWeight: FontWeight.w700),
        displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
        titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        titleMedium: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        titleSmall: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(fontSize: 17, fontWeight: FontWeight.w400),
        bodyMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w400),
        bodySmall: TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
        labelLarge: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        labelMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        labelSmall: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: isDark ? kCardBgDark : kCardBgLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
            ? const Color(0xFF2C2C2E)
            : const Color(0xFFE5E5EA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark
            ? const Color(0xFF2C2C2E)
            : const Color(0xFF3C3C43),
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
