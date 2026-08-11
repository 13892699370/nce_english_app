import 'package:hive/hive.dart';

/// 应用设置（主题模式、当前教材、各教材当前学习天数）
class AppSettings {
  String selectedTextbook; // nce1 | nce2 | nce3
  String themeMode; // system | light | dark

  /// 各教材当前学习天数，key=教材id，value=天数（从1开始）
  Map<String, int> currentDayByTextbook;

  AppSettings({
    this.selectedTextbook = 'nce1',
    this.themeMode = 'system',
    this.currentDayByTextbook = const {},
  });

  /// 获取指定教材的当前天数，默认从第1天开始
  int currentDayOf(String textbookId) => currentDayByTextbook[textbookId] ?? 1;

  /// 设置指定教材的当前天数
  void setCurrentDay(String textbookId, int day) {
    currentDayByTextbook[textbookId] = day;
  }
}

/// AppSettings 的 Hive TypeAdapter（手动编写，双端兼容）
class AppSettingsAdapter extends TypeAdapter<AppSettings> {
  @override
  final int typeId = 14;

  @override
  AppSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppSettings(
      selectedTextbook: (fields[0] as String?) ?? 'nce1',
      themeMode: (fields[1] as String?) ?? 'system',
      currentDayByTextbook: (fields[2] as Map?)?.cast<String, int>() ?? {},
    );
  }

  @override
  void write(BinaryWriter writer, AppSettings obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.selectedTextbook)
      ..writeByte(1)
      ..write(obj.themeMode)
      ..writeByte(2)
      ..write(obj.currentDayByTextbook);
  }
}
