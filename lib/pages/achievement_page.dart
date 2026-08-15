import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../data/achievements_data.dart';
import '../data/textbook_registry.dart';
import '../models/lesson_checkin.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/liquid_glass_card.dart';
import '../widgets/theme_toggle_button.dart';

/// 成就徽章页（Duolingo Vibrant 风格）
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
    final textColor = isDark ? AppTheme.kTextDark : AppTheme.kTextLight;
    final secondaryColor = isDark
        ? AppTheme.kSecondaryTextDark
        : AppTheme.kSecondaryTextLight;
    final separatorColor = isDark
        ? AppTheme.kSeparatorDark
        : AppTheme.kSeparatorLight;

    final all = StorageService.instance.allCheckins();
    final streak = AchievementEvaluator.currentStreak(all);
    final total = AchievementEvaluator.totalDays(all);
    final unlockedMap = {
      for (final u in StorageService.instance.allUnlocks())
        u.achievementId: u.unlockedAt
    };

    return CupertinoPageScaffold(
      backgroundColor: Colors.transparent,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: Colors.transparent,
        border: null,
        trailing: const ThemeToggleButton(),
      ),
      child: Material(
        color: Colors.transparent,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
          children: [
            // 1. 大标题 + 副标题
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '成就',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: textColor,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '已解锁 ${unlockedMap.length} / ${kAchievements.length} 个徽章',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: secondaryColor,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),

            // 2. 统计卡（2x2 网格）
            LiquidGlassCard(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
              child: Column(
                children: [
                  IntrinsicHeight(
                    child: Row(
                      children: [
                        Expanded(
                          child: _statCell(
                            icon: CupertinoIcons.flame_fill,
                            iconColor: AppTheme.kDuoOrange,
                            value: '$streak',
                            valueColor: AppTheme.kDuoOrange,
                            label: '当前连续',
                            secondaryColor: secondaryColor,
                          ),
                        ),
                        Container(
                          width: 1,
                          color: separatorColor,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        Expanded(
                          child: _statCell(
                            icon: CupertinoIcons.calendar,
                            iconColor: AppTheme.kDuoBlue,
                            value: '$total',
                            valueColor: AppTheme.kDuoBlue,
                            label: '累计打卡',
                            secondaryColor: secondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 1,
                    color: separatorColor,
                    margin: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 12),
                  ),
                  IntrinsicHeight(
                    child: Row(
                      children: [
                        Expanded(
                          child: _statCell(
                            icon: CupertinoIcons.checkmark_seal_fill,
                            iconColor: AppTheme.kDuoGreen,
                            value: '${unlockedMap.length}',
                            valueColor: AppTheme.kDuoGreen,
                            label: '已解锁',
                            secondaryColor: secondaryColor,
                          ),
                        ),
                        Container(
                          width: 1,
                          color: separatorColor,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        Expanded(
                          child: _statCell(
                            icon: CupertinoIcons.rosette,
                            iconColor: AppTheme.kDuoPurple,
                            value: '${kAchievements.length}',
                            valueColor: AppTheme.kDuoPurple,
                            label: '总成就',
                            secondaryColor: secondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 3. 我的徽章 小标题
            Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Text(
                '我的徽章',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                  decoration: TextDecoration.none,
                ),
              ),
            ),

            // 4. 成就卡片
            ...kAchievements.asMap().entries.map((entry) {
              final index = entry.key;
              final def = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildAchievementCard(
                  index: index,
                  isDark: isDark,
                  def: def,
                  unlockedAt: unlockedMap[def.id],
                  all: all,
                  textColor: textColor,
                  secondaryColor: secondaryColor,
                  separatorColor: separatorColor,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  /// 统计单元：图标(24)放在 44x44 彩色圆形背景里 + 数字(36 w800) + 标签(13 w600 secondary)，居中
  Widget _statCell({
    required IconData icon,
    required Color iconColor,
    required String value,
    required Color valueColor,
    required String label,
    required Color secondaryColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: iconColor.withOpacity(0.15),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 10),
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
          const SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: secondaryColor,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementCard({
    required int index,
    required bool isDark,
    required AchievementDef def,
    required String? unlockedAt,
    required List<LessonCheckin> all,
    required Color textColor,
    required Color secondaryColor,
    required Color separatorColor,
  }) {
    final unlocked = unlockedAt != null;
    final progress = _progressOf(def, all);
    final palette = _badgePalette(index);
    final grayCircle =
        isDark ? AppTheme.kSeparatorDark : AppTheme.kSeparatorLight;

    return LiquidGlassCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 左侧 72x72 圆形徽章
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: unlocked
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: palette.colors,
                    )
                  : null,
              color: unlocked ? null : grayCircle,
              border: unlocked
                  ? Border.all(color: Colors.white, width: 2)
                  : Border.all(color: separatorColor, width: 1),
              boxShadow: unlocked
                  ? [
                      BoxShadow(
                        color: palette.glow.withOpacity(0.35),
                        blurRadius: 18,
                        spreadRadius: 3,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            alignment: Alignment.center,
            child: Opacity(
              opacity: unlocked ? 1.0 : 0.3,
              child: Text(
                def.emoji,
                style: const TextStyle(fontSize: 40),
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
                          fontWeight: FontWeight.w700,
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
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.kDuoGreen.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          '已解锁',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.kDuoGreen,
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
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.kDuoGreen,
                      decoration: TextDecoration.none,
                    ),
                  )
                else if (progress != null)
                  _progressBar(
                    progress.$1,
                    progress.$2,
                    AppTheme.kDuoGreen,
                    secondaryColor,
                    separatorColor,
                  )
                else
                  Text(
                    '未达成',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
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

  /// 进度条：灰色背景 + 绿色填充，圆角，配 current/target 小字
  Widget _progressBar(
    int current,
    int target,
    Color accent,
    Color secondaryColor,
    Color separatorColor,
  ) {
    final ratio = target == 0 ? 0.0 : (current / target).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 10,
            backgroundColor: separatorColor,
            valueColor: AlwaysStoppedAnimation<Color>(accent),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '$current / $target',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: secondaryColor.withOpacity(0.7),
            decoration: TextDecoration.none,
          ),
        ),
      ],
    );
  }

  /// 徽章渐变色板：按 index 循环多彩组合
  _BadgePalette _badgePalette(int index) {
    const palettes = <_BadgePalette>[
      _BadgePalette(
        colors: [AppTheme.kDuoGreenLight, AppTheme.kDuoGreen],
        glow: AppTheme.kDuoGreen,
      ),
      _BadgePalette(
        colors: [AppTheme.kDuoBlue, AppTheme.kDuoPurple],
        glow: AppTheme.kDuoPurple,
      ),
      _BadgePalette(
        colors: [AppTheme.kDuoOrange, AppTheme.kDuoRed],
        glow: AppTheme.kDuoRed,
      ),
      _BadgePalette(
        colors: [AppTheme.kDuoYellow, AppTheme.kDuoOrange],
        glow: AppTheme.kDuoOrange,
      ),
      _BadgePalette(
        colors: [AppTheme.kDuoPurple, AppTheme.kDuoRed],
        glow: AppTheme.kDuoPurple,
      ),
      _BadgePalette(
        colors: [AppTheme.kDuoBlue, AppTheme.kDuoGreen],
        glow: AppTheme.kDuoBlue,
      ),
    ];
    return palettes[index % palettes.length];
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

/// 徽章渐变色板：渐变色 + 发光色
class _BadgePalette {
  final List<Color> colors;
  final Color glow;
  const _BadgePalette({required this.colors, required this.glow});
}