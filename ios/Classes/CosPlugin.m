#import "CosPlugin.h"
#import "pigeon.h"
#import "QCloudServiceConfiguration_Private.h"
#import "CosPluginSignatureProvider.h"
#import <QCloudCOSXML/QCloudCOSXML.h>
#import <Flutter/Flutter.h>
#import <objc/runtime.h>
#import "QCloudHttpDNS.h"
#import "QCloudThreadSafeMutableDictionary.h"
#import "QCloudCore/QCloudLogger.h"
#import "QCloudCore/QCloudLogModel.h"
#import "QCloudCore/QCloudCLSLoggerOutput.h"
#import "QCloudCore/QCloudCustomLoggerOutput.h"
static void *kQCloudDownloadRequestResultCallbackKey = &kQCloudDownloadRequestResultCallbackKey;
static void *kQCloudDownloadRequestProgressCallbackKey = &kQCloudDownloadRequestProgressCallbackKey;
static void *kQCloudDownloadRequestStateCallbackKey = &kQCloudDownloadRequestStateCallbackKey;
static void *kQCloudDownloadRequestLocalDownloaded = &kQCloudDownloadRequestLocalDownloaded;

@class QCloudLoggerCallBackOutput;
@implementation QCloudServiceConfiguration (Headers)

+ (void)load{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [self class];
        
        SEL originalSelector = @selector(copyWithZone:);
        SEL swizzledSelector = @selector(swizzled_copyWithZone:);
        
        Method originalMethod = class_getInstanceMethod(class, originalSelector);
        Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
        
        if (!originalMethod) {
            NSLog(@"Original method copyWithZone: not found!");
            return;
        }
        
        BOOL didAddMethod = class_addMethod(class,
                                            originalSelector,
                                            method_getImplementation(swizzledMethod),
                                            method_getTypeEncoding(swizzledMethod));
        if (didAddMethod) {
            class_replaceMethod(class,
                                swizzledSelector,
                                method_getImplementation(originalMethod),
                                method_getTypeEncoding(originalMethod));
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod);
        }
    });
}

- (instancetype)swizzled_copyWithZone:(NSZone *)zone{
    QCloudServiceConfiguration *config = [self swizzled_copyWithZone:zone];
    config.customHeaders = self.customHeaders;
    config.noSignHeaders = self.noSignHeaders;
    return config;
}

