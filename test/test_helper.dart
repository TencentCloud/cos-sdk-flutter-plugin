// 测试辅助类：提供 Mock 原生 API 的能力
//
// 通过设置 Pigeon BasicMessageChannel 的 Mock Handler 来模拟原生 API 响应
// Pigeon 为每个方法创建单独的 channel，格式为：'dev.flutter.pigeon.{ClassName}.{methodName}'

import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tencentcloud_cos_sdk_plugin/pigeon.dart';

// ============== Pigeon 自定义 Codec 复制 ==============
// 为了正确解码 Pigeon 发送的消息，我们需要使用与 pigeon.dart 中相同的 codec

class _CosApiCodec extends StandardMessageCodec {
  const _CosApiCodec();
  @override
  void writeValue(WriteBuffer buffer, Object? value) {
    if (value is CosXmlServiceConfig) {
      buffer.putUint8(128);
      writeValue(buffer, value.encode());
    } else if (value is TransferConfig) {
      buffer.putUint8(129);
      writeValue(buffer, value.encode());
    } else {
      super.writeValue(buffer, value);
    }
  }

  @override
  Object? readValueOfType(int type, ReadBuffer buffer) {
    switch (type) {
      case 128:
        return CosXmlServiceConfig.decode(readValue(buffer)!);
      case 129:
        return TransferConfig.decode(readValue(buffer)!);
      default:
        return super.readValueOfType(type, buffer);
    }
  }
}

class _CosServiceApiCodec extends StandardMessageCodec {
  const _CosServiceApiCodec();
  @override
  void writeValue(WriteBuffer buffer, Object? value) {
    if (value is BucketContents) {
      buffer.putUint8(128);
      writeValue(buffer, value.encode());
    } else if (value is CommonPrefixes) {
      buffer.putUint8(129);
      writeValue(buffer, value.encode());
    } else if (value is Content) {
      buffer.putUint8(130);
      writeValue(buffer, value.encode());
    } else if (value is Bucket) {
      buffer.putUint8(131);
      writeValue(buffer, value.encode());
    } else if (value is ListAllMyBuckets) {
      buffer.putUint8(132);
      writeValue(buffer, value.encode());
    } else if (value is Owner) {
      buffer.putUint8(133);
      writeValue(buffer, value.encode());
    } else if (value is SessionQCloudCredentials) {
      buffer.putUint8(134);
      writeValue(buffer, value.encode());
    } else {
      super.writeValue(buffer, value);
    }
  }

  @override
  Object? readValueOfType(int type, ReadBuffer buffer) {
    switch (type) {
      case 128:
        return BucketContents.decode(readValue(buffer)!);
      case 129:
        return CommonPrefixes.decode(readValue(buffer)!);
      case 130:
        return Content.decode(readValue(buffer)!);
      case 131:
        return Bucket.decode(readValue(buffer)!);
      case 132:
        return ListAllMyBuckets.decode(readValue(buffer)!);
      case 133:
        return Owner.decode(readValue(buffer)!);
      case 134:
        return SessionQCloudCredentials.decode(readValue(buffer)!);
      default:
        return super.readValueOfType(type, buffer);
    }
  }
}

class _CosTransferApiCodec extends StandardMessageCodec {
  const _CosTransferApiCodec();
  @override
  void writeValue(WriteBuffer buffer, Object? value) {
    if (value is SessionQCloudCredentials) {
      buffer.putUint8(128);
      writeValue(buffer, value.encode());
    } else {
      super.writeValue(buffer, value);
    }
  }

