import 'package:hive/hive.dart';

/// 新概念学习打卡记录
///
/// 一条记录 = 某教材某天某课程的打卡。
/// 预习任务 2 项、正式学习 4 项、复习任务 3 项。
/// 不同教材数据通过 [textbook] 字段隔离。
class LessonCheckin {
  final String textbook;
  final String date; // yyyy-MM-dd
  final int lessonNumber;

  /// 预习任务完成状态（2 项）
  List<bool> previewTasks;

  /// 正式学习任务完成状态（4 项）
  List<bool> formalTasks;

  /// 复习任务完成状态（3 项）
  List<bool> reviewTasks;

  /// 仿写句子
  String imitationSentence;

  /// 创建时间戳（用于排序与成就统计）
  final String createdAt;

  LessonCheckin({
    required this.textbook,
    required this.date,
    required this.lessonNumber,
    required this.previewTasks,
    required this.formalTasks,
    required this.reviewTasks,
    this.imitationSentence = '',
    required this.createdAt,
  });

  /// 主键：教材 + 日期 + 课程号，保证唯一且按教材隔离
  String get key => '${textbook}_$date\_$lessonNumber';

  bool get isAllDone =>
      previewTasks.every((e) => e) &&
      formalTasks.every((e) => e) &&
      reviewTasks.every((e) => e);

  int get doneCount =>
      [...previewTasks, ...formalTasks, ...reviewTasks]
          .where((e) => e)
          .length;

  int get totalTaskCount =>
      previewTasks.length + formalTasks.length + reviewTasks.length;
}

/// LessonCheckin 的 Hive TypeAdapter（手动编写，双端兼容，无需 build_runner）
class LessonCheckinAdapter extends TypeAdapter<LessonCheckin> {
  @override
  final int typeId = 11;

  @override
  LessonCheckin read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LessonCheckin(
      textbook: fields[0] as String,
      date: fields[1] as String,
      lessonNumber: fields[2] as int,
      previewTasks: (fields[3] as List).cast<bool>(),
      formalTasks: (fields[4] as List).cast<bool>(),
      reviewTasks: (fields[5] as List).cast<bool>(),
      imitationSentence: (fields[6] as String?) ?? '',
      createdAt: fields[7] as String,
    );
  }

  @override
  void write(BinaryWriter writer, LessonCheckin obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.textbook)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.lessonNumber)
      ..writeByte(3)
      ..write(obj.previewTasks)
      ..writeByte(4)
      ..write(obj.formalTasks)
      ..writeByte(5)
      ..write(obj.reviewTasks)
      ..writeByte(6)
      ..write(obj.imitationSentence)
      ..writeByte(7)
      ..write(obj.createdAt);
  }
}
