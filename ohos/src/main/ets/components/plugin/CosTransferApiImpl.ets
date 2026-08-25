/*
 * Copyright (c) 2026 Tencent Cloud. All rights reserved.
 * Licensed under the Apache License, Version 2.0 (the "License").
 */

/**
 * `CosTransferApi` 的鸿蒙实现（upload / download / pause / resume / cancel）
 * 以及四类回调（result / state / progress / initMultipleUpload）的回传。
 *
 * 行为基准是 Android 侧 `CosPlugin.java` 的 `upload/download/pause/resume/cancel`
 * 与 `setTaskListener()`。
 *
 * ## 三个必须知道的平台差异
 *
 * **T1 —— pause()/cancel() 会走 onFail，必须拦截（否则就是功能 bug）**
 * 鸿蒙 `UploadTask.pause()` 内部直接 `this.onFail(request, new CosTransferPauseError())`，
 * `cancel()` 则是 `this.onFail(request, new QCloudUserCancelError())`；
 * `DownloadTask` 同理。也就是说用户点一下"暂停"，SDK 就会触发一次失败回调。
 * 若原样上抛给 Flutter 的 `resultFailCallback`，用户会收到"传输失败"。
 * 因此这里用 `ErrorConverter.isUserPausedOrCancelled()` 拦截，**只**更新任务表，
 * 不回调 Flutter 的失败通道 —— Flutter 侧靠 `stateCallback(PAUSED/CANCELED)` 感知。
 * Android 侧不存在这个问题（pause 不触发 onFail）。
 *
 * ℹ️ **T1 的连带影响**：
 * `TransferTask` 的 `private failed` 是「一次传输周期内只对外报一次失败」的闩。
 * 由于 `pause()` 本身会走一次 `onFail`，该闩会被合上；早期版本中它**永不复位**，
 * 导致 `resume()` 后再遇到真实失败时 `onResult.onFail` 不再触发，
 * Flutter 的 `resultFailCallback` 收不到。
 * SDK 已在 `UploadTask.resume()` / `DownloadTask.resume()` 中调用
 * `resetFailedFlag()` 复位，此问题不再存在。
 * （若回退到 1.2.4 及更早版本，仍需以 `stateCallback` 的 FAILED 为准。）
 *
 * **T3 —— 简单上传（无 uploadId）调 resume() 会抛错**
 * 见 `UploadTask.resume()`：`if (this.uploadId) {...} else { onFail(CosInvalidArgumentError) }`。
 * 而 Android 的简单上传 resume 行为是**从 0 重传**。这里对齐 Android：
 * 检测到任务没有 uploadId 时改调 `start()` 重新上传，而不是让它报错。见 resume()。
 *
 * **T5 —— download() 不接受 TransferConfig**
 * `CosXmlBaseService.download(getObjectRequest)` 只有一个参数，
 * 而 `upload(putObjectRequest, uploadId?, config?)` 有三个。
 * 因此 `registerTransferManger` 传入的 TransferConfig（分块大小/简单上传阈值）
 * **只对上传生效**，下载侧完全无效。见 download()。
 */

import {
  PutObjectRequest,
  GetObjectRequest,
  UploadTask,
  DownloadTask,
  CosXmlUploadTaskResult,
  CosXmlDownloadTaskResult,
  TransferState,
  HttpProgress,
} from '@tencentcloud/cos';
import buffer from '@ohos.buffer';
import {
  CosTransferApi,
  FlutterCosApi,
  SessionQCloudCredentials,
  CosXmlResult as PigeonCosXmlResult,
} from './Pigeon';
import { CosPluginSharedState } from './CosPlugin';
import { TransferEntry } from './CosServiceRegistry';
import { TransferTaskRegistry } from './TransferTaskRegistry';
import { ErrorConverter } from './ErrorConverter';
import { ModelConverter } from './ModelConverter';
import { StateConverter } from './StateConverter';
import { CredentialBridge } from './CredentialBridge';
import { PluginLog } from './PluginLog';
import { Reply } from '@ohos/flutter_ohos/src/main/ets/plugin/common/BasicMessageChannel';

