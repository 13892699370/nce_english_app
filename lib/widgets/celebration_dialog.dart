import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'duolingo_button.dart';
import '../data/achievements_data.dart';
import '../theme/app_theme.dart';

/// 成就解锁庆祝弹窗
///
/// iOS 原生风格：磨砂玻璃质感、系统配色、柔和出场动画。
class CelebrationDialog extends StatefulWidget {
  final AchievementDef achievement;
  const CelebrationDialog({super.key, required this.achievement});

  /// 便捷弹窗方法
  static Future<void> show(BuildContext context, AchievementDef def) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.45),
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
      duration: const Duration(milliseconds: 300),
    );
    _scale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
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
    final onSurfaceColor = isDark ? Colors.white : Colors.black;
    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(
        scale: _scale,
        alignment: Alignment.center,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1C1C1E).withOpacity(0.90)
                        : Colors.white.withOpacity(0.90),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withOpacity(0.08)
                          : Colors.black.withOpacity(0.04),
                      width: 0.5,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        CupertinoIcons.sparkles,
                        size: 32,
                        color: isDark
                            ? AppTheme.kSystemBlueDark
                            : AppTheme.kSystemBlue,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '成就解锁！',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppTheme.kSystemBlueDark
                              : AppTheme.kSystemBlue,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              isDark
                                  ? AppTheme.kSystemBlueDark
                                  : AppTheme.kSystemBlue,
                              isDark
                                  ? AppTheme.kSystemPurpleDark
                                  : AppTheme.kSystemPurple,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (isDark
                                      ? AppTheme.kSystemBlueDark
                                      : AppTheme.kSystemBlue)
                                  .withOpacity(0.30),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          widget.achievement.emoji,
                          style: const TextStyle(fontSize: 44),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.achievement.title,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: onSurfaceColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.achievement.desc,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: onSurfaceColor.withOpacity(0.60),
                        ),
                      ),
                      const SizedBox(height: 22),
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
      ),
    );
  }
}
