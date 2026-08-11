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
    await Hive.initFlutter();

    // 注册手动 TypeAdapter（typeId 已在 adapter 内固定，双端一致）
    Hive.registerAdapter(LessonCheckinAdapter());
    Hive.registerAdapter(WordProgressAdapter());
    Hive.registerAdapter(AchievementUnlockAdapter());
    Hive.registerAdapter(AppSettingsAdapter());

    _checkinBox = await Hive.openBox<LessonCheckin>('checkins');
    _wordBox = await Hive.openBox<WordProgress>('words');
    _achievementBox = await Hive.openBox<AchievementUnlock>('achievements');
    _settingsBox = await Hive.openBox<AppSettings>('settings');

    _initialized = true;
  }

  // ---------------- 打卡 ----------------

  List<LessonCheckin> allCheckins() => _checkinBox.values.toList();

  List<LessonCheckin> checkinsOf(String textbookId) =>
      _checkinBox.values.where((c) => c.textbook == textbookId).toList();

  LessonCheckin? getCheckin(String textbookId, String date, int lessonNumber) {
    return _checkinBox.get('${textbookId}_$date\_$lessonNumber');
  }

  /// 保存打卡（覆盖同主键记录）
  Future<void> saveCheckin(LessonCheckin c) async {
    await _checkinBox.put(c.key, c);
    notifyListeners();
  }

  Future<void> deleteCheckin(String key) async {
    await _checkinBox.delete(key);
    notifyListeners();
  }

  // ---------------- 单词进度 ----------------

  List<WordProgress> wordsOf(String textbookId) =>
      _wordBox.values.where((w) => w.textbook == textbookId).toList();

  WordProgress? getWord(String textbookId, String word) =>
      _wordBox.get('${textbookId}_$word');

  Future<void> saveWord(WordProgress w) async {
    await _wordBox.put(w.key, w);
    notifyListeners();
  }

  // ---------------- 成就 ----------------

  List<AchievementUnlock> allUnlocks() => _achievementBox.values.toList();

  bool isUnlocked(String achievementId) =>
      _achievementBox.containsKey(achievementId);

  Future<void> unlock(String achievementId, String at) async {
    await _achievementBox.put(achievementId, AchievementUnlock(
      achievementId: achievementId,
      unlockedAt: at,
    ));
    notifyListeners();
  }

  // ---------------- 设置 ----------------

  AppSettings settings() {
    final s = _settingsBox.get('app');
    if (s != null) return s;
    final fresh = AppSettings();
    _settingsBox.put('app', fresh);
    return fresh;
  }

  Future<void> updateSettings(AppSettings settings) async {
    await _settingsBox.put('app', settings);
    notifyListeners();
  }
}
