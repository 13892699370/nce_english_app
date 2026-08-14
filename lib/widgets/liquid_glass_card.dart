import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// 干净的现代卡片组件
/// 白色/深色底 + 柔和阴影 + 圆角，无玻璃模糊
class LiquidGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Border? border;
  final List<BoxShadow>? boxShadow;

  const LiquidGlassCard({
    super.key,
    required this.child,
    this.margin,
    this.padding,
    this.borderRadius = 20,
    this.onTap,
    this.backgroundColor,
    this.border,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = backgroundColor ??
        (isDark ? AppTheme.kCardDark : AppTheme.kCardLight);
    final defaultShadow = isDark
        ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 16,
              spreadRadius: -6,
              offset: const Offset(0, 4),
            ),
          ]
        : [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 20,
              spreadRadius: -4,
              offset: const Offset(0, 4),
            ),
          ];

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(borderRadius),
        border: border,
        boxShadow: boxShadow ?? defaultShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: padding != null
                ? Padding(padding: padding!, child: child)
                : child,
          ),
        ),
      ),
    );
  }
}
