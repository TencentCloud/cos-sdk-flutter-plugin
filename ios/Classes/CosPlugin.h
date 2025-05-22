#import <Flutter/Flutter.h>
#import "pigeon.h"
#import <QCloudCOSXML/QCloudCOSXML.h>
#import <Foundation/Foundation.h>



@interface QCloudServiceConfiguration (Headers)
@property (nonatomic, strong) NSArray *noSignHeaders;
@property (nonatomic, strong) NSDictionary *customHeaders;
@end

@interface QCloudCOSXMLDownloadObjectRequest (DownloadObjectRequestExt)
@property (nonatomic, strong) NSNumber *resultCallbackKey;
@property (nonatomic, strong) NSNumber *progressCallbackKey;
@property (nonatomic, strong) NSNumber *stateCallbackKey;
@property (nonatomic, strong) NSNumber *localDownloaded;
@end

@interface QCloudCOSXMLUploadObjectRequest (UploadObjectRequestExt)
@property (nonatomic, strong) NSNumber *resultCallbackKey;
@property (nonatomic, strong) NSNumber *progressCallbackKey;
@property (nonatomic, strong) NSNumber *stateCallbackKey;
@property (nonatomic, strong) NSNumber *iinitMultipleUploadCallbackKey;
@property (nonatomic, strong) NSData *resmeData;
@end

@interface CosPlugin : NSObject<FlutterPlugin, CosApi, CosServiceApi, CosTransferApi>
@end
