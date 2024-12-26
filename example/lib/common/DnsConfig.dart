import 'package:flutter/foundation.dart';
import 'package:tencentcloud_cos_sdk_plugin_nobeacon/fetch_dns.dart';
/// 测试用的自定义DNS配置
class FetchDns implements IFetchDns{
  static Map<String, List<String>> dnsMap = {
    'service.cos.myqcloud.com': ["106.119.174.56", "106.119.174.57", "106.119.174.55"],
    '000000-1253960454.cos.ap-guangzhou.myqcloud.com': ["27.155.119.179", "27.155.119.180", "27.155.119.166", "27.155.119.181"],
    'cos.ap-guangzhou.myqcloud.com': ["27.155.119.179", "27.155.119.180", "27.155.119.166", "27.155.119.181"],
  };
  @override
  Future<List<String>?> fetchDns(String domain) async {
    final matchedEntries = dnsMap.entries.where((entry) => domain.endsWith(entry.key));
    for (var entry in matchedEntries) {
      if (kDebugMode) {
        print('Host: ${entry.key}, IPS: ${entry.value}');
      }
      return entry.value;
    }
    return null;
  }
}