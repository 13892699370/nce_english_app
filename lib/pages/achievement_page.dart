import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../data/achievements_data.dart';
import '../data/textbook_registry.dart';
import '../models/lesson_checkin.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/liquid_glass_card.dart';
import '../widgets/theme_toggle_button.dart';

/// 成就徽章页（Modern Clean 风格）
class AchievementPage extends StatefulWidget {
  const AchievementPage({super.key});

  @override
  State<AchievementPage> createState() => _AchievementPageState();
}

class _AchievementPageState extends State<AchievementPage> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor =
        isDark ? AppTheme.kTextDark : AppTheme.kTextLight;
    final secondaryColor = AppTheme.kSecondaryTextLight;

    final all = StorageService.instance.allCheckins();
    final streak = AchievementEvaluator.currentStreak(all);
    final total = AchievementEvaluator.totalDays(all);
    final unlockedMap = {
      for (final u in StorageService.instance.allUnlocks())
        u.achievementId: u.unlockedAt
    };

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Lumina Mono'),
        trailing: ThemeToggleButton(),
      ),
      child: Material(
        color: Colors.transparent,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
          children: [
            // 1. 大标题
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 20),
              child: Text(
                '成就',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  color: textColor,
                  decoration: TextDecoration.none,
                ),
              ),
            ),

            // 2. 统计卡（2x2 网格）
            LiquidGlassCard(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _statCell(
                          icon: CupertinoIcons.flame_fill,
                          iconColor: AppTheme.kIndigo,
                          value: '$streak',
                          valueColor: AppTheme.kIndigo,
                          label: '当前连续',
                          secondaryColor: secondaryColor,
                        ),
                      ),
                      Expanded(
                        child: _statCell(
                          icon: CupertinoIcons.calendar,
                          iconColor: secondaryColor,
                          value: '$total',
                          valueColor: textColor,
                          label: '累计打卡',
                          secondaryColor: secondaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _statCell(
                          icon: CupertinoIcons.checkmark_seal_fill,
                          iconColor: secondaryColor,
                          value: '${unlockedMap.length}',
                          valueColor: textColor,
                          label: '已解锁',
                          secondaryColor: secondaryColor,
                        ),
                      ),
                      Expanded(
                        child: _statCell(
                          icon: CupertinoIcons.rosette,
                          iconColor: secondaryColor,
                          value: '${kAchievements.length}',
                          valueColor: textColor,
                          label: '总成就',
                          secondaryColor: secondaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 3. 我的徽章 标题
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 12),
              child: Text(
                '我的徽章',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                  decoration: TextDecoration.none,
                ),
              ),
            ),

            // 4. 成就卡片
            ...kAchievements.map((def) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildAchievementCard(
                    isDark: isDark,
                    def: def,
                    unlockedAt: unlockedMap[def.id],
                    all: all,
                    textColor: textColor,
                    secondaryColor: secondaryColor,
                  ),
                )),
          ],
        ),
      ),
    );
  }

  /// 统计单元：图标(20) + 数字(36 w800) + 标签(13 secondary)
  Widget _statCell({
    required IconData icon,
    required Color iconColor,
    required String value,
    required Color valueColor,
    required String label,
    required Color secondaryColor,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.0,
            color: valueColor,
            decoration: TextDecoration.none,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: secondaryColor,
            decoration: TextDecoration.none,
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementCard({
    required bool isDark,
    required AchievementDef def,
    required String? unlockedAt,
    required List<LessonCheckin> all,
    required Color textColor,
    required Color secondaryColor,
  }) {
    final unlocked = unlockedAt != null;
    final progress = _progressOf(def, all);
    final accent = isDark ? AppTheme.kIndigoLight : AppTheme.kIndigo;
    final grayCircle =
        isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA);

    return LiquidGlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 徽章圆形图标
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: unlocked
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [accent, AppTheme.kIndigo],
                    )
                  : null,
              color: unlocked ? null : grayCircle,
            ),
            alignment: Alignment.center,
            child: Opacity(
              opacity: unlocked ? 1.0 : 0.3,
              child: Text(
                def.emoji,
                style: const TextStyle(fontSize: 32),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // 右侧内容
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        def.title,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: unlocked
                              ? textColor
                              : textColor.withOpacity(0.5),
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                    if (unlocked) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.kSuccess.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '已解锁',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.kSuccess,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  def.desc,
                  style: TextStyle(
                    fontSize: 13,
                    color: unlocked
                        ? secondaryColor
                        : secondaryColor.withOpacity(0.5),
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 10),
                if (unlocked)
                  Text(
                    '解锁于 $unlockedAt',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.kSuccess,
                      decoration: TextDecoration.none,
                    ),
                  )
                else if (progress != null)
                  _progressBar(progress.$1, progress.$2, accent, secondaryColor)
                else
                  Text(
                    '未达成',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: secondaryColor.withOpacity(0.5),
                      decoration: TextDecoration.none,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 进度条：灰色背景 + Indigo 填充
  Widget _progressBar(
    int current,
    int target,
    Color accent,
    Color secondaryColor,
  ) {
    final ratio = target == 0 ? 0.0 : (current / target).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 5,
            backgroundColor: AppTheme.kSeparatorLight,
            valueColor: AlwaysStoppedAnimation(accent),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          '$current / $target',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: secondaryColor.withOpacity(0.6),
            decoration: TextDecoration.none,
          ),
        ),
      ],
    );
  }

  (int, int)? _progressOf(AchievementDef def, List<LessonCheckin> all) {
    switch (def.kind) {
      case 'streak':
        final cur = AchievementEvaluator.currentStreak(all);
        return (cur, def.threshold);
      case 'total':
        final cur = AchievementEvaluator.totalDays(all);
        return (cur, def.threshold);
      case 'textbook':
        final tbId = def.textbookId!;
        final total = TextbookRegistry.lessonsOf(tbId).length;
        final done = <int>{};
        for (final c in all) {
          if (c.textbook == tbId && c.isAllDone) {
            done.addAll(c.lessonNumbers);
          }
        }
        return (done.length, total);
      default:
        return null;
    }
  }
}
