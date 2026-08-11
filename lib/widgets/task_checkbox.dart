import 'package:flutter/material.dart';
import '../services/haptic_service.dart';

/// 任务勾选项（可勾选），多邻国风格按压反馈 + 统一触觉
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
    final theme = Theme.of(context);
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutBack,
        transform: Matrix4.identity()..scale(_pressed ? 0.97 : 1.0),
        transformAlignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: widget.value
              ? const Color(0xFF58CC02).withOpacity(0.10)
              : theme.colorScheme.surface.withOpacity(0.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: widget.value
                ? const Color(0xFF58CC02)
                : theme.colorScheme.outline.withOpacity(0.2),
            width: widget.value ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutBack,
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: widget.value ? const Color(0xFF58CC02) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: widget.value
                      ? const Color(0xFF58CC02)
                      : theme.colorScheme.outline.withOpacity(0.4),
                  width: 2,
                ),
              ),
              child: widget.value
                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: widget.value
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurface.withOpacity(0.85),
                  decoration: widget.value ? TextDecoration.none : TextDecoration.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
