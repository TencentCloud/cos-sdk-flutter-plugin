// Autogenerated from Pigeon (v4.2.14), do not edit directly.
// See also: https://pub.dev/packages/pigeon
#import <Foundation/Foundation.h>
@protocol FlutterBinaryMessenger;
@protocol FlutterMessageCodec;
@class FlutterError;
@class FlutterStandardTypedData;

NS_ASSUME_NONNULL_BEGIN

/// 日志级别枚举
typedef NS_ENUM(NSUInteger, LogLevel) {
  LogLevelVerbose = 0,
  LogLevelDebug = 1,
  LogLevelInfo = 2,
  LogLevelWarn = 3,
  LogLevelError = 4,
};

typedef NS_ENUM(NSUInteger, LogCategory) {
  LogCategoryProcess = 0,
  LogCategoryResult = 1,
  LogCategoryNetwork = 2,
  LogCategoryProbe = 3,
  LogCategoryError = 4,
};

@class CosXmlServiceConfig;
@class TransferConfig;
@class STSCredentialScope;
@class SessionQCloudCredentials;
@class CosXmlResult;
@class CallbackResult;
@class CallbackResultError;
@class CosXmlClientException;
@class CosXmlServiceException;
@class Owner;
@class LogEntity;
@class Bucket;
@class ListAllMyBuckets;
@class CommonPrefixes;
@class Content;
@class BucketContents;

@interface CosXmlServiceConfig : NSObject
+ (instancetype)makeWithRegion:(nullable NSString *)region
    connectionTimeout:(nullable NSNumber *)connectionTimeout
    socketTimeout:(nullable NSNumber *)socketTimeout
    isHttps:(nullable NSNumber *)isHttps
    host:(nullable NSString *)host
    hostFormat:(nullable NSString *)hostFormat
    port:(nullable NSNumber *)port
    isDebuggable:(nullable NSNumber *)isDebuggable
    signInUrl:(nullable NSNumber *)signInUrl
    userAgent:(nullable NSString *)userAgent
    dnsCache:(nullable NSNumber *)dnsCache
    accelerate:(nullable NSNumber *)accelerate
    domainSwitch:(nullable NSNumber *)domainSwitch
    customHeaders:(nullable NSDictionary<NSString *, NSString *> *)customHeaders
    noSignHeaders:(nullable NSArray<NSString *> *)noSignHeaders;
@property(nonatomic, copy, nullable) NSString * region;
@property(nonatomic, strong, nullable) NSNumber * connectionTimeout;
@property(nonatomic, strong, nullable) NSNumber * socketTimeout;
@property(nonatomic, strong, nullable) NSNumber * isHttps;
@property(nonatomic, copy, nullable) NSString * host;
@property(nonatomic, copy, nullable) NSString * hostFormat;
@property(nonatomic, strong, nullable) NSNumber * port;
@property(nonatomic, strong, nullable) NSNumber * isDebuggable;
@property(nonatomic, strong, nullable) NSNumber * signInUrl;
@property(nonatomic, copy, nullable) NSString * userAgent;
@property(nonatomic, strong, nullable) NSNumber * dnsCache;
@property(nonatomic, strong, nullable) NSNumber * accelerate;
@property(nonatomic, strong, nullable) NSNumber * domainSwitch;
@property(nonatomic, strong, nullable) NSDictionary<NSString *, NSString *> * customHeaders;
@property(nonatomic, strong, nullable) NSArray<NSString *> * noSignHeaders;
@end

@interface TransferConfig : NSObject
+ (instancetype)makeWithForceSimpleUpload:(nullable NSNumber *)forceSimpleUpload
    enableVerification:(nullable NSNumber *)enableVerification
    divisionForUpload:(nullable NSNumber *)divisionForUpload
    sliceSizeForUpload:(nullable NSNumber *)sliceSizeForUpload;
