import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'learning_checkin_page.dart';
import 'word_learning_page.dart';
import 'achievement_page.dart';

/// 主框架：CupertinoTabScaffold + CupertinoTabBar（iOS 原生风格底部导航）
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.book),
            activeIcon: Icon(CupertinoIcons.book_fill),
            label: '打卡',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.text_bubble),
            activeIcon: Icon(CupertinoIcons.text_bubble_fill),
            label: '单词',
          ),
          BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.star),
                activeIcon: Icon(CupertinoIcons.star_fill),
                label: '成就',
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
          default:
            return CupertinoTabView(
              builder: (_) => const AchievementPage(),
            );
        }
      },
    );
  }
}
