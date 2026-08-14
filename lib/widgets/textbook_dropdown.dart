import 'dart:io' show Platform;
import 'dart:math' as math;
import 'dart:ui';
import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/haptic_service.dart';

final _kIsLowEndDropdown = Platform.numberOfProcessors < 4;

/// Liquid Glass 风格教材下拉框（同卡片一致的模糊+高光+双层边框）
class TextbookDropdown extends StatefulWidget {
  final List<TextbookDropdownOption> options;
  final String value;
  final ValueChanged<String> onChanged;

  const TextbookDropdown({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  @override
  State<TextbookDropdown> createState() => _TextbookDropdownState();
}

class TextbookDropdownOption {
  final String value;
  final String label;
  const TextbookDropdownOption({required this.value, required this.label});
}

class _TextbookDropdownState extends State<TextbookDropdown> {
  bool _pressed = false;

  void _showActionSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor =
        isDark ? AppTheme.kLuminaLime : AppTheme.kLuminaBlack;

    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) {
        return CupertinoActionSheet(
          actions: widget.options.map((opt) {
            final selected = opt.value == widget.value;
            return CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(context).pop();
                if (selected) return;
                HapticService.selection();
                widget.onChanged(opt.value);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      opt.label,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (selected) ...[
                    const SizedBox(width: 8),
                    Icon(
                      CupertinoIcons.check_mark,
                      size: 20,
                      color: accentColor,
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor =
        isDark ? AppTheme.kLuminaLime : AppTheme.kLuminaBlack;
    final currentLabel = widget.options
        .firstWhere((o) => o.value == widget.value,
            orElse: () => widget.options.first)
        .label;

    // iOS 18 Liquid Glass 2.0 参数 —— 与 LiquidGlassCard 严格对齐
    const blur = 50.0;
    const radius = 20.0;
    final glassBase = isDark
        ? const Color(0xFF1B1B1B).withOpacity(0.40) // 卡片一致
        : const Color(0xFFFFFFFF).withOpacity(0.32); // 卡片一致
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
    final shadows = isDark
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
          ];
    const satMatrix = <double>[
      1.3488, 0.147, 0.0342, 0, 0,
      0.0426, 1.171, 0.0364, 0, 0,
      0.0426, 0.147, 1.1714, 0, 0,
      0, 0, 0, 1, 0,
    ];

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        _showActionSheet();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 140),
        scale: _pressed ? 0.985 : 1.0,
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
                // 1) Blur + saturation 1.6 (iOS 18 signature)
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                        sigmaX: blur, sigmaY: blur, tileMode: TileMode.decal),
                    child: ColorFiltered(
                      colorFilter: const ColorFilter.matrix(satMatrix),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
                // 2) Base + 三段渐变
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
                // 3) Inner border
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
                // 4) Sharp 顶部高光 (iOS 18: 锐利窄边)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(radius)),
                    child: SizedBox(
                      height: math.min(radius * 0.9, 18),
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
                      painter: _DropdownEdgeRimPainter(
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
                  height: radius,
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
                if (!_kIsLowEndDropdown)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: isDark ? 0.05 : 0.035,
                        child: const _DropdownNoiseTile(),
                      ),
                    ),
                  ),
                // 9) Content
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
                  child: Row(
                    children: [
                      Icon(
                        CupertinoIcons.book,
                        size: 20,
                        color: accentColor,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          currentLabel,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppTheme.kLuminaTextDark
                                : AppTheme.kLuminaText,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                      Icon(
                        CupertinoIcons.chevron_down,
                        size: 14,
                        color: const Color(0xFF8E8E93),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DropdownEdgeRimPainter extends CustomPainter {
  final double radius;
  final bool isDark;
  _DropdownEdgeRimPainter({required this.radius, required this.isDark});

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
  bool shouldRepaint(covariant _DropdownEdgeRimPainter oldDelegate) =>
      oldDelegate.radius != radius || oldDelegate.isDark != isDark;
}

class _DropdownNoiseTile extends StatefulWidget {
  const _DropdownNoiseTile();

  @override
  State<_DropdownNoiseTile> createState() => _DropdownNoiseTileState();
}

class _DropdownNoiseTileState extends State<_DropdownNoiseTile> {
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
    return CustomPaint(painter: _DropdownNoisePainter(img));
  }
}

class _DropdownNoisePainter extends CustomPainter {
  final ui.Image image;
  _DropdownNoisePainter(this.image);

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
  bool shouldRepaint(covariant _DropdownNoisePainter oldDelegate) =>
      oldDelegate.image != image;
}
