import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import '../services/haptic_service.dart';
import '../theme/app_theme.dart';

/// iOS 风格按钮（弹性按压微交互 + 低端设备降级）
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
      duration: const Duration(milliseconds: 120),
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

    final displayBg = disabled ? Colors.grey.shade300 : bg;
    final displayFg = disabled
        ? (isSecondary ? Colors.grey : Colors.white)
        : fg;

    final pressScale = _isLowEndDevice ? 1.0 : 0.96;

    final inner = GestureDetector(
      onTapDown: disabled ? null : (_) => _onTapDown(),
      onTapCancel: disabled ? null : _onTapCancel,
      onTapUp: disabled ? null : (_) => _onTapUp(),
      child: AnimatedBuilder(
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
