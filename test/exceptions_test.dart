// 异常类单元测试
//
// 测试自定义异常类

import 'package:flutter_test/flutter_test.dart';
import 'package:tencentcloud_cos_sdk_plugin/exceptions.dart';

void main() {
  group('IllegalArgumentException 测试', () {
    test('IllegalArgumentException 应该是 Exception 的实现', () {
      final exception = IllegalArgumentException();
      expect(exception, isA<Exception>());
    });

    test('IllegalArgumentException 可以带有消息', () {
      final exception = IllegalArgumentException('参数不能为空');
      expect(exception, isA<Exception>());
    });

    test('IllegalArgumentException 可以不带消息', () {
      final exception = IllegalArgumentException();
      expect(exception, isA<Exception>());
    });

    test('应该能够在 try-catch 中捕获 IllegalArgumentException', () {
      expect(
        () => throw IllegalArgumentException('测试异常'),
        throwsA(isA<IllegalArgumentException>()),
      );
    });

    test('应该能够在 try-catch 中作为 Exception 捕获', () {
      expect(
        () => throw IllegalArgumentException('测试异常'),
        throwsA(isA<Exception>()),
      );
    });
  });
}
