import 'dart:io' show Platform;
import 'dart:math' as math;
import 'dart:ui';
import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'learning_checkin_page.dart';
import 'word_learning_page.dart';
import 'achievement_page.dart';
import 'calendar_page.dart';

final _kIsLowEndGlass = Platform.numberOfProcessors < 4;

/// 主框架：iOS 18 风格 Liquid Glass 胶囊底部导航 + 色斑渐变背景
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;

  static const _pages = [
    LearningCheckinPage(),
    WordLearningPage(),
    AchievementPage(),
    CalendarPage(),
  ];

  static const _items = [
    _NavItem('打卡', CupertinoIcons.checkmark_alt_circle,
        CupertinoIcons.checkmark_alt_circle_fill),
    _NavItem('单词', CupertinoIcons.text_bubble, CupertinoIcons.text_bubble_fill),
    _NavItem('成就', CupertinoIcons.star, CupertinoIcons.star_fill),
    _NavItem('日历', CupertinoIcons.calendar, CupertinoIcons.calendar),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Stack(
      fit: StackFit.expand,
      children: [
        // —— 底层：Liquid Glass 效果必需的色斑渐变背景 ——
        const Positioned.fill(child: _LiquidGlassBackground()),

        // —— 中层：页面内容（强制透明让色斑透上来） ——
        Positioned.fill(
          child: _TransparentPages(
            index: _index,
            pages: _pages,
          ),
        ),

        // —— 顶层：iOS 18 Glass 风格的底部导航栏 ——
        Positioned(
          left: 18,
          right: 18,
          bottom: 4,
          child: SafeArea(
            top: false,
            child: _GlassBottomBar(
              isDark: isDark,
              items: _items,
              currentIndex: _index,
              onTap: (i) => setState(() => _index = i),
            ),
          ),
        ),
      ],
    );
  }
}

/// Liquid Glass 2.0 背景（iOS 18）：
/// 色斑更大、更饱和、sigma 100 级超柔边。
/// 没有这层背景的话玻璃的 blur+saturation 没有任何效果。
class _LiquidGlassBackground extends StatelessWidget {
  const _LiquidGlassBackground();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ColoredBox(
      color: isDark ? AppTheme.kLuminaBgDark : AppTheme.kLuminaBg,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // —— 1) 巨大色斑：尺寸 +30%、透明度 +30%、sigma 100 ——
          Positioned(
            top: -120,
            left: -80,
            child: _blob(
              size: 440,
              color: isDark
                  ? AppTheme.kLuminaLime.withOpacity(0.14)
                  : AppTheme.kLuminaLime.withOpacity(0.40),
              sigma: 100,
            ),
          ),
          Positioned(
            top: 160,
            right: -150,
            child: _blob(
              size: 480,
              color: isDark
                  ? const Color(0xFF527AFF).withOpacity(0.20)
                  : const Color(0xFF527AFF).withOpacity(0.28),
              sigma: 100,
            ),
          ),
          Positioned(
            bottom: -20,
            left: -120,
            child: _blob(
              size: 500,
              color: isDark
                  ? const Color(0xFFFF6B6B).withOpacity(0.12)
                  : const Color(0xFFFF8A3C).withOpacity(0.22),
              sigma: 100,
            ),
          ),
          if (isDark)
            Positioned(
              top: 420,
              left: 120,
              child: _blob(
                size: 320,
                color: const Color(0xFFBF5AF2).withOpacity(0.13),
                sigma: 90,
              ),
            ),
          if (!isDark)
            Positioned(
              top: 420,
              right: -40,
              child: _blob(
                size: 300,
                color: const Color(0xFFBF5AF2).withOpacity(0.14),
                sigma: 90,
              ),
            ),
          if (isDark)
            Positioned(
              bottom: 220,
              right: -20,
              child: _blob(
                size: 280,
                color: AppTheme.kLuminaLime.withOpacity(0.08),
                sigma: 80,
              ),
            ),

          // —— 2) 垂直微渐变 ——
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDark
                      ? [
                          Colors.transparent,
                          const Color(0xFF000000).withOpacity(0.28),
                        ]
                      : [
                          const Color(0xFFFFFFFF).withOpacity(0.0),
                          const Color(0xFFE7E7F0).withOpacity(0.42),
                        ],
                ),
              ),
            ),
          ),

          // —— 3) 轻微噪声（极低透明度，消除色带） ——
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: isDark ? 0.025 : 0.018,
                child: const _BackdropNoise(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _blob({
    required double size,
    required Color color,
    required double sigma,
  }) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma, tileMode: TileMode.decal),
        child: Container(
          width: size,
          height: size,
          color: color,
        ),
      ),
    );
  }
}

/// 背景用的噪声瓦片（与卡片共享实现但不需要那么多像素）
class _BackdropNoise extends StatefulWidget {
  const _BackdropNoise();

  @override
  State<_BackdropNoise> createState() => _BackdropNoiseState();
}

class _BackdropNoiseState extends State<_BackdropNoise> {
  ui.Image? _image;

  @override
  void initState() {
    super.initState();
    _build();
  }

  Future<void> _build() async {
    const w = 128, h = 128;
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    final rnd = math.Random(0xBEEF);
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
    return CustomPaint(painter: _BackdropNoisePainter(img));
  }
}

class _BackdropNoisePainter extends CustomPainter {
  final ui.Image image;
  _BackdropNoisePainter(this.image);

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
  bool shouldRepaint(covariant _BackdropNoisePainter oldDelegate) =>
      oldDelegate.image != image;
}

/// 包裹所有页面，强制透明背景让底层色斑透上来
class _TransparentPages extends StatelessWidget {
  final int index;
  final List<Widget> pages;

