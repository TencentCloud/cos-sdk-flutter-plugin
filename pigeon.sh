flutter pub run pigeon \
  --input pigeons/pigeon_cos.dart \
  --dart_out lib/pigeon.dart \
  --objc_header_out ios/Classes/pigeon.h \
  --objc_source_out ios/Classes/pigeon.m \
  --java_out ./android/src/main/java/com/tencent/cos/flutter/plugin/Pigeon.java \
  --java_package "com.tencent.cos.flutter.plugin"