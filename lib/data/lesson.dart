/// 课程单元模型
///
/// 规则：1 组 = 单数新课 + 双数复习课，例 L1+L2。
class Lesson {
  final int number;
  final String title;
  final String type; // 'new' 新课 | 'review' 复习课
  final int group; // 组号，从 1 开始

  const Lesson({
    required this.number,
    required this.title,
    required this.type,
    required this.group,
  });

  bool get isNew => type == 'new';
}

/// 单词模型
class VocabWord {
  final String word;
  final String phonetic; // 音标
  final String meaning; // 中文释义
  final int lessonNumber; // 所属课程号

  const VocabWord({
    required this.word,
    required this.phonetic,
    required this.meaning,
    required this.lessonNumber,
  });
}
