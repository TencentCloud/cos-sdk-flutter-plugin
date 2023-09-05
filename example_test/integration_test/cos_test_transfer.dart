import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:cos_example_test/lib/cos.dart';
import 'package:cos_example_test/lib/cos_transfer_manger.dart';
import 'package:cos_example_test/lib/pigeon.dart';
import 'package:cos_example_test/lib/transfer_task.dart';
import 'package:flutter_test/flutter_test.dart';

import 'common/constant.dart';
import 'common/file_utils.dart';
import 'common/utils.dart';
import 'config/config.dart';

class TestTransfer {
  static Future<bool> uploadSamll() async {
    var completer = Completer<bool>();

    // 检查DefaultTransferManger是否注册
    if(!Cos().hasDefaultTransferManger()){
      print("DefaultTransferManger unregistered");
      completer.complete(false);
    }

    try {
      // 上传成功回调
      successCallBack(result) {
        print(result);
        completer.complete(true);
      }
      //上传失败回调
      failCallBack(clientException, serviceException) {
        if (clientException != null) {
          print(clientException);
        }
        if (serviceException != null) {
          print(serviceException);
        }
        completer.complete(false);
      }
      //上传状态回调
      stateCallback(state) {
        print(state);
      }
      //上传进度回调
      progressCallBack(complete, target) {
        print('$complete---$target');
      }
      //初始化分块完成回调
      initMultipleUploadCallback(
          String bucket, String cosKey, String uploadId) {
        print(bucket+"-"+cosKey+"-"+uploadId);
      }

      var smallFilePath = await FileUtils.smallFilePath();
      final file = File(smallFilePath);
      Uint8List bytes = file.readAsBytesSync();
      //开始上传
      TransferTask transferTask = await await Cos().getDefaultTransferManger().upload(
          Constant.PERSIST_BUCKET,
          Constant.PERSIST_BUCKET_SMALL_OBJECT_PATH,
          byteArr: bytes,
          resultListener: ResultListener(successCallBack, failCallBack),
          stateCallback: stateCallback,
          progressCallBack: progressCallBack,
          initMultipleUploadCallback: initMultipleUploadCallback
      );
    } catch (e) {
      print(e);
      completer.complete(false);
    }
    return completer.future;
  }

  static Future<bool> uploadSamllError() async {
    var completer = Completer<bool>();

    await Cos().registerTransferManger(TestConst().PERSIST_BUCKET_REGION, Constant.serviceConfig, TransferConfig());
    if(!Cos().hasTransferManger(TestConst().PERSIST_BUCKET_REGION)){
      print('${TestConst().PERSIST_BUCKET_REGION} TransferManger unregistered');
      completer.complete(false);
    }

    try {
      // 上传成功回调
      successCallBack(result) {
        print(result);
        completer.complete(false);
      }
      //上传失败回调
      failCallBack(clientException, serviceException) {
        if (clientException != null) {
          print(clientException);
        }
        if (serviceException != null) {
          print(serviceException);
        }
        completer.complete(true);
      }
      var smallFilePath = await FileUtils.smallFilePath();
      //开始上传
      TransferTask transferTask = await await Cos().getTransferManger(TestConst().PERSIST_BUCKET_REGION).upload(
          Constant.TEMP_BUCKET,
          Constant.PERSIST_BUCKET_SMALL_OBJECT_PATH,
          filePath: smallFilePath,
          resultListener: ResultListener(successCallBack, failCallBack)
      );
    } catch (e) {
      print(e);
      completer.complete(false);
    }
    return completer.future;
  }

  static Future<bool> uploadBig() async {
    var completer = Completer<bool>();

    // 检查DefaultTransferManger是否注册
    if(!Cos().hasDefaultTransferManger()){
      print("DefaultTransferManger unregistered");
      completer.complete(false);
    }

    try {
      // 上传成功回调
      successCallBack(result) {
        print(result);
        completer.complete(true);
      }
      //上传失败回调
      failCallBack(clientException, serviceException) {
        if (clientException != null) {
          print(clientException);
        }
        if (serviceException != null) {
          print(serviceException);
        }
        completer.complete(false);
      }
      //上传状态回调
      stateCallback(state) {
        print(state);
      }
      //上传进度回调
      progressCallBack(complete, target) {
        print('$complete---$target');
      }
      //初始化分块完成回调
      initMultipleUploadCallback(
          String bucket, String cosKey, String uploadId) {
        print(bucket+"-"+cosKey+"-"+uploadId);
      }

      var bigFilePath = await FileUtils.bigFilePath();
      //开始上传
      TransferTask transferTask = await await Cos().getDefaultTransferManger().upload(
          Constant.PERSIST_BUCKET,
          Constant.PERSIST_BUCKET_BIG_OBJECT_PATH,
          filePath: bigFilePath,
          // byteArr: bytes,
          resultListener: ResultListener(successCallBack, failCallBack),
          stateCallback: stateCallback,
          progressCallBack: progressCallBack,
          initMultipleUploadCallback: initMultipleUploadCallback
      );
    } catch (e) {
      print(e);
      completer.complete(false);
    }
    return completer.future;
  }

