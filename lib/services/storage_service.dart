import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/achievement_unlock.dart';
import '../models/app_settings.dart';
import '../models/lesson_checkin.dart';
import '../models/word_progress.dart';

/// Hive 本地存储服务（双端兼容）
///
/// 统一管理所有 Box，提供 CRUD + ChangeNotifier 通知 UI 刷新。
/// 不同教材数据通过模型字段隔离，不混存。
/// 所有读取操作包裹 try-catch，异常时返回安全默认值，不闪退。
class StorageService extends ChangeNotifier {
  StorageService._();
  static final StorageService instance = StorageService._();

  late Box<LessonCheckin> _checkinBox;
  late Box<WordProgress> _wordBox;
  late Box<AchievementUnlock> _achievementBox;
  late Box<AppSettings> _settingsBox;

  bool _initialized = false;

  /// 初始化 Hive 并打开所有 Box（应用启动调用一次）
  Future<void> init() async {
    if (_initialized) return;
    try {
      await Hive.initFlutter();

      Hive.registerAdapter(LessonCheckinAdapter());
      Hive.registerAdapter(WordProgressAdapter());
      Hive.registerAdapter(AchievementUnlockAdapter());
      Hive.registerAdapter(AppSettingsAdapter());

      _checkinBox = await Hive.openBox<LessonCheckin>('checkins');
      _wordBox = await Hive.openBox<WordProgress>('words');
      _achievementBox = await Hive.openBox<AchievementUnlock>('achievements');
      _settingsBox = await Hive.openBox<AppSettings>('settings');

      _initialized = true;
    } catch (e) {
      debugPrint('StorageService init error: $e');
      rethrow;
    }
  }

  // ---------------- 打卡 ----------------

  List<LessonCheckin> allCheckins() {
    try {
      return _checkinBox.values.toList();
    } catch (e) {
      debugPrint('allCheckins error: $e');
      return [];
    }
  }

  List<LessonCheckin> checkinsOf(String textbookId) {
    try {
      return _checkinBox.values.where((c) => c.textbook == textbookId).toList();
    } catch (e) {
      debugPrint('checkinsOf error: $e');
      return [];
    }
  }

  List<LessonCheckin> checkinsOfDay(String textbookId, int dayNumber) {
    try {
      return _checkinBox.values
          .where((c) => c.textbook == textbookId && c.dayNumber == dayNumber)
          .toList();
    } catch (e) {
      debugPrint('checkinsOfDay error: $e');
      return [];
    }
  }

  LessonCheckin? getCheckin(String textbookId, String date, int dayNumber) {
    try {
      return _checkinBox.get('${textbookId}_$date\_day$dayNumber');
    } catch (e) {
      debugPrint('getCheckin error: $e');
      return null;
    }
  }

  /// 保存打卡（覆盖同主键记录）
  Future<void> saveCheckin(LessonCheckin c) async {
    try {
      await _checkinBox.put(c.key, c);
      notifyListeners();
    } catch (e) {
      debugPrint('saveCheckin error: $e');
    }
  }

  Future<void> deleteCheckin(String key) async {
    try {
      await _checkinBox.delete(key);
      notifyListeners();
    } catch (e) {
      debugPrint('deleteCheckin error: $e');
    }
  }

  // ---------------- 单词进度 ----------------

  List<WordProgress> wordsOf(String textbookId) {
    try {
      return _wordBox.values.where((w) => w.textbook == textbookId).toList();
    } catch (e) {
      debugPrint('wordsOf error: $e');
      return [];
    }
  }

  WordProgress? getWord(String textbookId, String word) {
    try {
      return _wordBox.get('${textbookId}_$word');
    } catch (e) {
      debugPrint('getWord error: $e');
      return null;
    }
  }

  Future<void> saveWord(WordProgress w) async {
    try {
      await _wordBox.put(w.key, w);
      notifyListeners();
    } catch (e) {
      debugPrint('saveWord error: $e');
    }
  }

  // ---------------- 成就 ----------------

  List<AchievementUnlock> allUnlocks() {
    try {
      return _achievementBox.values.toList();
    } catch (e) {
      debugPrint('allUnlocks error: $e');
      return [];
    }
  }

  bool isUnlocked(String achievementId) {
    try {
      return _achievementBox.containsKey(achievementId);
    } catch (e) {
      debugPrint('isUnlocked error: $e');
      return false;
    }
  }

  Future<void> unlock(String achievementId, String at) async {
    try {
      await _achievementBox.put(achievementId, AchievementUnlock(
        achievementId: achievementId,
        unlockedAt: at,
      ));
      notifyListeners();
    } catch (e) {
      debugPrint('unlock error: $e');
    }
  }

  // ---------------- 设置 ----------------

  AppSettings settings() {
    try {
      final s = _settingsBox.get('app');
      if (s != null) return s;
      final fresh = AppSettings();
      _settingsBox.put('app', fresh);
      return fresh;
    } catch (e) {
      debugPrint('settings error: $e');
      return AppSettings();
    }
  }

  Future<void> updateSettings(AppSettings settings) async {
    try {
      await _settingsBox.put('app', settings);
      notifyListeners();
    } catch (e) {
      debugPrint('updateSettings error: $e');
    }
  }

  /// 更新指定教材的当前学习天数
  Future<void> setCurrentDay(String textbookId, int day) async {
    final s = settings();
    s.setCurrentDay(textbookId, day);
    await updateSettings(s);
  }

  /// 获取指定教材的当前学习天数
  int currentDayOf(String textbookId) {
    return settings().currentDayOf(textbookId);
  }
}
