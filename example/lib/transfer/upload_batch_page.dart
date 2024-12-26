import 'dart:ffi';
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

import '../common/constant.dart';
import '../common/res/colors.dart';
import '../common/res/gaps.dart';
import '../common/toast_utils.dart';
import '../common/utils.dart';
import '../routers/delegate.dart';
import '../config/config.dart';
import 'dart:io';

class UploadBatchPage extends StatefulWidget {
  final String bucketName;
  final String bucketRegion;
  final String? folderPath;

  UploadBatchPage(
    Map<String, String?> arguments, {
    super.key,
  })  : bucketName = arguments['bucketName']!,
        bucketRegion = arguments['bucketRegion']!,
        folderPath = arguments['folderPath'];

  @override
  createState() => _UploadBatchPageState();
}

class _UploadBatchPageState extends State<UploadBatchPage> {
  CosTransferManger? _cosTransferManger;

  final List<String?> _pickFilePathArr = [];
  String _pickFilePathArrString = "";

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
      appBar: AppBar(title: const Text('批量上传'), actions: [
        TextButton(
            onPressed: () async {
              FilePickerResult? result = await FilePicker.platform.pickFiles();
              if (result != null) {
                setState(() {
                  _pickFilePathArr.add(result.files.single.path);
                  _pickFilePathArrString = _pickFilePathArr.join("\r\n");
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
              "已选文件名：${_pickFilePathArrString ?? "未选择"}",
              overflow: TextOverflow.fade,
            ),
            Gaps.vGap50,
            Row(children: [
              Expanded(
                flex: 1,
                child: MaterialButton(
                  height: 50.0,
                  color: Colours.app_main,
                  textColor: Colors.white,
                  onPressed: () {
                    _upload();
                  },
                  child: Text("开始"),
                ),
              )
            ]),
          ],
        ),
      ),
    );
  }

  void _upload() async {
    for (int i=0;i<_pickFilePathArr.length;i++) {
      var _pickFilePath = _pickFilePathArr[i];
      try {
        if(i==1){
          //故意搞错一个
          _pickFilePath = "asdasdasdasdasdasd";
        }
        var cosPath =
            "${widget.folderPath ?? ""}${_pickFilePath!.split("/").last}";
        CosTransferManger cosTransferManger = await getTransferManger();
        // 上传成功回调
        successCallBack(header, result) {
          if (kDebugMode) {
            print("successCallBack");
          }
          print(header);
        }
        //上传失败回调
        failCallBack(clientException, serviceException) {
          if (kDebugMode) {
            print("failCallBack");
          }
          if (clientException != null) {
            if (kDebugMode) {
              print(clientException);
            }
          }
          if (serviceException != null) {
            if (kDebugMode) {
              print(serviceException);
            }
          }
        }

        //开始上传
        await cosTransferManger.upload(widget.bucketName, cosPath,
            filePath: _pickFilePath,
            resultListener: ResultListener(successCallBack, failCallBack)
        );
      } catch (e) {
        Toast.show(e.toString());
        if (kDebugMode) {
          print(e);
        }
      }
    }
  }

}
