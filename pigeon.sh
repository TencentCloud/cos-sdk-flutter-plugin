#!/bin/bash
# 生成四端 pigeon 通道代码。
#
# 使用 CPF-Flutter fork 的 pigeon（见 pubspec.yaml dev_dependencies），
# 因为官方 pigeon 没有 ArkTS(鸿蒙) 生成器。
#
# --package_name 不可省略：fork pigeon 无法从本项目 pubspec 推导包名，
# 缺失时会抛 "Unable to deduce package name"。该值同时决定 channel 名中的
# 包名段（dev.flutter.pigeon.<package_name>.<Api>.<method>），四端必须一致。
set -e

flutter pub run pigeon \
  --input pigeons/pigeon_cos.dart \
  --package_name tencentcloud_cos_sdk_plugin \
  --dart_out lib/pigeon.dart \
  --objc_header_out ios/Classes/pigeon.h \
  --objc_source_out ios/Classes/pigeon.m \
  --java_out ./android/src/main/java/com/tencent/cos/flutter/plugin/Pigeon.java \
  --java_package "com.tencent.cos.flutter.plugin" \
  --arkts_out ./ohos/src/main/ets/components/plugin/Pigeon.ets
