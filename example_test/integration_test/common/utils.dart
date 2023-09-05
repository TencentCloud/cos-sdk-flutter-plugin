import 'dart:io';
import 'package:path_provider/path_provider.dart';

class Utils {
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
