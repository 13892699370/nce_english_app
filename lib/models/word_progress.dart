import 'package:hive/hive.dart';

/// 单词学习进度
///
/// 每个单词一条记录，按 [textbook] 隔离。
/// 点“不认识” -> 加入复习队列；点“认识” -> 降低复习优先级。
class WordProgress {
  final String word;
  final String textbook;

  /// 熟悉度 0~5，越大越熟悉
  int familiarity;

  /// 上次复习日期 yyyy-MM-dd
  String lastReviewDate;

  /// 复习次数
  int reviewCount;

  /// 是否在生词本
  bool inNotebook;

  /// 是否已学习过
  bool learned;

  WordProgress({
    required this.word,
    required this.textbook,
    this.familiarity = 0,
    this.lastReviewDate = '',
    this.reviewCount = 0,
    this.inNotebook = false,
    this.learned = false,
  });

  /// 主键：教材 + 单词
  String get key => '${textbook}_$word';

  /// 是否待复习：已学习过且熟悉度 < 4
  bool get needReview => learned && familiarity < 4;
}

/// WordProgress 的 Hive TypeAdapter（手动编写，双端兼容）
class WordProgressAdapter extends TypeAdapter<WordProgress> {
  @override
  final int typeId = 12;

  @override
  WordProgress read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WordProgress(
      word: fields[0] as String,
      textbook: fields[1] as String,
      familiarity: (fields[2] as int?) ?? 0,
      lastReviewDate: (fields[3] as String?) ?? '',
      reviewCount: (fields[4] as int?) ?? 0,
      inNotebook: (fields[5] as bool?) ?? false,
      learned: (fields[6] as bool?) ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, WordProgress obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.word)
      ..writeByte(1)
      ..write(obj.textbook)
      ..writeByte(2)
      ..write(obj.familiarity)
      ..writeByte(3)
      ..write(obj.lastReviewDate)
      ..writeByte(4)
      ..write(obj.reviewCount)
      ..writeByte(5)
      ..write(obj.inNotebook)
      ..writeByte(6)
      ..write(obj.learned);
  }
}
