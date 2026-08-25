import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

class Utils {
  static String toDateTimeString(String? utc) {
    if(utc == null || utc.isEmpty){
      return "";
    } else {
      var dateValue = DateTime.parse(utc).toLocal();
      return DateFormat("yyyy-MM-dd hh:mm:ss").format(dateValue);
    }
  }

  static String readableStorageSize(int sizeInB)  {
    double floatSize = sizeInB.toDouble();
    int index = 0;
    List units = ["B", "KB", "MB", "GB", "TB", "PB"];

    while (floatSize > 1000 && index < 5) {
    index++;
    floatSize /= 1024;
    }

    return '${floatSize.toStringAsFixed(2)}${units[index]}';
  }

  static Future<String> getDownloadDirectoryPath() async {
    if(Platform.isAndroid){
      Directory? appDocDir = await getExternalStorageDirectory();
      appDocDir ??= await getApplicationDocumentsDirectory();
      return appDocDir.path;
    } else if(Platform.isIOS) {
      Directory appDocDir = await getApplicationDocumentsDirectory();
      return appDocDir.path;
    } else if (Platform.operatingSystem == 'ohos') {
      // 鸿蒙上 path_provider 没有实现（调用 getApplicationDocumentsDirectory 会抛
      // MissingPluginException），改用应用沙箱的固定可写目录。
      // el2/base/haps/entry/files 是 entry 模块的私有可写目录，与验证页一致。
      return '/data/storage/el2/base/haps/entry/files';
    } else {
      throw UnsupportedError("Only Android, iOS and HarmonyOS are supported");
    }
  }
}
