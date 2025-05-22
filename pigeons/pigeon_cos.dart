import 'package:pigeon/pigeon.dart';

@HostApi()
abstract class CosApi {
  void initWithPlainSecret(String secretId, String secretKey);

  void initWithSessionCredential();

  void initWithScopeLimitCredential();

  void initCustomerDNS(Map<String, List<String>> dnsMap);

  void initCustomerDNSFetch();

  void forceInvalidationCredential();

  void setCloseBeacon(bool isCloseBeacon);

  @async
  String registerDefaultService(CosXmlServiceConfig config);

  @async
  String registerDefaultTransferManger(
      CosXmlServiceConfig config, TransferConfig? transferConfig);

  @async
  String registerService(String key, CosXmlServiceConfig config);

  @async
  String registerTransferManger(
      String key, CosXmlServiceConfig config, TransferConfig? transferConfig);

  void enableLogcat(bool enable);

  void enableLogFile(bool enable);

  void addLogListener(int key);

  void removeLogListener(int key);

  void setMinLevel(LogLevel minLevel);

  void setLogcatMinLevel(LogLevel minLevel);

  void setFileMinLevel(LogLevel minLevel);

  void setClsMinLevel(LogLevel minLevel);

  void setDeviceID(String deviceID);

  void setDeviceModel(String deviceModel);

  void setAppVersion(String appVersion);

  void setExtras(Map<String, String> extras);

  void setLogFileEncryptionKey(Uint8List key, Uint8List iv);

  String getLogRootDir();

  void setCLsChannelAnonymous(String topicId, String endpoint);

  void setCLsChannelStaticKey(
      String topicId, String endpoint, String secretId, String secretKey);

  void setCLsChannelSessionCredential(String topicId, String endpoint);

  void addSensitiveRule(String ruleName, String regex);

  void removeSensitiveRule(String ruleName);
}

@HostApi()
abstract class CosServiceApi {
  @async
  Map<String?, String?> headObject(String serviceKey, String bucket,
      String? region, String cosPath, String? versionId, SessionQCloudCredentials? sessionCredentials);

  @async
  void deleteObject(String serviceKey, String bucket, String? region,
      String cosPath, String? versionId, SessionQCloudCredentials? sessionCredentials);

  String getObjectUrl(
      String bucket, String region, String cosPath, String serviceKey);

  @async
  String getPresignedUrl(
      String serviceKey,
      String bucket,
      String cosPath,
      int? signValidTime,
      bool? signHost,
      Map<String?, String?>? parameters,
      String? region, SessionQCloudCredentials? sessionCredentials);

  @async
  void preBuildConnection(String bucket, String serviceKey);

  @async
  ListAllMyBuckets getService(String serviceKey, SessionQCloudCredentials? sessionCredentials);

  @async
  BucketContents getBucket(
      String serviceKey,
      String bucket,
      String? region,
      String? prefix,
      String? delimiter,
      String? encodingType,
      String? marker,
      int? maxKeys,
      SessionQCloudCredentials? sessionCredentials);

  @async
  void putBucket(
      String serviceKey,
      String bucket,
      String? region,
      bool? enableMAZ,
      String? cosacl,
      String? readAccount,
      String? writeAccount,
      String? readWriteAccount,
      SessionQCloudCredentials? sessionCredentials);

  @async
  Map<String?, String?> headBucket(
      String serviceKey, String bucket, String? region,
      SessionQCloudCredentials? sessionCredentials);

  @async
  void deleteBucket(String serviceKey, String bucket, String? region, SessionQCloudCredentials? sessionCredentials);

  @async
  bool getBucketAccelerate(String serviceKey, String bucket, String? region, SessionQCloudCredentials? sessionCredentials);

  @async
  void putBucketAccelerate(
      String serviceKey, String bucket, String? region, bool enable, SessionQCloudCredentials? sessionCredentials);

  @async
  String getBucketLocation(String serviceKey, String bucket, String? region, SessionQCloudCredentials? sessionCredentials);

  @async
  bool getBucketVersioning(String serviceKey, String bucket, String? region, SessionQCloudCredentials? sessionCredentials);

