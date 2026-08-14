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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppTheme.kTextDark : AppTheme.kTextLight;
    final secondaryColor = AppTheme.kSecondaryTextLight;
    final accent = isDark ? AppTheme.kIndigoLight : AppTheme.kIndigo;

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
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
          children: [
            // 1. 大标题
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 16),
              child: Text(
                '学习日历',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  color: textColor,
                  decoration: TextDecoration.none,
                ),
              ),
            ),

            // 2. 教材下拉
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: TextbookDropdown(
                options: textbooks,
                value: _textbookId,
                onChanged: (id) async {
                  await TextbookService.instance.select(id);
                  setState(() => _textbookId = id);
                },
              ),
            ),

            // 3. 日历卡
            LiquidGlassCard(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              child: _buildCalendar(
                checkinMap,
                today,
                textColor,
                secondaryColor,
                accent,
              ),
            ),

            // 4. 图例
            _buildLegend(secondaryColor, accent),
            const SizedBox(height: 16),

            // 5. 月度统计卡
            _buildStats(checkinMap, textColor, secondaryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar(
    Map<String, LessonCheckin> checkinMap,
    String today,
    Color textColor,
    Color secondaryColor,
    Color accent,
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
        // 月份头 + 翻页箭头
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: _prevMonth,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  CupertinoIcons.chevron_left,
                  size: 20,
                  color: accent,
                ),
              ),
            ),
            Text(
              monthLabel,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: textColor,
                decoration: TextDecoration.none,
              ),
            ),
            GestureDetector(
              onTap: _nextMonth,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  CupertinoIcons.chevron_right,
                  size: 20,
                  color: accent,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        // 星期标签
        Row(
          children: weekLabels
              .map((w) => Expanded(
                    child: Center(
                      child: Text(
                        w,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: secondaryColor,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 10),
        // 日期网格
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
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
              child: _buildDayCell(
                day: day,
                isToday: isToday,
                allDone: allDone,
                partial: partial,
                textColor: textColor,
                secondaryColor: secondaryColor,
                accent: accent,
              ),
            );
          },
        ),
      ],
    );
  }

  /// 单个日期格：今日/全部完成/部分完成/无打卡
  Widget _buildDayCell({
    required int day,
    required bool isToday,
    required bool allDone,
    required bool partial,
    required Color textColor,
    required Color secondaryColor,
    required Color accent,
  }) {
    final String dayText = '$day';
    final TextStyle dayStyle = TextStyle(
      fontSize: 15,
      fontWeight: isToday || allDone || partial
          ? FontWeight.w600
          : FontWeight.w400,
      decoration: TextDecoration.none,
    );

    if (allDone) {
      return Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.kSuccess,
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              dayText,
              style: dayStyle.copyWith(color: Colors.white),
            ),
            Container(
              width: 4,
              height: 4,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.85),
              ),
            ),
          ],
        ),
      );
    }

    if (partial) {
      return Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.kWarning,
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              dayText,
              style: dayStyle.copyWith(color: Colors.white),
            ),
            Container(
              width: 4,
              height: 4,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.85),
              ),
            ),
          ],
        ),
      );
    }

    if (isToday) {
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: accent.withOpacity(0.12),
          border: Border.all(color: accent, width: 1.5),
        ),
        alignment: Alignment.center,
        child: Text(
          dayText,
          style: dayStyle.copyWith(color: accent),
        ),
      );
    }

    return Container(
      alignment: Alignment.center,
      child: Text(
        dayText,
        style: dayStyle.copyWith(color: secondaryColor),
      ),
    );
  }

  /// 图例：已全部完成 / 部分完成 / 今天
  Widget _buildLegend(Color secondaryColor, Color accent) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendDot(AppTheme.kSuccess, '已全部完成', secondaryColor),
        const SizedBox(width: 20),
        _legendDot(AppTheme.kWarning, '部分完成', secondaryColor),
        const SizedBox(width: 20),
        _legendDot(accent, '今天', secondaryColor, isRing: true),
      ],
    );
  }

  Widget _legendDot(
    Color color,
    String label,
    Color secondaryColor, {
    bool isRing = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isRing ? color.withOpacity(0.12) : color,
            border: isRing ? Border.all(color: color, width: 1.5) : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: secondaryColor,
            decoration: TextDecoration.none,
          ),
        ),
      ],
    );
  }

  /// 月度统计卡：总打卡天数 / 全部完成天数 / 部分完成天数
  Widget _buildStats(
    Map<String, LessonCheckin> checkinMap,
    Color textColor,
    Color secondaryColor,
  ) {
    final total = checkinMap.length;
    final allDone = checkinMap.values.where((c) => c.isAllDone).length;
    final partial = total - allDone;

    return LiquidGlassCard(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      child: Row(
        children: [
          Expanded(
            child: _statItem(
              '$total',
              '总打卡天数',
              textColor,
              secondaryColor,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: AppTheme.kSeparatorLight,
          ),
          Expanded(
            child: _statItem(
              '$allDone',
              '全部完成天数',
              textColor,
              secondaryColor,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: AppTheme.kSeparatorLight,
          ),
          Expanded(
            child: _statItem(
              '$partial',
              '部分完成天数',
              textColor,
              secondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem(
    String value,
    String label,
    Color textColor,
    Color secondaryColor,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: textColor,
            decoration: TextDecoration.none,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: secondaryColor,
            decoration: TextDecoration.none,
          ),
        ),
      ],
    );
  }

  /// 日期详情底部弹层：干净的 ModalBottomSheet，无玻璃层
  void _showCheckinDetail(LessonCheckin checkin) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppTheme.kTextDark : AppTheme.kTextLight;
    final secondaryColor = AppTheme.kSecondaryTextLight;
    final accent = isDark ? AppTheme.kIndigoLight : AppTheme.kIndigo;
    final sheetBg = isDark ? AppTheme.kCardDark : AppTheme.kCardLight;
    final lessons = TextbookRegistry.lessonsOfDay(_textbookId, checkin.dayNumber);
    final textbookName = TextbookRegistry.byId(_textbookId).name;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: sheetBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 5,
              decoration: BoxDecoration(
                color: secondaryColor.withOpacity(0.25),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${checkin.dayNumber}',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: accent,
                        decoration: TextDecoration.none,
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
                            color: textColor,
                            decoration: TextDecoration.none,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          checkin.date,
                          style: TextStyle(
                            fontSize: 13,
                            color: secondaryColor,
                            decoration: TextDecoration.none,
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
                              ? AppTheme.kSuccess
                              : AppTheme.kWarning)
                          .withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${checkin.doneCount}/${checkin.totalTaskCount}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: checkin.isAllDone
                            ? AppTheme.kSuccess
                            : AppTheme.kWarning,
                        decoration: TextDecoration.none,
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
                        color: secondaryColor,
                        decoration: TextDecoration.none,
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
                                      ? accent.withOpacity(0.12)
                                      : AppTheme.kWarning.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'L${l.number} · ${l.isNew ? "新课" : "复习"}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: l.isNew
                                        ? accent
                                        : AppTheme.kWarning,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  l.title,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: textColor.withOpacity(0.7),
                                    decoration: TextDecoration.none,
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
                    '预习任务',
                    kPreviewTaskLabels,
                    checkin.previewTasks,
                    textColor,
                    secondaryColor,
                  ),
                  const SizedBox(height: 12),
                  _buildTaskList(
                    '正式学习',
                    kFormalTaskLabels,
                    checkin.formalTasks,
                    textColor,
                    secondaryColor,
                  ),
                  if (checkin.imitationSentence.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      '仿写句子',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: secondaryColor,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        checkin.imitationSentence,
                        style: TextStyle(
                          fontSize: 15,
                          color: textColor,
                          height: 1.5,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  _buildTaskList(
                    '复习任务',
                    kReviewTaskLabels,
                    checkin.reviewTasks,
                    textColor,
                    secondaryColor,
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
    String title,
    List<String> labels,
    List<bool> states,
    Color textColor,
    Color secondaryColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: secondaryColor,
            decoration: TextDecoration.none,
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
                      ? AppTheme.kSuccess
                      : secondaryColor.withOpacity(0.4),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    labels[i],
                    style: TextStyle(
                      fontSize: 14,
                      color: states[i]
                          ? textColor
                          : textColor.withOpacity(0.4),
                      decoration: TextDecoration.none,
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
