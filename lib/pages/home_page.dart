import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'learning_checkin_page.dart';
import 'word_learning_page.dart';
import 'achievement_page.dart';
import 'calendar_page.dart';

/// 主框架：Lumina Mono 悬浮胶囊底部导航 + 全局 Liquid Glass 渐变背景
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
        // —— 底层：Liquid Glass 效果必需的渐变与色斑背景 ——
        const Positioned.fill(child: _LiquidGlassBackground()),

        // —— 中层：页面内容。包一层透明背景避免各页面自己的 scaffold 底色覆盖背景 ——
        Positioned.fill(
          child: _TransparentPages(
            index: _index,
            pages: _pages,
          ),
        ),

        // —— 顶层：Glass 风格的底部导航栏 ——
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

/// Liquid Glass 风格的全局背景：
/// 1) 大面积柔和渐变打底
/// 2) 3~4 个巨大、虚边、低饱和的色斑（Blob）
/// 3) 色斑上方再叠一层极微的颗粒噪声（可选）
/// 这是苹果 Control Center / Wallpaper Style 经典做法。
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
          // 1) 3 个巨大的色斑，随机位置 + 巨大 blur
          Positioned(
            top: -80,
            left: -60,
            child: _blob(
              size: 320,
              color: isDark
                  ? AppTheme.kLuminaLime.withOpacity(0.10)
                  : AppTheme.kLuminaLime.withOpacity(0.32),
            ),
          ),
          Positioned(
            top: 180,
            right: -100,
            child: _blob(
              size: 340,
              color: isDark
                  ? const Color(0xFF527AFF).withOpacity(0.18)
                  : const Color(0xFF527AFF).withOpacity(0.22),
            ),
          ),
          Positioned(
            bottom: 40,
            left: -80,
            child: _blob(
              size: 360,
              color: isDark
                  ? const Color(0xFFFF9500).withOpacity(0.10)
                  : const Color(0xFFFF9500).withOpacity(0.18),
            ),
          ),
          if (isDark)
            Positioned(
              bottom: 280,
              right: -40,
              child: _blob(
                size: 260,
                color: AppTheme.kLuminaLime.withOpacity(0.06),
              ),
            ),

          // 2) 浅色模式再叠一层更淡的紫斑，增加层次
          if (!isDark)
            Positioned(
              top: 440,
              right: 20,
              child: _blob(
                size: 220,
                color: const Color(0xFF527AFF).withOpacity(0.10),
              ),
            ),

          // 3) 垂直微渐变：上部更亮，下部稍沉
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDark
                      ? [
                          Colors.transparent,
                          const Color(0xFF000000).withOpacity(0.22),
                        ]
                      : [
                          const Color(0xFFFFFFFF).withOpacity(0.0),
                          const Color(0xFFEFEFF3).withOpacity(0.38),
                        ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _blob({required double size, required Color color}) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
        child: Container(
          width: size,
          height: size,
          color: color,
        ),
      ),
    );
  }
}

/// 包裹所有页面，强制透明背景让底层色斑透上来
class _TransparentPages extends StatelessWidget {
  final int index;
  final List<Widget> pages;

  const _TransparentPages({required this.index, required this.pages});

  @override
  Widget build(BuildContext context) {
    // 把 MaterialApp 的 scaffold background 强制覆盖为完全透明
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

/// Glass 风格底部导航栏：使用 GlassSurface 渲染逻辑（同卡片一致）
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
    final blur = 40.0;
    final radius = 999.0;
    final innerBorder =
        isDark ? Colors.white.withOpacity(0.18) : Colors.white.withOpacity(0.80);
    final outerBorder = isDark
        ? Colors.white.withOpacity(0.06)
        : const Color(0xFF000000).withOpacity(0.06);
    final glassBase = isDark
        ? const Color(0xFF1B1B1B).withOpacity(0.55)
        : const Color(0xFFFFFFFF).withOpacity(0.52);
    final activeColor =
        isDark ? AppTheme.kLuminaLime : AppTheme.kLuminaBlack;
    final muted = isDark ? AppTheme.kLuminaMutedDark : AppTheme.kLuminaMuted;

    final shadows = isDark
        ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.42),
              blurRadius: 32,
              spreadRadius: -6,
              offset: const Offset(0, 14),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 10,
              spreadRadius: -2,
              offset: const Offset(0, 5),
            ),
          ]
        : [
            BoxShadow(
              color: const Color(0xFF3A3A4A).withOpacity(0.18),
              blurRadius: 36,
              spreadRadius: -8,
              offset: const Offset(0, 14),
            ),
            BoxShadow(
              color: const Color(0xFF3A3A4A).withOpacity(0.08),
              blurRadius: 12,
              spreadRadius: -2,
              offset: const Offset(0, 5),
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
            // Blur
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                child: const SizedBox.expand(),
              ),
            ),
            // Base
            Positioned.fill(child: ColoredBox(color: glassBase)),
            // Inner border
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
            // Top highlight
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
                child: SizedBox(
                  height: 48,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withOpacity(isDark ? 0.14 : 0.55),
                          Colors.white.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Content
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
                                color: isDark
                                    ? AppTheme.kLuminaLime
                                    : AppTheme.kLuminaLime,
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