/** 对齐 Android `COSRequestHeaderKey.X_COS_STORAGE_CLASS_` */
const HEADER_STORAGE_CLASS: string = 'x-cos-storage-class';
/** 对齐 Android `BasePutObjectRequest.setTrafficLimit` / `GetObjectRequest.setTrafficLimit` */
const HEADER_TRAFFIC_LIMIT: string = 'x-cos-traffic-limit';
/** 对齐 Android `request.setRequestHeaders("x-cos-callback", base64, false)` */
const HEADER_CALLBACK: string = 'x-cos-callback';

/**
 * FlutterApi 通知型回调的空 Reply（与 CosPlugin.voidReply 同义）。
 *
 * 这里重复一份而不是从 CosPlugin 导出：`voidReply` 在 CosPlugin.ets 里是模块私有函数，
 * 把它导出会扩大 CosPlugin 的对外面（该文件的默认导出是插件主类）。
 */
function voidReply(what: string): Reply<void> {
  return {
    reply: (result: ESObject): void => {
      if (result !== undefined && result !== null) {
        PluginLog.error(`flutter api callback failed (${what}): ${result}`);
      }
    },
  };
}

export class CosTransferApiImpl extends CosTransferApi {
  private readonly shared: CosPluginSharedState;
  private readonly tasks: TransferTaskRegistry;

  constructor(shared: CosPluginSharedState, tasks: TransferTaskRegistry) {
    super();
    this.shared = shared;
    this.tasks = tasks;
  }

  private get flutterApi(): FlutterCosApi {
    return this.shared.flutterCosApi;
  }

  // ------------------------------------------------------------------
  // upload
  // ------------------------------------------------------------------

  /**
   * 上传（文件路径或字节数组）。
   *
   * ⚠️⚠️ **`byteArr` 的真实运行时类型是 `Uint8Array`，不是 `number[]`**。
   * pigeon 把 Dart 的 `Uint8List` 在 ArkTS 侧声明成了 `number[]`，但 codec
   * 实际读出来的是 type id 8 的 `Uint8Array`（Phase 0 已实证）。
   * ArkTS 的 `as` 只是编译期断言、运行时不转换，所以：
   *  - **不要**按数组语义遍历（`Array.isArray(byteArr)` 返回 **false**）；
   *  - 取 ArrayBuffer 要走 `(byteArr as ESObject as Uint8Array).buffer`。
   * 鸿蒙 `PutObjectRequest` 的 body 接受 `string | ArrayBuffer`，所以这里传 `.buffer`。
   *
   * ⚠️ `uploadId` 语义：鸿蒙 `service.upload(request, uploadId, config)` 的第二参就是
   * 续传用的 uploadId，与 Android `transferManager.upload(request, uploadId)` 一致。
   *
   * ⚠️ 同步返回 taskId：pigeon 侧该方法是同步的（返回 string），
   * 所以这里生成 taskId、挂好回调、`task.start()` 之后立刻返回，
   * 实际结果通过四类回调异步回传。这与 Android 完全一致。
   */
  upload(
    transferKey: string,
    bucket: string,
    cosPath: string,
    region: string | undefined,
    filePath: string | undefined,
    byteArr: number[] | undefined,
    uploadId: string | undefined,
    stroageClass: string | undefined,
    trafficLimit: number | undefined,
    callbackParam: string | undefined,
    customHeaders: Map<string, string> | undefined,
    noSignHeaders: Array<string | undefined> | undefined,
    resultCallbackKey: number | undefined,
    stateCallbackKey: number | undefined,
    progressCallbackKey: number | undefined,
    initMultipleUploadCallbackKey: number | undefined,
    sessionCredentials: SessionQCloudCredentials | undefined,
  ): string {
    // 未注册时抛出，由 pigeon 的 onMessage try/catch 包成 channel 错误回传，
    // 与 Android 的 getTransferManager() 抛 IllegalArgumentException 一致。
    const entry: TransferEntry = this.shared.registry.getTransferEntry(transferKey);

    // --- body：文件路径优先，与 Android 的 if (filePath != null) 分支一致 ---
    let body: string | ArrayBuffer | undefined = undefined;
    if (filePath !== undefined && filePath !== null) {
      body = filePath;
    } else if (byteArr !== undefined && byteArr !== null) {
      // 见方法注释：运行时是 Uint8Array
      body = CosTransferApiImpl.toArrayBuffer(byteArr as ESObject as Uint8Array);
    }

    const request: PutObjectRequest = new PutObjectRequest(bucket, cosPath, body);
    if (region !== undefined && region !== null) {
      request.region = region;
    }
    if (sessionCredentials !== undefined && sessionCredentials !== null) {
      request.credential = CredentialBridge.toQCloudCredential(sessionCredentials);
    }
    if (entry.signInUrl !== undefined && entry.signInUrl !== null) {
      request.isSignedInURL = entry.signInUrl;
    }
    if (stroageClass !== undefined && stroageClass !== null) {
      // 鸿蒙 PutObjectRequest 无 setStroageClass()，直接设 header
      // （Android 的 setStroageClass 内部也只是 addHeader(x-cos-storage-class, value)）。
      // 这里不做 COSStorageClass 枚举校验：Flutter 侧传的就是字符串，
      // 校验反而会把服务端将来新增的存储类型挡掉。
      request.addHeader(HEADER_STORAGE_CLASS, stroageClass);
    }
    if (trafficLimit !== undefined && trafficLimit !== null) {
      // 同上，鸿蒙无 setTrafficLimit()，header 名与 Android 一致
      request.addHeader(HEADER_TRAFFIC_LIMIT, `${trafficLimit}`);
    }
    if (callbackParam !== undefined && callbackParam !== null) {
      // 对齐 Android：base64 编码后放进 x-cos-callback 头
      const encoded: string | undefined = CosTransferApiImpl.toBase64(callbackParam);
      if (encoded !== undefined) {
        request.addHeader(HEADER_CALLBACK, encoded);
      }
    }
    CosTransferApiImpl.applyCustomHeaders(request, customHeaders);
    CosTransferApiImpl.applyNoSignHeaders(request, noSignHeaders);

    const task: UploadTask = entry.service.upload(request, uploadId, entry.transferConfig);
    const taskId: string = this.tasks.generateTaskId();
    this.tasks.putUpload(taskId, task);

    this.bindUploadCallbacks(
      task, taskId, transferKey,
      resultCallbackKey, stateCallbackKey, progressCallbackKey, initMultipleUploadCallbackKey,
    );
    task.start();
    return taskId;
  }

