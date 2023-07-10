#import "CosPlugin.h"
#import "pigeon.h"
#import "QCloudServiceConfiguration_Private.h"
#import "CosPluginSignatureProvider.h"
#import <QCloudCOSXML/QCloudCOSXML.h>
#import <Flutter/Flutter.h>
#import <objc/runtime.h>

static void *kQCloudDownloadRequestResultCallbackKey = &kQCloudDownloadRequestResultCallbackKey;
static void *kQCloudDownloadRequestProgressCallbackKey = &kQCloudDownloadRequestProgressCallbackKey;
static void *kQCloudDownloadRequestStateCallbackKey = &kQCloudDownloadRequestStateCallbackKey;
static void *kQCloudDownloadRequestLocalDownloaded = &kQCloudDownloadRequestLocalDownloaded;
@implementation QCloudCOSXMLDownloadObjectRequest (DownloadObjectRequestExt)

- (void)setStateCallbackKey:(NSNumber *)stateCallbackKey {
    objc_setAssociatedObject(self, kQCloudDownloadRequestStateCallbackKey, stateCallbackKey, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSNumber *)stateCallbackKey {
    return objc_getAssociatedObject(self, kQCloudDownloadRequestStateCallbackKey);
}

- (void)setResultCallbackKey:(NSNumber *)resultCallbackKey {
    objc_setAssociatedObject(self, kQCloudDownloadRequestResultCallbackKey, resultCallbackKey, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSNumber *)resultCallbackKey {
    return objc_getAssociatedObject(self, kQCloudDownloadRequestResultCallbackKey);
}

- (void)setProgressCallbackKey:(NSNumber *)progressCallbackKey {
    objc_setAssociatedObject(self, kQCloudDownloadRequestProgressCallbackKey, progressCallbackKey, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSNumber *)progressCallbackKey {
    return objc_getAssociatedObject(self, kQCloudDownloadRequestProgressCallbackKey);
}

- (void)setLocalDownloaded:(NSNumber *)localDownloaded {
    objc_setAssociatedObject(self, kQCloudDownloadRequestLocalDownloaded, localDownloaded, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSNumber *)localDownloaded {
    return objc_getAssociatedObject(self, kQCloudDownloadRequestLocalDownloaded);
}

@end

static void *kQCloudUploadRequestResultCallbackKey = &kQCloudUploadRequestResultCallbackKey;
static void *kQCloudUploadRequestProgressCallbackKey = &kQCloudUploadRequestProgressCallbackKey;
static void *kQCloudUploadRequestStateCallbackKey = &kQCloudUploadRequestStateCallbackKey;
static void *kQCloudUploadRequestIinitMultipleUploadCallbackKey = &kQCloudUploadRequestIinitMultipleUploadCallbackKey;
static void *kQCloudUploadRequestResmeData = &kQCloudUploadRequestResmeData;
@implementation QCloudCOSXMLUploadObjectRequest (UploadObjectRequestExt)

- (void)setStateCallbackKey:(NSNumber *)stateCallbackKey {
    objc_setAssociatedObject(self, kQCloudUploadRequestStateCallbackKey, stateCallbackKey, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSNumber *)stateCallbackKey {
    return objc_getAssociatedObject(self, kQCloudUploadRequestStateCallbackKey);
}

- (void)setResultCallbackKey:(NSNumber *)resultCallbackKey {
    objc_setAssociatedObject(self, kQCloudUploadRequestResultCallbackKey, resultCallbackKey, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSNumber *)resultCallbackKey {
    return objc_getAssociatedObject(self, kQCloudUploadRequestResultCallbackKey);
}

- (void)setProgressCallbackKey:(NSNumber *)progressCallbackKey {
    objc_setAssociatedObject(self, kQCloudUploadRequestProgressCallbackKey, progressCallbackKey, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSNumber *)progressCallbackKey {
    return objc_getAssociatedObject(self, kQCloudUploadRequestProgressCallbackKey);
}

- (void)setIinitMultipleUploadCallbackKey:(NSNumber *)iinitMultipleUploadCallbackKey {
    objc_setAssociatedObject(self, kQCloudUploadRequestIinitMultipleUploadCallbackKey, iinitMultipleUploadCallbackKey, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSNumber *)iinitMultipleUploadCallbackKey {
    return objc_getAssociatedObject(self, kQCloudUploadRequestIinitMultipleUploadCallbackKey);
}

- (void)setResmeData:(NSData *)resmeData {
    objc_setAssociatedObject(self, kQCloudUploadRequestResmeData, resmeData, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSData *)resmeData {
    return objc_getAssociatedObject(self, kQCloudUploadRequestResmeData);
}

@end

@interface CosPlugin ()
{
    CosPluginSignatureProvider* signatureProvider;
    NSString * permanentSecretId;
    NSString * permanentSecretKey;
    bool isScopeLimitCredential;
}
@end

@implementation CosPlugin
NSString * const QCloudCOS_DEFAULT_KEY = @"";
NSString * const QCloudCOS_BRIDGE = @"Flutter";
NSString * const QCloudCOS_UA_FLUTTER_PLUGIN = @"FlutterPlugin";

NSString * const QCloudCOS_STATE_WAITING = @"WAITING";
NSString * const QCloudCOS_STATE_IN_PROGRESS = @"IN_PROGRESS";
NSString * const QCloudCOS_STATE_PAUSED = @"PAUSED";
NSString * const QCloudCOS_STATE_RESUMED_WAITING = @"RESUMED_WAITING";
NSString * const QCloudCOS_STATE_COMPLETED = @"COMPLETED";
NSString * const QCloudCOS_STATE_FAILED = @"FAILED";
NSString * const QCloudCOS_STATE_CANCELED = @"CANCELED";

FlutterCosApi* flutterCosApi;

QCloudThreadSafeMutableDictionary *QCloudCOSTransferConfigCache() {
    static QCloudThreadSafeMutableDictionary *CloudCOSTransferConfig = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        CloudCOSTransferConfig = [QCloudThreadSafeMutableDictionary new];
    });
    return CloudCOSTransferConfig;
}

QCloudThreadSafeMutableDictionary *QCloudCOSTaskCache() {
    static QCloudThreadSafeMutableDictionary *CloudCOSTask = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        CloudCOSTask = [QCloudThreadSafeMutableDictionary new];
    });
    return CloudCOSTask;
}


+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    CosPlugin * cosPlugin = [CosPlugin new];
    CosApiSetup([registrar messenger], cosPlugin);
    CosServiceApiSetup([registrar messenger], cosPlugin);
    CosTransferApiSetup([registrar messenger], cosPlugin);
    flutterCosApi = [[FlutterCosApi new] initWithBinaryMessenger:[registrar messenger]];
}

-(nonnull QCloudServiceConfiguration *)buildConfiguration:(nonnull CosXmlServiceConfig *)config{
    QCloudServiceConfiguration* configuration = [QCloudServiceConfiguration new];
    configuration.bridge = QCloudCOS_BRIDGE;
    QCloudCOSXMLEndPoint* endpoint;
    if(config.host){
        endpoint = [[QCloudCOSXMLEndPoint alloc] initWithLiteralURL:[NSURL URLWithString:config.host]];
    } else {
        endpoint = [[QCloudCOSXMLEndPoint alloc] init];
    }
    if(config.region){
        endpoint.regionName = config.region;
    }
    if(config.connectionTimeout){
        configuration.timeoutInterval = [config.connectionTimeout doubleValue]/1000;
    }
    if(config.userAgent && ![config.userAgent isEqualToString:@""]){
        configuration.userAgentProductKey = config.userAgent;
    } else {
        configuration.userAgentProductKey = QCloudCOS_UA_FLUTTER_PLUGIN;
    }
    if(config.isHttps){
        endpoint.useHTTPS = config.isHttps;
    }
    if(config.accelerate && [config.accelerate boolValue]){
        endpoint.suffix = @"cos.accelerate.myqcloud.com";
    }
    // todo iOS不支持：HostFormat、SocketTimeout、port、IsDebuggable、SignInUrl、DnsCache、
    configuration.endpoint = endpoint;
    configuration.signatureProvider = signatureProvider;
    return configuration;
}

-(QCloudCOSXMLService *)getQCloudCOSXMLService:(nonnull NSString *)key {
    if([QCloudCOS_DEFAULT_KEY isEqual:key]){
        return [QCloudCOSXMLService defaultCOSXML];
    } else {
        return [QCloudCOSXMLService cosxmlServiceForKey:key];
    }
}

-(QCloudCOSTransferMangerService *)getQCloudCOSTransferMangerService:(nonnull NSString *)key {
    if([QCloudCOS_DEFAULT_KEY isEqual:key]){
        return [QCloudCOSTransferMangerService defaultCOSTransferManager];
    } else {
        return [QCloudCOSTransferMangerService costransfermangerServiceForKey:key];
    }
}

- (void)initWithPlainSecretSecretId:(NSString *)secretId secretKey:(NSString *)secretKey error:(FlutterError *_Nullable *_Nonnull)error{
    permanentSecretId = secretId;
    permanentSecretKey = secretKey;
    signatureProvider = [CosPluginSignatureProvider makeWithFlutterCosApi:flutterCosApi secretId:permanentSecretId secretKey:permanentSecretKey isScopeLimitCredential:isScopeLimitCredential];
}
- (void)initWithSessionCredentialWithError:(FlutterError *_Nullable *_Nonnull)error{
    isScopeLimitCredential = false;
    signatureProvider = [CosPluginSignatureProvider makeWithFlutterCosApi:flutterCosApi secretId:permanentSecretId secretKey:permanentSecretKey isScopeLimitCredential:isScopeLimitCredential];
}

- (void)initWithScopeLimitCredentialWithError:(FlutterError *_Nullable *_Nonnull)error{
    isScopeLimitCredential = true;
    signatureProvider = [CosPluginSignatureProvider makeWithFlutterCosApi:flutterCosApi secretId:permanentSecretId secretKey:permanentSecretKey isScopeLimitCredential:isScopeLimitCredential];
}

- (void)forceInvalidationCredentialWithError:(FlutterError *_Nullable *_Nonnull)error{
    if(signatureProvider){
        [signatureProvider forceInvalidationCredential];
    }
}

- (void)registerDefaultServiceConfig:(CosXmlServiceConfig *)config completion:(void(^)(NSString *_Nullable, FlutterError *_Nullable))completion{
    [QCloudCOSXMLService registerDefaultCOSXMLWithConfiguration: [self buildConfiguration: config]];
    completion(QCloudCOS_DEFAULT_KEY, nil);
}

- (void)registerDefaultTransferMangerConfig:(CosXmlServiceConfig *)config transferConfig:(nullable TransferConfig *)transferConfig completion:(void(^)(NSString *_Nullable, FlutterError *_Nullable))completion{
    [QCloudCOSTransferMangerService registerDefaultCOSTransferMangerWithConfiguration: [self buildConfiguration: config]];
    if(transferConfig){
        [QCloudCOSTransferConfigCache() setObject:transferConfig forKey:QCloudCOS_DEFAULT_KEY];
    }
    completion(QCloudCOS_DEFAULT_KEY, nil);
}

- (void)registerServiceKey:(NSString *)key config:(CosXmlServiceConfig *)config completion:(void(^)(NSString *_Nullable, FlutterError *_Nullable))completion{
    [QCloudCOSXMLService registerCOSXMLWithConfiguration: [self buildConfiguration: config] withKey: key];
    completion(key, nil);
}

- (void)registerTransferMangerKey:(NSString *)key config:(CosXmlServiceConfig *)config transferConfig:(nullable TransferConfig *)transferConfig completion:(void(^)(NSString *_Nullable, FlutterError *_Nullable))completion{
    [QCloudCOSTransferMangerService registerCOSTransferMangerWithConfiguration: [self buildConfiguration: config] withKey: key];
    if(transferConfig){
        [QCloudCOSTransferConfigCache() setObject:transferConfig forKey:key];
    }
    completion(key, nil);
}

- (void)setCloseBeaconIsCloseBeacon:(nonnull NSNumber *)isCloseBeacon error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    //iOS不支持关闭灯塔
    NSLog(@"iOS does not support");
}

- (void)cancelAllServiceKey:(nonnull NSString *)serviceKey error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    if([QCloudCOSXMLService hasCosxmlServiceForKey:serviceKey]){
        QCloudCOSXMLService * service = [self getQCloudCOSXMLService:serviceKey];
        [[service sessionManager] cancelAllRequest];
    }
    
    if([QCloudCOSTransferMangerService hasTransferMangerServiceForKey:serviceKey]){
        QCloudCOSTransferMangerService * transferManger = [self getQCloudCOSTransferMangerService:serviceKey];
        [[transferManger sessionManager] cancelAllRequest];
    }
}

- (void)deleteBucketServiceKey:(nonnull NSString *)serviceKey bucket:(nonnull NSString *)bucket region:(nullable NSString *)region completion:(nonnull void (^)(FlutterError * _Nullable))completion {
    QCloudCOSXMLService * service = [self getQCloudCOSXMLService:serviceKey];
    QCloudDeleteBucketRequest* request = [[QCloudDeleteBucketRequest alloc ] init];
    request.bucket = bucket;
    if(region){
        request.regionName = region;
    }
    [request setFinishBlock:^(id outputObject,NSError*error) {
        if(outputObject){
            completion(nil);
        } else {
            completion([self buildFlutterError:error]);
        }
    }];
    [service DeleteBucket:request];
}

- (void)deleteObjectServiceKey:(nonnull NSString *)serviceKey bucket:(nonnull NSString *)bucket region:(nullable NSString *)region cosPath:(nonnull NSString *)cosPath versionId:(nullable NSString *)versionId completion:(nonnull void (^)(FlutterError * _Nullable))completion {
    QCloudCOSXMLService * service = [self getQCloudCOSXMLService:serviceKey];
    QCloudDeleteObjectRequest* request = [[QCloudDeleteObjectRequest alloc ] init];
    request.bucket = bucket;
    request.object = cosPath;
    if(region){
        request.regionName = region;
    }
    if(versionId){
        request.versionID = versionId;
    }
    [request setFinishBlock:^(id outputObject,NSError*error) {
        if(outputObject){
            completion(nil);
        } else {
            completion([self buildFlutterError:error]);
        }
    }];
    [service DeleteObject:request];
}

- (void)doesBucketExistServiceKey:(nonnull NSString *)serviceKey bucket:(nonnull NSString *)bucket completion:(nonnull void (^)(NSNumber * _Nullable, FlutterError * _Nullable))completion {
    QCloudCOSXMLService * service = [self getQCloudCOSXMLService:serviceKey];
    completion([NSNumber numberWithBool:[service doesBucketExist:bucket]], nil);
}

- (void)doesObjectExistServiceKey:(nonnull NSString *)serviceKey bucket:(nonnull NSString *)bucket cosPath:(nonnull NSString *)cosPath completion:(nonnull void (^)(NSNumber * _Nullable, FlutterError * _Nullable))completion {
    QCloudCOSXMLService * service = [self getQCloudCOSXMLService:serviceKey];
    completion([NSNumber numberWithBool:[service doesObjectExistWithBucket:bucket object:cosPath]], nil);
}

- (void)getBucketAccelerateServiceKey:(nonnull NSString *)serviceKey bucket:(nonnull NSString *)bucket region:(nullable NSString *)region completion:(nonnull void (^)(NSNumber * _Nullable, FlutterError * _Nullable))completion {
    QCloudCOSXMLService * service = [self getQCloudCOSXMLService:serviceKey];
    QCloudGetBucketAccelerateRequest* request = [[QCloudGetBucketAccelerateRequest alloc ] init];
    request.bucket = bucket;
    if(region){
        request.regionName = region;
    }
    [request setFinishBlock:^(id outputObject,NSError*error) {
        if(outputObject){
            bool b = [outputObject status] == QCloudCOSBucketAccelerateStatusEnabled;
            completion([NSNumber numberWithBool:b], nil);
        } else {
            completion(nil, [self buildFlutterError:error]);
        }
    }];
    [service GetBucketAccelerate:request];
}

- (void)getBucketLocationServiceKey:(nonnull NSString *)serviceKey bucket:(nonnull NSString *)bucket region:(nullable NSString *)region completion:(nonnull void (^)(NSString * _Nullable, FlutterError * _Nullable))completion {
    QCloudCOSXMLService * service = [self getQCloudCOSXMLService:serviceKey];
    QCloudGetBucketLocationRequest* request = [[QCloudGetBucketLocationRequest alloc ] init];
    request.bucket = bucket;
    if(region){
        request.regionName = region;
    }
    [request setFinishBlock:^(id outputObject,NSError*error) {
        if(outputObject){
            completion([outputObject locationConstraint], nil);
        } else {
            completion(nil, [self buildFlutterError:error]);
        }
    }];
    [service GetBucketLocation:request];
}

- (void)getBucketServiceKey:(nonnull NSString *)serviceKey bucket:(nonnull NSString *)bucket region:(nullable NSString *)region prefix:(nullable NSString *)prefix delimiter:(nullable NSString *)delimiter encodingType:(nullable NSString *)encodingType marker:(nullable NSString *)marker maxKeys:(nullable NSNumber *)maxKeys completion:(nonnull void (^)(BucketContents * _Nullable, FlutterError * _Nullable))completion {
    QCloudCOSXMLService * service = [self getQCloudCOSXMLService:serviceKey];
    QCloudGetBucketRequest* request = [[QCloudGetBucketRequest alloc ] init];
    request.bucket = bucket;
    if(region){
        request.regionName = region;
    }
    if(prefix){
        request.prefix = prefix;
    }
    if(delimiter){
        request.delimiter = delimiter;
    }
    if(encodingType){
        request.encodingType = encodingType;
    }
    if(marker){
        request.marker = marker;
    }
    if(maxKeys){
        request.maxKeys = [maxKeys intValue];
    }
    [request setFinishBlock:^(QCloudListBucketResult * result, NSError* error) {
        if(error == nil){
            NSMutableArray<Content *> *contents = [NSMutableArray array];
            if(result.contents != nil && [result.contents count]>0){
                for(QCloudBucketContents *content in result.contents) {
                    [contents addObject:[Content makeWithKey:[content key] lastModified:[content lastModified] eTag:[content eTag] size:[NSNumber numberWithInteger:[content size]]
                                                       owner:[Owner makeWithId:[[content owner] identifier] disPlayName:[[content owner] displayName]]
                                                storageClass:QCloudCOSStorageClassTransferToString([content storageClass])]];
                }
            }
            NSMutableArray<CommonPrefixes *> *commonPrefixes = [NSMutableArray array];
            if(result.commonPrefixes != nil && [result.commonPrefixes count]>0){
                for(QCloudCommonPrefixes *commonPrefixe in result.commonPrefixes) {
                    [commonPrefixes addObject:[CommonPrefixes makeWithPrefix:[commonPrefixe prefix]]];
                }
            }
            BucketContents *bucketContents = [BucketContents makeWithName:[result name] encodingType:encodingType prefix:[result prefix] marker:[result marker] maxKeys:[NSNumber numberWithInt:[result maxKeys]] isTruncated:[NSNumber numberWithBool:[result isTruncated]] nextMarker:[result nextMarker] contentsList:contents commonPrefixesList:commonPrefixes delimiter:[result delimiter]];
            completion(bucketContents, nil);
        } else {
            completion(nil, [self buildFlutterError:error]);
        }
    }];
    [service GetBucket:request];
}

- (void)getBucketVersioningServiceKey:(nonnull NSString *)serviceKey bucket:(nonnull NSString *)bucket region:(nullable NSString *)region completion:(nonnull void (^)(NSNumber * _Nullable, FlutterError * _Nullable))completion {
    QCloudCOSXMLService * service = [self getQCloudCOSXMLService:serviceKey];
    QCloudGetBucketVersioningRequest* request = [[QCloudGetBucketVersioningRequest alloc ] init];
    request.bucket = bucket;
    if(region){
        request.regionName = region;
    }
    [request setFinishBlock:^(id outputObject,NSError*error) {
        if(outputObject){
            bool b = [outputObject status] == QCloudCOSBucketVersioningStatusEnabled;
            completion([NSNumber numberWithBool:b], nil);
        } else {
            completion(nil, [self buildFlutterError:error]);
        }
    }];
    [service GetBucketVersioning:request];
}

- (nullable NSString *)getObjectUrlBucket:(nonnull NSString *)bucket region:(nonnull NSString *)region cosPath:(nonnull NSString *)cosPath serviceKey:(nonnull NSString *)serviceKey error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    QCloudCOSXMLService * service = [self getQCloudCOSXMLService:serviceKey];
    return [service getURLWithBucket:bucket object:cosPath withAuthorization:false regionName:region];
}

- (void)getPresignedUrlServiceKey:(nonnull NSString *)serviceKey bucket:(nonnull NSString *)bucket cosPath:(nonnull NSString *)cosPath signValidTime:(nullable NSNumber *)signValidTime signHost:(nullable NSNumber *)signHost parameters:(nullable NSDictionary<NSString *,NSString *> *)parameters region:(nullable NSString *)region completion:(nonnull void (^)(NSString * _Nullable, FlutterError * _Nullable))completion {
    QCloudCOSXMLService * service = [self getQCloudCOSXMLService:serviceKey];
    QCloudGetPresignedURLRequest* getPresignedURLRequest = [[QCloudGetPresignedURLRequest alloc] init];

    // 存储桶名称，由BucketName-Appid 组成，可以在COS控制台查看 https://console.cloud.tencent.com/cos5/bucket
    getPresignedURLRequest.bucket = bucket;
    // 对象键，是对象在 COS 上的完整路径，如果带目录的话，格式为 "video/xxx/movie.mp4"
    getPresignedURLRequest.object = cosPath;
    getPresignedURLRequest.HTTPMethod = @"GET";

    if(signValidTime){
        getPresignedURLRequest.expires = [NSDate dateWithTimeIntervalSinceNow:[signValidTime intValue]];
    }
    
    if(signHost){
        // 获取预签名函数，默认签入Header Host；您也可以选择不签入Header Host，但可能导致请求失败或安全漏洞
        getPresignedURLRequest.signHost = [signHost boolValue];
    }
    
    if(parameters){
        // http 请求参数，传入的请求参数需与实际请求相同，能够防止用户篡改此HTTP请求的参数
        for (NSString *parametersKey in parameters) {
            [getPresignedURLRequest setValue:[parameters objectForKey:parametersKey] forRequestParameter:parametersKey];
        }
    }

    if(region){
        getPresignedURLRequest.regionName = region;
    }

    [getPresignedURLRequest setFinishBlock:^(QCloudGetPresignedURLResult * _Nonnull result,
                                             NSError * _Nonnull error) {
        if(error == nil){
            // 预签名 URL
            completion(result.presienedURL, nil);
        } else {
            completion(nil, [self buildFlutterError:error]);
        }
    }];

    [service getPresignedURL:getPresignedURLRequest];
}

- (void)getServiceServiceKey:(nonnull NSString *)serviceKey completion:(nonnull void (^)(ListAllMyBuckets * _Nullable, FlutterError * _Nullable))completion {
    QCloudCOSXMLService * service = [self getQCloudCOSXMLService:serviceKey];
    QCloudGetServiceRequest* request = [[QCloudGetServiceRequest alloc ] init];
    [request setFinishBlock:^(QCloudListAllMyBucketsResult* result, NSError* error) {
        if(error == nil){
            NSMutableArray<Bucket *> *buckets = [NSMutableArray array];
            if(result.buckets != nil && [result.buckets count]>0){
                for(QCloudBucket *bucket in result.buckets) {
                    [buckets addObject:[Bucket makeWithName:[bucket name] location:[bucket location] createDate:[bucket createDate] type:[bucket type]]];
                }
            }
            ListAllMyBuckets *listAllMyBuckets = [ListAllMyBuckets makeWithOwner:[Owner makeWithId:[[result owner] identifier] disPlayName:[[result owner] displayName]]
                                                                         buckets:buckets];
            completion(listAllMyBuckets, nil);
        } else {
            completion(nil, [self buildFlutterError:error]);
        }
    }];
    [service GetService:request];
}

- (void)headBucketServiceKey:(nonnull NSString *)serviceKey bucket:(nonnull NSString *)bucket region:(nullable NSString *)region completion:(nonnull void (^)(NSDictionary<NSString *, NSString *> * _Nullable, FlutterError * _Nullable))completion {
    QCloudCOSXMLService * service = [self getQCloudCOSXMLService:serviceKey];
    QCloudHeadBucketRequest* request = [[QCloudHeadBucketRequest alloc ] init];
    request.bucket = bucket;
    if(region){
        request.regionName = region;
    }
    [request setFinishBlock:^(id outputObject,NSError*error) {
        if(outputObject){
            NSDictionary* headerAll = [[outputObject __originHTTPURLResponse__] allHeaderFields];
            NSMutableDictionary* resultDictionary = [NSMutableDictionary new];
            for (NSString *key in headerAll) {
                [resultDictionary setObject:[headerAll objectForKey:key] forKey:[key lowercaseString]];
            }
            completion(resultDictionary, nil);
        } else {
            completion(nil, [self buildFlutterError:error]);
        }
    }];
    [service HeadBucket:request];
}

- (void)headObjectServiceKey:(nonnull NSString *)serviceKey bucket:(nonnull NSString *)bucket region:(nullable NSString *)region cosPath:(nonnull NSString *)cosPath versionId:(nullable NSString *)versionId completion:(nonnull void (^)(NSDictionary<NSString *, NSString *> * _Nullable, FlutterError * _Nullable))completion {
    QCloudCOSXMLService * service = [self getQCloudCOSXMLService:serviceKey];
    QCloudHeadObjectRequest* request = [[QCloudHeadObjectRequest alloc ] init];
    request.bucket = bucket;
    request.object = cosPath;
    if(region){
        request.regionName = region;
    }
    if(versionId){
        request.versionID = versionId;
    }
    [request setFinishBlock:^(id outputObject,NSError*error) {
        if(outputObject){
            NSDictionary* headerAll = [[outputObject __originHTTPURLResponse__] allHeaderFields];
            NSMutableDictionary* resultDictionary = [NSMutableDictionary new];
            for (NSString *key in headerAll) {
                [resultDictionary setObject:[headerAll objectForKey:key] forKey:[key lowercaseString]];
            }
            completion(resultDictionary, nil);
        } else {
            completion(nil, [self buildFlutterError:error]);
        }
    }];
    [service HeadObject:request];
}

- (void)preBuildConnectionBucket:(nonnull NSString *)bucket serviceKey:(nonnull NSString *)serviceKey completion:(void(^)(FlutterError *_Nullable))completion {
    //iOS不支持预连接
    NSLog(@"iOS does not support");
    completion(nil);
}

- (void)putBucketAccelerateServiceKey:(nonnull NSString *)serviceKey bucket:(nonnull NSString *)bucket region:(nullable NSString *)region enable:(nonnull NSNumber *)enable completion:(nonnull void (^)(FlutterError * _Nullable))completion {
    QCloudCOSXMLService * service = [self getQCloudCOSXMLService:serviceKey];
    QCloudPutBucketAccelerateRequest* request = [[QCloudPutBucketAccelerateRequest alloc ] init];
    request.bucket = bucket;
    if(region){
        request.regionName = region;
    }
    QCloudBucketAccelerateConfiguration* configuration = [[QCloudBucketAccelerateConfiguration alloc ] init];
    BOOL enableB = [enable boolValue];
    if(enableB){
        configuration.status = QCloudCOSBucketAccelerateStatusEnabled;
    } else {
        configuration.status = QCloudCOSBucketAccelerateStatusSuspended;
    }
    request.configuration = configuration;
    [request setFinishBlock:^(id outputObject,NSError*error) {
        if(outputObject){
            completion(nil);
        } else {
            completion([self buildFlutterError:error]);
        }
    }];
    [service PutBucketAccelerate:request];
}

- (void)putBucketServiceKey:(nonnull NSString *)serviceKey bucket:(nonnull NSString *)bucket region:(nullable NSString *)region enableMAZ:(nullable NSNumber *)enableMAZ cosacl:(nullable NSString *)cosacl readAccount:(nullable NSString *)readAccount writeAccount:(nullable NSString *)writeAccount readWriteAccount:(nullable NSString *)readWriteAccount completion:(nonnull void (^)(FlutterError * _Nullable))completion {
    QCloudCOSXMLService * service = [self getQCloudCOSXMLService:serviceKey];
    QCloudPutBucketRequest* request = [[QCloudPutBucketRequest alloc ] init];
    request.bucket = bucket;
    if(region){
        request.regionName = region;
    }
    if(cosacl){
        request.accessControlList = cosacl;
    }
    if(readAccount){
        request.grantRead = readAccount;
    }
    if(writeAccount){
        request.grantWrite =writeAccount;
    }
    if(readWriteAccount){
        request.grantFullControl = readWriteAccount;
    }
    BOOL enableMAZB = [enableMAZ boolValue];
    if(enableMAZB){
        QCloudCreateBucketConfiguration* configuration = [[QCloudCreateBucketConfiguration alloc ] init];
        configuration.bucketAZConfig = @"MAZ";
        request.createBucketConfiguration = configuration;
    }
    
    [request setFinishBlock:^(id outputObject,NSError*error) {
        if(outputObject){
            completion(nil);
        } else {
            completion([self buildFlutterError:error]);
        }
    }];
    [service PutBucket:request];
}

- (void)putBucketVersioningServiceKey:(nonnull NSString *)serviceKey bucket:(nonnull NSString *)bucket region:(nullable NSString *)region enable:(nonnull NSNumber *)enable completion:(nonnull void (^)(FlutterError * _Nullable))completion {
    QCloudCOSXMLService * service = [self getQCloudCOSXMLService:serviceKey];
    QCloudPutBucketVersioningRequest* request = [[QCloudPutBucketVersioningRequest alloc ] init];
    request.bucket = bucket;
    if(region){
        request.regionName = region;
    }
    QCloudBucketVersioningConfiguration* configuration = [[QCloudBucketVersioningConfiguration alloc ] init];
    BOOL enableB = [enable boolValue];
    if(enableB){
        configuration.status = QCloudCOSBucketVersioningStatusEnabled;
    } else {
        configuration.status = QCloudCOSBucketVersioningStatusSuspended;
    }
    request.configuration = configuration;
    [request setFinishBlock:^(id outputObject,NSError*error) {
        if(outputObject){
            completion(nil);
        } else {
            completion([self buildFlutterError:error]);
        }
    }];
    [service PutBucketVersioning:request];
}


- (nullable NSString *)downloadTransferKey:(nonnull NSString *)transferKey bucket:(nonnull NSString *)bucket cosPath:(nonnull NSString *)cosPath region:(nullable NSString *)region savePath:(nonnull NSString *)savePath versionId:(nullable NSString *)versionId trafficLimit:(nullable NSNumber *)trafficLimit resultCallbackKey:(nullable NSNumber *)resultCallbackKey stateCallbackKey:(nullable NSNumber *)stateCallbackKey progressCallbackKey:(nullable NSNumber *)progressCallbackKey error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    return [self downloadInternalTransferKey:transferKey
                                      bucket:bucket
                                     cosPath:cosPath
                                      region:region
                                    savePath:savePath
                                   versionId:versionId
                                trafficLimit:trafficLimit
                           resultCallbackKey:resultCallbackKey
                            stateCallbackKey:stateCallbackKey
                         progressCallbackKey:progressCallbackKey
                                     taskKey:nil
                                       error:error];
}

