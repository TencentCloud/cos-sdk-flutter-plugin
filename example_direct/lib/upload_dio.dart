import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

class UploadDio {
  /// 上传文件
  /// @param filePath 文件路径
  /// @param progressCallback 进度回调
  static Future<void> upload(String filePath, ProgressCallback progressCallback) async {
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
    Options options = Options(
      method: 'PUT',
      headers: {
        'Content-Length': await file.length(),
        'Content-Type': 'application/octet-stream',
        'Authorization': authorization,
        'x-cos-security-token': securityToken,
        'Host': cosHost,
      },
    );
    try {
      Dio dio = Dio();
      Response response = await dio.put(url,
          data: file.openRead(),
          options: options, onSendProgress: (int sent, int total) {
            double progress = sent / total;
            if (kDebugMode) {
              print('Progress: ${progress.toStringAsFixed(2)}');
            }
            progressCallback(sent, total);
          });
      if (response.statusCode == 200) {
        if (kDebugMode) {
          print('上传成功');
        }
      } else {
        throw Exception("上传失败 ${response.statusMessage}");
      }
    } catch (error) {
      if (kDebugMode) {
        print('Error: $error');
      }
      throw Exception("上传失败 ${error.toString()}");
    }
  }

  /// 获取直传的url和签名等
  /// @param ext 文件后缀 直传后端会根据后缀生成cos key
  /// @return 直传url和签名等
  static Future<Map<String, dynamic>> _getStsDirectSign(String ext) async {
    Dio dio = Dio();
    //直传签名业务服务端url（正式环境 请替换成正式的直传签名业务url）
    //直传签名业务服务端代码示例可以参考：https://github.com/tencentyun/cos-demo/blob/main/server/direct-sign/nodejs/app.js
    //10.91.22.16为直传签名业务服务器的地址 例如上述node服务，总之就是访问到直传签名业务服务器的url
    Response response = await dio.get('http://10.91.22.16:3000/sts-direct-sign',
        queryParameters: {'ext': ext});
    if (response.statusCode == 200) {
      if (kDebugMode) {
        print(response.data);
      }
      if (response.data['code'] == 0) {
        return response.data['data'];
      } else {
        throw Exception(
            'getStsDirectSign error code: ${response.data['code']}, error message: ${response.data['message']}');
      }
    } else {
      throw Exception(
          'getStsDirectSign HTTP error code: ${response.statusCode}');
    }
  }
}