  /**
   * 挂上传任务的四类回调。
   *
   * ⚠️ 这里是 **T1** 的落点：`onFail` 必须先判 `isUserPausedOrCancelled`。
   */
  private bindUploadCallbacks(
    task: UploadTask,
    taskId: string,
    transferKey: string,
    resultCallbackKey: number | undefined,
    stateCallbackKey: number | undefined,
    progressCallbackKey: number | undefined,
    initMultipleUploadCallbackKey: number | undefined,
  ): void {
    task.onResult = {
      onSuccess: (request: PutObjectRequest, result: CosXmlUploadTaskResult): void => {
        // 先从任务表移除，对齐 Android 的 taskMap.remove()
        this.tasks.remove(taskId);
        if (resultCallbackKey === undefined || resultCallbackKey === null) {
          return;
        }
        this.flutterApi.resultSuccessCallback(
          transferKey,
          resultCallbackKey!,
          ModelConverter.toHeaderMap(result.headers),
          CosTransferApiImpl.toPigeonUploadResult(result),
          voidReply('resultSuccessCallback'),
        );
      },
      onFail: (request: PutObjectRequest, error: ESObject): void => {
        // ⚠️ T1：pause()/cancel() 会走到这里，绝不能当成"传输失败"上报
        if (ErrorConverter.isUserPausedOrCancelled(error)) {
          // 暂停后还要能 resume，所以**不**从任务表移除；
          // cancel 的清理在 cancel() 方法里做。
          return;
        }
        this.tasks.remove(taskId);
        if (resultCallbackKey === undefined || resultCallbackKey === null) {
          return;
        }
        this.dispatchFailure(transferKey, resultCallbackKey!, error);
      },
    };

    if (progressCallbackKey !== undefined && progressCallbackKey !== null) {
      task.onProgress = (progress: HttpProgress): void => {
        this.flutterApi.progressCallback(
          transferKey, progressCallbackKey!, progress.complete, progress.target,
          voidReply('progressCallback'),
        );
      };
    }

    if (stateCallbackKey !== undefined && stateCallbackKey !== null) {
      task.onState = (state: TransferState): void => {
        this.flutterApi.stateCallback(
          transferKey, stateCallbackKey!, StateConverter.toFlutterStateName(state),
          voidReply('stateCallback'),
        );
      };
    }

    if (initMultipleUploadCallbackKey !== undefined && initMultipleUploadCallbackKey !== null) {
      // ⚠️ 鸿蒙 initCallBack 只回 uploadId 一个字符串，
      // 而 pigeon 的 initMultipleUploadCallback 要 bucket / cosKey / uploadId 三个。
      // bucket 与 cosKey 从 request 上取（与 Android 的 InitiateMultipartUpload
      // 里的 bucket/key 同源，都是本次上传的目标），语义等价。
      task.initCallBack = (id: string): void => {
        this.flutterApi.initMultipleUploadCallback(
          transferKey,
          initMultipleUploadCallbackKey!,
          task.request.bucket ?? '',
          task.request.cosPath,
          id,
          voidReply('initMultipleUploadCallback'),
        );
      };
    }
  }

