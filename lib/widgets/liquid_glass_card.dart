import 'dart:io' show Platform;
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../theme/app_theme.dart';

/// ============================================================
/// iOS 18 风格 Liquid Glass 2.0 —— 液态玻璃卡片
/// ============================================================
/// 与 iOS 17 / macOS Frosted Glass 的关键区别：
/// 1. ColorFilter.matrix saturation boost ×1.6  —— 玻璃下的颜色不会发灰，反而更润
/// 2. 极高透明度（浅 32% / 深 40%）             —— 背景色斑能真正透出来
/// 3. Sharp thin highlight                       —— 顶部 2px 锐利亮边 + 渐隐
/// 4. Edge rim light & shadow                    —— 左上亮边/右下暗影
/// 5. Fine noise overlay                         —— 消除色带，给玻璃颗粒感
/// 6. Tinted shadow                              —— 阴影带 tint 色，不是死黑
/// 7. Blur sigma 默认 50                         —— 更柔和的模糊边缘
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
    this.blurRadius = 50,
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

  // —— iOS 18 saturation boost matrix ——
  // 取 saturation 1.6 (符合 iOS 18 玻璃的色彩增强感)
  static List<double> _saturationMatrix(double sat) {
    final r = 0.213;
    final g = 0.715;
    final b = 0.072;
    final a00 = r * (1 - sat) + sat;
    final a01 = g * (1 - sat);
    final a02 = b * (1 - sat);
    final a10 = r * (1 - sat);
    final a11 = g * (1 - sat) + sat;
    final a12 = b * (1 - sat);
    final a20 = r * (1 - sat);
    final a21 = g * (1 - sat);
    final a22 = b * (1 - sat) + sat;
    return [
      a00, a01, a02, 0, 0, //
      a10, a11, a12, 0, 0,
      a20, a21, a22, 0, 0,
      0, 0, 0, 1, 0,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final radius = widget.borderRadius;

    // —— iOS 18 更透的玻璃底色 ——
    final Color glassBase;
    final Color glassTint1;
    final Color glassTint2;
    if (widget.glassColor != null) {
      glassBase = widget.glassColor!;
      glassTint1 = Colors.white.withOpacity(0);
      glassTint2 = Colors.white.withOpacity(0);
    } else if (isDark) {
      glassBase = const Color(0xFF1B1B1B).withOpacity(0.40); // 之前0.55 → 更透
      glassTint1 = AppTheme.kLuminaLime.withOpacity(0.04);
      glassTint2 = const Color(0xFF000000).withOpacity(0.28);
    } else {
      glassBase = const Color(0xFFFFFFFF).withOpacity(0.32); // 之前0.48 → 更透
      glassTint1 = const Color(0xFFFFFFFF).withOpacity(0.22);
      glassTint2 = const Color(0xFFE4E4EA).withOpacity(0.22);
    }

    // —— 双层边框 ——
    final Color innerBorder;
    final Color outerBorder;
    if (isDark) {
      innerBorder = Colors.white.withOpacity(0.22); // 之前0.18 → 更亮
      outerBorder = Colors.white.withOpacity(0.05);
    } else {
      innerBorder = Colors.white.withOpacity(0.82); // 之前0.75 → 更亮
      outerBorder = const Color(0xFF000000).withOpacity(0.04);
    }

    // —— iOS 18 Tinted shadow: 阴影带一点点 tint ——
    final tint = isDark ? AppTheme.kLuminaLime : const Color(0xFF527AFF);
    final List<BoxShadow> shadows = widget.boxShadow ??
        (isDark
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.48),
                  blurRadius: 42,
                  spreadRadius: -6,
                  offset: const Offset(0, 18),
                ),
                BoxShadow(
                  color: tint.withOpacity(0.10),
                  blurRadius: 16,
                  spreadRadius: -2,
                  offset: const Offset(0, 8),
                ),
              ]
            : [
                BoxShadow(
                  color: const Color(0xFF3A3A4A).withOpacity(0.20),
                  blurRadius: 46,
                  spreadRadius: -8,
                  offset: const Offset(0, 20),
                ),
                BoxShadow(
                  color: tint.withOpacity(0.12),
                  blurRadius: 18,
                  spreadRadius: -4,
                  offset: const Offset(0, 8),
                ),
              ]);

    final pressScale = _isLowEndDevice ? 1.0 : 0.982;

    final content = AnimatedBuilder(
      animation: _pressController,
      builder: (context, child) {
        final t = _pressController.value;
        final scale = 1.0 + (pressScale - 1.0) * t;
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: widget.margin ??
            const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
        child: _GlassSurface(
          radius: radius,
          blur: _effectiveBlur,
          saturation: _isLowEndDevice ? 1.0 : 1.6,
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

/// ============================================================
/// GlassSurface —— 严格按 iOS 18 顺序叠 10 层
/// ============================================================
class _GlassSurface extends StatelessWidget {
  final double radius;
  final double blur;
  final double saturation;
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
    required this.saturation,
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
    final satMatrix = _LiquidGlassCardState._saturationMatrix(saturation);

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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          children: [
            // 1) iOS 18 核心：模糊 + 饱和度提升（color matrix 叠在 blur 上）
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(
                    sigmaX: blur, sigmaY: blur, tileMode: TileMode.decal),
                child: ColorFiltered(
                  colorFilter: ColorFilter.matrix(satMatrix),
                  child: const SizedBox.expand(),
                ),
              ),
            ),

            // 2) 玻璃底色 + 三段垂直渐变（上亮 → 中 → 下沉）
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

            // 3) 内描边（inside）
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

            // 4) iOS 18 锐利顶部高光 —— 2px 亮边 + 快速渐隐（不再是大弧形）
            if (enableHighlight)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: ClipRRect(
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(radius)),
                  child: SizedBox(
                    height: math.min(radius * 0.9, 22),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            // 第一行 2px 最亮，模拟玻璃切割边缘
                            Colors.white
                                .withOpacity(isDark ? 0.50 : 0.90),
                            Colors.white
                                .withOpacity(isDark ? 0.12 : 0.42),
                            Colors.white.withOpacity(0.0),
                          ],
                          stops: const [0.0, 0.35, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // 5) Edge rim —— 左上亮边 / 右下暗影（细线切面感）
            if (enableHighlight) ...[
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _EdgeRimPainter(
                      radius: radius,
                      isDark: isDark,
                    ),
                  ),
                ),
              ),
            ],

            // 6) 对角线微光：左上微亮 → 右下微暗
            if (enableHighlight)
              Positioned.fill(
                child: IgnorePointer(
                  child: ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(isDark ? 0.05 : 0.16),
                        Colors.white.withOpacity(0.0),
                        Colors.white.withOpacity(0.0),
                        Colors.black.withOpacity(isDark ? 0.16 : 0.035),
                      ],
                      stops: const [0.0, 0.40, 0.75, 1.0],
                    ).createShader(bounds),
                    blendMode: BlendMode.srcOver,
                    child: const SizedBox.expand(),
                  ),
                ),
              ),

            // 7) 底部吸光阴影
            if (enableHighlight)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: radius * 1.0,
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
                            .withOpacity(isDark ? 0.36 : 0.10),
                      ],
                    ),
                  ),
                ),
              ),

            // 8) Noise overlay —— 用 hash noise 消除色带，给玻璃颗粒感
            if (enableHighlight)
              Positioned.fill(
                child: IgnorePointer(
                  child: Opacity(
                    opacity: isDark ? 0.05 : 0.035,
                    child: const _NoiseTile(),
                  ),
                ),
              ),

            // 9) child content
            child,
          ],
        ),
      ),
    );
  }
}

