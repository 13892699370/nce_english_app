import 'package:hive/hive.dart';

/// 应用设置（主题模式、当前教材）
class AppSettings {
  String selectedTextbook; // nce1 | nce2 | nce3
  String themeMode; // system | light | dark

  AppSettings({
    this.selectedTextbook = 'nce1',
    this.themeMode = 'system',
  });
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
    );
  }

  @override
  void write(BinaryWriter writer, AppSettings obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.selectedTextbook)
      ..writeByte(1)
      ..write(obj.themeMode);
  }
}
