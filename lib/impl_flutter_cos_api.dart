import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'extensions.dart';

import 'pigeon.dart';

import 'cos.dart';

class ImplFlutterCosApi extends FlutterCosApi{
  // 范围限制临时秘钥缓存
  static const int MAX_CACHE_CREDENTIAL_SIZE = 100;
  Map<int, SessionQCloudCredentials> credentialPairs = Map<int, SessionQCloudCredentials>.from({});

  void forceInvalidationScopeCredentials(){
    credentialPairs.clear();
  }

  @override
  Future<SessionQCloudCredentials> fetchSessionCredentials() {
    return Cos().getFetchCredentials().fetchSessionCredentials();
  }

  @override
  Future<SessionQCloudCredentials> fetchScopeLimitCredentials(List<STSCredentialScope?> stsCredentialScopes) async {
    // 先从缓存中获取，当scope一样的时候并且没有过期则使用缓存，否则调研业务回调方法获取最新的临时秘钥
    // 用于解决类似分块上传这种频繁但是秘钥大概率一样的情况
    String stsCredentialScopesJson = jsonifyScopes(stsCredentialScopes);
    if (kDebugMode) {
      print(stsCredentialScopesJson);
    }
    int scopeId = stsCredentialScopesJson.hashCode;
    SessionQCloudCredentials? credentials = lookupValidCredentials(scopeId);
    if (credentials == null) {
      credentials = await Cos().getFetchScopeLimitCredentials().fetchScopeLimitCredentials(stsCredentialScopes.map((e) => STSCredentialScope(
          action: e == null ? '' : (e.action),
          region: e == null ? '' : (e.region),
          bucket: e == null ? '' : (e.bucket ?? ''),
          prefix: e == null ? '' : (e.prefix ?? '')
      )).toList());
      cacheCredentialsAndCleanUp(scopeId, credentials);
    }
    return credentials;
  }

  @override
  Future<List<String>?> fetchDns(String domain) {
    return Cos().getFetchDns().fetchDns(domain);
  }

  @override
  void progressCallback(String transferKey, int key, int complete, int target) {
    Cos().getTransferManger(transferKey).runProgressCallBack(key, complete, target);
  }

  @override
  void resultFailCallback(String transferKey, int key, CosXmlClientException? clientException, CosXmlServiceException? serviceException) {
    Cos().getTransferManger(transferKey).runResultFailCallBack(key, clientException, serviceException);
  }

  @override
  void resultSuccessCallback(String transferKey, int key, Map<String?, String?>? header, CosXmlResult? result) {
    Cos().getTransferManger(transferKey).runResultSuccessCallBack(key, header, result);
  }

  @override
  void stateCallback(String transferKey, int key, String state) {
    Cos().getTransferManger(transferKey).runStateCallBack(key, state);
  }

  @override
  void initMultipleUploadCallback(String transferKey, int key, String bucket, String cosKey, String uploadId) {
    Cos().getTransferManger(transferKey).runInitMultipleUploadCallback(key, bucket, cosKey, uploadId);
  }

  // 以下为实现范围限制临时秘钥缓存的代码
  SessionQCloudCredentials? lookupValidCredentials(int scopeId) {
    SessionQCloudCredentials? credentials = credentialPairs[scopeId];
    if (credentials != null && credentials.isValid()) {
      return credentials;
    }
    return null;
  }

  void cacheCredentialsAndCleanUp(int scopeId, SessionQCloudCredentials newCredentials) {
    credentialPairs.removeWhere((key, value) => !value.isValid());

    if (credentialPairs.length > MAX_CACHE_CREDENTIAL_SIZE) {
      int overSize = credentialPairs.length - MAX_CACHE_CREDENTIAL_SIZE;
      credentialPairs.removeWhere((key, value) {
        if (overSize-- > 0) {
          return true;
        } else {
          return false;
        }
      });
    }

    credentialPairs[scopeId] = newCredentials;
  }

  String jsonifyScopes(List<STSCredentialScope?> scopes) {
    List<Map<String, String?>> scopeList = [];
    for (STSCredentialScope? scope in scopes) {
      if(scope != null) {
        Map<String, String?> scopeMap = {
          'action': scope.action,
          'bucket': scope.bucket,
          'prefix': scope.prefix,
          'region': scope.region,
        };
        scopeList.add(scopeMap);
      }
    }
    return jsonEncode(scopeList);
  }

  @override
  Future<SessionQCloudCredentials> fetchClsSessionCredentials() {
    return Cos().getFetchCLsChannelCredentials().fetchCLsChannelSessionCredentials();
  }

  @override
  void onLog(int key, LogEntity entity) {
    Cos().getLogListeners()[key]?.call(entity);
  }
}