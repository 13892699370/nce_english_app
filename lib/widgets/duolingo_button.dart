import 'package:flutter/material.dart';
import '../services/haptic_service.dart';
import '../theme/app_theme.dart';

/// 简洁现代按钮
/// - primary: Indigo 底 + 白字
/// - secondary: 灰底 + 文字色
/// - success: 绿底 + 白字
/// - danger: 红底 + 白字
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
    this.borderRadius = 14,
    this.minHeight = 52,
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

  (Color, Color) _colors(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (widget.variant) {
      case DuolingoButtonVariant.primary:
        return (isDark ? AppTheme.kIndigoLight : AppTheme.kIndigo, Colors.white);
      case DuolingoButtonVariant.success:
        return (AppTheme.kSuccess, Colors.white);
      case DuolingoButtonVariant.danger:
        return (AppTheme.kDanger, Colors.white);
      case DuolingoButtonVariant.secondary:
        return isDark
            ? (const Color(0xFF2C2C2E), AppTheme.kTextDark)
            : (const Color(0xFFE5E5EA), AppTheme.kTextLight);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final disabled = widget.onPressed == null;
    final (bg, fg) = _colors(context);

    final displayBg = disabled
        ? (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA))
        : bg;
    final displayFg =
        disabled ? (isDark ? AppTheme.kSecondaryTextDark : AppTheme.kSecondaryTextLight) : fg;

    final inner = GestureDetector(
      onTapDown: disabled ? null : (_) => _onTapDown(),
      onTapCancel: disabled ? null : _onTapCancel,
      onTapUp: disabled ? null : (_) => _onTapUp(),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          constraints: BoxConstraints(minHeight: widget.minHeight),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: displayBg,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: disabled
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.30 : 0.10),
                      blurRadius: 16,
                      spreadRadius: -4,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: Row(
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
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return widget.fullwidth
        ? SizedBox(width: double.infinity, child: inner)
        : inner;
  }
}