@property(nonatomic, strong, nullable) NSNumber * forceSimpleUpload;
@property(nonatomic, strong, nullable) NSNumber * enableVerification;
@property(nonatomic, strong, nullable) NSNumber * divisionForUpload;
@property(nonatomic, strong, nullable) NSNumber * sliceSizeForUpload;
@end

@interface STSCredentialScope : NSObject
/// `init` unavailable to enforce nonnull fields, see the `make` class method.
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)makeWithAction:(NSString *)action
    region:(NSString *)region
    bucket:(nullable NSString *)bucket
    prefix:(nullable NSString *)prefix;
@property(nonatomic, copy) NSString * action;
@property(nonatomic, copy) NSString * region;
@property(nonatomic, copy, nullable) NSString * bucket;
@property(nonatomic, copy, nullable) NSString * prefix;
@end

@interface SessionQCloudCredentials : NSObject
/// `init` unavailable to enforce nonnull fields, see the `make` class method.
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)makeWithSecretId:(NSString *)secretId
    secretKey:(NSString *)secretKey
    token:(NSString *)token
    startTime:(nullable NSNumber *)startTime
    expiredTime:(NSNumber *)expiredTime;
@property(nonatomic, copy) NSString * secretId;
@property(nonatomic, copy) NSString * secretKey;
@property(nonatomic, copy) NSString * token;
@property(nonatomic, strong, nullable) NSNumber * startTime;
@property(nonatomic, strong) NSNumber * expiredTime;
@end

@interface CosXmlResult : NSObject
+ (instancetype)makeWithETag:(nullable NSString *)eTag
    accessUrl:(nullable NSString *)accessUrl
    callbackResult:(nullable CallbackResult *)callbackResult;
@property(nonatomic, copy, nullable) NSString * eTag;
@property(nonatomic, copy, nullable) NSString * accessUrl;
@property(nonatomic, strong, nullable) CallbackResult * callbackResult;
@end

@interface CallbackResult : NSObject
/// `init` unavailable to enforce nonnull fields, see the `make` class method.
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)makeWithStatus:(NSNumber *)status
    callbackBody:(nullable NSString *)callbackBody
    error:(nullable CallbackResultError *)error;
/// Callback 是否成功。枚举值，支持 200、203。200表示上传成功、回调成功；203表示上传成功，回调失败
@property(nonatomic, strong) NSNumber * status;
/// Status为200时，说明上传成功、回调成功，返回 CallbackBody
@property(nonatomic, copy, nullable) NSString * callbackBody;
/// Status为203时，说明Callback，返回 Error，说明回调失败信息
@property(nonatomic, strong, nullable) CallbackResultError * error;
@end

@interface CallbackResultError : NSObject
+ (instancetype)makeWithCode:(nullable NSString *)code
    message:(nullable NSString *)message;
/// 回调失败信息的错误码，例如CallbackFailed
@property(nonatomic, copy, nullable) NSString * code;
/// Callback 失败的错误信息
@property(nonatomic, copy, nullable) NSString * message;
@end

@interface CosXmlClientException : NSObject
/// `init` unavailable to enforce nonnull fields, see the `make` class method.
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)makeWithErrorCode:(NSNumber *)errorCode
    message:(nullable NSString *)message
    details:(nullable NSString *)details;
@property(nonatomic, strong) NSNumber * errorCode;
@property(nonatomic, copy, nullable) NSString * message;
@property(nonatomic, copy, nullable) NSString * details;
@end

@interface CosXmlServiceException : NSObject
/// `init` unavailable to enforce nonnull fields, see the `make` class method.
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)makeWithStatusCode:(NSNumber *)statusCode
    httpMsg:(nullable NSString *)httpMsg
    requestId:(nullable NSString *)requestId
    errorCode:(nullable NSString *)errorCode
    errorMessage:(nullable NSString *)errorMessage
    serviceName:(nullable NSString *)serviceName
    details:(nullable NSString *)details;
