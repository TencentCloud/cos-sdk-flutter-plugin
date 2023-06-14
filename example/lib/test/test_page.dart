import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:tencentcloud_cos_sdk_plugin/cos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:tencentcloud_cos_sdk_plugin/pigeon.dart';

import '../common/res/colors.dart';
import '../common/res/gaps.dart';
import '../common/toast_utils.dart';
import '../routers/delegate.dart';
import '../config/config.dart';

class TestPage extends StatefulWidget {
  const TestPage({
    super.key,
  });

  @override
  createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('测试'),
      ),
      body: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: <Widget>[
            Gaps.vGap5,
            MaterialButton(
              minWidth: double.infinity,
              height: 30.0,
              color: Colours.app_main,
              textColor: Colors.white,
              onPressed: () async {
                // 存储桶名称，由bucketname-appid 组成，appid必须填入，可以在COS控制台查看存储桶名称。 https://console.cloud.tencent.com/cos5/bucket
                String bucket = "mobile-ut-1253960454";
                // 存储桶所在地域简称，例如广州地区是 ap-guangzhou
                String region = "ap-guangzhou";
                try {
                  Map<String?, String?> header = await Cos().getDefaultService().headBucket(
                      bucket,
                      region: region
                  );
                  if (kDebugMode) {
                    print(header);
                  }
                } catch (e) {
                  // 失败后会抛异常 根据异常进行业务处理
                  Toast.show(e.toString());
                  if (kDebugMode) {
                    print(e);
                  }
                }
              },
              child: const Text("存储桶head"),
            ),
            Gaps.vGap5,
            MaterialButton(
              minWidth: double.infinity,
              height: 30.0,
              color: Colours.app_main,
              textColor: Colors.white,
              onPressed: () async {
                // 存储桶名称，由bucketname-appid 组成，appid必须填入，可以在COS控制台查看存储桶名称。 https://console.cloud.tencent.com/cos5/bucket
                String bucket = "qjdtest1-1253960454";
                // 存储桶所在地域简称，例如广州地区是 ap-guangzhou
                String region = "ap-beijing";
                try {
                  await Cos().getDefaultService().deleteBucket(
                      bucket,
                      region: region
                  );
                } catch (e) {
                  // 失败后会抛异常 根据异常进行业务处理
                  Toast.show(e.toString());
                  if (kDebugMode) {
                    print(e);
                  }
                }
              },
              child: const Text("删除存储桶"),
            ),
            Gaps.vGap5,
            MaterialButton(
              minWidth: double.infinity,
              height: 30.0,
              color: Colours.app_main,
              textColor: Colors.white,
              onPressed: () async {
                // 存储桶名称，由bucketname-appid 组成，appid必须填入，可以在COS控制台查看存储桶名称。 https://console.cloud.tencent.com/cos5/bucket
                String bucket = "examplebucket-1250000000";
                //对象在存储桶中的位置标识符，即对象键
                String cosPath = "exampleobject";
                // 存储桶所在地域简称，例如广州地区是 ap-guangzhou
                String region = "COS_REGION";
                try {
                  await Cos().getDefaultService().deleteObject(
                      bucket, cosPath,
                      region: region
                  );
                } catch (e) {
                  // 失败后会抛异常 根据异常进行业务处理
                  Toast.show(e.toString());
                  if (kDebugMode) {
                    print(e);
                  }
                }
              },
              child: const Text("删除对象"),
            ),
            Gaps.vGap5,
            MaterialButton(
              minWidth: double.infinity,
              height: 30.0,
              color: Colours.app_main,
              textColor: Colors.white,
              onPressed: () async {
                // 存储桶名称，由bucketname-appid 组成，appid必须填入，可以在COS控制台查看存储桶名称。 https://console.cloud.tencent.com/cos5/bucket
                String bucket = "examplebucket-1250000000";
                try {
                  BucketContents bucketContents = await Cos().getDefaultService().getBucket(
                      bucket,
                      prefix: "dir/", // 前缀匹配，用来规定返回的对象前缀地址
                      maxKeys: 100 // 单次返回最大的条目数量，默认1000
                  );
                  // 表示数据被截断，需要拉取下一页数据
                  var isTruncated = bucketContents.isTruncated;
                  // nextMarker 表示下一页的起始位置
                  var nextMarker = bucketContents.nextMarker;
                } catch (e) {
                  // 失败后会抛异常 根据异常进行业务处理
                  Toast.show(e.toString());
                  if (kDebugMode) {
                    print(e);
                  }
                }
              },
              child: const Text("列出对象第一页数据"),
            ),
            Gaps.vGap5,
            MaterialButton(
              minWidth: double.infinity,
              height: 30.0,
              color: Colours.app_main,
              textColor: Colors.white,
              onPressed: () async {
                // // 存储桶名称，由bucketname-appid 组成，appid必须填入，可以在COS控制台查看存储桶名称。 https://console.cloud.tencent.com/cos5/bucket
                // String bucket = "examplebucket-1250000000";
                // // prevPageBucketContents 是上一页的返回结果，这里的 nextMarker 表示下一页的起始位置
                // String prevPageMarker = prevPageBucketContents.nextMarker;
                // try {
                //   BucketContents bucketContents = await Cos().getDefaultService().getBucket(
                //       bucket,
                //       prefix: "dir/", // 前缀匹配，用来规定返回的对象前缀地址
                //       marker: prevPageMarker, // 起始位置
                //       maxKeys: 100 // 单次返回最大的条目数量，默认1000
                //   );
                //   // 表示数据被截断，需要拉取下一页数据
                //   var isTruncated = bucketContents.isTruncated;
                //   // nextMarker 表示下一页的起始位置
                //   var nextMarker = bucketContents.nextMarker;
                // } catch (e) {
                //   // 失败后会抛异常 根据异常进行业务处理
                //   Toast.show(e.toString());
                //   print(e);
                // }
              },
              child: const Text("列出对象下一页数据"),
            ),
            Gaps.vGap5,
            MaterialButton(
              minWidth: double.infinity,
              height: 30.0,
              color: Colours.app_main,
              textColor: Colors.white,
              onPressed: () async {
                // 存储桶名称，由bucketname-appid 组成，appid必须填入，可以在COS控制台查看存储桶名称。 https://console.cloud.tencent.com/cos5/bucket
                String bucket = "examplebucket-1250000000";
                // 定界符为一个符号，如果有 Prefix，
                // 则将 Prefix 到 delimiter 之间的相同路径归为一类，定义为 Common Prefix，
                // 然后列出所有 Common Prefix。如果没有 Prefix，则从路径起点开始
                var delimiter = "/";
                try {
                  BucketContents bucketContents = await Cos().getDefaultService().getBucket(
                      bucket,
                      prefix: "dir/", // 前缀匹配，用来规定返回的对象前缀地址
                      delimiter: delimiter,
                      maxKeys: 100 // 单次返回最大的条目数量，默认1000
                  );
                  // 表示数据被截断，需要拉取下一页数据
                  var isTruncated = bucketContents.isTruncated;
                  // nextMarker 表示下一页的起始位置
                  var nextMarker = bucketContents.nextMarker;
                } catch (e) {
                  // 失败后会抛异常 根据异常进行业务处理
                  Toast.show(e.toString());
                  if (kDebugMode) {
                    print(e);
                  }
                }
              },
              child: const Text("获取对象列表与子目录"),
            ),
            Gaps.vGap5,
            MaterialButton(
              minWidth: double.infinity,
              height: 30.0,
              color: Colours.app_main,
              textColor: Colors.white,
              onPressed: () async {
                // 存储桶region可以在COS控制台指定存储桶的概览页查看 https://console.cloud.tencent.com/cos5/bucket/ ，关于地域的详情见 https://cloud.tencent.com/document/product/436/6224
                String region = "ap-beijing"; // 您的存储桶地域
                String customDomain = "exampledomain.com"; // 自定义域名

                // 创建 CosXmlServiceConfig 对象，根据需要修改默认的配置参数
                CosXmlServiceConfig serviceConfig = CosXmlServiceConfig(
                    region: region,
                    isDebuggable: false,
                    isHttps: true,
                    hostFormat: customDomain // 修改请求的域名
                );
                // 注册默认 COS Service
                Cos().registerDefaultService(serviceConfig);
              },
              child: const Text("自定义源站域名"),
            ),
            Gaps.vGap5,
            MaterialButton(
              minWidth: double.infinity,
              height: 30.0,
              color: Colours.app_main,
              textColor: Colors.white,
              onPressed: () async {
                // 存储桶region可以在COS控制台指定存储桶的概览页查看 https://console.cloud.tencent.com/cos5/bucket/ ，关于地域的详情见 https://cloud.tencent.com/document/product/436/6224
                String region = "ap-beijing"; // 您的存储桶地域
                bool accelerate = true; // 使能全球加速域名

                // 创建 CosXmlServiceConfig 对象，根据需要修改默认的配置参数
                CosXmlServiceConfig serviceConfig = CosXmlServiceConfig(
                    region: region,
                    isDebuggable: false,
                    isHttps: true,
                    accelerate: accelerate
                );
                // 注册默认 COS Service
                Cos().registerDefaultService(serviceConfig);
              },
              child: const Text("全球加速域名"),
            ),
            Gaps.vGap5,
            MaterialButton(
              minWidth: double.infinity,
              height: 30.0,
              color: Colours.app_main,
              textColor: Colors.white,
              onPressed: () async {
                // 存储桶名称，由bucketname-appid 组成，appid必须填入，可以在COS控制台查看存储桶名称。 https://console.cloud.tencent.com/cos5/bucket
                String bucket = "mobile-ut-1253960454";
                // 存储桶所在地域简称，例如广州地区是 ap-guangzhou
                String region = "ap-guangzhou";
                // 对象在存储桶中的位置标识符，即对象键
                String cosKey = "test.png";
                try {
                  String objectUrl = await Cos().getDefaultService().getObjectUrl(bucket, region, cosKey);
                  if (kDebugMode) {
                    print(objectUrl);
                  }
                } catch (e) {
                  // 失败后会抛异常 根据异常进行业务处理
                  Toast.show(e.toString());
                  if (kDebugMode) {
                    print(e);
                  }
                }
              },
              child: const Text("获取对象url"),
            ),
            Gaps.vGap5,
            MaterialButton(
              minWidth: double.infinity,
              height: 30.0,
              color: Colours.app_main,
              textColor: Colors.white,
              onPressed: () async {
                // 存储桶名称，由bucketname-appid 组成，appid必须填入，可以在COS控制台查看存储桶名称。 https://console.cloud.tencent.com/cos5/bucket
                String bucket = "000000-1253960454";
                // 对象在存储桶中的位置标识符，即对象键
                String cosKey = "1.txt";
                try {
                  HashMap<String, String> parameters = HashMap();
                  parameters["test1k"] = "test1v";
                  parameters["test2k"] = "test2v";
                  String objectUrl = await Cos().getDefaultService().getPresignedUrl(bucket, cosKey, signValidTime: 500, signHost: false, parameters: parameters);
                  if (kDebugMode) {
                    print(objectUrl);
                  }
                } catch (e) {
                  // 失败后会抛异常 根据异常进行业务处理
                  Toast.show(e.toString());
                  if (kDebugMode) {
                    print(e);
                  }
                }
              },
              child: const Text("预签名链接"),
            ),
            Gaps.vGap5,
            MaterialButton(
              minWidth: double.infinity,
              height: 30.0,
              color: Colours.app_main,
              textColor: Colors.white,
              onPressed: () async {
                await Cos().forceInvalidationCredential();
              },
              child: const Text("强制签名失效"),
            )
          ],
        ),
      ),
    );
  }
}
