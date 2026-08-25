/*
 * Copyright (c) 2026 Tencent Cloud. All rights reserved.
 * Licensed under the Apache License, Version 2.0 (the "License").
 */

/**
 * `CosServiceApi` 的鸿蒙实现（18 个方法）。
 *
 * 行为基准是 Android 侧 `android/src/main/java/com/tencent/cos/flutter/plugin/CosPlugin.java`，
 * 平台差异逐条在注释中标注。
 *
 * ## 为什么是独立的类而不是写在 CosPlugin 里
 *
 * pigeon 生成的 `CosApi` / `CosServiceApi` / `CosTransferApi` 都是 **abstract class**，
 * 而 ArkTS 不支持多继承。`CosPlugin` 已经 `extends CosApi`，所以这里用
 * 「独立适配器类 + 共享状态（`CosPluginSharedState`）」的方式承载另外两个 Api，
 * 与 fork pigeon 官方 example 的做法一致。见 `CosPlugin.ets` 顶部注释。
 *
 * ## 异步与错误处理的统一约定
 *
 * 鸿蒙 SDK 全是 Promise，因此每个方法都是「构造 request → await service.xxx()
 * → result.success() / result.error()」。所有错误统一经 `ErrorConverter.toFlutterError()`
 * 转换，不自行拼 exception。
 *
 * `getServiceEntry()` 在未注册时会抛错（错误信息与 Android 逐字一致），
 * 因此每个方法都用 try/catch 把这一步也包进去，避免同步抛出打穿 pigeon 的
 * `onMessage`（那样 Flutter 侧收到的是 channel 级异常而不是 result.error）。
 */

import {
  CosXmlBaseService,
  CosXmlRequest,
  HeadObjectRequest,
  HeadObjectResult,
  DeleteObjectRequest,
  ListBucketsRequest,
  ListBucketsResult,
  ListObjectsRequest,
  ListObjectsResult,
  PutBucketRequest,
  HeadBucketRequest,
  HeadBucketResult,
  DeleteBucketRequest,
  GetBucketAccelerateRequest,
  GetBucketAccelerateResult,
  PutBucketAccelerateRequest,
  GetBucketLocationRequest,
  GetBucketLocationResult,
  GetBucketVersioningRequest,
  GetBucketVersioningResult,
  PutBucketVersioningRequest,
  PresignedUrlRequest,
  QCloudCredential,
  CosServiceError,
} from '@tencentcloud/cos';
import {
  CosServiceApi,
  Result,
  SessionQCloudCredentials,
  ListAllMyBuckets,
  BucketContents,
} from './Pigeon';
import { CosPluginSharedState } from './CosPlugin';
import { ServiceEntry } from './CosServiceRegistry';
import { ErrorConverter } from './ErrorConverter';
import { ModelConverter } from './ModelConverter';
import { CredentialBridge } from './CredentialBridge';
import { PluginLog } from './PluginLog';

/** COS 「存储桶/对象不存在」的 HTTP 状态码 */
const HTTP_NOT_FOUND: number = 404;
/**
 * 「存储桶存在但需重定向」的状态码。
 * 对齐 Android `Constants.BUCKET_REDIRECT_STATUS_CODE`，在 doesBucketExist 里视为「存在」。
 */
const HTTP_BUCKET_REDIRECT: number = 301;
/** 对齐 Android doesBucketExist：AccessDenied 说明桶存在但当前身份无权限 */
const ERROR_CODE_ACCESS_DENIED: string = 'AccessDenied';
/** 鸿蒙 `PresignedUrlRequest` 构造时默认加入 noSignHeaderKeys 的 Host 头 */
const HEADER_HOST: string = 'Host';

export class CosServiceApiImpl extends CosServiceApi {
  private readonly shared: CosPluginSharedState;

  constructor(shared: CosPluginSharedState) {
    super();
    this.shared = shared;
  }

  // ------------------------------------------------------------------
  // 内部工具
  // ------------------------------------------------------------------

  private getEntry(serviceKey: string): ServiceEntry {
    return this.shared.registry.getServiceEntry(serviceKey);
  }

