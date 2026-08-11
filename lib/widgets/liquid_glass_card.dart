import 'dart:io' show Platform;
import 'dart:ui';
import 'package:flutter/material.dart';

/// iOS Liquid Glass 风格磨砂卡片
///
/// 增强版：渐变高光 + 弹性按压 + 低端设备自动降级。
/// 半透明背景 + BackdropFilter 模糊 + 顶部高光渐变 + 柔和阴影。
/// 低端设备（CPU<4核）自动降低模糊半径至40%、关闭高光与弹性动画。
class LiquidGlassCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double blurRadius;
  final double borderRadius;
  final Color? glassColor;
  final List<BoxShadow>? boxShadow;
  final VoidCallback? onTap;
  final bool enableHaptic;
  final bool enableHighlight;

  const LiquidGlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.blurRadius = 15,
    this.borderRadius = 12,
    this.glassColor,
    this.boxShadow,
    this.onTap,
    this.enableHaptic = false,
    this.enableHighlight = true,
  });

  @override
  State<LiquidGlassCard> createState() => _LiquidGlassCardState();
}

class _LiquidGlassCardState extends State<LiquidGlassCard>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late final AnimationController _pressController;

  static final bool _isLowEndDevice = Platform.numberOfProcessors < 4;

  double get _effectiveBlur =>
      _isLowEndDevice ? widget.blurRadius * 0.4 : widget.blurRadius;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  void _setPressed(bool v) {
    if (_pressed == v) return;
    _pressed = v;
    if (v) {
      _pressController.forward();
    } else {
      _pressController.reverse();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final base = widget.glassColor ??
        (isDark
            ? const Color(0xCC1C1C1E)
            : const Color(0xCCFFFFFF));

    final pressScale = _isLowEndDevice ? 1.0 : 0.97;

    final content = AnimatedBuilder(
      animation: _pressController,
      builder: (context, child) {
        final t = _pressController.value;
        final scale = 1.0 + (pressScale - 1.0) * t;
        final opacity = 1.0 - 0.4 * t;
        return Transform.scale(
          scale: scale,
          child: Opacity(opacity: opacity, child: child),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: widget.margin ??
            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: _effectiveBlur,
              sigmaY: _effectiveBlur,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: base,
                borderRadius: BorderRadius.circular(widget.borderRadius),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.10)
                      : Colors.white.withOpacity(0.60),
                  width: 0.5,
                ),
                boxShadow: widget.boxShadow ??
                    [
                      BoxShadow(
                        color: Colors.black
                            .withOpacity(isDark ? 0.3 : 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
              ),
              child: Stack(
                children: [
                  if (widget.enableHighlight && !_isLowEndDevice)
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius:
                            BorderRadius.circular(widget.borderRadius),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white
                                    .withOpacity(isDark ? 0.06 : 0.18),
                                Colors.white.withOpacity(0.0),
                              ],
                              stops: const [0.0, 0.5],
                            ),
                          ),
                        ),
                      ),
                    ),
                  Padding(
                    padding:
                        widget.padding ?? const EdgeInsets.all(16),
                    child: widget.child,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (widget.onTap == null) return content;
    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapCancel: () => _setPressed(false),
      onTapUp: (_) {
        _setPressed(false);
        widget.onTap?.call();
      },
      child: content,
    );
  }
}
