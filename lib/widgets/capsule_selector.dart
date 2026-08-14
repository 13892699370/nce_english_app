import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/haptic_service.dart';

/// Liquid Glass 胶囊分段选择器：玻璃背景 + 玻璃滑块 + 弹性动画
class CapsuleSelector<T> extends StatefulWidget {
  final List<CapsuleOption<T>> options;
  final T value;
  final ValueChanged<T> onChanged;
  final bool enableHaptic;

  const CapsuleSelector({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.enableHaptic = true,
  });

  @override
  State<CapsuleSelector<T>> createState() => _CapsuleSelectorState<T>();
}

class CapsuleOption<T> {
  final T value;
  final String label;
  final IconData? icon;
  const CapsuleOption({required this.value, required this.label, this.icon});
}

class _CapsuleSelectorState<T> extends State<CapsuleSelector<T>> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unselectedTextColor =
        isDark ? AppTheme.kLuminaMutedDark : AppTheme.kLuminaMuted;

    const radius = 999.0;
    final blur = 30.0;
    final glassBase = isDark
        ? const Color(0xFF1B1B1B).withOpacity(0.40)
        : const Color(0xFFFFFFFF).withOpacity(0.46);
    final innerBorder =
        isDark ? Colors.white.withOpacity(0.14) : Colors.white.withOpacity(0.70);
    final outerBorder = isDark
        ? Colors.white.withOpacity(0.05)
        : const Color(0xFF000000).withOpacity(0.05);

    return LayoutBuilder(
      builder: (context, constraints) {
        final count = widget.options.length;
        final w = constraints.maxWidth;
        final segW = count > 0 ? w / count : 0;
        final currentIdx = widget.options
            .indexWhere((o) => o.value == widget.value);
        final idx = currentIdx < 0 ? 0 : currentIdx;

        return Container(
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: outerBorder,
              width: 1.0,
              strokeAlign: BorderSide.strokeAlignOutside,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.30)
                    : const Color(0xFF3A3A4A).withOpacity(0.10),
                blurRadius: 18,
                spreadRadius: -4,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: Stack(
              children: [
                // Glass background blur
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                    child: const SizedBox.expand(),
                  ),
                ),
                Positioned.fill(child: ColoredBox(color: glassBase)),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(radius),
                      border: Border.all(
                        color: innerBorder,
                        width: 0.8,
                        strokeAlign: BorderSide.strokeAlignInside,
                      ),
                    ),
                  ),
                ),
                // Top highlight on glass
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 24,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withOpacity(isDark ? 0.12 : 0.45),
                          Colors.white.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ),

                // Animated thumb (glass slider)
                AnimatedAlign(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment(
                      -1.0 + (idx * 2.0) / (count - 1 > 0 ? count - 1 : 1), 0.0),
                  child: SizedBox(
                    width: segW,
                    height: double.infinity,
                    child: Padding(
                      padding: const EdgeInsets.all(3),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(radius),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: BackdropFilter(
                                filter:
                                    ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                                child: const SizedBox.expand(),
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(radius),
                                color: isDark
                                    ? AppTheme.kLuminaLime.withOpacity(0.90)
                                    : AppTheme.kLuminaBlack.withOpacity(0.88),
                                border: Border.all(
                                  color: Colors.white.withOpacity(
                                      isDark ? 0.35 : 0.22),
                                  width: 0.8,
                                  strokeAlign:
                                      BorderSide.strokeAlignInside,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: (isDark
                                            ? AppTheme.kLuminaLime
                                            : AppTheme.kLuminaBlack)
                                        .withOpacity(0.25),
                                    blurRadius: 10,
                                    spreadRadius: -2,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(radius),
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.white.withOpacity(
                                          isDark ? 0.35 : 0.18),
                                      Colors.white.withOpacity(0.0),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Labels (on top)
                Positioned.fill(
                  child: Row(
                    children: widget.options.map((opt) {
                      final selected = opt.value == widget.value;
                      final fg = selected
                          ? (isDark
                              ? AppTheme.kLuminaBlack
                              : Colors.white)
                          : unselectedTextColor;
                      return Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            if (opt.value == widget.value) return;
                            if (widget.enableHaptic) HapticService.selection();
                            widget.onChanged(opt.value);
                          },
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (opt.icon != null) ...[
                                  Icon(
                                    opt.icon,
                                    size: 16,
                                    color: fg,
                                  ),
                                  const SizedBox(width: 6),
                                ],
                                Text(
                                  opt.label,
                                  style: TextStyle(
                                    color: fg,
                                    fontWeight: selected
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                    fontSize: 15,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
