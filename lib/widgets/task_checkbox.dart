import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/haptic_service.dart';

/// 简洁复选框：24×24 圆形
/// 未选 = 透明 + 灰边；选中 = Indigo 填充 + 白色对勾
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
    const accentColor = AppTheme.kIndigo;
    final borderColor = isDark
        ? AppTheme.kSecondaryTextDark.withOpacity(0.5)
        : AppTheme.kSecondaryTextLight.withOpacity(0.5);
    final labelColor = isDark ? AppTheme.kTextDark : AppTheme.kTextLight;
    final doneLabelColor = isDark
        ? AppTheme.kSecondaryTextDark
        : AppTheme.kSecondaryTextLight;

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
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.value ? accentColor : Colors.transparent,
                  border: Border.all(
                    color: widget.value ? accentColor : borderColor,
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
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: widget.value ? doneLabelColor : labelColor,
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
