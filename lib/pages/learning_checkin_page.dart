import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../data/textbook_registry.dart';
import '../data/lesson.dart';
import '../models/lesson_checkin.dart';
import '../services/storage_service.dart';
import '../services/textbook_service.dart';
import '../services/achievement_service.dart';
import '../services/haptic_service.dart';
import '../theme/app_theme.dart';
import '../utils/date_util.dart';
import '../widgets/liquid_glass_card.dart';
import '../widgets/textbook_dropdown.dart';
import '../widgets/task_checkbox.dart';
import '../widgets/duolingo_button.dart';
import '../widgets/celebration_dialog.dart';
import '../widgets/day_completion_overlay.dart';
import '../widgets/theme_toggle_button.dart';

/// 新概念学习打卡页（Duolingo Vibrant 风格）
/// 灵感来源：Duolingo（鲜艳色块、3D 立体按钮、游戏化）
class LearningCheckinPage extends StatefulWidget {
  const LearningCheckinPage({super.key});

  @override
  State<LearningCheckinPage> createState() => _LearningCheckinPageState();
}

class _LearningCheckinPageState extends State<LearningCheckinPage> {
  late List<Lesson> _lessons;
  int _currentDay = 1;
  String _today = '';

  List<bool> _preview = [];
  List<bool> _formal = [];
  List<bool> _review = [];
  final TextEditingController _imitationCtrl = TextEditingController();
  bool _loading = true;

