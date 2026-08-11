import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../data/textbook_registry.dart';
import '../models/lesson_checkin.dart';
import '../services/storage_service.dart';
import '../services/textbook_service.dart';
import '../theme/app_theme.dart';
import '../utils/date_util.dart';
import '../widgets/liquid_glass_card.dart';
import '../widgets/textbook_dropdown.dart';
import '../widgets/theme_toggle_button.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late DateTime _focusedMonth;
  late String _textbookId;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month);
    _textbookId = TextbookService.instance.currentId;
    TextbookService.instance.addListener(_onTextbookChanged);
  }

  @override
  void dispose() {
    TextbookService.instance.removeListener(_onTextbookChanged);
    super.dispose();
  }

  void _onTextbookChanged() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _textbookId = TextbookService.instance.currentId;
      });
    });
  }

  Map<String, LessonCheckin> get _checkinMap {
    final map = <String, LessonCheckin>{};
    for (final c in StorageService.instance.checkinsOf(_textbookId)) {
      map[c.date] = c;
    }
    return map;
  }

  void _prevMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textbooks = TextbookRegistry.all
        .map((t) => TextbookDropdownOption(value: t.id, label: t.name))
        .toList();
    final checkinMap = _checkinMap;
    final today = DateUtil.today();

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Lumina Mono'),
        trailing: ThemeToggleButton(),
      ),
      child: Material(
        color: Colors.transparent,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 132),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 6, 4, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '学习日历',
                    style: theme.textTheme.displayMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '回看历史打卡，只读查看当天任务和仿写记录。',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.58),
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextbookDropdown(
                options: textbooks,
                value: _textbookId,
                onChanged: (id) async {
                  await TextbookService.instance.select(id);
                  setState(() => _textbookId = id);
                },
              ),
            ),
            LiquidGlassCard(
              child: _buildCalendar(theme, isDark, checkinMap, today),
            ),
            const SizedBox(height: 12),
            _buildLegend(theme, isDark),
            const SizedBox(height: 16),
            _buildStats(theme, isDark, checkinMap),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar(
    ThemeData theme,
    bool isDark,
    Map<String, LessonCheckin> checkinMap,
    String today,
  ) {
    const weekLabels = ['日', '一', '二', '三', '四', '五', '六'];
    final year = _focusedMonth.year;
    final month = _focusedMonth.month;
    final firstDay = DateTime(year, month, 1);
    final firstWeekday = firstDay.weekday % 7;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final monthLabel = '$year年$month月';

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: _prevMonth,
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  CupertinoIcons.chevron_left,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            Text(
              monthLabel,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            GestureDetector(
              onTap: _nextMonth,
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  CupertinoIcons.chevron_right,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: weekLabels
              .map((w) => Expanded(
                    child: Center(
                      child: Text(
                        w,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface.withOpacity(0.4),
                        ),
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            childAspectRatio: 1,
          ),
          itemCount: firstWeekday + daysInMonth,
          itemBuilder: (context, index) {
            if (index < firstWeekday) {
              return const SizedBox.shrink();
            }
            final day = index - firstWeekday + 1;
            final dateStr = DateUtil.date(DateTime(year, month, day));
            final checkin = checkinMap[dateStr];
            final isToday = dateStr == today;
            final allDone = checkin?.isAllDone ?? false;
            final partial = checkin != null && !allDone;

            return GestureDetector(
              onTap: checkin != null
                  ? () => _showCheckinDetail(checkin)
                  : null,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isToday
                      ? theme.colorScheme.primary.withOpacity(0.12)
                      : (allDone
                          ? AppTheme.kSystemGreen.withOpacity(0.10)
                          : (partial
                              ? AppTheme.kSystemOrange.withOpacity(0.10)
                              : Colors.transparent)),
                  border: isToday
                      ? Border.all(
                          color: theme.colorScheme.primary, width: 1.5)
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$day',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                        color: isToday
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    if (allDone)
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(top: 2),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.kSystemGreen,
                        ),
                      )
                    else if (partial)
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(top: 2),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.kSystemOrange,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLegend(ThemeData theme, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendDot(theme, AppTheme.kSystemGreen, '全部完成'),
        const SizedBox(width: 16),
        _legendDot(theme, AppTheme.kSystemOrange, '部分完成'),
        const SizedBox(width: 16),
        _legendDot(theme, const Color(0xFF8E8E93), '未打卡'),
      ],
    );
  }

  Widget _legendDot(ThemeData theme, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildStats(
    ThemeData theme,
    bool isDark,
    Map<String, LessonCheckin> checkinMap,
  ) {
    final total = checkinMap.length;
    final allDone = checkinMap.values.where((c) => c.isAllDone).length;
    final partial = total - allDone;

    return LiquidGlassCard(
      child: Row(
        children: [
          Expanded(
            child: _statItem(
              theme,
              '$total',
              '总打卡',
              AppTheme.kSystemBlue,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: theme.colorScheme.outline.withOpacity(0.12),
          ),
          Expanded(
            child: _statItem(
              theme,
              '$allDone',
              '全部完成',
              AppTheme.kSystemGreen,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: theme.colorScheme.outline.withOpacity(0.12),
          ),
          Expanded(
            child: _statItem(
              theme,
              '$partial',
              '部分完成',
              AppTheme.kSystemOrange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem(
    ThemeData theme,
    String value,
    String label,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
      ],
    );
  }

  void _showCheckinDetail(LessonCheckin checkin) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final lessons = TextbookRegistry.lessonsOfDay(_textbookId, checkin.dayNumber);
    final textbookName = TextbookRegistry.byId(_textbookId).name;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: isDark ? AppTheme.kCardBgDark : AppTheme.kCardBgLight,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 5,
              decoration: BoxDecoration(
                color: theme.colorScheme.outline.withOpacity(0.25),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: (checkin.isAllDone
                              ? AppTheme.kSystemGreen
                              : AppTheme.kSystemOrange)
                          .withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${checkin.dayNumber}',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: checkin.isAllDone
                            ? AppTheme.kSystemGreen
                            : AppTheme.kSystemOrange,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '第${checkin.dayNumber}天 · $textbookName',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          checkin.date,
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: (checkin.isAllDone
                              ? AppTheme.kSystemGreen
                              : AppTheme.kSystemOrange)
                          .withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${checkin.doneCount}/${checkin.totalTaskCount}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: checkin.isAllDone
                            ? AppTheme.kSystemGreen
                            : AppTheme.kSystemOrange,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                children: [
                  if (lessons.isNotEmpty) ...[
                    Text(
                      '本日课程',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...lessons.map((l) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: l.isNew
                                      ? AppTheme.kSystemTeal.withOpacity(0.12)
                                      : AppTheme.kSystemOrange.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'L${l.number} · ${l.isNew ? "新课" : "复习"}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: l.isNew
                                        ? AppTheme.kSystemTeal
                                        : AppTheme.kSystemOrange,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  l.title,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.7),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        )),
                    const SizedBox(height: 16),
                  ],
                  _buildTaskList(
                    theme,
                    '预习任务',
                    kPreviewTaskLabels,
                    checkin.previewTasks,
                  ),
                  const SizedBox(height: 12),
                  _buildTaskList(
                    theme,
                    '正式学习',
                    kFormalTaskLabels,
                    checkin.formalTasks,
                  ),
                  if (checkin.imitationSentence.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      '仿写句子',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        checkin.imitationSentence,
                        style: TextStyle(
                          fontSize: 15,
                          color: theme.colorScheme.onSurface,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  _buildTaskList(
                    theme,
                    '复习任务',
                    kReviewTaskLabels,
                    checkin.reviewTasks,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskList(
    ThemeData theme,
    String title,
    List<String> labels,
    List<bool> states,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 6),
        for (int i = 0; i < labels.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                Icon(
                  states[i]
                      ? CupertinoIcons.checkmark_circle_fill
                      : CupertinoIcons.circle,
                  size: 18,
                  color: states[i]
                      ? AppTheme.kSystemGreen
                      : const Color(0xFF8E8E93).withOpacity(0.4),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    labels[i],
                    style: TextStyle(
                      fontSize: 14,
                      color: states[i]
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurface.withOpacity(0.4),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
