import 'dart:collection';
import 'dart:typed_data';

import 'pigeon.dart';
import 'transfer_task.dart';

import 'enums.dart';
import 'exceptions.dart';

class CosTransferManger {
  late final String _transferKey;

  CosTransferManger(this._transferKey);

  final CosTransferApi _transferApi = CosTransferApi();

  //回调map
  final Map<int, ResultListener> _resultListeners = HashMap();
  final Map<int, StateCallBack> _stateCallBacks = HashMap();
  final Map<int, ProgressCallBack> _progressCallBacks = HashMap();
  final Map<int, InitMultipleUploadCallback> _initMultipleUploadCallbacks = HashMap();

  Future<TransferTask> upload(String bucket, String cosPath,
      {String? region,
      String? filePath,
      Uint8List? byteArr,
      String? uploadId,
      String? stroageClass,
      int? trafficLimit,
      String? callbackParam,
      Map<String, String>? customHeaders,
      List<String?>? noSignHeaders,
      ResultListener? resultListener,
      StateCallBack? stateCallback,
      ProgressCallBack? progressCallBack,
      InitMultipleUploadCallback? initMultipleUploadCallback }) async {
    if (filePath == null && byteArr == null) {
      throw IllegalArgumentException("filePath or byteArr cannot be empty");
    }

    int? resultCallbackKey = _addResultListener(resultListener);
    int? stateCallbackKey = _addStateCallBack(stateCallback);
    int? progressCallbackKey = _addProgressCallBack(progressCallBack);
    int? initMultipleUploadCallbackKey = _addInitMultipleUploadCallback(initMultipleUploadCallback);

    String taskId = await _transferApi.upload(
        _transferKey,
        bucket,
        cosPath,
        region,
        filePath,
        byteArr,
        uploadId,
        stroageClass,
        trafficLimit,
        callbackParam,
        customHeaders,
        noSignHeaders,
        resultCallbackKey,
        stateCallbackKey,
        progressCallbackKey,
        initMultipleUploadCallbackKey);

    return TransferTask(_transferKey, taskId, _transferApi);
  }

  Future<TransferTask> download(String bucket, String cosPath, String savePath,
      {String? region,
      String? versionId,
      int? trafficLimit,
      Map<String, String>? customHeaders,
      List<String?>? noSignHeaders,
      ResultListener? resultListener,
      StateCallBack? stateCallback,
      ProgressCallBack? progressCallBack}) async {
    int? resultCallbackKey = _addResultListener(resultListener);
    int? stateCallbackKey = _addStateCallBack(stateCallback);
    int? progressCallbackKey = _addProgressCallBack(progressCallBack);

    String taskId = await _transferApi.download(
        _transferKey,
        bucket,
        cosPath,
        region,
        savePath,
        versionId,
        trafficLimit,
        customHeaders,
        noSignHeaders,
        resultCallbackKey,
        stateCallbackKey,
        progressCallbackKey);

    return TransferTask(_transferKey, taskId, _transferApi);
  }

  void runResultSuccessCallBack(int key, Map<String?, String?>? header, CosXmlResult? result) {
    _resultListeners[key]?.successCallBack.call(header, result);
    _resultListeners.remove(key);
    _stateCallBacks.remove(key);
    _progressCallBacks.remove(key);
  }

  void runResultFailCallBack(int key, CosXmlClientException? clientException,
      CosXmlServiceException? serviceException) {
    _resultListeners[key]?.failCallBack.call(clientException, serviceException);
    _resultListeners.remove(key);
    _stateCallBacks.remove(key);
    _progressCallBacks.remove(key);
  }

  void runStateCallBack(int key, String state) {
    _stateCallBacks[key]?.call(TransferState.values.byName(state));
  }

  void runProgressCallBack(int key, int complete, int target) {
    _progressCallBacks[key]?.call(complete, target);
  }

  void runInitMultipleUploadCallback(int key, String bucket, String cosKey, String uploadId) {
    _initMultipleUploadCallbacks[key]?.call(bucket, cosKey, uploadId);
  }

  /// 生成回调key并加入回调map
  int? _addResultListener(ResultListener? resultListener) {
    if (resultListener != null) {
      int resultCallbackKey = resultListener.hashCode;
      _resultListeners[resultCallbackKey] = resultListener;
      return resultCallbackKey;
    }
    return null;
  }

  int? _addStateCallBack(StateCallBack? stateCallback) {
    if (stateCallback != null) {
      int stateCallbackKey = stateCallback.hashCode;
      _stateCallBacks[stateCallbackKey] = stateCallback;
      return stateCallbackKey;
    }
    return null;
  }

  int? _addProgressCallBack(ProgressCallBack? progressCallBack) {
    if (progressCallBack != null) {
      int progressCallbackKey = progressCallBack.hashCode;
      _progressCallBacks[progressCallbackKey] = progressCallBack;
      return progressCallbackKey;
    }
    return null;
  }

  int? _addInitMultipleUploadCallback(InitMultipleUploadCallback? initMultipleUploadCallback) {
    if (initMultipleUploadCallback != null) {
      int initMultipleUploadCallbackKey = initMultipleUploadCallback.hashCode;
      _initMultipleUploadCallbacks[initMultipleUploadCallbackKey] = initMultipleUploadCallback;
      return initMultipleUploadCallbackKey;
    }
    return null;
  }
}

/// 成功回调
typedef ResultSuccessCallBack = Function(Map<String?, String?>? header, CosXmlResult? result);

/// 失败回调
typedef ResultFailCallBack = Function(CosXmlClientException? clientException,
    CosXmlServiceException? serviceException);

/// 请求结果回调
class ResultListener {
  final ResultSuccessCallBack successCallBack;
  final ResultFailCallBack failCallBack;

  ResultListener(this.successCallBack, this.failCallBack);
}

/// 传输状态变化回调
/// @param state 传输状态
typedef StateCallBack = Function(TransferState state);

/// 进度回调方法
/// @param complete 已上传或者已下载的数据长度
/// @param target 总的数据长度
typedef ProgressCallBack = Function(int complete, int target);

/// 分块上传初始化完成回调方法
/// @param bucket 分片上传的目标 Bucket，由用户自定义字符串和系统生成appid数字串由中划线连接而成，如：mybucket-1250000000.
/// @param cosKey Object 的名称
/// @param uploadId 在后续上传中使用的 ID
typedef InitMultipleUploadCallback = Function(String bucket, String cosKey, String uploadId);