@property(nonatomic, strong) NSNumber * statusCode;
@property(nonatomic, copy, nullable) NSString * httpMsg;
@property(nonatomic, copy, nullable) NSString * requestId;
@property(nonatomic, copy, nullable) NSString * errorCode;
@property(nonatomic, copy, nullable) NSString * errorMessage;
@property(nonatomic, copy, nullable) NSString * serviceName;
@property(nonatomic, copy, nullable) NSString * details;
@end

@interface Owner : NSObject
/// `init` unavailable to enforce nonnull fields, see the `make` class method.
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)makeWithId:(NSString *)id
    disPlayName:(nullable NSString *)disPlayName;
/// 存储桶持有者的完整 ID
@property(nonatomic, copy) NSString * id;
/// 存储桶持有者的名字
@property(nonatomic, copy, nullable) NSString * disPlayName;
@end

@interface LogEntity : NSObject
/// `init` unavailable to enforce nonnull fields, see the `make` class method.
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)makeWithTimestamp:(NSNumber *)timestamp
    level:(LogLevel)level
    category:(LogCategory)category
    tag:(NSString *)tag
    message:(NSString *)message
    threadName:(NSString *)threadName
    extras:(nullable NSDictionary<NSString *, NSString *> *)extras
    throwable:(nullable NSString *)throwable;
@property(nonatomic, strong) NSNumber * timestamp;
@property(nonatomic, assign) LogLevel level;
@property(nonatomic, assign) LogCategory category;
@property(nonatomic, copy) NSString * tag;
@property(nonatomic, copy) NSString * message;
@property(nonatomic, copy) NSString * threadName;
@property(nonatomic, strong, nullable) NSDictionary<NSString *, NSString *> * extras;
@property(nonatomic, copy, nullable) NSString * throwable;
@end

@interface Bucket : NSObject
/// `init` unavailable to enforce nonnull fields, see the `make` class method.
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)makeWithName:(NSString *)name
    location:(nullable NSString *)location
    createDate:(nullable NSString *)createDate
    type:(nullable NSString *)type;
/// 存储桶的名称
@property(nonatomic, copy) NSString * name;
/// 存储桶所在地域
@property(nonatomic, copy, nullable) NSString * location;
/// 存储桶的创建时间，为 ISO8601 格式，例如2019-05-24T10:56:40Z
@property(nonatomic, copy, nullable) NSString * createDate;
@property(nonatomic, copy, nullable) NSString * type;
@end

@interface ListAllMyBuckets : NSObject
/// `init` unavailable to enforce nonnull fields, see the `make` class method.
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)makeWithOwner:(Owner *)owner
    buckets:(NSArray<Bucket *> *)buckets;
/// 存储桶持有者信息
@property(nonatomic, strong) Owner * owner;
/// 存储桶列表
@property(nonatomic, strong) NSArray<Bucket *> * buckets;
@end

@interface CommonPrefixes : NSObject
/// `init` unavailable to enforce nonnull fields, see the `make` class method.
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)makeWithPrefix:(NSString *)prefix;
/// Common Prefix 的前缀
@property(nonatomic, copy) NSString * prefix;
@end

@interface Content : NSObject
/// `init` unavailable to enforce nonnull fields, see the `make` class method.
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)makeWithKey:(NSString *)key
    lastModified:(NSString *)lastModified
    eTag:(NSString *)eTag
    size:(NSNumber *)size
    owner:(Owner *)owner
    storageClass:(NSString *)storageClass;
/// 对象键
@property(nonatomic, copy) NSString * key;
/// 对象最后修改时间，为 ISO8601 格式，如2019-05-24T10:56:40Z
@property(nonatomic, copy) NSString * lastModified;
/// 对象的实体标签（Entity Tag），是对象被创建时标识对象内容的信息标签，可用于检查对象的内容是否发生变化，
/// 例如“8e0b617ca298a564c3331da28dcb50df”，此头部并不一定返回对象的 MD5 值，而是根据对象上传和加密方式而有所不同
@property(nonatomic, copy) NSString * eTag;
/// 对象大小，单位为 Byte
@property(nonatomic, strong) NSNumber * size;
/// 对象持有者信息
@property(nonatomic, strong) Owner * owner;
/// 对象存储类型
@property(nonatomic, copy) NSString * storageClass;
@end

