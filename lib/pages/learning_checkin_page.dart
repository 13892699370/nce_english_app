import 'dart:async';

import 'package:flutter/material.dart';
import '../data/textbook_registry.dart';
import '../data/lesson.dart';
import '../models/lesson_checkin.dart';
import '../services/storage_service.dart';
import '../services/textbook_service.dart';
import '../services/achievement_service.dart';
import '../services/haptic_service.dart';
import '../utils/date_util.dart';
import '../widgets/liquid_glass_card.dart';
import '../widgets/textbook_dropdown.dart';
import '../widgets/task_checkbox.dart';
import '../widgets/celebration_dialog.dart';
import '../widgets/day_completion_overlay.dart';

/// 新概念学习打卡页
///
/// 天数标识：第X天，每天绑定 2 节课（单数新课 + 双数复习课）。
/// 勾选/取消任务自动实时保存（防抖 500ms），完成当天全部任务自动跳转下一天。
class LearningCheckinPage extends StatefulWidget {
  const LearningCheckinPage({super.key});

  @override
  State<LearningCheckinPage> createState() => _LearningCheckinPageState();
}

class _LearningCheckinPageState extends State<LearningCheckinPage> {
  late List<Lesson> _lessons;
  int _currentDay = 1;
  String _today = '';

  // 编辑缓冲
  List<bool> _preview = [];
  List<bool> _formal = [];
  List<bool> _review = [];
  final TextEditingController _imitationCtrl = TextEditingController();
  bool _loading = true;

  // 防抖
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

  /// 初始化当前天数（从持久化读取，默认第1天）
  void _initDay() {
    final tbId = TextbookService.instance.currentId;
    _currentDay = StorageService.instance.currentDayOf(tbId);
    _reloadLessons();
    _loadCheckin();
  }

  /// 监听教材切换：刷新课程、重置天数、清空状态
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

  /// 获取当前天的课程列表
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

  /// 防抖保存：勾选/取消后延迟 500ms 写入
  void _debouncedSave() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _doSave();
    });
  }

  /// 立即保存（用于切换天数/离开页面时）
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

    // 同步更新当前教材的学习天数
    await StorageService.instance.setCurrentDay(
        TextbookService.instance.currentId, _currentDay);

    // 成就检测
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

    // 如果当天全部完成，自动跳转下一天
    if (checkin.isAllDone && _currentDay < _totalDays()) {
      _jumpToNextDay();
    }

    _isSaving = false;
  }

  /// 跳转到下一天
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
          content: Text('🌟 打卡完成，进入第$_currentDay天！'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF58CC02),
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
    // 仅持久化当前天数，不触发 _doSave 以避免切换到已完成天时误触自动跳转
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

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 顶部：教材下拉 + 今日日期
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Text('📚 学习打卡',
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.w800)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '今日 $_today',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextbookDropdown(
                    options: textbooks,
                    value: TextbookService.instance.currentId,
                    onChanged: _onTextbookChanged,
                  ),
                ],
              ),
            ),

            // 天数选择
            SizedBox(
              height: 56,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: totalDays,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final day = i + 1;
                  final selected = day == _currentDay;
                  return GestureDetector(
                    onTap: () => _onDayChanged(day),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      curve: Curves.easeOutBack,
                      transform: Matrix4.identity()
                        ..scale(selected ? 1.0 : 0.94),
                      transformAlignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: selected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.surface.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: selected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outline.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '第$day天',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: selected
                                  ? Colors.white
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 4),

            // 任务区
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildTaskArea(theme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskArea(ThemeData theme) {
    final dayLessons = _dayLessons;
    if (dayLessons.isEmpty) {
      return const Center(child: Text('暂无课程数据'));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 40),
      children: [
        // 天数标题卡
        LiquidGlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$_currentDay',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
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
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${TextbookService.instance.current.name} · ${dayLessons.map((l) => 'L${l.number}（${l.isNew ? "新课" : "复习"}）').join(' + ')}',
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                theme.colorScheme.onSurface.withOpacity(0.55),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // 课程标题列表
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
                                ? const Color(0xFF1CB0F6).withOpacity(0.15)
                                : const Color(0xFFFFC800).withOpacity(0.18),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'L${l.number} · ${l.isNew ? "新课" : "复习"}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: l.isNew
                                  ? const Color(0xFF1CB0F6)
                                  : const Color(0xFFE0A800),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l.title,
                            style: TextStyle(
                              fontSize: 13,
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.7),
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

        // 预习
        _buildSection(
          theme: theme,
          icon: '🎧',
          title: '预习任务',
          labels: kPreviewTaskLabels,
          states: _preview,
          section: 0,
        ),

        // 正式学习
        _buildSection(
          theme: theme,
          icon: '🎬',
          title: '正式学习',
          labels: kFormalTaskLabels,
          states: _formal,
          section: 1,
          extra: Padding(
            padding: const EdgeInsets.only(top: 8, left: 4, right: 4),
            child: TextField(
              controller: _imitationCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: '✍️ 在此仿写本课句型句子…',
                contentPadding: EdgeInsets.all(14),
              ),
              onChanged: (_) => _debouncedSave(),
            ),
          ),
        ),

        // 复习
        _buildSection(
          theme: theme,
          icon: '🔁',
          title: '复习任务',
          labels: kReviewTaskLabels,
          states: _review,
          section: 2,
        ),

        const SizedBox(height: 8),
        // 保存提示
        Center(
          child: Text(
            _isSaving ? '保存中…' : '✓ 自动保存',
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSection({
    required ThemeData theme,
    required String icon,
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
              Text(icon, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: doneCount == labels.length
                      ? const Color(0xFF58CC02).withOpacity(0.15)
                      : theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$doneCount/${labels.length}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: doneCount == labels.length
                        ? const Color(0xFF58CC02)
                        : theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
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
