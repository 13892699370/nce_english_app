import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// iOS 风格磨砂卡片（Apple Liquid Glass 质感）
///
/// 半透明背景 + 柔和毛玻璃模糊，按压时透明度变化（非缩放）。
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
    this.blurRadius = 15,
    this.borderRadius = 12,
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
            ? const Color(0xCC1C1C1E)
            : const Color(0xCCFFFFFF));
    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: widget.margin ??
          const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: widget.blurRadius,
            sigmaY: widget.blurRadius,
          ),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 100),
            opacity: _pressed ? 0.6 : 1.0,
            child: Container(
              decoration: BoxDecoration(
                color: base,
                borderRadius: BorderRadius.circular(widget.borderRadius),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.08)
                      : Colors.black.withOpacity(0.04),
                  width: 0.5,
                ),
                boxShadow: widget.boxShadow ??
                    [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
              ),
              padding: widget.padding ?? const EdgeInsets.all(16),
              child: widget.child,
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
