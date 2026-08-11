import 'package:flutter/material.dart';
import 'storage_service.dart';
import '../models/app_settings.dart';

/// 主题服务：深色/浅色/跟随系统切换
class ThemeService extends ChangeNotifier {
  ThemeService._();
  static final ThemeService instance = ThemeService._();

  ThemeMode _mode = ThemeMode.system;

  ThemeMode get mode => _mode;

  void init() {
    final s = StorageService.instance.settings();
    _mode = _parse(s.themeMode);
  }

  Future<void> setMode(ThemeMode m) async {
    _mode = m;
    final s = StorageService.instance.settings();
    s.themeMode = _stringify(m);
    await StorageService.instance.updateSettings(s);
    notifyListeners();
  }

  Future<void> toggle() async {
    await setMode(_mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
  }

  ThemeMode _parse(String s) {
    switch (s) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  String _stringify(ThemeMode m) {
    switch (m) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      default:
        return 'system';
    }
  }
}
