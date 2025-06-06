import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:tencentcloud_cos_sdk_plugin/cos.dart';
import 'package:tencentcloud_cos_sdk_plugin/cos_transfer_manger.dart';
import 'package:tencentcloud_cos_sdk_plugin/enums.dart';
import 'package:tencentcloud_cos_sdk_plugin/pigeon.dart';
import 'package:tencentcloud_cos_sdk_plugin/transfer_task.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

import '../common/DnsConfig.dart';
import '../common/constant.dart';
import '../common/res/colors.dart';
import '../common/res/gaps.dart';
import '../common/toast_utils.dart';
import '../common/utils.dart';
import '../cos/fetch_credentials.dart';
import '../routers/delegate.dart';
import '../config/config.dart';
import 'dart:io';

class UploadPage extends StatefulWidget {
  final String bucketName;
  final String bucketRegion;
  final String? folderPath;

  UploadPage(
    Map<String, String?> arguments, {
    super.key,
  })  : bucketName = arguments['bucketName']!,
        bucketRegion = arguments['bucketRegion']!,
        folderPath = arguments['folderPath'];

  @override
  createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  CosTransferManger? _cosTransferManger;

  String? _pickFilePath;
  TransferTask? _transferTask;
  TransferState? _state;
  int? _complete;
  int? _target;
  String? _resultString;
  Color _resultColor = Colours.text_gray;
  String? _uploadId = null;

