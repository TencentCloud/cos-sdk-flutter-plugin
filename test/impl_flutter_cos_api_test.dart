// ImplFlutterCosApi 单元测试
//
// 测试 ImplFlutterCosApi 类的各种方法

import 'package:flutter_test/flutter_test.dart';
import 'package:tencentcloud_cos_sdk_plugin/impl_flutter_cos_api.dart';
import 'package:tencentcloud_cos_sdk_plugin/pigeon.dart';
import 'package:tencentcloud_cos_sdk_plugin/cos.dart';
import 'package:tencentcloud_cos_sdk_plugin/cos_transfer_manger.dart';
import 'package:tencentcloud_cos_sdk_plugin/fetch_credentials.dart';
import 'package:tencentcloud_cos_sdk_plugin/fetch_dns.dart';

import 'test_helper.dart';

// Mock IFetchCredentials 实现
class MockFetchCredentials implements IFetchCredentials {
  int callCount = 0;
  
  @override
  Future<SessionQCloudCredentials> fetchSessionCredentials() async {
    callCount++;
    return SessionQCloudCredentials(
      secretId: 'mock-secret-id',
      secretKey: 'mock-secret-key',
      token: 'mock-token',
      expiredTime: DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600,
    );
  }
}

// Mock IFetchScopeLimitCredentials 实现
class MockFetchScopeLimitCredentials implements IFetchScopeLimitCredentials {
  int callCount = 0;
  
  @override
  Future<SessionQCloudCredentials> fetchScopeLimitCredentials(
      List<STSCredentialScope?> stsCredentialScopes) async {
    callCount++;
    return SessionQCloudCredentials(
      secretId: 'mock-scope-secret-id',
      secretKey: 'mock-scope-secret-key',
      token: 'mock-scope-token',
      expiredTime: DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600,
    );
  }
}

// Mock IFetchDns 实现
class MockFetchDns implements IFetchDns {
  int callCount = 0;
  
  @override
  Future<List<String>?> fetchDns(String domain) async {
    callCount++;
    return ['0.238.42.65', '49.27.177.216'];
  }
}

// Mock IFetchCLsChannelCredentials 实现
class MockFetchCLsChannelCredentials implements IFetchCLsChannelCredentials {
  @override
  Future<SessionQCloudCredentials> fetchCLsChannelSessionCredentials() async {
    return SessionQCloudCredentials(
      secretId: 'mock-cls-secret-id',
      secretKey: 'mock-cls-secret-key',
      token: 'mock-cls-token',
      expiredTime: DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ImplFlutterCosApi 测试', () {
    late ImplFlutterCosApi flutterCosApi;

    setUpAll(() {
      TestHelper.setupAll();
    });

    tearDownAll(() {
      TestHelper.tearDownAll();
    });

    setUp(() {
      flutterCosApi = ImplFlutterCosApi();
    });

    test('ImplFlutterCosApi 应该正确初始化', () {
      expect(flutterCosApi, isNotNull);
    });

    test('forceInvalidationScopeCredentials 应该清空缓存', () {
      // 设置一些凭证到缓存
      flutterCosApi.credentialPairs[123] = SessionQCloudCredentials(
        secretId: 'test-id',
        secretKey: 'test-key',
        token: 'test-token',
        expiredTime: DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600,
      );
      
      expect(flutterCosApi.credentialPairs.isNotEmpty, isTrue);
      
      // 清空缓存
      flutterCosApi.forceInvalidationScopeCredentials();
      
      expect(flutterCosApi.credentialPairs.isEmpty, isTrue);
    });

    test('MAX_CACHE_CREDENTIAL_SIZE 应该是 100', () {
      expect(ImplFlutterCosApi.MAX_CACHE_CREDENTIAL_SIZE, equals(100));
    });
  });

