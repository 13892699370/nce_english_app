import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/haptic_service.dart';

/// 简洁教材下拉框：白/深色卡片 + 书本图标 + 名称 + 下箭头
/// 点击弹出 CupertinoActionSheet
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
    final accentColor = isDark ? AppTheme.kIndigoLight : AppTheme.kIndigo;

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
    final accentColor = isDark ? AppTheme.kIndigoLight : AppTheme.kIndigo;
    final textColor = isDark ? AppTheme.kTextDark : AppTheme.kTextLight;
    final cardBg = isDark ? AppTheme.kCardDark : AppTheme.kCardLight;
    final currentLabel = widget.options
        .firstWhere((o) => o.value == widget.value,
            orElse: () => widget.options.first)
        .label;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        _showActionSheet();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.30 : 0.06),
                blurRadius: 16,
                spreadRadius: -4,
                offset: const Offset(0, 4),
              ),
            ],
          ),
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
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
              Icon(
                CupertinoIcons.chevron_down,
                size: 14,
                color: AppTheme.kSecondaryTextLight,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
