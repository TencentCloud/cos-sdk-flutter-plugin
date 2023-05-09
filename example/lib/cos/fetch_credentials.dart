import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:tencentcloud_cos_sdk_plugin/fetch_credentials.dart';
import 'package:tencentcloud_cos_sdk_plugin/pigeon.dart';

import '../config/config.dart';

class FetchCredentials implements IFetchCredentials{
  @override
  Future<SessionQCloudCredentials> fetchSessionCredentials() async {
    var httpClient = HttpClient();

    try {
      var request = await httpClient.getUrl(Uri.parse(TestConst().STS_URL));
      var response = await request.close();
      if (response.statusCode == HttpStatus.OK) {
        var json = await response.transform(utf8.decoder).join();
        if (kDebugMode) {
          print(json);
        }
        var data = jsonDecode(json);
        return SessionQCloudCredentials(
            secretId: data['credentials']['tmpSecretId'],
            secretKey: data['credentials']['tmpSecretKey'],
            token: data['credentials']['sessionToken'],
            startTime: data['startTime'],
            expiredTime: data['expiredTime']
        );
      } else {
        throw ArgumentError();
      }
    } catch (exception) {
      if (kDebugMode) {
        print(exception);
      }
      throw ArgumentError();
    }
  }
}

class FetchScopeLimitCredentials implements IFetchScopeLimitCredentials{
  @override
  Future<SessionQCloudCredentials> fetchScopeLimitCredentials(List<STSCredentialScope?> stsCredentialScopes) async {
    var httpClient = HttpClient();
    try {
      var request = await httpClient.postUrl(Uri.parse(TestConst().STS_SCOPE_LIMIT_URL));
      request.headers.contentType = ContentType.json;
      final body = jsonifyScopes(stsCredentialScopes);
      if (kDebugMode) {
        print(body);
      }
      request.write(body);

      var response = await request.close();
      if (response.statusCode == HttpStatus.OK) {
        var json = await response.transform(utf8.decoder).join();
        if (kDebugMode) {
          print(json);
        }
        var data = jsonDecode(json);
        return SessionQCloudCredentials(
            secretId: data['credentials']['tmpSecretId'],
            secretKey: data['credentials']['tmpSecretKey'],
            token: data['credentials']['sessionToken'],
            startTime: data['startTime'],
            expiredTime: data['expiredTime']
        );
      } else {
        throw ArgumentError();
      }
    } catch (exception) {
      if (kDebugMode) {
        print(exception);
      }
      throw ArgumentError();
    }
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
}

