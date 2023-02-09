import 'package:flutter/material.dart';

import '../bucket/bucket_add_page.dart';
import '../bucket/bucket_list_page.dart';
import '../bucket/region_list_page.dart';
import '../object/object_list_page.dart';
import '../test/test_page.dart';
import '../transfer/download_page.dart';
import '../transfer/upload_page.dart';
import '../common/toast_utils.dart';
import 'custom_page.dart';
import 'not_found_page.dart';

class MyRouterDelegate extends RouterDelegate<String> with ChangeNotifier, PopNavigatorRouterDelegateMixin<String> {
  static MyRouterDelegate of(BuildContext context) {
    final delegate = Router.of(context).routerDelegate;
    assert(delegate is MyRouterDelegate, 'Delegate type must match');
    return delegate as MyRouterDelegate;
  }

  MyRouterDelegate(){
    //首页
    _pages.add(_createPage(const RouteSettings(name: "/bucket")));
  }

  final List<Page> _pages = [];

  @override
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      pages: List.of(_pages),
      onPopPage: _onPopPage,
    );
  }

  @override
  Future<void> setNewRoutePath(String configuration) async {}

  @override
  Future<bool> popRoute() {
    if (canPop()) {
      _pages.removeLast();
      notifyListeners();
      return Future.value(true);
    }
    return _confirmExit();
  }

  bool canPop() {
    return _pages.length > 1;
  }

  bool _onPopPage(Route route, dynamic result) {
    if (!route.didPop(result)) return false;

    if (canPop()) {
      _pages.removeLast();
      return true;
    } else {
      return false;
    }
  }

  void pop<T extends Object?>([T? result]) {
    final finder = _pages.removeLast() as CustomPage;
    notifyListeners();
    finder.completerResult.complete(result);
  }

  Future<dynamic> push({required String name, dynamic arguments}) async {
    var page = _createPage(RouteSettings(name: name, arguments: arguments));
    _pages.add(page);
    notifyListeners();
    return await page.completerResult.future;
  }

  void replace({required String name, dynamic arguments}) {
    if (_pages.isNotEmpty) {
      _pages.removeLast();
    }
    push(name: name,arguments: arguments);
  }

  CustomPage _createPage(RouteSettings routeSettings) {
    Widget child;

    switch (routeSettings.name) {
      case '/bucket':
        child = const BucketListPage();
        break;
      case '/bucket/add':
        child = const BucketAddPage();
        break;
      case '/object':
        child = ObjectListPage(routeSettings.arguments! as Map<String, String>);
        break;
      case '/region':
        child = const RegionListPage();
        break;
      case '/download':
        child = DownloadPage(routeSettings.arguments! as Map<String, String>);
        break;
      case '/upload':
        child = UploadPage(routeSettings.arguments! as Map<String, String?>);
        break;
      case '/test':
        child = TestPage();
        break;
      default:
        child = const NotFoundPage();
    }

    return CustomPage(
      child: child,
      key: Key(routeSettings.name! + routeSettings.arguments.hashCode.toString()) as LocalKey,
      name: routeSettings.name,
      arguments: routeSettings.arguments,
    );
  }

  int _lastPressTime = 0;

  Future<bool> _confirmExit() {
    int pressTime = DateTime.now().millisecondsSinceEpoch;
    bool result = _lastPressTime == 0 || pressTime - _lastPressTime > 2000;
    _lastPressTime = pressTime;
    if(result){
      Toast.show("再按一次退出");
      return Future.value(true);
    } else {
      return Future.value(false);
    }
  }
}