/// ============================================================
/// Edge Rim Painter —— 左上亮边 / 右下暗影
/// ============================================================
class _EdgeRimPainter extends CustomPainter {
  final double radius;
  final bool isDark;

  _EdgeRimPainter({required this.radius, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );

    // 左上亮边（路径：沿着左边缘和顶边缘内侧，画一条 0.8px 半透明白）
    final rimLight = Paint()
      ..color = Colors.white.withOpacity(isDark ? 0.16 : 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..isAntiAlias = true;

    final shadowRim = Paint()
      ..color = (isDark ? Colors.black : const Color(0xFF3A3A4A))
          .withOpacity(isDark ? 0.22 : 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..isAntiAlias = true;

    // 裁剪在 rrect 内部 1px 的范围，避免边缘溢出
    canvas.save();
    canvas.clipRRect(rrect.deflate(0.4));

    // 左上角象限 —— 亮边
    final lightPath = Path()
      ..moveTo(radius * 0.5, 0.6)
      ..lineTo(0.6, radius * 0.5);
    canvas.drawPath(lightPath, rimLight);

    // 右下角象限 —— 暗影
    final darkPath = Path()
      ..moveTo(size.width - radius * 0.5, size.height - 0.6)
      ..lineTo(size.width - 0.6, size.height - radius * 0.5);
    canvas.drawPath(darkPath, shadowRim);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _EdgeRimPainter oldDelegate) =>
      oldDelegate.radius != radius || oldDelegate.isDark != isDark;
}

/// ============================================================
/// Noise tile —— 8x8 hash noise pattern，整张 tile 平铺
/// ============================================================
class _NoiseTile extends StatefulWidget {
  const _NoiseTile();

  @override
  State<_NoiseTile> createState() => _NoiseTileState();
}

class _NoiseTileState extends State<_NoiseTile> {
  ui.Image? _image;

  @override
  void initState() {
    super.initState();
    _build();
  }

  Future<void> _build() async {
    const w = 128, h = 128;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final rnd = math.Random(0xCAFEBABE);
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final v = rnd.nextInt(256);
        canvas.drawRect(
          Rect.fromLTWH(x.toDouble(), y.toDouble(), 1, 1),
          Paint()..color = Color.fromARGB(255, v, v, v),
        );
      }
    }
    final picture = recorder.endRecording();
    final img = await picture.toImage(w, h);
    if (mounted) setState(() => _image = img);
  }

  @override
  Widget build(BuildContext context) {
    final img = _image;
    if (img == null) return const SizedBox.expand();
    return CustomPaint(painter: _NoisePainter(img));
  }
}

class _NoisePainter extends CustomPainter {
  final ui.Image image;

  _NoisePainter(this.image);

  @override
  void paint(Canvas canvas, Size size) {
    const tile = 128.0;
    final paint = Paint()..isAntiAlias = false;
    for (double y = 0; y < size.height; y += tile) {
      for (double x = 0; x < size.width; x += tile) {
        canvas.drawImageRect(
          image,
          Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
          Rect.fromLTWH(x, y, tile, tile),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _NoisePainter oldDelegate) =>
      oldDelegate.image != image;
}