  @override
  Object? readValueOfType(int type, ReadBuffer buffer) {
    switch (type) {
      case 128:
        return SessionQCloudCredentials.decode(readValue(buffer)!);
      default:
        return super.readValueOfType(type, buffer);
    }
  }
}

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
  static const _codec = _CosApiCodec();
  
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
    _setMockHandlerWithCodec('dev.flutter.pigeon.CosApi.initWithPlainSecret', _codec, (args) async {
      initWithPlainSecretCalled = true;
      return null;
    });
    
    // initWithSessionCredential
    _setMockHandlerWithCodec('dev.flutter.pigeon.CosApi.initWithSessionCredential', _codec, (args) async {
      initWithSessionCredentialCalled = true;
      return null;
    });
    
    // initWithScopeLimitCredential
    _setMockHandlerWithCodec('dev.flutter.pigeon.CosApi.initWithScopeLimitCredential', _codec, (args) async {
      initWithScopeLimitCredentialCalled = true;
      return null;
    });
    
    // initCustomerDNS
    _setMockHandlerWithCodec('dev.flutter.pigeon.CosApi.initCustomerDNS', _codec, (args) async {
      return null;
    });
    
    // initCustomerDNSFetch
    _setMockHandlerWithCodec('dev.flutter.pigeon.CosApi.initCustomerDNSFetch', _codec, (args) async {
      return null;
    });
    
    // forceInvalidationCredential
    _setMockHandlerWithCodec('dev.flutter.pigeon.CosApi.forceInvalidationCredential', _codec, (args) async {
      forceInvalidationCredentialCalled = true;
      return null;
    });
    
    // setCloseBeacon
    _setMockHandlerWithCodec('dev.flutter.pigeon.CosApi.setCloseBeacon', _codec, (args) async {
      return null;
    });
    
    // registerDefaultService
    _setMockHandlerWithCodec('dev.flutter.pigeon.CosApi.registerDefaultService', _codec, (args) async {
      registerDefaultServiceCalled = true;
      lastRegisteredKey = '';
      return '';
    });
    
    // registerDefaultTransferManger
    _setMockHandlerWithCodec('dev.flutter.pigeon.CosApi.registerDefaultTransferManger', _codec, (args) async {
      registerDefaultTransferMangerCalled = true;
      lastRegisteredKey = '';
      return '';
    });
    
    // registerService
    _setMockHandlerWithCodec('dev.flutter.pigeon.CosApi.registerService', _codec, (args) async {
      registerServiceCalled = true;
      final argList = args as List<Object?>;
      lastRegisteredKey = argList[0] as String? ?? '';
      return lastRegisteredKey;
    });
    
    // registerTransferManger
    _setMockHandlerWithCodec('dev.flutter.pigeon.CosApi.registerTransferManger', _codec, (args) async {
      registerTransferMangerCalled = true;
      final argList = args as List<Object?>;
      lastRegisteredKey = argList[0] as String? ?? '';
      return lastRegisteredKey;
    });
    
    // enableLogcat
    _setMockHandlerWithCodec('dev.flutter.pigeon.CosApi.enableLogcat', _codec, (args) async {
      return null;
    });
    
    // enableLogFile
    _setMockHandlerWithCodec('dev.flutter.pigeon.CosApi.enableLogFile', _codec, (args) async {
      return null;
    });
    
    // addLogListener
    _setMockHandlerWithCodec('dev.flutter.pigeon.CosApi.addLogListener', _codec, (args) async {
      return null;
    });
    
    // removeLogListener
    _setMockHandlerWithCodec('dev.flutter.pigeon.CosApi.removeLogListener', _codec, (args) async {
      return null;
    });
    
    // setMinLevel
    _setMockHandlerWithCodec('dev.flutter.pigeon.CosApi.setMinLevel', _codec, (args) async {
      return null;
    });
    
    // setLogcatMinLevel
    _setMockHandlerWithCodec('dev.flutter.pigeon.CosApi.setLogcatMinLevel', _codec, (args) async {
      return null;
    });
    
    // setFileMinLevel
    _setMockHandlerWithCodec('dev.flutter.pigeon.CosApi.setFileMinLevel', _codec, (args) async {
      return null;
    });
    
    // setClsMinLevel
    _setMockHandlerWithCodec('dev.flutter.pigeon.CosApi.setClsMinLevel', _codec, (args) async {
      return null;
    });
    
    // setDeviceID
    _setMockHandlerWithCodec('dev.flutter.pigeon.CosApi.setDeviceID', _codec, (args) async {
      return null;
    });
    
    // setDeviceModel
    _setMockHandlerWithCodec('dev.flutter.pigeon.CosApi.setDeviceModel', _codec, (args) async {
      return null;
    });
    
    // setAppVersion
    _setMockHandlerWithCodec('dev.flutter.pigeon.CosApi.setAppVersion', _codec, (args) async {
      return null;
    });
    
    // setExtras
    _setMockHandlerWithCodec('dev.flutter.pigeon.CosApi.setExtras', _codec, (args) async {
      return null;
    });
    
    // setLogFileEncryptionKey
    _setMockHandlerWithCodec('dev.flutter.pigeon.CosApi.setLogFileEncryptionKey', _codec, (args) async {
      return null;
    });
    
    // getLogRootDir
    _setMockHandlerWithCodec('dev.flutter.pigeon.CosApi.getLogRootDir', _codec, (args) async {
      return '/mock/log/dir';
    });
    
    // setCLsChannelAnonymous
    _setMockHandlerWithCodec('dev.flutter.pigeon.CosApi.setCLsChannelAnonymous', _codec, (args) async {
      return null;
    });
    
    // setCLsChannelStaticKey
    _setMockHandlerWithCodec('dev.flutter.pigeon.CosApi.setCLsChannelStaticKey', _codec, (args) async {
      return null;
    });
    
    // setCLsChannelSessionCredential
    _setMockHandlerWithCodec('dev.flutter.pigeon.CosApi.setCLsChannelSessionCredential', _codec, (args) async {
      return null;
    });
    
    // addSensitiveRule
    _setMockHandlerWithCodec('dev.flutter.pigeon.CosApi.addSensitiveRule', _codec, (args) async {
      return null;
    });
    
    // removeSensitiveRule
    _setMockHandlerWithCodec('dev.flutter.pigeon.CosApi.removeSensitiveRule', _codec, (args) async {
      return null;
    });
  }
  
  void tearDown() {
    final channels = [
      'dev.flutter.pigeon.CosApi.initWithPlainSecret',
      'dev.flutter.pigeon.CosApi.initWithSessionCredential',
      'dev.flutter.pigeon.CosApi.initWithScopeLimitCredential',
      'dev.flutter.pigeon.CosApi.initCustomerDNS',
      'dev.flutter.pigeon.CosApi.initCustomerDNSFetch',
      'dev.flutter.pigeon.CosApi.forceInvalidationCredential',
      'dev.flutter.pigeon.CosApi.setCloseBeacon',
      'dev.flutter.pigeon.CosApi.registerDefaultService',
      'dev.flutter.pigeon.CosApi.registerDefaultTransferManger',
      'dev.flutter.pigeon.CosApi.registerService',
      'dev.flutter.pigeon.CosApi.registerTransferManger',
      'dev.flutter.pigeon.CosApi.enableLogcat',
      'dev.flutter.pigeon.CosApi.enableLogFile',
      'dev.flutter.pigeon.CosApi.addLogListener',
      'dev.flutter.pigeon.CosApi.removeLogListener',
      'dev.flutter.pigeon.CosApi.setMinLevel',
      'dev.flutter.pigeon.CosApi.setLogcatMinLevel',
      'dev.flutter.pigeon.CosApi.setFileMinLevel',
      'dev.flutter.pigeon.CosApi.setClsMinLevel',
      'dev.flutter.pigeon.CosApi.setDeviceID',
      'dev.flutter.pigeon.CosApi.setDeviceModel',
      'dev.flutter.pigeon.CosApi.setAppVersion',
      'dev.flutter.pigeon.CosApi.setExtras',
      'dev.flutter.pigeon.CosApi.setLogFileEncryptionKey',
      'dev.flutter.pigeon.CosApi.getLogRootDir',
      'dev.flutter.pigeon.CosApi.setCLsChannelAnonymous',
      'dev.flutter.pigeon.CosApi.setCLsChannelStaticKey',
      'dev.flutter.pigeon.CosApi.setCLsChannelSessionCredential',
      'dev.flutter.pigeon.CosApi.addSensitiveRule',
      'dev.flutter.pigeon.CosApi.removeSensitiveRule',
    ];
    for (final channel in channels) {
      _clearMockHandler(channel);
    }
  }
}

