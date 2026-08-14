import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/haptic_service.dart';

/// Liquid Glass 风格教材下拉框（同卡片一致的模糊+高光+双层边框）
class TextbookDropdown extends StatefulWidget {
  final List<TextbookDropdownOption> options;
  final String value;
  final ValueChanged<String> onChanged;

  const TextbookDropdown({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  @override
  State<TextbookDropdown> createState() => _TextbookDropdownState();
}

class TextbookDropdownOption {
  final String value;
  final String label;
  const TextbookDropdownOption({required this.value, required this.label});
}

class _TextbookDropdownState extends State<TextbookDropdown> {
  bool _pressed = false;

  void _showActionSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor =
        isDark ? AppTheme.kLuminaLime : AppTheme.kLuminaBlack;

    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) {
        return CupertinoActionSheet(
          actions: widget.options.map((opt) {
            final selected = opt.value == widget.value;
            return CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(context).pop();
                if (selected) return;
                HapticService.selection();
                widget.onChanged(opt.value);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      opt.label,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (selected) ...[
                    const SizedBox(width: 8),
                    Icon(
                      CupertinoIcons.check_mark,
                      size: 20,
                      color: accentColor,
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor =
        isDark ? AppTheme.kLuminaLime : AppTheme.kLuminaBlack;
    final currentLabel = widget.options
        .firstWhere((o) => o.value == widget.value,
            orElse: () => widget.options.first)
        .label;

    final blur = 36.0;
    const radius = 20.0;
    final glassBase = isDark
        ? const Color(0xFF1B1B1B).withOpacity(0.52)
        : const Color(0xFFFFFFFF).withOpacity(0.50);
    final innerBorder =
        isDark ? Colors.white.withOpacity(0.16) : Colors.white.withOpacity(0.75);
    final outerBorder = isDark
        ? Colors.white.withOpacity(0.06)
        : const Color(0xFF000000).withOpacity(0.05);
    final shadows = isDark
        ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.40),
              blurRadius: 30,
              spreadRadius: -6,
              offset: const Offset(0, 14),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 10,
              spreadRadius: -2,
              offset: const Offset(0, 5),
            ),
          ]
        : [
            BoxShadow(
              color: const Color(0xFF3A3A4A).withOpacity(0.14),
              blurRadius: 34,
              spreadRadius: -8,
              offset: const Offset(0, 14),
            ),
            BoxShadow(
              color: const Color(0xFF3A3A4A).withOpacity(0.06),
              blurRadius: 10,
              spreadRadius: -2,
              offset: const Offset(0, 5),
            ),
          ];

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        _showActionSheet();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 140),
        scale: _pressed ? 0.985 : 1.0,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: outerBorder,
              width: 1.0,
              strokeAlign: BorderSide.strokeAlignOutside,
            ),
            boxShadow: shadows,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: Stack(
              children: [
                // Blur
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                    child: const SizedBox.expand(),
                  ),
                ),
                // Base
                Positioned.fill(child: ColoredBox(color: glassBase)),
                // Inner border
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
                // Top highlight
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(radius)),
                    child: SizedBox(
                      height: 34,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withOpacity(isDark ? 0.14 : 0.50),
                              Colors.white.withOpacity(0.0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Bottom inner shadow
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: radius,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          (isDark ? Colors.black : const Color(0xFF3A3A4A))
                              .withOpacity(isDark ? 0.22 : 0.06),
                        ],
                      ),
                    ),
                  ),
                ),
                // Content
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
                  child: Row(
                    children: [
                      Icon(
                        CupertinoIcons.book,
                        size: 20,
                        color: accentColor,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          currentLabel,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppTheme.kLuminaTextDark
                                : AppTheme.kLuminaText,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                      Icon(
                        CupertinoIcons.chevron_down,
                        size: 14,
                        color: const Color(0xFF8E8E93),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