  static Future<bool> uploadBigResume() async {
    var completer = Completer<bool>();

    // 检查DefaultTransferManger是否注册
    if(!Cos().hasDefaultTransferManger()){
      print("DefaultTransferManger unregistered");
      completer.complete(false);
    }

    try {
      // 上传成功回调
      successCallBack(result) {
        print(result);
        completer.complete(true);
      }
      //上传失败回调
      failCallBack(clientException, serviceException) {
        if (clientException != null) {
          print(clientException);
        }
        if (serviceException != null) {
          print(serviceException);
        }
        completer.complete(false);
      }
      //上传状态回调
      stateCallback(state) {
        print(state);
      }
      //上传进度回调
      progressCallBack(complete, target) {
        print('$complete---$target');
      }

      var bigFilePath = await FileUtils.bigFilePath();
      //开始上传
      TransferTask transferTask = await await Cos().getDefaultTransferManger().upload(
          Constant.PERSIST_BUCKET,
          Constant.PERSIST_BUCKET_BIG_OBJECT_PATH,
          filePath: bigFilePath,
          // byteArr: bytes,
          resultListener: ResultListener(successCallBack, failCallBack),
          stateCallback: stateCallback,
          progressCallBack: progressCallBack
      );

      transferTask.pause();
      await Future.delayed(Duration(seconds: 3));
      transferTask.resume();
    } catch (e) {
      print(e);
      completer.complete(false);
    }
    return completer.future;
  }

  static Future<bool> download() async {
    var completer = Completer<bool>();

    // 检查DefaultTransferManger是否注册
    if(!Cos().hasDefaultTransferManger()){
      print("DefaultTransferManger unregistered");
      completer.complete(false);
    }

    try {
      // 下载成功回调
      successCallBack(result) {
        print(result);
        completer.complete(true);
      }
      //下载失败回调
      failCallBack(clientException, serviceException) {
        if (clientException != null) {
          print(clientException);
        }
        if (serviceException != null) {
          print(serviceException);
        }
        completer.complete(false);
      }
      //下载状态回调
      stateCallback(state) {
        print(state);
      }
      //下载进度回调
      progressCallBack(complete, target) {
        print('$complete---$target');
      }
      var downliadDirectoryPath = await Utils.getDownloadDirectoryPath();
      var downliadPath = "$downliadDirectoryPath/cos_download_big_object";
      TransferTask transferTask = await await Cos().getDefaultTransferManger().download(
          Constant.PERSIST_BUCKET,
          Constant.PERSIST_BUCKET_BIG_OBJECT_PATH,
          downliadPath,
          resultListener: ResultListener(successCallBack, failCallBack),
          stateCallback: stateCallback,
          progressCallBack: progressCallBack
      );
    } catch (e) {
      print(e);
      completer.complete(false);
    }
    return completer.future;
  }

  static Future<bool> downloadError() async {
    var completer = Completer<bool>();

    // 检查DefaultTransferManger是否注册
    if(!Cos().hasDefaultTransferManger()){
      print("DefaultTransferManger unregistered");
      completer.complete(false);
    }

    try {
      // 下载成功回调
      successCallBack(result) {
        print(result);
        completer.complete(false);
      }
      //下载失败回调
      failCallBack(clientException, serviceException) {
        if (clientException != null) {
          print(clientException);
        }
        if (serviceException != null) {
          print(serviceException);
        }
        completer.complete(true);
      }
      //下载状态回调
      stateCallback(state) {
        print(state);
      }
      //下载进度回调
      progressCallBack(complete, target) {
        print('$complete---$target');
      }
      var downliadDirectoryPath = await Utils.getDownloadDirectoryPath();
      var downliadPath = "$downliadDirectoryPath/cos_download_big_object";
      TransferTask transferTask = await await Cos().getDefaultTransferManger().download(
          Constant.PERSIST_BUCKET,
          Constant.PERSIST_BUCKET_BIG_OBJECT_PATH+"asdsadf",
          downliadPath,
          resultListener: ResultListener(successCallBack, failCallBack),
          stateCallback: stateCallback,
          progressCallBack: progressCallBack
      );
    } catch (e) {
      print(e);
      completer.complete(false);
    }
    return completer.future;
  }
}