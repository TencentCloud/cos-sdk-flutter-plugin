/*
 * Copyright (c) 2026 Tencent Cloud. All rights reserved.
 * Licensed under the Apache License, Version 2.0 (the "License").
 */

/**
 * 鸿蒙（ArkTS）侧 Flutter 插件主类。
 *
 * 行为基准是 Android 侧 `android/src/main/java/com/tencent/cos/flutter/plugin/CosPlugin.java`，
 * 平台差异逐条在注释中标注。
 *
 * ## ArkTS 单继承的处理方式
 *
 * pigeon 生成的 `CosApi` / `CosServiceApi` / `CosTransferApi` 是三个
 * **abstract class**（不是 interface），而 ArkTS 不支持多继承 —— 一个类只能
 * `extends` 其中一个。（已核实：`Pigeon.ets:2038/2988/3671` 均为 `export abstract class`。）
 *
 * 采用方案：`CosPlugin extends CosApi`，另两个 Api 由**独立的适配器类**实现，
 * 适配器持有本插件实例的共享状态（registry / credentialBridge / context /
 * flutterCosApi），在 `onAttachedToEngine` 里分别 `setup`。
 * 这与 fork pigeon 官方 example 的做法一致
 * （`packages/pigeon/example/app/ohos/.../MessagePlugin.ets:77`
 * 注释原文：`ArkTS single inheritance: bridge [HostApiImp] to [ExampleHostApi.setup]`）。
 *
 * 三个 Api 的落点：
 *  - `CosApi`         → 本类（30 个方法）
 *  - `CosServiceApi`  → `CosServiceApiImpl`（18 个方法）
 *  - `CosTransferApi` → `CosTransferApiImpl`（5 个方法 + 四类回调）
 *
 * ## 另一处与任务书不符的地方
 *
 * 生成的静态方法名是 **`setup`（小写 p）**，不是 Android/Dart 侧的 `setUp`。
 * 见 `Pigeon.ets:2104` `static setup(binaryMessenger, api, messageChannelSuffix)`。
 *
 * ## 线程模型
 *
 * `BinaryMessenger` 要求在创建它的线程（主线程）上使用。鸿蒙 SDK 本身是
 * Promise 异步，回调天然回到主线程的微任务队列，因此**不需要**像 Android 那样
 * `runMainThread()` 包装，也不要自行丢 TaskPool（跨线程需 Sendable，得不偿失）。
 */

import { FlutterPlugin, FlutterPluginBinding } from '@ohos/flutter_ohos/src/main/ets/embedding/engine/plugins/FlutterPlugin';
import common from '@ohos.app.ability.common';
import { QCloudLogger } from '@tencentcloud/cos';
import {
  CosApi,
  CosServiceApi,
  CosTransferApi,
  CosXmlServiceConfig as PigeonCosXmlServiceConfig,
  TransferConfig as PigeonTransferConfig,
  FlutterCosApi,
  LogEntity,
  LogLevel,
  LogCategory,
  Result,
} from './Pigeon';
import { CosServiceRegistry, DEFAULT_KEY } from './CosServiceRegistry';
import { CredentialBridge } from './CredentialBridge';
import { PluginLog } from './PluginLog';
import { CosServiceApiImpl } from './CosServiceApiImpl';
import { CosTransferApiImpl } from './CosTransferApiImpl';
import { TransferTaskRegistry } from './TransferTaskRegistry';
import { Reply } from '@ohos/flutter_ohos/src/main/ets/plugin/common/BasicMessageChannel';

/** 「鸿蒙无日志子系统」这一整块降级的统一说明，附在每条 warn 后面 */
const LOG_SUBSYSTEM_REASON: string =
  'The HarmonyOS COS SDK only ships hilog/console output plus a single global string callback ' +
  '(QCloudLogger.logOutputCallback); it has no log file, no structured listener, no CLS channel, ' +
  'no log encryption and no sensitive-data rules. See the "platform difference" section in README.';

/**
 * 供 CosServiceApi / CosTransferApi 适配器（P3-4 / P3-5）复用的共享状态。
 *
 * 之所以不让适配器直接持有 CosPlugin 引用：CosPlugin 已经 extends CosApi，
 * 把它整体暴露给适配器会把 30 个 CosApi 方法也一并暴露，边界不清。
 */
export class CosPluginSharedState {
  readonly registry: CosServiceRegistry;
  readonly context: common.Context;
  readonly flutterCosApi: FlutterCosApi;

