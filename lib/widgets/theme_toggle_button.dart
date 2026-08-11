import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../services/theme_service.dart';

/// iOS 风格主题切换按钮（用于 NavigationBar trailing）
class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeService.instance,
      builder: (context, _) {
        final isDark = ThemeService.instance.mode == ThemeMode.dark ||
            (ThemeService.instance.mode == ThemeMode.system &&
                MediaQuery.platformBrightnessOf(context) == Brightness.dark);
        return CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => ThemeService.instance.toggle(),
          child: Icon(
            isDark ? CupertinoIcons.sun_max_fill : CupertinoIcons.moon_fill,
            size: 22,
          ),
        );
      },
    );
  }
}
