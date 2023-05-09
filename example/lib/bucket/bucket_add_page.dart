import 'package:flutter/foundation.dart';
import 'package:tencentcloud_cos_sdk_plugin/cos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

import '../common/res/colors.dart';
import '../common/res/gaps.dart';
import '../common/toast_utils.dart';
import '../routers/delegate.dart';
import '../config/config.dart';

class BucketAddPage extends StatefulWidget {
  const BucketAddPage({
    super.key,
  });

  @override
  createState() => _BucketAddPageState();
}

class _BucketAddPageState extends State<BucketAddPage> {
  String? _region;
  final TextEditingController _bucketNameEtController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('新建存储桶'),
      ),
      body: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: <Widget>[
            TextField(
              controller: _bucketNameEtController,
              decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '请输入桶名称',
              ),
            ),
            Gaps.vGap32,
            ListTile(
              tileColor:Colours.text_gray_c,
              title: Text(_region == null ? "请选择地区" : "已选择：$_region"),
              trailing: const Icon(Icons.keyboard_arrow_right),
              onTap: () async {
                String region =
                    await MyRouterDelegate.of(context).push(name: "/region");
                setState(() {
                  _region = region;
                });
              },
            ),
            Gaps.vGap50,
            MaterialButton(
              minWidth: double.infinity,
              height: 50.0,
              color: Colours.app_main,
              textColor: Colors.white,
              onPressed: () async {
                if(_region == null){
                  Toast.show("请选择地区");
                  return;
                }
                if(_bucketNameEtController.text.isEmpty){
                  Toast.show("桶名称不能为空");
                  return;
                }
                String bucket = "${_bucketNameEtController.text}-${TestConst().COS_APP_ID}";

                try{
                  EasyLoading.show(status: '正在创建...');
                  await Cos().getDefaultService().putBucket(bucket, region: _region);
                  EasyLoading.showSuccess("$bucket桶已创建");
                  if (mounted) {
                    MyRouterDelegate.of(context).pop(true);
                  }
                } catch(e) {
                  if (kDebugMode) {
                    print(e);
                  }
                  EasyLoading.showError(e.toString());
                }
              },
              child: const Text("创建"),
            )
          ],
        ),
      ),
    );
  }
}
