import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'learning_checkin_page.dart';
import 'word_learning_page.dart';
import 'achievement_page.dart';
import 'calendar_page.dart';

/// 主框架：纯色背景 + IndexedStack 页面 + Duolingo 风格底部胶囊导航
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
    _NavItem('打卡', CupertinoIcons.checkmark_seal_fill),
    _NavItem('单词', CupertinoIcons.text_bubble_fill),
    _NavItem('成就', CupertinoIcons.rosette),
    _NavItem('日历', CupertinoIcons.calendar),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // 微妙纵向渐变背景：去除"毛坯房"纯色平铺感，增加纵深感
    // 浅色：白 → 极淡灰青；深色：深青 → 更深，顶部略亮
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: isDark
          ? [const Color(0xFF16222A), const Color(0xFF0E161B)]
          : [Colors.white, const Color(0xFFF4F6F8)],
    );
    return DecoratedBox(
      decoration: BoxDecoration(gradient: gradient),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 页面内容（各页面自带 CupertinoPageScaffold，背景透明以透出渐变）
          Positioned.fill(
            child: IndexedStack(index: _index, children: _pages),
          ),
          // Duolingo 风格底部胶囊导航
          Positioned(
            left: 16,
            right: 16,
            bottom: 8,
            child: SafeArea(
              top: false,
              child: _DuoBottomBar(
                items: _items,
                currentIndex: _index,
                onTap: (i) => setState(() => _index = i),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Duolingo 风格底部导航：白色胶囊容器，选中项有绿色圆角背景 + 3D 立体感
class _DuoBottomBar extends StatelessWidget {
  final List<_NavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _DuoBottomBar({
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const radius = 999.0;
    final bg = isDark
        ? const Color(0xFF1F2D34).withOpacity(0.92)
        : Colors.white.withOpacity(0.94);
    final borderColor = isDark
        ? Colors.white.withOpacity(0.08)
        : AppTheme.kSeparatorLight;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.45 : 0.12),
            blurRadius: 28,
            spreadRadius: -8,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            color: bg,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(items.length, (i) {
                final item = items[i];
                final selected = i == currentIndex;
                return GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: _DuoNavItem(
                    item: item,
                    selected: selected,
                    isDark: isDark,
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _DuoNavItem extends StatelessWidget {
  final _NavItem item;
  final bool selected;
  final bool isDark;

  const _DuoNavItem({
    required this.item,
    required this.selected,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    // 选中项：绿色填充胶囊 + 白字白图标（3D 立体感）
    // 未选中项：透明 + 灰字
    final activeBg = AppTheme.kDuoGreen;
    final activeFg = Colors.white;
    final muted = isDark
        ? AppTheme.kSecondaryTextDark
        : AppTheme.kSecondaryTextLight;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: selected ? activeBg : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        border: Border(
          bottom: BorderSide(
            color: selected ? AppTheme.kDuoGreenDark : Colors.transparent,
            width: selected ? 3 : 0,
          ),
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                item.icon,
                size: 22,
                color: selected ? activeFg : muted,
              ),
              const SizedBox(width: 7),
              Text(
                item.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: selected ? activeFg : muted,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
          // 选中态顶部高光：与 3D 按钮一致的"光面"质感
          if (selected)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Container(
                  height: 18,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(999),
                      topRight: Radius.circular(999),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withOpacity(0.22),
                        Colors.white.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;

  const _NavItem(this.label, this.icon);
}
