// 测试辅助类：提供 Mock 原生 API 的能力
//
// 通过设置 Pigeon BasicMessageChannel 的 Mock Handler 来模拟原生 API 响应
// Pigeon 为每个方法创建单独的 channel，格式为：
//   'dev.flutter.pigeon.{packageName}.{ClassName}.{methodName}'
// 其中 packageName 由 pigeon.sh 的 --package_name 指定（本项目为
// tencentcloud_cos_sdk_plugin）。pigeon v10.1.4 起 channel 名才包含包名段。

import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tencentcloud_cos_sdk_plugin/pigeon.dart';

// ============== Codec 说明 ==============
// 直接复用 pigeon 生成产物导出的 `pigeonChannelCodec`，不再手工复刻。
// pigeon 25.x 起改为「每文件单一 codec」（type id 从 129 起、按声明序分配），
// 与旧版「每个 Api 一个 codec、128 起、按类名字母序」不同。手工复刻会在每次
// pigeon 升级或 IDL 增删数据类时静默失效，故统一引用生成产物。

// ============== Mock Handler 设置函数 ==============

/// 设置单个 channel 的 mock handler，使用指定的 codec
void _setMockHandlerWithCodec(String channelName, MessageCodec<Object?> codec, Future<Object?> Function(Object?)? handler) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMessageHandler(channelName, (ByteData? message) async {
    if (handler == null || message == null) return null;
    
    final Object? args = codec.decodeMessage(message);
    final Object? result = await handler(args);
    
    // Pigeon 期望返回 [result] 格式（成功）或 [code, message, details] 格式（失败）
    return codec.encodeMessage(<Object?>[result]);
  });
}

/// 清除单个 channel 的 mock handler
void _clearMockHandler(String channelName) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMessageHandler(channelName, null);
}

// ============== Mock Channel 类 ==============

/// Mock CosApi 的所有 channel
class MockCosApiChannels {
  static const _codec = CosApi.pigeonChannelCodec;
  
  bool initWithPlainSecretCalled = false;
  bool initWithSessionCredentialCalled = false;
  bool initWithScopeLimitCredentialCalled = false;
  bool forceInvalidationCredentialCalled = false;
  bool registerDefaultServiceCalled = false;
  bool registerDefaultTransferMangerCalled = false;
  bool registerServiceCalled = false;
  bool registerTransferMangerCalled = false;
  
  String lastRegisteredKey = '';
  