  @async
  void putBucketVersioning(
      String serviceKey, String bucket, String? region, bool enable, SessionQCloudCredentials? sessionCredentials);

  @async
  bool doesBucketExist(String serviceKey, String bucket);

  @async
  bool doesObjectExist(String serviceKey, String bucket, String cosPath);

  void cancelAll(String serviceKey);
}

@HostApi()
abstract class CosTransferApi {
  String upload(
    String transferKey,
    String bucket,
    String cosPath,
    String? region,
    String? filePath,
    Uint8List? byteArr,
    String? uploadId,
    String? stroageClass,
    int? trafficLimit,
    String? callbackParam,
    Map<String, String>? customHeaders,
    List<String?>? noSignHeaders,
    int? resultCallbackKey,
    int? stateCallbackKey,
    int? progressCallbackKey,
    int? initMultipleUploadCallbackKey,
      SessionQCloudCredentials? sessionCredentials,
  );

  String download(
    String transferKey,
    String bucket,
    String cosPath,
    String? region,
    String savePath,
    String? versionId,
    int? trafficLimit,
    Map<String, String>? customHeaders,
    List<String?>? noSignHeaders,
    int? resultCallbackKey,
    int? stateCallbackKey,
    int? progressCallbackKey,
    SessionQCloudCredentials? sessionCredentials,
  );

  void pause(String taskId, String transferKey);

  void resume(String taskId, String transferKey);

  void cancel(String taskId, String transferKey);
}

@FlutterApi()
abstract class FlutterCosApi {
  @async
  SessionQCloudCredentials fetchSessionCredentials();

  @async
  SessionQCloudCredentials fetchScopeLimitCredentials(
      List<STSCredentialScope?> stsCredentialScopes);

  /// 获取dns记录
  /// @param domain 域名
  /// @return ip集合
  @async
  List<String>? fetchDns(String domain);

  void resultSuccessCallback(String transferKey, int key,
      Map<String?, String?>? header, CosXmlResult? result);

  void resultFailCallback(
      String transferKey,
      int key,
      CosXmlClientException? clientException,
      CosXmlServiceException? serviceException);

  void stateCallback(String transferKey, int key, String state);

  void progressCallback(String transferKey, int key, int complete, int target);

  void initMultipleUploadCallback(String transferKey, int key, String bucket,
      String cosKey, String uploadId);

  void onLog(int key, LogEntity entity);

  @async
  SessionQCloudCredentials fetchClsSessionCredentials();
}

class CosXmlServiceConfig {
  String? region;
  int? connectionTimeout;
  int? socketTimeout;
  bool? isHttps;
  String? host;
  String? hostFormat;
  int? port;
  bool? isDebuggable;
  bool? signInUrl;
  String? userAgent;
  bool? dnsCache;
  bool? accelerate;
  bool? domainSwitch;
  Map<String?, String?>? customHeaders;
  List<String?>? noSignHeaders;
}

class TransferConfig {
  bool? forceSimpleUpload;
  bool? enableVerification;
  int? divisionForUpload;
  int? sliceSizeForUpload;
}

class STSCredentialScope {
  late String action;
  late String region;
  String? bucket;
  String? prefix;
}

class SessionQCloudCredentials {
  late String secretId;
  late String secretKey;
  late String token;
  int? startTime;
  late int expiredTime;
}

class CosXmlResult {
  late String? eTag;
  late String? accessUrl;
  late CallbackResult? callbackResult;
}

class CallbackResult {
  /// Callback 是否成功。枚举值，支持 200、203。200表示上传成功、回调成功；203表示上传成功，回调失败
  late int status;

  /// Status为200时，说明上传成功、回调成功，返回 CallbackBody
  late String? callbackBody;

  /// Status为203时，说明Callback，返回 Error，说明回调失败信息
  late CallbackResultError? error;
}

class CallbackResultError {
  /// 回调失败信息的错误码，例如CallbackFailed
  late String? code;

  /// Callback 失败的错误信息
  late String? message;
}