@interface BucketContents : NSObject
/// `init` unavailable to enforce nonnull fields, see the `make` class method.
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)makeWithName:(NSString *)name
    encodingType:(nullable NSString *)encodingType
    prefix:(nullable NSString *)prefix
    marker:(nullable NSString *)marker
    maxKeys:(NSNumber *)maxKeys
    isTruncated:(NSNumber *)isTruncated
    nextMarker:(nullable NSString *)nextMarker
    contentsList:(NSArray<Content *> *)contentsList
    commonPrefixesList:(NSArray<CommonPrefixes *> *)commonPrefixesList
    delimiter:(nullable NSString *)delimiter;
/// 存储桶的名称，格式为<BucketName-APPID>，例如examplebucket-1250000000
@property(nonatomic, copy) NSString * name;
/// 编码格式，对应请求中的 encoding-type 参数，且仅当请求中指定了 encoding-type 参数才会返回该节点
@property(nonatomic, copy, nullable) NSString * encodingType;
/// 对象键匹配前缀，对应请求中的 prefix 参数
@property(nonatomic, copy, nullable) NSString * prefix;
/// 起始对象键标记，从该标记之后（不含）按照 UTF-8 字典序返回对象键条目，对应请求中的 marker 参数
@property(nonatomic, copy, nullable) NSString * marker;
/// 单次响应返回结果的最大条目数量，对应请求中的 max-keys 参数
/// 注意：该参数会限制每一次 List 操作返回的最大条目数，COS 在每次 List 操作中将返回不超过 max-keys 所设定数值的条目。
/// 如果由于您设置了 max-keys 参数，导致单次响应中未列出所有对象，COS 会返回一项 nextmarker 参数作为您下次 List 请求的入参，
/// 以便您后续进行列出对象
@property(nonatomic, strong) NSNumber * maxKeys;
/// 响应条目是否被截断，布尔值，例如 true 或 false
@property(nonatomic, strong) NSNumber * isTruncated;
/// 仅当响应条目有截断（IsTruncated 为 true）才会返回该节点，
/// 该节点的值为当前响应条目中的最后一个对象键，当需要继续请求后续条目时，将该节点的值作为下一次请求的 marker 参数传入
@property(nonatomic, copy, nullable) NSString * nextMarker;
/// 对象条目
@property(nonatomic, strong) NSArray<Content *> * contentsList;
/// 从 prefix 或从头（如未指定 prefix）到首个 delimiter 之间相同的部分，
/// 定义为 Common Prefix。仅当请求中指定了 delimiter 参数才有可能返回该节点
@property(nonatomic, strong) NSArray<CommonPrefixes *> * commonPrefixesList;
/// 分隔符，对应请求中的 delimiter 参数，且仅当请求中指定了 delimiter 参数才会返回该节点
@property(nonatomic, copy, nullable) NSString * delimiter;
@end

/// The codec used by CosApi.
NSObject<FlutterMessageCodec> *CosApiGetCodec(void);