  // ------------------------------------------------------------------
  // download
  // ------------------------------------------------------------------

  /**
   * 下载。
   *
   * ⚠️ **T5：鸿蒙的 `download()` 不接受 TransferConfig**
   * （`CosXmlBaseService.download(getObjectRequest): DownloadTask` 只有一个参数）。
   * 也就是说 `registerTransferManger` 里配的 `divisionForUpload` / `sliceSizeForUpload`
   * 对下载**完全不生效** —— 从字段名也能看出这两个本来就是上传侧参数，
   * Android 侧的 TransferConfig 同样只在上传时用到分块参数，故实际差异有限。
   *
   * ⚠️ savePath 的处理与 Android 不同（结果等价）：
   * Android 要把 savePath 拆成「目录 + 文件名」两个参数
   * （`GetObjectRequest(bucket, cosPath, dir, fileName)`），
   * 鸿蒙 `GetObjectRequest(bucket, cosPath, filePath)` 直接收完整路径，无需拆分。
   */
  download(
    transferKey: string,
    bucket: string,
    cosPath: string,
    region: string | undefined,
    savePath: string,
    versionId: string | undefined,
    trafficLimit: number | undefined,
    customHeaders: Map<string, string> | undefined,
    noSignHeaders: Array<string | undefined> | undefined,
    resultCallbackKey: number | undefined,
    stateCallbackKey: number | undefined,
    progressCallbackKey: number | undefined,
    sessionCredentials: SessionQCloudCredentials | undefined,
  ): string {
    const entry: TransferEntry = this.shared.registry.getTransferEntry(transferKey);
    if (entry.transferConfig !== undefined && entry.transferConfig !== null) {
      PluginLog.warnOnce(
        'download.transferConfig',
        '[platform difference] TransferConfig is IGNORED for downloads on HarmonyOS: ' +
          'CosXmlBaseService.download(request) takes no config parameter (unlike upload()). ' +
          'divisionForUpload / sliceSizeForUpload only affect uploads.',
      );
    }

    const request: GetObjectRequest = new GetObjectRequest(bucket, cosPath, savePath);
    if (region !== undefined && region !== null) {
      request.region = region;
    }
    if (sessionCredentials !== undefined && sessionCredentials !== null) {
      request.credential = CredentialBridge.toQCloudCredential(sessionCredentials);
    }
    if (entry.signInUrl !== undefined && entry.signInUrl !== null) {
      request.isSignedInURL = entry.signInUrl;
    }
    if (versionId !== undefined && versionId !== null) {
      // 鸿蒙 GetObjectRequest 无 versionId 字段，按 Android 的 query key 手动补
      request.addQuery('versionId', versionId);
    }
    if (trafficLimit !== undefined && trafficLimit !== null) {
      request.addHeader(HEADER_TRAFFIC_LIMIT, `${trafficLimit}`);
    }
    CosTransferApiImpl.applyCustomHeaders(request, customHeaders);
    CosTransferApiImpl.applyNoSignHeaders(request, noSignHeaders);

    const task: DownloadTask = entry.service.download(request);
    const taskId: string = this.tasks.generateTaskId();
    this.tasks.putDownload(taskId, task);

    this.bindDownloadCallbacks(
      task, taskId, transferKey, resultCallbackKey, stateCallbackKey, progressCallbackKey,
    );
    task.start();
    return taskId;
  }