  /**
   * 统一的 request 初始化：region / 请求级凭证 / signInUrl。
   *
   * 对齐 Android 的 `setRequestCredential()` + 各方法里的 `setRegion()`。
   * `signInUrl` 是鸿蒙的 request 级字段（config 级没有），故在这里逐 request 赋值，
   * 见 `ConfigConverter.ServiceConfigBundle` 的说明。
   */
  private prepare(
    request: CosXmlRequest,
    entry: ServiceEntry,
    region: string | undefined,
    sessionCredentials: SessionQCloudCredentials | undefined,
  ): void {
    if (region !== undefined && region !== null) {
      request.region = region;
    }
    if (sessionCredentials !== undefined && sessionCredentials !== null) {
      // 请求级凭证优先级高于 service 级 credentialCallBack（鸿蒙与 Android 一致）
      request.credential = CredentialBridge.toQCloudCredential(sessionCredentials);
    }
    if (entry.signInUrl !== undefined && entry.signInUrl !== null) {
      request.isSignedInURL = entry.signInUrl;
    }
  }

  /** 从任意 error 里取 HTTP 状态码，取不到返回 -1 */
  private static httpCodeOf(error: ESObject): number {
    if (error instanceof CosServiceError) {
      return (error as CosServiceError).httpCode;
    }
    return -1;
  }

  /** 从任意 error 里取服务端 errorCode（如 AccessDenied），取不到返回 undefined */
  private static errorCodeOf(error: ESObject): string | undefined {
    if (error instanceof CosServiceError) {
      return (error as CosServiceError).code;
    }
    return undefined;
  }

  // ------------------------------------------------------------------
  // 对象级
  // ------------------------------------------------------------------

  /**
   * HEAD Object。成功时把响应头回传给 Flutter（对齐 Android 的 `simplifyHeader`）。
   */
  headObject(
    serviceKey: string,
    bucket: string,
    region: string | undefined,
    cosPath: string,
    versionId: string | undefined,
    sessionCredentials: SessionQCloudCredentials | undefined,
    result: Result<Map<string | undefined, string | undefined>>,
  ): void {
    try {
      const entry: ServiceEntry = this.getEntry(serviceKey);
      const request: HeadObjectRequest = new HeadObjectRequest(bucket, cosPath);
      this.prepare(request, entry, region, sessionCredentials);
      if (versionId !== undefined && versionId !== null) {
        // 鸿蒙 HeadObjectRequest 无 versionId 字段，按 Android 的 query key
        // （`queryParameters.put("versionId", versionId)`）手动补 query。
        request.addQuery('versionId', versionId);
      }
      entry.service.headObject(request)
        .then((headResult: HeadObjectResult) => {
          result.success(ModelConverter.toHeaderMap(headResult.headers));
        })
        .catch((e: ESObject) => {
          result.error(ErrorConverter.toFlutterError(e));
        });
    } catch (e) {
      result.error(ErrorConverter.toFlutterError(e));
    }
  }

  /** DELETE Object */
  deleteObject(
    serviceKey: string,
    bucket: string,
    region: string | undefined,
    cosPath: string,
    versionId: string | undefined,
    sessionCredentials: SessionQCloudCredentials | undefined,
    result: Result<void>,
  ): void {
    try {
      const entry: ServiceEntry = this.getEntry(serviceKey);
      const request: DeleteObjectRequest = new DeleteObjectRequest(bucket, cosPath);
      this.prepare(request, entry, region, sessionCredentials);
      if (versionId !== undefined && versionId !== null) {
        // 同 headObject：鸿蒙 DeleteObjectRequest 无 versionId 字段
        request.addQuery('versionId', versionId);
      }
      entry.service.deleteObject(request)
        .then(() => {
          result.success(undefined);
        })
        .catch((e: ESObject) => {
          result.error(ErrorConverter.toFlutterError(e));
        });
    } catch (e) {
      result.error(ErrorConverter.toFlutterError(e));
    }
  }

