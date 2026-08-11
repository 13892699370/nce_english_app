import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/storage_service.dart';
import 'services/theme_service.dart';
import 'services/textbook_service.dart';
import 'services/audio_feedback_service.dart';
import 'services/word_tts_service.dart';
import 'theme/app_theme.dart';
import 'pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 锁定竖屏，双端一致体验
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  // 初始化 Hive 存储
  await StorageService.instance.init();
  // 初始化主题与教材
  ThemeService.instance.init();
  TextbookService.instance.init();
  await AudioFeedbackService.instance.init();
  await WordTtsService.instance.init();
  runApp(const NceApp());
}

class NceApp extends StatelessWidget {
  const NceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeService.instance,
      builder: (context, _) {
        return MaterialApp(
          title: '新概念英语打卡',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: ThemeService.instance.mode,
          home: const HomePage(),
        );
      },
    );
  }
}
