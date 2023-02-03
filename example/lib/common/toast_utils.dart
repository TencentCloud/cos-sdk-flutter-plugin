
import 'package:flutter_easyloading/flutter_easyloading.dart';

/// Toast工具类
class Toast {
  static void show(String? msg, {int duration = 2000}) {
    if (msg == null) {
      return;
    }
    EasyLoading.showToast(
      msg,
      duration: Duration(milliseconds: duration)
    );
  }
}
