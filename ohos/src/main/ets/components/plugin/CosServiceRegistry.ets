/*
 * Copyright (c) 2026 Tencent Cloud. All rights reserved.
 * Licensed under the Apache License, Version 2.0 (the "License").
 */

/**
 * 多实例管理：serviceKey / transferKey → `CosXmlBaseService` 实例。
 *
 * Flutter 侧靠字符串 key 区分多个 service / transferManager，默认 key 是空字符串 `""`。
 * 结构与 Android 侧的 `Map<String, CosXmlService>` + `Map<String, TransferManager>` 对齐。
 *
 * 实现选择（与设计文档一致）：**统一走 `new CosXmlBaseService(...)` + 自管 Map**，
 * 不用 `CosXmlBaseService.initDefaultService()` 静态方式，避免静态默认实例与
 * Map 中实例并存造成的语义歧义。
 */

import common from '@ohos.app.ability.common';
import { CosXmlBaseService, TransferConfig as HarmonyTransferConfig, CredentialCallBack } from '@tencentcloud/cos';
import {
  CosXmlServiceConfig as PigeonCosXmlServiceConfig,
  TransferConfig as PigeonTransferConfig,
} from './Pigeon';
import { ConfigConverter, ServiceConfigBundle } from './ConfigConverter';

/** Flutter 侧默认 key */
export const DEFAULT_KEY: string = '';
/** 抛错信息里默认 key 的展示名，对齐 Android */
const DEFAULT_KEY_DISPLAY: string = 'default';

/**
 * 一个已注册的 transfer 条目。
 *
 * 鸿蒙没有独立的 `TransferManager` 对象 —— `upload()` / `download()` 直接挂在
 * `CosXmlBaseService` 上，且 `upload()` 每次调用时接收 `config?: TransferConfig`。
 * 因此 `registerTransferManger` 在鸿蒙侧落地为「创建一个 service 实例 +
 * 记住它的 TransferConfig」，发起传输时再把 config 传进 `upload()`。
 */
export class TransferEntry {
  readonly service: CosXmlBaseService;
  /** 该 transfer 的分块配置；Flutter 未传时为 undefined，走 SDK 默认 */
  readonly transferConfig?: HarmonyTransferConfig;
  /** config.signInUrl，需逐 request 赋到 request.isSignedInURL */
  readonly signInUrl?: boolean;

  constructor(
    service: CosXmlBaseService,
    transferConfig?: HarmonyTransferConfig,
    signInUrl?: boolean,
  ) {
    this.service = service;
    this.transferConfig = transferConfig;
    this.signInUrl = signInUrl;
  }
}

/** 一个已注册的 service 条目 */
export class ServiceEntry {
  readonly service: CosXmlBaseService;
  /** config.signInUrl，需逐 request 赋到 request.isSignedInURL */
  readonly signInUrl?: boolean;

  constructor(service: CosXmlBaseService, signInUrl?: boolean) {
    this.service = service;
    this.signInUrl = signInUrl;
  }
}

export class CosServiceRegistry {
  private services: Map<string, ServiceEntry> = new Map<string, ServiceEntry>();
  private transfers: Map<string, TransferEntry> = new Map<string, TransferEntry>();

  /**
   * 注册一个 service。
   *
   * @param key serviceKey，默认实例传 DEFAULT_KEY（空串）
   * @param context 用 `binding.getApplicationContext()`
   * @param pigeonConfig Flutter 下发的配置
   * @param credentialCallBack 凭证回调，未初始化凭证时可为 undefined
   *        （此时只能靠 request 级凭证签名，对齐 Android「provider 为 null 时用两参构造」）
   * @param dnsMap `initCustomerDNS` 存下的静态 DNS 映射
   */
  registerService(
    key: string,
    context: common.Context,
    pigeonConfig: PigeonCosXmlServiceConfig,
    credentialCallBack?: CredentialCallBack,
    dnsMap?: Map<string, Array<string>>,
  ): void {
    const bundle: ServiceConfigBundle = ConfigConverter.toHarmonyConfig(pigeonConfig, dnsMap);
    const service: CosXmlBaseService = new CosXmlBaseService(context, bundle.config, credentialCallBack);
    this.services.set(key, new ServiceEntry(service, bundle.signInUrl));
  }

