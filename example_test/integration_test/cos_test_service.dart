import 'dart:collection';

import 'package:cos_example_test/lib/cos.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cos_example_test/lib/pigeon.dart';

import 'common/constant.dart';

/// 按照顺序执行，将是一个测试闭环
class TestService {
  static Future<void> getService() async {
    // 检查DefaultService是否注册
    if(!Cos().hasDefaultService()){
      fail("DefaultService unregistered");
    }

    try {
      ListAllMyBuckets listAllMyBuckets = await Cos().getDefaultService().getService();
      print(listAllMyBuckets);
      expect(listAllMyBuckets, isNotNull);
    } catch (e) {
      print(e);
      fail(e.toString());
    }
  }

  static Future<void> headObject() async {
    try {
      Map<String?, String?> header = await Cos().getDefaultService().headObject(
          Constant.PERSIST_BUCKET,
          Constant.PERSIST_BUCKET_SMALL_OBJECT_PATH
      );
      print(header);
      expect(header, isNotNull);
    } catch (e) {
      print(e);
      fail(e.toString());
    }
  }

  static Future<void> getObjectUrl() async {
    try {
      String url = await Cos().getDefaultService().getObjectUrl(
          Constant.PERSIST_BUCKET,
          Constant.PERSIST_BUCKET_REGION,
          Constant.PERSIST_BUCKET_SMALL_OBJECT_PATH
      );
      print(url);
      expect(url, isNotNull);
    } catch (e) {
      print(e);
      fail(e.toString());
    }
  }

  static Future<void> getPresignedUrl() async {
    try {
      HashMap<String, String> parameters = HashMap();
      parameters["test1k"] = "test1v";
      parameters["test2k"] = "test2v";
      String url = await Cos().getDefaultService().getPresignedUrl(
          Constant.PERSIST_BUCKET,
          Constant.PERSIST_BUCKET_SMALL_OBJECT_PATH,
          signValidTime: 500,
          signHost: false,
          parameters: parameters
      );
      print(url);
      expect(url, isNotNull);
    } catch (e) {
      print(e);
      fail(e.toString());
    }
  }

  static Future<void> doesObjectExist() async {
    try {
      bool isExist = await Cos().getDefaultService().doesObjectExist(Constant.PERSIST_BUCKET, Constant.PERSIST_BUCKET_BIG_OBJECT_PATH);
      expect(isExist, isTrue);
    } catch (e) {
      print(e);
      fail(e.toString());
    }
  }

  static Future<void> deleteObject() async {
    try {
      await Cos().getDefaultService().deleteObject(Constant.PERSIST_BUCKET, Constant.PERSIST_BUCKET_SMALL_OBJECT_PATH);
      expect(true, isTrue);
    } catch (e) {
      print(e);
      fail(e.toString());
    }
  }

  static Future<void> doesObjectExistError() async {
    try {
      bool isExist = await Cos().getDefaultService().doesObjectExist(Constant.PERSIST_BUCKET, Constant.PERSIST_BUCKET_SMALL_OBJECT_PATH);
      // bool isExist = await Cos().getDefaultService().doesObjectExist(Constant.PERSIST_BUCKET, Constant.PERSIST_BUCKET_SMALL_OBJECT_PATH+"not exist");
      expect(isExist, isFalse);
    } catch (e) {
      print(e);
      fail(e.toString());
    }
  }

  static Future<void> preBuildConnection() async {
    try {
      await Cos().getDefaultService().preBuildConnection(Constant.PERSIST_BUCKET);
      expect(true, isTrue);
    } catch (e) {
      print(e);
      fail(e.toString());
    }
  }

  static Future<void> getBucket() async {
    try {
      BucketContents bucketContents = await Cos().getDefaultService().getBucket(Constant.PERSIST_BUCKET);
      print(bucketContents);
      expect(bucketContents, isNotNull);
    } catch (e) {
      print(e);
      fail(e.toString());
    }
  }

  static Future<void> putBucket() async {
    try {
      await Cos().getDefaultService().putBucket(
          Constant.TEMP_BUCKET,
          region: Constant.TEMP_BUCKET_REGION,
          enableMAZ: false
      );
      expect(true, isTrue);
    } catch (e) {
      print(e);
      fail(e.toString());
    }
  }