/// Mock CosServiceApi 的所有 channel
class MockCosServiceApiChannels {
  static const _codec = _CosServiceApiCodec();
  
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
    _setMockHandlerWithCodec('dev.flutter.pigeon.CosServiceApi.headObject', _codec, (args) async {
      headObjectCalled = true;
      return <String?, String?>{'Content-Length': '1024', 'ETag': '"mock-etag"'};
    });
    
    // deleteObject
    _setMockHandlerWithCodec('dev.flutter.pigeon.CosServiceApi.deleteObject', _codec, (args) async {
      deleteObjectCalled = true;
      return null;
    });
    
    // getObjectUrl
    _setMockHandlerWithCodec('dev.flutter.pigeon.CosServiceApi.getObjectUrl', _codec, (args) async {
      getObjectUrlCalled = true;
      return 'https://bucket.cos.region.myqcloud.com/key';
    });
    
    // getPresignedUrl
    _setMockHandlerWithCodec('dev.flutter.pigeon.CosServiceApi.getPresignedUrl', _codec, (args) async {
      getPresignedUrlCalled = true;
      return 'https://bucket.cos.region.myqcloud.com/key?sign=mock';
    });
    
    // preBuildConnection
    _setMockHandlerWithCodec('dev.flutter.pigeon.CosServiceApi.preBuildConnection', _codec, (args) async {
      preBuildConnectionCalled = true;
      return null;
    });
    