  /**
   * 对象访问 URL（不带签名）—— **同步方法**，自行拼接。
   *
   * ⚠️ 与 Android 的实现路径不同（结果等价）：
   *  - Android：`getObjectUrl()` 内部 new 一个 `BasePutObjectRequest(bucket, key, "")`
   *    再走 `getAccessUrl(request)` 取 URL。
   *  - 鸿蒙：`getAccessUrl(request: CosXmlRequest)` 的签名要求传 request，
   *    但本方法只是取一个 URL，为此构造一个「不会被发出去」的 request 属于浪费且易踩
   *    checkParameters 的坑（PutObjectRequest 的 body 为空会抛 CosInvalidArgumentError）。
   *    因此直接用 `config.getRequestHost(bucket, region)` 拼，逻辑与 SDK 的
   *    `getAccessUrl` 完全一致（protocol + host + '/' + path）。
   *
   * ⚠️ 端口：SDK 的 `getAccessUrl` 也**没有**拼 port（只有 `HttpRequest.buildURL` 才拼），
   * 这里保持与 SDK 一致，不加 port，避免两处行为不一。
   *
   * cosPath 前导 `/` 会被去掉，避免拼出 `host//key`。
   */
  getObjectUrl(bucket: string, region: string, cosPath: string, serviceKey: string): string {
    const entry: ServiceEntry = this.getEntry(serviceKey);
    const service: CosXmlBaseService = entry.service;
    const host: string = service.cosXmlServiceConfig.getRequestHost(bucket, region);
    const path: string = cosPath.startsWith('/') ? cosPath.substring(1) : cosPath;
    return `${service.cosXmlServiceConfig.protocol}://${host}/${path}`;
  }

  /**
   * 预签名 URL。
   *
   * ⚠️⚠️ **陷阱 T2（跨端签名一致性，必须处理）**：
   * 鸿蒙 `PresignedUrlRequest` 的**构造函数里**就执行了
   * `this.addNoSignHeaderKey(HttpHeader.HOST)` —— 即**默认不签 Host**；
   * 而 Android 的 `PresignedUrlRequest` **默认签 Host**，只有调用方显式传
   * `signHost=false` 时才 `addNoSignHeader("Host")`。
   *
   * 两端默认值相反，不处理会导致同样的调用在两个平台生成**不同的签名**
   * （服务端校验通过与否也可能不同）。因此这里在 `signHost !== false`
   * （含未传，因为 Android 默认是签）时，把 Host 从 `noSignHeaderKeys` 里**删掉**。
   *
   * ⚠️ 注意鸿蒙的 `noSignHeaderKeys` 是 `Set<string>` 公开字段，只有 add 没有 remove，
   * 所以直接 `.delete()`。
   *
   * ⚠️ USER_AGENT 保留在 noSignHeaderKeys 里不动 —— Android 侧的 UA 头也不参与
   * 预签名（Android 是在 `getPresignedURL` 里走独立的签名路径），删掉反而会不一致。
   */
  getPresignedUrl(
    serviceKey: string,
    bucket: string,
    cosPath: string,
    signValidTime: number | undefined,
    signHost: boolean | undefined,
    parameters: Map<string | undefined, string | undefined> | undefined,
    region: string | undefined,
    sessionCredentials: SessionQCloudCredentials | undefined,
    result: Result<string>,
  ): void {
    try {
      const entry: ServiceEntry = this.getEntry(serviceKey);
      // requestMethod 默认就是 GET，与 Android 的 setRequestMethod("GET") 一致
      const request: PresignedUrlRequest = new PresignedUrlRequest(bucket, cosPath);
      this.prepare(request, entry, region, sessionCredentials);

      // --- T2：对齐 Android 的「默认签 Host」 ---
      if (signHost === undefined || signHost === null || signHost === true) {
        request.noSignHeaderKeys.delete(HEADER_HOST);
      }
      // signHost === false 时保持 SDK 默认（已 addNoSignHeaderKey(HOST)），无需额外动作

      if (parameters !== undefined && parameters !== null) {
        parameters.forEach((value: string | undefined, key: string | undefined) => {
          if (key !== undefined && key !== null && key.length > 0) {
            request.addQuery(key, value);
          }
        });
      }

      // --- signValidTime ---
      if (signValidTime !== undefined && signValidTime !== null) {
        CosServiceApiImpl.applySignValidTime(request, signValidTime, sessionCredentials);
      }

      entry.service.buildPresignedUrl(request)
        .then((url: string) => {
          result.success(url);
        })
        .catch((e: ESObject) => {
          result.error(ErrorConverter.toFlutterError(e));
        });
    } catch (e) {
      result.error(ErrorConverter.toFlutterError(e));
    }
  }