  Future<CosTransferManger> getTransferManger() async {
    if (_cosTransferManger == null) {
      if (Cos().hasTransferManger(widget.bucketRegion)) {
        _cosTransferManger = Cos().getTransferManger(widget.bucketRegion);
      } else {
        _cosTransferManger = await Cos().registerTransferManger(
            widget.bucketRegion,
            Constant.serviceConfig..region = widget.bucketRegion,
            TransferConfig());
      }
    }
    return _cosTransferManger!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('上传文件'), actions: [
        TextButton(
            onPressed: () async {
              FilePickerResult? result = await FilePicker.platform.pickFiles();
              if (result != null) {
                setState(() {
                  _pickFilePath = result.files.single.path;
                });
              }
            },
            child: const Text(
              "选择文件",
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ))
      ]),
      body: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              "已选文件名：${_pickFilePath ?? "未选择"}",
              overflow: TextOverflow.fade,
            ),
            Gaps.vGap16,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("状态：${_state?.toString() ?? ""}"),
                Text(_getProgressString())
              ],
            ),
            Gaps.vGap10,
            LinearProgressIndicator(
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation(Colours.app_main),
              value: _getProgress(),
            ),
            Gaps.vGap10,
            Text(_resultString ?? "",
                overflow: TextOverflow.fade,
                maxLines: 5,
                style: TextStyle(color: _resultColor)),
            Gaps.vGap50,
            Row(children: [
              Expanded(
                flex: 1,
                child: MaterialButton(
                  height: 50.0,
                  color: Colours.app_main,
                  textColor: Colors.white,
                  onPressed: () {
                    if (_transferTask == null) {
                      _upload();
                    } else {
                      _transferTask?.cancel();
                      Navigator.pop(context);
                    }
                  },
                  child: Text(_transferTask == null ? "开始" : "取消"),
                ),
              ),
              Gaps.hGap16,
              Expanded(
                flex: 1,
                child: MaterialButton(
                  height: 50.0,
                  color: Colours.app_main,
                  textColor: Colors.white,
                  onPressed: () async {
                    if (_state == TransferState.PAUSED) {
                      _transferTask?.resume();
                    } else if (_state == TransferState.IN_PROGRESS) {
                      _transferTask?.pause();
                    }
                  },
                  child: Text(_state == TransferState.PAUSED ? "恢复" : "暂停"),
                ),
              )
            ]),
            Gaps.vGap32,
            MaterialButton(
              height: 50.0,
              color: Colours.app_main,
              textColor: Colors.white,
              onPressed: () {
                MyRouterDelegate.of(context).push(name: "/upload/batch", arguments: {
                  'bucketName': widget.bucketName,
                  'bucketRegion': widget.bucketRegion,
                  'folderPath': widget.folderPath
                });
              },
              child: const Text("批量上传"),
            )
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _transferTask?.pause();
  }

  void _upload() async {
    try {
      if (_pickFilePath == null) {
        setState(() {
          _resultString = "错误信息：请先选择需要上传的文件";
          _resultColor = Colours.red;
        });
        return;
      }

      var cosPath =
          "${widget.folderPath ?? ""}${_pickFilePath!.split("/").last}";
      CosTransferManger cosTransferManger = await getTransferManger();
      // 上传成功回调
      successCallBack(Map<String?, String?>? header, CosXmlResult? result) {
        if (kDebugMode) {
          print(header);
          print(result?.eTag);
          print(result?.accessUrl);

          // 获取上传回调数据
          // CallbackResult? callbackResult = result?.callbackResult;
          // if(callbackResult != null){
          //   // 获取回调状态：Callback 是否成功。枚举值，支持 200、203。200表示上传成功、回调成功；203表示上传成功，回调失败。
          //   int status = callbackResult.status;
          //   print(status);
          //   if(status == 200){
          //     // 获取回调内容 CallbackBody
          //     String? callbackBody = callbackResult.callbackBody;
          //     print(callbackBody);
          //   } else if(status == 203){
          //     // 获取回调状态：Status为203时，说明Callback，返回 Error，说明回调失败信息。
          //     CallbackResultError? error = callbackResult.error;
          //     print(error?.code);
          //     print(error?.message);
          //   }
          // }
        }
        if (mounted) {
          setState(() {
            _resultString = "文件已上传到COS：$cosPath";
            _resultColor = Colours.text_gray;
          });
        }
      }
      //上传失败回调
      failCallBack(clientException, serviceException) {
        if (mounted) {
          if (clientException != null) {
            setState(() {
              _resultString = "错误信息：${clientException.toString()}";
              _resultColor = Colours.red;
            });
            if (kDebugMode) {
              print(clientException);
            }
          }
          if (serviceException != null) {
            setState(() {
              _resultString = "错误信息：${serviceException.toString()}";
              _resultColor = Colours.red;
            });
            if (kDebugMode) {
              print(serviceException);
            }
          }
        }
      }
      //上传状态回调
      stateCallback(state) {
        if (mounted) {
          setState(() {
            _state = state;
          });
        }
      }
      //上传进度回调
      progressCallBack(complete, target) {
        if (mounted) {
          setState(() {
            _complete = complete;
            _target = target;
          });
        }
      }
      //初始化分块完成回调
      initMultipleUploadCallback(
          String bucket, String cosKey, String uploadId) {
        _uploadId = uploadId;
      }

      File file = File(_pickFilePath!);
      Uint8List bytes = file.readAsBytesSync();
      //开始上传
      // String callbackParam = "{ \"callbackUrl\": \"http://xx.xx.xx.xx/index\", " +
      //     "\"callbackHost\": \"xx.xx.xx.xx\", " +
      //     "\"callbackBody\": \"bucket=\${bucket}&object=\${object}&etag=\${etag}&test=test_123\", " +
      //     "\"callbackBodyType\": \"application/x-www-form-urlencoded\" }";
      _transferTask = await cosTransferManger.upload(widget.bucketName, cosPath,
          filePath: _pickFilePath,
          // byteArr: bytes,
          uploadId: _uploadId,
          // callbackParam: callbackParam,
          customHeaders: {"x-cos-meta-a":"1","x-cos-meta-b":"2"},
          // noSignHeaders: ["Host"],
          resultListener: ResultListener(successCallBack, failCallBack),
          stateCallback: stateCallback,
          progressCallBack: progressCallBack,
          initMultipleUploadCallback: initMultipleUploadCallback,
          sessionCredentials: await FetchCredentials.getSessionCredentials()
      );
    } catch (e) {
      Toast.show(e.toString());
      if (kDebugMode) {
        print(e);
      }
    }
  }

  String _getProgressString() {
    if (_complete == null || _target == null) {
      return "";
    }

    return "${Utils.readableStorageSize(_complete!)}/${Utils.readableStorageSize(_target!)}";
  }

  double _getProgress() {
    if (_complete == null || _target == null) {
      return 0;
    }

    return _complete! / _target!;
  }
}
