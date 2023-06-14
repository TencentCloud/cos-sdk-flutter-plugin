import 'dart:collection';

import 'package:flutter/foundation.dart';

import 'pigeon.dart';

import 'cos_service.dart';
import 'cos_transfer_manger.dart';
import 'exceptions.dart';
import 'fetch_credentials.dart';
import 'impl_flutter_cos_api.dart';

class Cos {
  static const String defaultKey = "";

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
}