class CosXmlClientException {
  late int errorCode;
  late String? message;
  late String? details;
}

class CosXmlServiceException {
  late int statusCode;
  late String? httpMsg;
  late String? requestId;
  late String? errorCode;
  late String? errorMessage;
  late String? serviceName;
  late String? details;
}

class Owner {
  /// 存储桶持有者的完整 ID
  late String id;

  /// 存储桶持有者的名字
  late String? disPlayName;
}

/// 日志级别枚举
enum LogLevel { verbose, debug, info, warn, error }

enum LogCategory { process, result, network, probe, error }

class LogEntity {
  // 日志时间戳（毫秒）
  late int timestamp;

  // 日志级别
  late LogLevel level;

  // 日志分类
  late LogCategory category;

  // 日志标签
  late String tag;

  // 日志消息内容
  late String message;

  // 记录日志的线程名称
  late String threadName;

  // 额外信息（可选）
  late Map<String?, String?>? extras;

  // 异常信息（可选）
  late String? throwable;
}

class Bucket {
  /// 存储桶的名称
  late String name;

  /// 存储桶所在地域
  late String? location;

  /// 存储桶的创建时间，为 ISO8601 格式，例如2019-05-24T10:56:40Z
  late String? createDate;
  late String? type;
}

class ListAllMyBuckets {
  /// 存储桶持有者信息
  late Owner owner;

  /// 存储桶列表
  late List<Bucket?> buckets;
}

class CommonPrefixes {
  /// Common Prefix 的前缀
  late String prefix;
}

class Content {
  /// 对象键
  late String key;

  /// 对象最后修改时间，为 ISO8601 格式，如2019-05-24T10:56:40Z
  late String lastModified;

  /// 对象的实体标签（Entity Tag），是对象被创建时标识对象内容的信息标签，可用于检查对象的内容是否发生变化，
  /// 例如“8e0b617ca298a564c3331da28dcb50df”，此头部并不一定返回对象的 MD5 值，而是根据对象上传和加密方式而有所不同
  late String eTag;

  /// 对象大小，单位为 Byte
  late int size;

  /// 对象持有者信息
  late Owner owner;

  /// 对象存储类型
  late String storageClass;
}

class BucketContents {
  /// 存储桶的名称，格式为<BucketName-APPID>，例如examplebucket-1250000000
  late String name;

  /// 编码格式，对应请求中的 encoding-type 参数，且仅当请求中指定了 encoding-type 参数才会返回该节点
  String? encodingType;

  /// 对象键匹配前缀，对应请求中的 prefix 参数
  String? prefix;

  /// 起始对象键标记，从该标记之后（不含）按照 UTF-8 字典序返回对象键条目，对应请求中的 marker 参数
  String? marker;

  /// 单次响应返回结果的最大条目数量，对应请求中的 max-keys 参数
  /// 注意：该参数会限制每一次 List 操作返回的最大条目数，COS 在每次 List 操作中将返回不超过 max-keys 所设定数值的条目。
  /// 如果由于您设置了 max-keys 参数，导致单次响应中未列出所有对象，COS 会返回一项 nextmarker 参数作为您下次 List 请求的入参，
  /// 以便您后续进行列出对象
  late int maxKeys;

  /// 响应条目是否被截断，布尔值，例如 true 或 false
  late bool isTruncated;

  /// 仅当响应条目有截断（IsTruncated 为 true）才会返回该节点，
  /// 该节点的值为当前响应条目中的最后一个对象键，当需要继续请求后续条目时，将该节点的值作为下一次请求的 marker 参数传入
  String? nextMarker;

  /// 对象条目
  late List<Content?> contentsList;

  /// 从 prefix 或从头（如未指定 prefix）到首个 delimiter 之间相同的部分，
  /// 定义为 Common Prefix。仅当请求中指定了 delimiter 参数才有可能返回该节点
  late List<CommonPrefixes?> commonPrefixesList;

  /// 分隔符，对应请求中的 delimiter 参数，且仅当请求中指定了 delimiter 参数才会返回该节点
  String? delimiter;
}
