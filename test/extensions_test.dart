// Extensions 单元测试
//
// 测试 SessionQCloudCredentials 扩展方法

import 'package:flutter_test/flutter_test.dart';
import 'package:tencentcloud_cos_sdk_plugin/pigeon.dart';
import 'package:tencentcloud_cos_sdk_plugin/extensions.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SessionQCloudCredentialsExtension 测试', () {
    test('isValid 应该返回 true 对于未过期凭证', () {
      final credentials = SessionQCloudCredentials(
        secretId: 'test-id',
        secretKey: 'test-key',
        token: 'test-token',
        expiredTime: DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600, // 1小时后过期
      );
      
      expect(credentials.isValid(), isTrue);
    });

    test('isValid 应该返回 false 对于已过期凭证', () {
      final credentials = SessionQCloudCredentials(
        secretId: 'test-id',
        secretKey: 'test-key',
        token: 'test-token',
        expiredTime: DateTime.now().millisecondsSinceEpoch ~/ 1000 - 3600, // 1小时前已过期
      );
      
      expect(credentials.isValid(), isFalse);
    });

    test('isValid 应该返回 false 对于即将过期凭证（60秒内）', () {
      final credentials = SessionQCloudCredentials(
        secretId: 'test-id',
        secretKey: 'test-key',
        token: 'test-token',
        expiredTime: DateTime.now().millisecondsSinceEpoch ~/ 1000 + 30, // 30秒后过期
      );
      
      // 因为有 60 秒的缓冲期，30秒后过期的凭证应该被认为无效
      expect(credentials.isValid(), isFalse);
    });

    test('isValid 应该返回 true 对于刚好超过缓冲期的凭证', () {
      final credentials = SessionQCloudCredentials(
        secretId: 'test-id',
        secretKey: 'test-key',
        token: 'test-token',
        expiredTime: DateTime.now().millisecondsSinceEpoch ~/ 1000 + 120, // 120秒后过期
      );
      
      // 超过 60 秒缓冲期，应该有效
      expect(credentials.isValid(), isTrue);
    });

    test('isValid 边界测试：刚好在 60 秒缓冲期边界', () {
      final credentials = SessionQCloudCredentials(
        secretId: 'test-id',
        secretKey: 'test-key',
        token: 'test-token',
        expiredTime: DateTime.now().millisecondsSinceEpoch ~/ 1000 + 60, // 刚好60秒后过期
      );
      
      // timestamp <= expiredTime - 60，刚好等于应该返回 true
      expect(credentials.isValid(), isTrue);
    });

    test('isValid 边界测试：59 秒后过期', () {
      final credentials = SessionQCloudCredentials(
        secretId: 'test-id',
        secretKey: 'test-key',
        token: 'test-token',
        expiredTime: DateTime.now().millisecondsSinceEpoch ~/ 1000 + 59, // 59秒后过期
      );
      
      // 小于 60 秒缓冲期，应该无效
      expect(credentials.isValid(), isFalse);
    });

    test('isValid 应该处理当前时间戳', () {
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      
      // 凭证刚好当前时间过期
      final expiredNow = SessionQCloudCredentials(
        secretId: 'test-id',
        secretKey: 'test-key',
        token: 'test-token',
        expiredTime: now,
      );
      expect(expiredNow.isValid(), isFalse);
      
      // 凭证在当前时间后很久过期
      final validLater = SessionQCloudCredentials(
        secretId: 'test-id',
        secretKey: 'test-key',
        token: 'test-token',
        expiredTime: now + 7200, // 2小时后
      );
      expect(validLater.isValid(), isTrue);
    });
  });
}
