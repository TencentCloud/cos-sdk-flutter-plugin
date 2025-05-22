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
  if(TestConst().USE_SESSION_TOKEN_CREDENTIAL){
    if(!TestConst().USE_SCOPE_LIMIT_TOKEN_CREDENTIAL){
      await Cos().initWithSessionCredential(FetchCredentials());
    } else {
      await Cos().initWithScopeLimitCredential(FetchScopeLimitCredentials());
    }
  } else {
    await Cos().initWithPlainSecret(TestConst().SECRET_ID, TestConst().SECRET_KEY);
  }

  // 设置静态自定义dns
  // await Cos().initCustomerDNS(FetchDns.dnsMap);
  // 设置动态自定义dns回调（更推荐使用 因为更灵活）
  // await Cos().initCustomerDNSFetch(FetchDns());

  await Cos().registerDefaultService(Constant.serviceConfig);
  await Cos().registerDefaultTransferManger(Constant.serviceConfig, TransferConfig());
  await Cos().setAppVersion("flutter_1.0");
  await Cos().setLogcatMinLevel(LogLevel.verbose);
  await Cos().setDeviceID("flutter_deviceId");
  await Cos().setDeviceModel("flutter_deviceModel");
  await Cos().setExtras({"userId":"1"});
  await Cos().setCLsChannelSessionCredential("5edf1c8b-160c-43d5-8506-0a8621a3fa73", "ap-guangzhou.cls.tencentcs.com", CLSFetchCLsChannelCredentials());
  // await Cos().setCLsChannelStaticKey("5edf1c8b-160c-43d5-8506-0a8621a3fa73", "ap-guangzhou.cls.tencentcs.com", "","");
  await Cos().addLogListener((log){
    if (kDebugMode) {
      print("LogListener");
      print(log.message);
    }
  });
  print("getLogRootDir");
  print(await Cos().getLogRootDir());
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