  Timer? _debounceTimer;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _today = DateUtil.today();
    _initDay();
    TextbookService.instance.addListener(_onTextbookNotification);
  }

  @override
  void dispose() {
    TextbookService.instance.removeListener(_onTextbookNotification);
    _imitationCtrl.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _initDay() {
    final tbId = TextbookService.instance.currentId;
    _currentDay = StorageService.instance.currentDayOf(tbId);
    _reloadLessons();
    _loadCheckin();
  }

  void _onTextbookNotification() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _currentDay = StorageService.instance
            .currentDayOf(TextbookService.instance.currentId);
        _loading = true;
      });
      _reloadLessons();
      _loadCheckin();
    });
  }

  void _reloadLessons() {
    _lessons = TextbookRegistry.lessonsOf(
        TextbookService.instance.currentId);
    final totalDays = _totalDays();
    if (_currentDay > totalDays) {
      _currentDay = totalDays;
    }
  }

  int _totalDays() {
    final info = TextbookRegistry.byId(TextbookService.instance.currentId);
    return info.totalDays;
  }

  List<Lesson> get _dayLessons =>
      _lessons.where((l) => l.dayNumber == _currentDay).toList();

  void _loadCheckin() {
    if (_lessons.isEmpty) {
      setState(() => _loading = false);
      return;
    }
    final existing = StorageService.instance.getCheckin(
      TextbookService.instance.currentId,
      _today,
      _currentDay,
    );
    _preview = existing?.previewTasks ??
        List<bool>.filled(kPreviewTaskLabels.length, false);
    _formal = existing?.formalTasks ??
        List<bool>.filled(kFormalTaskLabels.length, false);
    _review = existing?.reviewTasks ??
        List<bool>.filled(kReviewTaskLabels.length, false);
    _imitationCtrl.text = existing?.imitationSentence ?? '';
    setState(() => _loading = false);
  }

  Future<void> _onTextbookChanged(String id) async {
    await TextbookService.instance.select(id);
    setState(() {
      _currentDay = StorageService.instance.currentDayOf(id);
      _loading = true;
    });
    _reloadLessons();
    _loadCheckin();
  }

  void _debouncedSave() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _doSave();
    });
  }

  Future<void> _immediateSave() async {
    _debounceTimer?.cancel();
    await _doSave();
  }

  Future<void> _doSave() async {
    if (_isSaving) return;
    _isSaving = true;
    if (mounted) setState(() {});

    final dayLessons = _dayLessons;
    if (dayLessons.isEmpty) {
      _isSaving = false;
      if (mounted) setState(() {});
      return;
    }

    final createdAt = DateUtil.dateTime(DateTime.now());
    final checkin = LessonCheckin(
      textbook: TextbookService.instance.currentId,
      date: _today,
      dayNumber: _currentDay,
      lessonNumbers: dayLessons.map((l) => l.number).toList(),
      previewTasks: List<bool>.from(_preview),
      formalTasks: List<bool>.from(_formal),
      reviewTasks: List<bool>.from(_review),
      imitationSentence: _imitationCtrl.text.trim(),
      createdAt: createdAt,
    );
    await StorageService.instance.saveCheckin(checkin);

    await StorageService.instance.setCurrentDay(
        TextbookService.instance.currentId, _currentDay);

    final unlocked = await AchievementService.instance.checkAndUnlock();
    if (!mounted) {
      _isSaving = false;
      return;
    }
    if (unlocked.isNotEmpty) {
      for (final def in unlocked) {
        if (!mounted) break;
        await CelebrationDialog.show(context, def);
      }
    }

    if (checkin.isAllDone && _currentDay < _totalDays()) {
      _jumpToNextDay();
    }

    _isSaving = false;
    if (mounted) setState(() {});
  }

  void _jumpToNextDay() {
    HapticService.medium();
    Future.delayed(const Duration(milliseconds: 180), () async {
      if (!mounted) return;
      await DayCompletionOverlay.show(context, nextDay: _currentDay + 1);
      if (!mounted) return;
      setState(() {
        _currentDay += 1;
        _loading = true;
      });
      await StorageService.instance.setCurrentDay(
        TextbookService.instance.currentId,
        _currentDay,
      );
      _loadCheckin();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '打卡完成，进入第$_currentDay天',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              decoration: TextDecoration.none,
            ),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.kDuoGreen,
          duration: const Duration(seconds: 2),
        ),
      );
    });
  }

  void _onDayChanged(int day) {
    if (day == _currentDay) return;
    setState(() {
      _currentDay = day;
      _loading = true;
    });
    _loadCheckin();
    StorageService.instance.setCurrentDay(
        TextbookService.instance.currentId, day);
  }

  void _onTaskToggle(int section, int index, bool value) {
    setState(() {
      switch (section) {
        case 0:
          _preview[index] = value;
          break;
        case 1:
          _formal[index] = value;
          break;
        case 2:
          _review[index] = value;
          break;
      }
    });
    _debouncedSave();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textbooks = TextbookRegistry.all
        .map((t) => TextbookDropdownOption(value: t.id, label: t.name))
        .toList();
    final totalDays = _totalDays();
    final textColor = isDark ? AppTheme.kTextDark : AppTheme.kTextLight;
    final secondaryColor =
        isDark ? AppTheme.kSecondaryTextDark : AppTheme.kSecondaryTextLight;

    return CupertinoPageScaffold(
      backgroundColor: Colors.transparent,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: Colors.transparent,
        border: null,
        trailing: const ThemeToggleButton(),
      ),
      child: Material(
        color: Colors.transparent,
        child: Column(
          children: [
            // 1. 大标题 + 副标题
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '今日学习',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: textColor,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '第$_currentDay天 · ${TextbookService.instance.current.name}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: secondaryColor,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // 2. 教材下拉
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
              child: TextbookDropdown(
                options: textbooks,
                value: TextbookService.instance.currentId,
                onChanged: _onTextbookChanged,
              ),
            ),
            // 3. 天数 chips（水平滚动）
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: totalDays,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, i) {
                  final day = i + 1;
                  final selected = day == _currentDay;
                  return GestureDetector(
                    onTap: () => _onDayChanged(day),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      curve: Curves.easeOut,
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected
                            ? AppTheme.kDuoGreen
                            : (isDark
                                ? AppTheme.kCardDark
                                : AppTheme.kCardLight),
                        borderRadius: BorderRadius.circular(14),
                        border: selected
                            ? const Border(
                                bottom: BorderSide(
                                    color: AppTheme.kDuoGreenDark, width: 3),
                                top: BorderSide(
                                    color: AppTheme.kDuoGreen, width: 0),
                                left: BorderSide(
                                    color: AppTheme.kDuoGreen, width: 0),
                                right: BorderSide(
                                    color: AppTheme.kDuoGreen, width: 0),
                              )
                            : Border.all(
                                color: isDark
                                    ? AppTheme.kSeparatorDark
                                    : AppTheme.kSeparatorLight,
                                width: 1.5,
                              ),
                        boxShadow: selected
                            ? null
                            : [
                                BoxShadow(
                                  color: Colors.black
                                      .withOpacity(isDark ? 0.22 : 0.05),
                                  blurRadius: 8,
                                  spreadRadius: -3,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                      ),
                      child: Text(
                        '第$day天',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: selected
                              ? FontWeight.w800
                              : FontWeight.w600,
                          color: selected
                              ? Colors.white
                              : (isDark
                                  ? AppTheme.kSecondaryTextDark
                                  : AppTheme.kSecondaryTextLight),
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 18),
            // 4-8. 任务区
            Expanded(
              child: _loading
                  ? Center(
                      child: CupertinoActivityIndicator(
                        color: AppTheme.kDuoGreen,
                      ),
                    )
                  : _buildTaskArea(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskArea() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final secondaryColor = isDark
        ? AppTheme.kSecondaryTextDark
        : AppTheme.kSecondaryTextLight;
    final dayLessons = _dayLessons;

    if (dayLessons.isEmpty) {
      return Center(
        child: Text(
          '暂无课程数据',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: secondaryColor,
            decoration: TextDecoration.none,
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
      children: [
        // 4. 天信息卡
        _buildDayInfoCard(dayLessons),
        const SizedBox(height: 14),

        // 5. 任务区段
        _buildSection(
          icon: CupertinoIcons.book,
          title: '预习',
          labels: kPreviewTaskLabels,
          states: _preview,
          section: 0,
          color: AppTheme.kDuoBlue,
        ),
        const SizedBox(height: 14),
        _buildSection(
          icon: CupertinoIcons.play_circle_fill,
          title: '正式学习',
          labels: kFormalTaskLabels,
          states: _formal,
          section: 1,
          color: AppTheme.kDuoGreen,
        ),
        const SizedBox(height: 14),
        _buildSection(
          icon: CupertinoIcons.arrow_clockwise,
          title: '复习',
          labels: kReviewTaskLabels,
          states: _review,
          section: 2,
          color: AppTheme.kDuoOrange,
        ),

        // 6. 仿写句子
        const SizedBox(height: 14),
        _buildSentenceCard(isDark),

        // 7. 完成今日打卡
        const SizedBox(height: 22),
        Center(
          child: Opacity(
            opacity: 0.7,
            child: Text(
              '完成所有任务后自动跳转下一天',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: secondaryColor,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        DuolingoButton(
          label: '完成今日打卡',
          variant: DuolingoButtonVariant.primary,
          minHeight: 56,
          onPressed: _immediateSave,
        ),

        // 8. 自动保存指示
        const SizedBox(height: 14),
        Center(
          child: Opacity(
            opacity: 0.6,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _isSaving
                        ? AppTheme.kDuoOrange
                        : AppTheme.kDuoGreen,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _isSaving ? '保存中…' : '已自动保存',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: secondaryColor,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDayInfoCard(List<Lesson> dayLessons) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? AppTheme.kTextDark : AppTheme.kTextLight;
    final secondaryColor = isDark
        ? AppTheme.kSecondaryTextDark
        : AppTheme.kSecondaryTextLight;

    return LiquidGlassCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 左侧：64×64 大号天数方块（视觉焦点）
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppTheme.kDuoGreen.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '$_currentDay',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.kDuoGreen,
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(width: 2),
                Text(
                  '天',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: secondaryColor,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // 右侧：共X节课 + 课程列表
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '共 ${dayLessons.length} 节课',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: secondaryColor,
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 12),
                for (int i = 0; i < dayLessons.length; i++)
                  Padding(
                    padding: EdgeInsets.only(
                        bottom: i == dayLessons.length - 1 ? 0 : 10),
                    child: Row(
                      children: [
                        _lessonTag(dayLessons[i], isDark),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'L${dayLessons[i].number} · ${dayLessons[i].title}',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: textColor,
                              decoration: TextDecoration.none,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _lessonTag(Lesson l, bool isDark) {
    final isNew = l.isNew;
    final tagColor = isNew
        ? AppTheme.kDuoGreen
        : (isDark
            ? AppTheme.kSecondaryTextDark
            : AppTheme.kSecondaryTextLight);
    final bg = tagColor.withOpacity(0.12);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        isNew ? '新课' : '复习',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: tagColor,
          decoration: TextDecoration.none,
        ),
      ),
    );
  }

  Widget _buildSentenceCard(bool isDark) {
    final textColor = isDark ? AppTheme.kTextDark : AppTheme.kTextLight;
    final secondaryColor = isDark
        ? AppTheme.kSecondaryTextDark
        : AppTheme.kSecondaryTextLight;
    final fieldBg =
        isDark ? AppTheme.kBgSecondaryDark : AppTheme.kBgSecondaryLight;
    return LiquidGlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '仿写句子',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: textColor,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '仿写本课句型，巩固表达',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: secondaryColor,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: CupertinoTextField(
              controller: _imitationCtrl,
              maxLines: null,
              minLines: null,
              expands: true,
              placeholder: '在此仿写本课句型句子…',
              padding: const EdgeInsets.all(14),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: textColor,
                decoration: TextDecoration.none,
              ),
              decoration: BoxDecoration(
                color: fieldBg,
                borderRadius: BorderRadius.circular(16),
              ),
              onChanged: (_) => _debouncedSave(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required List<String> labels,
    required List<bool> states,
    required int section,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? AppTheme.kTextDark : AppTheme.kTextLight;
    final secondaryColor = isDark
        ? AppTheme.kSecondaryTextDark
        : AppTheme.kSecondaryTextLight;

    final doneCount = states.where((e) => e).length;
    final allDone = doneCount == labels.length;
    final countColor = allDone ? AppTheme.kDuoGreen : secondaryColor;

    return LiquidGlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                  decoration: TextDecoration.none,
                ),
              ),
              const Spacer(),
              Text(
                '$doneCount/${labels.length}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: countColor,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (int i = 0; i < labels.length; i++)
            Padding(
              padding: EdgeInsets.only(
                  bottom: i == labels.length - 1 ? 0 : 4),
              child: TaskCheckbox(
                label: labels[i],
                value: states[i],
                onChanged: (v) => _onTaskToggle(section, i, v),
              ),
            ),
        ],
      ),
    );
  }
}
