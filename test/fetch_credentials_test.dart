// Fetch Credentials 接口测试
//
// 测试 IFetchCredentials、IFetchScopeLimitCredentials、IFetchCLsChannelCredentials 接口

import 'package:flutter_test/flutter_test.dart';
import 'package:tencentcloud_cos_sdk_plugin/pigeon.dart';
import 'package:tencentcloud_cos_sdk_plugin/fetch_credentials.dart';

// Mock IFetchCredentials 实现
class TestFetchCredentials implements IFetchCredentials {
  int callCount = 0;
  
  @override
  Future<SessionQCloudCredentials> fetchSessionCredentials() async {
    callCount++;
    return SessionQCloudCredentials(
      secretId: 'test-secret-id',
      secretKey: 'test-secret-key',
      token: 'test-token',
      startTime: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      expiredTime: DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600,
    );
  }
}

// Mock IFetchScopeLimitCredentials 实现
class TestFetchScopeLimitCredentials implements IFetchScopeLimitCredentials {
  int callCount = 0;
  List<STSCredentialScope?>? lastScopes;
  
  @override
  Future<SessionQCloudCredentials> fetchScopeLimitCredentials(
      List<STSCredentialScope?> stsCredentialScopes) async {
    callCount++;
    lastScopes = stsCredentialScopes;
    return SessionQCloudCredentials(
      secretId: 'scope-secret-id',
      secretKey: 'scope-secret-key',
      token: 'scope-token',
      startTime: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      expiredTime: DateTime.now().millisecondsSinceEpoch ~/ 1000 + 1800,
    );
  }
}

// Mock IFetchCLsChannelCredentials 实现
class TestFetchCLsChannelCredentials implements IFetchCLsChannelCredentials {
  int callCount = 0;
  
  @override
  Future<SessionQCloudCredentials> fetchCLsChannelSessionCredentials() async {
    callCount++;
    return SessionQCloudCredentials(
      secretId: 'cls-secret-id',
      secretKey: 'cls-secret-key',
      token: 'cls-token',
      expiredTime: DateTime.now().millisecondsSinceEpoch ~/ 1000 + 7200,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('IFetchCredentials 接口测试', () {
    test('fetchSessionCredentials 应该返回有效凭证', () async {
      final fetcher = TestFetchCredentials();
      
      final credentials = await fetcher.fetchSessionCredentials();
      
      expect(credentials, isNotNull);
      expect(credentials.secretId, equals('test-secret-id'));
      expect(credentials.secretKey, equals('test-secret-key'));
      expect(credentials.token, equals('test-token'));
      expect(credentials.expiredTime, isPositive);
      expect(fetcher.callCount, equals(1));
    });

    test('多次调用 fetchSessionCredentials 应该正确计数', () async {
      final fetcher = TestFetchCredentials();
      
      await fetcher.fetchSessionCredentials();
      await fetcher.fetchSessionCredentials();
      await fetcher.fetchSessionCredentials();
      
      expect(fetcher.callCount, equals(3));
    });
  });

  group('IFetchScopeLimitCredentials 接口测试', () {
    test('fetchScopeLimitCredentials 应该返回有效凭证', () async {
      final fetcher = TestFetchScopeLimitCredentials();
      
      final scopes = [
        STSCredentialScope(
          action: 'PutObject',
          region: 'ap-guangzhou',
          bucket: 'test-bucket-1250000000',
          prefix: 'upload/*',
        ),
      ];
      
      final credentials = await fetcher.fetchScopeLimitCredentials(scopes);
      
      expect(credentials, isNotNull);
      expect(credentials.secretId, equals('scope-secret-id'));
      expect(credentials.secretKey, equals('scope-secret-key'));
      expect(credentials.token, equals('scope-token'));
      expect(fetcher.callCount, equals(1));
    });

    test('fetchScopeLimitCredentials 应该接收正确的 scopes', () async {
      final fetcher = TestFetchScopeLimitCredentials();
      
      final scopes = [
        STSCredentialScope(
          action: 'PutObject',
          region: 'ap-guangzhou',
          bucket: 'test-bucket-1250000000',
          prefix: 'upload/*',
        ),
        STSCredentialScope(
          action: 'GetObject',
          region: 'ap-beijing',
          bucket: 'test-bucket-1250000000',
          prefix: 'download/*',
        ),
      ];
      
      await fetcher.fetchScopeLimitCredentials(scopes);
      
      expect(fetcher.lastScopes, isNotNull);
      expect(fetcher.lastScopes?.length, equals(2));
      expect(fetcher.lastScopes?[0]?.action, equals('PutObject'));
      expect(fetcher.lastScopes?[1]?.action, equals('GetObject'));
    });

    test('fetchScopeLimitCredentials 应该处理空 scopes', () async {
      final fetcher = TestFetchScopeLimitCredentials();
      
      final credentials = await fetcher.fetchScopeLimitCredentials([]);
      
      expect(credentials, isNotNull);
      expect(fetcher.lastScopes?.isEmpty, isTrue);
    });

    test('fetchScopeLimitCredentials 应该处理包含 null 的 scopes', () async {
      final fetcher = TestFetchScopeLimitCredentials();
      
      final scopes = <STSCredentialScope?>[
        STSCredentialScope(
          action: 'PutObject',
          region: 'ap-guangzhou',
          bucket: 'test-bucket',
          prefix: '*',
        ),
        null,
      ];
      
      final credentials = await fetcher.fetchScopeLimitCredentials(scopes);
      
      expect(credentials, isNotNull);
      expect(fetcher.lastScopes?.length, equals(2));
      expect(fetcher.lastScopes?[1], isNull);
    });
  });

  group('IFetchCLsChannelCredentials 接口测试', () {
    test('fetchCLsChannelSessionCredentials 应该返回有效凭证', () async {
      final fetcher = TestFetchCLsChannelCredentials();
      
      final credentials = await fetcher.fetchCLsChannelSessionCredentials();
      
      expect(credentials, isNotNull);
      expect(credentials.secretId, equals('cls-secret-id'));
      expect(credentials.secretKey, equals('cls-secret-key'));
      expect(credentials.token, equals('cls-token'));
      expect(credentials.expiredTime, isPositive);
      expect(fetcher.callCount, equals(1));
    });

    test('多次调用 fetchCLsChannelSessionCredentials 应该正确计数', () async {
      final fetcher = TestFetchCLsChannelCredentials();
      
      await fetcher.fetchCLsChannelSessionCredentials();
      await fetcher.fetchCLsChannelSessionCredentials();
      
      expect(fetcher.callCount, equals(2));
    });
  });

  group('凭证接口组合测试', () {
    test('不同类型的凭证提供器应该能同时工作', () async {
      final sessionFetcher = TestFetchCredentials();
      final scopeFetcher = TestFetchScopeLimitCredentials();
      final clsFetcher = TestFetchCLsChannelCredentials();
      
      final sessionCredentials = await sessionFetcher.fetchSessionCredentials();
      final scopeCredentials = await scopeFetcher.fetchScopeLimitCredentials([
        STSCredentialScope(
          action: 'PutObject',
          region: 'ap-guangzhou',
          bucket: 'bucket',
          prefix: '*',
        ),
      ]);
      final clsCredentials = await clsFetcher.fetchCLsChannelSessionCredentials();
      
      expect(sessionCredentials.secretId, equals('test-secret-id'));
      expect(scopeCredentials.secretId, equals('scope-secret-id'));
      expect(clsCredentials.secretId, equals('cls-secret-id'));
    });
  });
}
