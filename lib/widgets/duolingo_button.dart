import 'package:flutter/material.dart';
import '../services/haptic_service.dart';
import '../theme/app_theme.dart';

/// Duolingo 标志性 3D 立体按钮
/// 亮色顶面 + 深色底边（5px）形成"凸起"立体感；
/// 顶部 1px 高光带；按下时整体下沉 5px 且底边消失，模拟"按压凹陷"。
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
    this.borderRadius = 16,
    this.minHeight = 54,
    this.fullwidth = true,
    this.enableHaptic = true,
  });

  @override
  State<DuolingoButton> createState() => _DuolingoButtonState();
}

class _DuolingoButtonState extends State<DuolingoButton> {
  bool _pressed = false;

  void _onTapDown() => setState(() => _pressed = true);
  void _onTapCancel() => setState(() => _pressed = false);
  void _onTapUp() {
    setState(() => _pressed = false);
    if (widget.enableHaptic) HapticService.light();
    widget.onPressed?.call();
  }

  /// 返回 (顶面色, 底边深色) 用于 3D 立体效果
  (Color, Color) _colors(BuildContext context) {
    switch (widget.variant) {
      case DuolingoButtonVariant.primary:
        return (AppTheme.kDuoGreen, AppTheme.kDuoGreenDark);
      case DuolingoButtonVariant.success:
        return (AppTheme.kDuoGreen, AppTheme.kDuoGreenDark);
      case DuolingoButtonVariant.danger:
        return (AppTheme.kDuoRed, AppTheme.kDuoRedDark);
      case DuolingoButtonVariant.secondary:
        return (Colors.transparent, Colors.transparent);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final disabled = widget.onPressed == null;
    final (top, bottom) = _colors(context);
    final isSecondary = widget.variant == DuolingoButtonVariant.secondary;

    final disabledBg =
        isDark ? const Color(0xFF2D3F47) : const Color(0xFFE5E5E5);
    final disabledFg =
        isDark ? AppTheme.kSecondaryTextDark : AppTheme.kSecondaryTextLight;

    final fg = disabled
        ? disabledFg
        : (isSecondary ? AppTheme.kDuoGreen : Colors.white);

    final pressed = _pressed && !disabled;
    final depth = (pressed || disabled) ? 0.0 : 5.0;

    // 顶部高光：未按下时叠 1px 白色半透明高光，按下时消失
    final showHighlight = !disabled && !pressed && !isSecondary;

    final inner = GestureDetector(
      onTapDown: disabled ? null : (_) => _onTapDown(),
      onTapCancel: disabled ? null : _onTapCancel,
      onTapUp: disabled ? null : (_) => _onTapUp(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 60),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, pressed ? 5.0 : 0.0, 0),
        constraints: BoxConstraints(minHeight: widget.minHeight),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: disabled
              ? disabledBg
              : (isSecondary
                  ? (isDark ? AppTheme.kCardDark : Colors.white)
                  : top),
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border(
            bottom: BorderSide(color: bottom, width: depth),
            top: BorderSide(
              color: isSecondary ? AppTheme.kDuoGreen : Colors.transparent,
              width: isSecondary ? 2.5 : 0,
            ),
            left: BorderSide(
              color: isSecondary ? AppTheme.kDuoGreen : Colors.transparent,
              width: isSecondary ? 2.5 : 0,
            ),
            right: BorderSide(
              color: isSecondary ? AppTheme.kDuoGreen : Colors.transparent,
              width: isSecondary ? 2.5 : 0,
            ),
          ),
          boxShadow: (disabled || pressed || isSecondary)
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.25 : 0.10),
                    blurRadius: 6,
                    spreadRadius: -1,
                    offset: const Offset(0, 5),
                  ),
                ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Row(
              mainAxisSize:
                  widget.fullwidth ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, color: fg, size: 20),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      color: fg,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            // 顶部高光带：Duolingo 标志性的"光面"质感
            if (showHighlight)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: Container(
                    height: widget.minHeight / 2,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topLeft:
                            Radius.circular(widget.borderRadius),
                        topRight:
                            Radius.circular(widget.borderRadius),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withOpacity(0.22),
                          Colors.white.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    return widget.fullwidth
        ? SizedBox(width: double.infinity, child: inner)
        : inner;
  }
}
