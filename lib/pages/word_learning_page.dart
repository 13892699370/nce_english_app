import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../data/textbook_registry.dart';
import '../data/lesson.dart';
import '../models/word_progress.dart';
import '../services/storage_service.dart';
import '../services/textbook_service.dart';
import '../services/haptic_service.dart';
import '../services/audio_feedback_service.dart';
import '../services/word_tts_service.dart';
import '../theme/app_theme.dart';
import '../utils/date_util.dart';
import '../widgets/liquid_glass_card.dart';
import '../widgets/duolingo_button.dart';
import '../widgets/textbook_dropdown.dart';
import '../widgets/day_wheel_picker.dart';
import '../widgets/theme_toggle_button.dart';

/// 单词学习页（iOS 原生风格）
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
  int _currentDay = 1;
  bool _showDayFilter = false;

  @override
  void initState() {
    super.initState();
    _initDayAndLoad();
    TextbookService.instance.addListener(_onTextbookNotification);
  }

  @override
  void dispose() {
    TextbookService.instance.removeListener(_onTextbookNotification);
    super.dispose();
  }

  void _initDayAndLoad() {
    final tbId = TextbookService.instance.currentId;
    _currentDay = StorageService.instance.currentDayOf(tbId);
    _showDayFilter = true;
    _reloadVocab();
  }

  void _onTextbookNotification() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _currentDay =
            StorageService.instance.currentDayOf(TextbookService.instance.currentId);
        _loading = true;
      });
      _reloadVocab();
    });
  }

  void _reloadVocab() {
    final tbId = TextbookService.instance.currentId;
    final allVocab = TextbookRegistry.vocabWithDayNumber(tbId);

    if (_showDayFilter) {
      _vocab = allVocab.where((v) => v.dayNumber == _currentDay).toList();
    } else {
      _vocab = List.from(allVocab);
    }

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

  int get _totalDays {
    final info = TextbookRegistry.byId(TextbookService.instance.currentId);
    return info.totalDays;
  }

  Future<void> _toggleSoundEffects(bool value) async {
    await AudioFeedbackService.instance.setEnabled(value);
    if (mounted) setState(() {});
  }

  Future<void> _speakWord(WordVoiceAccent accent) async {
    final message = await WordTtsService.instance.speak(
      _current.word,
      accent: accent,
      saveAsDefault: true,
    );
    if (!mounted) return;
    setState(() {});
    if (message == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _onTextbookChanged(String id) async {
    await TextbookService.instance.select(id);
    setState(() {
      _currentDay = StorageService.instance.currentDayOf(id);
      _showDayFilter = true;
      _loading = true;
    });
    _reloadVocab();
  }

  Future<void> _answer(bool known) async {
    if (_vocab.isEmpty || _index >= _vocab.length) return;
    if (known) {
      AudioFeedbackService.instance.playKnown();
    } else {
      AudioFeedbackService.instance.playUnknown();
    }
    final tbId = TextbookService.instance.currentId;
    final today = DateUtil.today();
    final existing = StorageService.instance.getWord(tbId, _current.word);
    final progress = existing ??
        WordProgress(word: _current.word, textbook: tbId);

    if (known) {
      progress.familiarity = (progress.familiarity + 1).clamp(0, 5);
      progress.learned = true;
      progress.inNotebook = false;
      await HapticService.light();
    } else {
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
        _index = _vocab.length;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textbooks = TextbookRegistry.all
        .map((t) => TextbookDropdownOption(value: t.id, label: t.name))
        .toList();

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Lumina Mono'),
        trailing: ThemeToggleButton(),
      ),
      child: Material(
        color: Colors.transparent,
        child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '单词训练',
                    style: theme.textTheme.displayMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '按天复习，听发音，标记生词。',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.58),
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _showNotebook(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.kSystemOrange.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(CupertinoIcons.book,
                            size: 15, color: AppTheme.kSystemOrange),
                        const SizedBox(width: 6),
                        Text(
                          '生词本 $_notebookCount',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.kSystemOrange,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                Icon(
                  CupertinoIcons.speaker_2_fill,
                  size: 17,
                  color: theme.colorScheme.onSurface.withOpacity(0.4),
                ),
                const SizedBox(width: 6),
                Transform.scale(
                  scale: 0.85,
                  child: CupertinoSwitch(
                    value: AudioFeedbackService.instance.enabled,
                    onChanged: _toggleSoundEffects,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextbookDropdown(
              options: textbooks,
              value: TextbookService.instance.currentId,
              onChanged: _onTextbookChanged,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _statChip(
                    theme: theme,
                    color: AppTheme.kSystemBlue,
                    label: '今日学习',
                    value: '$_todayLearned',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _statChip(
                    theme: theme,
                    color: AppTheme.kSystemOrange,
                    label: '待复习',
                    value: '$_toReview',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _statChip(
                    theme: theme,
                    color: AppTheme.kSystemPurple,
                    label: '词库',
                    value: '${_vocab.length}',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildDayFilter(theme),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _loading
                ? const Center(child: CupertinoActivityIndicator())
                : _vocab.isEmpty
                    ? _buildEmpty(theme)
                    : _index >= _vocab.length
                        ? _buildComplete(theme)
                        : _buildWordCard(theme),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildDayFilter(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _showDayFilter = !_showDayFilter;
                _reloadVocab();
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: _showDayFilter
                    ? theme.colorScheme.primary.withOpacity(0.10)
                    : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.line_horizontal_3_decrease,
                    size: 15,
                    color: _showDayFilter
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _showDayFilter
                        ? '第$_currentDay天 · L${_currentDay * 2 - 1}-L${_currentDay * 2}'
                        : '全部单词',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _showDayFilter
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_showDayFilter) ...[
          const SizedBox(width: 10),
          Expanded(
            child: DayWheelPicker(
              currentDay: _currentDay,
              totalDays: _totalDays,
              onChanged: (day) {
                if (day == _currentDay) return;
                setState(() {
                  _currentDay = day;
                  _loading = true;
                });
                _reloadVocab();
                StorageService.instance
                    .setCurrentDay(TextbookService.instance.currentId, day);
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _statChip({
    required ThemeData theme,
    required Color color,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface.withOpacity(0.5),
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
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              borderRadius: 20,
              child: Stack(
                children: [
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppTheme.kSystemTeal.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'L${word.lessonNumber}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.kSystemTeal,
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (progress != null) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              5,
                              (i) => Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 2),
                                child: Icon(
                                  CupertinoIcons.star_fill,
                                  size: 18,
                                  color: i < progress.familiarity
                                      ? AppTheme.kSystemYellow
                                      : theme.colorScheme.outline
                                          .withOpacity(0.2),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                        ],
                        Text(
                          word.word,
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _voiceButton(
                              theme: theme,
                              label: '英音',
                              accent: WordVoiceAccent.british,
                            ),
                            const SizedBox(width: 12),
                            _voiceButton(
                              theme: theme,
                              label: '美音',
                              accent: WordVoiceAccent.american,
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          word.phonetic,
                          style: TextStyle(
                            fontSize: 18,
                            color:
                                theme.colorScheme.onSurface.withOpacity(0.5),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 28),
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: _revealed ? 1 : 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 18),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary
                                  .withOpacity(0.08),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              word.meaning,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.w600,
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
                              Icon(CupertinoIcons.hand_draw,
                                  size: 15,
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.35)),
                              const SizedBox(width: 8),
                              Text(
                                '点击卡片查看释义',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.35),
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Text(
                '${_index + 1} / ${_vocab.length}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface.withOpacity(0.4),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (_index + 1) / _vocab.length,
                    minHeight: 5,
                    backgroundColor:
                        theme.colorScheme.surface,
                    valueColor:
                        AlwaysStoppedAnimation(theme.colorScheme.primary),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 140),
          child: Row(
            children: [
              Expanded(
                child: DuolingoButton(
                  label: '不认识',
                  variant: DuolingoButtonVariant.danger,
                  minHeight: 54,
                  borderRadius: 14,
                  onPressed: _revealed ? () => _answer(false) : null,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: DuolingoButton(
                  label: '认识',
                  variant: DuolingoButtonVariant.success,
                  minHeight: 54,
                  borderRadius: 14,
                  onPressed: _revealed ? () => _answer(true) : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _voiceButton({
    required ThemeData theme,
    required String label,
    required WordVoiceAccent accent,
  }) {
    final selected = WordTtsService.instance.defaultAccent == accent;
    return GestureDetector(
      onTap: () => _speakWord(accent),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary.withOpacity(0.12)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.speaker_2_fill,
              size: 15,
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withOpacity(0.5),
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: selected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComplete(ThemeData theme) {
    return Center(
      child: LiquidGlassCard(
        margin: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(CupertinoIcons.checkmark_seal_fill,
                size: 56, color: AppTheme.kSystemBlue),
            const SizedBox(height: 12),
            Text(
              _showDayFilter ? '第$_currentDay天单词已学完' : '今日单词已学完',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '本词库共 ${_vocab.length} 词',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 20),
            DuolingoButton(
              label: '重新开始',
              icon: CupertinoIcons.refresh,
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

  Widget _buildEmpty(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(CupertinoIcons.tray,
              size: 48, color: theme.colorScheme.onSurface.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text(
            _showDayFilter ? '第$_currentDay天暂无单词数据' : '暂无单词数据',
            style: TextStyle(
              fontSize: 15,
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 12),
          DuolingoButton(
            label: '查看全部单词',
            onPressed: () {
              setState(() {
                _showDayFilter = false;
                _reloadVocab();
              });
            },
          ),
        ],
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
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
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
              const SizedBox(height: 12),
              Text(
                '生词本（${words.length}）',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: words.isEmpty
                    ? Center(
                        child: Text(
                          '还没有生词\n点"不认识"即可加入',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: theme.colorScheme.onSurface.withOpacity(0.35),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
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
                                              fontSize: 17,
                                              fontWeight: FontWeight.w600)),
                                      if (vw != null)
                                        Text(vw.phonetic,
                                            style: TextStyle(
                                                fontSize: 13,
                                                color: theme.colorScheme
                                                    .onSurface
                                                    .withOpacity(0.4))),
                                      if (vw != null)
                                        Text(vw.meaning,
                                            style: TextStyle(
                                                fontSize: 13,
                                                color: theme.colorScheme
                                                    .onSurface
                                                    .withOpacity(0.6))),
                                    ],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () async {
                                    w.inNotebook = false;
                                    await StorageService.instance
                                        .saveWord(w);
                                    setState(() {});
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Icon(CupertinoIcons.delete,
                                        size: 20, color: AppTheme.kSystemRed),
                                  ),
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