- (nullable NSString *)downloadInternalTransferKey:(nonnull NSString *)transferKey bucket:(nonnull NSString *)bucket cosPath:(nonnull NSString *)cosPath region:(nullable NSString *)region savePath:(nonnull NSString *)savePath versionId:(nullable NSString *)versionId trafficLimit:(nullable NSNumber *)trafficLimit resultCallbackKey:(nullable NSNumber *)resultCallbackKey stateCallbackKey:(nullable NSNumber *)stateCallbackKey progressCallbackKey:(nullable NSNumber *)progressCallbackKey taskKey:(nullable NSString *)taskKey error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    QCloudCOSTransferMangerService * transferManger = [self getQCloudCOSTransferMangerService:transferKey];
    QCloudCOSXMLDownloadObjectRequest *getObjectRequest = [[QCloudCOSXMLDownloadObjectRequest alloc] init];
    //支持断点下载
    getObjectRequest.resumableDownload = true;
    getObjectRequest.bucket = bucket;
    getObjectRequest.object = cosPath;
    getObjectRequest.downloadingURL = [NSURL fileURLWithPath:savePath];
    if(region){
        getObjectRequest.regionName = region;
    }
    if(versionId){
        getObjectRequest.versionID = versionId;
    }
    if(trafficLimit){
        getObjectRequest.trafficLimit = [trafficLimit integerValue];
    }
    
    long long saveFileSize = [self fileSizeAtPath:savePath];
    getObjectRequest.localDownloaded = [NSNumber numberWithLongLong:saveFileSize];
    
    getObjectRequest.resultCallbackKey = resultCallbackKey;
    getObjectRequest.progressCallbackKey = progressCallbackKey;
    getObjectRequest.stateCallbackKey = stateCallbackKey;
    
    if(taskKey == nil){
        taskKey = [NSString stringWithFormat: @"download-%@", [NSNumber numberWithUnsignedInteger:[getObjectRequest hash]]];
    }
    // 监听下载结果
    [getObjectRequest setFinishBlock:^(id outputObject, NSError *error) {
        if(error != nil && [error code] == QCloudNetworkErrorCodeCanceled){
            return;
        }
        
        if(error == nil){
            [self stateCallback:transferKey stateCallbackKey:stateCallbackKey state:QCloudCOS_STATE_COMPLETED];
        } else {
            [self stateCallback:transferKey stateCallbackKey:stateCallbackKey state:QCloudCOS_STATE_FAILED];
        }
        
        if(resultCallbackKey){
            if(error == nil){
                NSDictionary* headerAll = [[outputObject __originHTTPURLResponse__] allHeaderFields];
                NSMutableDictionary* resultDictionary = [NSMutableDictionary new];
                for (NSString *key in headerAll) {
                    [resultDictionary setObject:[headerAll objectForKey:key] forKey:[key lowercaseString]];
                }

                [flutterCosApi resultSuccessCallbackTransferKey:transferKey
                                                            key:resultCallbackKey
                                                         header:resultDictionary
                                                     completion:^(NSError * _Nullable error) {}
                ];
            } else {
                [flutterCosApi resultFailCallbackTransferKey:transferKey
                                                         key:resultCallbackKey
                                             clientException:[self buildClientException:error]
                                            serviceException:[self buildServiceException:error]
                                                  completion:^(NSError * _Nullable error) {}
                ];
                
            }
        }
        [QCloudCOSTaskCache() removeObject:taskKey];
    }];
    
    // 监听下载进度
    [getObjectRequest setDownProcessBlock:^(int64_t bytesDownload,
                                            int64_t totalBytesDownload,
                                            int64_t totalBytesExpectedToDownload) {
        [self stateCallback:transferKey stateCallbackKey:stateCallbackKey state:QCloudCOS_STATE_IN_PROGRESS];
        if(progressCallbackKey){
            [flutterCosApi progressCallbackTransferKey:transferKey
                                                   key:progressCallbackKey
                                              complete:[NSNumber numberWithLongLong:((long long)totalBytesDownload + [getObjectRequest.localDownloaded longLongValue])]
                                                target:[NSNumber numberWithLongLong:((long long)totalBytesExpectedToDownload + [getObjectRequest.localDownloaded longLongValue])]
                                            completion:^(NSError *_Nullable error) {}
            ];
        }
    }];
    
    [transferManger DownloadObject:getObjectRequest];
    [self stateCallback:transferKey stateCallbackKey:stateCallbackKey state:QCloudCOS_STATE_WAITING];
    
    [QCloudCOSTaskCache() setObject:getObjectRequest forKey:taskKey];
    return taskKey;
}

