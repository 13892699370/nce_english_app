import 'dart:io' show Platform;
import 'dart:math' as math;
import 'dart:ui';
import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/haptic_service.dart';

final _kIsLowEndCapsule = Platform.numberOfProcessors < 4;

/// iOS 18 Liquid Glass 2.0 胶囊分段选择器
class CapsuleSelector<T> extends StatefulWidget {
  final List<CapsuleOption<T>> options;
  final T value;
  final ValueChanged<T> onChanged;
  final bool enableHaptic;

  const CapsuleSelector({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.enableHaptic = true,
  });

  @override
  State<CapsuleSelector<T>> createState() => _CapsuleSelectorState<T>();
}

class CapsuleOption<T> {
  final T value;
  final String label;
  final IconData? icon;
  const CapsuleOption({required this.value, required this.label, this.icon});
}

const _kSatMatrix = <double>[
  1.3488, 0.147, 0.0342, 0, 0,
  0.0426, 1.171, 0.0364, 0, 0,
  0.0426, 0.147, 1.1714, 0, 0,
  0, 0, 0, 1, 0,
];

class _CapsuleSelectorState<T> extends State<CapsuleSelector<T>> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unselectedTextColor =
        isDark ? AppTheme.kLuminaMutedDark : AppTheme.kLuminaMuted;

    const radius = 999.0;
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
    final innerBorder =
        isDark ? Colors.white.withOpacity(0.22) : Colors.white.withOpacity(0.82);
    final outerBorder = isDark
        ? Colors.white.withOpacity(0.05)
        : const Color(0xFF000000).withOpacity(0.04);
    final tint = isDark ? AppTheme.kLuminaLime : const Color(0xFF527AFF);

    return LayoutBuilder(
      builder: (context, constraints) {
        final count = widget.options.length;
        final w = constraints.maxWidth;
        final segW = count > 0 ? w / count : 0;
        final currentIdx = widget.options
            .indexWhere((o) => o.value == widget.value);
        final idx = currentIdx < 0 ? 0 : currentIdx;

        return Container(
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: outerBorder,
              width: 1.0,
              strokeAlign: BorderSide.strokeAlignOutside,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.48)
                    : const Color(0xFF3A3A4A).withOpacity(0.20),
                blurRadius: 32,
                spreadRadius: -6,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: tint.withOpacity(0.11),
                blurRadius: 14,
                spreadRadius: -2,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: Stack(
              children: [
                // 1) blur + sat 1.6
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                        sigmaX: blur, sigmaY: blur, tileMode: TileMode.decal),
                    child: ColorFiltered(
                      colorFilter: const ColorFilter.matrix(_kSatMatrix),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
                // 2) 三段渐变
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
                // 3) inner border
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
                // 4) sharp 顶部高光 (iOS 18: 锐利窄边)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 18,
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
                // 5) Edge rim —— 左上亮边 / 右下暗影
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _CapsuleEdgeRimPainter(isDark: isDark),
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
                if (!_kIsLowEndCapsule)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: isDark ? 0.05 : 0.035,
                        child: const _CapsuleNoiseTile(),
                      ),
                    ),
                  ),

                // Animated thumb (glass slider)
                AnimatedAlign(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment(
                      -1.0 + (idx * 2.0) / (count - 1 > 0 ? count - 1 : 1), 0.0),
                  child: SizedBox(
                    width: segW,
                    height: double.infinity,
                    child: Padding(
                      padding: const EdgeInsets.all(3),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(radius),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22, tileMode: TileMode.decal),
                                child: ColorFiltered(
                                  colorFilter: const ColorFilter.matrix(_kSatMatrix),
                                  child: const SizedBox.expand(),
                                ),
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(radius),
                                color: isDark
                                    ? AppTheme.kLuminaLime.withOpacity(0.90)
                                    : AppTheme.kLuminaBlack.withOpacity(0.88),
                                border: Border.all(
                                  color: Colors.white.withOpacity(
                                      isDark ? 0.38 : 0.24),
                                  width: 0.8,
                                  strokeAlign:
                                      BorderSide.strokeAlignInside,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: (isDark
                                            ? AppTheme.kLuminaLime
                                            : AppTheme.kLuminaBlack)
                                        .withOpacity(0.30),
                                    blurRadius: 12,
                                    spreadRadius: -2,
                                    offset: const Offset(0, 4),
                                  ),
                                  BoxShadow(
                                    color: (isDark
                                            ? AppTheme.kLuminaLime
                                            : AppTheme.kLuminaBlack)
                                        .withOpacity(0.12),
                                    blurRadius: 4,
                                    spreadRadius: -1,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(radius),
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.white.withOpacity(
                                          isDark ? 0.40 : 0.20),
                                      Colors.white.withOpacity(isDark ? 0.10 : 0.05),
                                      Colors.white.withOpacity(0.0),
                                    ],
                                    stops: const [0.0, 0.30, 1.0],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Labels (on top)
                Positioned.fill(
                  child: Row(
                    children: widget.options.map((opt) {
                      final selected = opt.value == widget.value;
                      final fg = selected
                          ? (isDark
                              ? AppTheme.kLuminaBlack
                              : Colors.white)
                          : unselectedTextColor;
                      return Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            if (opt.value == widget.value) return;
                            if (widget.enableHaptic) HapticService.selection();
                            widget.onChanged(opt.value);
                          },
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (opt.icon != null) ...[
                                  Icon(
                                    opt.icon,
                                    size: 16,
                                    color: fg,
                                  ),
                                  const SizedBox(width: 6),
                                ],
                                Text(
                                  opt.label,
                                  style: TextStyle(
                                    color: fg,
                                    fontWeight: selected
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                    fontSize: 15,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CapsuleEdgeRimPainter extends CustomPainter {
  final bool isDark;
  _CapsuleEdgeRimPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(999),
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
      ..moveTo(size.width * 0.15, 0.6)
      ..lineTo(0.6, size.height * 0.5);
    canvas.drawPath(lightPath, rimLight);
    final darkPath = Path()
      ..moveTo(size.width * 0.85, size.height - 0.6)
      ..lineTo(size.width - 0.6, size.height * 0.5);
    canvas.drawPath(darkPath, shadowRim);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CapsuleEdgeRimPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}

class _CapsuleNoiseTile extends StatefulWidget {
  const _CapsuleNoiseTile();

  @override
  State<_CapsuleNoiseTile> createState() => _CapsuleNoiseTileState();
}

class _CapsuleNoiseTileState extends State<_CapsuleNoiseTile> {
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
    return CustomPaint(painter: _CapsuleNoisePainter(img));
  }
}

class _CapsuleNoisePainter extends CustomPainter {
  final ui.Image image;
  _CapsuleNoisePainter(this.image);

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
  bool shouldRepaint(covariant _CapsuleNoisePainter oldDelegate) =>
      oldDelegate.image != image;
}