  constructor(registry: CosServiceRegistry, context: common.Context, flutterCosApi: FlutterCosApi) {
    this.registry = registry;
    this.context = context;
    this.flutterCosApi = flutterCosApi;
  }
}

/**
 * FlutterApi 通知型回调的空 Reply：成功忽略，失败只打日志
 * （对齐 Android 的 `getVoidReply()`）。
 *
 * 注意 `Reply<T>` 是「带一个函数属性的接口」（`{ reply: (reply: T) => void }`），
 * 不是抽象类，所以这里返回对象字面量而不是 `implements Reply<void>` 的类 ——
 * 与 fork pigeon 官方 example（DemoHostApiImpl）的写法保持一致。
 *
 * pigeon 生成的 FlutterApi 在通道异常时会把 `FlutterError` 作为入参调 `reply()`，
 * 正常完成时无参调用，据此区分成功/失败。
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

export default class CosPlugin extends CosApi implements FlutterPlugin {
  private context: common.Context | null = null;
  private flutterCosApi: FlutterCosApi | null = null;
  private registry: CosServiceRegistry = new CosServiceRegistry();
  /** 传输任务表（taskId → UploadTask/DownloadTask），由 CosTransferApiImpl 使用 */
  private taskRegistry: TransferTaskRegistry = new TransferTaskRegistry();

  /** 当前凭证模式（initWithXxx 的产物），构造 service 时用 */
  private credentialBridge: CredentialBridge | null = null;

  /**
   * 另两个 Api 的适配器实例。
   * 持有引用是为了在 onDetachedFromEngine 时能 setup(null) 解绑并释放。
   */
  private serviceApi: CosServiceApiImpl | null = null;
  private transferApi: CosTransferApiImpl | null = null;

  /** `initCustomerDNS` 存下的静态 DNS 映射，在 register 时喂给 ConfigConverter */
  private dnsMap: Map<string, Array<string>> | null = null;
  /** `initCustomerDNSFetch` 的开关。本轮仅记录，见该方法注释 */
  private initDnsFetch: boolean = false;

  /**
   * `addLogListener` 的降级实现所需：key → 是否已注册。
   * 注意 `QCloudLogger.logOutputCallback` 是**单个静态字段而非列表**，
   * 多 listener 必须由插件侧自行 fan-out。
   */
  private logListenerKeys: Set<number> = new Set<number>();
  /** 是否已经把 fan-out 回调挂到 QCloudLogger 上 */
  private logCallbackInstalled: boolean = false;

  // ------------------------------------------------------------------
  // FlutterPlugin
  // ------------------------------------------------------------------

  getUniqueClassName(): string {
    return 'CosPlugin';
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    // 用 ApplicationContext 即可满足 CosXmlBaseService 的构造需求；
    // 本插件不拉起 Ability、不弹权限框，故无需 implements AbilityAware。
    this.context = binding.getApplicationContext();
    this.flutterCosApi = new FlutterCosApi(binding.getBinaryMessenger());
    CosApi.setup(binding.getBinaryMessenger(), this);

    // 另两个 Api 走独立适配器（ArkTS 单继承，见文件头注释）。
    // 此时 context / flutterCosApi 都已就绪，getSharedState() 必不为 null。
    const shared: CosPluginSharedState | null = this.getSharedState();
    if (shared !== null) {
      this.serviceApi = new CosServiceApiImpl(shared!);
      this.transferApi = new CosTransferApiImpl(shared!, this.taskRegistry);
      CosServiceApi.setup(binding.getBinaryMessenger(), this.serviceApi);
      CosTransferApi.setup(binding.getBinaryMessenger(), this.transferApi);
    } else {
      // 理论不可达；真出现说明上面的赋值顺序被改坏了，必须能被发现而不是静默少两个 Api
      PluginLog.error(
        'failed to build shared state in onAttachedToEngine; ' +
          'CosServiceApi / CosTransferApi are NOT registered',
      );
    }
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    CosApi.setup(binding.getBinaryMessenger(), null);
    CosServiceApi.setup(binding.getBinaryMessenger(), null);
    CosTransferApi.setup(binding.getBinaryMessenger(), null);
    this.serviceApi = null;
    this.transferApi = null;
    this.uninstallLogCallback();
    this.logListenerKeys.clear();
    // 注意只清表不 cancel 在途任务：与 Android 的 onDetachedFromEngine 一致
    // （Android 也只是丢弃 taskMap），避免 engine 重建时误杀后台传输。
    this.taskRegistry.clear();
    this.registry.clear();
    this.credentialBridge = null;
    this.dnsMap = null;
    this.initDnsFetch = false;
    this.flutterCosApi = null;
    this.context = null;
  }

  /** 供 P3-4 / P3-5 的适配器取共享状态；未 attach 时返回 null */
  getSharedState(): CosPluginSharedState | null {
    if (this.context === null || this.flutterCosApi === null) {
      return null;
    }
    return new CosPluginSharedState(this.registry, this.context!, this.flutterCosApi!);
  }

  // ------------------------------------------------------------------
  // A. 初始化与鉴权
  // ------------------------------------------------------------------

  /**
   * 永久密钥。
   *
   * 与 Android 的差异：Android 用 `ShortTimeCredentialProvider(id, key, 600)`，
   * 签名有效期 600s；鸿蒙侧不设 expirationDate，由签名算法按 now+1800s 计算。
   * 两者都远大于单次请求耗时，不影响功能。见 CredentialBridge.buildPlainCredential。
   */
  initWithPlainSecret(secretId: string, secretKey: string): void {
    this.credentialBridge = CredentialBridge.forPlainSecret(secretId, secretKey);
  }

  /** 临时密钥：签名时回调 Flutter 的 fetchSessionCredentials */
  initWithSessionCredential(): void {
    const api: FlutterCosApi | null = this.flutterCosApi;
    if (api === null) {
      PluginLog.error('initWithSessionCredential called before onAttachedToEngine');
      return;
    }
    this.credentialBridge = CredentialBridge.forSession(api!);
  }

  /**
   * 范围限制签名 —— **鸿蒙不支持，降级为普通临时密钥**。
   * 降级原因见 `CredentialBridge.forScopeLimit`（会打一条 warn 说明）。
   */
  initWithScopeLimitCredential(): void {
    const api: FlutterCosApi | null = this.flutterCosApi;
    if (api === null) {
      PluginLog.error('initWithScopeLimitCredential called before onAttachedToEngine');
      return;
    }
    this.credentialBridge = CredentialBridge.forScopeLimit(api!);
  }

  /**
   * 静态自定义 DNS（域名 → IP 列表）。
   *
   * 与 Android 一致：这里只**存**映射，实际生效在后续 `registerService` /
   * `registerTransferManger` 时通过 `ConfigConverter` 写入
   * `config.dnsConfiguration.dnsRules`（rcp StaticDnsRules）。
   * 也就是说必须**先** initCustomerDNS **再** register，顺序要求与 Android 相同。
   *
   * ⚠️ 两点鸿蒙特有的限制（见 ConfigConverter.buildStaticDnsRules）：
   *  1. `rcp.StaticDnsRule` 要求 host + **port** 同时匹配，而 Flutter 侧只给域名。
   *     插件按 config 推导端口（显式 port 优先，否则 https→443 / http→80）。
   *  2. `dnsConfiguration` 与 `requestConfiguration` 在鸿蒙 SDK 内部互斥
   *     （`HttpRequest.buildRequestConfiguration()` 里 requestConfiguration 存在即 return），
   *     因此本插件从不设置 requestConfiguration。
   */
  initCustomerDNS(dnsMap: Map<string, Array<string>>): void {
    this.dnsMap = dnsMap;
  }

  /**
   * 动态自定义 DNS（每次解析回调 Flutter 拿 IP）—— **本轮尚未生效**。
   *
   * 诚实说明：鸿蒙 `rcp.DnsConfiguration.dnsRules` 支持
   * `DynamicDnsRule = (host, port) => IpAddress[]`，但它是**同步**返回，
   * 而回调 Flutter 拿 IP 是**异步**的（BasicMessageChannel），无法在同步函数里 await。
   * 要真正支持只能走自定义网络层（继承 `NetworkClient`/`NetworkProxy`，
   * 在异步 handler 里 await 完 Flutter 回调再改写 request.url），
   * 那等于重新实现整个网络层，且会导致 `onTimeInfo` 失效。
   *
   * 因此本轮只**记录开关**，不做任何假实现：调用不会报错，但动态 DNS 不会生效，
   * 并打一条 warn 让调用方可发现。P3-7 视排期决定是否走自定义网络层方案。
   */
  initCustomerDNSFetch(): void {
    this.initDnsFetch = true;
    PluginLog.warnOnce(
      'initCustomerDNSFetch',
      '[platform difference] initCustomerDNSFetch() has NO effect on HarmonyOS yet. ' +
        'rcp DynamicDnsRule is a synchronous callback ((host, port) => IpAddress[]) and cannot ' +
        'await the asynchronous Flutter fetchDns() round trip. Static mapping via ' +
        'initCustomerDNS() works; dynamic per-request DNS requires a custom NetworkClient ' +
        'implementation which is not shipped in this version.',
    );
  }

  /**
   * 清空凭证缓存。
   *
   * ⚠️ 与 Android 的语义差异：Android 只对 `BridgeCredentialProvider`（临时密钥模式）
   * 生效；鸿蒙的 `CredentialCache` 是**全局单例**，清理会影响所有已注册 service
   * 的缓存凭证。由于本插件的凭证源本身也是全局单个（credentialBridge），
   * 实际效果一致。
   */
  forceInvalidationCredential(): void {
    CredentialBridge.clearCredentialCache();
  }

  /**
   * 灯塔上报开关 —— **鸿蒙无上报模块，空实现**。
   *
   * 这是已确认的平台差异（鸿蒙 SDK 中 beacon/report 零命中），不是偷懒：
   * 鸿蒙侧本就不采集不上报，所以"关闭上报"这个动作本身没有对应物，
   * 也不存在隐私影响。因此这里不打 warn（打了反而是噪音）。
   */
  setCloseBeacon(isCloseBeacon: boolean): void {
    // no-op by design: HarmonyOS COS SDK has no beacon/reporting module at all.
  }

  // ------------------------------------------------------------------
  // 多实例注册
  // ------------------------------------------------------------------

  registerDefaultService(config: PigeonCosXmlServiceConfig, result: Result<string>): void {
    this.doRegisterService(DEFAULT_KEY, config, result);
  }

  registerService(key: string, config: PigeonCosXmlServiceConfig, result: Result<string>): void {
    if (key.length === 0) {
      // 与 Android 的差异（有意）：Android 侧调 result.error() 后**没有 return**，
      // 会继续走到 result.success()，造成一次调用双回复。这里修正为立即返回。
      result.error(new Error('register key cannot be empty'));
      return;
    }
    this.doRegisterService(key, config, result);
  }

  registerDefaultTransferManger(
    config: PigeonCosXmlServiceConfig,
    transferConfig: PigeonTransferConfig | undefined,
    result: Result<string>,
  ): void {
    this.doRegisterTransfer(DEFAULT_KEY, config, transferConfig, result);
  }

  registerTransferManger(
    key: string,
    config: PigeonCosXmlServiceConfig,
    transferConfig: PigeonTransferConfig | undefined,
    result: Result<string>,
  ): void {
    if (key.length === 0) {
      result.error(new Error('register key cannot be empty'));
      return;
    }
    this.doRegisterTransfer(key, config, transferConfig, result);
  }

  private doRegisterService(
    key: string,
    config: PigeonCosXmlServiceConfig,
    result: Result<string>,
  ): void {
    const context: common.Context | null = this.context;
    if (context === null) {
      result.error(new Error('CosPlugin is not attached to a FlutterEngine yet'));
      return;
    }
    try {
      this.registry.registerService(
        key,
        context!,
        config,
        this.credentialBridge?.toCredentialCallBack(),
        this.dnsMap ?? undefined,
      );
      result.success(key);
    } catch (e) {
      result.error(e as Error);
    }
  }

  private doRegisterTransfer(
    key: string,
    config: PigeonCosXmlServiceConfig,
    transferConfig: PigeonTransferConfig | undefined,
    result: Result<string>,
  ): void {
    const context: common.Context | null = this.context;
    if (context === null) {
      result.error(new Error('CosPlugin is not attached to a FlutterEngine yet'));
      return;
    }
    // 鸿蒙 TransferConfig 无这两个字段，不做假实现，只提示
    if (transferConfig !== undefined && transferConfig !== null) {
      if (transferConfig.getForceSimpleUpload() !== undefined &&
        transferConfig.getForceSimpleUpload() !== null) {
        PluginLog.warnOnce(
          'TransferConfig.forceSimpleUpload',
          '[platform difference] TransferConfig.forceSimpleUpload is ignored on HarmonyOS: ' +
            'the SDK has no such switch. Faking it by raising simpleUploadLimit is unsafe ' +
            '(COS simple upload is capped at 5GB), so the value is dropped.',
        );
      }
      if (transferConfig.getEnableVerification() !== undefined &&
        transferConfig.getEnableVerification() !== null) {
        PluginLog.warnOnce(
          'TransferConfig.enableVerification',
          '[platform difference] TransferConfig.enableVerification (CRC64) is ignored on ' +
            'HarmonyOS: the SDK exposes no CRC64 verification switch.',
        );
      }
    }
    try {
      this.registry.registerTransfer(
        key,
        context!,
        config,
        transferConfig,
        this.credentialBridge?.toCredentialCallBack(),
        this.dnsMap ?? undefined,
      );
      result.success(key);
    } catch (e) {
      result.error(e as Error);
    }
  }

  // ------------------------------------------------------------------
  // F. 日志与 CLS —— 16 项鸿蒙不支持，统一「空实现 + 首次调用 warn」
  //
  // 处置依据（设计文档 §7.4 方式 c）：静默 no-op 会让用户以为日志已开启，
  // 抛异常会打断跨平台代码，所以选「不打断但可发现」。
  // ------------------------------------------------------------------

  enableLogcat(enable: boolean): void {
    PluginLog.unsupported('enableLogcat', LOG_SUBSYSTEM_REASON +
      ' Tip: HarmonyOS SDK logs go to hilog and are gated by ' +
      'CosXmlServiceConfig.isDebuggable (CosXmlBaseService.setDebuggable) instead.');
  }

  enableLogFile(enable: boolean): void {
    PluginLog.unsupported('enableLogFile', LOG_SUBSYSTEM_REASON);
  }

  /**
   * 结构化日志监听 —— **降级实现**。
   *
   * 鸿蒙唯一的可用抓手是 `QCloudLogger.logOutputCallback?: (log: string) => void`，
   * 它拿到的是**已格式化的整段字符串**（含 QCloudLogger 自己加的边框装饰）。
   *
   * 因此 `LogEntity` 8 个字段里只有 `timestamp` / `message` 是真实的：
   *  - `level`      恒为 `INFO`（拿不到真实级别）
   *  - `category`   恒为 `PROCESS`（鸿蒙不存在 LogCategory 概念）
   *  - `tag`        恒为 `'QCloudLog'`（真实 tag 被嵌进边框文本，解析不可靠）
   *  - `threadName` 恒为 `'main'`（ArkTS 主线程模型）
   *  - `extras` / `throwable` 恒为 undefined
   *
   * ⚠️ 这意味着 Flutter 侧若按 `entity.level == ERROR` 过滤，将**永远不触发**。
   * 依赖级别/分类过滤的业务请勿使用鸿蒙侧的该回调。
   *
   * 之所以仍然实现而不是空实现：拿到原始日志文本对排查网络/签名问题有实际价值，
   * 且这里会打一条醒目的 warn 把上面的限制讲清楚，属于「可发现的降级」而非静默丢数据。
   *
   * ⚠️ 副作用：一旦设置 `logOutputCallback`，`QCloudLogger.logLevel()` 就不再走
   * 「mClose 提前返回」分支，所有日志都会被格式化一次（即使 debuggable=false）。
   * 因此只在存在 listener 时才安装回调，`removeLogListener` 清空后立即卸载。
   */
  addLogListener(key: number): void {
    PluginLog.warnOnce(
      'addLogListener',
      '[platform difference] addLogListener() on HarmonyOS is a DEGRADED implementation: ' +
        'only LogEntity.timestamp and LogEntity.message carry real data. ' +
        'level is always INFO, category always PROCESS, tag always "QCloudLog", ' +
        'threadName always "main", extras/throwable always null. ' +
        'Filtering by level or category will NOT work on this platform. ' + LOG_SUBSYSTEM_REASON,
    );
    this.logListenerKeys.add(key);
    this.installLogCallback();
  }

  removeLogListener(key: number): void {
    this.logListenerKeys.delete(key);
    if (this.logListenerKeys.size === 0) {
      this.uninstallLogCallback();
    }
  }

  private installLogCallback(): void {
    if (this.logCallbackInstalled) {
      return;
    }
    this.logCallbackInstalled = true;
    // logOutputCallback 是单个静态字段，这里自行 fan-out 给所有 listener key
    QCloudLogger.logOutputCallback = (log: string): void => {
      this.dispatchLog(log);
    };
  }

  private uninstallLogCallback(): void {
    if (!this.logCallbackInstalled) {
      return;
    }
    this.logCallbackInstalled = false;
    QCloudLogger.logOutputCallback = undefined;
  }

  private dispatchLog(log: string): void {
    const api: FlutterCosApi | null = this.flutterCosApi;
    if (api === null || this.logListenerKeys.size === 0) {
      return;
    }
    // enum 必须走生成的 setter/构造器，禁止自行拼数组或塞裸 enum 进 codec
    // （裸 enum 会落到 typeof number 分支，发成 INT32 而不是 type 129，Dart 侧解不出来）。
    this.logListenerKeys.forEach((key: number) => {
      const entity: LogEntity = new LogEntity(
        Date.now(),
        LogLevel.INFO,
        LogCategory.PROCESS,
        'QCloudLog',
        log,
        'main',
        undefined,
        undefined,
      );
      api!.onLog(key, entity, voidReply('onLog'));
    });
  }

  setMinLevel(minLevel: LogLevel): void {
    PluginLog.unsupported('setMinLevel', LOG_SUBSYSTEM_REASON);
  }

  setLogcatMinLevel(minLevel: LogLevel): void {
    PluginLog.unsupported('setLogcatMinLevel', LOG_SUBSYSTEM_REASON);
  }

  setFileMinLevel(minLevel: LogLevel): void {
    PluginLog.unsupported('setFileMinLevel', LOG_SUBSYSTEM_REASON);
  }

  setClsMinLevel(minLevel: LogLevel): void {
    PluginLog.unsupported('setClsMinLevel', LOG_SUBSYSTEM_REASON);
  }

  setDeviceID(deviceID: string): void {
    PluginLog.unsupported('setDeviceID', LOG_SUBSYSTEM_REASON);
  }

  setDeviceModel(deviceModel: string): void {
    PluginLog.unsupported('setDeviceModel', LOG_SUBSYSTEM_REASON);
  }

  setAppVersion(appVersion: string): void {
    PluginLog.unsupported('setAppVersion', LOG_SUBSYSTEM_REASON);
  }

  setExtras(extras: Map<string, string>): void {
    PluginLog.unsupported('setExtras', LOG_SUBSYSTEM_REASON);
  }

  /**
   * 日志文件加密密钥 —— 鸿蒙无日志文件，空实现。
   *
   * ⚠️⚠️ **类型陷阱，勿"修正"**：pigeon 把 `Uint8List` 的 ArkTS 类型声明成了
   * `number[]`，但运行时 codec 读到的是**真实的 `Uint8Array`**（type id 8，
   * 已在 Phase 0 实证）。ArkTS 的 `as` 只是编译期断言、运行时不做转换，
   * 所以这里的 `key` / `iv` 实际是 `Uint8Array` 而非 `number[]`。
   *
   * 本方法是空实现所以不受影响。但若将来要真正使用这两个参数，
   * **不要**按 `number[]` 的语义去遍历/concat（`Array.isArray(key)` 会返回 false），
   * 应先 `key as ESObject as Uint8Array`。
   */
  setLogFileEncryptionKey(key: number[], iv: number[]): void {
    PluginLog.unsupported('setLogFileEncryptionKey', LOG_SUBSYSTEM_REASON);
  }

  /**
   * 日志根目录 —— 鸿蒙无日志文件功能。
   *
   * 返回类型是非空 string，无法空实现，故返回 `""` 并 warn。
   * Flutter 侧应把空串当作「该平台无日志目录」处理。
   */
  getLogRootDir(): string {
    PluginLog.unsupported(
      'getLogRootDir',
      LOG_SUBSYSTEM_REASON + ' An empty string is returned.',
    );
    return '';
  }

  setCLsChannelAnonymous(topicId: string, endpoint: string): void {
    PluginLog.unsupported('setCLsChannelAnonymous', LOG_SUBSYSTEM_REASON);
  }

  setCLsChannelStaticKey(
    topicId: string,
    endpoint: string,
    secretId: string,
    secretKey: string,
  ): void {
    PluginLog.unsupported('setCLsChannelStaticKey', LOG_SUBSYSTEM_REASON);
  }

  setCLsChannelSessionCredential(topicId: string, endpoint: string): void {
    PluginLog.unsupported('setCLsChannelSessionCredential', LOG_SUBSYSTEM_REASON);
  }

  addSensitiveRule(ruleName: string, regex: string): void {
    PluginLog.unsupported('addSensitiveRule', LOG_SUBSYSTEM_REASON);
  }

  removeSensitiveRule(ruleName: string): void {
    PluginLog.unsupported('removeSensitiveRule', LOG_SUBSYSTEM_REASON);
  }
}
