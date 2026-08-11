import '../models/lesson_checkin.dart';
import 'nce1_data.dart';
import 'nce2_data.dart';
import 'nce3_data.dart';

/// 成就定义
class AchievementDef {
  final String id;
  final String emoji;
  final String title;
  final String desc;

  /// 成就类型：streak 连续打卡 / total 累计打卡 / textbook 教材通关
  final String kind;

  /// 阈值（连续天数 / 累计天数；textbook 类型时为课程总数）
  final int threshold;

  /// 教材 id（仅 textbook 类型用）；null 表示对所有教材统计
  final String? textbookId;

  const AchievementDef({
    required this.id,
    required this.emoji,
    required this.title,
    required this.desc,
    required this.kind,
    this.threshold = 0,
    this.textbookId,
  });
}

/// 成就列表（已解锁彩色，未解锁灰色置灰）
///
/// 预留新概念2、新概念3通关成就位。
const List<AchievementDef> kAchievements = [
  AchievementDef(
    id: 'streak_7',
    emoji: '🥉',
    title: '初出茅庐',
    desc: '累计打卡 7 天',
    kind: 'total',
    threshold: 7,
  ),
  AchievementDef(
    id: 'streak_14',
    emoji: '🥈',
    title: '稳步前行',
    desc: '连续打卡 14 天',
    kind: 'streak',
    threshold: 14,
  ),
  AchievementDef(
    id: 'streak_30',
    emoji: '🥇',
    title: '坚持不懈',
    desc: '连续打卡 30 天',
    kind: 'streak',
    threshold: 30,
  ),
  AchievementDef(
    id: 'nce1_complete',
    emoji: '💎',
    title: '筑基大师',
    desc: '新概念1全部课程打卡完成',
    kind: 'textbook',
    textbookId: 'nce1',
  ),
  // 预留位：新概念2通关
  AchievementDef(
    id: 'nce2_complete',
    emoji: '💠',
    title: '进阶大师',
    desc: '新概念2全部课程打卡完成',
    kind: 'textbook',
    textbookId: 'nce2',
  ),
  // 预留位：新概念3通关
  AchievementDef(
    id: 'nce3_complete',
    emoji: '👑',
    title: '巅峰大师',
    desc: '新概念3全部课程打卡完成',
    kind: 'textbook',
    textbookId: 'nce3',
  ),
];

/// 成就判定工具：根据打卡记录判断成就是否达成
class AchievementEvaluator {
  AchievementEvaluator._();

  /// 计算连续打卡天数（按日期去重排序后取最长连续段，到今天为止）
  static int currentStreak(List<LessonCheckin> allCheckins) {
    final days = allCheckins.map((c) => c.date).toSet().toList()..sort();
    if (days.isEmpty) return 0;
    // 从最后一个日期向前数连续天数
    int streak = 0;
    DateTime? prev;
    for (var i = days.length - 1; i >= 0; i--) {
      final d = DateTime.parse(days[i]);
      if (prev == null) {
        streak = 1;
      } else {
        if (prev.difference(d).inDays == 1) {
          streak++;
        } else {
          break;
        }
      }
      prev = d;
    }
    return streak;
  }

  /// 累计打卡天数（去重日期数）
  static int totalDays(List<LessonCheckin> allCheckins) {
    return allCheckins.map((c) => c.date).toSet().length;
  }

  /// 判断某教材是否全部课程打卡完成（完成全部任务）
  static bool isTextbookComplete(
    String textbookId,
    int totalLessons,
    List<LessonCheckin> allCheckins,
  ) {
    final done = <int>{};
    for (final c in allCheckins) {
      if (c.textbook == textbookId && c.isAllDone) {
        done.addAll(c.lessonNumbers);
      }
    }
    return done.length >= totalLessons;
  }

  /// 判断指定成就是否已达成
  static bool isUnlocked(
    AchievementDef def,
    List<LessonCheckin> allCheckins,
  ) {
    switch (def.kind) {
      case 'streak':
        return currentStreak(allCheckins) >= def.threshold;
      case 'total':
        return totalDays(allCheckins) >= def.threshold;
      case 'textbook':
        final tbId = def.textbookId!;
        final total = TextbookLessonCount.of(tbId);
        return isTextbookComplete(tbId, total, allCheckins);
      default:
        return false;
    }
  }
}

/// 教材课程总数辅助（避免循环依赖直接 import registry）
class TextbookLessonCount {
  static int of(String textbookId) {
    switch (textbookId) {
      case 'nce1':
        return nce1LessonTitles.length;
      case 'nce2':
        return nce2LessonTitles.length;
      case 'nce3':
        return nce3LessonTitles.length;
      default:
        return 0;
    }
  }
}
