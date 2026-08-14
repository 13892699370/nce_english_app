import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/haptic_service.dart';

class TaskCheckbox extends StatefulWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enableHaptic;

  const TaskCheckbox({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.enableHaptic = true,
  });

  @override
  State<TaskCheckbox> createState() => _TaskCheckboxState();
}

class _TaskCheckboxState extends State<TaskCheckbox> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const accentColor = AppTheme.kLuminaLime;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        if (widget.enableHaptic) {
          widget.value ? HapticService.light() : HapticService.selection();
        }
        widget.onChanged(!widget.value);
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 100),
        opacity: _pressed ? 0.5 : 1.0,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.value ? accentColor : Colors.transparent,
                  border: Border.all(
                    color: widget.value
                        ? accentColor
                        : (isDark
                            ? AppTheme.kLuminaMutedDark.withOpacity(0.45)
                            : AppTheme.kLuminaMuted.withOpacity(0.45)),
                    width: 2,
                  ),
                ),
                child: widget.value
                    ? const Icon(
                        CupertinoIcons.check_mark,
                        color: AppTheme.kLuminaBlack,
                        size: 17,
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: widget.value
                        ? (isDark
                            ? AppTheme.kLuminaTextDark.withOpacity(0.62)
                            : AppTheme.kLuminaText.withOpacity(0.62))
                        : (isDark ? AppTheme.kLuminaTextDark : AppTheme.kLuminaText),
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
