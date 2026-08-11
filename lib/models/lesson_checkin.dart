import 'package:hive/hive.dart';

/// 新概念学习打卡记录
///
/// 一条记录 = 某教材某天（dayNumber）的打卡，可包含多节课程。
/// 预习任务 2 项、正式学习 4 项、复习任务 3 项。
/// 不同教材数据通过 [textbook] 字段隔离。
class LessonCheckin {
  final String textbook;
  final String date; // yyyy-MM-dd
  final int dayNumber; // 第几天，从 1 开始
  final List<int> lessonNumbers; // 该天绑定的课程号列表，如 [1,2]

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
    required this.dayNumber,
    required this.lessonNumbers,
    required this.previewTasks,
    required this.formalTasks,
    required this.reviewTasks,
    this.imitationSentence = '',
    required this.createdAt,
  });

  /// 主键：教材 + 日期 + 天数，保证唯一且按教材隔离
  String get key => '${textbook}_$date\_day$dayNumber';

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
      dayNumber: (fields[2] as num?)?.toInt() ?? 1,
      lessonNumbers: (fields[3] as List?)?.cast<int>() ?? const [],
      previewTasks: (fields[4] as List?)?.cast<bool>() ??
          List<bool>.filled(kPreviewTaskCount, false),
      formalTasks: (fields[5] as List?)?.cast<bool>() ??
          List<bool>.filled(kFormalTaskCount, false),
      reviewTasks: (fields[6] as List?)?.cast<bool>() ??
          List<bool>.filled(kReviewTaskCount, false),
      imitationSentence: (fields[7] as String?) ?? '',
      createdAt: (fields[8] as String?) ?? '',
    );
  }

  @override
  void write(BinaryWriter writer, LessonCheckin obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.textbook)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.dayNumber)
      ..writeByte(3)
      ..write(obj.lessonNumbers)
      ..writeByte(4)
      ..write(obj.previewTasks)
      ..writeByte(5)
      ..write(obj.formalTasks)
      ..writeByte(6)
      ..write(obj.reviewTasks)
      ..writeByte(7)
      ..write(obj.imitationSentence)
      ..writeByte(8)
      ..write(obj.createdAt);
  }
}

const int kPreviewTaskCount = 2;
const int kFormalTaskCount = 4;
const int kReviewTaskCount = 3;
