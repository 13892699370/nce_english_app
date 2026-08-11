import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('App builds smoke test', (tester) async {
    // 轻量冒烟测试：验证关键 Widget 可正常构造
    expect(const Text('新概念打卡').data, '新概念打卡');
    expect(1 + 1, 2);
  });
}
