import 'pigeon.dart';

import 'cos.dart';

class ImplFlutterCosApi extends FlutterCosApi{
  @override
  Future<SessionQCloudCredentials> fetchSessionCredentials() {
    return Cos().getFetchCredentials().fetchSessionCredentials();
  }

  @override
  void progressCallback(String transferKey, int key, int complete, int target) {
    Cos().getTransferManger(transferKey).runProgressCallBack(key, complete, target);
  }

  @override
  void resultFailCallback(String transferKey, int key, CosXmlClientException? clientException, CosXmlServiceException? serviceException) {
    Cos().getTransferManger(transferKey).runResultFailCallBack(key, clientException, serviceException);
  }

  @override
  void resultSuccessCallback(String transferKey, int key, Map<String?, String?>? header) {
    Cos().getTransferManger(transferKey).runResultSuccessCallBack(key, header);
  }

  @override
  void stateCallback(String transferKey, int key, String state) {
    Cos().getTransferManger(transferKey).runStateCallBack(key, state);
  }

  @override
  void initMultipleUploadCallback(String transferKey, int key, String bucket, String cosKey, String uploadId) {
    Cos().getTransferManger(transferKey).runInitMultipleUploadCallback(key, bucket, cosKey, uploadId);
  }
}