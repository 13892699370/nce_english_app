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
import '../widgets/celebration_dialog.dart';
import '../widgets/day_completion_overlay.dart';
import '../widgets/theme_toggle_button.dart';

/// 新概念学习打卡页（iOS 原生风格）
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

    final dayLessons = _dayLessons;
    if (dayLessons.isEmpty) {
      _isSaving = false;
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('打卡完成，进入第$_currentDay天'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.kSystemBlue,
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
    final textbooks = TextbookRegistry.all
        .map((t) => TextbookDropdownOption(value: t.id, label: t.name))
        .toList();
    final totalDays = _totalDays();

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('打卡'),
        trailing: ThemeToggleButton(),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextbookDropdown(
                        options: textbooks,
                        value: TextbookService.instance.currentId,
                        onChanged: _onTextbookChanged,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _today,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: theme.colorScheme.onSurface.withOpacity(0.4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: totalDays,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final day = i + 1;
                final selected = day == _currentDay;
                return GestureDetector(
                  onTap: () => _onDayChanged(day),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: selected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        '第$day天',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                          color: selected
                              ? Colors.white
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: _loading
                ? const Center(child: CupertinoActivityIndicator())
                : _buildTaskArea(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskArea(ThemeData theme) {
    final dayLessons = _dayLessons;
    if (dayLessons.isEmpty) {
      return Center(
        child: Text(
          '暂无课程数据',
          style: TextStyle(
            color: theme.colorScheme.onSurface.withOpacity(0.4),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      children: [
        LiquidGlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$_currentDay',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '第$_currentDay天',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${TextbookService.instance.current.name} · ${dayLessons.map((l) => 'L${l.number}（${l.isNew ? "新课" : "复习"}）').join(' + ')}',
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...dayLessons.map((l) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
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
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),

        _buildSection(
          theme: theme,
          icon: CupertinoIcons.headphones,
          title: '预习任务',
          labels: kPreviewTaskLabels,
          states: _preview,
          section: 0,
        ),
        _buildSection(
          theme: theme,
          icon: CupertinoIcons.film,
          title: '正式学习',
          labels: kFormalTaskLabels,
          states: _formal,
          section: 1,
          extra: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: CupertinoTextField(
              controller: _imitationCtrl,
              maxLines: 3,
              placeholder: '在此仿写本课句型句子…',
              padding: const EdgeInsets.all(14),
              onChanged: (_) => _debouncedSave(),
            ),
          ),
        ),
        _buildSection(
          theme: theme,
          icon: CupertinoIcons.arrow_2_circlepath,
          title: '复习任务',
          labels: kReviewTaskLabels,
          states: _review,
          section: 2,
        ),

        const SizedBox(height: 8),
        Center(
          child: Text(
            _isSaving ? '保存中…' : '已自动保存',
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withOpacity(0.35),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSection({
    required ThemeData theme,
    required IconData icon,
    required String title,
    required List<String> labels,
    required List<bool> states,
    required int section,
    Widget? extra,
  }) {
    final doneCount = states.where((e) => e).length;
    return LiquidGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: doneCount == labels.length
                      ? AppTheme.kSystemGreen.withOpacity(0.12)
                      : theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$doneCount/${labels.length}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: doneCount == labels.length
                        ? AppTheme.kSystemGreen
                        : theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (int i = 0; i < labels.length; i++)
            TaskCheckbox(
              label: labels[i],
              value: states[i],
              onChanged: (v) => _onTaskToggle(section, i, v),
            ),
          if (extra != null) extra,
        ],
      ),
    );
  }
}
