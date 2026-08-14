import 'dart:io' show Platform;
import 'dart:math' as math;
import 'dart:ui';
import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../services/theme_service.dart';
import '../theme/app_theme.dart';

final _kIsLowEndToggle = Platform.numberOfProcessors < 4;

/// iOS 18 Liquid Glass 2.0 圆形切换按钮
class ThemeToggleButton extends StatefulWidget {
  const ThemeToggleButton({super.key});

  @override
  State<ThemeToggleButton> createState() => _ThemeToggleButtonState();
}

class _ThemeToggleButtonState extends State<ThemeToggleButton> {
  bool _pressed = false;

  static const _satMatrix = <double>[
    1.3488, 0.147, 0.0342, 0, 0,
    0.0426, 1.171, 0.0364, 0, 0,
    0.0426, 0.147, 1.1714, 0, 0,
    0, 0, 0, 1, 0,
  ];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeService.instance,
      builder: (context, _) {
        final isDark = ThemeService.instance.mode == ThemeMode.dark ||
            (ThemeService.instance.mode == ThemeMode.system &&
                MediaQuery.platformBrightnessOf(context) == Brightness.dark);

        const blur = 50.0;
        // 与 LiquidGlassCard 严格对齐的透明度
        final glassBase = isDark
            ? const Color(0xFF1B1B1B).withOpacity(0.40)
            : const Color(0xFFFFFFFF).withOpacity(0.32);
        final glassTint1 = isDark
            ? AppTheme.kLuminaLime.withOpacity(0.04)
            : Colors.white.withOpacity(0.22);
        final glassTint2 = isDark
            ? const Color(0xFF000000).withOpacity(0.28)
            : const Color(0xFFE4E4EA).withOpacity(0.22);
        final innerBorder = isDark
            ? Colors.white.withOpacity(0.22)
            : Colors.white.withOpacity(0.82);
        final outerBorder = isDark
            ? Colors.white.withOpacity(0.05)
            : const Color(0xFF000000).withOpacity(0.04);
        final iconColor = isDark ? AppTheme.kLuminaLime : AppTheme.kLuminaBlack;
        final tint = isDark ? AppTheme.kLuminaLime : const Color(0xFF527AFF);
        final shadows = isDark
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.48),
                  blurRadius: 32,
                  spreadRadius: -5,
                  offset: const Offset(0, 11),
                ),
                BoxShadow(
                  color: tint.withOpacity(0.10),
                  blurRadius: 12,
                  spreadRadius: -2,
                  offset: const Offset(0, 5),
                ),
              ]
            : [
                BoxShadow(
                  color: const Color(0xFF3A3A4A).withOpacity(0.20),
                  blurRadius: 36,
                  spreadRadius: -6,
                  offset: const Offset(0, 12),
                ),
                BoxShadow(
                  color: tint.withOpacity(0.12),
                  blurRadius: 14,
                  spreadRadius: -3,
                  offset: const Offset(0, 5),
                ),
              ];

        return GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) {
            setState(() => _pressed = false);
            ThemeService.instance.toggle();
          },
          child: AnimatedScale(
            duration: const Duration(milliseconds: 140),
            scale: _pressed ? 0.94 : 1.0,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: outerBorder,
                  width: 1.0,
                  strokeAlign: BorderSide.strokeAlignOutside,
                ),
                boxShadow: shadows,
              ),
              child: ClipOval(
                child: Stack(
                  children: [
                    // 1) Blur + sat 1.6
                    Positioned.fill(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(
                            sigmaX: blur, sigmaY: blur, tileMode: TileMode.decal),
                        child: ColorFiltered(
                          colorFilter: const ColorFilter.matrix(_satMatrix),
                          child: const SizedBox.expand(),
                        ),
                      ),
                    ),
                    // 2) Base + 三段渐变
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
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
                    // 3) Inner border
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: innerBorder,
                            width: 0.8,
                            strokeAlign: BorderSide.strokeAlignInside,
                          ),
                        ),
                      ),
                    ),
                    // 4) Sharp 顶部高光 (iOS 18: 锐利窄边)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: ClipOval(
                        child: SizedBox(
                          height: 15,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.white.withOpacity(isDark ? 0.50 : 0.90),
                                  Colors.white.withOpacity(isDark ? 0.12 : 0.42),
                                  Colors.white.withOpacity(0.0),
                                ],
                                stops: const [0.0, 0.35, 1.0],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // 5) Edge rim —— 左上亮边 / 右下暗影
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: _ToggleEdgeRimPainter(isDark: isDark),
                        ),
                      ),
                    ),
                    // 6) 对角线微光
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
                    // 7) 底部吸光
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: 20,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              (isDark ? Colors.black : const Color(0xFF3A3A4A))
                                  .withOpacity(isDark ? 0.36 : 0.10),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // 8) Noise overlay
                    if (!_kIsLowEndToggle)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Opacity(
                            opacity: isDark ? 0.05 : 0.035,
                            child: const _ToggleNoiseTile(),
                          ),
                        ),
                      ),
                    // Icon
                    Center(
                      child: Icon(
                        isDark
                            ? CupertinoIcons.sun_max_fill
                            : CupertinoIcons.moon_fill,
                        size: 22,
                        color: iconColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ToggleEdgeRimPainter extends CustomPainter {
  final bool isDark;
  _ToggleEdgeRimPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(size.width / 2),
    );
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
    canvas.save();
    canvas.clipRRect(rrect.deflate(0.4));
    final r = size.width / 2;
    final lightPath = Path()
      ..moveTo(r * 0.5, 0.6)
      ..lineTo(0.6, r * 0.5);
    canvas.drawPath(lightPath, rimLight);
    final darkPath = Path()
      ..moveTo(size.width - r * 0.5, size.height - 0.6)
      ..lineTo(size.width - 0.6, size.height - r * 0.5);
    canvas.drawPath(darkPath, shadowRim);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ToggleEdgeRimPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}

class _ToggleNoiseTile extends StatefulWidget {
  const _ToggleNoiseTile();

  @override
  State<_ToggleNoiseTile> createState() => _ToggleNoiseTileState();
}

class _ToggleNoiseTileState extends State<_ToggleNoiseTile> {
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
    return CustomPaint(painter: _ToggleNoisePainter(img));
  }
}

class _ToggleNoisePainter extends CustomPainter {
  final ui.Image image;
  _ToggleNoisePainter(this.image);

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
  bool shouldRepaint(covariant _ToggleNoisePainter oldDelegate) =>
      oldDelegate.image != image;
}