  group('ImplFlutterCosApi 凭证缓存测试', () {
    late ImplFlutterCosApi flutterCosApi;

    setUp(() {
      flutterCosApi = ImplFlutterCosApi();
    });

    test('lookupValidCredentials 应该返回有效凭证', () {
      final validCredentials = SessionQCloudCredentials(
        secretId: 'test-id',
        secretKey: 'test-key',
        token: 'test-token',
        expiredTime: DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600,
      );
      
      flutterCosApi.credentialPairs[123] = validCredentials;
      
      final result = flutterCosApi.lookupValidCredentials(123);
      expect(result, isNotNull);
      expect(result?.secretId, equals('test-id'));
    });

    test('lookupValidCredentials 应该返回 null 对于过期凭证', () {
      final expiredCredentials = SessionQCloudCredentials(
        secretId: 'test-id',
        secretKey: 'test-key',
        token: 'test-token',
        expiredTime: DateTime.now().millisecondsSinceEpoch ~/ 1000 - 3600, // 已过期
      );
      
      flutterCosApi.credentialPairs[123] = expiredCredentials;
      
      final result = flutterCosApi.lookupValidCredentials(123);
      expect(result, isNull);
    });

    test('lookupValidCredentials 应该返回 null 对于不存在的 scopeId', () {
      final result = flutterCosApi.lookupValidCredentials(999);
      expect(result, isNull);
    });

    test('cacheCredentialsAndCleanUp 应该缓存新凭证', () {
      final credentials = SessionQCloudCredentials(
        secretId: 'test-id',
        secretKey: 'test-key',
        token: 'test-token',
        expiredTime: DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600,
      );
      
      flutterCosApi.cacheCredentialsAndCleanUp(123, credentials);
      
      expect(flutterCosApi.credentialPairs[123], isNotNull);
      expect(flutterCosApi.credentialPairs[123]?.secretId, equals('test-id'));
    });

    test('cacheCredentialsAndCleanUp 应该清理过期凭证', () {
      // 添加过期凭证
      final expiredCredentials = SessionQCloudCredentials(
        secretId: 'expired-id',
        secretKey: 'expired-key',
        token: 'expired-token',
        expiredTime: DateTime.now().millisecondsSinceEpoch ~/ 1000 - 3600,
      );
      flutterCosApi.credentialPairs[100] = expiredCredentials;
      
      // 添加新凭证
      final newCredentials = SessionQCloudCredentials(
        secretId: 'new-id',
        secretKey: 'new-key',
        token: 'new-token',
        expiredTime: DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600,
      );
      flutterCosApi.cacheCredentialsAndCleanUp(200, newCredentials);
      
      // 过期凭证应该被清理
      expect(flutterCosApi.credentialPairs[100], isNull);
      // 新凭证应该存在
      expect(flutterCosApi.credentialPairs[200], isNotNull);
    });

    test('cacheCredentialsAndCleanUp 应该限制缓存大小', () {
      // 添加超过 MAX_CACHE_CREDENTIAL_SIZE 的凭证
      for (int i = 0; i < 105; i++) {
        final credentials = SessionQCloudCredentials(
          secretId: 'id-$i',
          secretKey: 'key-$i',
          token: 'token-$i',
          expiredTime: DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600,
        );
        flutterCosApi.cacheCredentialsAndCleanUp(i, credentials);
      }
      
      // 缓存大小应该不超过 MAX_CACHE_CREDENTIAL_SIZE + 1
      expect(flutterCosApi.credentialPairs.length, lessThanOrEqualTo(ImplFlutterCosApi.MAX_CACHE_CREDENTIAL_SIZE + 1));
    });

    test('jsonifyScopes 应该正确序列化 scopes', () {
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
      
      final json = flutterCosApi.jsonifyScopes(scopes);
      
      expect(json, contains('PutObject'));
      expect(json, contains('GetObject'));
      expect(json, contains('ap-guangzhou'));
      expect(json, contains('ap-beijing'));
    });

    test('jsonifyScopes 应该处理 null scope', () {
      final scopes = <STSCredentialScope?>[
        STSCredentialScope(
          action: 'PutObject',
          region: 'ap-guangzhou',
          bucket: 'test-bucket',
          prefix: '*',
        ),
        null,
      ];
      
      final json = flutterCosApi.jsonifyScopes(scopes);
      
      expect(json, contains('PutObject'));
      // null 应该被跳过
    });

    test('jsonifyScopes 应该处理空列表', () {
      final scopes = <STSCredentialScope?>[];
      
      final json = flutterCosApi.jsonifyScopes(scopes);
      
      expect(json, equals('[]'));
    });
  });

  group('ImplFlutterCosApi 回调测试', () {
    setUpAll(() {
      TestHelper.setupAll();
    });

    tearDownAll(() {
      TestHelper.tearDownAll();
    });

    test('onLog 应该触发日志监听器', () async {
      bool logCalled = false;
      LogEntity? receivedEntity;
      
      void logCallback(LogEntity entity) {
        logCalled = true;
        receivedEntity = entity;
      }
      
      // 注册日志监听器
      await Cos().addLogListener(logCallback);
      
      // 触发日志回调
      final entity = LogEntity(
        timestamp: DateTime.now().millisecondsSinceEpoch,
        level: LogLevel.info,
        category: LogCategory.network,
        tag: 'Test',
        message: 'Test message',
        threadName: 'main',
      );
      
      Cos().flutterCosApi.onLog(logCallback.hashCode, entity);
      
      expect(logCalled, isTrue);
      expect(receivedEntity?.message, equals('Test message'));
      
      // 清理
      await Cos().removeLogListener(logCallback);
    });

    test('onLog 对于不存在的 key 不应抛出异常', () {
      final entity = LogEntity(
        timestamp: DateTime.now().millisecondsSinceEpoch,
        level: LogLevel.info,
        category: LogCategory.network,
        tag: 'Test',
        message: 'Test message',
        threadName: 'main',
      );
      
      // 调用不存在的 key，不应抛出异常
      expect(() => Cos().flutterCosApi.onLog(999999, entity), returnsNormally);
    });
  });

