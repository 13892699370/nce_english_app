import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/haptic_service.dart';

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
    final accentColor =
        isDark ? AppTheme.kLuminaLime : AppTheme.kLuminaBlack;
    final thumbColor =
        isDark ? AppTheme.kLuminaSurfaceDark : AppTheme.kLuminaSurface;
    final unselectedTextColor =
        isDark ? AppTheme.kLuminaMutedDark : AppTheme.kLuminaMuted;

    final Map<T, Widget> segments = {};
    for (final opt in widget.options) {
      final selected = opt.value == widget.value;
      segments[opt.value] = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (opt.icon != null) ...[
            Icon(
              opt.icon,
              size: 16,
              color: selected ? accentColor : unselectedTextColor,
            ),
            const SizedBox(width: 6),
          ],
          Text(
            opt.label,
            style: TextStyle(
              color: selected ? accentColor : unselectedTextColor,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ],
      );
    }

    return CupertinoSlidingSegmentedControl<T>(
      groupValue: widget.value,
      thumbColor: thumbColor,
      padding: const EdgeInsets.all(2),
      children: segments,
      onValueChanged: (T? newValue) {
        if (newValue == null) return;
        if (newValue != widget.value) {
          if (widget.enableHaptic) HapticService.selection();
          widget.onChanged(newValue);
        }
      },
    );
  }
}