  /**
   * 挂下载任务的三类回调（下载没有 initMultipleUpload）。
   *
   * ⚠️ 与上传的差异：`resultSuccessCallback` 的 `result` 参数传 **undefined**，
   * 对齐 Android 的 `flutterCosApi.resultSuccessCallback(transferKey, key, header, null, ...)`
   * —— pigeon 的 `CosXmlResult`（eTag/accessUrl/callbackResult）是为上传结果设计的，
   * 下载侧 Flutter 只消费 header。
   */
  private bindDownloadCallbacks(
    task: DownloadTask,
    taskId: string,
    transferKey: string,
    resultCallbackKey: number | undefined,
    stateCallbackKey: number | undefined,
    progressCallbackKey: number | undefined,
  ): void {
    task.onResult = {
      onSuccess: (request: GetObjectRequest, result: CosXmlDownloadTaskResult): void => {
        this.tasks.remove(taskId);
        if (resultCallbackKey === undefined || resultCallbackKey === null) {
          return;
        }
        this.flutterApi.resultSuccessCallback(
          transferKey,
          resultCallbackKey!,
          ModelConverter.toHeaderMap(result.headers),
          undefined,
          voidReply('resultSuccessCallback'),
        );
      },
      onFail: (request: GetObjectRequest, error: ESObject): void => {
        // ⚠️ T1：同 upload，pause()/cancel() 会走到这里
        if (ErrorConverter.isUserPausedOrCancelled(error)) {
          return;
        }
        this.tasks.remove(taskId);
        if (resultCallbackKey === undefined || resultCallbackKey === null) {
          return;
        }
        this.dispatchFailure(transferKey, resultCallbackKey!, error);
      },
    };

    if (progressCallbackKey !== undefined && progressCallbackKey !== null) {
      task.onProgress = (progress: HttpProgress): void => {
        this.flutterApi.progressCallback(
          transferKey, progressCallbackKey!, progress.complete, progress.target,
          voidReply('progressCallback'),
        );
      };
    }

    if (stateCallbackKey !== undefined && stateCallbackKey !== null) {
      task.onState = (state: TransferState): void => {
        this.flutterApi.stateCallback(
          transferKey, stateCallbackKey!, StateConverter.toFlutterStateName(state),
          voidReply('stateCallback'),
        );
      };
    }
  }

  // ------------------------------------------------------------------
  // pause / resume / cancel
  // ------------------------------------------------------------------

  /**
   * 暂停。
   *
   * 注意**不**从任务表移除（要留着 resume），与 Android 一致。
   * 调用后 SDK 会触发一次 onFail(CosTransferPauseError)，已在回调里被 T1 拦截。
   */
  pause(taskId: string, transferKey: string): void {
    const upload: UploadTask | undefined = this.tasks.getUpload(taskId);
    if (upload !== undefined) {
      upload!.pause();
      return;
    }
    const download: DownloadTask | undefined = this.tasks.getDownload(taskId);
    if (download !== undefined) {
      download!.pause();
      return;
    }
    // 对齐 Android：找不到任务时抛出（Android 是 `throw new IllegalArgumentException()`）
    // 任务已终结（成功/失败后从任务表移除）时静默返回，不抛异常。
    // 这类操作应当是幂等的：用户在传输刚完成的瞬间点"取消"就会走到这里。
    // Android 与 iOS 也已统一为此行为。
    PluginLog.info(`transfer task already finished, ignore: taskId=${taskId}`);
  }

