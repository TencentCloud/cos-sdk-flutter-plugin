// Mock 文件：用于单元测试中模拟原生 API
// 
// 这个文件提供了 Pigeon 生成的原生 API 的 Mock 实现，
// 使得我们可以在不依赖 Android/iOS 设备的情况下运行单元测试。
// 
// 注意：此文件不是测试文件，而是测试辅助文件。
// @dart=2.15

library mock_cos_api;

import 'dart:typed_data';
import 'package:tencentcloud_cos_sdk_plugin/pigeon.dart';

/// Mock CosApi - 模拟 COS 核心 API
class MockCosApi implements CosApi {
  bool initWithPlainSecretCalled = false;
  bool initWithSessionCredentialCalled = false;
  bool initWithScopeLimitCredentialCalled = false;
  bool forceInvalidationCredentialCalled = false;
  String? lastSecretId;
  String? lastSecretKey;

  @override
  Future<void> initWithPlainSecret(String secretId, String secretKey) async {
    initWithPlainSecretCalled = true;
    lastSecretId = secretId;
    lastSecretKey = secretKey;
  }

  @override
  Future<void> initWithSessionCredential() async {
    initWithSessionCredentialCalled = true;
  }

  @override
  Future<void> initWithScopeLimitCredential() async {
    initWithScopeLimitCredentialCalled = true;
  }

  @override
  Future<void> initCustomerDNS(Map<String?, List<String?>?> dnsMap) async {}

  @override
  Future<void> initCustomerDNSFetch() async {}

  @override
  Future<void> forceInvalidationCredential() async {
    forceInvalidationCredentialCalled = true;
  }

  @override
  Future<void> setCloseBeacon(bool isCloseBeacon) async {}

  @override
  Future<String> registerDefaultService(CosXmlServiceConfig config) async {
    return '';
  }

  @override
  Future<String> registerDefaultTransferManger(
      CosXmlServiceConfig config, TransferConfig? transferConfig) async {
    return '';
  }

  @override
  Future<String> registerService(String key, CosXmlServiceConfig config) async {
    return key;
  }

  @override
  Future<String> registerTransferManger(
      String key, CosXmlServiceConfig config, TransferConfig? transferConfig) async {
    return key;
  }

  @override
  Future<void> enableLogcat(bool enable) async {}

  @override
  Future<void> enableLogFile(bool enable) async {}

  @override
  Future<void> addLogListener(int key) async {}

  @override
  Future<void> removeLogListener(int key) async {}

  @override
  Future<void> setMinLevel(LogLevel minLevel) async {}

  @override
  Future<void> setLogcatMinLevel(LogLevel minLevel) async {}

  @override
  Future<void> setFileMinLevel(LogLevel minLevel) async {}

  @override
  Future<void> setClsMinLevel(LogLevel minLevel) async {}

  @override
  Future<void> setDeviceID(String deviceID) async {}

  @override
  Future<void> setDeviceModel(String deviceModel) async {}

  @override
  Future<void> setAppVersion(String appVersion) async {}

  @override
  Future<void> setExtras(Map<String?, String?> extras) async {}

  @override
  Future<void> setLogFileEncryptionKey(Uint8List key, Uint8List iv) async {}

  @override
  Future<String> getLogRootDir() async {
    return '/mock/log/dir';
  }

  @override
  Future<void> setCLsChannelAnonymous(String topicId, String endpoint) async {}

  @override
  Future<void> setCLsChannelStaticKey(
      String topicId, String endpoint, String secretId, String secretKey) async {}

  @override
  Future<void> setCLsChannelSessionCredential(String topicId, String endpoint) async {}

  @override
  Future<void> addSensitiveRule(String ruleName, String regex) async {}

  @override
  Future<void> removeSensitiveRule(String ruleName) async {}
}

/// Mock CosServiceApi - 模拟 COS Service API
class MockCosServiceApi implements CosServiceApi {
  // 记录调用情况
  bool headObjectCalled = false;
  bool deleteObjectCalled = false;
  bool getServiceCalled = false;
  bool getBucketCalled = false;
  bool putBucketCalled = false;
  bool headBucketCalled = false;
  bool deleteBucketCalled = false;
  bool doesBucketExistCalled = false;
  bool doesObjectExistCalled = false;

  // Mock 返回数据
  Map<String?, String?> mockHeadObjectResult = {'Content-Length': '1024'};
  ListAllMyBuckets? mockGetServiceResult;
  BucketContents? mockGetBucketResult;
  bool mockBucketExists = true;
  bool mockObjectExists = true;
  String mockBucketLocation = 'ap-guangzhou';
  bool mockBucketAccelerate = false;
  bool mockBucketVersioning = false;

  @override
  Future<Map<String?, String?>> headObject(
      String serviceKey,
      String bucket,
      String? region,
      String cosPath,
      String? versionId,
      SessionQCloudCredentials? sessionCredentials) async {
    headObjectCalled = true;
    return mockHeadObjectResult;
  }

  @override
  Future<void> deleteObject(
      String serviceKey,
      String bucket,
      String? region,
      String cosPath,
      String? versionId,
      SessionQCloudCredentials? sessionCredentials) async {
    deleteObjectCalled = true;
  }

  @override
  Future<String> getObjectUrl(
      String bucket, String region, String cosPath, String serviceKey) async {
    return 'https://$bucket.cos.$region.myqcloud.com/$cosPath';
  }

