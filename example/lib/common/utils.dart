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
    } else {
      throw UnsupportedError("Only Android and iOS are supported");
    }
  }
}
