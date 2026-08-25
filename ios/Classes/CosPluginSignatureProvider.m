//
//  CosPluginSignatureProvider.m
//  cos
//
//  Created by jordanqin on 2022/12/8.
//

#import "CosPluginSignatureProvider.h"
#import "pigeon.h"
#import <QCloudCOSXML/QCloudCOSXML.h>
#import <Flutter/Flutter.h>
#import "CosPlugin.h"

@implementation CosPluginSignatureProvider

/// 把 pigeon 的 FlutterError 转成 NSError。
///
/// pigeon 25.x 起 FlutterApi 回调的错误类型由 NSError* 变为 FlutterError*，
/// 而 FlutterError 继承自 NSObject（**不是** NSError 子类）：它没有 domain/userInfo，
/// 且 code 是 NSString* 而非 NSInteger。QCloud 的 continueBlock 要求 NSError*，
/// 直接传 FlutterError* 不仅类型不符，后续对其取 .domain/.userInfo 还会
/// 触发 unrecognized selector 崩溃，故必须显式转换。
///
/// code 固定用 QCloudNetworkErrorCodeCredentialNotReady(10001)，而不是
/// [error.code integerValue]：pigeon 的 code 是 "channel-error"/"error" 这类
/// 非数字字符串，取 integerValue 恒为 0，既不可用于判断、也与 Android 不一致
/// （Android 同路径用 ClientErrorCode.INVALID_CREDENTIALS，见
/// BridgeCredentialProvider.java）。10001 亦是 QCloud 自身签名失败时使用的码。
/// 原始字符串 code 保留在 userInfo 中，便于排查。
+ (nullable NSError *)nsErrorFromFlutterError:(nullable FlutterError *)error {
    if (error == nil) {
        return nil;
    }
    NSMutableDictionary * userInfo = [NSMutableDictionary dictionary];
    if (error.message) {
        userInfo[NSLocalizedDescriptionKey] = error.message;
    }
    userInfo[@"FlutterErrorCode"] = error.code;
    if (error.details) {
        userInfo[@"FlutterErrorDetails"] = error.details;
    }
    return [NSError errorWithDomain:kQCloudNetworkDomain
                               code:QCloudNetworkErrorCodeCredentialNotReady
                           userInfo:userInfo];
}

+ (instancetype)makeWithFlutterCosApi:(nonnull FlutterCosApi *)flutterCosApi
                             secretId:(nullable NSString *)secretId
                            secretKey:(nullable NSString *)secretKey
               isScopeLimitCredential:(bool)isScopeLimitCredential{
    CosPluginSignatureProvider* cosPluginSignatureProvider = [[CosPluginSignatureProvider alloc] init];
    cosPluginSignatureProvider.flutterCosApi = flutterCosApi;
    cosPluginSignatureProvider.secretId = secretId;
    cosPluginSignatureProvider.secretKey = secretKey;
    cosPluginSignatureProvider.isScopeLimitCredential = isScopeLimitCredential;
    
    // 初始化临时密钥脚手架
    cosPluginSignatureProvider.credentialFenceQueue = [QCloudCredentailFenceQueue new];
    cosPluginSignatureProvider.credentialFenceQueue.delegate = cosPluginSignatureProvider;
    
    return cosPluginSignatureProvider;
}

