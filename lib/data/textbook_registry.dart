import 'lesson.dart';
import 'nce1_data.dart';
import 'nce2_data.dart';
import 'nce3_data.dart';

/// 预习任务清单（所有教材通用，可勾选项）
const List<String> kPreviewTaskLabels = [
  '音频盲听 2-3 遍',
  '查阅本课生词音标释义',
];

/// 正式学习固定 4 项任务
const List<String> kFormalTaskLabels = [
  '看完 Leo 精讲视频',
  '音频跟读训练',
  '完成绿皮书习题',
  '仿写本课句型句子',
];

/// 复习任务清单（可勾选项）
const List<String> kReviewTaskLabels = [
  '课文流利跟读',
  '回顾本课全部生词',
  '回看错题',
];

/// 教材信息
class TextbookInfo {
  final String id; // nce1 | nce2 | nce3
  final String name; // 新概念1
  final List<String> lessonTitles;
  final List<VocabWord> vocab;
  final bool available; // 是否已启用数据

  const TextbookInfo({
    required this.id,
    required this.name,
    required this.lessonTitles,
    required this.vocab,
    this.available = true,
  });

  int get lessonCount => lessonTitles.length;

  /// 总天数（每2节课=1天）
  int get totalDays => (lessonCount / 2).ceil();
}

/// 教材注册表
///
/// 业务逻辑与数据解耦：新增教材只需在此注册数据源，
/// 所有页面/服务自动按 [id] 隔离数据，无需修改业务代码。
class TextbookRegistry {
  TextbookRegistry._();

  static const List<TextbookInfo> all = [
    TextbookInfo(
      id: 'nce1',
      name: '新概念1',
      lessonTitles: nce1LessonTitles,
      vocab: nce1Vocab,
    ),
    TextbookInfo(
      id: 'nce2',
      name: '新概念2',
      lessonTitles: nce2LessonTitles,
      vocab: nce2Vocab,
    ),
    TextbookInfo(
      id: 'nce3',
      name: '新概念3',
      lessonTitles: nce3LessonTitles,
      vocab: nce3Vocab,
    ),
  ];

  static TextbookInfo byId(String id) {
    return all.firstWhere(
      (t) => t.id == id,
      orElse: () => all.first,
    );
  }

  /// 构建课程列表：1 天 = 2 节课 = 单数新课 + 双数复习课
  static List<Lesson> lessonsOf(String textbookId) {
    final info = byId(textbookId);
    final List<Lesson> lessons = [];
    for (var i = 0; i < info.lessonTitles.length; i++) {
      final number = i + 1;
      final dayNumber = (number / 2).ceil();
      final type = number.isOdd ? 'new' : 'review';
      lessons.add(Lesson(
        number: number,
        title: info.lessonTitles[i],
        type: type,
        group: dayNumber,
        dayNumber: dayNumber,
      ));
    }
    return lessons;
  }

  /// 获取指定天的课程列表（如第1天 -> [L1, L2]）
  static List<Lesson> lessonsOfDay(String textbookId, int dayNumber) {
    final lessons = lessonsOf(textbookId);
    return lessons.where((l) => l.dayNumber == dayNumber).toList();
  }

  /// 获取指定天的所有课程号（如第1天 -> [1, 2]）
  static List<int> lessonNumbersOfDay(String textbookId, int dayNumber) {
    return lessonsOfDay(textbookId, dayNumber)
        .map((l) => l.number)
        .toList();
  }

  /// 获取指定天的单词列表
  static List<VocabWord> vocabOfDay(String textbookId, int dayNumber) {
    final info = byId(textbookId);
    return info.vocab.where((v) => v.dayNumber == dayNumber).toList();
  }

  static List<VocabWord> vocabOf(String textbookId) => byId(textbookId).vocab;

  /// 更新词库中每个单词的 dayNumber 字段
  /// 因为词库数据可能未设置 dayNumber，这里按 lessonNumber 自动推算
  static List<VocabWord> vocabWithDayNumber(String textbookId) {
    final info = byId(textbookId);
    return info.vocab.map((v) {
      final day = (v.lessonNumber / 2).ceil();
      return VocabWord(
        word: v.word,
        phonetic: v.phonetic,
        meaning: v.meaning,
        lessonNumber: v.lessonNumber,
        dayNumber: day,
      );
    }).toList();
  }
}
