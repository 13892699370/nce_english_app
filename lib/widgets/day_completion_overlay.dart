import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'liquid_glass_card.dart';
import '../theme/app_theme.dart';

/// 当天全部任务完成后的全屏仪式感动画。
class DayCompletionOverlay extends StatefulWidget {
  final int nextDay;

  const DayCompletionOverlay({
    super.key,
    required this.nextDay,
  });

  static Future<void> show(BuildContext context, {required int nextDay}) async {
    await Navigator.of(context).push<void>(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.black.withOpacity(0.10),
        pageBuilder: (_, __, ___) => DayCompletionOverlay(nextDay: nextDay),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  State<DayCompletionOverlay> createState() => _DayCompletionOverlayState();
}

class _DayCompletionOverlayState extends State<DayCompletionOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
    Future.delayed(const Duration(milliseconds: 1250), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurfaceColor = isDark ? Colors.white : Colors.black;
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    (isDark
                            ? AppTheme.kSystemBlueDark
                            : AppTheme.kSystemBlue)
                        .withOpacity(0.20),
                    AppTheme.kSystemTeal.withOpacity(0.18),
                    (isDark
                            ? AppTheme.kCardBgDark
                            : AppTheme.kCardBgLight)
                        .withOpacity(0.84),
                  ],
                ),
              ),
            ),
          ),
          ...List.generate(8, (i) {
            final angle = i * (math.pi / 4);
            return AnimatedBuilder(
              animation: _controller,
              builder: (_, __) {
                final t = Curves.easeOut.transform(_controller.value);
                final radius = 46 + t * size.width * 0.42;
                return Positioned(
                  left: size.width / 2 + math.cos(angle) * radius,
                  top: size.height / 2 + math.sin(angle) * radius,
                  child: Opacity(
                    opacity: (1 - t).clamp(0.0, 1.0),
                    child: Transform.rotate(
                      angle: angle + t,
                      child: Icon(
                        CupertinoIcons.star_fill,
                        size: 22,
                        color: (isDark
                                ? AppTheme.kSystemYellowDark
                                : AppTheme.kSystemYellow)
                            .withOpacity(0.90),
                      ),
                    ),
                  ),
                );
              },
            );
          }),
          Center(
            child: ScaleTransition(
              scale: CurvedAnimation(
                parent: _controller,
                curve: Curves.easeOut,
              ),
              child: LiquidGlassCard(
                margin: const EdgeInsets.symmetric(horizontal: 28),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 34),
                borderRadius: 16,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CupertinoIcons.checkmark_seal_fill,
                      size: 56,
                      color: isDark
                          ? AppTheme.kSystemGreenDark
                          : AppTheme.kSystemGreen,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      '今天全部完成！',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: onSurfaceColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '即将进入第 ${widget.nextDay} 天学习',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: onSurfaceColor.withOpacity(0.60),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
