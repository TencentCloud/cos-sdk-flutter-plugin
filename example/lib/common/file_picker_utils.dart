import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';

/// 跨平台文件选择封装。
///
/// Android / iOS 使用 [FilePicker] 插件；鸿蒙上没有 file_picker 实现
/// （点击无反应 / MissingPluginException），改走 EntryAbility 注册的
/// MethodChannel（`example/file_picker`），原生侧用 DocumentViewPicker
/// 选文件后复制到应用沙箱，返回可直接被 COS SDK 读取的本地路径。
class FilePickerUtils {
  static const MethodChannel _channel = MethodChannel('example/file_picker');

  /// 选择单个文件，返回本地文件路径；用户取消时返回 null。
  static Future<String?> pickSingleFilePath() async {
    if (Platform.operatingSystem == 'ohos') {
      try {
        final String? path = await _channel.invokeMethod<String>('pickFile');
        if (path == null || path.isEmpty) {
          return null; // 用户取消选择
        }
        return path;
      } on PlatformException {
        return null;
      } catch (_) {
        return null;
      }
    }

    final FilePickerResult? result = await FilePicker.platform.pickFiles();
    return result?.files.single.path;
  }
}
