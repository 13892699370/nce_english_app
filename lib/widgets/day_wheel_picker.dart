import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'liquid_glass_card.dart';
import '../theme/app_theme.dart';

/// 缩小版 Cupertino 圆形滚轮选天器。
/// 小卡片 + "第N天" 文本 + 滚轮。
class DayWheelPicker extends StatefulWidget {
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
  State<DayWheelPicker> createState() => _DayWheelPickerState();
}

class _DayWheelPickerState extends State<DayWheelPicker> {
  late FixedExtentScrollController _controller;

  int get _safeIndex {
    if (widget.totalDays <= 0) return 0;
    return (widget.currentDay - 1).clamp(0, widget.totalDays - 1);
  }

  @override
  void initState() {
    super.initState();
    _controller = FixedExtentScrollController(initialItem: _safeIndex);
  }

  @override
  void didUpdateWidget(covariant DayWheelPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    final shouldReposition =
        oldWidget.currentDay != widget.currentDay ||
            oldWidget.totalDays != widget.totalDays;
    if (!shouldReposition) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_controller.hasClients) return;
      _controller.animateToItem(
        _safeIndex,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LiquidGlassCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      borderRadius: 14,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            CupertinoIcons.calendar,
            size: 17,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 6),
          Text(
            '第${widget.currentDay}天',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 100,
            height: 50,
            child: CupertinoPicker(
              scrollController: _controller,
              itemExtent: 28,
              magnification: 1.08,
              squeeze: 1.12,
              useMagnifier: true,
              selectionOverlay: CupertinoPickerDefaultSelectionOverlay(
                background: AppTheme.kIndigo.withOpacity(0.08),
              ),
              onSelectedItemChanged: (i) => widget.onChanged(i + 1),
              children: List.generate(
                widget.totalDays,
                (i) => Center(
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
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
