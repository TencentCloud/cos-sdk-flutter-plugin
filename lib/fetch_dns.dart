abstract class IFetchDns{
  /// 获取dns记录
  /// @param domain 域名
  /// @return ip集合
  Future<List<String>?> fetchDns(String domain);
}