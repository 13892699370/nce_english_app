import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../data/achievements_data.dart';
import '../data/textbook_registry.dart';
import '../models/lesson_checkin.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/liquid_glass_card.dart';
import '../widgets/theme_toggle_button.dart';

/// 成就徽章页（iOS 原生风格）
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
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 132),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 6, 4, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '打卡挑战',
                  style: theme.textTheme.displayMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '查看连续学习、累计打卡和已解锁徽章。',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.58),
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
          LiquidGlassCard(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _bigStat(
                        theme: theme,
                        value: '$streak',
                        label: '当前连续（天）',
                        color: AppTheme.kSystemTeal,
                        icon: CupertinoIcons.flame,
                      ),
                    ),
                    Container(
                        width: 1,
                        height: 44,
                        color: theme.colorScheme.outline.withOpacity(0.12)),
                    Expanded(
                      child: _bigStat(
                        theme: theme,
                        value: '$total',
                        label: '累计打卡（天）',
                        color: AppTheme.kSystemGreen,
                        icon: CupertinoIcons.calendar,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _bigStat(
                        theme: theme,
                        value: '${unlockedMap.length}',
                        label: '已解锁',
                        color: AppTheme.kSystemYellow,
                        icon: CupertinoIcons.rosette,
                      ),
                    ),
                    Container(
                        width: 1,
                        height: 44,
                        color: theme.colorScheme.outline.withOpacity(0.12)),
                    Expanded(
                      child: _bigStat(
                        theme: theme,
                        value: '${kAchievements.length}',
                        label: '徽章总数',
                        color: AppTheme.kSystemPurple,
                        icon: CupertinoIcons.star_fill,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...kAchievements.map((def) => _buildAchievementCard(
                theme: theme,
                isDark: isDark,
                def: def,
                unlockedAt: unlockedMap[def.id],
                all: all,
              )),
        ],
        ),
      ),
    );
  }

  Widget _bigStat({
    required ThemeData theme,
    required String value,
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurface.withOpacity(0.5),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildAchievementCard({
    required ThemeData theme,
    required bool isDark,
    required AchievementDef def,
    required String? unlockedAt,
    required List<LessonCheckin> all,
  }) {
    final unlocked = unlockedAt != null;
    final progress = _progressOf(def, all);

    return LiquidGlassCard(
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: unlocked
                  ? SweepGradient(
                      colors: [
                        AppTheme.kSystemBlue,
                        AppTheme.kSystemPurple,
                        AppTheme.kSystemPink,
                        AppTheme.kSystemOrange,
                        AppTheme.kSystemBlue,
                      ],
                    )
                  : null,
              color: unlocked
                  ? null
                  : (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA)),
              boxShadow: unlocked
                  ? [
                      BoxShadow(
                        color: AppTheme.kSystemBlue.withOpacity(0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            alignment: Alignment.center,
            child: Opacity(
              opacity: unlocked ? 1.0 : 0.35,
              child: Text(
                def.emoji,
                style: const TextStyle(fontSize: 28),
              ),
            ),
          ),
          const SizedBox(width: 14),
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
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: unlocked
                              ? theme.colorScheme.onSurface
                              : theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ),
                    if (unlocked) ...[
                      const SizedBox(width: 6),
                      Icon(CupertinoIcons.checkmark_circle_fill,
                          color: AppTheme.kSystemGreen, size: 16),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  def.desc,
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurface.withOpacity(0.55),
                  ),
                ),
                const SizedBox(height: 6),
                if (unlocked)
                  Text(
                    '解锁于 $unlockedAt',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.kSystemGreen,
                    ),
                  )
                else if (progress != null)
                  _progressBar(theme, progress.$1, progress.$2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _progressBar(ThemeData theme, int current, int target) {
    final ratio = target == 0 ? 0.0 : (current / target).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 4,
            backgroundColor: theme.colorScheme.surface,
            valueColor:
                AlwaysStoppedAnimation(theme.colorScheme.primary),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$current / $target',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurface.withOpacity(0.4),
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
