import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/haptic_service.dart';

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

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        _showActionSheet();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 100),
        opacity: _pressed ? 0.5 : 1.0,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.kLuminaSurfaceDark : AppTheme.kLuminaSurface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.06)
                  : AppTheme.kLuminaSurfaceHigh.withOpacity(0.55),
              width: 0.7,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.22 : 0.04),
                blurRadius: 24,
                offset: const Offset(0, 8),
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
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppTheme.kLuminaTextDark : AppTheme.kLuminaText,
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
      ),
    );
  }
}