  /**
   * 注册一个 transferManager（鸿蒙侧 = service 实例 + TransferConfig）。
   */
  registerTransfer(
    key: string,
    context: common.Context,
    pigeonConfig: PigeonCosXmlServiceConfig,
    pigeonTransferConfig?: PigeonTransferConfig,
    credentialCallBack?: CredentialCallBack,
    dnsMap?: Map<string, Array<string>>,
  ): void {
    const bundle: ServiceConfigBundle = ConfigConverter.toHarmonyConfig(pigeonConfig, dnsMap);
    const service: CosXmlBaseService = new CosXmlBaseService(context, bundle.config, credentialCallBack);
    const transferConfig: HarmonyTransferConfig | undefined =
      CosServiceRegistry.toHarmonyTransferConfig(pigeonTransferConfig);
    this.transfers.set(key, new TransferEntry(service, transferConfig, bundle.signInUrl));
  }

  /**
   * 取 service，取不到时抛错。错误信息与 Android 逐字一致：
   * `"<key> CosService unregistered, Please register first"`
   */
  getServiceEntry(serviceKey: string): ServiceEntry {
    const entry: ServiceEntry | undefined = this.services.get(serviceKey);
    if (entry === undefined) {
      const display: string = serviceKey === DEFAULT_KEY ? DEFAULT_KEY_DISPLAY : serviceKey;
      throw new Error(`${display} CosService unregistered, Please register first`);
    }
    return entry;
  }

  getService(serviceKey: string): CosXmlBaseService {
    return this.getServiceEntry(serviceKey).service;
  }

  /**
   * 取 transfer 条目，取不到时抛错。错误信息与 Android 逐字一致：
   * `"<key> TransferManager unregistered, Please register first"`
   */
  getTransferEntry(transferKey: string): TransferEntry {
    const entry: TransferEntry | undefined = this.transfers.get(transferKey);
    if (entry === undefined) {
      const display: string = transferKey === DEFAULT_KEY ? DEFAULT_KEY_DISPLAY : transferKey;
      throw new Error(`${display} TransferManager unregistered, Please register first`);
    }
    return entry;
  }

  hasService(serviceKey: string): boolean {
    return this.services.has(serviceKey);
  }

  hasTransfer(transferKey: string): boolean {
    return this.transfers.has(transferKey);
  }

  /** onDetachedFromEngine 时清理 */
  clear(): void {
    this.services.clear();
    this.transfers.clear();
  }

  /**
   * pigeon `TransferConfig` → 鸿蒙 `TransferConfig`。
   *
   * 字段对应（注意两端命名与语义都不同）：
   * | Flutter              | 鸿蒙               | 说明 |
   * | -------------------- | ------------------ | ---- |
   * | divisionForUpload    | simpleUploadLimit  | 小于该值走简单上传 |
   * | sliceSizeForUpload   | sliceLength        | 分块大小 |
   * | forceSimpleUpload    | —                  | **不支持**，见下 |
   * | enableVerification   | —                  | **不支持**，见下 |
   *
   * `forceSimpleUpload`：鸿蒙 `TransferConfig` 无此字段。用「simpleUploadLimit 置极大值」
   * 假实现是危险的（COS 简单上传上限 5GB，超过会失败），因此按设计决策**不支持**，
   * 由调用方（CosPlugin）打 warn 说明。
   *
   * `enableVerification`（CRC64 校验）：鸿蒙 SDK 无对应开关，同样不支持。
   */
  static toHarmonyTransferConfig(
    pigeonTransferConfig?: PigeonTransferConfig,
  ): HarmonyTransferConfig | undefined {
    if (pigeonTransferConfig === undefined || pigeonTransferConfig === null) {
      return undefined;
    }
    const config: HarmonyTransferConfig = new HarmonyTransferConfig();
    const divisionForUpload: number | undefined = pigeonTransferConfig.getDivisionForUpload();
    if (divisionForUpload !== undefined && divisionForUpload !== null) {
      config.simpleUploadLimit = divisionForUpload;
    }
    const sliceSizeForUpload: number | undefined = pigeonTransferConfig.getSliceSizeForUpload();
    if (sliceSizeForUpload !== undefined && sliceSizeForUpload !== null) {
      config.sliceLength = sliceSizeForUpload;
    }
    return config;
  }
}
