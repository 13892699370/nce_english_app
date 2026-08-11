import 'package:flutter/material.dart';
import '../services/haptic_service.dart';

/// 胶囊选择组件（教材下拉选择 / 通用分段选择）
///
/// 多邻国风格：大圆角、柔和配色、按压挤压回弹、统一触觉反馈。
/// 双端表现一致。
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
  int? _pressedIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.06)
            : Colors.black.withOpacity(0.04),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          for (int i = 0; i < widget.options.length; i++)
            Expanded(child: _buildSegment(i, isDark, theme)),
        ],
      ),
    );
  }

  Widget _buildSegment(int i, bool isDark, ThemeData theme) {
    final opt = widget.options[i];
    final selected = opt.value == widget.value;
    final pressed = _pressedIndex == i;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressedIndex = i),
      onTapUp: (_) {
        setState(() => _pressedIndex = null);
        if (!selected) {
          if (widget.enableHaptic) HapticService.selection();
          widget.onChanged(opt.value);
        }
      },
      onTapCancel: () => setState(() => _pressedIndex = null),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutBack,
        transform: Matrix4.identity()..scale(pressed ? 0.95 : 1.0),
        transformAlignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF58CC02)
              : (isDark ? Colors.white.withOpacity(0.04) : Colors.transparent),
          borderRadius: BorderRadius.circular(24),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: const Color(0xFF58CC02).withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (opt.icon != null) ...[
              Icon(opt.icon,
                  size: 16,
                  color: selected ? Colors.white : theme.colorScheme.onSurface.withOpacity(0.7)),
              const SizedBox(width: 6),
            ],
            Text(
              opt.label,
              style: TextStyle(
                color: selected
                    ? Colors.white
                    : theme.colorScheme.onSurface.withOpacity(0.7),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
