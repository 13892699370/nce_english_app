import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../services/theme_service.dart';
import '../theme/app_theme.dart';

/// Liquid Glass 胶囊风格主题切换按钮（同导航栏玻璃材质）
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

        const radius = 999.0;
        final blur = 28.0;
        final glassBase = isDark
            ? const Color(0xFF1B1B1B).withOpacity(0.55)
            : const Color(0xFFFFFFFF).withOpacity(0.52);
        final innerBorder = isDark
            ? Colors.white.withOpacity(0.18)
            : Colors.white.withOpacity(0.78);
        final outerBorder = isDark
            ? Colors.white.withOpacity(0.06)
            : const Color(0xFF000000).withOpacity(0.06);
        final iconColor = isDark ? AppTheme.kLuminaLime : AppTheme.kLuminaBlack;
        final shadows = isDark
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.40),
                  blurRadius: 22,
                  spreadRadius: -5,
                  offset: const Offset(0, 9),
                ),
              ]
            : [
                BoxShadow(
                  color: const Color(0xFF3A3A4A).withOpacity(0.16),
                  blurRadius: 24,
                  spreadRadius: -6,
                  offset: const Offset(0, 10),
                ),
              ];

        return GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) {
            setState(() => _pressed = false);
            ThemeService.instance.toggle();
          },
          child: AnimatedScale(
            duration: const Duration(milliseconds: 140),
            scale: _pressed ? 0.94 : 1.0,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: outerBorder,
                  width: 1.0,
                  strokeAlign: BorderSide.strokeAlignOutside,
                ),
                boxShadow: shadows,
              ),
              child: ClipOval(
                child: Stack(
                  children: [
                    // Blur
                    Positioned.fill(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                        child: const SizedBox.expand(),
                      ),
                    ),
                    // Base
                    Positioned.fill(child: ColoredBox(color: glassBase)),
                    // Inner border
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: innerBorder,
                            width: 0.8,
                            strokeAlign: BorderSide.strokeAlignInside,
                          ),
                        ),
                      ),
                    ),
                    // Top highlight
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: ClipOval(
                        child: SizedBox(
                          height: 24,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.white
                                      .withOpacity(isDark ? 0.18 : 0.60),
                                  Colors.white.withOpacity(0.0),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Icon
                    Center(
                      child: Icon(
                        isDark
                            ? CupertinoIcons.sun_max_fill
                            : CupertinoIcons.moon_fill,
                        size: 22,
                        color: iconColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