@protocol CosApi
- (void)initWithPlainSecretSecretId:(NSString *)secretId secretKey:(NSString *)secretKey error:(FlutterError *_Nullable *_Nonnull)error;
- (void)initWithSessionCredentialWithError:(FlutterError *_Nullable *_Nonnull)error;
- (void)initWithScopeLimitCredentialWithError:(FlutterError *_Nullable *_Nonnull)error;
- (void)initCustomerDNSDnsMap:(NSDictionary<NSString *, NSArray<NSString *> *> *)dnsMap error:(FlutterError *_Nullable *_Nonnull)error;
- (void)initCustomerDNSFetchWithError:(FlutterError *_Nullable *_Nonnull)error;
- (void)forceInvalidationCredentialWithError:(FlutterError *_Nullable *_Nonnull)error;
- (void)setCloseBeaconIsCloseBeacon:(NSNumber *)isCloseBeacon error:(FlutterError *_Nullable *_Nonnull)error;
- (void)registerDefaultServiceConfig:(CosXmlServiceConfig *)config completion:(void(^)(NSString *_Nullable, FlutterError *_Nullable))completion;
- (void)registerDefaultTransferMangerConfig:(CosXmlServiceConfig *)config transferConfig:(nullable TransferConfig *)transferConfig completion:(void(^)(NSString *_Nullable, FlutterError *_Nullable))completion;
- (void)registerServiceKey:(NSString *)key config:(CosXmlServiceConfig *)config completion:(void(^)(NSString *_Nullable, FlutterError *_Nullable))completion;
- (void)registerTransferMangerKey:(NSString *)key config:(CosXmlServiceConfig *)config transferConfig:(nullable TransferConfig *)transferConfig completion:(void(^)(NSString *_Nullable, FlutterError *_Nullable))completion;
- (void)enableLogcatEnable:(NSNumber *)enable error:(FlutterError *_Nullable *_Nonnull)error;
- (void)enableLogFileEnable:(NSNumber *)enable error:(FlutterError *_Nullable *_Nonnull)error;
- (void)addLogListenerKey:(NSNumber *)key error:(FlutterError *_Nullable *_Nonnull)error;
- (void)removeLogListenerKey:(NSNumber *)key error:(FlutterError *_Nullable *_Nonnull)error;
- (void)setMinLevelMinLevel:(LogLevel)minLevel error:(FlutterError *_Nullable *_Nonnull)error;
- (void)setLogcatMinLevelMinLevel:(LogLevel)minLevel error:(FlutterError *_Nullable *_Nonnull)error;
- (void)setFileMinLevelMinLevel:(LogLevel)minLevel error:(FlutterError *_Nullable *_Nonnull)error;
- (void)setClsMinLevelMinLevel:(LogLevel)minLevel error:(FlutterError *_Nullable *_Nonnull)error;
- (void)setDeviceIDDeviceID:(NSString *)deviceID error:(FlutterError *_Nullable *_Nonnull)error;
- (void)setDeviceModelDeviceModel:(NSString *)deviceModel error:(FlutterError *_Nullable *_Nonnull)error;
- (void)setAppVersionAppVersion:(NSString *)appVersion error:(FlutterError *_Nullable *_Nonnull)error;
- (void)setExtrasExtras:(NSDictionary<NSString *, NSString *> *)extras error:(FlutterError *_Nullable *_Nonnull)error;
- (void)setLogFileEncryptionKeyKey:(FlutterStandardTypedData *)key iv:(FlutterStandardTypedData *)iv error:(FlutterError *_Nullable *_Nonnull)error;
/// @return `nil` only when `error != nil`.
- (nullable NSString *)getLogRootDirWithError:(FlutterError *_Nullable *_Nonnull)error;
- (void)setCLsChannelAnonymousTopicId:(NSString *)topicId endpoint:(NSString *)endpoint error:(FlutterError *_Nullable *_Nonnull)error;
- (void)setCLsChannelStaticKeyTopicId:(NSString *)topicId endpoint:(NSString *)endpoint secretId:(NSString *)secretId secretKey:(NSString *)secretKey error:(FlutterError *_Nullable *_Nonnull)error;
- (void)setCLsChannelSessionCredentialTopicId:(NSString *)topicId endpoint:(NSString *)endpoint error:(FlutterError *_Nullable *_Nonnull)error;
- (void)addSensitiveRuleRuleName:(NSString *)ruleName regex:(NSString *)regex error:(FlutterError *_Nullable *_Nonnull)error;
- (void)removeSensitiveRuleRuleName:(NSString *)ruleName error:(FlutterError *_Nullable *_Nonnull)error;
@end