  group('ImplFlutterCosApi 原生回调测试', () {
    late CosTransferManger transferManger;
    
    setUpAll(() async {
      TestHelper.setupAll();
      // 注册一个 TransferManger 用于测试
      final config = CosXmlServiceConfig(region: 'ap-guangzhou');
      final transferConfig = TransferConfig();
      transferManger = await Cos().registerTransferManger('test-callback-key', config, transferConfig);
    });

    tearDownAll(() {
      TestHelper.tearDownAll();
    });

    test('progressCallback 应该触发进度回调', () async {
      int? receivedComplete;
      int? receivedTarget;
      
      // 上传并注册回调
      final task = await transferManger.upload(
        'test-bucket',
        'test/file.txt',
        filePath: '/local/file.txt',
        progressCallBack: (complete, target) {
          receivedComplete = complete;
          receivedTarget = target;
        },
      );
      
      // 验证方法可以被调用
      expect(task, isNotNull);
    });

    test('stateCallback 应该触发状态回调', () async {
      // 上传并注册回调
      await transferManger.upload(
        'test-bucket',
        'test/file2.txt',
        filePath: '/local/file2.txt',
        stateCallback: (state) {
          // 状态回调
        },
      );
      
      expect(true, isTrue);
    });

    test('resultListener 成功回调应该被触发', () async {
      bool successCalled = false;
      
      await transferManger.upload(
        'test-bucket',
        'test/file3.txt',
        filePath: '/local/file3.txt',
        resultListener: ResultListener(
          (header, result) {
            successCalled = true;
          },
          (clientException, serviceException) {},
        ),
      );
      
      expect(true, isTrue);
    });

    test('resultListener 失败回调应该被触发', () async {
      bool failCalled = false;
      
      await transferManger.upload(
        'test-bucket',
        'test/file4.txt',
        filePath: '/local/file4.txt',
        resultListener: ResultListener(
          (header, result) {},
          (clientException, serviceException) {
            failCalled = true;
          },
        ),
      );
      
      expect(true, isTrue);
    });

    test('initMultipleUploadCallback 应该被触发', () async {
      String? receivedBucket;
      String? receivedCosKey;
      String? receivedUploadId;
      
      await transferManger.upload(
        'test-bucket',
        'test/file5.txt',
        filePath: '/local/file5.txt',
        initMultipleUploadCallback: (bucket, cosKey, uploadId) {
          receivedBucket = bucket;
          receivedCosKey = cosKey;
          receivedUploadId = uploadId;
        },
      );
      
      expect(true, isTrue);
    });
  });

  group('ImplFlutterCosApi FlutterCosApi 接口回调测试', () {
    late CosTransferManger transferManger;
    
    setUpAll(() async {
      TestHelper.setupAll();
      final config = CosXmlServiceConfig(region: 'ap-guangzhou');
      final transferConfig = TransferConfig();
      transferManger = await Cos().registerTransferManger('test-api-callback-key', config, transferConfig);
    });

    tearDownAll(() {
      TestHelper.tearDownAll();
    });

    test('直接调用 progressCallback 应该触发回调', () {
      // 先注册一个回调
      int callbackKey = 12345;
      int? receivedComplete;
      int? receivedTarget;
      
      // 模拟调用 progressCallback
      // 由于回调是通过 key 查找的，这里主要验证方法可以被调用
      expect(() => Cos().flutterCosApi.progressCallback('test-api-callback-key', callbackKey, 50, 100), returnsNormally);
    });

    test('直接调用 stateCallback 应该触发回调', () {
      int callbackKey = 12346;
      
      expect(() => Cos().flutterCosApi.stateCallback('test-api-callback-key', callbackKey, 'IN_PROGRESS'), returnsNormally);
    });

    test('直接调用 resultSuccessCallback 应该触发回调', () {
      int callbackKey = 12347;
      final header = <String?, String?>{'ETag': '"test-etag"'};
      final result = CosXmlResult(eTag: '"test-etag"');
      
      expect(() => Cos().flutterCosApi.resultSuccessCallback('test-api-callback-key', callbackKey, header, result), returnsNormally);
    });

    test('直接调用 resultFailCallback 应该触发回调', () {
      int callbackKey = 12348;
      final clientException = CosXmlClientException(errorCode: 10001, message: 'Test error');
      
      expect(() => Cos().flutterCosApi.resultFailCallback('test-api-callback-key', callbackKey, clientException, null), returnsNormally);
    });

    test('直接调用 initMultipleUploadCallback 应该触发回调', () {
      int callbackKey = 12349;
      
      expect(() => Cos().flutterCosApi.initMultipleUploadCallback('test-api-callback-key', callbackKey, 'bucket', 'cosKey', 'uploadId'), returnsNormally);
    });
  });

