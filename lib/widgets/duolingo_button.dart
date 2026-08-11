import 'package:flutter/material.dart';
import '../services/haptic_service.dart';

/// 多邻国风格大号按钮：圆角胶囊、按压挤压回弹、水波纹、统一触觉反馈
///
/// 双端表现一致：按下缩小 -> 回弹；触觉反馈自动降级（设备不支持不报错）。
enum DuolingoButtonVariant {
  primary, // 主色填充
  secondary, // 次要描边
  success, // 绿色（认识）
  danger, // 红色（不认识）
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
    this.minHeight = 56,
    this.fullwidth = true,
    this.enableHaptic = true,
  });

  @override
  State<DuolingoButton> createState() => _DuolingoButtonState();
}

class _DuolingoButtonState extends State<DuolingoButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.93).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown() {
    _controller.forward();
  }

  void _onTapUp() {
    _controller.reverse();
    if (widget.enableHaptic) HapticService.light();
    widget.onPressed?.call();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  Color _bgColor() {
    switch (widget.variant) {
      case DuolingoButtonVariant.primary:
        return const Color(0xFF58CC02); // 多邻国绿
      case DuolingoButtonVariant.success:
        return const Color(0xFF58CC02);
      case DuolingoButtonVariant.danger:
        return const Color(0xFFFF4B4B);
      case DuolingoButtonVariant.secondary:
        return Colors.transparent;
    }
  }

  Color _fgColor() {
    return widget.variant == DuolingoButtonVariant.secondary
        ? const Color(0xFF4B4B4B)
        : Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSecondary = widget.variant == DuolingoButtonVariant.secondary;
    final disabled = widget.onPressed == null;
    final bg = disabled ? Colors.grey.shade300 : _bgColor();

    final inner = ScaleTransition(
      scale: _scale,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            color: isSecondary ? Colors.transparent : bg,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: isSecondary
                ? Border.all(color: theme.colorScheme.outline.withOpacity(0.4), width: 1.5)
                : null,
            boxShadow: isSecondary || disabled
                ? null
                : [
                    BoxShadow(
                      color: bg.withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            splashColor: Colors.white.withOpacity(0.2),
            highlightColor: Colors.white.withOpacity(0.1),
            onTapDown: disabled ? null : (_) => _onTapDown(),
            onTapCancel: disabled ? null : _onTapCancel,
            onTap: disabled ? null : _onTapUp,
            child: Container(
              constraints: BoxConstraints(minHeight: widget.minHeight),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                mainAxisSize: widget.fullwidth ? MainAxisSize.max : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.icon != null) ...[
                    Icon(widget.icon, color: _fgColor(), size: 20),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      widget.label,
                      style: TextStyle(
                        color: _fgColor(),
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
        ),
      ),
    );

    return widget.fullwidth
        ? SizedBox(width: double.infinity, child: inner)
        : inner;
  }
}
