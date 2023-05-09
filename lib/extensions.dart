import 'package:tencentcloud_cos_sdk_plugin/pigeon.dart';

extension SessionQCloudCredentialsExtension on SessionQCloudCredentials {
  bool isValid() {
    DateTime now = DateTime.now();
    int timestamp = now.millisecondsSinceEpoch ~/ 1000;
    return timestamp <= expiredTime - 60;
  }
}