import 'dart:ui';
import 'package:flutter/material.dart';

/// 液态玻璃磨砂卡片（iOS 质感 + 双端统一表现）
///
/// 使用 BackdropFilter 实现毛玻璃效果，叠加渐变高光与柔和阴影。
/// 不依赖任何平台专属 API，Android / iOS 表现一致。
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

  const LiquidGlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.blurRadius = 18,
    this.borderRadius = 24,
    this.glassColor,
    this.boxShadow,
    this.onTap,
    this.enableHaptic = false,
  });

  @override
  State<LiquidGlassCard> createState() => _LiquidGlassCardState();
}

class _LiquidGlassCardState extends State<LiquidGlassCard> {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final base = widget.glassColor ??
        (isDark
            ? Colors.white.withOpacity(0.08)
            : Colors.white.withOpacity(0.55));
    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutBack,
      margin: widget.margin ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      transform: Matrix4.identity()..scale(_pressed ? 0.97 : 1.0),
      transformAlignment: Alignment.center,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: widget.blurRadius,
            sigmaY: widget.blurRadius,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: base,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.12)
                    : Colors.white.withOpacity(0.7),
                width: 1.2,
              ),
              boxShadow: widget.boxShadow ??
                  [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(isDark ? 0.10 : 0.35),
                  Colors.white.withOpacity(0.0),
                ],
              ),
            ),
            padding: widget.padding ?? const EdgeInsets.all(16),
            child: widget.child,
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
