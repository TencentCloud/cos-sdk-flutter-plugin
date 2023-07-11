import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

typedef ProgressCallback = void Function(int count, int total);

class UploadHttpClient {
  /// 上传文件
  /// @param filePath 文件路径
  /// @param progressCallback 进度回调
  static Future<void> upload(String filePath, ProgressCallback progressCallback) async {
    // 获取直传签名等信息
    String ext = path.extension(filePath).substring(1);
    Map<String, dynamic> directTransferData;
    try {
      directTransferData = await _getStsDirectSign(ext);
    } catch (err) {
      if (kDebugMode) {
        print(err);
      }
      throw Exception("getStsDirectSign fail");
    }

    String cosHost = directTransferData['cosHost'];
    String cosKey = directTransferData['cosKey'];
    String authorization = directTransferData['authorization'];
    String securityToken = directTransferData['securityToken'];
    String url = 'https://$cosHost/$cosKey';

    File file = File(filePath);
    int fileSize = await file.length();
    HttpClient httpClient = HttpClient();
    HttpClientRequest request = await httpClient.putUrl(Uri.parse(url));
    request.headers.set('Content-Type', 'application/octet-stream');
    request.headers.set('Content-Length', fileSize.toString());
    request.headers.set('Authorization', authorization);
    request.headers.set('x-cos-security-token', securityToken);
    request.headers.set('Host', cosHost);
    request.contentLength = fileSize;
    Stream<List<int>> stream = file.openRead();
    int bytesSent = 0;
    stream.listen(
          (List<int> chunk) {
        bytesSent += chunk.length;
        double progress = bytesSent / fileSize;
        if (kDebugMode) {
          print('Progress: ${progress.toStringAsFixed(2)}');
        }
        progressCallback(bytesSent, fileSize);
        request.add(chunk);
      },
      onDone: () async {
        HttpClientResponse response = await request.close();
        if (response.statusCode == 200) {
          if (kDebugMode) {
            print('上传成功');
          }
        } else {
          throw Exception("上传失败 $response");
        }
      },
      onError: (error) {
        if (kDebugMode) {
          print('Error: $error');
        }
        throw Exception("上传失败 ${error.toString()}");
      },
      cancelOnError: true,
    );
  }

  /// 获取直传的url和签名等
  /// @param ext 文件后缀 直传后端会根据后缀生成cos key
  /// @return 直传url和签名等
  static Future<Map<String, dynamic>> _getStsDirectSign(String ext) async {
    HttpClient httpClient = HttpClient();
    //直传签名业务服务端url（正式环境 请替换成正式的直传签名业务url）
    //直传签名业务服务端代码示例可以参考：https://github.com/tencentyun/cos-demo/blob/main/server/direct-sign/nodejs/app.js
    //10.91.22.16为直传签名业务服务器的地址 例如上述node服务，总之就是访问到直传签名业务服务器的url
    HttpClientRequest request = await httpClient
        .getUrl(Uri.parse("http://10.91.22.16:3000/sts-direct-sign?ext=$ext"));
    HttpClientResponse response = await request.close();
    String responseBody = await response.transform(utf8.decoder).join();
    if (response.statusCode == 200) {
      Map<String, dynamic> json = jsonDecode(responseBody);
      if (kDebugMode) {
        print(json);
      }
      httpClient.close();
      if (json['code'] == 0) {
        return json['data'];
      } else {
        throw Exception(
            'getStsDirectSign error code: ${json['code']}, error message: ${json['message']}');
      }
    } else {
      httpClient.close();
      throw Exception(
          'getStsDirectSign HTTP error code: ${response.statusCode}');
    }
  }
}