- (void)pauseTaskId:(nonnull NSString *)taskId transferKey:(nonnull NSString *)transferKey error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    if([taskId hasPrefix:@"upload-"]){
        QCloudCOSXMLUploadObjectRequest* put = [QCloudCOSTaskCache() objectForKey:taskId];
        if(put == nil) {
            NSLog(@"%@ request canceled or ended", taskId);
            return;
        }
        NSError *error;
        put.resmeData = [put cancelByProductingResumeData:&error];
        [self stateCallback:transferKey stateCallbackKey:[put stateCallbackKey] state:QCloudCOS_STATE_PAUSED];
    } else if ([taskId hasPrefix:@"download-"]){
        QCloudCOSXMLDownloadObjectRequest* request = [QCloudCOSTaskCache() objectForKey:taskId];
        if(request == nil) {
            NSLog(@"%@ request canceled or ended", taskId);
            return;
        }
        [request cancel];
        [self stateCallback:transferKey stateCallbackKey:[request stateCallbackKey] state:QCloudCOS_STATE_PAUSED];
    }
}

- (void)resumeTaskId:(nonnull NSString *)taskId transferKey:(nonnull NSString *)transferKey error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    if([taskId hasPrefix:@"upload-"]){
        QCloudCOSXMLUploadObjectRequest* put = [QCloudCOSTaskCache() objectForKey:taskId];
        if(put == nil) {
            NSLog(@"%@ request canceled or ended", taskId);
            return;
        }
        [self uploadInternalTransferKey:transferKey
                              resmeData:[put resmeData]
                         bucket:[put bucket]
                        cosPath:[put object]
                         region:[put regionName]
                       filePath:nil
                        byteArr:nil
                       uploadId:[put valueForKey:@"uploadId"]
                   stroageClass:QCloudCOSStorageClassTransferToString([put storageClass])
                   trafficLimit:[NSNumber numberWithInteger:[put trafficLimit]]
              resultCallbackKey:[put resultCallbackKey]
               stateCallbackKey:[put stateCallbackKey]
            progressCallbackKey:[put progressCallbackKey]
  initMultipleUploadCallbackKey:[put iinitMultipleUploadCallbackKey]
                        taskKey:taskId
                          error:error];
        [self stateCallback:transferKey stateCallbackKey:[put stateCallbackKey] state:QCloudCOS_STATE_RESUMED_WAITING];
    } else if ([taskId hasPrefix:@"download-"]){
        QCloudCOSXMLDownloadObjectRequest* request = [QCloudCOSTaskCache() objectForKey:taskId];
        if(request == nil) {
            NSLog(@"%@ request canceled or ended", taskId);
            return;
        }
        [self downloadInternalTransferKey:transferKey
                           bucket:[request bucket]
                          cosPath:[request object]
                           region:[request regionName]
                         savePath:[[[request downloadingURL] filePathURL] path]
                        versionId:[request versionID]
                     trafficLimit:[NSNumber numberWithInteger:[request trafficLimit]]
                resultCallbackKey:[request resultCallbackKey]
                 stateCallbackKey:[request stateCallbackKey]
              progressCallbackKey:[request progressCallbackKey]
                          taskKey:taskId
                            error:error];
        [self stateCallback:transferKey stateCallbackKey:[request stateCallbackKey] state:QCloudCOS_STATE_RESUMED_WAITING];
    }
}


