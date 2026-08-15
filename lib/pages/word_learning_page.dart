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
import '../widgets/theme_toggle_button.dart';

/// 单词学习页（Duolingo Vibrant 风格）
/// 灵感来源：Duolingo（3D 立体按钮、鲜艳色块、游戏化进度）
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

  int get _mastered =>
      StorageService.instance
          .wordsOf(TextbookService.instance.currentId)
          .where((w) => w.learned && !w.needReview)
          .length;

  int get _notebookCount =>
      StorageService.instance
          .wordsOf(TextbookService.instance.currentId)
          .where((w) => w.inNotebook)
          .length;

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
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(decoration: TextDecoration.none),
        ),
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

  void _setDayFilter(bool today) {
    if (today == _showDayFilter) return;
    setState(() {
      _showDayFilter = today;
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
    final isDark = theme.brightness == Brightness.dark;
    final textbooks = TextbookRegistry.all
        .map((t) => TextbookDropdownOption(value: t.id, label: t.name))
        .toList();
    final textColor = isDark ? AppTheme.kTextDark : AppTheme.kTextLight;
    final secondaryColor =
        isDark ? AppTheme.kSecondaryTextDark : AppTheme.kSecondaryTextLight;

    return CupertinoPageScaffold(
      backgroundColor: Colors.transparent,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: Colors.transparent,
        border: Border.all(color: Colors.transparent),
        trailing: const ThemeToggleButton(),
      ),
      child: Material(
        color: Colors.transparent,
        child: Column(
          children: [
            // 1. 大标题 + 副标题
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '单词学习',
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
                      '按天复习，听发音，标记生词。',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: secondaryColor,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // 2. 教材下拉 + 生词本 + 音效开关
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
              child: Row(
                children: [
                  Flexible(
                    child: TextbookDropdown(
                      options: textbooks,
                      value: TextbookService.instance.currentId,
                      onChanged: _onTextbookChanged,
                    ),
                  ),
                  const SizedBox(width: 10),
                  _buildNotebookChip(isDark),
                  const SizedBox(width: 10),
                  _buildSoundToggle(isDark),
                ],
              ),
            ),
            // 3. 统计 chips
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
              child: Row(
                children: [
                  Expanded(
                    child: _statChip(
                      label: '今日',
                      value: '$_todayLearned',
                      valueColor: AppTheme.kDuoGreen,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _statChip(
                      label: '待复习',
                      value: '$_toReview',
                      valueColor: AppTheme.kDuoOrange,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _statChip(
                      label: '已掌握',
                      value: '$_mastered',
                      valueColor: AppTheme.kDuoBlue,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
            ),
            // 4. 天数过滤（分段控件）
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
              child: _buildDayFilter(isDark),
            ),
            // 5-7. 主内容区
            Expanded(
              child: _loading
                  ? const Center(
                      child: CupertinoActivityIndicator(
                        color: AppTheme.kDuoGreen,
                      ),
                    )
                  : _vocab.isEmpty
                      ? _buildEmpty(isDark)
                      : _index >= _vocab.length
                          ? _buildComplete(isDark)
                          : _buildWordCard(isDark),
            ),
          ],
        ),
      ),
    );
  }

  // —— 生词本 chip（绿色 tint + 书本图标 + 3D 底边）——
  Widget _buildNotebookChip(bool isDark) {
    const accent = AppTheme.kDuoGreen;
    return GestureDetector(
      onTap: () => _showNotebook(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: accent.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppTheme.kDuoGreenDark,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(CupertinoIcons.book, size: 16, color: accent),
            const SizedBox(width: 6),
            Text(
              '生词本 $_notebookCount',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: accent,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // —— 音效开关（保留 CupertinoSwitch）——
  Widget _buildSoundToggle(bool isDark) {
    final enabled = AudioFeedbackService.instance.enabled;
    final mutedColor =
        isDark ? AppTheme.kSecondaryTextDark : AppTheme.kSecondaryTextLight;
    return GestureDetector(
      onTap: () => _toggleSoundEffects(!enabled),
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            enabled ? CupertinoIcons.speaker_2_fill : CupertinoIcons.speaker_slash_fill,
            size: 17,
            color: enabled ? AppTheme.kDuoGreen : mutedColor,
          ),
          const SizedBox(width: 6),
          Transform.scale(
            scale: 0.78,
            child: CupertinoSwitch(
              value: enabled,
              onChanged: _toggleSoundEffects,
            ),
          ),
        ],
      ),
    );
  }

  // —— 统计卡片 ——
  Widget _statChip({
    required String label,
    required String value,
    required Color valueColor,
    required bool isDark,
  }) {
    final cardColor = isDark ? AppTheme.kCardDark : AppTheme.kCardLight;
    final borderColor =
        isDark ? AppTheme.kSeparatorDark : AppTheme.kSeparatorLight;
    final secondaryColor =
        isDark ? AppTheme.kSecondaryTextDark : AppTheme.kSecondaryTextLight;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 3,
            width: double.infinity,
            color: valueColor,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: valueColor,
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
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
        ],
      ),
    );
  }

  // —— 分段控件：今日 / 全部 ——
  Widget _buildDayFilter(bool isDark) {
    final trackColor =
        isDark ? AppTheme.kBgSecondaryDark : AppTheme.kBgSecondaryLight;
    final unselectedColor =
        isDark ? AppTheme.kSecondaryTextDark : AppTheme.kSecondaryTextLight;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: trackColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _segment(
            label: '今日',
            selected: _showDayFilter,
            unselectedColor: unselectedColor,
            onTap: () => _setDayFilter(true),
          ),
          _segment(
            label: '全部',
            selected: !_showDayFilter,
            unselectedColor: unselectedColor,
            onTap: () => _setDayFilter(false),
          ),
        ],
      ),
    );
  }

  Widget _segment({
    required String label,
    required bool selected,
    required Color unselectedColor,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: selected ? AppTheme.kDuoGreen : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: selected ? AppTheme.kDuoGreenDark : Colors.transparent,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : unselectedColor,
              decoration: TextDecoration.none,
            ),
          ),
        ),
      ),
    );
  }

  // —— 单词卡 + 进度条 + 按钮 ——
  Widget _buildWordCard(bool isDark) {
    final textColor = isDark ? AppTheme.kTextDark : AppTheme.kTextLight;
    final secondaryColor =
        isDark ? AppTheme.kSecondaryTextDark : AppTheme.kSecondaryTextLight;
    final separatorColor =
        isDark ? AppTheme.kSeparatorDark : AppTheme.kSeparatorLight;
    final word = _current;
    final progress =
        StorageService.instance.getWord(TextbookService.instance.currentId, word.word);
    final familiarity = progress?.familiarity ?? 0;

    return Column(
      children: [
        // 5. 单词卡
        Expanded(
          child: GestureDetector(
            onTap: () {
              if (!_revealed) setState(() => _revealed = true);
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: LiquidGlassCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // 右上角：课程号徽标
                    Align(
                      alignment: Alignment.centerRight,
                      child: _lessonBadge(word, isDark),
                    ),
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 5 星熟悉度
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                5,
                                (i) => Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: Icon(
                                    CupertinoIcons.star_fill,
                                    size: 22,
                                    color: i < familiarity
                                        ? AppTheme.kDuoYellow
                                        : separatorColor,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            // 大单词
                            Text(
                              word.word,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.w800,
                                color: textColor,
                                letterSpacing: 0.5,
                                decoration: TextDecoration.none,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // 音标
                            Text(
                              word.phonetic,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                                color: secondaryColor,
                                fontStyle: FontStyle.italic,
                                decoration: TextDecoration.none,
                              ),
                            ),
                            const SizedBox(height: 16),
                            // 英 / 美发音
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _voiceButton(
                                  label: '英',
                                  accent: WordVoiceAccent.british,
                                  isDark: isDark,
                                ),
                                const SizedBox(width: 12),
                                _voiceButton(
                                  label: '美',
                                  accent: WordVoiceAccent.american,
                                  isDark: isDark,
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            // 释义 / 提示
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: _revealed
                                  ? Padding(
                                      key: const ValueKey('meaning'),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16),
                                      child: Text(
                                        word.meaning,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: textColor,
                                          height: 1.5,
                                          decoration: TextDecoration.none,
                                        ),
                                      ),
                                    )
                                  : Row(
                                      key: const ValueKey('hint'),
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          CupertinoIcons.hand_draw,
                                          size: 15,
                                          color: secondaryColor.withOpacity(0.7),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '点击查看释义',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w400,
                                            color: secondaryColor.withOpacity(0.7),
                                            decoration: TextDecoration.none,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // 6. 进度条 + 计数
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Row(
            children: [
              Text(
                '${_index + 1} / ${_vocab.length}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: secondaryColor,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: (_index + 1) / _vocab.length,
                    minHeight: 12,
                    backgroundColor: separatorColor,
                    valueColor:
                        const AlwaysStoppedAnimation(AppTheme.kDuoGreen),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // 8. 认识 / 不认识按钮
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
          child: Row(
            children: [
              Expanded(
                child: DuolingoButton(
                  label: '不认识',
                  variant: DuolingoButtonVariant.danger,
                  minHeight: 58,
                  borderRadius: 16,
                  onPressed: _revealed ? () => _answer(false) : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DuolingoButton(
                  label: '认识',
                  variant: DuolingoButtonVariant.success,
                  minHeight: 58,
                  borderRadius: 16,
                  onPressed: _revealed ? () => _answer(true) : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // —— 课程号徽标（圆形 kDuoBlue tint）——
  Widget _lessonBadge(VocabWord word, bool isDark) {
    const badgeColor = AppTheme.kDuoBlue;
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.12),
        shape: BoxShape.circle,
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          'L${word.lessonNumber}',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: badgeColor,
            decoration: TextDecoration.none,
          ),
        ),
      ),
    );
  }

  // —— 英 / 美发音按钮 ——
  Widget _voiceButton({
    required String label,
    required WordVoiceAccent accent,
    required bool isDark,
  }) {
    const accentColor = AppTheme.kDuoGreen;
    final cardColor = isDark ? AppTheme.kCardDark : AppTheme.kCardLight;
    final selected = WordTtsService.instance.defaultAccent == accent;
    final fgColor = selected ? Colors.white : accentColor;
    return GestureDetector(
      onTap: () => _speakWord(accent),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? accentColor : cardColor,
          borderRadius: BorderRadius.circular(14),
          border: selected ? null : Border.all(color: accentColor, width: 2),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppTheme.kDuoGreenDark,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.speaker_2_fill,
              size: 15,
              color: fgColor,
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: fgColor,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // —— 完成卡片 ——
  Widget _buildComplete(bool isDark) {
    final textColor = isDark ? AppTheme.kTextDark : AppTheme.kTextLight;
    final secondaryColor =
        isDark ? AppTheme.kSecondaryTextDark : AppTheme.kSecondaryTextLight;
    return Padding(
      padding: const EdgeInsets.only(bottom: 120),
      child: Center(
        child: LiquidGlassCard(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                CupertinoIcons.checkmark_seal_fill,
                size: 72,
                color: AppTheme.kDuoGreen,
              ),
              const SizedBox(height: 12),
              Text(
                _showDayFilter ? '第$_currentDay天单词已学完' : '今日单词已学完',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '本词库共 ${_vocab.length} 词',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: secondaryColor,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '继续保持！',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: secondaryColor,
                  decoration: TextDecoration.none,
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
      ),
    );
  }

  // —— 空态 ——
  Widget _buildEmpty(bool isDark) {
    final secondaryColor =
        isDark ? AppTheme.kSecondaryTextDark : AppTheme.kSecondaryTextLight;
    return Padding(
      padding: const EdgeInsets.only(bottom: 120),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              CupertinoIcons.tray,
              size: 64,
              color: AppTheme.kDuoBlue,
            ),
            const SizedBox(height: 16),
            Text(
              _showDayFilter ? '第$_currentDay天暂无单词数据' : '暂无单词数据',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: secondaryColor,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '切换到全部词库试试',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: secondaryColor,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: DuolingoButton(
                label: '查看全部单词',
                variant: DuolingoButtonVariant.primary,
                onPressed: () {
                  setState(() {
                    _showDayFilter = false;
                    _loading = true;
                  });
                  _reloadVocab();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // —— 生词本底部弹窗（Duolingo 风格）——
  void _showNotebook(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final sheetBg = isDark ? AppTheme.kCardDark : AppTheme.kCardLight;
    final rowBg =
        isDark ? AppTheme.kBgSecondaryDark : AppTheme.kBgSecondaryLight;
    final textColor = isDark ? AppTheme.kTextDark : AppTheme.kTextLight;
    final secondaryColor =
        isDark ? AppTheme.kSecondaryTextDark : AppTheme.kSecondaryTextLight;

    final words = StorageService.instance
        .wordsOf(TextbookService.instance.currentId)
        .where((w) => w.inNotebook)
        .toList();
    final allVocab =
        TextbookRegistry.vocabWithDayNumber(TextbookService.instance.currentId);
    final vocabMap = {for (final v in allVocab) v.word: v};

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: sheetBg,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // 顶部把手
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: secondaryColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            // 标题 + 关闭
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
              child: Row(
                children: [
                  Text(
                    '生词本（${words.length}）',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        CupertinoIcons.xmark,
                        size: 20,
                        color: secondaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(
              height: 1,
              color: secondaryColor.withOpacity(0.2),
            ),
            // 列表
            Expanded(
              child: words.isEmpty
                  ? Center(
                      child: Text(
                        '还没有生词\n点“不认识”即可加入',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: secondaryColor.withOpacity(0.5),
                          decoration: TextDecoration.none,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      itemCount: words.length,
                      itemBuilder: (_, i) {
                        final w = words[i];
                        final vw = vocabMap[w.word];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: rowBg,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      w.word,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: textColor,
                                        decoration: TextDecoration.none,
                                      ),
                                    ),
                                    if (vw != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 3),
                                        child: Text(
                                          vw.phonetic,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w400,
                                            color: secondaryColor,
                                            decoration: TextDecoration.none,
                                          ),
                                        ),
                                      ),
                                    if (vw != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Text(
                                          vw.meaning,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w400,
                                            color: textColor.withOpacity(0.7),
                                            decoration: TextDecoration.none,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () async {
                                  w.inNotebook = false;
                                  await StorageService.instance.saveWord(w);
                                  if (!mounted) return;
                                  setState(() {});
                                  Navigator.of(context).pop();
                                  _showNotebook(context);
                                },
                                behavior: HitTestBehavior.opaque,
                                child: const Padding(
                                  padding: EdgeInsets.all(8),
                                  child: Icon(
                                    CupertinoIcons.delete,
                                    size: 21,
                                    color: AppTheme.kDuoRed,
                                  ),
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
    );
  }
}
