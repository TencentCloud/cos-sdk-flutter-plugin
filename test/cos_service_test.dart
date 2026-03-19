// CosService 单元测试
//
// 测试 CosService 类的各种方法
// 使用 Mock Channel 模拟原生 API 响应

import 'package:flutter_test/flutter_test.dart';
import 'package:tencentcloud_cos_sdk_plugin/pigeon.dart';
import 'package:tencentcloud_cos_sdk_plugin/cos_service.dart';

import 'test_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CosService 基本测试', () {
    late CosService cosService;

    setUpAll(() {
      TestHelper.setupAll();
    });

    tearDownAll(() {
      TestHelper.tearDownAll();
    });

    setUp(() {
      cosService = CosService('test-service-key');
    });

    test('CosService 初始化应该正确设置 serviceKey', () {
      expect(cosService.serviceKey, equals('test-service-key'));
    });

    test('CosService 应该有 cosApi 实例', () {
      expect(cosService.cosApi, isNotNull);
    });
  });

  group('CosService Object 操作测试', () {
    late CosService cosService;

    setUpAll(() {
      TestHelper.setupAll();
    });

    tearDownAll(() {
      TestHelper.tearDownAll();
    });

    setUp(() {
      cosService = CosService('test-service-key');
    });

    test('headObject 应该返回对象头信息', () async {
      final result = await cosService.headObject(
        'test-bucket-1250000000',
        'test/path/file.txt',
        region: 'ap-guangzhou',
      );
      expect(result, isNotNull);
      expect(result, isA<Map<String?, String?>>());
      expect(TestHelper.cosServiceApiChannel.headObjectCalled, isTrue);
    });

    test('headObject 带 versionId 应该正常工作', () async {
      final result = await cosService.headObject(
        'test-bucket-1250000000',
        'test/path/file.txt',
        region: 'ap-guangzhou',
        versionId: 'version-123',
      );
      expect(result, isNotNull);
    });

    test('headObject 带 sessionCredentials 应该正常工作', () async {
      final credentials = SessionQCloudCredentials(
        secretId: 'test-id',
        secretKey: 'test-key',
        token: 'test-token',
        expiredTime: 1735689600,
      );
      final result = await cosService.headObject(
        'test-bucket-1250000000',
        'test/path/file.txt',
        sessionCredentials: credentials,
      );
      expect(result, isNotNull);
    });

    test('deleteObject 应该成功删除对象', () async {
      await cosService.deleteObject(
        'test-bucket-1250000000',
        'test/path/file.txt',
        region: 'ap-guangzhou',
      );
      expect(TestHelper.cosServiceApiChannel.deleteObjectCalled, isTrue);
    });

    test('deleteObject 带 versionId 应该正常工作', () async {
      await cosService.deleteObject(
        'test-bucket-1250000000',
        'test/path/file.txt',
        versionId: 'version-123',
      );
      expect(true, isTrue);
    });

    test('doesObjectExist 应该返回布尔值', () async {
      final exists = await cosService.doesObjectExist(
        'test-bucket-1250000000',
        'test/path/file.txt',
      );
      expect(exists, isA<bool>());
      expect(TestHelper.cosServiceApiChannel.doesObjectExistCalled, isTrue);
    });
  });

  group('CosService URL 操作测试', () {
    late CosService cosService;

    setUpAll(() {
      TestHelper.setupAll();
    });

    tearDownAll(() {
      TestHelper.tearDownAll();
    });

    setUp(() {
      cosService = CosService('test-service-key');
    });

    test('getObjectUrl 应该返回未签名链接', () async {
      final url = await cosService.getObjectUrl(
        'test-bucket-1250000000',
        'ap-guangzhou',
        'test/path/file.txt',
      );
      expect(url, isNotEmpty);
      expect(TestHelper.cosServiceApiChannel.getObjectUrlCalled, isTrue);
    });

    test('getPresignedUrl 应该返回预签名链接', () async {
      final url = await cosService.getPresignedUrl(
        'test-bucket-1250000000',
        'test/path/file.txt',
      );
      expect(url, isNotEmpty);
      expect(TestHelper.cosServiceApiChannel.getPresignedUrlCalled, isTrue);
    });

    test('getPresignedUrl 带完整参数应该正常工作', () async {
      final url = await cosService.getPresignedUrl(
        'test-bucket-1250000000',
        'test/path/file.txt',
        signValidTime: 3600,
        signHost: true,
        parameters: {'response-content-type': 'image/png'},
        region: 'ap-guangzhou',
      );
      expect(url, isNotEmpty);
    });

    test('getPresignedUrl 带 sessionCredentials 应该正常工作', () async {
      final credentials = SessionQCloudCredentials(
        secretId: 'test-id',
        secretKey: 'test-key',
        token: 'test-token',
        expiredTime: 1735689600,
      );
      final url = await cosService.getPresignedUrl(
        'test-bucket-1250000000',
        'test/path/file.txt',
        sessionCredentials: credentials,
      );
      expect(url, isNotEmpty);
    });
  });

  group('CosService Bucket 操作测试', () {
    late CosService cosService;

    setUpAll(() {
      TestHelper.setupAll();
    });

    tearDownAll(() {
      TestHelper.tearDownAll();
    });

    setUp(() {
      cosService = CosService('test-service-key');
    });

    test('getService 应该返回 Bucket 列表', () async {
      final result = await cosService.getService();
      expect(result, isNotNull);
      expect(result, isA<ListAllMyBuckets>());
      expect(TestHelper.cosServiceApiChannel.getServiceCalled, isTrue);
    });

    test('getService 带 sessionCredentials 应该正常工作', () async {
      final credentials = SessionQCloudCredentials(
        secretId: 'test-id',
        secretKey: 'test-key',
        token: 'test-token',
        expiredTime: 1735689600,
      );
      final result = await cosService.getService(sessionCredentials: credentials);
      expect(result, isNotNull);
    });

    test('getBucket 应该返回 Bucket 内容', () async {
      final result = await cosService.getBucket('test-bucket-1250000000');
      expect(result, isNotNull);
      expect(result, isA<BucketContents>());
      expect(TestHelper.cosServiceApiChannel.getBucketCalled, isTrue);
    });

    test('getBucket 带完整参数应该正常工作', () async {
      final result = await cosService.getBucket(
        'test-bucket-1250000000',
        region: 'ap-guangzhou',
        prefix: 'uploads/',
        delimiter: '/',
        encodingType: 'url',
        marker: 'file100.txt',
        maxKeys: 100,
      );
      expect(result, isNotNull);
    });

    test('putBucket 应该创建 Bucket', () async {
      await cosService.putBucket('new-bucket-1250000000');
      expect(TestHelper.cosServiceApiChannel.putBucketCalled, isTrue);
    });

    test('putBucket 带完整参数应该正常工作', () async {
      await cosService.putBucket(
        'new-bucket-1250000000',
        region: 'ap-guangzhou',
        enableMAZ: true,
        cosacl: 'public-read',
        readAccount: 'uin/100000000001',
        writeAccount: 'uin/100000000002',
        readWriteAccount: 'uin/100000000003',
      );
      expect(true, isTrue);
    });

    test('headBucket 应该返回 Bucket 头信息', () async {
      final result = await cosService.headBucket('test-bucket-1250000000');
      expect(result, isNotNull);
      expect(result, isA<Map<String?, String?>>());
      expect(TestHelper.cosServiceApiChannel.headBucketCalled, isTrue);
    });

    test('headBucket 带 region 应该正常工作', () async {
      final result = await cosService.headBucket(
        'test-bucket-1250000000',
        region: 'ap-guangzhou',
      );
      expect(result, isNotNull);
    });

    test('deleteBucket 应该删除 Bucket', () async {
      await cosService.deleteBucket('test-bucket-1250000000');
      expect(TestHelper.cosServiceApiChannel.deleteBucketCalled, isTrue);
    });

    test('deleteBucket 带 region 应该正常工作', () async {
      await cosService.deleteBucket(
        'test-bucket-1250000000',
        region: 'ap-guangzhou',
      );
      expect(true, isTrue);
    });

    test('doesBucketExist 应该返回布尔值', () async {
      final exists = await cosService.doesBucketExist('test-bucket-1250000000');
      expect(exists, isA<bool>());
      expect(TestHelper.cosServiceApiChannel.doesBucketExistCalled, isTrue);
    });
  });

  group('CosService Bucket 配置操作测试', () {
    late CosService cosService;

    setUpAll(() {
      TestHelper.setupAll();
    });

    tearDownAll(() {
      TestHelper.tearDownAll();
    });

    setUp(() {
      cosService = CosService('test-service-key');
    });

    test('getBucketAccelerate 应该返回加速状态', () async {
      final enabled = await cosService.getBucketAccelerate('test-bucket-1250000000');
      expect(enabled, isA<bool>());
    });

    test('getBucketAccelerate 带 region 应该正常工作', () async {
      final enabled = await cosService.getBucketAccelerate(
        'test-bucket-1250000000',
        region: 'ap-guangzhou',
      );
      expect(enabled, isA<bool>());
    });

    test('putBucketAccelerate 应该设置加速状态', () async {
      await cosService.putBucketAccelerate('test-bucket-1250000000', true);
      await cosService.putBucketAccelerate('test-bucket-1250000000', false);
      expect(true, isTrue);
    });

    test('putBucketAccelerate 带 region 应该正常工作', () async {
      await cosService.putBucketAccelerate(
        'test-bucket-1250000000',
        true,
        region: 'ap-guangzhou',
      );
      expect(true, isTrue);
    });

    test('getBucketLocation 应该返回地域', () async {
      final location = await cosService.getBucketLocation('test-bucket-1250000000');
      expect(location, isNotEmpty);
    });

    test('getBucketLocation 带 region 应该正常工作', () async {
      final location = await cosService.getBucketLocation(
        'test-bucket-1250000000',
        region: 'ap-guangzhou',
      );
      expect(location, isNotEmpty);
    });

    test('getBucketVersioning 应该返回版本控制状态', () async {
      final enabled = await cosService.getBucketVersioning('test-bucket-1250000000');
      expect(enabled, isA<bool>());
    });

    test('getBucketVersioning 带 region 应该正常工作', () async {
      final enabled = await cosService.getBucketVersioning(
        'test-bucket-1250000000',
        region: 'ap-guangzhou',
      );
      expect(enabled, isA<bool>());
    });

    test('putBucketVersioning 应该设置版本控制状态', () async {
      await cosService.putBucketVersioning('test-bucket-1250000000', true);
      await cosService.putBucketVersioning('test-bucket-1250000000', false);
      expect(true, isTrue);
    });

    test('putBucketVersioning 带 region 应该正常工作', () async {
      await cosService.putBucketVersioning(
        'test-bucket-1250000000',
        true,
        region: 'ap-guangzhou',
      );
      expect(true, isTrue);
    });
  });

  group('CosService 其他操作测试', () {
    late CosService cosService;

    setUpAll(() {
      TestHelper.setupAll();
    });

    tearDownAll(() {
      TestHelper.tearDownAll();
    });

    setUp(() {
      cosService = CosService('test-service-key');
    });

    test('preBuildConnection 应该预建立连接', () async {
      await cosService.preBuildConnection('test-bucket-1250000000');
      expect(TestHelper.cosServiceApiChannel.preBuildConnectionCalled, isTrue);
    });

    test('cancelAll 应该取消所有请求', () async {
      await cosService.cancelAll();
      expect(TestHelper.cosServiceApiChannel.cancelAllCalled, isTrue);
    });
  });
}