- (void)setCustomHeaders:(NSDictionary *)customHeaders{
    objc_setAssociatedObject(self, @"customHeaders", customHeaders, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (NSDictionary *)customHeaders {
    return objc_getAssociatedObject(self, @"customHeaders");
}

- (void)setNoSignHeaders:(NSArray *)noSignHeaders{
    objc_setAssociatedObject(self, @"noSignHeaders", noSignHeaders, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSArray *)noSignHeaders{
    return objc_getAssociatedObject(self, @"noSignHeaders");
}
@end

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

@interface CosPlugin ()<QCloudHTTPDNSProtocol>
{
    CosPluginSignatureProvider* signatureProvider;
    NSString * permanentSecretId;
    NSString * permanentSecretKey;
    bool isScopeLimitCredential;
    bool isFetchDns;
}

@property (nonatomic,strong)NSMutableDictionary * logCallbackMap;
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


- (NSMutableDictionary *)logCallbackMap{
    if (!_logCallbackMap) {
        _logCallbackMap = [NSMutableDictionary new];
    }
    return _logCallbackMap;
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
    if(config.domainSwitch){
        configuration.disableChangeHost = ![config.domainSwitch boolValue];
    }
    if(config.isHttps){
        endpoint.useHTTPS = config.isHttps;
    }
    if(config.accelerate && [config.accelerate boolValue]){
        endpoint.suffix = @"cos.accelerate.myqcloud.com";
    }
    configuration.customHeaders = config.customHeaders;
    configuration.noSignHeaders = config.noSignHeaders;
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

- (void)initCustomerDNSDnsMap:(NSDictionary<NSString *, NSArray<NSString *> *> *)dnsMap error:(FlutterError *_Nullable *_Nonnull)error{
    [dnsMap enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSArray<NSString *> * _Nonnull obj, BOOL * _Nonnull stop) {
        [obj enumerateObjectsUsingBlock:^(NSString * _Nonnull ip, NSUInteger idx, BOOL * _Nonnull stop) {
            [[QCloudHttpDNS shareDNS] setIp:ip forDomain:key];
        }];
        QCloudThreadSafeMutableDictionary * ipHostMap = [[QCloudHttpDNS shareDNS] valueForKey:@"_ipHostMap"];
        if(obj && key){
            [ipHostMap setObject:obj forKey:key];
        }
    }];
}
- (void)initCustomerDNSFetchWithError:(FlutterError *_Nullable *_Nonnull)error{
    isFetchDns = YES;
    [QCloudHttpDNS shareDNS].delegate = self;
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

- (void)deleteBucketServiceKey:(NSString *)serviceKey bucket:(NSString *)bucket region:(nullable NSString *)region sessionCredentials:(nullable SessionQCloudCredentials *)sessionCredentials completion:(void(^)(FlutterError *_Nullable))completion {
    QCloudCOSXMLService * service = [self getQCloudCOSXMLService:serviceKey];
    QCloudDeleteBucketRequest* request = [[QCloudDeleteBucketRequest alloc ] init];
    request.credential = [self transferCredential:sessionCredentials];
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

- (void)deleteObjectServiceKey:(NSString *)serviceKey bucket:(NSString *)bucket region:(nullable NSString *)region cosPath:(NSString *)cosPath versionId:(nullable NSString *)versionId sessionCredentials:(nullable SessionQCloudCredentials *)sessionCredentials completion:(void(^)(FlutterError *_Nullable))completion {
    QCloudCOSXMLService * service = [self getQCloudCOSXMLService:serviceKey];
    QCloudDeleteObjectRequest* request = [[QCloudDeleteObjectRequest alloc ] init];
    request.credential = [self transferCredential:sessionCredentials];
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

- (void)getBucketAccelerateServiceKey:(NSString *)serviceKey bucket:(NSString *)bucket region:(nullable NSString *)region sessionCredentials:(nullable SessionQCloudCredentials *)sessionCredentials completion:(void(^)(NSNumber *_Nullable, FlutterError *_Nullable))completion {
    QCloudCOSXMLService * service = [self getQCloudCOSXMLService:serviceKey];
    QCloudGetBucketAccelerateRequest* request = [[QCloudGetBucketAccelerateRequest alloc ] init];
    request.credential = [self transferCredential:sessionCredentials];
    request.bucket = bucket;
    if(region){
        request.regionName = region;
    }
    [request setFinishBlock:^(QCloudBucketAccelerateConfiguration *_Nullable outputObject,NSError*error) {
        if(outputObject){
            bool b = [outputObject status] == QCloudCOSBucketAccelerateStatusEnabled;
            completion([NSNumber numberWithBool:b], nil);
        } else {
            completion(nil, [self buildFlutterError:error]);
        }
    }];
    [service GetBucketAccelerate:request];
}

- (void)getBucketLocationServiceKey:(NSString *)serviceKey bucket:(NSString *)bucket region:(nullable NSString *)region sessionCredentials:(nullable SessionQCloudCredentials *)sessionCredentials completion:(void(^)(NSString *_Nullable, FlutterError *_Nullable))completion {
    QCloudCOSXMLService * service = [self getQCloudCOSXMLService:serviceKey];
    QCloudGetBucketLocationRequest* request = [[QCloudGetBucketLocationRequest alloc ] init];
    request.credential = [self transferCredential:sessionCredentials];
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

- (void)getBucketServiceKey:(NSString *)serviceKey bucket:(NSString *)bucket region:(nullable NSString *)region prefix:(nullable NSString *)prefix delimiter:(nullable NSString *)delimiter encodingType:(nullable NSString *)encodingType marker:(nullable NSString *)marker maxKeys:(nullable NSNumber *)maxKeys sessionCredentials:(nullable SessionQCloudCredentials *)sessionCredentials completion:(void(^)(BucketContents *_Nullable, FlutterError *_Nullable))completion {
    QCloudCOSXMLService * service = [self getQCloudCOSXMLService:serviceKey];
    QCloudGetBucketRequest* request = [[QCloudGetBucketRequest alloc ] init];
    request.credential = [self transferCredential:sessionCredentials];
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

- (void)getBucketVersioningServiceKey:(NSString *)serviceKey bucket:(NSString *)bucket region:(nullable NSString *)region sessionCredentials:(nullable SessionQCloudCredentials *)sessionCredentials completion:(void(^)(NSNumber *_Nullable, FlutterError *_Nullable))completion {
    QCloudCOSXMLService * service = [self getQCloudCOSXMLService:serviceKey];
    QCloudGetBucketVersioningRequest* request = [[QCloudGetBucketVersioningRequest alloc ] init];
    request.credential = [self transferCredential:sessionCredentials];
    request.bucket = bucket;
    if(region){
        request.regionName = region;
    }
    [request setFinishBlock:^(QCloudBucketVersioningConfiguration *_Nullable outputObject,NSError*error) {
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

- (void)getPresignedUrlServiceKey:(NSString *)serviceKey bucket:(NSString *)bucket cosPath:(NSString *)cosPath signValidTime:(nullable NSNumber *)signValidTime signHost:(nullable NSNumber *)signHost parameters:(nullable NSDictionary<NSString *, NSString *> *)parameters region:(nullable NSString *)region sessionCredentials:(nullable SessionQCloudCredentials *)sessionCredentials completion:(void(^)(NSString *_Nullable, FlutterError *_Nullable))completion {
    QCloudCOSXMLService * service = [self getQCloudCOSXMLService:serviceKey];
    QCloudGetPresignedURLRequest* getPresignedURLRequest = [[QCloudGetPresignedURLRequest alloc] init];
    getPresignedURLRequest.credential = [self transferCredential:sessionCredentials];
    // 存储桶名称，由BucketName-Appid 组成，可以在COS控制台查看 https://console.cloud.tencent.com/cos5/bucket
    getPresignedURLRequest.bucket = bucket;
    // 对象键，是对象在 COS 上的完整路径，如果带目录的话，格式为 "video/xxx/movie.mp4"
    getPresignedURLRequest.object = QCloudURLEncodeUTF8(cosPath);
    getPresignedURLRequest.HTTPMethod = @"GET";

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

- (void)getServiceServiceKey:(NSString *)serviceKey sessionCredentials:(nullable SessionQCloudCredentials *)sessionCredentials completion:(void(^)(ListAllMyBuckets *_Nullable, FlutterError *_Nullable))completion {
    QCloudCOSXMLService * service = [self getQCloudCOSXMLService:serviceKey];
    QCloudGetServiceRequest* request = [[QCloudGetServiceRequest alloc ] init];
    request.credential = [self transferCredential:sessionCredentials];
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

- (void)headBucketServiceKey:(NSString *)serviceKey bucket:(NSString *)bucket region:(nullable NSString *)region sessionCredentials:(nullable SessionQCloudCredentials *)sessionCredentials completion:(void(^)(NSDictionary<NSString *, NSString *> *_Nullable, FlutterError *_Nullable))completion {
    QCloudCOSXMLService * service = [self getQCloudCOSXMLService:serviceKey];
    QCloudHeadBucketRequest* request = [[QCloudHeadBucketRequest alloc ] init];
    request.credential = [self transferCredential:sessionCredentials];
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

- (void)headObjectServiceKey:(NSString *)serviceKey bucket:(NSString *)bucket region:(nullable NSString *)region cosPath:(NSString *)cosPath versionId:(nullable NSString *)versionId sessionCredentials:(nullable SessionQCloudCredentials *)sessionCredentials completion:(void(^)(NSDictionary<NSString *, NSString *> *_Nullable, FlutterError *_Nullable))completion {
    QCloudCOSXMLService * service = [self getQCloudCOSXMLService:serviceKey];
    QCloudHeadObjectRequest* request = [[QCloudHeadObjectRequest alloc ] init];
    request.credential = [self transferCredential:sessionCredentials];
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

- (void)putBucketAccelerateServiceKey:(NSString *)serviceKey bucket:(NSString *)bucket region:(nullable NSString *)region enable:(NSNumber *)enable sessionCredentials:(nullable SessionQCloudCredentials *)sessionCredentials completion:(void(^)(FlutterError *_Nullable))completion {
    QCloudCOSXMLService * service = [self getQCloudCOSXMLService:serviceKey];
    QCloudPutBucketAccelerateRequest* request = [[QCloudPutBucketAccelerateRequest alloc ] init];
    request.credential = [self transferCredential:sessionCredentials];
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

- (void)putBucketServiceKey:(NSString *)serviceKey bucket:(NSString *)bucket region:(nullable NSString *)region enableMAZ:(nullable NSNumber *)enableMAZ cosacl:(nullable NSString *)cosacl readAccount:(nullable NSString *)readAccount writeAccount:(nullable NSString *)writeAccount readWriteAccount:(nullable NSString *)readWriteAccount sessionCredentials:(nullable SessionQCloudCredentials *)sessionCredentials completion:(void(^)(FlutterError *_Nullable))completion {
    QCloudCOSXMLService * service = [self getQCloudCOSXMLService:serviceKey];
    QCloudPutBucketRequest* request = [[QCloudPutBucketRequest alloc ] init];
    request.credential = [self transferCredential:sessionCredentials];
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

- (void)putBucketVersioningServiceKey:(NSString *)serviceKey bucket:(NSString *)bucket region:(nullable NSString *)region enable:(NSNumber *)enable sessionCredentials:(nullable SessionQCloudCredentials *)sessionCredentials completion:(void(^)(FlutterError *_Nullable))completion {
    QCloudCOSXMLService * service = [self getQCloudCOSXMLService:serviceKey];
    QCloudPutBucketVersioningRequest* request = [[QCloudPutBucketVersioningRequest alloc ] init];
    request.credential = [self transferCredential:sessionCredentials];
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


- (nullable NSString *)downloadTransferKey:(NSString *)transferKey bucket:(NSString *)bucket cosPath:(NSString *)cosPath region:(nullable NSString *)region savePath:(NSString *)savePath versionId:(nullable NSString *)versionId trafficLimit:(nullable NSNumber *)trafficLimit customHeaders:(nullable NSDictionary<NSString *, NSString *> *)customHeaders noSignHeaders:(nullable NSArray<NSString *> *)noSignHeaders resultCallbackKey:(nullable NSNumber *)resultCallbackKey stateCallbackKey:(nullable NSNumber *)stateCallbackKey progressCallbackKey:(nullable NSNumber *)progressCallbackKey sessionCredentials:(nullable SessionQCloudCredentials *)sessionCredentials error:(FlutterError *_Nullable *_Nonnull)error{
    return [self downloadInternalTransferKey:transferKey
                                      bucket:bucket
                                     cosPath:cosPath
                                      region:region
                                    savePath:savePath
                                   versionId:versionId
                                trafficLimit:trafficLimit
                               customHeaders:customHeaders
                               noSignHeaders:noSignHeaders
                           resultCallbackKey:resultCallbackKey
                            stateCallbackKey:stateCallbackKey
                         progressCallbackKey:progressCallbackKey
                                     taskKey:nil
                          sessionCredentials:sessionCredentials
                                       error:error];
}

- (nullable NSString *)downloadInternalTransferKey:(nonnull NSString *)transferKey bucket:(nonnull NSString *)bucket cosPath:(nonnull NSString *)cosPath region:(nullable NSString *)region savePath:(nonnull NSString *)savePath versionId:(nullable NSString *)versionId trafficLimit:(nullable NSNumber *)trafficLimit customHeaders:(nullable NSDictionary<NSString *, NSString *> *)customHeaders noSignHeaders:(nullable NSArray<NSString *> *)noSignHeaders resultCallbackKey:(nullable NSNumber *)resultCallbackKey stateCallbackKey:(nullable NSNumber *)stateCallbackKey progressCallbackKey:(nullable NSNumber *)progressCallbackKey taskKey:(nullable NSString *)taskKey sessionCredentials:(nullable SessionQCloudCredentials *)sessionCredentials error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    QCloudCOSTransferMangerService * transferManger = [self getQCloudCOSTransferMangerService:transferKey];
    QCloudCOSXMLDownloadObjectRequest *getObjectRequest = [[QCloudCOSXMLDownloadObjectRequest alloc] init];
    getObjectRequest.credential = [self transferCredential:sessionCredentials];
    
    getObjectRequest.resumeLocalProcess = YES;
    //支持断点下载
    [getObjectRequest.customHeaders addEntriesFromDictionary:customHeaders];
    if (noSignHeaders) {
        getObjectRequest.payload = @{@"noSignHeaders":noSignHeaders};
    }
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
                                                         result:nil
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
                                              complete:[NSNumber numberWithLongLong:((long long)totalBytesDownload)]
                                                target:[NSNumber numberWithLongLong:((long long)totalBytesExpectedToDownload)]
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
        if (put.resmeData){
            [self stateCallback:transferKey stateCallbackKey:[put stateCallbackKey] state:QCloudCOS_STATE_PAUSED];
        }else{
            NSLog(@"UnsupportOperation:无法暂停当前的上传请求，因为complete请求已经发出");
        }
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

- (void)resumeTaskId:(NSString *)taskId transferKey:(NSString *)transferKey error:(FlutterError *_Nullable *_Nonnull)error {
    if([taskId hasPrefix:@"upload-"]){
        QCloudCOSXMLUploadObjectRequest* put = [QCloudCOSTaskCache() objectForKey:taskId];
        if(put == nil) {
            NSLog(@"%@ request canceled or ended", taskId);
            return;
        }
        if([put resmeData] == nil) {
            NSLog(@"%@ request has not started", taskId);
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
                          callbackParam:[put customHeaders][@"x-cos-callback"]
                        customHeaders:put.customHeaders                          noSignHeaders:nil
              resultCallbackKey:[put resultCallbackKey]
               stateCallbackKey:[put stateCallbackKey]
            progressCallbackKey:[put progressCallbackKey]
  initMultipleUploadCallbackKey:[put iinitMultipleUploadCallbackKey]
                        taskKey:taskId
                     sessionCredentials:nil
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
                            customHeaders:request.customHeaders                          noSignHeaders:nil
                resultCallbackKey:[request resultCallbackKey]
                 stateCallbackKey:[request stateCallbackKey]
              progressCallbackKey:[request progressCallbackKey]
                          taskKey:taskId
                       sessionCredentials:nil
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

- (nullable NSString *)uploadTransferKey:(NSString *)transferKey bucket:(NSString *)bucket cosPath:(NSString *)cosPath region:(nullable NSString *)region filePath:(nullable NSString *)filePath byteArr:(nullable FlutterStandardTypedData *)byteArr uploadId:(nullable NSString *)uploadId stroageClass:(nullable NSString *)stroageClass trafficLimit:(nullable NSNumber *)trafficLimit callbackParam:(nullable NSString *)callbackParam customHeaders:(nullable NSDictionary<NSString *, NSString *> *)customHeaders noSignHeaders:(nullable NSArray<NSString *> *)noSignHeaders resultCallbackKey:(nullable NSNumber *)resultCallbackKey stateCallbackKey:(nullable NSNumber *)stateCallbackKey progressCallbackKey:(nullable NSNumber *)progressCallbackKey initMultipleUploadCallbackKey:(nullable NSNumber *)initMultipleUploadCallbackKey sessionCredentials:(nullable SessionQCloudCredentials *)sessionCredentials error:(FlutterError *_Nullable *_Nonnull)error {
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
                             callbackParam:callbackParam
                             customHeaders:customHeaders
                             noSignHeaders:noSignHeaders
                         resultCallbackKey:resultCallbackKey
                          stateCallbackKey:stateCallbackKey
                       progressCallbackKey:progressCallbackKey
             initMultipleUploadCallbackKey:initMultipleUploadCallbackKey
                                   taskKey:nil
                        sessionCredentials:sessionCredentials
                                     error:error];
}

- (nullable NSString *)uploadInternalTransferKey:(nonnull NSString *)transferKey resmeData:(nullable NSData *)resmeData bucket:(nonnull NSString *)bucket cosPath:(nonnull NSString *)cosPath region:(nullable NSString *)region filePath:(nullable NSString *)filePath byteArr:(nullable FlutterStandardTypedData *)byteArr uploadId:(nullable NSString *)uploadId stroageClass:(nullable NSString *)stroageClass trafficLimit:(nullable NSNumber *)trafficLimit callbackParam:(nullable NSString *)callbackParam customHeaders:(nullable NSDictionary<NSString *, NSString *> *)customHeaders noSignHeaders:(nullable NSArray<NSString *> *)noSignHeaders resultCallbackKey:(nullable NSNumber *)resultCallbackKey stateCallbackKey:(nullable NSNumber *)stateCallbackKey progressCallbackKey:(nullable NSNumber *)progressCallbackKey initMultipleUploadCallbackKey:(nullable NSNumber *)initMultipleUploadCallbackKey taskKey:(nullable NSString *)taskKey sessionCredentials:(nullable SessionQCloudCredentials *)sessionCredentials error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    QCloudCOSTransferMangerService * transferManger = [self getQCloudCOSTransferMangerService:transferKey];
    QCloudCOSXMLUploadObjectRequest* put = nil;
    if(resmeData == nil){
        put = [QCloudCOSXMLUploadObjectRequest new];
        [put.customHeaders addEntriesFromDictionary:customHeaders];
        if (noSignHeaders) {
            put.payload = @{@"noSignHeaders":noSignHeaders};
        }
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
        if(callbackParam){
            NSData *data = [callbackParam dataUsingEncoding:NSUTF8StringEncoding];
            NSString *base64String = [data base64EncodedStringWithOptions:0];
            if(base64String){
                // 配置回调参数
                [put.customHeaders setObject:base64String forKey:@"x-cos-callback"];
            }
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
        put.credential = [self transferCredential:sessionCredentials];
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
                [resultDictionary setObject:result.location?:@"" forKey:@"accessUrl"];
                [resultDictionary setObject:result.eTag?:@"" forKey:@"eTag"];
                NSString* crc64ecma = [headerAll objectForKey: @"x-cos-hash-crc64ecma"];
                if(crc64ecma){
                    [resultDictionary setObject:crc64ecma forKey:@"crc64ecma"];
                }
                
                CosXmlResult * cosXmlResult = [CosXmlResult new];
                [cosXmlResult setETag:result.eTag?:@""];
                [cosXmlResult setAccessUrl:result.location?:@""];
                if (result.CallbackResult) {
                    CallbackResultError* callbackResultError = nil;
                    if(result.CallbackResult.Error){
                        callbackResultError = [CallbackResultError makeWithCode:result.CallbackResult.Error.Code message:result.CallbackResult.Error.Message];
                    }
                    CallbackResult * callbackResult = [CallbackResult makeWithStatus:[NSNumber numberWithInteger:result.CallbackResult.Status.integerValue] callbackBody:result.CallbackResult.CallbackBody error:callbackResultError];
                    [cosXmlResult setCallbackResult:callbackResult];
                }

                
                [flutterCosApi resultSuccessCallbackTransferKey:transferKey
                                                            key:resultCallbackKey
                                                         header:resultDictionary
                                                         result:cosXmlResult
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

- (NSString *)resolveDomain:(NSString *)domain{
    __block NSString * ip;
    dispatch_semaphore_t semp = dispatch_semaphore_create(0);
    [flutterCosApi fetchDnsDomain:domain completion:^(NSArray<NSString *> * _Nullable ips, NSError * _Nullable) {
        ip = ips.lastObject;
        QCloudThreadSafeMutableDictionary * ipHostMap = [[QCloudHttpDNS shareDNS] valueForKey:@"_ipHostMap"];
        if(ips && domain){
            [ipHostMap setObject:ips forKey:domain];
        }
        dispatch_semaphore_signal(semp);
    }];
    dispatch_semaphore_wait(semp, dispatch_time(DISPATCH_TIME_NOW, 60 * NSEC_PER_SEC));
    return ip;
}

- (void)enableLogcatEnable:(NSNumber *)enable error:(FlutterError *_Nullable *_Nonnull)error{
    if (enable.integerValue > 0) {
        QCloudLogger.sharedLogger.logLevel = QCloudLogLevelVerbose;
    }else{
        QCloudLogger.sharedLogger.logLevel = QCloudLogLevelNone;
    }
}
- (void)enableLogFileEnable:(NSNumber *)enable error:(FlutterError *_Nullable *_Nonnull)error{
    if (enable.integerValue > 0) {
        QCloudLogger.sharedLogger.logFileLevel = QCloudLogLevelVerbose;
    }else{
        QCloudLogger.sharedLogger.logFileLevel = QCloudLogLevelNone;
    }
}

- (void)addLogListenerKey:(NSNumber *)key error:(FlutterError *_Nullable *_Nonnull)error{
    @synchronized (self) {
        QCloudCustomLoggerOutput * output = [[QCloudCustomLoggerOutput alloc]init];
        output.callback = ^(QCloudLogModel * _Nonnull model, NSDictionary * _Nonnull extendInfo) {
            double time = [model.date timeIntervalSince1970];
            NSInteger timestamp = time * 1000;
            LogEntity * entity = [LogEntity makeWithTimestamp:@(timestamp) level:6 - model.level category:model.category - 1 tag:model.tag message:model.message threadName:model.threadName extras:extendInfo throwable:nil];
            [flutterCosApi onLogKey:key entity:entity completion:^(NSError * _Nullable error) {}];
        };
        [[QCloudLogger sharedLogger] addLogger:output];
        [self.logCallbackMap setObject:output forKey:key.stringValue];
    }
}

- (void)removeLogListenerKey:(NSNumber *)key error:(FlutterError *_Nullable *_Nonnull)error{
    @synchronized (self) {
        QCloudCustomLoggerOutput * output = [self.logCallbackMap objectForKey:key.stringValue];
        [[QCloudLogger sharedLogger] removeLogger:output];
    }
}

- (void)setMinLevelMinLevel:(LogLevel )minLevel error:(FlutterError *_Nullable *_Nonnull)error{
    [QCloudLogger sharedLogger].logLevel = 6 - minLevel;
    [QCloudLogger sharedLogger].logClsLevel = 6 - minLevel;
    [QCloudLogger sharedLogger].logFileLevel = 6 - minLevel;
}
- (void)setLogcatMinLevelMinLevel:(LogLevel )minLevel error:(FlutterError *_Nullable *_Nonnull)error{
    [QCloudLogger sharedLogger].logLevel = 6 - minLevel;
}
- (void)setFileMinLevelMinLevel:(LogLevel )minLevel error:(FlutterError *_Nullable *_Nonnull)error{
    [QCloudLogger sharedLogger].logFileLevel = 6 - minLevel;
}
- (void)setClsMinLevelMinLevel:(LogLevel )minLevel error:(FlutterError *_Nullable *_Nonnull)error{
    [QCloudLogger sharedLogger].logClsLevel = 6 - minLevel;
                }
- (void)setDeviceIDDeviceID:(NSString *)deviceID error:(FlutterError *_Nullable *_Nonnull)error{
    [QCloudLogger sharedLogger].deviceID = deviceID;
}
- (void)setDeviceModelDeviceModel:(NSString *)deviceModel error:(FlutterError *_Nullable *_Nonnull)error{
    [QCloudLogger sharedLogger].deviceModel = deviceModel;
}
- (void)setAppVersionAppVersion:(NSString *)appVersion error:(FlutterError *_Nullable *_Nonnull)error{
    [QCloudLogger sharedLogger].appVersion = appVersion;
}
- (void)setExtrasExtras:(NSDictionary<NSString *, NSString *> *)extras error:(FlutterError *_Nullable *_Nonnull)error{
    [QCloudLogger sharedLogger].extendInfo = extras;
}
- (void)setLogFileEncryptionKeyKey:(FlutterStandardTypedData *)key iv:(FlutterStandardTypedData *)iv error:(FlutterError *_Nullable *_Nonnull)error{
    [QCloudLogger sharedLogger].aesKey = key.data;
    [QCloudLogger sharedLogger].aesIv = iv.data;
}
- (void)setCLsChannelAnonymousTopicId:(NSString *)topicId endpoint:(NSString *)endpoint error:(FlutterError *_Nullable *_Nonnull)error{
    QCloudCLSLoggerOutput * output = [[QCloudCLSLoggerOutput alloc]initWithTopicId:topicId endpoint:endpoint];
    [[QCloudLogger sharedLogger]addLogger:output];
}
- (void)setCLsChannelStaticKeyTopicId:(NSString *)topicId endpoint:(NSString *)endpoint secretId:(NSString *)secretId secretKey:(NSString *)secretKey error:(FlutterError *_Nullable *_Nonnull)error{
    QCloudCLSLoggerOutput * output = [[QCloudCLSLoggerOutput alloc]initWithTopicId:topicId endpoint:endpoint];
    [output setupPermanentCredentialsSecretId:secretId secretKey:secretKey];
    [[QCloudLogger sharedLogger]addLogger:output];
}
- (void)setCLsChannelSessionCredentialTopicId:(NSString *)topicId endpoint:(NSString *)endpoint error:(FlutterError *_Nullable *_Nonnull)error{
    QCloudCLSLoggerOutput * output = [[QCloudCLSLoggerOutput alloc]initWithTopicId:topicId endpoint:endpoint];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [output setupCredentialsRefreshBlock:^QCloudCredential * _Nonnull{
            __block SessionQCloudCredentials * credentials = nil;
            dispatch_semaphore_t semp = dispatch_semaphore_create(0);
            [flutterCosApi fetchClsSessionCredentialsWithCompletion:^(SessionQCloudCredentials * _Nullable _credentials, NSError * _Nullable) {
                credentials = _credentials;
                dispatch_semaphore_signal(semp);
            }];
            dispatch_semaphore_wait(semp, DISPATCH_TIME_FOREVER);
            QCloudCredential * credential = [QCloudCredential new];
            credential.secretID = credentials.secretId;
            credential.secretKey = credentials.secretKey;
            credential.token = credentials.token;
            if (credentials.expiredTime) {
                credential.expirationDate = [NSDate dateWithTimeIntervalSince1970:[credentials.expiredTime integerValue]];
            }
            if (credentials.startTime) {
                credential.startDate = [NSDate dateWithTimeIntervalSince1970:[credentials.startTime integerValue]];
            }
            return credential;
        }];
    });
    [[QCloudLogger sharedLogger]addLogger:output];
}
- (void)addSensitiveRuleRuleName:(NSString *)ruleName regex:(NSString *)regex error:(FlutterError *_Nullable *_Nonnull)error{
    NSLog(@"ios 不支持：addSensitiveRuleRuleName");
}
- (void)removeSensitiveRuleRuleName:(NSString *)ruleName error:(FlutterError *_Nullable *_Nonnull)error{
    NSLog(@"ios 不支持：removeSensitiveRuleRuleName");
}

- (nullable NSString *)getLogRootDirWithError:(FlutterError *_Nullable *_Nonnull)error{
    return [QCloudLogger sharedLogger].logDirctoryPath;
}

-(QCloudCredential *)transferCredential:(SessionQCloudCredentials *)sessionCredentials{
    if (!sessionCredentials) {
        return nil;
    }
    QCloudCredential * credential = [QCloudCredential new];
    credential.secretID = sessionCredentials.secretId;
    credential.secretKey = sessionCredentials.secretKey;
    credential.token = sessionCredentials.token;
    if (sessionCredentials.expiredTime) {
        credential.expirationDate = [NSDate dateWithTimeIntervalSince1970:sessionCredentials.expiredTime.integerValue];
    }
    if (sessionCredentials.startTime) {
        credential.startDate = [NSDate dateWithTimeIntervalSince1970:sessionCredentials.startTime.integerValue];
    }
    return credential;
}

@end