  /**
   * 继续。
   *
   * ⚠️ **T3：简单上传（无 uploadId）在鸿蒙调 `resume()` 会抛 `CosInvalidArgumentError`**
   * （`UploadTask.resume()` 的 else 分支：
   * `onFail(new CosInvalidArgumentError("Upload Id is empty, upload resumption failed"))`）。
   * 而 Android 的简单上传 resume 语义是**从 0 重传**。
   *
   * 处置：检测到 `task.uploadId` 为空时改调 `start()` —— 这正是"从 0 重传"，
   * 与 Android 行为一致，且避免了用户点"继续"却收到一个失败回调。
   * （`UploadTask.start()` 会重新走 executeTask()，简单上传就是重新 putObject。）
   *
   * 下载侧无此问题：`DownloadTask.resume()` 内部就是 `this.start()`，
   * 且 SDK 用 preferences 持久化了断点，天然支持续传。
   */
  resume(taskId: string, transferKey: string): void {
    const upload: UploadTask | undefined = this.tasks.getUpload(taskId);
    if (upload !== undefined) {
      const task: UploadTask = upload!;
      if (task.uploadId === undefined || task.uploadId === null || task.uploadId!.length === 0) {
        // T3：简单上传没有 uploadId，走重传而不是让 SDK 抛错
        PluginLog.warnOnce(
          'resume.simpleUpload',
          '[platform difference] resume() on a simple (non-multipart) upload restarts the ' +
            'transfer from byte 0 on HarmonyOS. The SDK\'s UploadTask.resume() would otherwise ' +
            'fail with CosInvalidArgumentError("Upload Id is empty"). This matches the Android ' +
            'behaviour, but the already-transferred bytes are re-sent.',
        );
        task.start();
        return;
      }
      task.resume();
      return;
    }
    const download: DownloadTask | undefined = this.tasks.getDownload(taskId);
    if (download !== undefined) {
      download!.resume();
      return;
    }
    // 任务已终结（成功/失败后从任务表移除）时静默返回，不抛异常。
    // 这类操作应当是幂等的：用户在传输刚完成的瞬间点"取消"就会走到这里。
    // Android 与 iOS 也已统一为此行为。
    PluginLog.info(`transfer task already finished, ignore: taskId=${taskId}`);
  }

  /**
   * 取消。
   *
   * 取消后任务不可恢复，故直接从任务表移除。
   * SDK 会触发 onFail(QCloudUserCancelError)，同样已被 T1 拦截。
   *
   * ⚠️ `UploadTask.cancel()` / `DownloadTask.cancel()` 都是 **async**（返回 Promise），
   * 但 pigeon 侧本方法是同步 void。这里不 await —— 取消是"发起即生效"的语义
   * （内部会先 updateState(Canceled) 再做清理），Flutter 侧靠 stateCallback 感知。
   * 显式忽略 Promise 以免 ArkTS 报未处理的 rejection。
   */
  cancel(taskId: string, transferKey: string): void {
    const upload: UploadTask | undefined = this.tasks.getUpload(taskId);
    if (upload !== undefined) {
      this.tasks.remove(taskId);
      upload!.cancel().catch((e: ESObject) => {
        PluginLog.error(`cancel upload task failed: ${e}`);
      });
      return;
    }
    const download: DownloadTask | undefined = this.tasks.getDownload(taskId);
    if (download !== undefined) {
      this.tasks.remove(taskId);
      download!.cancel().catch((e: ESObject) => {
        PluginLog.error(`cancel download task failed: ${e}`);
      });
      return;
    }
    // 任务已终结（成功/失败后从任务表移除）时静默返回，不抛异常。
    // 这类操作应当是幂等的：用户在传输刚完成的瞬间点"取消"就会走到这里。
    // Android 与 iOS 也已统一为此行为。
    PluginLog.info(`transfer task already finished, ignore: taskId=${taskId}`);
  }

  // ------------------------------------------------------------------
  // 内部工具
  // ------------------------------------------------------------------

  /**
   * 把一个传输失败分发到 Flutter 的 `resultFailCallback`。
   *
   * pigeon 该方法要 `clientException` / `serviceException` 两个可空参数，
   * 与 Android 一样「二选一」：服务端错误填 serviceException，其余填 clientException。
   */
  private dispatchFailure(transferKey: string, resultCallbackKey: number, error: ESObject): void {
    if (ErrorConverter.isServiceError(error)) {
      this.flutterApi.resultFailCallback(
        transferKey, resultCallbackKey, undefined,
        ErrorConverter.toServiceException(error),
        voidReply('resultFailCallback'),
      );
      return;
    }
    this.flutterApi.resultFailCallback(
      transferKey, resultCallbackKey,
      ErrorConverter.toClientException(error), undefined,
      voidReply('resultFailCallback'),
    );
  }