extern void CosApiSetup(id<FlutterBinaryMessenger> binaryMessenger, NSObject<CosApi> *_Nullable api);

/// The codec used by CosServiceApi.
NSObject<FlutterMessageCodec> *CosServiceApiGetCodec(void);

@protocol CosServiceApi
- (void)headObjectServiceKey:(NSString *)serviceKey bucket:(NSString *)bucket region:(nullable NSString *)region cosPath:(NSString *)cosPath versionId:(nullable NSString *)versionId sessionCredentials:(nullable SessionQCloudCredentials *)sessionCredentials completion:(void(^)(NSDictionary<NSString *, NSString *> *_Nullable, FlutterError *_Nullable))completion;
- (void)deleteObjectServiceKey:(NSString *)serviceKey bucket:(NSString *)bucket region:(nullable NSString *)region cosPath:(NSString *)cosPath versionId:(nullable NSString *)versionId sessionCredentials:(nullable SessionQCloudCredentials *)sessionCredentials completion:(void(^)(FlutterError *_Nullable))completion;
/// @return `nil` only when `error != nil`.
- (nullable NSString *)getObjectUrlBucket:(NSString *)bucket region:(NSString *)region cosPath:(NSString *)cosPath serviceKey:(NSString *)serviceKey error:(FlutterError *_Nullable *_Nonnull)error;
- (void)getPresignedUrlServiceKey:(NSString *)serviceKey bucket:(NSString *)bucket cosPath:(NSString *)cosPath signValidTime:(nullable NSNumber *)signValidTime signHost:(nullable NSNumber *)signHost parameters:(nullable NSDictionary<NSString *, NSString *> *)parameters region:(nullable NSString *)region sessionCredentials:(nullable SessionQCloudCredentials *)sessionCredentials completion:(void(^)(NSString *_Nullable, FlutterError *_Nullable))completion;
- (void)preBuildConnectionBucket:(NSString *)bucket serviceKey:(NSString *)serviceKey completion:(void(^)(FlutterError *_Nullable))completion;
- (void)getServiceServiceKey:(NSString *)serviceKey sessionCredentials:(nullable SessionQCloudCredentials *)sessionCredentials completion:(void(^)(ListAllMyBuckets *_Nullable, FlutterError *_Nullable))completion;
- (void)getBucketServiceKey:(NSString *)serviceKey bucket:(NSString *)bucket region:(nullable NSString *)region prefix:(nullable NSString *)prefix delimiter:(nullable NSString *)delimiter encodingType:(nullable NSString *)encodingType marker:(nullable NSString *)marker maxKeys:(nullable NSNumber *)maxKeys sessionCredentials:(nullable SessionQCloudCredentials *)sessionCredentials completion:(void(^)(BucketContents *_Nullable, FlutterError *_Nullable))completion;
- (void)putBucketServiceKey:(NSString *)serviceKey bucket:(NSString *)bucket region:(nullable NSString *)region enableMAZ:(nullable NSNumber *)enableMAZ cosacl:(nullable NSString *)cosacl readAccount:(nullable NSString *)readAccount writeAccount:(nullable NSString *)writeAccount readWriteAccount:(nullable NSString *)readWriteAccount sessionCredentials:(nullable SessionQCloudCredentials *)sessionCredentials completion:(void(^)(FlutterError *_Nullable))completion;
- (void)headBucketServiceKey:(NSString *)serviceKey bucket:(NSString *)bucket region:(nullable NSString *)region sessionCredentials:(nullable SessionQCloudCredentials *)sessionCredentials completion:(void(^)(NSDictionary<NSString *, NSString *> *_Nullable, FlutterError *_Nullable))completion;
- (void)deleteBucketServiceKey:(NSString *)serviceKey bucket:(NSString *)bucket region:(nullable NSString *)region sessionCredentials:(nullable SessionQCloudCredentials *)sessionCredentials completion:(void(^)(FlutterError *_Nullable))completion;
- (void)getBucketAccelerateServiceKey:(NSString *)serviceKey bucket:(NSString *)bucket region:(nullable NSString *)region sessionCredentials:(nullable SessionQCloudCredentials *)sessionCredentials completion:(void(^)(NSNumber *_Nullable, FlutterError *_Nullable))completion;
- (void)putBucketAccelerateServiceKey:(NSString *)serviceKey bucket:(NSString *)bucket region:(nullable NSString *)region enable:(NSNumber *)enable sessionCredentials:(nullable SessionQCloudCredentials *)sessionCredentials completion:(void(^)(FlutterError *_Nullable))completion;
- (void)getBucketLocationServiceKey:(NSString *)serviceKey bucket:(NSString *)bucket region:(nullable NSString *)region sessionCredentials:(nullable SessionQCloudCredentials *)sessionCredentials completion:(void(^)(NSString *_Nullable, FlutterError *_Nullable))completion;
- (void)getBucketVersioningServiceKey:(NSString *)serviceKey bucket:(NSString *)bucket region:(nullable NSString *)region sessionCredentials:(nullable SessionQCloudCredentials *)sessionCredentials completion:(void(^)(NSNumber *_Nullable, FlutterError *_Nullable))completion;
- (void)putBucketVersioningServiceKey:(NSString *)serviceKey bucket:(NSString *)bucket region:(nullable NSString *)region enable:(NSNumber *)enable sessionCredentials:(nullable SessionQCloudCredentials *)sessionCredentials completion:(void(^)(FlutterError *_Nullable))completion;
- (void)doesBucketExistServiceKey:(NSString *)serviceKey bucket:(NSString *)bucket completion:(void(^)(NSNumber *_Nullable, FlutterError *_Nullable))completion;
- (void)doesObjectExistServiceKey:(NSString *)serviceKey bucket:(NSString *)bucket cosPath:(NSString *)cosPath completion:(void(^)(NSNumber *_Nullable, FlutterError *_Nullable))completion;
- (void)cancelAllServiceKey:(NSString *)serviceKey error:(FlutterError *_Nullable *_Nonnull)error;
@end