  const _TransparentPages({required this.index, required this.pages});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        scaffoldBackgroundColor: Colors.transparent,
      ),
      child: CupertinoTheme(
        data: CupertinoTheme.of(context).copyWith(
          scaffoldBackgroundColor: Colors.transparent,
        ),
        child: IndexedStack(index: index, children: pages),
      ),
    );
  }
}

// —— iOS 18 saturation matrix helper ——
List<double> _satMatrix(double sat) {
  const r = 0.213, g = 0.715, b = 0.072;
  return [
    r * (1 - sat) + sat, g * (1 - sat), b * (1 - sat), 0, 0,
    r * (1 - sat), g * (1 - sat) + sat, b * (1 - sat), 0, 0,
    r * (1 - sat), g * (1 - sat), b * (1 - sat) + sat, 0, 0,
    0, 0, 0, 1, 0,
  ];
}

/// Glass 风格底部导航栏：严格对齐 LiquidGlassCard 的 10 层结构
class _GlassBottomBar extends StatelessWidget {
  final bool isDark;
  final List<_NavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _GlassBottomBar({
    required this.isDark,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const blur = 50.0;
    const radius = 999.0;
    final innerBorder =
        isDark ? Colors.white.withOpacity(0.24) : Colors.white.withOpacity(0.86);
    final outerBorder = isDark
        ? Colors.white.withOpacity(0.05)
        : const Color(0xFF000000).withOpacity(0.04);
    final glassBase = isDark
        ? const Color(0xFF1B1B1B).withOpacity(0.40)
        : const Color(0xFFFFFFFF).withOpacity(0.32);
    final glassTint1 = isDark
        ? AppTheme.kLuminaLime.withOpacity(0.04)
        : Colors.white.withOpacity(0.22);
    final glassTint2 = isDark
        ? const Color(0xFF000000).withOpacity(0.28)
        : const Color(0xFFE4E4EA).withOpacity(0.20);
    final activeColor =
        isDark ? AppTheme.kLuminaLime : AppTheme.kLuminaBlack;
    final muted = isDark ? AppTheme.kLuminaMutedDark : AppTheme.kLuminaMuted;
    final tint = isDark ? AppTheme.kLuminaLime : const Color(0xFF527AFF);

    final shadows = isDark
        ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.52),
              blurRadius: 44,
              spreadRadius: -6,
              offset: const Offset(0, 18),
            ),
            BoxShadow(
              color: tint.withOpacity(0.11),
              blurRadius: 18,
              spreadRadius: -2,
              offset: const Offset(0, 8),
            ),
          ]
        : [
            BoxShadow(
              color: const Color(0xFF3A3A4A).withOpacity(0.22),
              blurRadius: 46,
              spreadRadius: -8,
              offset: const Offset(0, 18),
            ),
            BoxShadow(
              color: tint.withOpacity(0.13),
              blurRadius: 18,
              spreadRadius: -4,
              offset: const Offset(0, 8),
            ),
          ];

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
            // 1) blur + saturation boost
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur, tileMode: TileMode.decal),
                child: ColorFiltered(
                  colorFilter: ColorFilter.matrix(_satMatrix(1.6)),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
            // 2) base + 三段渐变
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
            // 4) sharp top highlight (iOS 18: 锐利窄边)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(top: const Radius.circular(radius)),
                child: SizedBox(
                  height: 22,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withOpacity(isDark ? 0.50 : 0.90),
                          Colors.white.withOpacity(isDark ? 0.10 : 0.36),
                          Colors.white.withOpacity(0.0),
                        ],
                        stops: const [0.0, 0.32, 1.0],
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
                  painter: _NavEdgeRimPainter(isDark: isDark),
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
              height: 36,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      (isDark ? Colors.black : const Color(0xFF3A3A4A))
                          .withOpacity(isDark ? 0.30 : 0.08),
                    ],
                  ),
                ),
              ),
            ),
            // 8) Noise overlay
            if (!_kIsLowEndGlass)
              Positioned.fill(
                child: IgnorePointer(
                  child: Opacity(
                    opacity: isDark ? 0.05 : 0.035,
                    child: const _NavNoiseTile(),
                  ),
                ),
              ),
            // 9) Content
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(items.length, (i) {
                  final item = items[i];
                  final selected = i == currentIndex;
                  return GestureDetector(
                    onTap: () => onTap(i),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutBack,
                      scale: selected ? 1.08 : 1.0,
                      child: SizedBox(
                        width: 64,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              selected ? item.activeIcon : item.icon,
                              size: selected ? 25 : 23,
                              color: selected ? activeColor : muted,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.label,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: selected ? activeColor : muted,
                                decoration: TextDecoration.none,
                              ),
                            ),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              margin: const EdgeInsets.only(top: 4),
                              width: selected ? 6 : 0,
                              height: selected ? 6 : 0,
                              decoration: BoxDecoration(
                                color: AppTheme.kLuminaLime,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const _NavItem(this.label, this.icon, this.activeIcon);
}

class _NavEdgeRimPainter extends CustomPainter {
  final bool isDark;
  _NavEdgeRimPainter({required this.isDark});

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
  bool shouldRepaint(covariant _NavEdgeRimPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}

class _NavNoiseTile extends StatefulWidget {
  const _NavNoiseTile();

  @override
  State<_NavNoiseTile> createState() => _NavNoiseTileState();
}

class _NavNoiseTileState extends State<_NavNoiseTile> {
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
    return CustomPaint(painter: _NavNoisePainter(img));
  }
}

class _NavNoisePainter extends CustomPainter {
  final ui.Image image;
  _NavNoisePainter(this.image);

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
  bool shouldRepaint(covariant _NavNoisePainter oldDelegate) =>
      oldDelegate.image != image;
}
