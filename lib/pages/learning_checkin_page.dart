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
import '../widgets/duolingo_button.dart';
import '../widgets/capsule_selector.dart';
import '../widgets/task_checkbox.dart';
import '../widgets/celebration_dialog.dart';

/// 新概念学习打卡页
///
/// 教材下拉选择 -> 课程单元（1组=新课+复习课） ->
/// 预习 / 正式学习 / 复习 完整流程 -> 提交打卡（Hive 本地存储，按教材隔离）。
class LearningCheckinPage extends StatefulWidget {
  const LearningCheckinPage({super.key});

  @override
  State<LearningCheckinPage> createState() => _LearningCheckinPageState();
}

class _LearningCheckinPageState extends State<LearningCheckinPage> {
  late List<Lesson> _lessons;
  int _selectedLessonIndex = 0;
  String _today = '';

  // 编辑缓冲
  List<bool> _preview = [];
  List<bool> _formal = [];
  List<bool> _review = [];
  TextEditingController _imitationCtrl = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _today = DateUtil.today();
    _reloadLessons();
    _loadCheckin();
    TextbookService.instance.addListener(_onTextbookNotification);
  }

  @override
  void dispose() {
    TextbookService.instance.removeListener(_onTextbookNotification);
    _imitationCtrl.dispose();
    super.dispose();
  }

  /// 监听教材切换（可能来自其他 Tab），下一帧刷新课程与打卡，避免 build 期间 setState
  void _onTextbookNotification() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _selectedLessonIndex = 0;
        _loading = true;
      });
      _reloadLessons();
      _loadCheckin();
    });
  }

  void _reloadLessons() {
    _lessons = TextbookRegistry.lessonsOf(TextbookService.instance.currentId);
    if (_selectedLessonIndex >= _lessons.length) {
      _selectedLessonIndex = 0;
    }
  }

  void _loadCheckin() {
    if (_lessons.isEmpty) {
      setState(() => _loading = false);
      return;
    }
    final lesson = _lessons[_selectedLessonIndex];
    final existing = StorageService.instance.getCheckin(
      TextbookService.instance.currentId,
      _today,
      lesson.number,
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

  void _onLessonChanged(int index) {
    setState(() {
      _selectedLessonIndex = index;
      _loading = true;
    });
    _loadCheckin();
  }

  Future<void> _onTextbookChanged(String id) async {
    await TextbookService.instance.select(id);
    setState(() {
      _selectedLessonIndex = 0;
      _loading = true;
    });
    _reloadLessons();
    _loadCheckin();
  }

  Future<void> _submit() async {
    if (_lessons.isEmpty) return;
    final lesson = _lessons[_selectedLessonIndex];
    final createdAt = DateUtil.dateTime(DateTime.now());

    final checkin = LessonCheckin(
      textbook: TextbookService.instance.currentId,
      date: _today,
      lessonNumber: lesson.number,
      previewTasks: List<bool>.from(_preview),
      formalTasks: List<bool>.from(_formal),
      reviewTasks: List<bool>.from(_review),
      imitationSentence: _imitationCtrl.text.trim(),
      createdAt: createdAt,
    );
    await StorageService.instance.saveCheckin(checkin);
    await HapticService.heavy();

    // 检查成就解锁
    final unlocked = await AchievementService.instance.checkAndUnlock();
    if (!mounted) return;
    if (unlocked.isNotEmpty) {
      for (final def in unlocked) {
        if (!mounted) return;
        await CelebrationDialog.show(context, def);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(checkin.isAllDone ? '✅ 打卡完成，继续加油！' : '📝 已保存进度'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: checkin.isAllDone
              ? const Color(0xFF58CC02)
              : Theme.of(context).colorScheme.surface,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textbooks = TextbookRegistry.all
        .map((t) => CapsuleOption(value: t.id, label: t.name))
        .toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 顶部：教材选择 + 今日日期
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
                  const SizedBox(height: 12),
                  CapsuleSelector<String>(
                    options: textbooks,
                    value: TextbookService.instance.currentId,
                    onChanged: _onTextbookChanged,
                  ),
                ],
              ),
            ),

            // 课程横向选择
            SizedBox(
              height: 64,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _lessons.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final lesson = _lessons[i];
                  final selected = i == _selectedLessonIndex;
                  final group = lesson.group;
                  return GestureDetector(
                    onTap: () => _onLessonChanged(i),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'L${lesson.number}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: selected
                                      ? Colors.white
                                      : theme.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: lesson.isNew
                                      ? (selected
                                          ? Colors.white.withOpacity(0.3)
                                          : const Color(0xFF1CB0F6)
                                              .withOpacity(0.15))
                                      : (selected
                                          ? Colors.white.withOpacity(0.3)
                                          : const Color(0xFFFFC800)
                                              .withOpacity(0.18)),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  lesson.isNew ? '新课' : '复习',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: lesson.isNew
                                        ? (selected
                                            ? Colors.white
                                            : const Color(0xFF1CB0F6))
                                        : (selected
                                            ? Colors.white
                                            : const Color(0xFFE0A800)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '第$group组',
                            style: TextStyle(
                              fontSize: 11,
                              color: selected
                                  ? Colors.white.withOpacity(0.85)
                                  : theme.colorScheme.onSurface.withOpacity(0.5),
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
    if (_lessons.isEmpty) {
      return const Center(child: Text('暂无课程数据'));
    }
    final lesson = _lessons[_selectedLessonIndex];
    return ListView(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 100),
      children: [
        // 课程标题卡
        LiquidGlassCard(
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: lesson.isNew
                      ? const Color(0xFF1CB0F6).withOpacity(0.15)
                      : const Color(0xFFFFC800).withOpacity(0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${lesson.number}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: lesson.isNew
                        ? const Color(0xFF1CB0F6)
                        : const Color(0xFFE0A800),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${TextbookService.instance.current.name} · 第${lesson.group}组 · ${lesson.isNew ? "新课" : "复习课"}',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withOpacity(0.55),
                      ),
                    ),
                  ],
                ),
              ),
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
          onToggle: (i, v) => setState(() => _preview[i] = v),
        ),

        // 正式学习
        _buildSection(
          theme: theme,
          icon: '🎬',
          title: '正式学习',
          labels: kFormalTaskLabels,
          states: _formal,
          onToggle: (i, v) => setState(() => _formal[i] = v),
          extra: Padding(
            padding: const EdgeInsets.only(top: 8, left: 4, right: 4),
            child: TextField(
              controller: _imitationCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: '✍️ 在此仿写本课句型句子…',
                contentPadding: EdgeInsets.all(14),
              ),
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
          onToggle: (i, v) => setState(() => _review[i] = v),
        ),

        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DuolingoButton(
            label: '提交打卡',
            icon: Icons.check_circle_outline,
            onPressed: _submit,
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
    required void Function(int, bool) onToggle,
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
              onChanged: (v) => onToggle(i, v),
            ),
          if (extra != null) extra,
        ],
      ),
    );
  }
}
