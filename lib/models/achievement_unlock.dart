import 'package:hive/hive.dart';

/// 成就解锁记录
class AchievementUnlock {
  final String achievementId;

  /// 解锁时间 yyyy-MM-dd HH:mm:ss
  final String unlockedAt;

  AchievementUnlock({
    required this.achievementId,
    required this.unlockedAt,
  });

  String get key => achievementId;
}

/// AchievementUnlock 的 Hive TypeAdapter（手动编写，双端兼容）
class AchievementUnlockAdapter extends TypeAdapter<AchievementUnlock> {
  @override
  final int typeId = 13;

  @override
  AchievementUnlock read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AchievementUnlock(
      achievementId: fields[0] as String,
      unlockedAt: fields[1] as String,
    );
  }

  @override
  void write(BinaryWriter writer, AchievementUnlock obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.achievementId)
      ..writeByte(1)
      ..write(obj.unlockedAt);
  }
}
