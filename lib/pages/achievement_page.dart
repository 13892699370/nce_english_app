import 'package:flutter/material.dart';
import '../data/achievements_data.dart';
import '../data/textbook_registry.dart';
import '../models/lesson_checkin.dart';
import '../services/storage_service.dart';
import '../services/textbook_service.dart';
import '../widgets/liquid_glass_card.dart';

/// 成就徽章系统
///
/// 已解锁彩色，未解锁灰色置灰；本地保存解锁时间。
class AchievementPage extends StatefulWidget {
  const AchievementPage({super.key});

  @override
  State<AchievementPage> createState() => _AchievementPageState();
}

class _AchievementPageState extends State<AchievementPage> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final all = StorageService.instance.allCheckins();
    final streak = AchievementEvaluator.currentStreak(all);
    final total = AchievementEvaluator.totalDays(all);
    final unlockedMap = {
      for (final u in StorageService.instance.allUnlocks())
        u.achievementId: u.unlockedAt
    };

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            // 标题
            Text('🏅 成就徽章',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),

            // 进度统计卡
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
                          color: const Color(0xFF1CB0F6),
                          icon: Icons.local_fire_department_rounded,
                        ),
                      ),
                      Container(
                          width: 1,
                          height: 48,
                          color: theme.colorScheme.outline.withOpacity(0.15)),
                      Expanded(
                        child: _bigStat(
                          theme: theme,
                          value: '$total',
                          label: '累计打卡（天）',
                          color: const Color(0xFF58CC02),
                          icon: Icons.calendar_month_rounded,
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
                          label: '已解锁徽章',
                          color: const Color(0xFFFFC800),
                          icon: Icons.emoji_events_rounded,
                        ),
                      ),
                      Container(
                          width: 1,
                          height: 48,
                          color: theme.colorScheme.outline.withOpacity(0.15)),
                      Expanded(
                        child: _bigStat(
                          theme: theme,
                          value: '${kAchievements.length}',
                          label: '徽章总数',
                          color: const Color(0xFFCE82FF),
                          icon: Icons.star_rounded,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 成就列表
            ...kAchievements.map((def) => _buildAchievementCard(
                  theme: theme,
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
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface.withOpacity(0.55),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildAchievementCard({
    required ThemeData theme,
    required AchievementDef def,
    required String? unlockedAt,
    required List<LessonCheckin> all,
  }) {
    final unlocked = unlockedAt != null;
    final progress = _progressOf(def, all);

    return LiquidGlassCard(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          // 徽章
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: unlocked
                  ? const SweepGradient(
                      colors: [
                        Color(0xFFFFC800),
                        Color(0xFFFF9600),
                        Color(0xFFCE82FF),
                        Color(0xFF1CB0F6),
                        Color(0xFFFFC800),
                      ],
                    )
                  : null,
              color: unlocked ? null : Colors.grey.shade300,
              boxShadow: unlocked
                  ? [
                      BoxShadow(
                        color: const Color(0xFFFFC800).withOpacity(0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            alignment: Alignment.center,
            child: Opacity(
              opacity: unlocked ? 1.0 : 0.4,
              child: Text(
                def.emoji,
                style: const TextStyle(fontSize: 32),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // 文案
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
                          fontWeight: FontWeight.w800,
                          color: unlocked
                              ? theme.colorScheme.onSurface
                              : theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ),
                    if (unlocked) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.check_circle,
                          color: Color(0xFF58CC02), size: 16),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  def.desc,
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 6),
                if (unlocked)
                  Text(
                    '🔓 解锁于 $unlockedAt',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF58CC02),
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
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 6,
            backgroundColor: theme.colorScheme.surface,
            valueColor:
                const AlwaysStoppedAnimation(Color(0xFFFFC800)),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$current / $target',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface.withOpacity(0.5),
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
