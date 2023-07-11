import 'package:example_direct/upload_dio.dart';
import 'package:example_direct/upload_httpclient.dart';
import 'package:example_direct/utils.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
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
  // 设置使用的网络库
  static const String NETWORK_LIB = NETWORK_LIB_HTTP_CLIENT;
  // dio网络库
  static const String NETWORK_LIB_DIO = "dio";
  // 原生自带http client网络库
  static const String NETWORK_LIB_HTTP_CLIENT = "http_client";

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

    try {
      if(NETWORK_LIB == NETWORK_LIB_DIO){
        if (kDebugMode) {
          print("使用dio库上传");
        }
        await UploadDio.upload(_pickFilePath!, (count, total) {
          if (mounted) {
            setState(() {
              _complete = count;
              _target = total;
            });
          }
        });
      } else if(NETWORK_LIB == NETWORK_LIB_HTTP_CLIENT){
        if (kDebugMode) {
          print("使用原生http client库上传");
        }
        await UploadHttpClient.upload(_pickFilePath!, (count, total) {
          if (mounted) {
            setState(() {
              _complete = count;
              _target = total;
            });
          }
        });
      }

      setState(() {
        _resultString = "上传成功";
        _resultColor = const Color(0xFF999999);
      });
    } catch (e) {
      setState(() {
        _resultString = e.toString();
        _resultColor = const Color(0xFFFF4759);
      });
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
      appBar: AppBar(title: const Text('Flutter直传'), actions: [
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
              children: [Text(_getProgressString())],
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