extern void CosServiceApiSetup(id<FlutterBinaryMessenger> binaryMessenger, NSObject<CosServiceApi> *_Nullable api);

/// The codec used by CosTransferApi.
NSObject<FlutterMessageCodec> *CosTransferApiGetCodec(void);

@protocol CosTransferApi
/// @return `nil` only when `error != nil`.
- (nullable NSString *)uploadTransferKey:(NSString *)transferKey bucket:(NSString *)bucket cosPath:(NSString *)cosPath region:(nullable NSString *)region filePath:(nullable NSString *)filePath byteArr:(nullable FlutterStandardTypedData *)byteArr uploadId:(nullable NSString *)uploadId stroageClass:(nullable NSString *)stroageClass trafficLimit:(nullable NSNumber *)trafficLimit callbackParam:(nullable NSString *)callbackParam customHeaders:(nullable NSDictionary<NSString *, NSString *> *)customHeaders noSignHeaders:(nullable NSArray<NSString *> *)noSignHeaders resultCallbackKey:(nullable NSNumber *)resultCallbackKey stateCallbackKey:(nullable NSNumber *)stateCallbackKey progressCallbackKey:(nullable NSNumber *)progressCallbackKey initMultipleUploadCallbackKey:(nullable NSNumber *)initMultipleUploadCallbackKey sessionCredentials:(nullable SessionQCloudCredentials *)sessionCredentials error:(FlutterError *_Nullable *_Nonnull)error;
/// @return `nil` only when `error != nil`.
- (nullable NSString *)downloadTransferKey:(NSString *)transferKey bucket:(NSString *)bucket cosPath:(NSString *)cosPath region:(nullable NSString *)region savePath:(NSString *)savePath versionId:(nullable NSString *)versionId trafficLimit:(nullable NSNumber *)trafficLimit customHeaders:(nullable NSDictionary<NSString *, NSString *> *)customHeaders noSignHeaders:(nullable NSArray<NSString *> *)noSignHeaders resultCallbackKey:(nullable NSNumber *)resultCallbackKey stateCallbackKey:(nullable NSNumber *)stateCallbackKey progressCallbackKey:(nullable NSNumber *)progressCallbackKey sessionCredentials:(nullable SessionQCloudCredentials *)sessionCredentials error:(FlutterError *_Nullable *_Nonnull)error;
- (void)pauseTaskId:(NSString *)taskId transferKey:(NSString *)transferKey error:(FlutterError *_Nullable *_Nonnull)error;
- (void)resumeTaskId:(NSString *)taskId transferKey:(NSString *)transferKey error:(FlutterError *_Nullable *_Nonnull)error;
- (void)cancelTaskId:(NSString *)taskId transferKey:(NSString *)transferKey error:(FlutterError *_Nullable *_Nonnull)error;
@end