  void setup() {
    // initWithPlainSecret
    _setMockHandlerWithCodec('dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosApi.initWithPlainSecret', _codec, (args) async {
      initWithPlainSecretCalled = true;
      return null;
    });
    
    // initWithSessionCredential
    _setMockHandlerWithCodec('dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosApi.initWithSessionCredential', _codec, (args) async {
      initWithSessionCredentialCalled = true;
      return null;
    });
    
    // initWithScopeLimitCredential
    _setMockHandlerWithCodec('dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosApi.initWithScopeLimitCredential', _codec, (args) async {
      initWithScopeLimitCredentialCalled = true;
      return null;
    });
    
    // initCustomerDNS
    _setMockHandlerWithCodec('dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosApi.initCustomerDNS', _codec, (args) async {
      return null;
    });
    
    // initCustomerDNSFetch
    _setMockHandlerWithCodec('dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosApi.initCustomerDNSFetch', _codec, (args) async {
      return null;
    });
    
    // forceInvalidationCredential
    _setMockHandlerWithCodec('dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosApi.forceInvalidationCredential', _codec, (args) async {
      forceInvalidationCredentialCalled = true;
      return null;
    });
    
    // setCloseBeacon
    _setMockHandlerWithCodec('dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosApi.setCloseBeacon', _codec, (args) async {
      return null;
    });
    
    // registerDefaultService
    _setMockHandlerWithCodec('dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosApi.registerDefaultService', _codec, (args) async {
      registerDefaultServiceCalled = true;
      lastRegisteredKey = '';
      return '';
    });
    
    // registerDefaultTransferManger
    _setMockHandlerWithCodec('dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosApi.registerDefaultTransferManger', _codec, (args) async {
      registerDefaultTransferMangerCalled = true;
      lastRegisteredKey = '';
      return '';
    });
    
    // registerService
    _setMockHandlerWithCodec('dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosApi.registerService', _codec, (args) async {
      registerServiceCalled = true;
      final argList = args as List<Object?>;
      lastRegisteredKey = argList[0] as String? ?? '';
      return lastRegisteredKey;
    });
    
    // registerTransferManger
    _setMockHandlerWithCodec('dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosApi.registerTransferManger', _codec, (args) async {
      registerTransferMangerCalled = true;
      final argList = args as List<Object?>;
      lastRegisteredKey = argList[0] as String? ?? '';
      return lastRegisteredKey;
    });
    
    // enableLogcat
    _setMockHandlerWithCodec('dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosApi.enableLogcat', _codec, (args) async {
      return null;
    });
    
    // enableLogFile
    _setMockHandlerWithCodec('dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosApi.enableLogFile', _codec, (args) async {
      return null;
    });
    
    // addLogListener
    _setMockHandlerWithCodec('dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosApi.addLogListener', _codec, (args) async {
      return null;
    });
    
    // removeLogListener
    _setMockHandlerWithCodec('dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosApi.removeLogListener', _codec, (args) async {
      return null;
    });
    
    // setMinLevel
    _setMockHandlerWithCodec('dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosApi.setMinLevel', _codec, (args) async {
      return null;
    });
    
    // setLogcatMinLevel
    _setMockHandlerWithCodec('dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosApi.setLogcatMinLevel', _codec, (args) async {
      return null;
    });
    
    // setFileMinLevel
    _setMockHandlerWithCodec('dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosApi.setFileMinLevel', _codec, (args) async {
      return null;
    });
    
    // setClsMinLevel
    _setMockHandlerWithCodec('dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosApi.setClsMinLevel', _codec, (args) async {
      return null;
    });
    
    // setDeviceID
    _setMockHandlerWithCodec('dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosApi.setDeviceID', _codec, (args) async {
      return null;
    });
    
    // setDeviceModel
    _setMockHandlerWithCodec('dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosApi.setDeviceModel', _codec, (args) async {
      return null;
    });
    
    // setAppVersion
    _setMockHandlerWithCodec('dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosApi.setAppVersion', _codec, (args) async {
      return null;
    });
    
    // setExtras
    _setMockHandlerWithCodec('dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosApi.setExtras', _codec, (args) async {
      return null;
    });
    
    // setLogFileEncryptionKey
    _setMockHandlerWithCodec('dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosApi.setLogFileEncryptionKey', _codec, (args) async {
      return null;
    });
    
    // getLogRootDir
    _setMockHandlerWithCodec('dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosApi.getLogRootDir', _codec, (args) async {
      return '/mock/log/dir';
    });
    
    // setCLsChannelAnonymous
    _setMockHandlerWithCodec('dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosApi.setCLsChannelAnonymous', _codec, (args) async {
      return null;
    });
    
    // setCLsChannelStaticKey
    _setMockHandlerWithCodec('dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosApi.setCLsChannelStaticKey', _codec, (args) async {
      return null;
    });
    
    // setCLsChannelSessionCredential
    _setMockHandlerWithCodec('dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosApi.setCLsChannelSessionCredential', _codec, (args) async {
      return null;
    });
    
    // addSensitiveRule
    _setMockHandlerWithCodec('dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosApi.addSensitiveRule', _codec, (args) async {
      return null;
    });
    
    // removeSensitiveRule
    _setMockHandlerWithCodec('dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosApi.removeSensitiveRule', _codec, (args) async {
      return null;
    });
  }
  
  void tearDown() {
    final channels = [
      'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosApi.initWithPlainSecret',
      'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosApi.initWithSessionCredential',
      'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosApi.initWithScopeLimitCredential',
      'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosApi.initCustomerDNS',
      'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosApi.initCustomerDNSFetch',
      'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosApi.forceInvalidationCredential',
      'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosApi.setCloseBeacon',
      'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosApi.registerDefaultService',
      'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosApi.registerDefaultTransferManger',
      'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosApi.registerService',
      'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosApi.registerTransferManger',
      'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosApi.enableLogcat',
      'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosApi.enableLogFile',
      'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosApi.addLogListener',
      'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosApi.removeLogListener',
      'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosApi.setMinLevel',
      'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosApi.setLogcatMinLevel',
      'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosApi.setFileMinLevel',
      'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosApi.setClsMinLevel',
      'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosApi.setDeviceID',
      'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosApi.setDeviceModel',
      'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosApi.setAppVersion',
      'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosApi.setExtras',
      'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosApi.setLogFileEncryptionKey',
      'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosApi.getLogRootDir',
      'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosApi.setCLsChannelAnonymous',
      'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosApi.setCLsChannelStaticKey',
      'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosApi.setCLsChannelSessionCredential',
      'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosApi.addSensitiveRule',
      'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosApi.removeSensitiveRule',
    ];
    for (final channel in channels) {
      _clearMockHandler(channel);
    }
  }
}

