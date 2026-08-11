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
    final accentColor =
        isDark ? AppTheme.kSystemBlueDark : AppTheme.kSystemBlue;

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
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.value ? accentColor : Colors.transparent,
                  border: Border.all(
                    color: widget.value
                        ? accentColor
                        : const Color(0xFF8E8E93),
                    width: 2,
                  ),
                ),
                child: widget.value
                    ? const Icon(
                        CupertinoIcons.check_mark,
                        color: Colors.white,
                        size: 16,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: widget.value
                        ? (isDark
                            ? Colors.white.withOpacity(0.6)
                            : Colors.black.withOpacity(0.6))
                        : (isDark ? Colors.white : Colors.black),
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
