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

@implementation CosPluginSignatureProvider

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
                                                               completion:^(SessionQCloudCredentials * _Nullable credentials, NSError * _Nullable error) {
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
                credential.expirationDate = [NSDate dateWithTimeIntervalSince1970: [[credentials expiredTime] doubleValue]];// 单位是秒
                
                QCloudAuthentationV5Creator* creator = [[QCloudAuthentationV5Creator alloc]
                                                        initWithCredential:credential];
                QCloudSignature* signature =  [creator signatureForData:urlRequst];
                continueBlock(signature, nil);
            }
        }];
    } else {
        [self.credentialFenceQueue performAction:^(QCloudAuthentationCreator *creator,
                                                   NSError *error) {
            if (error) {
                continueBlock(nil, error);
            } else {
                // 注意 这里不要对urlRequst 进行copy以及mutableCopy操作
                QCloudSignature* signature =  [creator signatureForData:urlRequst];
                continueBlock(signature, nil);
            }
        }];
    }
}

- (void)fenceQueue:(QCloudCredentailFenceQueue *)queue requestCreatorWithContinue:(QCloudCredentailFenceQueueContinue)continueBlock {
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
        continueBlock(creator, nil);
        
    } else {
        //这里同步从◊后台服务器获取临时密钥，强烈建议将获取临时密钥的逻辑放在这里，最大程度上保证密钥的可用性
        [self.flutterCosApi fetchSessionCredentialsWithCompletion:^(SessionQCloudCredentials *_Nullable credentials, NSError *_Nullable error) {
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
                credential.expirationDate = [NSDate dateWithTimeIntervalSince1970: [[credentials expiredTime] doubleValue]];// 单位是秒
                
                QCloudAuthentationV5Creator* creator = [[QCloudAuthentationV5Creator alloc]
                                                        initWithCredential:credential];
                continueBlock(creator, nil);
            }
        }
        ];
    }
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