  @override
  Future<String> getPresignedUrl(
      String serviceKey,
      String bucket,
      String cosPath,
      int? signValidTime,
      bool? signHost,
      Map<String?, String?>? parameters,
      String? region,
      SessionQCloudCredentials? sessionCredentials) async {
    return 'https://$bucket.cos.${region ?? "ap-guangzhou"}.myqcloud.com/$cosPath?sign=mock';
  }

  @override
  Future<void> preBuildConnection(String bucket, String serviceKey) async {}

  @override
  Future<ListAllMyBuckets> getService(
      String serviceKey, SessionQCloudCredentials? sessionCredentials) async {
    getServiceCalled = true;
    return mockGetServiceResult ??
        ListAllMyBuckets(
          owner: Owner(id: 'mock-owner-id', disPlayName: 'MockOwner'),
          buckets: [
            Bucket(
              name: 'test-bucket-1250000000',
              location: 'ap-guangzhou',
              createDate: '2024-01-01T00:00:00Z',
            )
          ],
        );
  }

  @override
  Future<BucketContents> getBucket(
      String serviceKey,
      String bucket,
      String? region,
      String? prefix,
      String? delimiter,
      String? encodingType,
      String? marker,
      int? maxKeys,
      SessionQCloudCredentials? sessionCredentials) async {
    getBucketCalled = true;
    return mockGetBucketResult ??
        BucketContents(
          name: bucket,
          maxKeys: maxKeys ?? 1000,
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
  }

  @override
  Future<void> putBucket(
      String serviceKey,
      String bucket,
      String? region,
      bool? enableMAZ,
      String? cosacl,
      String? readAccount,
      String? writeAccount,
      String? readWriteAccount,
      SessionQCloudCredentials? sessionCredentials) async {
    putBucketCalled = true;
  }

  @override
  Future<Map<String?, String?>> headBucket(String serviceKey, String bucket,
      String? region, SessionQCloudCredentials? sessionCredentials) async {
    headBucketCalled = true;
    return {'x-cos-bucket-region': region ?? 'ap-guangzhou'};
  }

  @override
  Future<void> deleteBucket(String serviceKey, String bucket, String? region,
      SessionQCloudCredentials? sessionCredentials) async {
    deleteBucketCalled = true;
  }

  @override
  Future<bool> getBucketAccelerate(String serviceKey, String bucket,
      String? region, SessionQCloudCredentials? sessionCredentials) async {
    return mockBucketAccelerate;
  }

  @override
  Future<void> putBucketAccelerate(String serviceKey, String bucket,
      String? region, bool enable, SessionQCloudCredentials? sessionCredentials) async {
    mockBucketAccelerate = enable;
  }

  @override
  Future<String> getBucketLocation(String serviceKey, String bucket,
      String? region, SessionQCloudCredentials? sessionCredentials) async {
    return mockBucketLocation;
  }

  @override
  Future<bool> getBucketVersioning(String serviceKey, String bucket,
      String? region, SessionQCloudCredentials? sessionCredentials) async {
    return mockBucketVersioning;
  }

  @override
  Future<void> putBucketVersioning(String serviceKey, String bucket,
      String? region, bool enable, SessionQCloudCredentials? sessionCredentials) async {
    mockBucketVersioning = enable;
  }

  @override
  Future<bool> doesBucketExist(String serviceKey, String bucket) async {
    doesBucketExistCalled = true;
    return mockBucketExists;
  }

  @override
  Future<bool> doesObjectExist(
      String serviceKey, String bucket, String cosPath) async {
    doesObjectExistCalled = true;
    return mockObjectExists;
  }

  @override
  Future<void> cancelAll(String serviceKey) async {}
}

/// Mock CosTransferApi - 模拟传输 API
class MockCosTransferApi implements CosTransferApi {
  bool uploadCalled = false;
  bool downloadCalled = false;
  bool pauseCalled = false;
  bool resumeCalled = false;
  bool cancelCalled = false;

  String mockTaskId = 'mock-task-id';

  @override
  Future<String> upload(
      String transferKey,
      String bucket,
      String cosPath,
      String? region,
      String? filePath,
      Uint8List? byteArr,
      String? uploadId,
      String? stroageClass,
      int? trafficLimit,
      String? callbackParam,
      Map<String?, String?>? customHeaders,
      List<String?>? noSignHeaders,
      int? resultCallbackKey,
      int? stateCallbackKey,
      int? progressCallbackKey,
      int? initMultipleUploadCallbackKey,
      SessionQCloudCredentials? sessionCredentials) async {
    uploadCalled = true;
    return mockTaskId;
  }

  @override
  Future<String> download(
      String transferKey,
      String bucket,
      String cosPath,
      String? region,
      String savePath,
      String? versionId,
      int? trafficLimit,
      Map<String?, String?>? customHeaders,
      List<String?>? noSignHeaders,
      int? resultCallbackKey,
      int? stateCallbackKey,
      int? progressCallbackKey,
      SessionQCloudCredentials? sessionCredentials) async {
    downloadCalled = true;
    return mockTaskId;
  }

  @override
  Future<void> pause(String taskId, String transferKey) async {
    pauseCalled = true;
  }

  @override
  Future<void> resume(String taskId, String transferKey) async {
    resumeCalled = true;
  }

  @override
  Future<void> cancel(String taskId, String transferKey) async {
    cancelCalled = true;
  }
}
