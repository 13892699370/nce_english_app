import 'package:flutter/foundation.dart';
import 'storage_service.dart';
import '../data/textbook_registry.dart';

/// 当前教材选择服务
///
/// 持有当前选中的教材 id，切换时持久化并通知所有监听页面。
class TextbookService extends ChangeNotifier {
  TextbookService._();
  static final TextbookService instance = TextbookService._();

  String _currentId = 'nce1';

  String get currentId => _currentId;
  TextbookInfo get current => TextbookRegistry.byId(_currentId);

  void init() {
    final s = StorageService.instance.settings();
    _currentId = s.selectedTextbook;
  }

  Future<void> select(String id) async {
    if (_currentId == id) return;
    _currentId = id;
    final s = StorageService.instance.settings();
    s.selectedTextbook = id;
    await StorageService.instance.updateSettings(s);
    notifyListeners();
  }
}
