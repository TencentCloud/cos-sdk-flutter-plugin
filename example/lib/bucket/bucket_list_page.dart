import 'package:tencentcloud_cos_sdk_plugin/cos.dart';
import 'package:tencentcloud_cos_sdk_plugin/cos_service.dart';
import 'package:tencentcloud_cos_sdk_plugin/pigeon.dart';
import 'package:flutter/material.dart';

import 'package:pull_to_refresh/pull_to_refresh.dart';
import '../common/constant.dart';
import '../common/toast_utils.dart';
import '../common/utils.dart';
import '../routers/delegate.dart';

class BucketListPage extends StatefulWidget {
  const BucketListPage({
    super.key,
  });

  @override
  createState() => _BucketListPageState();
}

class _BucketListPageState extends State<BucketListPage> {
  final CosService _defaultService = Cos().getDefaultService();

  final List<Bucket?> _items = [];
  final RefreshController _refreshController = RefreshController(
      initialRefresh: true);

  void _onRefresh() async {
    try {
      //cos 获取桶列表
      ListAllMyBuckets listAllMyBuckets = await _defaultService.getService();
      setState(() {
        _items.clear();
        _items.addAll(listAllMyBuckets.buckets);
      });
      _refreshController.refreshCompleted();
    } catch (e) {
      Toast.show(e.toString());
      print(e);
      _refreshController.refreshFailed();
    }
  }

  @override
  void dispose() async {
    super.dispose();
    CosService defaultService = Cos().getDefaultService();
    defaultService.cancelAll();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('存储桶列表'),
          actions: [
            IconButton(
              onPressed: () async {
                bool? isAdd = await MyRouterDelegate.of(context).push(name: "/bucket/add");
                if(isAdd == true){
                  _refreshController.requestRefresh();
                }
                // await MyRouterDelegate.of(context).push(name: "/test");
              },
              icon: const Icon(Icons.add),
            ),
          ]
      ),
      body: SmartRefresher(
        enablePullDown: true,
        enablePullUp: false,
        footer: Constant.listFooter,
        controller: _refreshController,
        onRefresh: _onRefresh,
        child: ListView.builder(
          itemBuilder: (c, i) => Card(child: ListTile(
            title: Text("名称：${_items[i]!.name}"),
            subtitle: Text("地区：${_items[i]!.location}\n创建时间：${Utils.toDateTimeString(_items[i]!.createDate)}"),
            trailing: const Icon(Icons.keyboard_arrow_right),
            isThreeLine: true,
            onTap: () => MyRouterDelegate.of(context).push(name: "/object", arguments: {'bucketName':_items[i]!.name,'bucketRegion':_items[i]!.location!}),
          )),
          itemCount: _items.length,
        ),
      ),
    );
  }
}
