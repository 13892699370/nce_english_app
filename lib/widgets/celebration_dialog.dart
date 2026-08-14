import 'dart:io' show Platform;
import 'dart:math' as math;
import 'dart:ui';
import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'duolingo_button.dart';
import '../data/achievements_data.dart';
import '../theme/app_theme.dart';

// iOS 18 saturation 1.6 matrix
const _kSatMatrix = <double>[
  1.3488, 0.147, 0.0342, 0, 0,
  0.0426, 1.171, 0.0364, 0, 0,
  0.0426, 0.147, 1.1714, 0, 0,
  0, 0, 0, 1, 0,
];

/// 成就解锁庆祝弹窗
///
/// iOS 原生风格：磨砂玻璃质感、系统配色、柔和出场动画。
class CelebrationDialog extends StatefulWidget {
  final AchievementDef achievement;
  const CelebrationDialog({super.key, required this.achievement});

  /// 便捷弹窗方法
  static Future<void> show(BuildContext context, AchievementDef def) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (_) => CelebrationDialog(achievement: def),
    );
  }

  @override
  State<CelebrationDialog> createState() => _CelebrationDialogState();
}

class _CelebrationDialogState extends State<CelebrationDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static final bool _isLowEndDevice = Platform.numberOfProcessors < 4;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurfaceColor = isDark ? Colors.white : Colors.black;
    const radius = 32.0;
    final blur = _isLowEndDevice ? 18.0 : 50.0;
    final tint = isDark ? AppTheme.kLuminaLime : const Color(0xFF527AFF);

    // iOS 18 更透的玻璃底色
    final glassBase = isDark
        ? const Color(0xFF1B1B1B).withOpacity(0.40)
        : const Color(0xFFFFFFFF).withOpacity(0.32);
    final glassTint1 = isDark
        ? AppTheme.kLuminaLime.withOpacity(0.04)
        : Colors.white.withOpacity(0.22);
    final glassTint2 = isDark
        ? const Color(0xFF000000).withOpacity(0.28)
        : const Color(0xFFE4E4EA).withOpacity(0.22);
    final innerBorder =
        isDark ? Colors.white.withOpacity(0.22) : Colors.white.withOpacity(0.82);
    final outerBorder = isDark
        ? Colors.white.withOpacity(0.05)
        : const Color(0xFF000000).withOpacity(0.04);

    final shadows = [
      BoxShadow(
        color: isDark
            ? Colors.black.withOpacity(0.48)
            : const Color(0xFF3A3A4A).withOpacity(0.20),
        blurRadius: 46,
        spreadRadius: -8,
        offset: const Offset(0, 20),
      ),
      BoxShadow(
        color: tint.withOpacity(isDark ? 0.10 : 0.12),
        blurRadius: 18,
        spreadRadius: -4,
        offset: const Offset(0, 8),
      ),
    ];

    const enableEffects = true;

    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(
        scale: _scale,
        alignment: Alignment.center,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: Container(
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
                    // 1) Blur + sat 1.6 (iOS 18 signature)
                    Positioned.fill(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(
                            sigmaX: blur, sigmaY: blur, tileMode: TileMode.decal),
                        child: ColorFiltered(
                          colorFilter:
                              const ColorFilter.matrix(_kSatMatrix),
                          child: const SizedBox.expand(),
                        ),
                      ),
                    ),

                    // 2) 三段垂直渐变底色
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

                    // 3) 内描边
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

                    // 4) iOS 18 锐利顶部高光 —— 2px 亮边 + 快速渐隐
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(radius)),
                        child: SizedBox(
                          height: math.min(radius * 0.9, 22),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
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

                    // 5) Edge rim —— 左上亮边 / 右下暗影
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: _CelebrationEdgeRimPainter(
                            radius: radius,
                            isDark: isDark,
                          ),
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

                    // 8) Noise overlay
                    if (!_isLowEndDevice)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Opacity(
                            opacity: isDark ? 0.05 : 0.035,
                            child: const _CelebrationNoiseTile(),
                          ),
                        ),
                      ),

                    // 9) 内容
                    Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            CupertinoIcons.sparkles,
                            size: 34,
                            color: isDark
                                ? AppTheme.kLuminaLime
                                : AppTheme.kLuminaBlack,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '成就解锁！',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppTheme.kLuminaLime
                                  : AppTheme.kLuminaBlack,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: SweepGradient(
                                colors: [
                                  AppTheme.kSystemBlue,
                                  AppTheme.kSystemPurple,
                                  AppTheme.kSystemPink,
                                  AppTheme.kSystemOrange,
                                  AppTheme.kLuminaLime,
                                  AppTheme.kSystemBlue,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.kSystemBlue.withOpacity(0.30),
                                  blurRadius: 20,
                                  spreadRadius: -2,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Container(
                              width: 84,
                              height: 84,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.18),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                widget.achievement.emoji,
                                style: const TextStyle(fontSize: 46),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            widget.achievement.title,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: onSurfaceColor,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.achievement.desc,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                              height: 1.5,
                              color: onSurfaceColor.withOpacity(0.62),
                            ),
                          ),
                          const SizedBox(height: 28),
                          SizedBox(
                            width: double.infinity,
                            child: DuolingoButton(
                              label: '太棒了！',
                              variant: DuolingoButtonVariant.primary,
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Edge Rim Painter for Celebration Dialog
class _CelebrationEdgeRimPainter extends CustomPainter {
  final double radius;
  final bool isDark;

  _CelebrationEdgeRimPainter({required this.radius, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
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
    final lightPath = Path()
      ..moveTo(radius * 0.5, 0.6)
      ..lineTo(0.6, radius * 0.5);
    canvas.drawPath(lightPath, rimLight);
    final darkPath = Path()
      ..moveTo(size.width - radius * 0.5, size.height - 0.6)
      ..lineTo(size.width - 0.6, size.height - radius * 0.5);
    canvas.drawPath(darkPath, shadowRim);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CelebrationEdgeRimPainter oldDelegate) =>
      oldDelegate.radius != radius || oldDelegate.isDark != isDark;
}

/// Noise tile for Celebration Dialog
class _CelebrationNoiseTile extends StatefulWidget {
  const _CelebrationNoiseTile();

  @override
  State<_CelebrationNoiseTile> createState() => _CelebrationNoiseTileState();
}

class _CelebrationNoiseTileState extends State<_CelebrationNoiseTile> {
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
    return CustomPaint(painter: _CelebrationNoisePainter(img));
  }
}

class _CelebrationNoisePainter extends CustomPainter {
  final ui.Image image;
  _CelebrationNoisePainter(this.image);

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
  bool shouldRepaint(covariant _CelebrationNoisePainter oldDelegate) =>
      oldDelegate.image != image;
}
