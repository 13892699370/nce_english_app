import 'package:flutter/material.dart';
import '../services/theme_service.dart';
import '../services/textbook_service.dart';
import '../services/storage_service.dart';
import 'learning_checkin_page.dart';
import 'word_learning_page.dart';
import 'achievement_page.dart';

/// 主框架：底部 3 个 Tab
///
/// 页面切换使用弹性动画；AppBar 右上角主题切换。
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;

  final _pages = const [
    LearningCheckinPage(),
    WordLearningPage(),
    AchievementPage(),
  ];

  @override
  Widget build(BuildContext context) {
    // 监听服务变化（教材切换/主题切换/数据更新）
    return AnimatedBuilder(
      animation: Listenable.merge([
        StorageService.instance,
        TextbookService.instance,
        ThemeService.instance,
      ]),
      builder: (context, _) {
        return Scaffold(
          body: IndexedStack(
            index: _index,
            children: _pages,
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              child: BottomNavigationBar(
                currentIndex: _index,
                onTap: (i) => setState(() => _index = i),
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.menu_book_outlined),
                    activeIcon: Icon(Icons.menu_book),
                    label: '学习打卡',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.translate),
                    activeIcon: Icon(Icons.translate),
                    label: '单词学习',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.emoji_events_outlined),
                    activeIcon: Icon(Icons.emoji_events),
                    label: '成就徽章',
                  ),
                ],
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            mini: true,
            elevation: 0,
            highlightElevation: 0,
            backgroundColor: Theme.of(context).colorScheme.surface,
            onPressed: () async {
              await ThemeService.instance.toggle();
            },
            child: Icon(
              ThemeService.instance.mode == ThemeMode.dark
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
              size: 20,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        );
      },
    );
  }
}
