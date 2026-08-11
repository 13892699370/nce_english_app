import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'liquid_glass_card.dart';

/// 缩小版 Cupertino 圆形滚轮选天器。
class DayWheelPicker extends StatelessWidget {
  final int currentDay;
  final int totalDays;
  final ValueChanged<int> onChanged;

  const DayWheelPicker({
    super.key,
    required this.currentDay,
    required this.totalDays,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LiquidGlassCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      borderRadius: 18,
      child: Row(
        children: [
          Icon(
            CupertinoIcons.calendar,
            size: 17,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 6),
          Text(
            '第$currentDay天',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const Spacer(),
          SizedBox(
            width: 86,
            height: 54,
            child: CupertinoPicker(
              scrollController: FixedExtentScrollController(
                initialItem: (currentDay - 1).clamp(0, totalDays - 1),
              ),
              itemExtent: 28,
              magnification: 1.08,
              squeeze: 1.12,
              useMagnifier: true,
              selectionOverlay: CupertinoPickerDefaultSelectionOverlay(
                background: theme.colorScheme.primary.withOpacity(0.08),
              ),
              onSelectedItemChanged: (i) => onChanged(i + 1),
              children: List.generate(
                totalDays,
                (i) => Center(
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
