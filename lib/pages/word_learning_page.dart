import 'package:flutter/material.dart';
import '../data/textbook_registry.dart';
import '../data/lesson.dart';
import '../models/word_progress.dart';
import '../services/storage_service.dart';
import '../services/textbook_service.dart';
import '../services/haptic_service.dart';
import '../utils/date_util.dart';
import '../widgets/liquid_glass_card.dart';
import '../widgets/duolingo_button.dart';
import '../widgets/capsule_selector.dart';

/// 单词学习页（仿百词斩）
///
/// 根据当前选中教材自动加载对应词库；液态玻璃单词大卡片，
/// 展示英文、音标、中文释义；底部大号 认识/不认识 按钮，
/// 复刻多邻国按压动效，双端表现一致。
class WordLearningPage extends StatefulWidget {
  const WordLearningPage({super.key});

  @override
  State<WordLearningPage> createState() => _WordLearningPageState();
}

class _WordLearningPageState extends State<WordLearningPage> {
  late List<VocabWord> _vocab;
  int _index = 0;
  bool _revealed = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reloadVocab();
    TextbookService.instance.addListener(_onTextbookNotification);
  }

  @override
  void dispose() {
    TextbookService.instance.removeListener(_onTextbookNotification);
    super.dispose();
  }

  /// 监听教材切换（可能来自其他 Tab），下一帧刷新词库，避免 build 期间 setState
  void _onTextbookNotification() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _loading = true);
      _reloadVocab();
    });
  }

  void _reloadVocab() {
    final tbId = TextbookService.instance.currentId;
    _vocab = TextbookRegistry.vocabOf(tbId);
    // 排序：待复习优先，其次未学习，最后按课程号
    _vocab.sort((a, b) {
      final pa = StorageService.instance.getWord(tbId, a.word);
      final pb = StorageService.instance.getWord(tbId, b.word);
      final aReview = pa?.needReview ?? false;
      final bReview = pb?.needReview ?? false;
      final aLearned = pa?.learned ?? false;
      final bLearned = pb?.learned ?? false;
      if (aReview && !bReview) return -1;
      if (!aReview && bReview) return 1;
      if (!aLearned && bLearned) return -1;
      if (aLearned && !bLearned) return 1;
      return a.lessonNumber.compareTo(b.lessonNumber);
    });
    _index = 0;
    _revealed = false;
    setState(() => _loading = false);
  }

  VocabWord get _current => _vocab[_index];

  int get _todayLearned {
    final today = DateUtil.today();
    return StorageService.instance
        .wordsOf(TextbookService.instance.currentId)
        .where((w) => w.learned && w.lastReviewDate == today)
        .length;
  }

  int get _toReview =>
      StorageService.instance
          .wordsOf(TextbookService.instance.currentId)
          .where((w) => w.needReview)
          .length;

  int get _notebookCount =>
      StorageService.instance
          .wordsOf(TextbookService.instance.currentId)
          .where((w) => w.inNotebook)
          .length;

  Future<void> _onTextbookChanged(String id) async {
    await TextbookService.instance.select(id);
    setState(() => _loading = true);
    _reloadVocab();
  }

  Future<void> _answer(bool known) async {
    final tbId = TextbookService.instance.currentId;
    final today = DateUtil.today();
    final existing = StorageService.instance.getWord(tbId, _current.word);
    final progress = existing ??
        WordProgress(word: _current.word, textbook: tbId);

    if (known) {
      // 认识：提升熟悉度，降低复习优先级
      progress.familiarity = (progress.familiarity + 1).clamp(0, 5);
      progress.learned = true;
      progress.inNotebook = false;
      await HapticService.light();
    } else {
      // 不认识：加入生词本与复习队列
      progress.familiarity = 0;
      progress.learned = true;
      progress.inNotebook = true;
      await HapticService.heavy();
    }
    progress.lastReviewDate = today;
    progress.reviewCount += 1;
    await StorageService.instance.saveWord(progress);

    setState(() {
      if (_index < _vocab.length - 1) {
        _index += 1;
        _revealed = false;
      } else {
        _index = _vocab.length; // 完成
      }
    });
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
            // 顶部
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Text('📖 单词学习',
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.w800)),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => _showNotebook(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFC800).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.menu_book,
                                  size: 14, color: Color(0xFFE0A800)),
                              const SizedBox(width: 4),
                              Text(
                                '生词本 $_notebookCount',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFE0A800),
                                ),
                              ),
                            ],
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
                  const SizedBox(height: 12),
                  // 统计卡
                  Row(
                    children: [
                      Expanded(
                        child: _statChip(
                          theme: theme,
                          color: const Color(0xFF58CC02),
                          label: '今日学习',
                          value: '$_todayLearned',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _statChip(
                          theme: theme,
                          color: const Color(0xFFFFC800),
                          label: '待复习',
                          value: '$_toReview',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _statChip(
                          theme: theme,
                          color: const Color(0xFF1CB0F6),
                          label: '词库',
                          value: '${_vocab.length}',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // 单词卡 + 按钮
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _index >= _vocab.length
                      ? _buildComplete(theme)
                      : _buildWordCard(theme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statChip({
    required ThemeData theme,
    required Color color,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWordCard(ThemeData theme) {
    final word = _current;
    final progress =
        StorageService.instance.getWord(TextbookService.instance.currentId, word.word);
    return Column(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _revealed = true),
            child: LiquidGlassCard(
              margin: const EdgeInsets.all(16),
              borderRadius: 32,
              child: Stack(
                children: [
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1CB0F6).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'L${word.lessonNumber}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1CB0F6),
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 进度环
                        if (progress != null) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              5,
                              (i) => Icon(
                                Icons.star_rounded,
                                size: 18,
                                color: i < progress.familiarity
                                    ? const Color(0xFFFFC800)
                                    : theme.colorScheme.outline
                                        .withOpacity(0.25),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        Text(
                          word.word,
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.onSurface,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          word.phonetic,
                          style: TextStyle(
                            fontSize: 20,
                            color:
                                theme.colorScheme.onSurface.withOpacity(0.6),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 28),
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 240),
                          opacity: _revealed ? 1 : 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF58CC02)
                                  .withOpacity(0.08),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              word.meaning,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ),
                        if (!_revealed) ...[
                          const SizedBox(height: 28),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.touch_app_rounded,
                                  size: 16,
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.4)),
                              const SizedBox(width: 6),
                              Text(
                                '点击卡片查看释义',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.4),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // 进度
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Text(
                '${_index + 1} / ${_vocab.length}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: (_index + 1) / _vocab.length,
                    minHeight: 8,
                    backgroundColor:
                        theme.colorScheme.surface,
                    valueColor:
                        const AlwaysStoppedAnimation(Color(0xFF58CC02)),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // 按钮
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: DuolingoButton(
                  label: '不认识',
                  variant: DuolingoButtonVariant.danger,
                  minHeight: 60,
                  borderRadius: 20,
                  onPressed: _revealed ? () => _answer(false) : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DuolingoButton(
                  label: '认识',
                  variant: DuolingoButtonVariant.success,
                  minHeight: 60,
                  borderRadius: 20,
                  onPressed: _revealed ? () => _answer(true) : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildComplete(ThemeData theme) {
    return Center(
      child: LiquidGlassCard(
        margin: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 12),
            Text(
              '今日单词已学完！',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '本词库共 ${_vocab.length} 词，\n记得回来复习哦～',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 20),
            DuolingoButton(
              label: '重新开始',
              icon: Icons.refresh_rounded,
              variant: DuolingoButtonVariant.secondary,
              onPressed: () => setState(() {
                _index = 0;
                _revealed = false;
              }),
            ),
          ],
        ),
      ),
    );
  }

  void _showNotebook(BuildContext context) {
    final theme = Theme.of(context);
    final words = StorageService.instance
        .wordsOf(TextbookService.instance.currentId)
        .where((w) => w.inNotebook)
        .toList();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outline.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '生词本（${words.length}）',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: words.isEmpty
                    ? Center(
                        child: Text(
                          '还没有生词\n点“不认识”即可加入',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withOpacity(0.4),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: words.length,
                        itemBuilder: (_, i) {
                          final w = words[i];
                          VocabWord? vw;
                          for (final v in _vocab) {
                            if (v.word == w.word) {
                              vw = v;
                              break;
                            }
                          }
                          return LiquidGlassCard(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(w.word,
                                          style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w800)),
                                      if (vw != null)
                                        Text(vw.phonetic,
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: theme.colorScheme
                                                    .onSurface
                                                    .withOpacity(0.5))),
                                      if (vw != null)
                                        Text(vw.meaning,
                                            style: TextStyle(
                                                fontSize: 13,
                                                color: theme.colorScheme
                                                    .onSurface
                                                    .withOpacity(0.7))),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      color: Color(0xFFFF4B4B)),
                                  onPressed: () async {
                                    w.inNotebook = false;
                                    await StorageService.instance
                                        .saveWord(w);
                                    setState(() {});
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