- (void)cancelTaskId:(nonnull NSString *)taskId transferKey:(nonnull NSString *)transferKey error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    if([taskId hasPrefix:@"upload-"]){
        QCloudCOSXMLUploadObjectRequest* put = [QCloudCOSTaskCache() objectForKey:taskId];
        if(put == nil) {
            NSLog(@"%@ request canceled or ended", taskId);
            return;
        }
        [put abort:^(id outputObject, NSError *error) {}];
        [self stateCallback:transferKey stateCallbackKey:[put stateCallbackKey] state:QCloudCOS_STATE_CANCELED];
    } else if ([taskId hasPrefix:@"download-"]){
        QCloudCOSXMLDownloadObjectRequest* request = [QCloudCOSTaskCache() objectForKey:taskId];
        if(request == nil) {
            NSLog(@"%@ request canceled or ended", taskId);
            return;
        }
        [request cancel];
        [self stateCallback:transferKey stateCallbackKey:[request stateCallbackKey] state:QCloudCOS_STATE_CANCELED];
    }
    [QCloudCOSTaskCache() removeObject:taskId];
}

- (nullable NSString *)uploadTransferKey:(nonnull NSString *)transferKey bucket:(nonnull NSString *)bucket cosPath:(nonnull NSString *)cosPath region:(nullable NSString *)region filePath:(nullable NSString *)filePath byteArr:(nullable FlutterStandardTypedData *)byteArr uploadId:(nullable NSString *)uploadId stroageClass:(nullable NSString *)stroageClass trafficLimit:(nullable NSNumber *)trafficLimit resultCallbackKey:(nullable NSNumber *)resultCallbackKey stateCallbackKey:(nullable NSNumber *)stateCallbackKey progressCallbackKey:(nullable NSNumber *)progressCallbackKey initMultipleUploadCallbackKey:(nullable NSNumber *)initMultipleUploadCallbackKey error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    return [self uploadInternalTransferKey:transferKey
                                 resmeData:nil
                                    bucket:bucket
                                   cosPath:cosPath
                                    region:region
                                  filePath:filePath
                                   byteArr:byteArr
                                  uploadId:uploadId
                              stroageClass:stroageClass
                              trafficLimit:trafficLimit
                         resultCallbackKey:resultCallbackKey
                          stateCallbackKey:stateCallbackKey
                       progressCallbackKey:progressCallbackKey
             initMultipleUploadCallbackKey:initMultipleUploadCallbackKey
                                   taskKey:nil
                                     error:error];
}