  /**
   * 应用 `signValidTime`（签名有效时长，单位秒）。
   *
   * ⚠️⚠️ **与 Android 语义近似但不等价，这是已知且无法消除的平台差异**：
   *  - Android：`presignedUrlRequest.setSignKeyTime(signValidTime)`，只影响**签名**的
   *    q-sign-time/q-key-time，**不改动凭证本身**的有效期。
   *  - 鸿蒙：没有 setSignKeyTime 的等价物。`QCloudAuthentationCreator.buildSignature`
   *    的 qSignTime/qKeyTime 完全由 `credential.startDate` / `credential.expirationDate`
   *    推导（`now = startDate ?? 现在`，`exp = expirationDate ?? now + 1800`）。
   *    因此只能构造一个 `expirationDate = now + signValidTime` 的临时 credential
   *    塞进 `request.credential`。
   *
   * 后果差异（**需要知道**）：
   *  1. 使用**临时密钥**（sessionCredentials）时，本方法会用 signValidTime 覆盖掉
   *     STS 返回的 expiredTime。若 signValidTime **大于**临时密钥的剩余有效期，
   *     签名里会声明一个超出密钥实际有效期的 q-key-time，服务端仍会在密钥过期后拒绝 ——
   *     即 URL 的实际可用时长以「密钥有效期」和 signValidTime 的**较小者**为准。
   *  2. 未传 sessionCredentials（走 service 级 credentialCallBack）时，
   *     `request.credential` 一旦被赋值，签名流程就**不再回调** credentialCallBack
   *     （见 `QCloudSignatureBuilder.signatureBuild` 的凭证优先级：
   *     request.credential > 缓存 > 回调）。而此时我们手上**没有** secretId/secretKey，
   *     构造出的 credential 是空的，会导致签名失败。
   *     因此**只有在同时拿到 sessionCredentials 时**才应用 signValidTime；
   *     否则保持凭证不变并打 warn 说明 signValidTime 被忽略。
   */
  private static applySignValidTime(
    request: PresignedUrlRequest,
    signValidTime: number,
    sessionCredentials: SessionQCloudCredentials | undefined,
  ): void {
    if (sessionCredentials === undefined || sessionCredentials === null) {
      PluginLog.warnOnce(
        'getPresignedUrl.signValidTime',
        '[platform difference] getPresignedUrl(signValidTime) is IGNORED on HarmonyOS when no ' +
          'per-request sessionCredentials are supplied. The HarmonyOS SDK has no setSignKeyTime(); ' +
          'the signature validity is derived from credential.startDate/expirationDate, and ' +
          'overriding request.credential here would bypass the service-level credentialCallBack ' +
          '(request.credential has the highest priority) leaving the request unsigned. ' +
          'Pass sessionCredentials together with signValidTime if you need a custom validity.',
      );
      return;
    }
    // 已有请求级凭证：在其基础上改写有效期窗口
    const credential: QCloudCredential = request.credential ?? new QCloudCredential();
    const now: Date = new Date();
    credential.startDate = now;
    credential.expirationDate = new Date(now.getTime() + signValidTime * 1000);
    request.credential = credential;
    PluginLog.warnOnce(
      'getPresignedUrl.signValidTime.semantics',
      '[platform difference] getPresignedUrl(signValidTime) on HarmonyOS is implemented by ' +
        'narrowing the credential validity window (startDate=now, expirationDate=now+signValidTime), ' +
        'because the SDK has no setSignKeyTime(). Android only changes the signature time and ' +
        'leaves the credential untouched. The effective URL lifetime is therefore min(signValidTime, ' +
        'remaining lifetime of the temporary key).',
    );
  }

