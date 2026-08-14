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
            constraints: const BoxConstraints(maxWidth: 340),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.08)
                      : const Color(0xFF000000).withOpacity(0.06),
                  width: 1.0,
                  strokeAlign: BorderSide.strokeAlignOutside,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withOpacity(0.50)
                        : const Color(0xFF3A3A4A).withOpacity(0.24),
                    blurRadius: 50,
                    spreadRadius: -8,
                    offset: const Offset(0, 22),
                  ),
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withOpacity(0.25)
                        : const Color(0xFF3A3A4A).withOpacity(0.10),
                    blurRadius: 16,
                    spreadRadius: -2,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: Stack(
                  children: [
                    // 1) Blur - Liquid Glass 核心
                    Positioned.fill(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 44, sigmaY: 44),
                        child: const SizedBox.expand(),
                      ),
                    ),
                    // 2) 底色渐变
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: isDark
                                ? [
                                    const Color(0xFF2A2A2E).withOpacity(0.60),
                                    const Color(0xFF1B1B1B).withOpacity(0.68),
                                    const Color(0xFF111111).withOpacity(0.82),
                                  ]
                                : [
                                    const Color(0xFFFFFFFF).withOpacity(0.70),
                                    const Color(0xFFFFFFFF).withOpacity(0.56),
                                    const Color(0xFFF0F0F4).withOpacity(0.68),
                                  ],
                          ),
                        ),
                      ),
                    ),
                    // 3) 内描边
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withOpacity(0.20)
                                : Colors.white.withOpacity(0.78),
                            width: 0.8,
                            strokeAlign: BorderSide.strokeAlignInside,
                          ),
                        ),
                      ),
                    ),
                    // 4) 顶部弧形高光（iOS 玻璃最具标志性的效果）
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: ClipRRect(
                        borderRadius:
                            const BorderRadius.vertical(top: Radius.circular(32)),
                        child: SizedBox(
                          height: 80,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.white.withOpacity(isDark ? 0.22 : 0.65),
                                  Colors.white.withOpacity(isDark ? 0.04 : 0.10),
                                  Colors.white.withOpacity(0.0),
                                ],
                                stops: const [0.0, 0.55, 1.0],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // 5) 对角线微光
                    Positioned.fill(
                      child: IgnorePointer(
                        child: ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withOpacity(isDark ? 0.06 : 0.18),
                              Colors.white.withOpacity(0.0),
                              Colors.white.withOpacity(0.0),
                              Colors.black.withOpacity(isDark ? 0.14 : 0.03),
                            ],
                            stops: const [0.0, 0.4, 0.75, 1.0],
                          ).createShader(bounds),
                          blendMode: BlendMode.srcOver,
                          child: const SizedBox.expand(),
                        ),
                      ),
                    ),
                    // 6) 底部吸光阴影
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: 60,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              (isDark
                                      ? Colors.black
                                      : const Color(0xFF3A3A4A))
                                  .withOpacity(isDark ? 0.30 : 0.08),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // 7) 内容
                    Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            CupertinoIcons.sparkles,
                            size: 34,
                            color: isDark
                                ? AppTheme.kLuminaLime
                                : AppTheme.kLuminaBlack,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '成就解锁！',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppTheme.kLuminaLime
                                  : AppTheme.kLuminaBlack,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: SweepGradient(
                                colors: [
                                  AppTheme.kSystemBlue,
                                  AppTheme.kSystemPurple,
                                  AppTheme.kSystemPink,
                                  AppTheme.kSystemOrange,
                                  AppTheme.kLuminaLime,
                                  AppTheme.kSystemBlue,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.kSystemBlue.withOpacity(0.30),
                                  blurRadius: 20,
                                  spreadRadius: -2,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Container(
                              width: 84,
                              height: 84,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.18),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                widget.achievement.emoji,
                                style: const TextStyle(fontSize: 46),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            widget.achievement.title,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: onSurfaceColor,
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
                              color: onSurfaceColor.withOpacity(0.62),
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