- (nullable NSString *)uploadInternalTransferKey:(nonnull NSString *)transferKey resmeData:(nullable NSData *)resmeData bucket:(nonnull NSString *)bucket cosPath:(nonnull NSString *)cosPath region:(nullable NSString *)region filePath:(nullable NSString *)filePath byteArr:(nullable FlutterStandardTypedData *)byteArr uploadId:(nullable NSString *)uploadId stroageClass:(nullable NSString *)stroageClass trafficLimit:(nullable NSNumber *)trafficLimit resultCallbackKey:(nullable NSNumber *)resultCallbackKey stateCallbackKey:(nullable NSNumber *)stateCallbackKey progressCallbackKey:(nullable NSNumber *)progressCallbackKey initMultipleUploadCallbackKey:(nullable NSNumber *)initMultipleUploadCallbackKey taskKey:(nullable NSString *)taskKey error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    QCloudCOSTransferMangerService * transferManger = [self getQCloudCOSTransferMangerService:transferKey];
    QCloudCOSXMLUploadObjectRequest* put = nil;
    if(resmeData == nil){
        put = [QCloudCOSXMLUploadObjectRequest new];
        put.bucket = bucket;
        put.object = cosPath;
        if(region){
            put.regionName = region;
        }
        if(uploadId){
            [put setValue:uploadId forKey:@"uploadId"];
        }
        if(stroageClass){
            put.storageClass = QCloudCOSStorageClassDumpFromString(stroageClass);
        }
        if(trafficLimit){
            put.trafficLimit = [trafficLimit integerValue];
        }
        // 需要上传的对象内容。可以传入NSData*或者NSURL*类型的变量
        if(filePath){
            put.body = [NSURL fileURLWithPath:filePath];
        } else if(byteArr){
            put.body = byteArr.data;
        }

        put.resultCallbackKey = resultCallbackKey;
        put.progressCallbackKey = progressCallbackKey;
        put.stateCallbackKey = stateCallbackKey;
        put.iinitMultipleUploadCallbackKey = initMultipleUploadCallbackKey;
        
        TransferConfig *transferConfig = [QCloudCOSTransferConfigCache() objectForKey:transferKey];
        if(nil != transferConfig){
            if(transferConfig.sliceSizeForUpload){
                put.sliceSize = [transferConfig.sliceSizeForUpload integerValue];
            }
            if(transferConfig.divisionForUpload){
                put.mutilThreshold = [transferConfig.divisionForUpload integerValue];
            }
            if(transferConfig.enableVerification){
                put.enableVerification = [transferConfig.enableVerification boolValue];
            }
            //不支持强制简单上传
        }
    } else{
        put = [QCloudCOSXMLUploadObjectRequest requestWithRequestData:resmeData];
    }
    
    // 监听上传进度
    [put setSendProcessBlock:^(int64_t bytesSent,
                               int64_t totalBytesSent,
                               int64_t totalBytesExpectedToSend) {
        [self stateCallback:transferKey stateCallbackKey:stateCallbackKey state:QCloudCOS_STATE_IN_PROGRESS];
        if(progressCallbackKey){
            [flutterCosApi progressCallbackTransferKey:transferKey
                                                   key:progressCallbackKey
                                              complete:[NSNumber numberWithLongLong:(long long)totalBytesSent]
                                                target:[NSNumber numberWithLongLong:(long long)totalBytesExpectedToSend]
                                            completion:^(NSError *_Nullable error) {}
            ];
        }
    }];
    if(taskKey == nil){
        taskKey = [NSString stringWithFormat: @"upload-%@", [NSNumber numberWithUnsignedInteger:[put hash]]];
    }
    // 监听上传结果
    [put setFinishBlock:^(QCloudUploadObjectResult *result, NSError *error) {
        if(error != nil && [error code] == QCloudNetworkErrorCodeCanceled){
            return;
        }
        
        if(error == nil){
            [self stateCallback:transferKey stateCallbackKey:stateCallbackKey state:QCloudCOS_STATE_COMPLETED];
        } else {
            [self stateCallback:transferKey stateCallbackKey:stateCallbackKey state:QCloudCOS_STATE_FAILED];
        }
        
        if(resultCallbackKey){
            if(error == nil){
                NSDictionary* headerAll = [[result __originHTTPURLResponse__] allHeaderFields];
                NSMutableDictionary* resultDictionary = [NSMutableDictionary new];
                NSString* encodedAccessUrl = [result.location stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
                [resultDictionary setObject:encodedAccessUrl forKey:@"accessUrl"];
                [resultDictionary setObject:result.eTag forKey:@"eTag"];
                NSString* crc64ecma = [headerAll objectForKey: @"x-cos-hash-crc64ecma"];
                if(crc64ecma){
                    [resultDictionary setObject:crc64ecma forKey:@"crc64ecma"];
                }
                [flutterCosApi resultSuccessCallbackTransferKey:transferKey
                                                            key:resultCallbackKey
                                                         header:resultDictionary
                                                     completion:^(NSError * _Nullable error) {}
                ];
            } else {
                [flutterCosApi resultFailCallbackTransferKey:transferKey
                                                         key:resultCallbackKey
                                             clientException:[self buildClientException:error]
                                            serviceException:[self buildServiceException:error]
                                                  completion:^(NSError * _Nullable error) {}
                ];
                
            }
        }
        [QCloudCOSTaskCache() removeObject:taskKey];
    }];
    [put setInitMultipleUploadFinishBlock:^(QCloudInitiateMultipartUploadResult *
                                            multipleUploadInitResult,
                                            QCloudCOSXMLUploadObjectResumeData resumeData) {
        if(initMultipleUploadCallbackKey){
            [flutterCosApi initMultipleUploadCallbackTransferKey:transferKey key:initMultipleUploadCallbackKey bucket:multipleUploadInitResult.bucket cosKey:multipleUploadInitResult.key uploadId:multipleUploadInitResult.uploadId completion:^(NSError *_Nullable error) {}
            ];
        }
    }];
    [transferManger UploadObject:put];
    [self stateCallback:transferKey stateCallbackKey:stateCallbackKey state:QCloudCOS_STATE_WAITING];
    
    [QCloudCOSTaskCache() setObject:put forKey:taskKey];
    return taskKey;
}

