import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'learning_checkin_page.dart';
import 'word_learning_page.dart';
import 'achievement_page.dart';
import 'calendar_page.dart';

/// 主框架：Lumina Mono 悬浮胶囊底部导航
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
      children: [
        IndexedStack(index: _index, children: _pages),
        Positioned(
          left: 20,
          right: 20,
          bottom: 18,
          child: SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                color: (isDark
                        ? AppTheme.kLuminaSurfaceDark
                        : AppTheme.kLuminaSurface)
                    .withOpacity(0.88),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.08)
                      : Colors.white.withOpacity(0.7),
                  width: 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.28 : 0.08),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(_items.length, (i) {
                  final item = _items[i];
                  final selected = i == _index;
                  final activeColor =
                      isDark ? AppTheme.kLuminaLime : AppTheme.kLuminaBlack;
                  final muted = isDark
                      ? AppTheme.kLuminaMutedDark
                      : AppTheme.kLuminaMuted;
                  return GestureDetector(
                    onTap: () => setState(() => _index = i),
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
          ),
        ),
      ],
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const _NavItem(this.label, this.icon, this.activeIcon);
}