  /**
   * 预连接（预热 TCP/TLS 连接）。
   *
   * 鸿蒙 SDK 没有 `PreBuildConnectionRequest` 这种专用请求，
   * 按 Android 的实际语义等价实现：**对 bucket 根发一个 HEAD 请求**，
   * 只要不是 404 就算成功。
   *
   * 依据（Android `CosXmlSimpleService.preBuildConnectionAsync`）：
   * ```java
   * onFail(...) {
   *   if (serviceException != null && serviceException.getStatusCode() != 404) {
   *     listener.onSuccess();      // 403 等也算预连接成功（连接确实建起来了）
   *   } else { listener.onFail(...); }
   * }
   * ```
   * 也就是说：2xx → 成功；非 404 的服务端错误 → 也算成功；404 或客户端错误 → 失败。
   * 这里逐条对齐。
   *
   * ⚠️ 差异：鸿蒙侧无法像 Android 那样复用「连接池预热」的专用轻量请求，
   * 这里发的是真实 HEAD Bucket 请求，会产生一次真实的 API 调用（可能计费/计流量）。
   */
  preBuildConnection(bucket: string, serviceKey: string, result: Result<void>): void {
    try {
      const entry: ServiceEntry = this.getEntry(serviceKey);
      const request: HeadBucketRequest = new HeadBucketRequest(bucket);
      this.prepare(request, entry, undefined, undefined);
      entry.service.headBucket(request)
        .then(() => {
          result.success(undefined);
        })
        .catch((e: ESObject) => {
          // 非 404 的服务端错误也视为「连接已建立」，对齐 Android
          const httpCode: number = CosServiceApiImpl.httpCodeOf(e);
          if (httpCode > 0 && httpCode !== HTTP_NOT_FOUND) {
            result.success(undefined);
            return;
          }
          result.error(ErrorConverter.toFlutterError(e));
        });
    } catch (e) {
      result.error(ErrorConverter.toFlutterError(e));
    }
  }

  /**
   * 对象是否存在 = HEAD Object + 判状态码。
   *
   * 对齐 Android `CosXmlService.doesObjectExistAsync`：
   *   成功 → true；404 → false；其余错误 → 上抛。
   */
  doesObjectExist(
    serviceKey: string,
    bucket: string,
    cosPath: string,
    result: Result<boolean>,
  ): void {
    try {
      const entry: ServiceEntry = this.getEntry(serviceKey);
      const request: HeadObjectRequest = new HeadObjectRequest(bucket, cosPath);
      this.prepare(request, entry, undefined, undefined);
      entry.service.headObject(request)
        .then(() => {
          result.success(true);
        })
        .catch((e: ESObject) => {
          if (CosServiceApiImpl.httpCodeOf(e) === HTTP_NOT_FOUND) {
            result.success(false);
            return;
          }
          result.error(ErrorConverter.toFlutterError(e));
        });
    } catch (e) {
      result.error(ErrorConverter.toFlutterError(e));
    }
  }

  /**
   * 存储桶是否存在 = HEAD Bucket + 判状态码。
   *
   * 对齐 Android `CosXmlService.doesBucketExistAsync` 的**三条**判定（不只是 200/404）：
   *   - 成功                         → true
   *   - 301（BUCKET_REDIRECT）       → true（桶存在，只是地域不对需重定向）
   *   - errorCode == "AccessDenied"  → true（桶存在，只是当前身份无权限）
   *   - 404（NO_SUCH_BUCKET）        → false
   *   - 其余                          → 上抛
   */
  doesBucketExist(serviceKey: string, bucket: string, result: Result<boolean>): void {
    try {
      const entry: ServiceEntry = this.getEntry(serviceKey);
      const request: HeadBucketRequest = new HeadBucketRequest(bucket);
      this.prepare(request, entry, undefined, undefined);
      entry.service.headBucket(request)
        .then(() => {
          result.success(true);
        })
        .catch((e: ESObject) => {
          const httpCode: number = CosServiceApiImpl.httpCodeOf(e);
          const errorCode: string | undefined = CosServiceApiImpl.errorCodeOf(e);
          if (httpCode === HTTP_BUCKET_REDIRECT || errorCode === ERROR_CODE_ACCESS_DENIED) {
            result.success(true);
            return;
          }
          if (httpCode === HTTP_NOT_FOUND) {
            result.success(false);
            return;
          }
          result.error(ErrorConverter.toFlutterError(e));
        });
    } catch (e) {
      result.error(ErrorConverter.toFlutterError(e));
    }
  }

  // ------------------------------------------------------------------
  // 存储桶级
  // ------------------------------------------------------------------