- (nullable CosXmlClientException *)buildClientException:(nonnull NSError *) error {
    if([[self errorType:error] isEqualToString:@"Client"]){
        NSDictionary *userinfoDic = error.userInfo;
        NSString *details = @"";
        NSString * message = @"";
        if (userinfoDic) {
            message = userinfoDic[NSLocalizedDescriptionKey];
            details = [userinfoDic qcloud_modelToJSONString];
        }
        return [CosXmlClientException makeWithErrorCode:[NSNumber numberWithInteger:error.code] message:message details:details];
    } else {
        return nil;
    }
}
- (nullable CosXmlServiceException *)buildServiceException:(nonnull NSError *) error {
    if([[self errorType:error] isEqualToString:@"Server"]){
        NSDictionary *userinfoDic = error.userInfo;
        NSString *details = @"";
        NSString *errorCode = [NSError qcloud_networkErrorCodeTransferToString:error.code];
        if([errorCode isEqualToString:@""]){
            errorCode = [@(error.code) stringValue];
        }
        NSString *requestID = @"";
        NSString *resource = @"";
        NSString *errorMsg = userinfoDic[NSLocalizedDescriptionKey];
        if (userinfoDic) {
            details = [userinfoDic qcloud_modelToJSONString];
            if (userinfoDic[@"Code"]) {
                errorCode = userinfoDic[@"Code"];
                requestID = userinfoDic[@"RequestId"];
                resource = userinfoDic[@"Resource"];
                errorMsg = userinfoDic[@"Message"];
            }
        }
        return [CosXmlServiceException makeWithStatusCode:[NSNumber numberWithInteger:error.code] httpMsg:@"" requestId:requestID?requestID : @"" errorCode:errorCode ? errorCode : @"" errorMessage:errorMsg?errorMsg:@"" serviceName:resource?resource:@"" details:details];
    } else {
        return nil;
    }
}

