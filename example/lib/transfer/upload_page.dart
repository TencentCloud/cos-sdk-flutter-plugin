import 'package:tencentcloud_cos_sdk_plugin/cos.dart';
import 'package:tencentcloud_cos_sdk_plugin/cos_transfer_manger.dart';
import 'package:tencentcloud_cos_sdk_plugin/enums.dart';
import 'package:tencentcloud_cos_sdk_plugin/pigeon.dart';
import 'package:tencentcloud_cos_sdk_plugin/transfer_task.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

import '../common/constant.dart';
import '../common/res/colors.dart';
import '../common/res/gaps.dart';
import '../common/toast_utils.dart';
import '../common/utils.dart';
import '../routers/delegate.dart';
import '../config/config.dart';

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
      successCallBack(result) {
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
            print(clientException);
          }
          if (serviceException != null) {
            setState(() {
              _resultString = "错误信息：${serviceException.toString()}";
              _resultColor = Colours.red;
            });
            print(serviceException);
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
      //开始上传
      _transferTask = await cosTransferManger.upload(widget.bucketName, cosPath,
          filePath: _pickFilePath,
          uploadId: _uploadId,
          resultListener: ResultListener(successCallBack, failCallBack),
          stateCallback: stateCallback,
          progressCallBack: progressCallBack,
          initMultipleUploadCallback: initMultipleUploadCallback);
    } catch (e) {
      Toast.show(e.toString());
      print(e);
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
