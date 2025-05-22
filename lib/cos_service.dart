import 'pigeon.dart';

class CosService {
  late String serviceKey;

  CosService(this.serviceKey);

  final CosServiceApi cosApi = CosServiceApi();

  Future<Map<String?, String?>> headObject(String bucket, String cosPath,
      {String? region, String? versionId, SessionQCloudCredentials? sessionCredentials}) {
    return cosApi.headObject(serviceKey, bucket, region, cosPath, versionId, sessionCredentials);
  }

  Future<void> deleteObject(String bucket, String cosPath,
      {String? region, String? versionId, SessionQCloudCredentials? sessionCredentials}) {
    return cosApi.deleteObject(serviceKey, bucket, region, cosPath, versionId, sessionCredentials);
  }

  /// 获取get请求未签名链接
  /// bucket 存储桶名称，由BucketName-Appid 组成，可以在COS控制台查看 https://console.cloud.tencent.com/cos5/bucket
  /// region 地域
  /// cosPath 对象键，是对象在 COS 上的完整路径，如果带目录的话，格式为 "video/xxx/movie.mp4"
  Future<String> getObjectUrl(String bucket, String region, String cosPath) {
    return cosApi.getObjectUrl(bucket, region, cosPath, serviceKey);
  }

  /// 获取get请求预签名链接
  /// bucket 存储桶名称，由BucketName-Appid 组成，可以在COS控制台查看 https://console.cloud.tencent.com/cos5/bucket
  /// cosPath 对象键，是对象在 COS 上的完整路径，如果带目录的话，格式为 "video/xxx/movie.mp4"
  /// signValidTime 设置签名有效期(单位为秒)，注意这里是签名有效期，您需要自行保证密钥有效期
  /// signHost 是否签入Header Host，不签可能导致请求失败或安全漏洞
  /// parameters http请求参数，传入的请求参数需与实际请求相同，能够防止用户篡改此HTTP请求的参数
  Future<String> getPresignedUrl(
      String bucket,
      String cosPath,
      {
      int? signValidTime,
      bool? signHost,
      Map<String?, String?>? parameters,
      String? region, SessionQCloudCredentials? sessionCredentials
      }
  ) {
    return cosApi.getPresignedUrl(serviceKey, bucket, cosPath, signValidTime, signHost, parameters, region, sessionCredentials);
  }

  Future<void> preBuildConnection(String bucket) {
    return cosApi.preBuildConnection(bucket, serviceKey);
  }

  Future<ListAllMyBuckets> getService({SessionQCloudCredentials? sessionCredentials}) {
    return cosApi.getService(serviceKey,sessionCredentials);
  }

  Future<BucketContents> getBucket(String bucket,
      {String? region,
      String? prefix,
      String? delimiter,
      String? encodingType,
      String? marker,
      int? maxKeys,
      SessionQCloudCredentials? sessionCredentials}) {
    return cosApi.getBucket(serviceKey, bucket, region, prefix, delimiter,
        encodingType, marker, maxKeys, sessionCredentials);
  }

  Future<void> putBucket(String bucket,
      {String? region,
      bool? enableMAZ,
      String? cosacl,
      String? readAccount,
      String? writeAccount,
      String? readWriteAccount, SessionQCloudCredentials? sessionCredentials}) {
    return cosApi.putBucket(serviceKey, bucket, region, enableMAZ, cosacl,
        readAccount, writeAccount, readWriteAccount, sessionCredentials);
  }

  Future<Map<String?, String?>> headBucket(String bucket, {String? region, SessionQCloudCredentials? sessionCredentials}) {
    return cosApi.headBucket(serviceKey, bucket, region, sessionCredentials);
  }

  Future<void> deleteBucket(String bucket, {String? region, SessionQCloudCredentials? sessionCredentials}) {
    return cosApi.deleteBucket(serviceKey, bucket, region, sessionCredentials);
  }

  Future<bool> getBucketAccelerate(String bucket, {String? region, SessionQCloudCredentials? sessionCredentials}) {
    return cosApi.getBucketAccelerate(serviceKey, bucket, region, sessionCredentials);
  }

  Future<void> putBucketAccelerate(String bucket, bool enable,
      {String? region, SessionQCloudCredentials? sessionCredentials}) {
    return cosApi.putBucketAccelerate(serviceKey, bucket, region, enable, sessionCredentials);
  }

  Future<String> getBucketLocation(String bucket, {String? region, SessionQCloudCredentials? sessionCredentials}) {
    return cosApi.getBucketLocation(serviceKey, bucket, region, sessionCredentials);
  }

  Future<bool> getBucketVersioning(String bucket, {String? region, SessionQCloudCredentials? sessionCredentials}) {
    return cosApi.getBucketVersioning(serviceKey, bucket, region, sessionCredentials);
  }

  Future<void> putBucketVersioning(String bucket, bool enable,
      {String? region, SessionQCloudCredentials? sessionCredentials}) {
    return cosApi.putBucketVersioning(serviceKey, bucket, region, enable, sessionCredentials);
  }

  Future<bool> doesBucketExist(String bucket) {
    return cosApi.doesBucketExist(serviceKey, bucket);
  }

  Future<bool> doesObjectExist(String bucket, String cosPath) {
    return cosApi.doesObjectExist(serviceKey, bucket, cosPath);
  }

  Future<void> cancelAll() {
    return cosApi.cancelAll(serviceKey);
  }
}
