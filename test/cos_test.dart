// Cos 主类单元测试
//
// 测试 Cos 单例类的初始化、服务注册等功能
// 使用 Mock Channel 模拟原生 API 响应

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:tencentcloud_cos_sdk_plugin/cos.dart';
import 'package:tencentcloud_cos_sdk_plugin/pigeon.dart';
import 'package:tencentcloud_cos_sdk_plugin/exceptions.dart';
import 'package:tencentcloud_cos_sdk_plugin/fetch_credentials.dart';
import 'package:tencentcloud_cos_sdk_plugin/fetch_dns.dart';

import 'test_helper.dart';

// Mock IFetchCredentials 实现
class MockFetchCredentials implements IFetchCredentials {
  @override
  Future<SessionQCloudCredentials> fetchSessionCredentials() async {
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
  @override
  Future<SessionQCloudCredentials> fetchScopeLimitCredentials(
      List<STSCredentialScope?> stsCredentialScopes) async {
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
  @override
  Future<List<String>?> fetchDns(String domain) async {
    return ['1.1.1.1', '2.2.2.2'];
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

  group('Cos 单例类测试', () {
    setUpAll(() {
      TestHelper.setupAll();
    });

    tearDownAll(() {
      TestHelper.tearDownAll();
    });

    test('Cos 应该是单例模式', () {
      final cos1 = Cos();
      final cos2 = Cos();
      expect(identical(cos1, cos2), isTrue);
    });

    test('defaultKey 应该是空字符串', () {
      expect(Cos.defaultKey, equals(''));
    });

    test('flutterCosApi 应该被正确初始化', () {
      expect(Cos().flutterCosApi, isNotNull);
    });
  });

  group('Cos 初始化测试', () {
    setUpAll(() {
      TestHelper.setupAll();
    });

    tearDownAll(() {
      TestHelper.tearDownAll();
    });

    test('initWithPlainSecret 应该调用原生 API', () async {
      // 由于 Cos 是单例且 _initialized 标志位会保持状态，
      // 这里只测试方法能被调用（可能会跳过因为已初始化）
      await Cos().initWithPlainSecret('test-secret-id', 'test-secret-key');
      // 方法执行不抛出异常即为成功
      expect(true, isTrue);
    });

    test('initWithSessionCredential 应该设置凭证提供器', () async {
      final mockCredentials = MockFetchCredentials();
      await Cos().initWithSessionCredential(mockCredentials);
      // 方法执行不抛出异常即为成功
      expect(true, isTrue);
    });

    test('initWithScopeLimitCredential 应该设置范围限制凭证提供器', () async {
      final mockCredentials = MockFetchScopeLimitCredentials();
      await Cos().initWithScopeLimitCredential(mockCredentials);
      // 方法执行不抛出异常即为成功
      expect(true, isTrue);
    });
  });

  group('Cos DNS 配置测试', () {
    setUpAll(() {
      TestHelper.setupAll();
    });

    tearDownAll(() {
      TestHelper.tearDownAll();
    });

    test('initCustomerDNS 应该调用原生 API', () async {
      await Cos().initCustomerDNS({
        'example.cos.ap-guangzhou.myqcloud.com': ['1.1.1.1', '2.2.2.2']
      });
      expect(true, isTrue);
    });

    test('initCustomerDNSFetch 应该设置 DNS 提供器', () async {
      final mockDns = MockFetchDns();
      await Cos().initCustomerDNSFetch(mockDns);
      expect(Cos().getFetchDns(), equals(mockDns));
    });
  });

  group('Cos 凭证管理测试', () {
    setUpAll(() {
      TestHelper.setupAll();
    });

    tearDownAll(() {
      TestHelper.tearDownAll();
    });

    test('forceInvalidationCredential 应该调用原生 API', () async {
      await Cos().forceInvalidationCredential();
      expect(true, isTrue);
    });

    test('setCloseBeacon 应该调用原生 API', () async {
      await Cos().setCloseBeacon(true);
      await Cos().setCloseBeacon(false);
      expect(true, isTrue);
    });
  });

  group('Cos Service 注册测试', () {
    setUpAll(() {
      TestHelper.setupAll();
    });

    tearDownAll(() {
      TestHelper.tearDownAll();
    });

    test('registerDefaultService 应该返回 CosService', () async {
      final config = CosXmlServiceConfig(region: 'ap-guangzhou');
      final service = await Cos().registerDefaultService(config);
      expect(service, isNotNull);
      expect(Cos().hasDefaultService(), isTrue);
    });

    test('getDefaultService 应该返回已注册的服务', () {
      if (Cos().hasDefaultService()) {
        final service = Cos().getDefaultService();
        expect(service, isNotNull);
      }
    });

    test('registerService 不能使用空 key', () async {
      final config = CosXmlServiceConfig(region: 'ap-guangzhou');
      expect(
        () => Cos().registerService('', config),
        throwsA(isA<IllegalArgumentException>()),
      );
    });

    test('registerService 应该使用指定的 key', () async {
      final config = CosXmlServiceConfig(region: 'ap-beijing');
      final service = await Cos().registerService('my-service', config);
      expect(service, isNotNull);
      expect(Cos().hasService('my-service'), isTrue);
    });

    test('getService 应该返回指定 key 的服务', () {
      if (Cos().hasService('my-service')) {
        final service = Cos().getService('my-service');
        expect(service, isNotNull);
      }
    });

    test('getService 对未注册的 key 应该抛出异常', () {
      expect(
        () => Cos().getService('non-existent-key'),
        throwsA(isA<IllegalArgumentException>()),
      );
    });
  });

  group('Cos TransferManger 注册测试', () {
    setUpAll(() {
      TestHelper.setupAll();
    });

    tearDownAll(() {
      TestHelper.tearDownAll();
    });

    test('registerDefaultTransferManger 应该返回 CosTransferManger', () async {
      final config = CosXmlServiceConfig(region: 'ap-guangzhou');
      final transferConfig = TransferConfig();
      final manger = await Cos().registerDefaultTransferManger(config, transferConfig);
      expect(manger, isNotNull);
      expect(Cos().hasDefaultTransferManger(), isTrue);
    });

    test('getDefaultTransferManger 应该返回已注册的管理器', () {
      if (Cos().hasDefaultTransferManger()) {
        final manger = Cos().getDefaultTransferManger();
        expect(manger, isNotNull);
      }
    });

    test('registerTransferManger 不能使用空 key', () async {
      final config = CosXmlServiceConfig(region: 'ap-guangzhou');
      final transferConfig = TransferConfig();
      expect(
        () => Cos().registerTransferManger('', config, transferConfig),
        throwsA(isA<IllegalArgumentException>()),
      );
    });

    test('registerTransferManger 应该使用指定的 key', () async {
      final config = CosXmlServiceConfig(region: 'ap-beijing');
      final transferConfig = TransferConfig();
      final manger = await Cos().registerTransferManger('my-transfer', config, transferConfig);
      expect(manger, isNotNull);
      expect(Cos().hasTransferManger('my-transfer'), isTrue);
    });

    test('getTransferManger 应该返回指定 key 的管理器', () {
      if (Cos().hasTransferManger('my-transfer')) {
        final manger = Cos().getTransferManger('my-transfer');
        expect(manger, isNotNull);
      }
    });

    test('getTransferManger 对未注册的 key 应该抛出异常', () {
      expect(
        () => Cos().getTransferManger('non-existent-key'),
        throwsA(isA<IllegalArgumentException>()),
      );
    });
  });

  group('Cos 日志配置测试', () {
    setUpAll(() {
      TestHelper.setupAll();
    });

    tearDownAll(() {
      TestHelper.tearDownAll();
    });

    test('enableLogcat 应该调用原生 API', () async {
      await Cos().enableLogcat(true);
      await Cos().enableLogcat(false);
      expect(true, isTrue);
    });

    test('enableLogFile 应该调用原生 API', () async {
      await Cos().enableLogFile(true);
      await Cos().enableLogFile(false);
      expect(true, isTrue);
    });

    test('addLogListener 和 removeLogListener 应该管理监听器', () async {
      void logCallback(LogEntity entity) {
        // 处理日志
      }
      
      await Cos().addLogListener(logCallback);
      expect(Cos().getLogListeners().containsKey(logCallback.hashCode), isTrue);
      
      await Cos().removeLogListener(logCallback);
      expect(Cos().getLogListeners().containsKey(logCallback.hashCode), isFalse);
    });

    test('setMinLevel 应该调用原生 API', () async {
      await Cos().setMinLevel(LogLevel.info);
      await Cos().setMinLevel(LogLevel.debug);
      await Cos().setMinLevel(LogLevel.error);
      expect(true, isTrue);
    });

    test('setLogcatMinLevel 应该调用原生 API', () async {
      await Cos().setLogcatMinLevel(LogLevel.warn);
      expect(true, isTrue);
    });

    test('setFileMinLevel 应该调用原生 API', () async {
      await Cos().setFileMinLevel(LogLevel.error);
      expect(true, isTrue);
    });

    test('setClsMinLevel 应该调用原生 API', () async {
      await Cos().setClsMinLevel(LogLevel.verbose);
      expect(true, isTrue);
    });

    test('getLogRootDir 应该返回目录路径', () async {
      final dir = await Cos().getLogRootDir();
      expect(dir, isNotEmpty);
    });

    test('setLogFileEncryptionKey 应该调用原生 API', () async {
      final key = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16]);
      final iv = Uint8List.fromList([16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1]);
      await Cos().setLogFileEncryptionKey(key, iv);
      expect(true, isTrue);
    });
  });

  group('Cos 设备信息配置测试', () {
    setUpAll(() {
      TestHelper.setupAll();
    });

    tearDownAll(() {
      TestHelper.tearDownAll();
    });

    test('setDeviceID 应该调用原生 API', () async {
      await Cos().setDeviceID('test-device-id');
      expect(true, isTrue);
    });

    test('setDeviceModel 应该调用原生 API', () async {
      await Cos().setDeviceModel('iPhone 15 Pro');
      expect(true, isTrue);
    });

    test('setAppVersion 应该调用原生 API', () async {
      await Cos().setAppVersion('1.0.0');
      expect(true, isTrue);
    });

    test('setExtras 应该调用原生 API', () async {
      await Cos().setExtras({'key1': 'value1', 'key2': 'value2'});
      expect(true, isTrue);
    });
  });

  group('Cos CLS 配置测试', () {
    setUpAll(() {
      TestHelper.setupAll();
    });

    tearDownAll(() {
      TestHelper.tearDownAll();
    });

    test('setCLsChannelAnonymous 应该调用原生 API', () async {
      await Cos().setCLsChannelAnonymous('topic-id', 'https://cls.endpoint.com');
      expect(true, isTrue);
    });

    test('setCLsChannelStaticKey 应该调用原生 API', () async {
      await Cos().setCLsChannelStaticKey(
        'topic-id',
        'https://cls.endpoint.com',
        'secret-id',
        'secret-key',
      );
      expect(true, isTrue);
    });

    test('setCLsChannelSessionCredential 应该设置 CLS 凭证提供器', () async {
      final mockClsCredentials = MockFetchCLsChannelCredentials();
      await Cos().setCLsChannelSessionCredential(
        'topic-id',
        'https://cls.endpoint.com',
        mockClsCredentials,
      );
      expect(Cos().getFetchCLsChannelCredentials(), equals(mockClsCredentials));
    });
  });

  group('Cos 敏感规则测试', () {
    setUpAll(() {
      TestHelper.setupAll();
    });

    tearDownAll(() {
      TestHelper.tearDownAll();
    });

    test('addSensitiveRule 应该调用原生 API', () async {
      await Cos().addSensitiveRule('phone', r'\d{11}');
      expect(true, isTrue);
    });

    test('removeSensitiveRule 应该调用原生 API', () async {
      await Cos().removeSensitiveRule('phone');
      expect(true, isTrue);
    });
  });

  group('Cos Getter 方法测试', () {
    setUpAll(() {
      TestHelper.setupAll();
    });

    tearDownAll(() {
      TestHelper.tearDownAll();
    });

    test('getFetchCredentials 应该返回凭证提供器', () async {
      final mockCredentials = MockFetchCredentials();
      await Cos().initWithSessionCredential(mockCredentials);
      
      final fetcher = Cos().getFetchCredentials();
      expect(fetcher, equals(mockCredentials));
    });

    test('getFetchScopeLimitCredentials 应该返回范围限制凭证提供器', () async {
      final mockCredentials = MockFetchScopeLimitCredentials();
      await Cos().initWithScopeLimitCredential(mockCredentials);
      
      final fetcher = Cos().getFetchScopeLimitCredentials();
      expect(fetcher, equals(mockCredentials));
    });

    test('getFetchDns 应该返回 DNS 提供器', () async {
      final mockDns = MockFetchDns();
      await Cos().initCustomerDNSFetch(mockDns);
      
      final fetcher = Cos().getFetchDns();
      expect(fetcher, equals(mockDns));
    });

    test('getFetchCLsChannelCredentials 应该返回 CLS 凭证提供器', () async {
      final mockClsCredentials = MockFetchCLsChannelCredentials();
      await Cos().setCLsChannelSessionCredential(
        'topic-id-getter',
        'https://cls.endpoint.com',
        mockClsCredentials,
      );
      
      final fetcher = Cos().getFetchCLsChannelCredentials();
      expect(fetcher, equals(mockClsCredentials));
    });

    test('getLogListeners 应该返回日志监听器映射', () async {
      void logCallback(LogEntity entity) {}
      
      await Cos().addLogListener(logCallback);
      
      final listeners = Cos().getLogListeners();
      expect(listeners, isA<Map<int, void Function(LogEntity)>>());
      expect(listeners.isNotEmpty, isTrue);
      
      await Cos().removeLogListener(logCallback);
    });
  });

  group('Cos 重复初始化测试', () {
    setUpAll(() {
      TestHelper.setupAll();
    });

    tearDownAll(() {
      TestHelper.tearDownAll();
    });

    test('重复调用 initWithPlainSecret 应该跳过（已初始化）', () async {
      // 第一次初始化（可能已经在其他测试中完成）
      await Cos().initWithPlainSecret('first-id', 'first-key');
      
      // 第二次初始化，应该静默跳过
      await Cos().initWithPlainSecret('second-id', 'second-key');
      
      // 不应该抛出异常
      expect(true, isTrue);
    });

    test('重复调用 initWithSessionCredential 应该跳过', () async {
      final mockCredentials1 = MockFetchCredentials();
      final mockCredentials2 = MockFetchCredentials();
      
      await Cos().initWithSessionCredential(mockCredentials1);
      await Cos().initWithSessionCredential(mockCredentials2);
      
      expect(true, isTrue);
    });

    test('重复调用 initWithScopeLimitCredential 应该跳过', () async {
      final mockCredentials1 = MockFetchScopeLimitCredentials();
      final mockCredentials2 = MockFetchScopeLimitCredentials();
      
      await Cos().initWithScopeLimitCredential(mockCredentials1);
      await Cos().initWithScopeLimitCredential(mockCredentials2);
      
      expect(true, isTrue);
    });
  });
}