  /**
   * 鸿蒙上传结果 → pigeon `CosXmlResult`。
   *
   * ⚠️ `callbackResult` **鸿蒙侧拿不到**：Android 的
   * `COSXMLUploadTaskResult.callbackResult`（status / callbackBody / error）
   * 来自 SDK 对 `x-cos-callback` 响应体的解析，鸿蒙 `CosXmlUploadTaskResult`
   * 只有 `eTag` / `picUploadResult` 两个扩展字段，没有 callback 结果的解析。
   * 因此这里恒为 undefined —— 用了 callbackParam 的业务在鸿蒙侧拿不到回调结果，
   * 这是 SDK 能力缺口，不做假实现。
   *
   * `accessUrl` 与 `eTag` 都是真实数据（基类 CosXmlResult.accessUrl + eTag 字段）。
   */
  private static toPigeonUploadResult(result: CosXmlUploadTaskResult): PigeonCosXmlResult {
    PluginLog.warnOnce(
      'upload.callbackResult',
      '[platform difference] CosXmlResult.callbackResult is always null on HarmonyOS: ' +
        'CosXmlUploadTaskResult exposes only eTag/picUploadResult and the SDK does not parse ' +
        'the x-cos-callback response body. eTag and accessUrl are still populated.',
    );
    return new PigeonCosXmlResult(result.eTag, result.accessUrl, undefined);
  }

  /**
   * 自定义请求头。对齐 Android 的
   * `request.setRequestHeaders(key, value, false)`（false = 不做 URL 编码）。
   */
  private static applyCustomHeaders(
    request: PutObjectRequest | GetObjectRequest,
    customHeaders: Map<string, string> | undefined,
  ): void {
    if (customHeaders === undefined || customHeaders === null) {
      return;
    }
    customHeaders.forEach((value: string, key: string) => {
      if (key !== undefined && key !== null && key.length > 0 &&
        value !== undefined && value !== null) {
        request.addHeader(key, value);
      }
    });
  }

  /** 不参与签名的请求头。对齐 Android 的 `request.addNoSignHeader(key)` */
  private static applyNoSignHeaders(
    request: PutObjectRequest | GetObjectRequest,
    noSignHeaders: Array<string | undefined> | undefined,
  ): void {
    if (noSignHeaders === undefined || noSignHeaders === null) {
      return;
    }
    noSignHeaders.forEach((key: string | undefined) => {
      if (key !== undefined && key !== null && key.length > 0) {
        request.addNoSignHeaderKey(key);
      }
    });
  }

  /**
   * `Uint8Array` → 只含该视图数据的 `ArrayBuffer`。
   *
   * ⚠️⚠️ **不能直接用 `bytes.buffer`**：`Uint8Array` 可能是某个更大 ArrayBuffer 上的
   * **视图**（`byteOffset > 0` 或 `byteLength < buffer.byteLength`）。pigeon 的
   * codec 从整条消息的 ByteBuffer 里读字节数组，很可能返回的就是这样一个视图
   * （flutter_ohos 的 `ByteBuffer.readUint8Array()` 具体是 subarray 还是 slice
   * 无法在本地源码中核实 —— 真实 flutter.har 由 flutter tool 构建 example 时才生成）。
   *
   * 若真是视图而直接取 `.buffer`，上传的就会是**整条 pigeon 消息**的字节
   * （包含方法参数等前后内容），且长度也不对 —— 这属于静默的数据损坏，
   * 排查起来极其困难。
   *
   * 因此这里按视图边界安全裁剪：
   *  - 恰好覆盖整个 buffer（最常见）→ 直接复用，零拷贝；
   *  - 否则 → `slice(byteOffset, byteOffset + byteLength)` 拷出真正的那一段。
   *
   * 这样无论底层实现是 subarray 还是 slice，结果都正确。
   */
  private static toArrayBuffer(bytes: Uint8Array): ArrayBuffer {
    const buf: ArrayBuffer = bytes.buffer as ArrayBuffer;
    if (bytes.byteOffset === 0 && bytes.byteLength === buf.byteLength) {
      return buf;
    }
    return buf.slice(bytes.byteOffset, bytes.byteOffset + bytes.byteLength);
  }

  /**
   * UTF-8 字符串 → base64。对齐 Android 的 `DigestUtils.getBase64(callbackParam)`。
   *
   * 用 `@ohos.buffer`（鸿蒙 SDK 自己算 MD5 的 base64 也是用它，见
   * foundation 的 `CryptoUtil.qcloudMd5*`），编码失败时返回 undefined 并打日志，
   * 与 Android 的 `catch (Exception ignored)` 一样不打断上传。
   */
  private static toBase64(text: string): string | undefined {
    try {
      return buffer.from(text, 'utf-8').toString('base64');
    } catch (e) {
      PluginLog.error(`failed to base64-encode callbackParam: ${e}`);
      return undefined;
    }
  }
}
