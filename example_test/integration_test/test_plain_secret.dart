import 'config/config.dart';
import 'common/constant.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:cos_example_test/lib/cos.dart';
import 'package:cos_example_test/lib/pigeon.dart';

import 'cos_test_service.dart';
import 'cos_test_transfer.dart';

void main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  //永久秘钥初始化COS
  await Cos().initWithPlainSecret(TestConst().SECRET_ID, TestConst().SECRET_KEY);

  await Cos().registerDefaultService(Constant.serviceConfig);
  await Cos().registerDefaultTransferManger(Constant.serviceConfig, TransferConfig());

  await Cos().setCloseBeacon(true);

  group('PlainSecret', () {
    // 先上传一个文件 供一下service测试
    testWidgets('uploadSamll', (tester) async {
      bool isSuccess = await TestTransfer.uploadSamll();
      expect(isSuccess, isTrue);
    });
    testWidgets('getService', (tester) async {
      await TestService.getService();
    });
    testWidgets('headObject', (tester) async {
      await TestService.headObject();
    });
    testWidgets('getObjectUrl', (tester) async {
      await TestService.getObjectUrl();
    });
    testWidgets('getPresignedUrl', (tester) async {
      await TestService.getPresignedUrl();
    });
    testWidgets('doesObjectExist', (tester) async {
      await TestService.doesObjectExist();
    });
    testWidgets('deleteObject', (tester) async {
      await TestService.deleteObject();
    });
    testWidgets('doesObjectExistError', (tester) async {
      await TestService.doesObjectExistError();
    });
    testWidgets('preBuildConnection', (tester) async {
      await TestService.preBuildConnection();
    });
    testWidgets('getBucket', (tester) async {
      await TestService.getBucket();
    });
    testWidgets('putBucket', (tester) async {
      await TestService.putBucket();
    });
    testWidgets('headBucket', (tester) async {
      await TestService.headBucket();
    });
    testWidgets('putBucketAccelerate', (tester) async {
      await TestService.putBucketAccelerate();
    });
    testWidgets('getBucketAccelerate', (tester) async {
      await Future.delayed(Duration(seconds: 3));
      await TestService.getBucketAccelerate();
    });
    testWidgets('getBucketLocation', (tester) async {
      await TestService.getBucketLocation();
    });
    testWidgets('putBucketVersioning', (tester) async {
      await TestService.putBucketVersioning();
    });
    testWidgets('getBucketVersioning', (tester) async {
      await Future.delayed(Duration(seconds: 3));
      await TestService.getBucketVersioning();
    });
    testWidgets('doesBucketExist', (tester) async {
      await TestService.doesBucketExist();
    });
    testWidgets('deleteBucket', (tester) async {
      await TestService.deleteBucket();
    });
    testWidgets('doesBucketExistError', (tester) async {
      await TestService.doesBucketExistError();
    });
    testWidgets('cancelAll', (tester) async {
      await TestService.cancelAll();
    });

    testWidgets('uploadSamllError', (tester) async {
      await TestTransfer.uploadSamllError();
    });
    testWidgets('uploadBig', (tester) async {
      await TestTransfer.uploadBig();
    });
    testWidgets('uploadBigResume', (tester) async {
      await TestTransfer.uploadBigResume();
    });
    testWidgets('download', (tester) async {
      await TestTransfer.download();
    });
    testWidgets('downloadError', (tester) async {
      await TestTransfer.downloadError();
    });
  });
}
