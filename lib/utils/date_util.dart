/// 日期/时间格式化工具（避免 intl 依赖带来的版本冲突）
class DateUtil {
  DateUtil._();

  /// yyyy-MM-dd
  static String date(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}'
      '-${d.month.toString().padLeft(2, '0')}'
      '-${d.day.toString().padLeft(2, '0')}';

  /// yyyy-MM-dd HH:mm:ss
  static String dateTime(DateTime d) =>
      '${date(d)} '
      '${d.hour.toString().padLeft(2, '0')}'
      ':${d.minute.toString().padLeft(2, '0')}'
      ':${d.second.toString().padLeft(2, '0')}';

  /// 今天的日期字符串
  static String today() => date(DateTime.now());
}
