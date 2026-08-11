import 'package:flutter/material.dart';
import '../services/haptic_service.dart';

/// 教材下拉选择组件
///
/// 多邻国风格：点击展开列表，选中后收起显示当前教材。
/// 液态玻璃磨砂半透明质感。
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

class _TextbookDropdownState extends State<TextbookDropdown>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _animation;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _animation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    if (_expanded) {
      _animController.forward();
    } else {
      _animController.reverse();
    }
  }

  void _select(String value) {
    if (value == widget.value) {
      _toggle();
      return;
    }
    HapticService.selection();
    widget.onChanged(value);
    _toggle();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentLabel = widget.options
        .firstWhere((o) => o.value == widget.value,
            orElse: () => widget.options.first)
        .label;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 折叠状态：当前选中教材 + 下拉箭头
        GestureDetector(
          onTap: _toggle,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutBack,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withOpacity(0.8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  Icons.menu_book_rounded,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    currentLabel,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                AnimatedRotation(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutBack,
                  turns: _expanded ? 0.5 : 0.0,
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 22,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
        // 展开的选项列表
        SizeTransition(
          sizeFactor: _animation,
          axisAlignment: 1.0,
          child: Container(
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.15),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: widget.options.map((opt) {
                  final selected = opt.value == widget.value;
                  return GestureDetector(
                    onTap: () => _select(opt.value),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      color: selected
                          ? theme.colorScheme.primary.withOpacity(0.12)
                          : Colors.transparent,
                      child: Row(
                        children: [
                          Icon(
                            selected
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked,
                            size: 20,
                            color: selected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface.withOpacity(0.4),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              opt.label,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: selected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