  /** GET Service（列出所有存储桶）。鸿蒙对应 `listBucket()` */
  getService(
    serviceKey: string,
    sessionCredentials: SessionQCloudCredentials | undefined,
    result: Result<ListAllMyBuckets>,
  ): void {
    try {
      const entry: ServiceEntry = this.getEntry(serviceKey);
      const request: ListBucketsRequest = new ListBucketsRequest();
      // GET Service 是账号级接口，host 固定为 service.cos.myqcloud.com（bucket 为空时
      // 鸿蒙 getRequestHost 会自动返回该值），因此不传 region。
      this.prepare(request, entry, undefined, sessionCredentials);
      entry.service.listBucket(request)
        .then((listResult: ListBucketsResult) => {
          try {
            result.success(ModelConverter.toListAllMyBuckets(listResult));
          } catch (e) {
            result.error(ErrorConverter.toFlutterError(e));
          }
        })
        .catch((e: ESObject) => {
          result.error(ErrorConverter.toFlutterError(e));
        });
    } catch (e) {
      result.error(ErrorConverter.toFlutterError(e));
    }
  }

  /** GET Bucket（列出对象）。鸿蒙对应 `listObject()` */
  getBucket(
    serviceKey: string,
    bucket: string,
    region: string | undefined,
    prefix: string | undefined,
    delimiter: string | undefined,
    encodingType: string | undefined,
    marker: string | undefined,
    maxKeys: number | undefined,
    sessionCredentials: SessionQCloudCredentials | undefined,
    result: Result<BucketContents>,
  ): void {
    try {
      const entry: ServiceEntry = this.getEntry(serviceKey);
      const request: ListObjectsRequest = new ListObjectsRequest(bucket);
      this.prepare(request, entry, region, sessionCredentials);
      if (prefix !== undefined && prefix !== null) {
        request.prefix = prefix;
      }
      if (delimiter !== undefined && delimiter !== null) {
        request.delimiter = delimiter;
      }
      if (encodingType !== undefined && encodingType !== null) {
        request.encodingType = encodingType;
      }
      if (marker !== undefined && marker !== null) {
        request.marker = marker;
      }
      if (maxKeys !== undefined && maxKeys !== null) {
        request.maxKeys = maxKeys;
      }
      entry.service.listObject(request)
        .then((listResult: ListObjectsResult) => {
          try {
            result.success(ModelConverter.toBucketContents(listResult));
          } catch (e) {
            result.error(ErrorConverter.toFlutterError(e));
          }
        })
        .catch((e: ESObject) => {
          result.error(ErrorConverter.toFlutterError(e));
        });
    } catch (e) {
      result.error(ErrorConverter.toFlutterError(e));
    }
  }

  /**
   * PUT Bucket（创建存储桶）。
   *
   * ⚠️ ACL 字段名对照（Android → 鸿蒙）：
   *   setXCOSACL        → setXCosAcl
   *   setXCOSGrantRead  → setXCosGrantRead
   *   setXCOSGrantWrite → setXCosGrantWrite
   *   setXCOSReadWrite  → setXCosGrantFullControl
   *
   * 最后一条**不是笔误**：Android 的 `setXCOSReadWrite` 内部设的就是
   * `x-cos-grant-full-control` 头，鸿蒙同名方法叫 setXCosGrantFullControl。
   * Flutter 侧该参数名为 `readWriteAccount`，语义一致。
   */
  putBucket(
    serviceKey: string,
    bucket: string,
    region: string | undefined,
    enableMAZ: boolean | undefined,
    cosacl: string | undefined,
    readAccount: string | undefined,
    writeAccount: string | undefined,
    readWriteAccount: string | undefined,
    sessionCredentials: SessionQCloudCredentials | undefined,
    result: Result<void>,
  ): void {
    try {
      const entry: ServiceEntry = this.getEntry(serviceKey);
      const request: PutBucketRequest = new PutBucketRequest(bucket);
      this.prepare(request, entry, region, sessionCredentials);
      if (enableMAZ !== undefined && enableMAZ !== null) {
        request.enableMAZ = enableMAZ;
      }
      if (cosacl !== undefined && cosacl !== null) {
        request.setXCosAcl(cosacl);
      }
      if (readAccount !== undefined && readAccount !== null) {
        request.setXCosGrantRead(readAccount);
      }
      if (writeAccount !== undefined && writeAccount !== null) {
        request.setXCosGrantWrite(writeAccount);
      }
      if (readWriteAccount !== undefined && readWriteAccount !== null) {
        // 对齐 Android setXCOSReadWrite → x-cos-grant-full-control
        request.setXCosGrantFullControl(readWriteAccount);
      }
      entry.service.putBucket(request)
        .then(() => {
          result.success(undefined);
        })
        .catch((e: ESObject) => {
          result.error(ErrorConverter.toFlutterError(e));
        });
    } catch (e) {
      result.error(ErrorConverter.toFlutterError(e));
    }
  }

