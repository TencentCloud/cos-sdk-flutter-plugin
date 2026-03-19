// CosTransferManger 单元测试
//
// 测试 CosTransferManger 类的上传、下载等传输功能
// 使用 Mock Channel 模拟原生 API 响应

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:tencentcloud_cos_sdk_plugin/cos_transfer_manger.dart';
import 'package:tencentcloud_cos_sdk_plugin/pigeon.dart';
import 'package:tencentcloud_cos_sdk_plugin/exceptions.dart';
import 'package:tencentcloud_cos_sdk_plugin/enums.dart';

import 'test_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CosTransferManger 基本测试', () {
    late CosTransferManger transferManger;

    setUpAll(() {
      TestHelper.setupAll();
    });

    tearDownAll(() {
      TestHelper.tearDownAll();
    });

    setUp(() {
      transferManger = CosTransferManger('test-transfer-key');
    });

    test('CosTransferManger 初始化应该正确', () {
      expect(transferManger, isNotNull);
    });
  });

  group('CosTransferManger Upload 测试', () {
    late CosTransferManger transferManger;

    setUpAll(() {
      TestHelper.setupAll();
    });

    tearDownAll(() {
      TestHelper.tearDownAll();
    });

    setUp(() {
      transferManger = CosTransferManger('test-transfer-key');
    });

    test('upload 没有 filePath 和 byteArr 时应该抛出异常', () async {
      expect(
        () => transferManger.upload(
          'test-bucket-1250000000',
          'test/path/file.txt',
        ),
        throwsA(isA<IllegalArgumentException>()),
      );
    });

    test('upload 使用 filePath 应该返回 TransferTask', () async {
      final task = await transferManger.upload(
        'test-bucket-1250000000',
        'test/path/file.txt',
        filePath: '/local/path/file.txt',
      );
      expect(task, isNotNull);
      expect(TestHelper.cosTransferApiChannel.uploadCalled, isTrue);
    });

    test('upload 使用 byteArr 应该返回 TransferTask', () async {
      final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      final task = await transferManger.upload(
        'test-bucket-1250000000',
        'test/path/file.txt',
        byteArr: bytes,
      );
      expect(task, isNotNull);
    });

    test('upload 带完整参数应该正常工作', () async {
      bool successCalled = false;
      bool stateCalled = false;
      bool progressCalled = false;
      bool initUploadCalled = false;

      final task = await transferManger.upload(
        'test-bucket-1250000000',
        'test/path/file.txt',
        region: 'ap-guangzhou',
        filePath: '/local/path/file.txt',
        uploadId: 'upload-id-123',
        stroageClass: 'STANDARD',
        trafficLimit: 1048576,
        callbackParam: '{"key": "value"}',
        customHeaders: {'X-Custom-Header': 'custom-value'},
        noSignHeaders: ['Content-Type'],
        resultListener: ResultListener(
          (header, result) {
            successCalled = true;
          },
          (clientException, serviceException) {},
        ),
        stateCallback: (state) {
          stateCalled = true;
        },
        progressCallBack: (complete, target) {
          progressCalled = true;
        },
        initMultipleUploadCallback: (bucket, cosKey, uploadId) {
          initUploadCalled = true;
        },
      );
      expect(task, isNotNull);
    });

    test('upload 带 sessionCredentials 应该正常工作', () async {
      final credentials = SessionQCloudCredentials(
        secretId: 'test-id',
        secretKey: 'test-key',
        token: 'test-token',
        expiredTime: 1735689600,
      );
      final task = await transferManger.upload(
        'test-bucket-1250000000',
        'test/path/file.txt',
        filePath: '/local/path/file.txt',
        sessionCredentials: credentials,
      );
      expect(task, isNotNull);
    });
  });

  group('CosTransferManger Download 测试', () {
    late CosTransferManger transferManger;

    setUpAll(() {
      TestHelper.setupAll();
    });

    tearDownAll(() {
      TestHelper.tearDownAll();
    });

    setUp(() {
      transferManger = CosTransferManger('test-transfer-key');
    });

    test('download 应该返回 TransferTask', () async {
      final task = await transferManger.download(
        'test-bucket-1250000000',
        'test/path/file.txt',
        '/local/save/path/file.txt',
      );
      expect(task, isNotNull);
      expect(TestHelper.cosTransferApiChannel.downloadCalled, isTrue);
    });

    test('download 带完整参数应该正常工作', () async {
      bool successCalled = false;
      bool stateCalled = false;
      bool progressCalled = false;

      final task = await transferManger.download(
        'test-bucket-1250000000',
        'test/path/file.txt',
        '/local/save/path/file.txt',
        region: 'ap-guangzhou',
        versionId: 'version-123',
        trafficLimit: 1048576,
        customHeaders: {'X-Custom-Header': 'custom-value'},
        noSignHeaders: ['Content-Type'],
        resultListener: ResultListener(
          (header, result) {
            successCalled = true;
          },
          (clientException, serviceException) {},
        ),
        stateCallback: (state) {
          stateCalled = true;
        },
        progressCallBack: (complete, target) {
          progressCalled = true;
        },
      );
      expect(task, isNotNull);
    });

    test('download 带 sessionCredentials 应该正常工作', () async {
      final credentials = SessionQCloudCredentials(
        secretId: 'test-id',
        secretKey: 'test-key',
        token: 'test-token',
        expiredTime: 1735689600,
      );
      final task = await transferManger.download(
        'test-bucket-1250000000',
        'test/path/file.txt',
        '/local/save/path/file.txt',
        sessionCredentials: credentials,
      );
      expect(task, isNotNull);
    });
  });

  group('CosTransferManger 回调管理测试', () {
    late CosTransferManger transferManger;

    setUpAll(() {
      TestHelper.setupAll();
    });

    tearDownAll(() {
      TestHelper.tearDownAll();
    });

    setUp(() {
      transferManger = CosTransferManger('test-transfer-key');
    });

    test('runResultSuccessCallBack 应该触发成功回调', () async {
      bool called = false;
      Map<String?, String?>? receivedHeader;
      CosXmlResult? receivedResult;

      // 先上传以注册回调
      final listener = ResultListener(
        (header, result) {
          called = true;
          receivedHeader = header;
          receivedResult = result;
        },
        (clientException, serviceException) {},
      );

      await transferManger.upload(
        'test-bucket-1250000000',
        'test/path/file.txt',
        filePath: '/local/path/file.txt',
        resultListener: listener,
      );

      // 模拟触发成功回调
      final mockHeader = <String?, String?>{'ETag': '"mock-etag"'};
      final mockResult = CosXmlResult(
        eTag: '"mock-etag"',
        accessUrl: 'https://bucket.cos.region.myqcloud.com/key',
      );
      
      transferManger.runResultSuccessCallBack(
        listener.hashCode,
        mockHeader,
        mockResult,
      );

      expect(called, isTrue);
      expect(receivedHeader, equals(mockHeader));
      expect(receivedResult?.eTag, equals(mockResult.eTag));
    });

    test('runResultFailCallBack 应该触发失败回调', () async {
      bool called = false;
      CosXmlClientException? receivedClientException;
      CosXmlServiceException? receivedServiceException;

      final listener = ResultListener(
        (header, result) {},
        (clientException, serviceException) {
          called = true;
          receivedClientException = clientException;
          receivedServiceException = serviceException;
        },
      );

      await transferManger.upload(
        'test-bucket-1250000000',
        'test/path/file.txt',
        filePath: '/local/path/file.txt',
        resultListener: listener,
      );

      // 模拟触发失败回调
      final mockClientException = CosXmlClientException(
        errorCode: 10001,
        message: 'Network error',
      );
      
      transferManger.runResultFailCallBack(
        listener.hashCode,
        mockClientException,
        null,
      );

      expect(called, isTrue);
      expect(receivedClientException?.errorCode, equals(10001));
    });

    test('runStateCallBack 应该触发状态回调', () async {
      TransferState? receivedState;

      StateCallBack stateCallback = (state) {
        receivedState = state;
      };

      await transferManger.upload(
        'test-bucket-1250000000',
        'test/path/file.txt',
        filePath: '/local/path/file.txt',
        stateCallback: stateCallback,
      );

      // 模拟触发状态回调
      transferManger.runStateCallBack(stateCallback.hashCode, 'IN_PROGRESS');

      expect(receivedState, equals(TransferState.IN_PROGRESS));
    });

    test('runProgressCallBack 应该触发进度回调', () async {
      int? receivedComplete;
      int? receivedTarget;

      ProgressCallBack progressCallback = (complete, target) {
        receivedComplete = complete;
        receivedTarget = target;
      };

      await transferManger.upload(
        'test-bucket-1250000000',
        'test/path/file.txt',
        filePath: '/local/path/file.txt',
        progressCallBack: progressCallback,
      );

      // 模拟触发进度回调
      transferManger.runProgressCallBack(progressCallback.hashCode, 50, 100);

      expect(receivedComplete, equals(50));
      expect(receivedTarget, equals(100));
    });

    test('runInitMultipleUploadCallback 应该触发分块上传初始化回调', () async {
      String? receivedBucket;
      String? receivedCosKey;
      String? receivedUploadId;

      InitMultipleUploadCallback initCallback = (bucket, cosKey, uploadId) {
        receivedBucket = bucket;
        receivedCosKey = cosKey;
        receivedUploadId = uploadId;
      };

      await transferManger.upload(
        'test-bucket-1250000000',
        'test/path/file.txt',
        filePath: '/local/path/file.txt',
        initMultipleUploadCallback: initCallback,
      );

      // 模拟触发分块上传初始化回调
      transferManger.runInitMultipleUploadCallback(
        initCallback.hashCode,
        'test-bucket-1250000000',
        'test/path/file.txt',
        'upload-id-123',
      );

      expect(receivedBucket, equals('test-bucket-1250000000'));
      expect(receivedCosKey, equals('test/path/file.txt'));
      expect(receivedUploadId, equals('upload-id-123'));
    });
  });

  group('ResultListener 测试', () {
    test('ResultListener 应该正确初始化', () {
      bool successCalled = false;
      bool failCalled = false;

      final listener = ResultListener(
        (header, result) {
          successCalled = true;
        },
        (clientException, serviceException) {
          failCalled = true;
        },
      );

      expect(listener.successCallBack, isNotNull);
      expect(listener.failCallBack, isNotNull);

      // 测试成功回调
      listener.successCallBack(null, null);
      expect(successCalled, isTrue);

      // 测试失败回调
      listener.failCallBack(null, null);
      expect(failCalled, isTrue);
    });

    test('ResultListener 成功回调应该接收正确参数', () {
      Map<String?, String?>? receivedHeader;
      CosXmlResult? receivedResult;

      final listener = ResultListener(
        (header, result) {
          receivedHeader = header;
          receivedResult = result;
        },
        (clientException, serviceException) {},
      );

      final mockHeader = <String?, String?>{'Content-Length': '1024'};
      final mockResult = CosXmlResult(eTag: '"test-etag"');

      listener.successCallBack(mockHeader, mockResult);

      expect(receivedHeader, equals(mockHeader));
      expect(receivedResult?.eTag, equals('"test-etag"'));
    });

    test('ResultListener 失败回调应该接收正确参数', () {
      CosXmlClientException? receivedClientException;
      CosXmlServiceException? receivedServiceException;

      final listener = ResultListener(
        (header, result) {},
        (clientException, serviceException) {
          receivedClientException = clientException;
          receivedServiceException = serviceException;
        },
      );

      final mockClientException = CosXmlClientException(
        errorCode: 10001,
        message: 'Test error',
      );
      final mockServiceException = CosXmlServiceException(
        statusCode: 403,
        errorCode: 'AccessDenied',
        errorMessage: 'Access Denied',
      );

      listener.failCallBack(mockClientException, mockServiceException);

      expect(receivedClientException?.errorCode, equals(10001));
      expect(receivedServiceException?.statusCode, equals(403));
    });
  });

  group('回调类型定义测试', () {
    test('StateCallBack 应该接收 TransferState', () {
      TransferState? receivedState;
      
      StateCallBack callback = (state) {
        receivedState = state;
      };
      
      callback(TransferState.COMPLETED);
      expect(receivedState, equals(TransferState.COMPLETED));
      
      callback(TransferState.FAILED);
      expect(receivedState, equals(TransferState.FAILED));
    });

    test('ProgressCallBack 应该接收 complete 和 target', () {
      int? receivedComplete;
      int? receivedTarget;
      
      ProgressCallBack callback = (complete, target) {
        receivedComplete = complete;
        receivedTarget = target;
      };
      
      callback(50, 100);
      expect(receivedComplete, equals(50));
      expect(receivedTarget, equals(100));
      
      callback(100, 100);
      expect(receivedComplete, equals(100));
    });

    test('InitMultipleUploadCallback 应该接收 bucket、cosKey 和 uploadId', () {
      String? receivedBucket;
      String? receivedCosKey;
      String? receivedUploadId;
      
      InitMultipleUploadCallback callback = (bucket, cosKey, uploadId) {
        receivedBucket = bucket;
        receivedCosKey = cosKey;
        receivedUploadId = uploadId;
      };
      
      callback('my-bucket', 'path/to/file.txt', 'upload-123');
      expect(receivedBucket, equals('my-bucket'));
      expect(receivedCosKey, equals('path/to/file.txt'));
      expect(receivedUploadId, equals('upload-123'));
    });
  });
}