-(FlutterError *)buildFlutterError:(nonnull NSError *) error {
    NSDictionary *userinfoDic = error.userInfo;
    NSString *details = @"";
    NSString *errorCode = [NSError qcloud_networkErrorCodeTransferToString:(QCloudNetworkErrorCode)error.code];
    if([errorCode isEqualToString:@""]){
        errorCode = [@(error.code) stringValue];
    }
    NSString *errorMsg = userinfoDic[NSLocalizedDescriptionKey];
    if (userinfoDic) {
        details = [userinfoDic qcloud_modelToJSONString];
        if (userinfoDic[@"Code"]) {
            errorCode = userinfoDic[@"Code"];
            errorMsg = userinfoDic[@"Message"];
        }
    }
    return [FlutterError errorWithCode:errorCode message:errorMsg details:details];
}

-(NSString *)errorType:(nonnull NSError *) error{
    NSDictionary *userinfoDic = error.userInfo;
    NSString *errorCode = [NSError qcloud_networkErrorCodeTransferToString:(QCloudNetworkErrorCode)error.code];
    NSString *requestID = @"";
    NSString *error_name = @"Client";
    NSString *errorMsg = userinfoDic[NSLocalizedDescriptionKey];
    if (userinfoDic) {
        if (userinfoDic[@"Code"]) {
            errorCode = userinfoDic[@"Code"];
            requestID = userinfoDic[@"RequestId"];
            error_name = @"Server";
            errorMsg = userinfoDic[@"Message"];
        }
    }
    if([error.domain isEqualToString:kQCloudNetworkDomain] && error.code == QCloudNetworkErrorCodeResponseDataTypeInvalid){
        error_name = @"Server";
    }
    
    return error_name;
}

-(FlutterError *)buildNotSupportFlutterError {
    return [FlutterError errorWithCode:@"999" message:@"iOS does not support" details:nil];
}

-(void)stateCallback:(nonnull NSString *)transferKey stateCallbackKey:(nullable NSNumber *)stateCallbackKey state:(nullable NSString *)state{
    if(stateCallbackKey){
        [flutterCosApi stateCallbackTransferKey:transferKey
                                            key:stateCallbackKey
                                          state:state
                                     completion:^(NSError *_Nullable error) {}
        ];
    }
}

- (long long) fileSizeAtPath:(NSString*) filePath{

    NSFileManager* manager = [NSFileManager defaultManager];
    if ([manager fileExistsAtPath:filePath]){
        return [[manager attributesOfItemAtPath:filePath error:nil] fileSize];
    }
    return 0;

}
@end
