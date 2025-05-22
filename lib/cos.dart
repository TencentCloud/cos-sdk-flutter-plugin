import 'dart:collection';

import 'package:flutter/foundation.dart';

import 'fetch_dns.dart';
import 'pigeon.dart';

import 'cos_service.dart';
import 'cos_transfer_manger.dart';
import 'exceptions.dart';
import 'fetch_credentials.dart';
import 'impl_flutter_cos_api.dart';

typedef OnLogCallBack = Function(LogEntity entity);

class Cos {
  static const String defaultKey = "";

  late OnLogCallBack onLogCallBack;

  final ImplFlutterCosApi flutterCosApi = ImplFlutterCosApi();
  Cos._internal() {
    FlutterCosApi.setup(flutterCosApi);
  }

  factory Cos() => _instance;
  static final Cos _instance = Cos._internal();

  final CosApi _cosApi = CosApi();

  final Map<String, CosService> _cosServices = HashMap();
  final Map<String, CosTransferManger> _cosTransferMangers = HashMap();

  bool _initialized = false;

  late IFetchCredentials _iFetchCredentials;
  IFetchCredentials getFetchCredentials(){
    return _iFetchCredentials;
  }

  late IFetchScopeLimitCredentials _iFetchScopeLimitCredentials;
  IFetchScopeLimitCredentials getFetchScopeLimitCredentials(){
    return _iFetchScopeLimitCredentials;
  }

  late IFetchDns _iFetchDns;
  IFetchDns getFetchDns(){
    return _iFetchDns;
  }

  final Map<int, void Function(LogEntity)> _logListeners = HashMap();
  Map<int, void Function(LogEntity)> getLogListeners(){
    return _logListeners;
  }

  late IFetchCLsChannelCredentials _iFetchCLsChannelCredentials;
  IFetchCLsChannelCredentials getFetchCLsChannelCredentials(){
    return _iFetchCLsChannelCredentials;
  }

  /// 设置永久秘钥
  Future<void> initWithPlainSecret(String secretId, String secretKey) async {
    if (!_initialized) {
      _initialized = true;
      return await _cosApi.initWithPlainSecret(secretId, secretKey);
    } else {
      if (kDebugMode) {
        print("COS Service has been inited before.");
      }
    }
  }

  /// 设置临时秘钥提供器
  Future<void> initWithSessionCredential(IFetchCredentials iFetchCredentials) async {
    if (!_initialized) {
      _initialized = true;
      _iFetchCredentials = iFetchCredentials;
      return await _cosApi.initWithSessionCredential();
    } else {
      if (kDebugMode) {
        print("COS Service has been inited before.");
      }
    }
  }

  /// 设置范围限制的临时秘钥提供器
  Future<void> initWithScopeLimitCredential(IFetchScopeLimitCredentials iFetchScopeLimitCredentials) async {
    if (!_initialized) {
      _initialized = true;
      _iFetchScopeLimitCredentials = iFetchScopeLimitCredentials;
      return await _cosApi.initWithScopeLimitCredential();
    } else {
      if (kDebugMode) {
        print("COS Service has been inited before.");
      }
    }
  }

  /// 初始化自定义 DNS 解析Map
  Future<void> initCustomerDNS(Map<String, List<String>> dnsMap) async {
    return _cosApi.initCustomerDNS(dnsMap);
  }

  /// 初始化自定义 DNS 解析器
  Future<void> initCustomerDNSFetch(IFetchDns iFetchDns) async {
    _iFetchDns = iFetchDns;
    return _cosApi.initCustomerDNSFetch();
  }

  /// 强制让本地保存临时秘钥失效
  /// 包括SessionCredential或ScopeLimitCredential
  Future<void> forceInvalidationCredential() async {
    flutterCosApi.forceInvalidationScopeCredentials();
    return await _cosApi.forceInvalidationCredential();
  }

  Future<void> setCloseBeacon(bool isCloseBeacon) async {
    return await _cosApi.setCloseBeacon(isCloseBeacon);
  }

  Future<CosService> registerDefaultService(CosXmlServiceConfig config) async {
    String key = await _cosApi.registerDefaultService(config);
    var cosService = CosService(key);
    _cosServices[key] = cosService;
    return cosService;
  }

  Future<CosTransferManger> registerDefaultTransferManger(
      CosXmlServiceConfig config, TransferConfig transferConfig) async {
    String key = await _cosApi.registerDefaultTransferManger(config, transferConfig);
    var cosTransferManger = CosTransferManger(key);
    _cosTransferMangers[key] = cosTransferManger;
    return cosTransferManger;
  }

  Future<CosService> registerService(
      String serviceKey, CosXmlServiceConfig config) async {
    if (serviceKey == defaultKey) {
      throw IllegalArgumentException("register key cannot be empty");
    }

    String key = await _cosApi.registerService(serviceKey, config);
    var cosService = CosService(key);
    _cosServices[key] = cosService;
    return cosService;
  }