- (void)signatureWithFields:(QCloudSignatureFields *)fileds request:(QCloudBizHTTPRequest *)request urlRequest:(NSMutableURLRequest *)urlRequst compelete:(QCloudHTTPAuthentationContinueBlock)continueBlock {
    
    if (request.runOnService.configuration.customHeaders) {
        [request.runOnService.configuration.customHeaders enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            if (![request.customHeaders.allKeys containsObject:key]) {
                if (obj && key) {
                    [urlRequst setValue:obj forHTTPHeaderField:key];
                }
            }
        }];
    }
    
    NSMutableArray * noSignHeaders = request.runOnService.configuration.noSignHeaders.mutableCopy?:[NSMutableArray new];
    if (request.payload && request.payload[@"noSignHeaders"] && [request.payload[@"noSignHeaders"] isKindOfClass:NSArray.class]) {
        NSArray * nosign = request.payload[@"noSignHeaders"];
        [noSignHeaders addObjectsFromArray:nosign];
    }
    
    NSArray * allSignHeaders = @[@"Cache-Control", @"Content-Disposition", @"Content-Encoding", @"Content-Length", @"Content-MD5", @"Content-Type", @"Expect", @"Expires", @"If-Match" , @"If-Modified-Since" , @"If-None-Match" , @"If-Unmodified-Since" , @"Origin" , @"Range" , @"transfer-encoding" ,@"Host",@"Pic-Operations",@"ci-process"];
    
    NSMutableArray * shouldSignHeaders = [NSMutableArray new];
    [allSignHeaders enumerateObjectsUsingBlock:^(NSString *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (![noSignHeaders containsObject:obj]) {
            [shouldSignHeaders addObject:obj];;
        }
    }];

    // 如果 request 的 payload 中携带了单次临时密钥，优先使用它来签名
    QCloudCredential* payloadCredential = request.payload[@"NewQCloudCredential"];
    if(payloadCredential != nil){
        QCloudAuthentationV5Creator* creator = [[QCloudAuthentationV5Creator alloc]
                                                initWithCredential:payloadCredential];
        creator.shouldSignedList = shouldSignHeaders;
        QCloudSignature* signature =  [creator signatureForData:urlRequst];
        continueBlock(signature, nil);
        return;
    }
    
    // 永久秘钥
    if(self.secretId != nil && self.secretKey != nil && ![@"" isEqualToString:self.secretId] && ![@"" isEqualToString:self.secretKey]){
        QCloudCredential* credential = [QCloudCredential new];
        // 永久密钥 secretID
        // sercret_id替换为用户的 SecretId，登录访问管理控制台查看密钥，https://console.cloud.tencent.com/cam/capi
        credential.secretID = self.secretId;
        // 永久密钥 SecretKey
        // sercret_key替换为用户的 SecretKey，登录访问管理控制台查看密钥，https://console.cloud.tencent.com/cam/capi
        credential.secretKey = self.secretKey;
        // 使用永久密钥计算签名
        QCloudAuthentationV5Creator* creator = [[QCloudAuthentationV5Creator alloc]
                                                initWithCredential:credential];
        creator.shouldSignedList = shouldSignHeaders;
        QCloudSignature* signature =  [creator signatureForData:urlRequst];
        continueBlock(signature, nil);
        return;
    }
    
    // 临时秘钥
    if(self.isScopeLimitCredential){        
        NSArray<STSCredentialScope *> * stsScopesArray = [self convertSTSCredentialScope:[request scopesArray]];
        
        // QCloudGetPresignedURLRequest特殊处理，原生没有返回scopesArray
        if([request isMemberOfClass:[QCloudGetPresignedURLRequest class]]){
            QCloudGetPresignedURLRequest * getPresignedURLRequest = (QCloudGetPresignedURLRequest *)request;
            NSMutableArray<STSCredentialScope *> *array = [NSMutableArray array];
            NSString * region = getPresignedURLRequest.runOnService.configuration.endpoint.regionName;
            if([getPresignedURLRequest regionName]){
                region = [getPresignedURLRequest regionName];
            }
            [array addObject:[STSCredentialScope makeWithAction:@"name/cos:GetObject"
                                                         region:region
                                                         bucket:[getPresignedURLRequest bucket]
                                                         prefix:[getPresignedURLRequest object]
            ]];
            stsScopesArray = array;
        }
        // QCloudGetBucketRequest特殊处理，原生返回的scopesArray有bug
        if([request isMemberOfClass:[QCloudGetBucketRequest class]]){
            QCloudGetBucketRequest * getBucketRequest = (QCloudGetBucketRequest *)request;
            if([getBucketRequest prefix] == nil || [getBucketRequest prefix] == NULL){
                stsScopesArray[0].prefix = @"";
            } else {
                stsScopesArray[0].prefix = [getBucketRequest prefix];
            }
        }
        
        [self.flutterCosApi fetchScopeLimitCredentialsStsCredentialScopes:stsScopesArray
                                                               completion:^(SessionQCloudCredentials * _Nullable credentials, FlutterError * _Nullable error) {
            if(credentials != nil){
                QCloudCredential* credential = [QCloudCredential new];
                // 临时密钥 SecretId
                // sercret_id替换为用户的 SecretId，登录访问管理控制台查看密钥，https://console.cloud.tencent.com/cam/capi
                credential.secretID = [credentials secretId];
                // 临时密钥 SecretKey
                // sercret_key替换为用户的 SecretKey，登录访问管理控制台查看密钥，https://console.cloud.tencent.com/cam/capi
                credential.secretKey = [credentials secretKey];
                // 临时密钥 Token
                // 如果使用永久密钥不需要填入token，如果使用临时密钥需要填入，临时密钥生成和使用指引参见https://cloud.tencent.com/document/product/436/14048
                credential.token =  [credentials token];
                /** 强烈建议返回服务器时间作为签名的开始时间, 用来避免由于用户手机本地时间偏差过大导致的签名不正确(参数startTime和expiredTime单位为秒)
                 */
                credential.startDate = [NSDate dateWithTimeIntervalSince1970: [[credentials startTime] doubleValue]]; // 单位是秒
                // expiredTime 在 IDL 中是非空 int，pigeon 25.x 起为裸 NSInteger，不能再发 doubleValue 消息
                credential.expirationDate = [NSDate dateWithTimeIntervalSince1970: (double)[credentials expiredTime]];// 单位是秒
                
                QCloudAuthentationV5Creator* creator = [[QCloudAuthentationV5Creator alloc]
                                                        initWithCredential:credential];
                creator.shouldSignedList = shouldSignHeaders;
                QCloudSignature* signature =  [creator signatureForData:urlRequst];
                continueBlock(signature, nil);
            } else {
                continueBlock(nil, [CosPluginSignatureProvider nsErrorFromFlutterError:error]);
        }
        }];
    } else {
        [self.credentialFenceQueue performAction:^(QCloudAuthentationCreator *creator,
                                                   NSError *error) {
            if (error) {
                continueBlock(nil, error);
            } else {
                // 注意 这里不要对urlRequst 进行copy以及mutableCopy操作
                if ([creator isKindOfClass:QCloudAuthentationV5Creator.class]) {
                    ((QCloudAuthentationV5Creator *)creator).shouldSignedList = shouldSignHeaders;
                }
                QCloudSignature* signature =  [creator signatureForData:urlRequst];
                continueBlock(signature, nil);
            }
        }];
    }
}

