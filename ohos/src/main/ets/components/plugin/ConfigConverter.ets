/*
 * Copyright (c) 2026 Tencent Cloud. All rights reserved.
 * Licensed under the Apache License, Version 2.0 (the "License").
 */

/**
 * 配置映射层：Flutter 侧 pigeon `CosXmlServiceConfig`（15 字段）
 * → 鸿蒙 `@tencentcloud/cos` 的 `CosXmlServiceConfig`。
 *
 * 字段名在两端有多处不同（connectionTimeout→connectTimeout、socketTimeout→readTimeout、
 * isHttps→protocol 字符串、domainSwitch→disableBackupHost 取反），
 * 漏一条就静默丢配置，故独立成文件便于 review。
 */

import { rcp } from '@kit.RemoteCommunicationKit';
import {
  CosXmlServiceConfig as HarmonyCosXmlServiceConfig,
  CosXmlBaseService,
  COS_VERSION,
} from '@tencentcloud/cos';
import { CosXmlServiceConfig as PigeonCosXmlServiceConfig } from './Pigeon';
import { PluginLog } from './PluginLog';

/** 与 Android `CosXmlServiceConfig.ACCELERATE_HOST_FORMAT` 逐字一致 */
const ACCELERATE_HOST_FORMAT: string = '${bucket}.cos.accelerate.myqcloud.com';
/** 与 Android `CosXmlServiceConfig.DEFAULT_HOST_FORMAT` 逐字一致，也是鸿蒙 config.host 的默认值 */
const DEFAULT_HOST_FORMAT: string = '${bucket}.cos.${region}.myqcloud.com';
/** Android 侧 userAgentExtended 的默认值 */
const DEFAULT_UA_EXTENDED: string = 'FlutterPlugin';
const USER_AGENT_HEADER: string = 'User-Agent';

/**
 * 转换产物。
 *
 * 鸿蒙 `CosXmlServiceConfig` 没有 `signInUrl` 字段（只有 request 级 `isSignedInURL`），
 * 所以该值单独带出来，由调用方在构造每个 request 后赋到 `request.isSignedInURL`。
 */
export class ServiceConfigBundle {
  /** 传给 `new CosXmlBaseService(context, config, credentialCallBack)` 的配置 */
  readonly config: HarmonyCosXmlServiceConfig;
  /**
   * Flutter 侧 `config.signInUrl`。鸿蒙无 config 级字段，需逐 request 设
   * `request.isSignedInURL = signInUrl`。undefined 表示 Flutter 未传，保持 SDK 默认（false）。
   */
  readonly signInUrl: boolean | undefined;

  constructor(config: HarmonyCosXmlServiceConfig, signInUrl: boolean | undefined) {
    this.config = config;
    this.signInUrl = signInUrl;
  }
}

