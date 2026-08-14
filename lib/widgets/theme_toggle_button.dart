import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../services/theme_service.dart';
import '../theme/app_theme.dart';

/// 简洁的 36×36 圆形主题切换按钮
/// 浅色模式显示 moon_fill（Indigo），深色模式显示 sun_max_fill（IndigoLight）
class ThemeToggleButton extends StatefulWidget {
  const ThemeToggleButton({super.key});

  @override
  State<ThemeToggleButton> createState() => _ThemeToggleButtonState();
}

class _ThemeToggleButtonState extends State<ThemeToggleButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeService.instance,
      builder: (context, _) {
        final isDark = ThemeService.instance.mode == ThemeMode.dark ||
            (ThemeService.instance.mode == ThemeMode.system &&
                MediaQuery.platformBrightnessOf(context) == Brightness.dark);

        final iconColor = isDark ? AppTheme.kIndigoLight : AppTheme.kIndigo;
        final bgColor =
            isDark ? AppTheme.kCardDark : AppTheme.kCardLight;

        return GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) {
            setState(() => _pressed = false);
            ThemeService.instance.toggle();
          },
          child: AnimatedScale(
            scale: _pressed ? 0.92 : 1.0,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.30 : 0.08),
                    blurRadius: 12,
                    spreadRadius: -3,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  isDark
                      ? CupertinoIcons.sun_max_fill
                      : CupertinoIcons.moon_fill,
                  size: 19,
                  color: iconColor,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
