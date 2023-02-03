//
//  CosPluginSignatureProvider.h
//  Pods
//
//  Created by jordanqin on 2022/12/8.
//

#ifndef CosSignatureProvider_h
#define CosSignatureProvider_h


#endif /* CosSignatureProvider_h */

#import <QCloudCOSXML/QCloudCOSXML.h>
#import <Flutter/Flutter.h>
#import "pigeon.h"

NS_ASSUME_NONNULL_BEGIN

@interface CosPluginSignatureProvider : NSObject<QCloudSignatureProvider, QCloudCredentailFenceQueueDelegate>
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)makeWithFlutterCosApi:(nonnull FlutterCosApi *)flutterCosApi
                                    secretId:(nullable NSString *)secretId
                                   secretKey:(nullable NSString *)secretKey;

@property (nonatomic, strong, nonnull) QCloudCredentailFenceQueue* credentialFenceQueue;
@property (nonatomic, strong, nonnull) FlutterCosApi* flutterCosApi;
@property (nonatomic, copy, nullable) NSString* secretId;
@property (nonatomic, copy, nullable) NSString* secretKey;

@end

NS_ASSUME_NONNULL_END
