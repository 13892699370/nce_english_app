import 'package:flutter/services.dart';

/// 跨平台统一触觉反馈服务
///
/// 设备不支持震动时自动降级，不崩溃不报错。
/// Android / iOS 行为一致：调用系统 HapticFeedback API，
/// 权限由 AndroidManifest.xml 声明（VIBRATE），iOS 无需额外权限。
class HapticService {
  HapticService._();

  /// 轻量反馈（按钮点击）
  static Future<void> light() async {
    try {
      await HapticFeedback.lightImpact();
    } on Exception {
      // 降级：静默忽略
    }
  }

  /// 中等反馈（选中切换）
  static Future<void> selection() async {
    try {
      await HapticFeedback.selectionClick();
    } on Exception {
      // 降级
    }
  }

  /// 中等反馈（跳转、完成等）
  static Future<void> medium() async {
    try {
      await HapticFeedback.mediumImpact();
    } on Exception {
      // 降级
    }
  }

  /// 重度反馈（成就解锁、完成提交）
  static Future<void> heavy() async {
    try {
      await HapticFeedback.heavyImpact();
    } on Exception {
      // 降级
    }
  }

  /// 成就解锁庆典震感
  static Future<void> celebrate() async {
    try {
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 120));
      await HapticFeedback.mediumImpact();
      await Future.delayed(const Duration(milliseconds: 120));
      await HapticFeedback.lightImpact();
    } on Exception {
      // 降级
    }
  }
}
