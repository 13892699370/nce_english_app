import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'duolingo_button.dart';
import '../data/achievements_data.dart';
import '../theme/app_theme.dart';

/// 成就解锁庆祝弹窗
/// 缩放 + 淡入动画，简洁白/深色卡片，Indigo 渐变 emoji 圆
class CelebrationDialog extends StatefulWidget {
  final AchievementDef achievement;
  const CelebrationDialog({super.key, required this.achievement});

  /// 便捷弹窗方法
  static Future<void> show(BuildContext context, AchievementDef def) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (_) => CelebrationDialog(achievement: def),
    );
  }

  @override
  State<CelebrationDialog> createState() => _CelebrationDialogState();
}

class _CelebrationDialogState extends State<CelebrationDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _scale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppTheme.kTextDark : AppTheme.kTextLight;
    final cardBg = isDark ? AppTheme.kCardDark : AppTheme.kCardLight;
    final accent = isDark ? AppTheme.kIndigoLight : AppTheme.kIndigo;
    const radius = 24.0;

    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(
        scale: _scale,
        alignment: Alignment.center,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(radius),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.5 : 0.18),
                    blurRadius: 40,
                    spreadRadius: -8,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CupertinoIcons.sparkles,
                      size: 34,
                      color: accent,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '成就解锁！',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: accent,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppTheme.kIndigoLight,
                            AppTheme.kIndigo,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.kIndigo.withOpacity(0.30),
                            blurRadius: 20,
                            spreadRadius: -2,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        widget.achievement.emoji,
                        style: const TextStyle(fontSize: 44),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      widget.achievement.title,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.achievement.desc,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        height: 1.5,
                        color: textColor.withOpacity(0.62),
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: DuolingoButton(
                        label: '太棒了！',
                        variant: DuolingoButtonVariant.primary,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