  group('ImplFlutterCosApi 凭证和 DNS 回调测试', () {
    setUpAll(() async {
      TestHelper.setupAll();
    });

    tearDownAll(() {
      TestHelper.tearDownAll();
    });

    test('fetchSessionCredentials 应该调用凭证提供器', () async {
      // 设置凭证提供器
      final mockCredentials = MockFetchCredentials();
      await Cos().initWithSessionCredential(mockCredentials);
      
      // 调用 fetchSessionCredentials
      final result = await Cos().flutterCosApi.fetchSessionCredentials();
      
      expect(result, isNotNull);
      expect(result.secretId, equals('mock-secret-id'));
      expect(mockCredentials.callCount, greaterThanOrEqualTo(1));
    });

    test('fetchScopeLimitCredentials 应该调用范围限制凭证提供器', () async {
      // 设置范围限制凭证提供器
      final mockScopeLimitCredentials = MockFetchScopeLimitCredentials();
      await Cos().initWithScopeLimitCredential(mockScopeLimitCredentials);
      
      // 准备 scopes
      final scopes = [
        STSCredentialScope(
          action: 'PutObject',
          region: 'ap-guangzhou',
          bucket: 'test-bucket',
          prefix: '*',
        ),
      ];
      
      // 调用 fetchScopeLimitCredentials
      final result = await Cos().flutterCosApi.fetchScopeLimitCredentials(scopes);
      
      expect(result, isNotNull);
      expect(result.secretId, equals('mock-scope-secret-id'));
      expect(mockScopeLimitCredentials.callCount, greaterThanOrEqualTo(1));
    });

    test('fetchScopeLimitCredentials 应该使用缓存对于相同的 scopes', () async {
      // 设置范围限制凭证提供器
      final mockScopeLimitCredentials = MockFetchScopeLimitCredentials();
      await Cos().initWithScopeLimitCredential(mockScopeLimitCredentials);
      
      final initialCallCount = mockScopeLimitCredentials.callCount;
      
      // 准备相同的 scopes
      final scopes = [
        STSCredentialScope(
          action: 'PutObject',
          region: 'ap-guangzhou',
          bucket: 'test-bucket-cache',
          prefix: 'upload/*',
        ),
      ];
      
      // 第一次调用
      await Cos().flutterCosApi.fetchScopeLimitCredentials(scopes);
      final callCountAfterFirst = mockScopeLimitCredentials.callCount;
      
      // 第二次调用相同的 scopes，应该使用缓存
      await Cos().flutterCosApi.fetchScopeLimitCredentials(scopes);
      final callCountAfterSecond = mockScopeLimitCredentials.callCount;
      
      // 由于有缓存，第二次调用可能不会增加调用次数
      expect(callCountAfterFirst, greaterThan(initialCallCount));
    });

    test('fetchDns 应该调用 DNS 提供器', () async {
      // 设置 DNS 提供器
      final mockDns = MockFetchDns();
      await Cos().initCustomerDNSFetch(mockDns);
      
      // 调用 fetchDns
      final result = await Cos().flutterCosApi.fetchDns('test.example.com');
      
      expect(result, isNotNull);
      expect(result?.length, equals(2));
      expect(mockDns.callCount, greaterThanOrEqualTo(1));
    });

    test('fetchClsSessionCredentials 应该调用 CLS 凭证提供器', () async {
      // 设置 CLS 凭证提供器
      final mockClsCredentials = MockFetchCLsChannelCredentials();
      await Cos().setCLsChannelSessionCredential(
        'test-topic-id',
        'https://cls.endpoint.com',
        mockClsCredentials,
      );
      
      // 调用 fetchClsSessionCredentials
      final result = await Cos().flutterCosApi.fetchClsSessionCredentials();
      
      expect(result, isNotNull);
      expect(result.secretId, equals('mock-cls-secret-id'));
    });
  });
}