    // getService - 返回编码后的 ListAllMyBuckets
    _setMockHandlerWithCodec('dev.flutter.pigeon.CosServiceApi.getService', _codec, (args) async {
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
    _setMockHandlerWithCodec('dev.flutter.pigeon.CosServiceApi.getBucket', _codec, (args) async {
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
    _setMockHandlerWithCodec('dev.flutter.pigeon.CosServiceApi.putBucket', _codec, (args) async {
      putBucketCalled = true;
      return null;
    });
    
    // headBucket
    _setMockHandlerWithCodec('dev.flutter.pigeon.CosServiceApi.headBucket', _codec, (args) async {
      headBucketCalled = true;
      return <String?, String?>{'x-cos-bucket-region': 'ap-guangzhou'};
    });
    
    // deleteBucket
    _setMockHandlerWithCodec('dev.flutter.pigeon.CosServiceApi.deleteBucket', _codec, (args) async {
      deleteBucketCalled = true;
      return null;
    });
    
    // getBucketAccelerate
    _setMockHandlerWithCodec('dev.flutter.pigeon.CosServiceApi.getBucketAccelerate', _codec, (args) async {
      return true;
    });
    
    // putBucketAccelerate
    _setMockHandlerWithCodec('dev.flutter.pigeon.CosServiceApi.putBucketAccelerate', _codec, (args) async {
      return null;
    });
    
    // getBucketLocation
    _setMockHandlerWithCodec('dev.flutter.pigeon.CosServiceApi.getBucketLocation', _codec, (args) async {
      return 'ap-guangzhou';
    });
    
    // getBucketVersioning
    _setMockHandlerWithCodec('dev.flutter.pigeon.CosServiceApi.getBucketVersioning', _codec, (args) async {
      return true;
    });
    
    // putBucketVersioning
    _setMockHandlerWithCodec('dev.flutter.pigeon.CosServiceApi.putBucketVersioning', _codec, (args) async {
      return null;
    });
    
    // doesBucketExist
    _setMockHandlerWithCodec('dev.flutter.pigeon.CosServiceApi.doesBucketExist', _codec, (args) async {
      doesBucketExistCalled = true;
      return true;
    });
    
    // doesObjectExist
    _setMockHandlerWithCodec('dev.flutter.pigeon.CosServiceApi.doesObjectExist', _codec, (args) async {
      doesObjectExistCalled = true;
      return true;
    });
    
    // cancelAll
    _setMockHandlerWithCodec('dev.flutter.pigeon.CosServiceApi.cancelAll', _codec, (args) async {
      cancelAllCalled = true;
      return null;
    });
  }
  
  void tearDown() {
    final channels = [
      'dev.flutter.pigeon.CosServiceApi.headObject',
      'dev.flutter.pigeon.CosServiceApi.deleteObject',
      'dev.flutter.pigeon.CosServiceApi.getObjectUrl',
      'dev.flutter.pigeon.CosServiceApi.getPresignedUrl',
      'dev.flutter.pigeon.CosServiceApi.preBuildConnection',
      'dev.flutter.pigeon.CosServiceApi.getService',
      'dev.flutter.pigeon.CosServiceApi.getBucket',
      'dev.flutter.pigeon.CosServiceApi.putBucket',
      'dev.flutter.pigeon.CosServiceApi.headBucket',
      'dev.flutter.pigeon.CosServiceApi.deleteBucket',
      'dev.flutter.pigeon.CosServiceApi.getBucketAccelerate',
      'dev.flutter.pigeon.CosServiceApi.putBucketAccelerate',
      'dev.flutter.pigeon.CosServiceApi.getBucketLocation',
      'dev.flutter.pigeon.CosServiceApi.getBucketVersioning',
      'dev.flutter.pigeon.CosServiceApi.putBucketVersioning',
      'dev.flutter.pigeon.CosServiceApi.doesBucketExist',
      'dev.flutter.pigeon.CosServiceApi.doesObjectExist',
      'dev.flutter.pigeon.CosServiceApi.cancelAll',
    ];
    for (final channel in channels) {
      _clearMockHandler(channel);
    }
  }
}

/// Mock CosTransferApi 的所有 channel
class MockCosTransferApiChannels {
  static const _codec = _CosTransferApiCodec();
  
  bool uploadCalled = false;
  bool downloadCalled = false;
  bool pauseCalled = false;
  bool resumeCalled = false;
  bool cancelCalled = false;
  
  void setup() {
    // upload
    _setMockHandlerWithCodec('dev.flutter.pigeon.CosTransferApi.upload', _codec, (args) async {
      uploadCalled = true;
      return 'mock-task-id';
    });
    
    // download
    _setMockHandlerWithCodec('dev.flutter.pigeon.CosTransferApi.download', _codec, (args) async {
      downloadCalled = true;
      return 'mock-task-id';
    });
    
    // pause
    _setMockHandlerWithCodec('dev.flutter.pigeon.CosTransferApi.pause', _codec, (args) async {
      pauseCalled = true;
      return null;
    });
    
    // resume
    _setMockHandlerWithCodec('dev.flutter.pigeon.CosTransferApi.resume', _codec, (args) async {
      resumeCalled = true;
      return null;
    });
    
    // cancel
    _setMockHandlerWithCodec('dev.flutter.pigeon.CosTransferApi.cancel', _codec, (args) async {
      cancelCalled = true;
      return null;
    });
  }
  
  void tearDown() {
    final channels = [
      'dev.flutter.pigeon.CosTransferApi.upload',
      'dev.flutter.pigeon.CosTransferApi.download',
      'dev.flutter.pigeon.CosTransferApi.pause',
      'dev.flutter.pigeon.CosTransferApi.resume',
      'dev.flutter.pigeon.CosTransferApi.cancel',
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
