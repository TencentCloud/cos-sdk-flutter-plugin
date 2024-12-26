import 'package:tencentcloud_cos_sdk_plugin_nobeacon/pigeon.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../config/config.dart';

class Constant {

  /// App运行在Release环境时，inProduction为true；当App运行在Debug和Profile环境时，inProduction为false
  static const bool inProduction  = kReleaseMode;

  static bool isDriverTest  = false;
  static bool isUnitTest  = false;

  static const String theme = 'AppTheme';
  static const String locale = 'locale';

  static CustomFooter listFooter = CustomFooter(
    builder: (BuildContext context,LoadStatus? mode){
      Widget body;
      if(mode==LoadStatus.idle){
        body = const Text("上拉加载");
      }
      else if(mode==LoadStatus.loading){
        body = const CupertinoActivityIndicator();
      }
      else if(mode == LoadStatus.failed){
        body = const Text("加载失败！点击重试！");
      }
      else if(mode == LoadStatus.canLoading){
        body = const Text("松手,加载更多!");
      }
      else{
        body = const Text("没有更多数据了!");
      }
      return SizedBox(
        height: 55.0,
        child: Center(child:body),
      );
    },
  );

  static CosXmlServiceConfig serviceConfig = CosXmlServiceConfig(
    region: TestConst().PERSIST_BUCKET_REGION,
    isDebuggable: true,
  );
}
