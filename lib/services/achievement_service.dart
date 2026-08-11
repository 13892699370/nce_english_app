import 'package:flutter/foundation.dart';
import 'storage_service.dart';
import '../data/achievements_data.dart';
import '../models/lesson_checkin.dart';
import 'haptic_service.dart';

/// 成就服务：检查达成条件并解锁
///
/// 解锁时返回新解锁的成就列表，由 UI 弹出庆祝弹窗。
class AchievementService extends ChangeNotifier {
  AchievementService._();
  static final AchievementService instance = AchievementService._();

  /// 扫描所有成就，返回本次新解锁的成就（未在持久化记录中的）
  Future<List<AchievementDef>> checkAndUnlock() async {
    final all = StorageService.instance.allCheckins();
    final newlyUnlocked = <AchievementDef>[];
    for (final def in kAchievements) {
      if (StorageService.instance.isUnlocked(def.id)) continue;
      if (AchievementEvaluator.isUnlocked(def, all)) {
        final now = DateTime.now();
        final at =
            '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
        await StorageService.instance.unlock(def.id, at);
        newlyUnlocked.add(def);
      }
    }
    if (newlyUnlocked.isNotEmpty) {
      await HapticService.celebrate();
      notifyListeners();
    }
    return newlyUnlocked;
  }
}