export class ConfigConverter {
  /**
   * @param pigeonConfig Flutter 侧下发的配置
   * @param dnsMap `initCustomerDNS` 存下来的静态 DNS 映射（域名 → IP 列表），可空
   */
  static toHarmonyConfig(
    pigeonConfig: PigeonCosXmlServiceConfig,
    dnsMap?: Map<string, Array<string>>,
  ): ServiceConfigBundle {
    // region 通过构造函数传入（鸿蒙 config.region 可为 undefined，此时 host 不做占位符替换）
    const config: HarmonyCosXmlServiceConfig = new HarmonyCosXmlServiceConfig(pigeonConfig.getRegion());

    // --- 超时：注意两端字段名不同 ---
    const connectionTimeout: number | undefined = pigeonConfig.getConnectionTimeout();
    if (connectionTimeout !== undefined && connectionTimeout !== null) {
      config.connectTimeout = connectionTimeout;
    }
    const socketTimeout: number | undefined = pigeonConfig.getSocketTimeout();
    if (socketTimeout !== undefined && socketTimeout !== null) {
      config.readTimeout = socketTimeout;
    }

    // --- 协议：鸿蒙用字符串而非 bool ---
    const isHttps: boolean | undefined = pigeonConfig.getIsHttps();
    if (isHttps !== undefined && isHttps !== null) {
      config.protocol = isHttps ? 'https' : 'http';
    }

    // --- host 系列 ---
    // 优先级对齐 Android（`CosXmlServiceConfig.getRequestHost` / `getHostFormat`）：
    //   host > hostFormat > accelerate > 默认
    // 鸿蒙只有一个 `config.host` 字段，本身就支持 ${bucket}/${region} 占位符，
    // 因此 hostFormat 与 host 都落到同一字段，靠赋值顺序体现优先级。
    const accelerate: boolean | undefined = pigeonConfig.getAccelerate();
    if (accelerate === true) {
      config.host = ACCELERATE_HOST_FORMAT;
    }
    const hostFormat: string | undefined = pigeonConfig.getHostFormat();
    if (hostFormat !== undefined && hostFormat !== null && hostFormat.length > 0) {
      config.host = hostFormat;
    }
    const host: string | undefined = pigeonConfig.getHost();
    if (host !== undefined && host !== null && host.length > 0) {
      // 固定 host（无占位符）时 replace 是 no-op，鸿蒙 getRequestHost 会原样返回
      config.host = host;
    }

    const port: number | undefined = pigeonConfig.getPort();
    if (port !== undefined && port !== null) {
      config.port = port;
    }

    // --- domainSwitch：语义**取反** ---
    // Flutter/Android 的 domainSwitch=true 表示「允许切备用域名」，
    // 鸿蒙是 disableBackupHost=true 表示「禁用备用域名」。
    const domainSwitch: boolean | undefined = pigeonConfig.getDomainSwitch();
    if (domainSwitch !== undefined && domainSwitch !== null) {
      config.disableBackupHost = !domainSwitch;
    }

    // --- 公共 header ---
    const customHeaders: Map<string | undefined, string | undefined> | undefined =
      pigeonConfig.getCustomHeaders();
    if (customHeaders !== undefined && customHeaders !== null) {
      customHeaders.forEach((value: string | undefined, key: string | undefined) => {
        if (key !== undefined && key !== null && key.length > 0 &&
          value !== undefined && value !== null && value.length > 0) {
          config.headers.set(key, value);
        }
      });
    }

    // --- User-Agent ---
    // ⚠️ 鸿蒙是**覆盖**语义（`CosXmlBaseService.buildHttpRequest` 里 config.headers
    // 后展开会盖掉 request 的默认 UA），而 Android 的 setUserAgentExtended 是**追加**。
    // 所以这里必须自己把 SDK 版本号拼进去，否则会丢掉 `cos-harmony-sdk-{ver}`。
    const userAgent: string | undefined = pigeonConfig.getUserAgent();
    const uaExtended: string =
      userAgent !== undefined && userAgent !== null && userAgent.length > 0
        ? userAgent
        : DEFAULT_UA_EXTENDED;
    config.headers.set(USER_AGENT_HEADER, `cos-harmony-sdk-${COS_VERSION} ${uaExtended}`);

    // --- 不参与签名的 header ---
    const noSignHeaders: Array<string | undefined> | undefined = pigeonConfig.getNoSignHeaders();
    if (noSignHeaders !== undefined && noSignHeaders !== null) {
      noSignHeaders.forEach((key: string | undefined) => {
        if (key !== undefined && key !== null && key.length > 0) {
          config.noSignHeaderKeys.add(key);
        }
      });
    }

    // --- 静态自定义 DNS ---
    // ⚠️ 陷阱 T4：鸿蒙 `HttpRequest.buildRequestConfiguration()` 里若
    // `requestConfiguration` 存在会直接 return，dnsConfiguration 分支不执行。
    // 因此本插件**从不**设置 config.requestConfiguration，两者不可同时用。
    if (dnsMap !== undefined && dnsMap !== null && dnsMap.size > 0) {
      const rules: Array<rcp.StaticDnsRule> = ConfigConverter.buildStaticDnsRules(dnsMap, config);
      if (rules.length > 0) {
        config.dnsConfiguration = { dnsRules: rules };
      }
    }

    // --- isDebuggable ---
    // ⚠️ 鸿蒙的调试开关是**静态方法**（`CosXmlBaseService.setDebuggable`），
    // 非 per-service。多 service 配不同值会互相覆盖 —— 最后一次 register 生效。
    // 这是已知的平台限制，需在 README「平台差异」中声明。
    const isDebuggable: boolean | undefined = pigeonConfig.getIsDebuggable();
    if (isDebuggable !== undefined && isDebuggable !== null) {
      CosXmlBaseService.setDebuggable(isDebuggable);
    }

    // --- dnsCache：鸿蒙无对应配置项，空实现 ---
    // rcp 是否自带 DNS 缓存未在官方文档明确（待核验），这里不做任何动作。
    const dnsCache: boolean | undefined = pigeonConfig.getDnsCache();
    if (dnsCache !== undefined && dnsCache !== null) {
      PluginLog.warnOnce(
        'config.dnsCache',
        '[platform difference] CosXmlServiceConfig.dnsCache is ignored on HarmonyOS: ' +
          'the rcp network stack manages DNS caching itself and exposes no switch.',
      );
    }

    return new ServiceConfigBundle(config, pigeonConfig.getSignInUrl());
  }

  /**
   * 把 `Map<域名, IP列表>` 转成 rcp 的 StaticDnsRules。
   *
   * ⚠️ `rcp.StaticDnsRule` **要求 host + port 两者都匹配**，而 Flutter 侧
   * `initCustomerDNS` 只给域名不给端口。这里按 config 推导端口：
   *   显式 config.port(>0) 优先，否则 https→443 / http→80。
   * 若业务实际请求端口与此不同，该条规则不会命中（不会报错，只是不生效）。
   */
  private static buildStaticDnsRules(
    dnsMap: Map<string, Array<string>>,
    config: HarmonyCosXmlServiceConfig,
  ): Array<rcp.StaticDnsRule> {
    const defaultPort: number = config.port > 0
      ? config.port
      : (config.protocol === 'http' ? 80 : 443);
    const rules: Array<rcp.StaticDnsRule> = new Array<rcp.StaticDnsRule>();
    dnsMap.forEach((ips: Array<string>, domain: string) => {
      if (domain !== undefined && domain !== null && domain.length > 0 &&
        ips !== undefined && ips !== null && ips.length > 0) {
        rules.push({ host: domain, port: defaultPort, ipAddresses: ips });
      }
    });
    return rules;
  }

  /** 供 `getObjectUrl` 等场景使用的默认 host format */
  static defaultHostFormat(): string {
    return DEFAULT_HOST_FORMAT;
  }
}
