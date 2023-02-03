import 'package:flutter/material.dart';
import '../routers/delegate.dart';

class RegionListPage extends StatefulWidget {
  const RegionListPage({
    super.key,
  });

  @override
  createState() => _RegionListPageState();
}

class _RegionListPageState extends State<RegionListPage> {
  final List<Set> _items = [
    {"ap-chengdu", "成都"},
    {"ap-beijing", "北京"},
    {"ap-guangzhou", "广州"},
    {"ap-shanghai", "上海"},
    {"ap-chongqing", "重庆"},
    {"ap-hongkong", "中国香港"},
    {"ap-beijing-fsi", "北京金融"},
    {"ap-shanghai-fsi", "上海金融"},
    {"ap-shenzhen-fsi", "深圳金融"},
    {"ap-singapore", "新加坡"},
    {"ap-mumbai", "印度孟买"},
    {"ap-seoul", "韩国首尔"},
    {"ap-bangkok", "泰国曼谷"},
    {"ap-tokyo", "日本东京"},
    {"eu-moscow", "俄罗斯莫斯科"},
    {"eu-frankfurt", "德国法兰克福"},
    {"na-toronto", "加拿大多伦多"},
    {"na-ashburn", "美东弗吉尼亚"},
    {"na-siliconvalley", "美西硅谷"}
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('选择区域'),
        ),
        body: ListView.builder(
          itemBuilder: (c, i) => Card(
              child: ListTile(
                  title: Text(_items[i].last),
                  trailing: const Icon(Icons.keyboard_arrow_right),
                  onTap: () =>
                      MyRouterDelegate.of(context).pop(_items[i].first))),
          itemCount: _items.length,
        ));
  }
}