  Future<CosTransferManger> registerTransferManger(String serviceKey,
      CosXmlServiceConfig config, TransferConfig transferConfig) async {
    if (serviceKey == defaultKey) {
      throw IllegalArgumentException("register key cannot be empty");
    }

    String key = await _cosApi.registerTransferManger(serviceKey, config, transferConfig);
    var cosTransferManger = CosTransferManger(key);
    _cosTransferMangers[key] = cosTransferManger;
    return cosTransferManger;
  }

  bool hasDefaultService() {
    return _cosServices.containsKey(defaultKey);
  }

  CosService getDefaultService() {
    if(_cosServices.containsKey(defaultKey)){
      return _cosServices[defaultKey]!;
    } else {
      throw IllegalArgumentException("default service unregistered");
    }
  }

  bool hasDefaultTransferManger() {
    return _cosTransferMangers.containsKey(defaultKey);
  }

  CosTransferManger getDefaultTransferManger() {
    if(_cosTransferMangers.containsKey(defaultKey)){
      return _cosTransferMangers[defaultKey]!;
    } else {
      throw IllegalArgumentException("default transfer manger unregistered");
    }
  }

  bool hasService(String key) {
    return _cosServices.containsKey(key);
  }

  CosService getService(String key) {
    if(_cosServices.containsKey(key)){
      return _cosServices[key]!;
    } else {
      throw IllegalArgumentException("$key service unregistered");
    }
  }

  bool hasTransferManger(String key) {
    return _cosTransferMangers.containsKey(key);
  }

  CosTransferManger getTransferManger(String key) {
    if(_cosTransferMangers.containsKey(key)){
      return _cosTransferMangers[key]!;
    } else {
      throw IllegalArgumentException("$key transfer manger unregistered");
    }
  }

  Future<void> enableLogcat(bool enable) async {
    return await _cosApi.enableLogcat(enable);
  }
  Future<void> enableLogFile(bool enable) async {
    return await _cosApi.enableLogFile(enable);
  }
  Future<void> addLogListener(void Function(LogEntity) callback) async {
    int key = callback.hashCode;
    _logListeners[key] = callback;
    return await _cosApi.addLogListener(key);
  }
  Future<void> removeLogListener(void Function(LogEntity) callback) async {
    int key = callback.hashCode;
    _logListeners.remove(key);
    return await _cosApi.removeLogListener(key);
  }
  Future<void> setMinLevel(LogLevel minLevel) async {
    return await _cosApi.setMinLevel(minLevel);
  }
  Future<void> setLogcatMinLevel(LogLevel minLevel) async {
    return await _cosApi.setLogcatMinLevel(minLevel);
  }
  Future<void> setFileMinLevel(LogLevel minLevel) async {
    return await _cosApi.setFileMinLevel(minLevel);
  }
  Future<void> setClsMinLevel(LogLevel minLevel) async {
    return await _cosApi.setClsMinLevel(minLevel);
  }
  Future<void> setDeviceID(String deviceID) async {
    return await _cosApi.setDeviceID(deviceID);
  }
  Future<void> setDeviceModel(String deviceModel) async {
    return await _cosApi.setDeviceModel(deviceModel);
  }
  Future<void> setAppVersion(String appVersion) async {
    return await _cosApi.setAppVersion(appVersion);
  }
  Future<void> setExtras(Map<String, String> extras) async {
    return await _cosApi.setExtras(extras);
  }
  Future<void> setLogFileEncryptionKey(Uint8List key, Uint8List iv) async {
    return await _cosApi.setLogFileEncryptionKey(key, iv);
  }
  Future<String> getLogRootDir() {
    return _cosApi.getLogRootDir();
  }
  Future<void> setCLsChannelAnonymous(String topicId, String endpoint) async {
    return await _cosApi.setCLsChannelAnonymous(topicId, endpoint);
  }
  Future<void> setCLsChannelStaticKey(String topicId, String endpoint,String secretId, String secretKey) async {
    return await _cosApi.setCLsChannelStaticKey(topicId, endpoint, secretId, secretKey);
  }
  Future<void> setCLsChannelSessionCredential(String topicId, String endpoint, IFetchCLsChannelCredentials iFetchCLsChannelCredentials) async {
    _iFetchCLsChannelCredentials = iFetchCLsChannelCredentials;
    return await _cosApi.setCLsChannelSessionCredential(topicId, endpoint);
  }
  Future<void> addSensitiveRule(String ruleName, String regex) async {
    return await _cosApi.addSensitiveRule(ruleName, regex);
  }
  Future<void> removeSensitiveRule(String ruleName) async {
    return await _cosApi.removeSensitiveRule(ruleName);
  }
}
