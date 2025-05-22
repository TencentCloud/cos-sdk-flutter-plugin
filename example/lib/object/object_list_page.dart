import 'package:flutter/foundation.dart';
import 'package:tencentcloud_cos_sdk_plugin/cos.dart';
import 'package:tencentcloud_cos_sdk_plugin/cos_service.dart';
import 'package:tencentcloud_cos_sdk_plugin/pigeon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import '../../common/constant.dart';
import '../../common/toast_utils.dart';
import '../common/DnsConfig.dart';
import '../common/res/colors.dart';
import '../cos/fetch_credentials.dart';
import '../routers/delegate.dart';
import '../../common/utils.dart';
import 'object_entity.dart';

class ObjectListPage extends StatefulWidget {
  final String bucketName;
  final String bucketRegion;
  final String? folderPath;

  ObjectListPage(
    Map<String, String> arguments, {
    super.key,
  })  : bucketName = arguments['bucketName']!,
        bucketRegion = arguments['bucketRegion']!,
        folderPath = arguments['folderPath'];

  @override
  createState() => _ObjectListPageState();
}

class _ObjectListPageState extends State<ObjectListPage> {
  CosService? _cosService;

  //分页标示
  String? _marker;

  //是否截断（用来判断分页数据是否完全加载）
  bool _isTruncated = false;

  final List<ObjectEntity> _items = [];
  final RefreshController _refreshController =
      RefreshController(initialRefresh: true);

  Future<CosService> getCosService() async {
    if(_cosService == null){
      if(Cos().hasService(widget.bucketRegion)){
        _cosService = Cos().getService(widget.bucketRegion);
      } else {
        _cosService = await Cos().registerService(widget.bucketRegion,
            Constant.serviceConfig..region = widget.bucketRegion);
      }
    }
    return _cosService!;
  }

  void _onRefresh() async {
    try {
      //cos 分页获取对象列表
      CosService cosService = await getCosService();
      BucketContents bucketContents = await cosService.getBucket(
          widget.bucketName,
          prefix: widget.folderPath,
          delimiter: "/",
          maxKeys: 100,
          sessionCredentials: await FetchCredentials.getSessionCredentials()
      );
      _isTruncated = bucketContents.isTruncated;
      _marker = bucketContents.nextMarker;
      setState(() {
        _items.clear();
        _items.addAll(ObjectEntity.bucketContents2ObjectList(
            bucketContents, widget.folderPath));
      });
      _refreshController.refreshCompleted(resetFooterState: true);
      if (!_isTruncated) {
        _refreshController.loadNoData();
      }
    } catch (e) {
      Toast.show(e.toString());
      if (kDebugMode) {
        print(e);
      }
      _refreshController.refreshFailed();
    }
  }

  void _onLoading() async {
    try {
      //cos 分页获取对象列表
      CosService cosService = await getCosService();
      BucketContents bucketContents = await cosService.getBucket(
          widget.bucketName,
          prefix: widget.folderPath,
          delimiter: "/",
          marker: _marker,
          maxKeys: 100,
          sessionCredentials: await FetchCredentials.getSessionCredentials()
      );
      _isTruncated = bucketContents.isTruncated;
      _marker = bucketContents.nextMarker;
      if (mounted) {
        setState(() {
          _items.addAll(ObjectEntity.bucketContents2ObjectList(
              bucketContents, widget.folderPath));
        });
      }
      _refreshController.loadComplete();
      if (!_isTruncated) {
        _refreshController.loadNoData();
      }
    } catch (e) {
      Toast.show(e.toString());
      if (kDebugMode) {
        print(e);
      }
      _refreshController.loadFailed();
    }
  }

  @override
  void dispose() async {
    super.dispose();
    CosService cosService = await getCosService();
    cosService.cancelAll();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            title: Text(
                widget.folderPath ?? widget.bucketName,
                overflow: TextOverflow.fade,
            ),
            actions: [
              IconButton(
                onPressed: () {
                  MyRouterDelegate.of(context).push(name: "/upload", arguments: {
                    'bucketName': widget.bucketName,
                    'bucketRegion': widget.bucketRegion,
                    'folderPath': widget.folderPath
                  });
                },
                icon: const Icon(Icons.upload),
              ),
            ]),
        body: SmartRefresher(
            enablePullDown: true,
            enablePullUp: true,
            footer: Constant.listFooter,
            controller: _refreshController,
            onRefresh: _onRefresh,
            onLoading: _onLoading,
            child: ListView.builder(
                itemBuilder: (c, i) =>
                    Card(child: _buildFListItemWidget(context, _items[i])),
                itemCount: _items.length)));
  }

  Widget _buildFListItemWidget(
      BuildContext context, ObjectEntity objectEntity) {
    if (objectEntity.getType() == 0) {
      return _buildFolderWidget(context, objectEntity);
    } else {
      return _buildFileWidget(context, objectEntity);
    }
  }

  Widget _buildFolderWidget(BuildContext context, ObjectEntity objectEntity) {
    String text;
    if (widget.folderPath == null || widget.folderPath!.isEmpty) {
      text = objectEntity.getCommonPrefixes()!.prefix;
    } else {
      text = objectEntity
          .getCommonPrefixes()!
          .prefix
          .replaceFirst(widget.folderPath!, "");
    }

    return ListTile(
        title: Text(text,
            overflow: TextOverflow.fade,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colours.app_main)),
        trailing: const Icon(Icons.keyboard_arrow_right),
        onTap: () =>
            MyRouterDelegate.of(context).push(name: "/object", arguments: {
              'bucketName': widget.bucketName,
              'bucketRegion': widget.bucketRegion,
              'folderPath': objectEntity.getCommonPrefixes()!.prefix
            }));
  }

  Widget _buildFileWidget(BuildContext context, ObjectEntity objectEntity) {
    return ListTile(
      title: Text(
        "名称：${objectEntity.getContent()!.key.split("/").last}",
        overflow: TextOverflow.fade,
      ),
      subtitle: Text(
          "创建时间：${Utils.toDateTimeString(objectEntity.getContent()!.lastModified)}\n大小：${Utils.readableStorageSize(objectEntity.getContent()!.size)}"),
      trailing: const Icon(Icons.more_horiz_rounded),
      isThreeLine: true,
      onTap: () => showMaterialModalBottomSheet(
          backgroundColor: Colors.white,
          context: context,
          builder: (context) => Material(
                  child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    ListTile(
                      title: const Text('下载'),
                      leading: const Icon(Icons.download),
                      onTap: () {
                        MyRouterDelegate.of(context).push(name: "/download", arguments: {
                          'bucketName': widget.bucketName,
                          'bucketRegion': widget.bucketRegion,
                          'fileKey': objectEntity.getContent()!.key
                        });
                        if (mounted) {
                          Navigator.pop(context);
                        }
                      },
                    ),
                    ListTile(
                      title: const Text('删除'),
                      leading: const Icon(Icons.delete),
                      onTap: () async {
                        try {
                          EasyLoading.show(status: '正在删除...');
                          CosService cosService = await getCosService();
                          await cosService.deleteObject(widget.bucketName,
                              objectEntity.getContent()!.key, sessionCredentials: await FetchCredentials.getSessionCredentials());
                          EasyLoading.showSuccess(
                              "${objectEntity.getContent()!.key}已删除");
                          _refreshController.requestRefresh();
                          if (mounted) {
                            Navigator.pop(context);
                          }
                        } catch (e) {
                          if (kDebugMode) {
                            print(e);
                          }
                          EasyLoading.showError(e.toString());
                        }
                      },
                    ),
                  ],
                ),
              ))),
    );
  }
}