  static Future<void> headBucket() async {
    try {
      Map<String?, String?> header = await Cos().getDefaultService().headBucket(Constant.TEMP_BUCKET, region: Constant.TEMP_BUCKET_REGION);
      print(header);
      expect(header, isNotNull);
    } catch (e) {
      print(e);
      fail(e.toString());
    }
  }

  static Future<void> putBucketAccelerate() async {
    try {
      await Cos().getDefaultService().putBucketAccelerate(Constant.TEMP_BUCKET, true, region: Constant.TEMP_BUCKET_REGION);
      expect(true, isTrue);
    } catch (e) {
      print(e);
      fail(e.toString());
    }
  }

  static Future<void> getBucketAccelerate() async {
    try {
      bool isAccelerate = await Cos().getDefaultService().getBucketAccelerate(Constant.TEMP_BUCKET, region: Constant.TEMP_BUCKET_REGION);
      expect(isAccelerate, isTrue);
    } catch (e) {
      print(e);
      fail(e.toString());
    }
  }

  static Future<void> getBucketLocation() async {
    try {
      String location = await Cos().getDefaultService().getBucketLocation(Constant.TEMP_BUCKET, region: Constant.TEMP_BUCKET_REGION);
      print(location);
      expect(location, isNotNull);
    } catch (e) {
      print(e);
      fail(e.toString());
    }
  }

  static Future<void> putBucketVersioning() async {
    try {
      await Cos().getDefaultService().putBucketVersioning(Constant.TEMP_BUCKET, false, region: Constant.TEMP_BUCKET_REGION);
      expect(true, isTrue);
    } catch (e) {
      print(e);
      fail(e.toString());
    }
  }

  static Future<void> getBucketVersioning() async {
    try {
      bool isVersioning = await Cos().getDefaultService().getBucketVersioning(Constant.TEMP_BUCKET, region: Constant.TEMP_BUCKET_REGION);
      expect(isVersioning, isFalse);
    } catch (e) {
      print(e);
      fail(e.toString());
    }
  }

  static Future<void> doesBucketExist() async {
    CosXmlServiceConfig serviceConfig = CosXmlServiceConfig(
      region: Constant.TEMP_BUCKET_REGION,
      isDebuggable: true,
    );
    await Cos().registerService(Constant.TEMP_BUCKET_REGION, serviceConfig);

    if(!Cos().hasService(Constant.TEMP_BUCKET_REGION)){
      fail(Constant.TEMP_BUCKET_REGION+" service unregistered");
    }

    try {
      bool isExist = await Cos().getService(Constant.TEMP_BUCKET_REGION).doesBucketExist(Constant.TEMP_BUCKET);
      expect(isExist, isTrue);
    } catch (e) {
      print(e);
      fail(e.toString());
    }
  }

  static Future<void> deleteBucket() async {
    try {
      await Cos().getDefaultService().deleteBucket(Constant.TEMP_BUCKET, region: Constant.TEMP_BUCKET_REGION);
      expect(true, isTrue);
    } catch (e) {
      print(e);
      fail(e.toString());
    }
  }

  static Future<void> doesBucketExistError() async {
    CosXmlServiceConfig serviceConfig = CosXmlServiceConfig(
      region: Constant.TEMP_BUCKET_REGION,
      isDebuggable: true,
    );
    await Cos().registerService(Constant.TEMP_BUCKET_REGION, serviceConfig);
    if(!Cos().hasService(Constant.TEMP_BUCKET_REGION)){
      fail(Constant.TEMP_BUCKET_REGION+" service unregistered");
    }

    try {
      bool isExist = await Cos().getService(Constant.TEMP_BUCKET_REGION).doesBucketExist(Constant.TEMP_BUCKET);
      // bool isExist = await Cos().getDefaultService().doesBucketExist("mobile-not-exist-1253960454");
      expect(isExist, isFalse);
    } catch (e) {
      print(e);
      fail(e.toString());
    }
  }

  static Future<void> cancelAll() async {
    try {
      await Cos().getDefaultService().cancelAll();
      expect(true, isTrue);
    } catch (e) {
      print(e);
      fail(e.toString());
    }
  }
}