/// Mock CosServiceApi 的所有 channel
class MockCosServiceApiChannels {
  static const _codec = CosApi.pigeonChannelCodec;
  
  bool headObjectCalled = false;
  bool deleteObjectCalled = false;
  bool getServiceCalled = false;
  bool getBucketCalled = false;
  bool putBucketCalled = false;
  bool headBucketCalled = false;
  bool deleteBucketCalled = false;
  bool doesBucketExistCalled = false;
  bool doesObjectExistCalled = false;
  bool getObjectUrlCalled = false;
  bool getPresignedUrlCalled = false;
  bool preBuildConnectionCalled = false;
  bool cancelAllCalled = false;
  
  void setup() {
    // headObject
    _setMockHandlerWithCodec('dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosServiceApi.headObject', _codec, (args) async {
      headObjectCalled = true;
      return <String?, String?>{'Content-Length': '1024', 'ETag': '"mock-etag"'};
    });
    
    // deleteObject
    _setMockHandlerWithCodec('dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosServiceApi.deleteObject', _codec, (args) async {
      deleteObjectCalled = true;
      return null;
    });
    
    // getObjectUrl
    _setMockHandlerWithCodec('dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosServiceApi.getObjectUrl', _codec, (args) async {
      getObjectUrlCalled = true;
      return 'https://bucket.cos.region.myqcloud.com/key';
    });
    
    // getPresignedUrl
    _setMockHandlerWithCodec('dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosServiceApi.getPresignedUrl', _codec, (args) async {
      getPresignedUrlCalled = true;
      return 'https://bucket.cos.region.myqcloud.com/key?sign=mock';
    });
    
    // preBuildConnection
    _setMockHandlerWithCodec('dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosServiceApi.preBuildConnection', _codec, (args) async {
      preBuildConnectionCalled = true;
      return null;
    });
    
    // getService - 返回编码后的 ListAllMyBuckets
    _setMockHandlerWithCodec('dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosServiceApi.getService', _codec, (args) async {
      getServiceCalled = true;
      return ListAllMyBuckets(
        owner: Owner(id: 'mock-owner-id', disPlayName: 'MockOwner'),
        buckets: [
          Bucket(
            name: 'test-bucket-1250000000',
            location: 'ap-guangzhou',
            createDate: '2024-01-01T00:00:00Z',
          )
        ],
      );
    });
    
    // getBucket - 返回编码后的 BucketContents
    _setMockHandlerWithCodec('dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosServiceApi.getBucket', _codec, (args) async {
      getBucketCalled = true;
      return BucketContents(
        name: 'test-bucket',
        maxKeys: 1000,
        isTruncated: false,
        contentsList: [
          Content(
            key: 'test-file.txt',
            lastModified: '2024-01-01T00:00:00Z',
            eTag: '"mock-etag"',
            size: 1024,
            owner: Owner(id: 'mock-owner-id'),
            storageClass: 'STANDARD',
          )
        ],
        commonPrefixesList: [],
      );
    });
    
    // putBucket
    _setMockHandlerWithCodec('dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosServiceApi.putBucket', _codec, (args) async {
      putBucketCalled = true;
      return null;
    });
    
    // headBucket
    _setMockHandlerWithCodec('dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosServiceApi.headBucket', _codec, (args) async {
      headBucketCalled = true;
      return <String?, String?>{'x-cos-bucket-region': 'ap-guangzhou'};
    });
    
    // deleteBucket
    _setMockHandlerWithCodec('dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosServiceApi.deleteBucket', _codec, (args) async {
      deleteBucketCalled = true;
      return null;
    });
    
    // getBucketAccelerate
    _setMockHandlerWithCodec('dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosServiceApi.getBucketAccelerate', _codec, (args) async {
      return true;
    });
    
    // putBucketAccelerate
    _setMockHandlerWithCodec('dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosServiceApi.putBucketAccelerate', _codec, (args) async {
      return null;
    });
    
    // getBucketLocation
    _setMockHandlerWithCodec('dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosServiceApi.getBucketLocation', _codec, (args) async {
      return 'ap-guangzhou';
    });
    
    // getBucketVersioning
    _setMockHandlerWithCodec('dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosServiceApi.getBucketVersioning', _codec, (args) async {
      return true;
    });
    
    // putBucketVersioning
    _setMockHandlerWithCodec('dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosServiceApi.putBucketVersioning', _codec, (args) async {
      return null;
    });
    
    // doesBucketExist
    _setMockHandlerWithCodec('dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosServiceApi.doesBucketExist', _codec, (args) async {
      doesBucketExistCalled = true;
      return true;
    });
    
    // doesObjectExist
    _setMockHandlerWithCodec('dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosServiceApi.doesObjectExist', _codec, (args) async {
      doesObjectExistCalled = true;
      return true;
    });
    
    // cancelAll
    _setMockHandlerWithCodec('dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosServiceApi.cancelAll', _codec, (args) async {
      cancelAllCalled = true;
      return null;
    });
  }
  
