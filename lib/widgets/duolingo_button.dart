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

  /// 返回 (背景基础色, 文字色, 顶高光透明度, 边框tint色, 高光sharp opacity)
  (Color, Color, double, Color, double) _surfaceColors(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (widget.variant) {
      case DuolingoButtonVariant.primary:
        return isDark
            ? (AppTheme.kLuminaLime.withOpacity(0.90), AppTheme.kLuminaBlack,
                0.52, AppTheme.kLuminaLime.withOpacity(0.5), 0.92)
            : (AppTheme.kLuminaBlack.withOpacity(0.86), Colors.white, 0.12,
                AppTheme.kLuminaBlack.withOpacity(0.4), 0.72);
      case DuolingoButtonVariant.success:
        return (
          AppTheme.kLuminaLime.withOpacity(0.90),
          AppTheme.kLuminaBlack,
          0.52,
          AppTheme.kLuminaLime.withOpacity(0.5),
          0.92
        );
      case DuolingoButtonVariant.danger:
        final red = isDark ? AppTheme.kSystemRedDark : AppTheme.kSystemRed;
        return (red.withOpacity(0.88), Colors.white, 0.30,
            red.withOpacity(0.42), 0.82);
      case DuolingoButtonVariant.secondary:
        return isDark
            ? (const Color(0xFF1B1B1B).withOpacity(0.36), AppTheme.kLuminaLime,
                0.14, AppTheme.kLuminaLime.withOpacity(0.40), 0.44)
            : (const Color(0xFFFFFFFF).withOpacity(0.30), AppTheme.kLuminaBlack,
                0.44, AppTheme.kLuminaBlack.withOpacity(0.32), 0.88);
    }
  }

  static List<double> _satMatrix(double sat) {
    const r = 0.213, g = 0.715, b = 0.072;
    return [
      r * (1 - sat) + sat, g * (1 - sat), b * (1 - sat), 0, 0,
      r * (1 - sat), g * (1 - sat) + sat, b * (1 - sat), 0, 0,
      r * (1 - sat), g * (1 - sat), b * (1 - sat) + sat, 0, 0,
      0, 0, 0, 1, 0,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isSecondary = widget.variant == DuolingoButtonVariant.secondary;
    final disabled = widget.onPressed == null;
    final (base, fg, highlightAlpha, borderTint, sharpHighlightAlpha) =
        _surfaceColors(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final displayBase = disabled
        ? (isDark
            ? AppTheme.kLuminaSurfaceLowDark.withOpacity(0.55)
            : AppTheme.kLuminaSurfaceHigh.withOpacity(0.55))
        : base;
    final displayFg = disabled
        ? (isSecondary
            ? Colors.grey
            : (isDark ? Colors.white70 : Colors.white70))
        : fg;

    final blur = _isLowEndDevice ? 6.0 : 30.0;
    final pressScale = _isLowEndDevice ? 1.0 : 0.975;
    final radius = widget.borderRadius;

    final innerBorder = isSecondary
        ? (isDark
            ? Colors.white.withOpacity(0.22)
            : Colors.white.withOpacity(0.82))
        : Colors.white.withOpacity(highlightAlpha * 0.38);
    final outerBorder = isDark
        ? Colors.white.withOpacity(0.05)
        : const Color(0xFF000000).withOpacity(0.05);

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
            border: Border.all(
              color: outerBorder,
              width: 1.0,
              strokeAlign: BorderSide.strokeAlignOutside,
            ),
            boxShadow: disabled
                ? null
                : [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withOpacity(0.46)
                          : borderTint.withOpacity(isSecondary ? 0.0 : 0.32),
                      blurRadius: 26,
                      spreadRadius: -5,
                      offset: const Offset(0, 10),
                    ),
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withOpacity(0.20)
                          : const Color(0xFF3A3A4A).withOpacity(0.08),
                      blurRadius: 10,
                      spreadRadius: -1,
                      offset: const Offset(0, 4),
                    ),
                    // iOS 18 tinted shadow (第二层染色)
                    if (!isSecondary)
                      BoxShadow(
                        color: borderTint.withOpacity(0.12),
                        blurRadius: 6,
                        spreadRadius: -1,
                        offset: const Offset(0, 2),
                      ),
                  ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: Stack(
              children: [
                // 1) Blur + iOS 18 saturation boost × 1.6
                if (!disabled && !_isLowEndDevice)
                  Positioned.fill(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                          sigmaX: blur, sigmaY: blur, tileMode: TileMode.decal),
                      child: ColorFiltered(
                        colorFilter: ColorFilter.matrix(_satMatrix(1.6)),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),

                // 2) 底色 + 三段渐变
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color.alphaBlend(
                              Colors.white.withOpacity(highlightAlpha * 0.55),
                              displayBase),
                          displayBase,
                          Color.alphaBlend(
                              Colors.black.withOpacity(
                                  isDark ? 0.18 : (isSecondary ? 0.05 : 0.03)),
                              displayBase),
                        ],
                        stops: const [0.0, 0.55, 1.0],
                      ),
                      color: isSecondary ? Colors.transparent : null,
                      borderRadius: BorderRadius.circular(radius),
                      border: Border.all(
                        color: innerBorder,
                        width: 0.85,
                        strokeAlign: BorderSide.strokeAlignInside,
                      ),
                    ),
                  ),
                ),

                // 3) iOS 18 Sharp 顶部高光（锐利亮边 + 快速渐隐）
                if (!disabled)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: ClipRRect(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(radius)),
                      child: SizedBox(
                        height: widget.minHeight * 0.42,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.white.withOpacity(sharpHighlightAlpha),
                                Colors.white.withOpacity(highlightAlpha * 0.65),
                                Colors.white.withOpacity(0.0),
                              ],
                              stops: const [0.0, 0.30, 1.0],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                // 4) 对角线微光
                if (!disabled)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withOpacity(isDark ? 0.04 : 0.14),
                            Colors.white.withOpacity(0.0),
                            Colors.white.withOpacity(0.0),
                            Colors.black.withOpacity(isDark ? 0.14 : 0.03),
                          ],
                          stops: const [0.0, 0.40, 0.75, 1.0],
                        ).createShader(bounds),
                        blendMode: BlendMode.srcOver,
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),

                // 5) 下边缘吸光阴影
                if (!disabled)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: radius * 0.9,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(isDark ? 0.24 : 0.07),
                          ],
                        ),
                      ),
                    ),
                  ),

                // 6) 内容
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
