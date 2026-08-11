import 'package:flutter/cupertino.dart';
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
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  await StorageService.instance.init();
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
          builder: (context, child) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return CupertinoTheme(
              data: AppTheme.cupertinoTheme(
                isDark ? Brightness.dark : Brightness.light,
              ),
              child: child!,
            );
          },
          home: const HomePage(),
        );
      },
    );
  }
}
