import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'learning_checkin_page.dart';
import 'word_learning_page.dart';
import 'achievement_page.dart';
import 'calendar_page.dart';

/// 主框架：纯色背景 + IndexedStack 页面 + 浮动胶囊底部导航
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
    _NavItem('成就', CupertinoIcons.rosette_fill),
    _NavItem('日历', CupertinoIcons.calendar),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ColoredBox(
      color: isDark ? AppTheme.kBgDark : AppTheme.kBgLight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 页面内容（各页面自带 CupertinoPageScaffold + 透明导航栏）
          Positioned.fill(
            child: IndexedStack(index: _index, children: _pages),
          ),
          // 浮动胶囊底部导航
          Positioned(
            left: 16,
            right: 16,
            bottom: 8,
            child: SafeArea(
              top: false,
              child: _PillBottomBar(
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

/// 简洁浮动胶囊底部导航：仅 BackdropFilter sigma 30 模糊，
/// 白/深色半透明底，选中项 Indigo + 小圆点指示，未选中灰色。
class _PillBottomBar extends StatelessWidget {
  final List<_NavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _PillBottomBar({
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const radius = 999.0;
    final bg = isDark
        ? const Color(0xFF1C1C1E).withOpacity(0.72)
        : Colors.white.withOpacity(0.72);
    final borderColor = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.black.withOpacity(0.04);
    final activeColor = isDark ? AppTheme.kIndigoLight : AppTheme.kIndigo;
    final muted = isDark ? AppTheme.kSecondaryTextDark : AppTheme.kSecondaryTextLight;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.40 : 0.10),
            blurRadius: 24,
            spreadRadius: -6,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            color: bg,
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
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
                    curve: Curves.easeOut,
                    scale: selected ? 1.08 : 1.0,
                    child: SizedBox(
                      width: 64,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            item.icon,
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
                            width: selected ? 5 : 0,
                            height: selected ? 5 : 0,
                            decoration: BoxDecoration(
                              color: activeColor,
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
        ),
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;

  const _NavItem(this.label, this.icon);
}