extern void CosTransferApiSetup(id<FlutterBinaryMessenger> binaryMessenger, NSObject<CosTransferApi> *_Nullable api);

/// The codec used by FlutterCosApi.
NSObject<FlutterMessageCodec> *FlutterCosApiGetCodec(void);

@interface FlutterCosApi : NSObject
- (instancetype)initWithBinaryMessenger:(id<FlutterBinaryMessenger>)binaryMessenger;
- (void)fetchSessionCredentialsWithCompletion:(void(^)(SessionQCloudCredentials *_Nullable, NSError *_Nullable))completion;
- (void)fetchScopeLimitCredentialsStsCredentialScopes:(NSArray<STSCredentialScope *> *)stsCredentialScopes completion:(void(^)(SessionQCloudCredentials *_Nullable, NSError *_Nullable))completion;
/// 获取dns记录
/// @param domain 域名
/// @return ip集合
- (void)fetchDnsDomain:(NSString *)domain completion:(void(^)(NSArray<NSString *> *_Nullable, NSError *_Nullable))completion;
- (void)resultSuccessCallbackTransferKey:(NSString *)transferKey key:(NSNumber *)key header:(nullable NSDictionary<NSString *, NSString *> *)header result:(nullable CosXmlResult *)result completion:(void(^)(NSError *_Nullable))completion;
- (void)resultFailCallbackTransferKey:(NSString *)transferKey key:(NSNumber *)key clientException:(nullable CosXmlClientException *)clientException serviceException:(nullable CosXmlServiceException *)serviceException completion:(void(^)(NSError *_Nullable))completion;
- (void)stateCallbackTransferKey:(NSString *)transferKey key:(NSNumber *)key state:(NSString *)state completion:(void(^)(NSError *_Nullable))completion;
- (void)progressCallbackTransferKey:(NSString *)transferKey key:(NSNumber *)key complete:(NSNumber *)complete target:(NSNumber *)target completion:(void(^)(NSError *_Nullable))completion;
- (void)initMultipleUploadCallbackTransferKey:(NSString *)transferKey key:(NSNumber *)key bucket:(NSString *)bucket cosKey:(NSString *)cosKey uploadId:(NSString *)uploadId completion:(void(^)(NSError *_Nullable))completion;
- (void)onLogKey:(NSNumber *)key entity:(LogEntity *)entity completion:(void(^)(NSError *_Nullable))completion;
- (void)fetchClsSessionCredentialsWithCompletion:(void(^)(SessionQCloudCredentials *_Nullable, NSError *_Nullable))completion;
@end
NS_ASSUME_NONNULL_END
