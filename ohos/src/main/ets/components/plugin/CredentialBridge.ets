/*
 * Copyright (c) 2026 Tencent Cloud. All rights reserved.
 * Licensed under the Apache License, Version 2.0 (the "License").
 */

/**
 * 凭证桥接层：把鸿蒙 SDK 的 `CredentialCallBack` 接到 Flutter 侧。
 *
 * 对齐 Android 的三种凭证模式（`CosPlugin.initWithPlainSecret` /
 * `initWithSessionCredential` / `initWithScopeLimitCredential`）。
 */

import { CredentialCallBack, QCloudCredential, CredentialCache } from '@tencentcloud/cos';
import { Reply } from '@ohos/flutter_ohos/src/main/ets/plugin/common/BasicMessageChannel';
import { FlutterCosApi, FlutterError, SessionQCloudCredentials } from './Pigeon';
import { PluginLog } from './PluginLog';

/**
 * 向 Flutter 拉取临时密钥的超时（ms）。
 *
 * 注意：鸿蒙 SDK 的 `QCloudSignatureBuilder.signatureBuild` 内部已有一层 20s 超时，
 * 会先于这里触发。此处的定时器只是兜底，避免 Flutter 永不回包时 Promise 永挂。
 */
const FETCH_TIMEOUT_MS: number = 20 * 1000;

/** 凭证模式，用于 `forceInvalidationCredential` 与日志诊断 */
export enum CredentialMode {
  /** 未初始化 */
  NONE = 'NONE',
  /** 永久密钥（本地固定 secretId/secretKey） */
  PLAIN_SECRET = 'PLAIN_SECRET',
  /** 临时密钥，回调 Flutter 的 fetchSessionCredentials */
  SESSION = 'SESSION',
  /**
   * 范围限制签名。鸿蒙**不支持**，降级为 SESSION。
   * 原因见 CredentialBridge.forScopeLimit 的注释。
   */
  SCOPE_LIMIT = 'SCOPE_LIMIT',
}

export class CredentialBridge {
  private readonly mode: CredentialMode;
  /** PLAIN_SECRET 模式下的固定密钥 */
  private readonly secretId?: string;
  private readonly secretKey?: string;
  private readonly flutterCosApi?: FlutterCosApi;

  private constructor(
    mode: CredentialMode,
    secretId?: string,
    secretKey?: string,
    flutterCosApi?: FlutterCosApi,
  ) {
    this.mode = mode;
    this.secretId = secretId;
    this.secretKey = secretKey;
    this.flutterCosApi = flutterCosApi;
  }

  getMode(): CredentialMode {
    return this.mode;
  }

  /** 永久密钥模式 */
  static forPlainSecret(secretId: string, secretKey: string): CredentialBridge {
    return new CredentialBridge(CredentialMode.PLAIN_SECRET, secretId, secretKey, undefined);
  }

  /** 临时密钥模式：每次需要签名时回调 Flutter 的 `fetchSessionCredentials` */
  static forSession(flutterCosApi: FlutterCosApi): CredentialBridge {
    return new CredentialBridge(CredentialMode.SESSION, undefined, undefined, flutterCosApi);
  }

  /**
   * 范围限制签名模式 —— **鸿蒙平台不支持，降级为普通临时密钥**。
   *
   * 原因（已确认，非偷懒）：鸿蒙的 `CredentialCallBack` 签名是
   * `<T>(request: HttpRequest<T>) => Promise<QCloudCredential>`。
   * 虽然拿到了 request，但 `HttpRequest` 上并没有 COS 语义层的
   * action / bucket / region 三元组（只有 method/host/path/headers/queries），
   * 无法可靠地反推出 Flutter 侧 `fetchScopeLimitCredentials` 需要的
   * `STSCredentialScope` 列表 —— 从 path 逆向猜 action 会给出错误的授权范围，
   * 这比不支持更危险（可能申请到过宽或过窄的权限）。
   *
   * 因此这里调用 Flutter 的 `fetchSessionCredentials`（而非
   * `fetchScopeLimitCredentials`），并打一条 warn 说明降级。
   * 业务方若依赖范围限制签名，需在 Flutter 侧改用 `initWithSessionCredential`
   * 并自行在 STS 服务端收敛权限范围。
   */
  static forScopeLimit(flutterCosApi: FlutterCosApi): CredentialBridge {
    PluginLog.warnOnce(
      'initWithScopeLimitCredential',
      '[platform difference] initWithScopeLimitCredential() is NOT supported on HarmonyOS and ' +
        'has been degraded to initWithSessionCredential(): the HarmonyOS CredentialCallBack ' +
        'cannot expose the action/bucket/region scope required to build STSCredentialScope. ' +
        'Flutter side fetchSessionCredentials() will be called instead of ' +
        'fetchScopeLimitCredentials(). Narrow the permission scope on your STS server if needed.',
    );
    return new CredentialBridge(CredentialMode.SCOPE_LIMIT, undefined, undefined, flutterCosApi);
  }

