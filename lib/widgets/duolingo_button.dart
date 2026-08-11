import 'package:flutter/material.dart';
import '../services/haptic_service.dart';
import '../theme/app_theme.dart';

/// iOS 风格按钮（CupertinoButton 行为：按压透明度变化，无缩放）
///
/// 4 种变体：primary（蓝色填充）、secondary（蓝色文字）、success（绿色）、danger（红色）
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
    this.borderRadius = 12,
    this.minHeight = 50,
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

  (Color, Color) _colors() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (widget.variant) {
      case DuolingoButtonVariant.primary:
        return (
          isDark ? AppTheme.kSystemBlueDark : AppTheme.kSystemBlue,
          Colors.white,
        );
      case DuolingoButtonVariant.success:
        return (
          isDark ? AppTheme.kSystemGreenDark : AppTheme.kSystemGreen,
          Colors.white,
        );
      case DuolingoButtonVariant.danger:
        return (
          isDark ? AppTheme.kSystemRedDark : AppTheme.kSystemRed,
          Colors.white,
        );
      case DuolingoButtonVariant.secondary:
        return (Colors.transparent, isDark ? AppTheme.kSystemBlueDark : AppTheme.kSystemBlue);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSecondary = widget.variant == DuolingoButtonVariant.secondary;
    final disabled = widget.onPressed == null;
    final (bg, fg) = _colors();
    final theme = Theme.of(context);

    final displayBg = disabled ? Colors.grey.shade300 : bg;
    final displayFg = disabled
        ? (isSecondary ? Colors.grey : Colors.white)
        : fg;

    final inner = GestureDetector(
      onTapDown: disabled ? null : (_) => _onTapDown(),
      onTapCancel: disabled ? null : _onTapCancel,
      onTapUp: disabled ? null : (_) => _onTapUp(),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 100),
        opacity: _pressed ? 0.5 : 1.0,
        child: Container(
          constraints: BoxConstraints(minHeight: widget.minHeight),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: isSecondary ? Colors.transparent : displayBg,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: isSecondary
                ? Border.all(color: displayFg.withOpacity(0.2), width: 1)
                : null,
          ),
          child: Row(
            mainAxisSize: widget.fullwidth ? MainAxisSize.max : MainAxisSize.min,
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
                    fontWeight: isSecondary ? FontWeight.w400 : FontWeight.w600,
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
