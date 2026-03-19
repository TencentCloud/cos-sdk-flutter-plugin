// TransferTask 单元测试
//
// 测试 TransferTask 类的暂停、恢复、取消功能

import 'package:flutter_test/flutter_test.dart';
import 'package:tencentcloud_cos_sdk_plugin/transfer_task.dart';
import 'package:tencentcloud_cos_sdk_plugin/pigeon.dart';

import 'test_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TransferTask 测试', () {
    setUpAll(() {
      TestHelper.setupAll();
    });

    tearDownAll(() {
      TestHelper.tearDownAll();
    });

    test('TransferTask 初始化应该正确', () {
      final transferApi = CosTransferApi();
      final task = TransferTask('test-transfer-key', 'mock-task-id', transferApi);
      expect(task, isNotNull);
    });

    test('pause 应该调用原生 API', () async {
      final transferApi = CosTransferApi();
      final task = TransferTask('test-transfer-key', 'mock-task-id', transferApi);
      
      await task.pause();
      expect(TestHelper.cosTransferApiChannel.pauseCalled, isTrue);
    });

    test('resume 应该调用原生 API', () async {
      final transferApi = CosTransferApi();
      final task = TransferTask('test-transfer-key', 'mock-task-id', transferApi);
      
      await task.resume();
      expect(TestHelper.cosTransferApiChannel.resumeCalled, isTrue);
    });

    test('cancel 应该调用原生 API', () async {
      final transferApi = CosTransferApi();
      final task = TransferTask('test-transfer-key', 'mock-task-id', transferApi);
      
      await task.cancel();
      expect(TestHelper.cosTransferApiChannel.cancelCalled, isTrue);
    });

    test('暂停后恢复应该正常工作', () async {
      final transferApi = CosTransferApi();
      final task = TransferTask('test-transfer-key', 'mock-task-id', transferApi);
      
      await task.pause();
      await task.resume();
      
      expect(TestHelper.cosTransferApiChannel.pauseCalled, isTrue);
      expect(TestHelper.cosTransferApiChannel.resumeCalled, isTrue);
    });

    test('暂停后取消应该正常工作', () async {
      final transferApi = CosTransferApi();
      final task = TransferTask('test-transfer-key', 'mock-task-id', transferApi);
      
      await task.pause();
      await task.cancel();
      
      expect(TestHelper.cosTransferApiChannel.pauseCalled, isTrue);
      expect(TestHelper.cosTransferApiChannel.cancelCalled, isTrue);
    });
  });
}