  /** HEAD Bucket，成功时回传响应头 */
  headBucket(
    serviceKey: string,
    bucket: string,
    region: string | undefined,
    sessionCredentials: SessionQCloudCredentials | undefined,
    result: Result<Map<string | undefined, string | undefined>>,
  ): void {
    try {
      const entry: ServiceEntry = this.getEntry(serviceKey);
      const request: HeadBucketRequest = new HeadBucketRequest(bucket);
      this.prepare(request, entry, region, sessionCredentials);
      entry.service.headBucket(request)
        .then((headResult: HeadBucketResult) => {
          result.success(ModelConverter.toHeaderMap(headResult.headers));
        })
        .catch((e: ESObject) => {
          result.error(ErrorConverter.toFlutterError(e));
        });
    } catch (e) {
      result.error(ErrorConverter.toFlutterError(e));
    }
  }

  /** DELETE Bucket */
  deleteBucket(
    serviceKey: string,
    bucket: string,
    region: string | undefined,
    sessionCredentials: SessionQCloudCredentials | undefined,
    result: Result<void>,
  ): void {
    try {
      const entry: ServiceEntry = this.getEntry(serviceKey);
      const request: DeleteBucketRequest = new DeleteBucketRequest(bucket);
      this.prepare(request, entry, region, sessionCredentials);
      entry.service.deleteBucket(request)
        .then(() => {
          result.success(undefined);
        })
        .catch((e: ESObject) => {
          result.error(ErrorConverter.toFlutterError(e));
        });
    } catch (e) {
      result.error(ErrorConverter.toFlutterError(e));
    }
  }

  /**
   * GET Bucket accelerate（查询全球加速开关）。
   *
   * 对齐 Android：`accelerateConfiguration == null` → false，
   * 否则 `"Enabled".equals(status)`。存储桶从未配置过加速时，
   * 鸿蒙的 accelerateConfiguration 或其 status 可能为 undefined，均按 false 处理。
   */
  getBucketAccelerate(
    serviceKey: string,
    bucket: string,
    region: string | undefined,
    sessionCredentials: SessionQCloudCredentials | undefined,
    result: Result<boolean>,
  ): void {
    try {
      const entry: ServiceEntry = this.getEntry(serviceKey);
      const request: GetBucketAccelerateRequest = new GetBucketAccelerateRequest(bucket);
      this.prepare(request, entry, region, sessionCredentials);
      entry.service.getBucketAccelerate(request)
        .then((accResult: GetBucketAccelerateResult) => {
          result.success(accResult.accelerateConfiguration?.status === 'Enabled');
        })
        .catch((e: ESObject) => {
          result.error(ErrorConverter.toFlutterError(e));
        });
    } catch (e) {
      result.error(ErrorConverter.toFlutterError(e));
    }
  }

  /** PUT Bucket accelerate（开启/关闭全球加速） */
  putBucketAccelerate(
    serviceKey: string,
    bucket: string,
    region: string | undefined,
    enable: boolean,
    sessionCredentials: SessionQCloudCredentials | undefined,
    result: Result<void>,
  ): void {
    try {
      const entry: ServiceEntry = this.getEntry(serviceKey);
      const request: PutBucketAccelerateRequest = new PutBucketAccelerateRequest(bucket, enable);
      this.prepare(request, entry, region, sessionCredentials);
      entry.service.putBucketAccelerate(request)
        .then(() => {
          result.success(undefined);
        })
        .catch((e: ESObject) => {
          result.error(ErrorConverter.toFlutterError(e));
        });
    } catch (e) {
      result.error(ErrorConverter.toFlutterError(e));
    }
  }

