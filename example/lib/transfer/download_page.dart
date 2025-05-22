import 'package:flutter/foundation.dart';
import 'package:tencentcloud_cos_sdk_plugin/cos.dart';
import 'package:tencentcloud_cos_sdk_plugin/cos_transfer_manger.dart';
import 'package:tencentcloud_cos_sdk_plugin/enums.dart';
import 'package:tencentcloud_cos_sdk_plugin/pigeon.dart';
import 'package:tencentcloud_cos_sdk_plugin/transfer_task.dart';
import 'package:flutter/material.dart';

import '../common/constant.dart';
import '../common/res/colors.dart';
import '../common/res/gaps.dart';
import '../common/toast_utils.dart';
import '../common/utils.dart';

class DownloadPage extends StatefulWidget {
  final String bucketName;
  final String bucketRegion;
  final String fileKey;

  DownloadPage(
    Map<String, String> arguments, {
    super.key,
  })  : bucketName = arguments['bucketName']!,
        bucketRegion = arguments['bucketRegion']!,
        fileKey = arguments['fileKey']!;

  @override
  createState() => _DownloadPageState();
}

class _DownloadPageState extends State<DownloadPage> {
  CosTransferManger? _cosTransferManger;

  TransferTask? _transferTask;
  TransferState? _state;
  int? _complete;
  int? _target;
  String? _resultString;
  Color _resultColor = Colours.text_gray;

  Future<CosTransferManger> getTransferManger() async {
    if(_cosTransferManger == null){
      if(Cos().hasTransferManger(widget.bucketRegion)){
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
      appBar: AppBar(
        title: const Text('下载文件'),
      ),
      body: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              "文件名：${widget.fileKey.split("/").last}",
              overflow: TextOverflow.fade,
            ),
            Gaps.vGap16,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("状态：${_state?.toString()??""}"),
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
            Text(
              _resultString??"",
              overflow: TextOverflow.fade,
              maxLines: 5,
              style: TextStyle(color: _resultColor)
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
                    if (_transferTask == null) {
                      _download();
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

  void _download() async {
    try {
      var downliadDirectoryPath = await Utils.getDownloadDirectoryPath();
      var downliadPath = "$downliadDirectoryPath/cos_download_${widget.fileKey.split("/").last}";
      CosTransferManger cosTransferManger = await getTransferManger();
      _transferTask = await cosTransferManger.download(
          widget.bucketName, widget.fileKey, downliadPath,
          customHeaders: {"x-cos-meta-a":"1","x-cos-meta-b":"2"},
          // noSignHeaders: ["Host"],
          resultListener:
              ResultListener((header, result) {
                if (kDebugMode) {
                  print(header);
                }
                if (mounted) {
                  setState(() {
                    _resultString = "文件已下载到：$downliadPath";
                    _resultColor = Colours.text_gray;
                  });
                }
              }, (clientException, serviceException) {
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
          }), stateCallback: (state) {
        if (mounted) {
          setState(() {
            _state = state;
          });
        }
      }, progressCallBack: (complete, target) {
        if (mounted) {
          setState(() {
            _complete = complete;
            _target = target;
          });
        }
      });
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
