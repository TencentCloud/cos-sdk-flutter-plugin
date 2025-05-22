import 'package:flutter/foundation.dart';
import 'dart:math';
import 'package:tencentcloud_cos_sdk_plugin/cos.dart';
import 'package:tencentcloud_cos_sdk_plugin/pigeon.dart';
import 'common/DnsConfig.dart';
import 'routers/delegate.dart';
import 'routers/route_parser.dart';
import 'config/config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

import 'common/constant.dart';
import 'common/handle_error_utils.dart';
import 'cos/fetch_credentials.dart';

void main() async {
  /// 确保初始化完成
  WidgetsFlutterBinding.ensureInitialized();

  //初始化COS
  if(TestConst().USE_CREDENTIAL){
    if(TestConst().USE_SESSION_TOKEN_CREDENTIAL){
      if(!TestConst().USE_SCOPE_LIMIT_TOKEN_CREDENTIAL){
        await Cos().initWithSessionCredential(FetchCredentials());
      } else {
        await Cos().initWithScopeLimitCredential(FetchScopeLimitCredentials());
      }
    } else {
      await Cos().initWithPlainSecret(TestConst().SECRET_ID, TestConst().SECRET_KEY);
    }
  }

  // 设置静态自定义dns
  // await Cos().initCustomerDNS(FetchDns.dnsMap);
  // 设置动态自定义dns回调（更推荐使用 因为更灵活）
  // await Cos().initCustomerDNSFetch(FetchDns());

  await Cos().registerDefaultService(Constant.serviceConfig);
  await Cos().registerDefaultTransferManger(Constant.serviceConfig, TransferConfig());
  await Cos().enableLogcat(true);
  await Cos().enableLogFile(true);
  await Cos().setMinLevel(LogLevel.verbose);
  await Cos().setAppVersion("flutter_1.0");
  await Cos().setLogcatMinLevel(LogLevel.verbose);
  await Cos().setDeviceID("flutter_deviceId");
  await Cos().setDeviceModel("flutter_deviceModel");
  await Cos().setExtras({"userId":"1"});
  await Cos().setCLsChannelSessionCredential("5edf1c8b-160c-43d5-8506-0a8621a3fa73", "ap-guangzhou.cls.tencentcs.com", CLSFetchCLsChannelCredentials());
  // await Cos().setCLsChannelStaticKey("5edf1c8b-160c-43d5-8506-0a8621a3fa73", "ap-guangzhou.cls.tencentcs.com", "","");
  loglistener(log) {
    print(log.message);
  }
  await Cos().addLogListener(loglistener);
  await Cos().removeLogListener(loglistener);
  print("getLogRootDir");
  print(await Cos().getLogRootDir());

//   // 创建加密密钥和初始化向量
//   final key = Uint8List.fromList([
//     // 32字节的密钥（示例值，实际应使用安全随机数生成）
//     0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07,
//     0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F,
//     0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17,
//     0x18, 0x19, 0x1A, 0x1B, 0x1C, 0x1D, 0x1E, 0x1F
//   ]);
//
//   final iv = Uint8List.fromList([
//     // 16字节的初始化向量
//     0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37,
//     0x38, 0x39, 0x3A, 0x3B, 0x3C, 0x3D, 0x3E, 0x3F
//   ]);
//
// // 调用设置日志文件加密密钥的方法
//   await Cos().setLogFileEncryptionKey(key, iv);


  handleError(() => runApp(const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'COS 传输实践',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      routeInformationParser: MyRouteParser(),
      routerDelegate: MyRouterDelegate(),
      backButtonDispatcher: RootBackButtonDispatcher(),
      builder: EasyLoading.init(),
    );
  }
}


