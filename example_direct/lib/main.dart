import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

import 'package:dio/dio.dart';
import 'package:example_direct/utils.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter直传',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter直传'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // 选择的文件路径
  String? _pickFilePath;
  // 当前进度
  int? _complete;
  // 进度总长度
  int? _target;
  // 结果提示
  String? _resultString;
  Color _resultColor = const Color(0xFF999999);

  /// 上传
  void _upload() async {
    if (_pickFilePath == null) {
      setState(() {
        _resultString = "错误信息：请先选择需要上传的文件";
        _resultColor = const Color(0xFFFF4759);
      });
      return;
    }

    Dio dio = Dio();
    String ext = path.extension(_pickFilePath!).substring(1);
    Map<String, dynamic> directTransferData;
    try {
      directTransferData = await getStsDirectSign(ext);
    } catch(err) {
      if (kDebugMode) {
        print(err);
      }
      setState(() {
        _resultString = "getStsDirectSign fail";
        _resultColor = const Color(0xFFFF4759);
      });
      return;
    }
    String cosHost = directTransferData['cosHost'];
    String cosKey = directTransferData['cosKey'];
    String authorization = directTransferData['authorization'];
    String securityToken = directTransferData['securityToken'];
    String url = 'https://$cosHost/$cosKey';
    FormData formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(_pickFilePath!),
    });
    Options options = Options(
      method: 'PUT',
      headers: {
        'Content-Type': 'application/octet-stream',
        'Authorization': authorization,
        'x-cos-security-token': securityToken,
        'Host': cosHost,
      },
    );
    try {
      Response response = await dio.put(url, data: formData, options: options, onSendProgress: (int sent, int total) {
        if (mounted) {
          setState(() {
            _complete = sent;
            _target = total;
          });
        }
      });
      if(response.statusCode == 200){
        setState(() {
          _resultString = "上传成功";
          _resultColor = const Color(0xFF999999);
        });
      } else {
        setState(() {
          _resultString = "上传失败 ${response.statusMessage}";
          _resultColor = const Color(0xFFFF4759);
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      setState(() {
        _resultString = "上传失败 ${e.toString()}";
        _resultColor = const Color(0xFFFF4759);
      });
    }
  }

  /// 获取直传的url和签名等
  /// @param ext 文件后缀 直传后端会根据后缀生成cos key
  /// @return 直传url和签名等
  Future<Map<String, dynamic>> getStsDirectSign(String ext) async {
    Dio dio = Dio();
    //直传签名业务服务端url（正式环境 请替换成正式的直传签名业务url）
    //直传签名业务服务端代码示例可以参考：https://github.com/tencentyun/cos-demo/blob/main/server/direct-sign/nodejs/app.js
    //10.91.22.16为直传签名业务服务器的地址 例如上述node服务，总之就是访问到直传签名业务服务器的url
    Response response = await dio.get('http://10.91.22.16:3000/sts-direct-sign', queryParameters: {'ext': ext});
    if (response.statusCode == 200) {
      if (kDebugMode) {
        print(response.data);
      }
      if (response.data['code'] == 0) {
        return response.data['data'];
      } else {
        throw Exception('getStsDirectSign error code: ${response.data['code']}, error message: ${response.data['message']}');
      }
    } else {
      throw Exception('getStsDirectSign HTTP error code: ${response.statusCode}');
    }
  }

  /// 获取进度字符串
  String _getProgressString() {
    if (_complete == null || _target == null) {
      return "";
    }
    return "${Utils.readableStorageSize(_complete!)}/${Utils.readableStorageSize(_target!)}";
  }
  /// 后去进度百分比
  double _getProgress() {
    if (_complete == null || _target == null) {
      return 0;
    }
    return _complete! / _target!;
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
                  _resultString = null;
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
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_getProgressString())
              ],
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation(Color(0xFF4688FA)),
              value: _getProgress(),
            ),
          const SizedBox(height: 10),
            Text(_resultString ?? "",
                overflow: TextOverflow.fade,
                maxLines: 5,
                style: TextStyle(color: _resultColor)),
            const SizedBox(height: 50),
            Row(children: [
              Expanded(
                flex: 1,
                child: MaterialButton(
                  height: 50.0,
                  color: const Color(0xFF4688FA),
                  textColor: Colors.white,
                  onPressed: () {
                    _upload();
                  },
                  child: const Text("开始"),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
