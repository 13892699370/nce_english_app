import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'learning_checkin_page.dart';
import 'word_learning_page.dart';
import 'achievement_page.dart';
import 'calendar_page.dart';

/// 主框架：CupertinoTabScaffold + CupertinoTabBar（iOS 原生风格底部导航）
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.checkmark_alt_circle, size: 24),
            activeIcon: Icon(CupertinoIcons.checkmark_alt_circle_fill, size: 24),
            label: '打卡',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.text_bubble, size: 24),
            activeIcon: Icon(CupertinoIcons.text_bubble_fill, size: 24),
            label: '单词',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.star, size: 24),
            activeIcon: Icon(CupertinoIcons.star_fill, size: 24),
            label: '成就',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.calendar, size: 24),
            activeIcon: Icon(CupertinoIcons.calendar, size: 26),
            label: '日历',
          ),
        ],
      ),
      tabBuilder: (context, index) {
        switch (index) {
          case 0:
            return CupertinoTabView(
              builder: (_) => const LearningCheckinPage(),
            );
          case 1:
            return CupertinoTabView(
              builder: (_) => const WordLearningPage(),
            );
          case 2:
            return CupertinoTabView(
              builder: (_) => const AchievementPage(),
            );
          default:
            return CupertinoTabView(
              builder: (_) => const CalendarPage(),
            );
        }
      },
    );
  }
}