  /**
   * 生成传给 `new CosXmlBaseService(context, config, credentialCallBack)` 的回调。
   *
   * 注意签名里的 `request` 参数在鸿蒙侧用不上（见 forScopeLimit 的说明），
   * 但类型必须匹配 `CredentialCallBack`，所以保留形参。
   */
  toCredentialCallBack(): CredentialCallBack {
    // ArkTS 无法给泛型箭头函数标注类型参数，这里用 ESObject 承接 request 并忽略
    const callback: CredentialCallBack = (request: ESObject): Promise<QCloudCredential> => {
      if (this.mode === CredentialMode.PLAIN_SECRET) {
        return this.buildPlainCredential();
      }
      return this.fetchSessionCredential();
    };
    return callback;
  }

  /**
   * 永久密钥：只填 secretID/secretKey，**不设** startDate/expirationDate。
   *
   * 这样 `QCloudAuthentationCreator.buildSignature` 会以「当次请求时刻」为起点、
   * 有效期 30 分钟来算签名（默认 `exp = now + 1800`）。
   *
   * 与 Android 的差异：Android `initWithPlainSecret` 用
   * `ShortTimeCredentialProvider(secretId, secretKey, 600)`，签名有效期 600 秒。
   * 鸿蒙侧为 1800 秒。两者都远大于单次请求耗时，不影响功能，
   * 且不设 expirationDate 可避免 `CredentialCache` 把过期的固定密钥缓存住。
   */
  private buildPlainCredential(): Promise<QCloudCredential> {
    return new Promise<QCloudCredential>((resolve: (v: QCloudCredential) => void) => {
      const credential: QCloudCredential = new QCloudCredential();
      credential.secretID = this.secretId;
      credential.secretKey = this.secretKey;
      resolve(credential);
    });
  }

  /** 回调 Flutter 取临时密钥并转成 QCloudCredential */
  private fetchSessionCredential(): Promise<QCloudCredential> {
    return new Promise<QCloudCredential>(
      (resolve: (v: QCloudCredential) => void, reject: (e: Error) => void) => {
        const api: FlutterCosApi | undefined = this.flutterCosApi;
        if (api === undefined || api === null) {
          reject(new Error('FlutterCosApi is not attached, cannot fetch session credentials'));
          return;
        }

        let settled: boolean = false;
        const timer: number = setTimeout(() => {
          if (!settled) {
            settled = true;
            reject(new Error('timeout fetching session credentials from Flutter'));
          }
        }, FETCH_TIMEOUT_MS);

        // BinaryMessenger 要求在创建它的线程（主线程）上调用。
        // 鸿蒙侧 SDK 的签名流程本身就跑在主线程的微任务里，无需像 Android 那样切线程。
        const reply: Reply<SessionQCloudCredentials> = {
          reply: (result: ESObject): void => {
            if (settled) {
              return;
            }
            settled = true;
            clearTimeout(timer);
            if (result instanceof FlutterError) {
              const fe: FlutterError = result as FlutterError;
              reject(new Error(`fetch credentials error happens: ${fe.code} ${fe.message}`));
              return;
            }
            if (result === null || result === undefined) {
              reject(new Error('fetch credentials error happens: null credentials'));
              return;
            }
            try {
              resolve(CredentialBridge.toQCloudCredential(result as SessionQCloudCredentials));
            } catch (e) {
              reject(e as Error);
            }
          },
        };
        api.fetchSessionCredentials(reply);
      },
    );
  }

  /**
   * pigeon `SessionQCloudCredentials` → 鸿蒙 `QCloudCredential`。
   *
   * ⚠️ 单位差异：pigeon 侧 `startTime` / `expiredTime` 是**秒**（Unix 时间戳，
   * 与 Android `SessionQCloudCredentials` 一致），鸿蒙 `QCloudCredential` 的
   * `startDate` / `expirationDate` 是 `Date`。必须 ×1000。
   *
   * `startTime` 可空：为空时不设 startDate，签名以设备当前时间为起点
   * （对齐 Android 的 `SessionQCloudCredentials(id, key, token, expiredTime)` 三参构造）。
   */
  static toQCloudCredential(session: SessionQCloudCredentials): QCloudCredential {
    const credential: QCloudCredential = new QCloudCredential();
    credential.secretID = session.getSecretId();
    credential.secretKey = session.getSecretKey();
    credential.token = session.getToken();
    const startTime: number | undefined = session.getStartTime();
    if (startTime !== undefined && startTime !== null) {
      credential.startDate = new Date(startTime * 1000);
    }
    credential.expirationDate = new Date(session.getExpiredTime() * 1000);
    return credential;
  }

  /**
   * 清空全局凭证缓存。
   *
   * 对齐 Android `forceInvalidationCredential`。
   * ⚠️ 鸿蒙的 `CredentialCache` 是**全局单例**（`CredentialCache.singleCache()`），
   * 不是 per-service，所以这里会作用于所有已注册的 service。
   */
  static clearCredentialCache(): void {
    CredentialCache.singleCache().clearCredential();
  }
}
