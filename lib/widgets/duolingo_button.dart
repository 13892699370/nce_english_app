import 'dart:io' show Platform;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/haptic_service.dart';
import '../theme/app_theme.dart';

/// iOS Liquid Glass 风格按钮：
/// - 填充按钮：半透明底层 + 背景模糊 + 顶部高光 + 双层边框 + 多层阴影
/// - secondary：玻璃描边按钮
/// 所有变体保留 Duolingo API（variant/icon/minHeight 等）
enum DuolingoButtonVariant {
  primary,
  secondary,
  success,
  danger,
}

class DuolingoButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final DuolingoButtonVariant variant;
  final IconData? icon;
  final double borderRadius;
  final double minHeight;
  final bool fullwidth;
  final bool enableHaptic;

  const DuolingoButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = DuolingoButtonVariant.primary,
    this.icon,
    this.borderRadius = 18,
    this.minHeight = 50,
    this.fullwidth = true,
    this.enableHaptic = true,
  });

  @override
  State<DuolingoButton> createState() => _DuolingoButtonState();
}

class _DuolingoButtonState extends State<DuolingoButton>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late final AnimationController _pressController;

  static final bool _isLowEndDevice = Platform.numberOfProcessors < 4;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  void _onTapDown() {
    _pressed = true;
    _pressController.forward();
    setState(() {});
  }

  void _onTapCancel() {
    _pressed = false;
    _pressController.reverse();
    setState(() {});
  }

  void _onTapUp() {
    _pressed = false;
    _pressController.reverse();
    if (widget.enableHaptic) HapticService.light();
    widget.onPressed?.call();
    setState(() {});
  }

  /// 返回 (背景基础色, 文字色, 顶高光透明度)
  (Color, Color, double, Color) _surfaceColors(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (widget.variant) {
      case DuolingoButtonVariant.primary:
        return isDark
            ? (AppTheme.kLuminaLime.withOpacity(0.92), AppTheme.kLuminaBlack,
                0.55, AppTheme.kLuminaLime.withOpacity(0.5))
            : (AppTheme.kLuminaBlack.withOpacity(0.88), Colors.white, 0.14,
                AppTheme.kLuminaBlack.withOpacity(0.4));
      case DuolingoButtonVariant.success:
        return (
          AppTheme.kLuminaLime.withOpacity(0.92),
          AppTheme.kLuminaBlack,
          0.55,
          AppTheme.kLuminaLime.withOpacity(0.5)
        );
      case DuolingoButtonVariant.danger:
        final red = isDark ? AppTheme.kSystemRedDark : AppTheme.kSystemRed;
        return (red.withOpacity(0.90), Colors.white, 0.32, red.withOpacity(0.4));
      case DuolingoButtonVariant.secondary:
        return isDark
            ? (AppTheme.kLuminaSurfaceDark.withOpacity(0.55), AppTheme.kLuminaLime,
                0.14, AppTheme.kLuminaLime.withOpacity(0.35))
            : (const Color(0xFFFFFFFF).withOpacity(0.52), AppTheme.kLuminaBlack,
                0.45, AppTheme.kLuminaBlack.withOpacity(0.3));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSecondary = widget.variant == DuolingoButtonVariant.secondary;
    final disabled = widget.onPressed == null;
    final (base, fg, highlightAlpha, borderColor) = _surfaceColors(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final displayBase = disabled
        ? (isDark
            ? AppTheme.kLuminaSurfaceLowDark.withOpacity(0.6)
            : AppTheme.kLuminaSurfaceHigh.withOpacity(0.6))
        : base;
    final displayFg = disabled
        ? (isSecondary
            ? Colors.grey
            : (isDark ? Colors.white70 : Colors.white70))
        : fg;

    final blur = _isLowEndDevice ? 6.0 : 24.0;
    final pressScale = _isLowEndDevice ? 1.0 : 0.975;
    final radius = widget.borderRadius;

    final inner = GestureDetector(
      onTapDown: disabled ? null : (_) => _onTapDown(),
      onTapCancel: disabled ? null : _onTapCancel,
      onTapUp: disabled ? null : (_) => _onTapUp(),
      child: AnimatedBuilder(
        animation: _pressController,
        builder: (context, child) {
          final t = _pressController.value;
          final scale = 1.0 + (pressScale - 1.0) * t;
          return Transform.scale(
            scale: scale,
            child: child,
          );
        },
        child: Container(
          constraints: BoxConstraints(minHeight: widget.minHeight),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            boxShadow: disabled
                ? null
                : [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withOpacity(0.38)
                          : borderColor.withOpacity(isSecondary ? 0.0 : 0.28),
                      blurRadius: 20,
                      spreadRadius: -4,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withOpacity(0.18)
                          : const Color(0xFF3A3A4A).withOpacity(0.06),
                      blurRadius: 8,
                      spreadRadius: -1,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: Stack(
              children: [
                // —— Liquid Glass 核心：模糊层（对填充按钮主要是增强；对 secondary 是关键） ——
                if (!disabled && !_isLowEndDevice)
                  Positioned.fill(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                      child: const SizedBox.expand(),
                    ),
                  ),

                // —— 底色 ——
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: isSecondary ? Colors.transparent : displayBase,
                      borderRadius: BorderRadius.circular(radius),
                      border: Border.all(
                        color: isSecondary
                            ? (isDark
                                ? Colors.white.withOpacity(0.12)
                                : const Color(0xFF000000).withOpacity(0.08))
                            : Colors.white.withOpacity(highlightAlpha * 0.32),
                        width: 0.9,
                        strokeAlign: BorderSide.strokeAlignInside,
                      ),
                    ),
                  ),
                ),

                // —— 顶部弧形高光 ——
                if (!disabled)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: ClipRRect(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(radius)),
                      child: SizedBox(
                        height: widget.minHeight * 0.62,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.white.withOpacity(highlightAlpha),
                                Colors.white.withOpacity(0.0),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                // —— 下边缘吸光阴影 ——
                if (!disabled)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: radius * 0.8,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(isDark ? 0.22 : 0.06),
                          ],
                        ),
                      ),
                    ),
                  ),

                // —— 内容 ——
                Row(
                  mainAxisSize:
                      widget.fullwidth ? MainAxisSize.max : MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, color: displayFg, size: 19),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Text(
                        widget.label,
                        style: TextStyle(
                          color: displayFg,
                          fontSize: 17,
                          fontWeight: isSecondary
                              ? FontWeight.w500
                              : FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return widget.fullwidth
        ? SizedBox(width: double.infinity, child: inner)
        : inner;
  }
}