  void tearDown() {
    final channels = [
      'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosServiceApi.headObject',
      'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosServiceApi.deleteObject',
      'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosServiceApi.getObjectUrl',
      'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosServiceApi.getPresignedUrl',
      'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosServiceApi.preBuildConnection',
      'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosServiceApi.getService',
      'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosServiceApi.getBucket',
      'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosServiceApi.putBucket',
      'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosServiceApi.headBucket',
      'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosServiceApi.deleteBucket',
      'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosServiceApi.getBucketAccelerate',
      'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosServiceApi.putBucketAccelerate',
      'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosServiceApi.getBucketLocation',
      'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosServiceApi.getBucketVersioning',
      'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosServiceApi.putBucketVersioning',
      'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosServiceApi.doesBucketExist',
      'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosServiceApi.doesObjectExist',
      'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosServiceApi.cancelAll',
    ];
    for (final channel in channels) {
      _clearMockHandler(channel);
    }
  }
}

/// Mock CosTransferApi 的所有 channel
class MockCosTransferApiChannels {
  static const _codec = CosApi.pigeonChannelCodec;
  
  bool uploadCalled = false;
  bool downloadCalled = false;
  bool pauseCalled = false;
  bool resumeCalled = false;
  bool cancelCalled = false;
  
  void setup() {
    // upload
    _setMockHandlerWithCodec('dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosTransferApi.upload', _codec, (args) async {
      uploadCalled = true;
      return 'mock-task-id';
    });
    
    // download
    _setMockHandlerWithCodec('dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosTransferApi.download', _codec, (args) async {
      downloadCalled = true;
      return 'mock-task-id';
    });
    
    // pause
    _setMockHandlerWithCodec('dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosTransferApi.pause', _codec, (args) async {
      pauseCalled = true;
      return null;
    });
    
    // resume
    _setMockHandlerWithCodec('dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosTransferApi.resume', _codec, (args) async {
      resumeCalled = true;
      return null;
    });
    
    // cancel
    _setMockHandlerWithCodec('dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosTransferApi.cancel', _codec, (args) async {
      cancelCalled = true;
      return null;
    });
  }
  
  void tearDown() {
    final channels = [
      'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosTransferApi.upload',
      'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosTransferApi.download',
      'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosTransferApi.pause',
      'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosTransferApi.resume',
      'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosTransferApi.cancel',
    ];
    for (final channel in channels) {
      _clearMockHandler(channel);
    }
  }
}

/// 全局测试助手类
class TestHelper {
  static final MockCosApiChannels cosApiChannel = MockCosApiChannels();
  static final MockCosServiceApiChannels cosServiceApiChannel = MockCosServiceApiChannels();
  static final MockCosTransferApiChannels cosTransferApiChannel = MockCosTransferApiChannels();
  
  /// 设置所有 Mock Channel
  static void setupAll() {
    cosApiChannel.setup();
    cosServiceApiChannel.setup();
    cosTransferApiChannel.setup();
  }
  
  /// 清理所有 Mock Channel
  static void tearDownAll() {
    cosApiChannel.tearDown();
    cosServiceApiChannel.tearDown();
    cosTransferApiChannel.tearDown();
  }
  
  /// 重置所有 Mock 状态
  static void resetAll() {
    tearDownAll();
    setupAll();
  }
}
