import 'pigeon.dart';

class CosService {
  late String serviceKey;

  CosService(this.serviceKey);

  final CosServiceApi cosApi = CosServiceApi();

  Future<Map<String?, String?>> headObject(String bucket, String cosPath,
      {String? region, String? versionId}) {
    return cosApi.headObject(serviceKey, bucket, region, cosPath, versionId);
  }

  Future<void> deleteObject(String bucket, String cosPath,
      {String? region, String? versionId}) {
    return cosApi.deleteObject(serviceKey, bucket, region, cosPath, versionId);
  }

  Future<String> getObjectUrl(String bucket, String region, String key) {
    return cosApi.getObjectUrl(bucket, region, key, serviceKey);
  }

  Future<void> preBuildConnection(String bucket) {
    return cosApi.preBuildConnection(bucket, serviceKey);
  }

  Future<ListAllMyBuckets> getService() {
    return cosApi.getService(serviceKey);
  }

  Future<BucketContents> getBucket(String bucket,
      {String? region,
      String? prefix,
      String? delimiter,
      String? encodingType,
      String? marker,
      int? maxKeys}) {
    return cosApi.getBucket(serviceKey, bucket, region, prefix, delimiter,
        encodingType, marker, maxKeys);
  }

  Future<void> putBucket(String bucket,
      {String? region,
      bool? enableMAZ,
      String? cosacl,
      String? readAccount,
      String? writeAccount,
      String? readWriteAccount}) {
    return cosApi.putBucket(serviceKey, bucket, region, enableMAZ, cosacl,
        readAccount, writeAccount, readWriteAccount);
  }

  Future<Map<String?, String?>> headBucket(String bucket, {String? region}) {
    return cosApi.headBucket(serviceKey, bucket, region);
  }

  Future<void> deleteBucket(String bucket, {String? region}) {
    return cosApi.deleteBucket(serviceKey, bucket, region);
  }

  Future<bool> getBucketAccelerate(String bucket, {String? region}) {
    return cosApi.getBucketAccelerate(serviceKey, bucket, region);
  }

  Future<void> putBucketAccelerate(String bucket, bool enable,
      {String? region}) {
    return cosApi.putBucketAccelerate(serviceKey, bucket, region, enable);
  }

  Future<String> getBucketLocation(String bucket, {String? region}) {
    return cosApi.getBucketLocation(serviceKey, bucket, region);
  }

  Future<bool> getBucketVersioning(String bucket, {String? region}) {
    return cosApi.getBucketVersioning(serviceKey, bucket, region);
  }

  Future<void> putBucketVersioning(String bucket, bool enable,
      {String? region}) {
    return cosApi.putBucketVersioning(serviceKey, bucket, region, enable);
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