- (void)forceInvalidationCredential {
    if(self.credentialFenceQueue){
        // 获取当前时间
        NSDate *now = [NSDate date];
        // 计算当前时间减去一天的时间
        NSTimeInterval oneDay = 24 * 60 * 60;
        NSDate *yesterday = [now dateByAddingTimeInterval:-oneDay];
        
        // 将当前秘钥的过期时间指定为昨天 使其失效
        self.credentialFenceQueue.authentationCreator.credential.expirationDate = yesterday;
    }
}

- (void)fenceQueue:(QCloudCredentailFenceQueue *)queue requestCreatorWithContinue:(QCloudCredentailFenceQueueContinue)continueBlock {
    //这里同步从◊后台服务器获取临时密钥，强烈建议将获取临时密钥的逻辑放在这里，最大程度上保证密钥的可用性
    [self.flutterCosApi fetchSessionCredentialsWithCompletion:^(SessionQCloudCredentials *_Nullable credentials, FlutterError *_Nullable error) {
        if(credentials != nil){
            QCloudCredential* credential = [QCloudCredential new];
            // 临时密钥 SecretId
            // sercret_id替换为用户的 SecretId，登录访问管理控制台查看密钥，https://console.cloud.tencent.com/cam/capi
            credential.secretID = [credentials secretId];
            // 临时密钥 SecretKey
            // sercret_key替换为用户的 SecretKey，登录访问管理控制台查看密钥，https://console.cloud.tencent.com/cam/capi
            credential.secretKey = [credentials secretKey];
            // 临时密钥 Token
            // 如果使用永久密钥不需要填入token，如果使用临时密钥需要填入，临时密钥生成和使用指引参见https://cloud.tencent.com/document/product/436/14048
            credential.token =  [credentials token];
            /** 强烈建议返回服务器时间作为签名的开始时间, 用来避免由于用户手机本地时间偏差过大导致的签名不正确(参数startTime和expiredTime单位为秒)
             */
            credential.startDate = [NSDate dateWithTimeIntervalSince1970: [[credentials startTime] doubleValue]]; // 单位是秒
            // expiredTime 在 IDL 中是非空 int，pigeon 25.x 起为裸 NSInteger，不能再发 doubleValue 消息
            credential.expirationDate = [NSDate dateWithTimeIntervalSince1970: (double)[credentials expiredTime]];// 单位是秒

            QCloudAuthentationV5Creator* creator = [[QCloudAuthentationV5Creator alloc]
                                                    initWithCredential:credential];
            continueBlock(creator, nil);
        } else {
            // 修复既有缺陷：原先 credentials 为 nil 时不调用 continueBlock，
            // 请求要一直卡到 QCloudCredentailFenceQueue 的 120s 超时才报一个
            // 笼统错误（且该超时定时器挂在 main runloop 上，主线程被阻塞时
            // 可能根本不触发）。这里显式回传错误，做到快速失败并保留原始信息。
            continueBlock(nil, [CosPluginSignatureProvider nsErrorFromFlutterError:error]);
        }
    }
    ];
}

-(nonnull NSArray<STSCredentialScope *> *)convertSTSCredentialScope:(nonnull NSArray<NSMutableDictionary *> *) scopesArray {
    NSMutableArray<STSCredentialScope *> *array = [NSMutableArray array];
    if(scopesArray != nil && [scopesArray count]>0){
        for(NSMutableDictionary *scope in scopesArray) {
            [array addObject:[STSCredentialScope makeWithAction:[scope objectForKey: @"action"]
                                                         region:[scope objectForKey: @"region"]
                                                         bucket:[scope objectForKey: @"bucket"]
                                                         prefix:[scope objectForKey: @"prefix"]
                             ]];
        }
    }
    return array;
}

@end
