import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'liquid_glass_card.dart';
import '../theme/app_theme.dart';

/// 当天全部任务完成后的全屏仪式感动画。
/// Indigo 渐变背景 + 居中卡片，1.5s 后自动消失。
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
      duration: const Duration(milliseconds: 1000),
    )..forward();
    Future.delayed(const Duration(milliseconds: 1500), () {
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
    final textColor =
        isDark ? AppTheme.kTextDark : AppTheme.kTextLight;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // 简洁渐变背景：Indigo → 深色
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.kIndigo.withOpacity(0.92),
                    isDark ? AppTheme.kBgDark : const Color(0xFF1C1C1E),
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: ScaleTransition(
              scale: CurvedAnimation(
                parent: _controller,
                curve: Curves.easeOutBack,
              ),
              child: LiquidGlassCard(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
                borderRadius: 24,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      CupertinoIcons.checkmark_seal_fill,
                      size: 60,
                      color: AppTheme.kIndigo,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '今日任务完成！',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '即将进入第${widget.nextDay}天',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: textColor.withOpacity(0.60),
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
