import 'dart:io' show Platform;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// iOS 18 风格 Liquid Glass 液态玻璃卡片
///
/// 特性：
/// 1. 高半径 BackdropFilter 背景模糊（sigma 32-50）
/// 2. 半透明底色 + 多层渐变叠染，使模糊色彩有层次
/// 3. 双层边框：内描边高光 + 外描边暗边，营造厚度感
/// 4. 顶部弧形高光带 + 对角线微光，模仿玻璃反光
/// 5. 内外双层阴影，悬浮感更强
/// 6. 低端设备（CPU<4 核）自动降级到基础玻璃
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
  final bool enableHighlight;

  const LiquidGlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.blurRadius = 40,
    this.borderRadius = 28,
    this.glassColor,
    this.boxShadow,
    this.onTap,
    this.enableHaptic = false,
    this.enableHighlight = true,
  });

  @override
  State<LiquidGlassCard> createState() => _LiquidGlassCardState();
}

class _LiquidGlassCardState extends State<LiquidGlassCard>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late final AnimationController _pressController;

  static final bool _isLowEndDevice = Platform.numberOfProcessors < 4;

  double get _effectiveBlur =>
      _isLowEndDevice ? widget.blurRadius * 0.35 : widget.blurRadius;

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

  void _setPressed(bool v) {
    if (_pressed == v) return;
    _pressed = v;
    if (v) {
      _pressController.forward();
    } else {
      _pressController.reverse();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final radius = widget.borderRadius;

    // —— 玻璃底色：iOS 风格更透，让模糊背景透出来 ——
    final Color glassBase;
    final Color glassTint1; // 顶部色调（偏亮）
    final Color glassTint2; // 底部色调（偏沉）
    if (widget.glassColor != null) {
      glassBase = widget.glassColor!;
      glassTint1 = Colors.white.withOpacity(0);
      glassTint2 = Colors.white.withOpacity(0);
    } else if (isDark) {
      // 深色：半透明黑 + 极微绿调（Lime 环境色）
      glassBase = const Color(0xFF1B1B1B).withOpacity(0.55);
      glassTint1 = AppTheme.kLuminaLime.withOpacity(0.03);
      glassTint2 = const Color(0xFF000000).withOpacity(0.20);
    } else {
      // 浅色：半透明白 + 轻微冷灰调
      glassBase = const Color(0xFFFFFFFF).withOpacity(0.48);
      glassTint1 = const Color(0xFFFFFFFF).withOpacity(0.30);
      glassTint2 = const Color(0xFFEFEFF3).withOpacity(0.25);
    }

    // —— 双层边框颜色：内层高光 + 外层描边 ——
    final Color innerBorder;
    final Color outerBorder;
    if (isDark) {
      innerBorder = Colors.white.withOpacity(0.18); // 上边缘高光
      outerBorder = Colors.white.withOpacity(0.06);
    } else {
      innerBorder = Colors.white.withOpacity(0.75);
      outerBorder = const Color(0xFF000000).withOpacity(0.05);
    }

    // —— 内外双层阴影 ——
    final List<BoxShadow> shadows = widget.boxShadow ??
        (isDark
            ? [
                // 外部：深阴影让卡片从黑背景上浮
                BoxShadow(
                  color: Colors.black.withOpacity(0.45),
                  blurRadius: 36,
                  spreadRadius: -6,
                  offset: const Offset(0, 16),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.20),
                  blurRadius: 12,
                  spreadRadius: -2,
                  offset: const Offset(0, 6),
                ),
              ]
            : [
                BoxShadow(
                  color: const Color(0xFF3A3A4A).withOpacity(0.16),
                  blurRadius: 40,
                  spreadRadius: -8,
                  offset: const Offset(0, 18),
                ),
                BoxShadow(
                  color: const Color(0xFF3A3A4A).withOpacity(0.08),
                  blurRadius: 14,
                  spreadRadius: -2,
                  offset: const Offset(0, 6),
                ),
              ]);

    final pressScale = _isLowEndDevice ? 1.0 : 0.982;

    final content = AnimatedBuilder(
      animation: _pressController,
      builder: (context, child) {
        final t = _pressController.value;
        final scale = 1.0 + (pressScale - 1.0) * t;
        final opacity = 1.0 - 0.12 * t;
        return Transform.scale(
          scale: scale,
          child: Opacity(opacity: opacity, child: child),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: widget.margin ??
            const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
        child: _GlassSurface(
          radius: radius,
          blur: _effectiveBlur,
          glassBase: glassBase,
          glassTint1: glassTint1,
          glassTint2: glassTint2,
          innerBorder: innerBorder,
          outerBorder: outerBorder,
          shadows: shadows,
          enableHighlight: widget.enableHighlight && !_isLowEndDevice,
          isDark: isDark,
          child: Padding(
            padding: widget.padding ?? const EdgeInsets.all(22),
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

/// —— 核心：真正的 Glass 表层容器 ——
/// 用 Stack 叠加顺序严格保证：
/// 外边框 → BackdropFilter 模糊 → 底色渐变 → 内边框高光 → 顶部反光 → 对角线微光 → child
class _GlassSurface extends StatelessWidget {
  final double radius;
  final double blur;
  final Color glassBase;
  final Color glassTint1;
  final Color glassTint2;
  final Color innerBorder;
  final Color outerBorder;
  final List<BoxShadow> shadows;
  final bool enableHighlight;
  final bool isDark;
  final Widget child;

  const _GlassSurface({
    required this.radius,
    required this.blur,
    required this.glassBase,
    required this.glassTint1,
    required this.glassTint2,
    required this.innerBorder,
    required this.outerBorder,
    required this.shadows,
    required this.enableHighlight,
    required this.isDark,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // 外层：外描边 + 阴影容器
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: outerBorder,
          width: 1.0,
          strokeAlign: BorderSide.strokeAlignOutside,
        ),
        boxShadow: shadows,
      ),
      // 裁切圆角，用于后面的 BackdropFilter 与 高光
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          children: [
            // 1) BackdropFilter：大面积背景模糊（Liquid Glass 核心）
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                child: const SizedBox.expand(),
              ),
            ),

            // 2) 玻璃底色 + 垂直渐变叠染，让颜色有深度
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color.alphaBlend(glassTint1, glassBase),
                      glassBase,
                      Color.alphaBlend(glassTint2, glassBase),
                    ],
                    stops: const [0.0, 0.55, 1.0],
                  ),
                ),
              ),
            ),

            // 3) 内描边：用 Container 的 inside 边，制造边缘厚度
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(radius),
                  border: Border.all(
                    color: innerBorder,
                    width: 0.8,
                    strokeAlign: BorderSide.strokeAlignInside,
                  ),
                ),
              ),
            ),

            // 4) 顶部弧形高光（真正的玻璃反光——iOS 标志性效果）
            if (enableHighlight)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: ClipRRect(
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(radius)),
                  child: SizedBox(
                    height: radius * 1.2,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withOpacity(isDark ? 0.16 : 0.55),
                            Colors.white.withOpacity(isDark ? 0.04 : 0.12),
                            Colors.white.withOpacity(0.0),
                          ],
                          stops: const [0.0, 0.55, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // 5) 对角线微光（左上 → 右下），让整体更"润"
            if (enableHighlight)
              Positioned.fill(
                child: IgnorePointer(
                  child: ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(isDark ? 0.06 : 0.22),
                        Colors.white.withOpacity(0.0),
                        Colors.white.withOpacity(0.0),
                        Colors.black.withOpacity(isDark ? 0.10 : 0.03),
                      ],
                      stops: const [0.0, 0.35, 0.75, 1.0],
                    ).createShader(bounds),
                    blendMode: BlendMode.srcOver,
                    child: const SizedBox.expand(),
                  ),
                ),
              ),

            // 6) 底部内阴影：模仿玻璃下边缘吸光
            if (enableHighlight)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: radius,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        (isDark
                                ? Colors.black
                                : const Color(0xFF3A3A4A))
                            .withOpacity(isDark ? 0.28 : 0.08),
                      ],
                    ),
                  ),
                ),
              ),

            // 7) child
            child,
          ],
        ),
      ),
    );
  }
}