  /**
   * GET Bucket location（查询存储桶地域）。
   *
   * ⚠️ Flutter 侧返回类型是**非空** string，而鸿蒙 `location` 是可选字段，
   * 解析不出来时兜空串（Android 侧 `locationConstraint.location` 为 null 时
   * 会走 NPE → result.error，这里选择不抛，返回空串更温和且不丢失"请求成功"这一事实）。
   */
  getBucketLocation(
    serviceKey: string,
    bucket: string,
    region: string | undefined,
    sessionCredentials: SessionQCloudCredentials | undefined,
    result: Result<string>,
  ): void {
    try {
      const entry: ServiceEntry = this.getEntry(serviceKey);
      const request: GetBucketLocationRequest = new GetBucketLocationRequest(bucket);
      this.prepare(request, entry, region, sessionCredentials);
      entry.service.getBucketLocation(request)
        .then((locResult: GetBucketLocationResult) => {
          result.success(locResult.location ?? '');
        })
        .catch((e: ESObject) => {
          result.error(ErrorConverter.toFlutterError(e));
        });
    } catch (e) {
      result.error(ErrorConverter.toFlutterError(e));
    }
  }

  /**
   * GET Bucket versioning（查询多版本开关）。
   *
   * 对齐 Android：未开启过版本控制时 status 为空 → false。
   * 注意 COS 的 `Suspended`（已暂停）也返回 false，这与 Android 的
   * `"Enabled".equals(status)` 一致。
   */
  getBucketVersioning(
    serviceKey: string,
    bucket: string,
    region: string | undefined,
    sessionCredentials: SessionQCloudCredentials | undefined,
    result: Result<boolean>,
  ): void {
    try {
      const entry: ServiceEntry = this.getEntry(serviceKey);
      const request: GetBucketVersioningRequest = new GetBucketVersioningRequest(bucket);
      this.prepare(request, entry, region, sessionCredentials);
      entry.service.getBucketVersioning(request)
        .then((verResult: GetBucketVersioningResult) => {
          result.success(verResult.versioningConfiguration?.status === 'Enabled');
        })
        .catch((e: ESObject) => {
          result.error(ErrorConverter.toFlutterError(e));
        });
    } catch (e) {
      result.error(ErrorConverter.toFlutterError(e));
    }
  }

  /** PUT Bucket versioning（开启/暂停多版本） */
  putBucketVersioning(
    serviceKey: string,
    bucket: string,
    region: string | undefined,
    enable: boolean,
    sessionCredentials: SessionQCloudCredentials | undefined,
    result: Result<void>,
  ): void {
    try {
      const entry: ServiceEntry = this.getEntry(serviceKey);
      const request: PutBucketVersioningRequest = new PutBucketVersioningRequest(bucket, enable);
      this.prepare(request, entry, region, sessionCredentials);
      entry.service.putBucketVersioning(request)
        .then(() => {
          result.success(undefined);
        })
        .catch((e: ESObject) => {
          result.error(ErrorConverter.toFlutterError(e));
        });
    } catch (e) {
      result.error(ErrorConverter.toFlutterError(e));
    }
  }

  // ------------------------------------------------------------------
  // 其他
  // ------------------------------------------------------------------

  /**
   * 取消该 service 上的所有请求。
   *
   * ⚠️ **平台差异（作用域比 Android 更大）**：鸿蒙的 `cancelAll()` 内部走
   * `QCloudTaskManager.manager().cancelAll()`，而 `QCloudTaskManager` 是**全局单例**，
   * 因此这里会取消**所有 service 实例**（以及所有传输任务）的在途请求，
   * 而不只是 `serviceKey` 对应的那一个。Android 的 `CosXmlService.cancelAll()`
   * 是 per-service 的。
   *
   * 单 service（绝大多数用法）下两者等价；多 service 并发时需注意该差异。
   *
   * 返回类型为 void 且 pigeon 侧是同步调用，service 未注册时会同步抛出，
   * 由 pigeon 的 `onMessage` try/catch 包成 channel 错误回传 Flutter —— 这与
   * Android 的 `getCosXmlService()` 抛 IllegalArgumentException 行为一致。
   */
  cancelAll(serviceKey: string): void {
    PluginLog.warnOnce(
      'cancelAll',
      '[platform difference] cancelAll() on HarmonyOS cancels in-flight requests of ALL ' +
        'registered services and transfer tasks, not just the given serviceKey: the SDK ' +
        'delegates to the global QCloudTaskManager singleton. Android scopes it per service.',
    );
    this.getEntry(serviceKey).service.cancelAll();
  }
}
