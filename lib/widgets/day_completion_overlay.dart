import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'liquid_glass_card.dart';

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
      duration: const Duration(milliseconds: 1600),
    )..forward();
    Future.delayed(const Duration(milliseconds: 1650), () {
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
    final theme = Theme.of(context);
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
                    const Color(0xFF58CC02).withOpacity(0.24),
                    const Color(0xFF1CB0F6).withOpacity(0.22),
                    theme.colorScheme.surface.withOpacity(0.84),
                  ],
                ),
              ),
            ),
          ),
          ...List.generate(18, (i) {
            final angle = i * math.pi / 9;
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
                      child: Text(
                        ['✨', '⭐', '💚', '🎉'][i % 4],
                        style: const TextStyle(fontSize: 24),
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
                curve: Curves.elasticOut,
              ),
              child: LiquidGlassCard(
                margin: const EdgeInsets.symmetric(horizontal: 28),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 34),
                borderRadius: 34,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🎉', style: TextStyle(fontSize: 74)),
                    const SizedBox(height: 12),
                    Text(
                      '今天全部完成！',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '即将进入第 ${widget.nextDay} 天学习',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface.withOpacity(0.66),
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
