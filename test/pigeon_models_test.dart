// Pigeon 数据模型单元测试
//
// 测试 Pigeon 生成的各种数据模型类的 encode/decode 功能

import 'package:flutter_test/flutter_test.dart';
import 'package:tencentcloud_cos_sdk_plugin/pigeon.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LogLevel 枚举测试', () {
    test('LogLevel 应该包含所有级别', () {
      expect(LogLevel.values.length, equals(5));
      expect(LogLevel.verbose.index, equals(0));
      expect(LogLevel.debug.index, equals(1));
      expect(LogLevel.info.index, equals(2));
      expect(LogLevel.warn.index, equals(3));
      expect(LogLevel.error.index, equals(4));
    });
  });

  group('LogCategory 枚举测试', () {
    test('LogCategory 应该包含所有类别', () {
      expect(LogCategory.values.length, equals(5));
      expect(LogCategory.process.index, equals(0));
      expect(LogCategory.result.index, equals(1));
      expect(LogCategory.network.index, equals(2));
      expect(LogCategory.probe.index, equals(3));
      expect(LogCategory.error.index, equals(4));
    });
  });

  group('CosXmlServiceConfig 测试', () {
    test('CosXmlServiceConfig 应该正确初始化', () {
      final config = CosXmlServiceConfig(
        region: 'ap-guangzhou',
        connectionTimeout: 30000,
        socketTimeout: 30000,
        isHttps: true,
        isDebuggable: false,
        accelerate: false,
      );

      expect(config.region, equals('ap-guangzhou'));
      expect(config.connectionTimeout, equals(30000));
      expect(config.socketTimeout, equals(30000));
      expect(config.isHttps, isTrue);
      expect(config.isDebuggable, isFalse);
      expect(config.accelerate, isFalse);
    });

    test('CosXmlServiceConfig encode/decode 应该正确工作', () {
      final config = CosXmlServiceConfig(
        region: 'ap-beijing',
        connectionTimeout: 60000,
        socketTimeout: 60000,
        isHttps: true,
        host: 'cos.ap-beijing.myqcloud.com',
        port: 443,
        isDebuggable: true,
        signInUrl: false,
        userAgent: 'test-agent',
        dnsCache: true,
        accelerate: false,
        domainSwitch: true,
        customHeaders: {'X-Custom': 'value'},
        noSignHeaders: ['Content-Type'],
      );

      final encoded = config.encode() as List<Object?>;
      expect(encoded.length, equals(15));
      expect(encoded[0], equals('ap-beijing'));
      expect(encoded[1], equals(60000));
      expect(encoded[3], isTrue);

      final decoded = CosXmlServiceConfig.decode(encoded);
      expect(decoded.region, equals('ap-beijing'));
      expect(decoded.connectionTimeout, equals(60000));
      expect(decoded.isHttps, isTrue);
      expect(decoded.host, equals('cos.ap-beijing.myqcloud.com'));
      expect(decoded.port, equals(443));
    });
  });

  group('TransferConfig 测试', () {
    test('TransferConfig 应该正确初始化', () {
      final config = TransferConfig(
        forceSimpleUpload: false,
        enableVerification: true,
        divisionForUpload: 1024 * 1024,
        sliceSizeForUpload: 512 * 1024,
      );

      expect(config.forceSimpleUpload, isFalse);
      expect(config.enableVerification, isTrue);
      expect(config.divisionForUpload, equals(1024 * 1024));
      expect(config.sliceSizeForUpload, equals(512 * 1024));
    });

    test('TransferConfig encode/decode 应该正确工作', () {
      final config = TransferConfig(
        forceSimpleUpload: true,
        enableVerification: false,
        divisionForUpload: 2 * 1024 * 1024,
        sliceSizeForUpload: 1024 * 1024,
      );

      final encoded = config.encode() as List<Object?>;
      expect(encoded.length, equals(4));

      final decoded = TransferConfig.decode(encoded);
      expect(decoded.forceSimpleUpload, isTrue);
      expect(decoded.enableVerification, isFalse);
      expect(decoded.divisionForUpload, equals(2 * 1024 * 1024));
      expect(decoded.sliceSizeForUpload, equals(1024 * 1024));
    });
  });

  group('STSCredentialScope 测试', () {
    test('STSCredentialScope 应该正确初始化', () {
      final scope = STSCredentialScope(
        action: 'PutObject',
        region: 'ap-guangzhou',
        bucket: 'test-bucket-1250000000',
        prefix: 'upload/*',
      );

      expect(scope.action, equals('PutObject'));
      expect(scope.region, equals('ap-guangzhou'));
      expect(scope.bucket, equals('test-bucket-1250000000'));
      expect(scope.prefix, equals('upload/*'));
    });

    test('STSCredentialScope encode/decode 应该正确工作', () {
      final scope = STSCredentialScope(
        action: 'GetObject',
        region: 'ap-beijing',
        bucket: 'my-bucket-1250000000',
        prefix: 'download/',
      );

      final encoded = scope.encode() as List<Object?>;
      expect(encoded.length, equals(4));

      final decoded = STSCredentialScope.decode(encoded);
      expect(decoded.action, equals('GetObject'));
      expect(decoded.region, equals('ap-beijing'));
      expect(decoded.bucket, equals('my-bucket-1250000000'));
      expect(decoded.prefix, equals('download/'));
    });
  });

  group('SessionQCloudCredentials 测试', () {
    test('SessionQCloudCredentials 应该正确初始化', () {
      final credentials = SessionQCloudCredentials(
        secretId: 'test-secret-id',
        secretKey: 'test-secret-key',
        token: 'test-token',
        startTime: 1704067200,
        expiredTime: 1704070800,
      );

      expect(credentials.secretId, equals('test-secret-id'));
      expect(credentials.secretKey, equals('test-secret-key'));
      expect(credentials.token, equals('test-token'));
      expect(credentials.startTime, equals(1704067200));
      expect(credentials.expiredTime, equals(1704070800));
    });

    test('SessionQCloudCredentials encode/decode 应该正确工作', () {
      final credentials = SessionQCloudCredentials(
        secretId: 'my-secret-id',
        secretKey: 'my-secret-key',
        token: 'my-token',
        expiredTime: 1704153600,
      );

      final encoded = credentials.encode() as List<Object?>;
      expect(encoded.length, equals(5));

      final decoded = SessionQCloudCredentials.decode(encoded);
      expect(decoded.secretId, equals('my-secret-id'));
      expect(decoded.secretKey, equals('my-secret-key'));
      expect(decoded.token, equals('my-token'));
      expect(decoded.startTime, isNull);
      expect(decoded.expiredTime, equals(1704153600));
    });
  });

  group('CosXmlResult 测试', () {
    test('CosXmlResult 应该正确初始化', () {
      final result = CosXmlResult(
        eTag: '"abc123"',
        accessUrl: 'https://bucket.cos.region.myqcloud.com/key',
      );

      expect(result.eTag, equals('"abc123"'));
      expect(result.accessUrl, equals('https://bucket.cos.region.myqcloud.com/key'));
    });

    test('CosXmlResult encode/decode 应该正确工作', () {
      final result = CosXmlResult(
        eTag: '"def456"',
        accessUrl: 'https://example.com/file',
        callbackResult: CallbackResult(
          status: 200,
          callbackBody: '{"success": true}',
        ),
      );

      final encoded = result.encode() as List<Object?>;
      expect(encoded.length, equals(3));

      final decoded = CosXmlResult.decode(encoded);
      expect(decoded.eTag, equals('"def456"'));
      expect(decoded.accessUrl, equals('https://example.com/file'));
      expect(decoded.callbackResult?.status, equals(200));
      expect(decoded.callbackResult?.callbackBody, equals('{"success": true}'));
    });
  });

  group('CallbackResult 测试', () {
    test('CallbackResult 成功状态应该正确初始化', () {
      final result = CallbackResult(
        status: 200,
        callbackBody: '{"result": "ok"}',
      );

      expect(result.status, equals(200));
      expect(result.callbackBody, equals('{"result": "ok"}'));
      expect(result.error, isNull);
    });

    test('CallbackResult 失败状态应该正确初始化', () {
      final result = CallbackResult(
        status: 203,
        error: CallbackResultError(
          code: 'CallbackFailed',
          message: 'Callback execution failed',
        ),
      );

      expect(result.status, equals(203));
      expect(result.callbackBody, isNull);
      expect(result.error?.code, equals('CallbackFailed'));
      expect(result.error?.message, equals('Callback execution failed'));
    });

    test('CallbackResult encode/decode 应该正确工作', () {
      final result = CallbackResult(
        status: 200,
        callbackBody: '{"data": "test"}',
      );

      final encoded = result.encode() as List<Object?>;
      final decoded = CallbackResult.decode(encoded);

      expect(decoded.status, equals(200));
      expect(decoded.callbackBody, equals('{"data": "test"}'));
    });
  });

  group('CallbackResultError 测试', () {
    test('CallbackResultError 应该正确初始化', () {
      final error = CallbackResultError(
        code: 'InvalidRequest',
        message: 'The request is invalid',
      );

      expect(error.code, equals('InvalidRequest'));
      expect(error.message, equals('The request is invalid'));
    });

    test('CallbackResultError encode/decode 应该正确工作', () {
      final error = CallbackResultError(
        code: 'ServerError',
        message: 'Internal server error',
      );

      final encoded = error.encode() as List<Object?>;
      final decoded = CallbackResultError.decode(encoded);

      expect(decoded.code, equals('ServerError'));
      expect(decoded.message, equals('Internal server error'));
    });
  });

  group('CosXmlClientException 测试', () {
    test('CosXmlClientException 应该正确初始化', () {
      final exception = CosXmlClientException(
        errorCode: 10001,
        message: 'Network error',
        details: 'Connection timeout',
      );

      expect(exception.errorCode, equals(10001));
      expect(exception.message, equals('Network error'));
      expect(exception.details, equals('Connection timeout'));
    });

    test('CosXmlClientException encode/decode 应该正确工作', () {
      final exception = CosXmlClientException(
        errorCode: 10002,
        message: 'Invalid parameter',
      );

      final encoded = exception.encode() as List<Object?>;
      final decoded = CosXmlClientException.decode(encoded);

      expect(decoded.errorCode, equals(10002));
      expect(decoded.message, equals('Invalid parameter'));
    });
  });

  group('CosXmlServiceException 测试', () {
    test('CosXmlServiceException 应该正确初始化', () {
      final exception = CosXmlServiceException(
        statusCode: 403,
        httpMsg: 'Forbidden',
        requestId: 'NjA1ZDQ2NzZfNjE4',
        errorCode: 'AccessDenied',
        errorMessage: 'Access Denied',
        serviceName: 'cos',
      );

      expect(exception.statusCode, equals(403));
      expect(exception.httpMsg, equals('Forbidden'));
      expect(exception.requestId, equals('NjA1ZDQ2NzZfNjE4'));
      expect(exception.errorCode, equals('AccessDenied'));
      expect(exception.errorMessage, equals('Access Denied'));
      expect(exception.serviceName, equals('cos'));
    });

    test('CosXmlServiceException encode/decode 应该正确工作', () {
      final exception = CosXmlServiceException(
        statusCode: 404,
        httpMsg: 'Not Found',
        errorCode: 'NoSuchKey',
        errorMessage: 'The specified key does not exist',
      );

      final encoded = exception.encode() as List<Object?>;
      final decoded = CosXmlServiceException.decode(encoded);

      expect(decoded.statusCode, equals(404));
      expect(decoded.httpMsg, equals('Not Found'));
      expect(decoded.errorCode, equals('NoSuchKey'));
    });
  });

  group('Owner 测试', () {
    test('Owner 应该正确初始化', () {
      final owner = Owner(
        id: 'qcs::cam::uin/100000000001:uin/100000000001',
        disPlayName: 'owner-name',
      );

      expect(owner.id, equals('qcs::cam::uin/100000000001:uin/100000000001'));
      expect(owner.disPlayName, equals('owner-name'));
    });

    test('Owner encode/decode 应该正确工作', () {
      final owner = Owner(
        id: 'test-owner-id',
        disPlayName: 'Test Owner',
      );

      final encoded = owner.encode() as List<Object?>;
      final decoded = Owner.decode(encoded);

      expect(decoded.id, equals('test-owner-id'));
      expect(decoded.disPlayName, equals('Test Owner'));
    });
  });

  group('Bucket 测试', () {
    test('Bucket 应该正确初始化', () {
      final bucket = Bucket(
        name: 'my-bucket-1250000000',
        location: 'ap-guangzhou',
        createDate: '2024-01-01T00:00:00Z',
        type: 'normal',
      );

      expect(bucket.name, equals('my-bucket-1250000000'));
      expect(bucket.location, equals('ap-guangzhou'));
      expect(bucket.createDate, equals('2024-01-01T00:00:00Z'));
      expect(bucket.type, equals('normal'));
    });

    test('Bucket encode/decode 应该正确工作', () {
      final bucket = Bucket(
        name: 'test-bucket-1250000000',
        location: 'ap-beijing',
        createDate: '2024-06-01T12:00:00Z',
      );

      final encoded = bucket.encode() as List<Object?>;
      final decoded = Bucket.decode(encoded);

      expect(decoded.name, equals('test-bucket-1250000000'));
      expect(decoded.location, equals('ap-beijing'));
      expect(decoded.createDate, equals('2024-06-01T12:00:00Z'));
    });
  });

  group('ListAllMyBuckets 测试', () {
    test('ListAllMyBuckets 应该正确初始化', () {
      final listBuckets = ListAllMyBuckets(
        owner: Owner(id: 'owner-id'),
        buckets: [
          Bucket(name: 'bucket1-1250000000'),
          Bucket(name: 'bucket2-1250000000'),
        ],
      );

      expect(listBuckets.owner.id, equals('owner-id'));
      expect(listBuckets.buckets.length, equals(2));
      expect(listBuckets.buckets[0]?.name, equals('bucket1-1250000000'));
    });
  });

  group('Content 测试', () {
    test('Content 应该正确初始化', () {
      final content = Content(
        key: 'folder/file.txt',
        lastModified: '2024-01-15T10:30:00Z',
        eTag: '"abc123def456"',
        size: 2048,
        owner: Owner(id: 'owner-id'),
        storageClass: 'STANDARD',
      );

      expect(content.key, equals('folder/file.txt'));
      expect(content.lastModified, equals('2024-01-15T10:30:00Z'));
      expect(content.eTag, equals('"abc123def456"'));
      expect(content.size, equals(2048));
      expect(content.storageClass, equals('STANDARD'));
    });

    test('Content encode/decode 应该正确工作', () {
      final content = Content(
        key: 'test/path/file.pdf',
        lastModified: '2024-02-01T08:00:00Z',
        eTag: '"xyz789"',
        size: 4096,
        owner: Owner(id: 'test-owner'),
        storageClass: 'STANDARD_IA',
      );

      final encoded = content.encode() as List<Object?>;
      final decoded = Content.decode(encoded);

      expect(decoded.key, equals('test/path/file.pdf'));
      expect(decoded.size, equals(4096));
      expect(decoded.storageClass, equals('STANDARD_IA'));
    });
  });

  group('BucketContents 测试', () {
    test('BucketContents 应该正确初始化', () {
      final contents = BucketContents(
        name: 'my-bucket-1250000000',
        maxKeys: 1000,
        isTruncated: false,
        prefix: 'uploads/',
        marker: 'file100.txt',
        contentsList: [
          Content(
            key: 'uploads/file1.txt',
            lastModified: '2024-01-01T00:00:00Z',
            eTag: '"etag1"',
            size: 100,
            owner: Owner(id: 'owner'),
            storageClass: 'STANDARD',
          ),
        ],
        commonPrefixesList: [
          CommonPrefixes(prefix: 'uploads/subfolder/'),
        ],
      );

      expect(contents.name, equals('my-bucket-1250000000'));
      expect(contents.maxKeys, equals(1000));
      expect(contents.isTruncated, isFalse);
      expect(contents.contentsList.length, equals(1));
      expect(contents.commonPrefixesList.length, equals(1));
    });
  });

  group('CommonPrefixes 测试', () {
    test('CommonPrefixes 应该正确初始化', () {
      final prefix = CommonPrefixes(prefix: 'folder/subfolder/');
      expect(prefix.prefix, equals('folder/subfolder/'));
    });

    test('CommonPrefixes encode/decode 应该正确工作', () {
      final prefix = CommonPrefixes(prefix: 'test/path/');

      final encoded = prefix.encode() as List<Object?>;
      final decoded = CommonPrefixes.decode(encoded);

      expect(decoded.prefix, equals('test/path/'));
    });
  });

  group('LogEntity 测试', () {
    test('LogEntity 应该正确初始化', () {
      final entity = LogEntity(
        timestamp: 1704067200000,
        level: LogLevel.info,
        category: LogCategory.network,
        tag: 'CosSDK',
        message: 'Upload completed',
        threadName: 'main',
        extras: {'key': 'value'},
      );

      expect(entity.timestamp, equals(1704067200000));
      expect(entity.level, equals(LogLevel.info));
      expect(entity.category, equals(LogCategory.network));
      expect(entity.tag, equals('CosSDK'));
      expect(entity.message, equals('Upload completed'));
      expect(entity.threadName, equals('main'));
      expect(entity.extras?['key'], equals('value'));
    });

    test('LogEntity encode/decode 应该正确工作', () {
      final entity = LogEntity(
        timestamp: 1704153600000,
        level: LogLevel.error,
        category: LogCategory.error,
        tag: 'Error',
        message: 'Something went wrong',
        threadName: 'worker',
        throwable: 'NullPointerException',
      );

      final encoded = entity.encode() as List<Object?>;
      final decoded = LogEntity.decode(encoded);

      expect(decoded.timestamp, equals(1704153600000));
      expect(decoded.level, equals(LogLevel.error));
      expect(decoded.category, equals(LogCategory.error));
      expect(decoded.message, equals('Something went wrong'));
      expect(decoded.throwable, equals('NullPointerException'));
    });
  });
}
