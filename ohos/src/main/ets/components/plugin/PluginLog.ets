/*
 * Copyright (c) 2026 Tencent Cloud. All rights reserved.
 * Licensed under the Apache License, Version 2.0 (the "License").
 */

/**
 * 插件自身的日志出口。
 *
 * 为什么不直接用 `QCloudLogger`：`QCloudLogger.mClose` 默认是 **true**
 * （只有 `CosXmlBaseService.setDebuggable(true)` 才会打开），
 * 且 `logLevel()` 开头就是
 *   `if (QCloudLogger.mClose && !QCloudLogger.logOutputCallback) return`
 * —— 也就是默认配置下 `QCloudLogger.warn(...)` **什么都不会输出**。
 *
 * 而「鸿蒙不支持某能力」这类降级提示必须无条件可见，否则就退化成了静默 no-op，
 * 用户会以为日志/CLS 已经生效。所以这里直接走 hilog。
 */

import hilog from '@ohos.hilog';

/** 与 QCloudLogger 使用同一日志领域，便于一起过滤 */
const DOMAIN: number = 0x0369;
const TAG: string = 'CosFlutterPlugin';

export class PluginLog {
  /** 已经提示过的 key，用于「仅首次调用告警」，避免高频调用刷屏 */
  private static warnedOnce: Set<string> = new Set<string>();

  static info(message: string): void {
    hilog.info(DOMAIN, TAG, '%{public}s', message);
  }

  static warn(message: string): void {
    hilog.warn(DOMAIN, TAG, '%{public}s', message);
  }

  static error(message: string): void {
    hilog.error(DOMAIN, TAG, '%{public}s', message);
  }

  /**
   * 同一个 key 只在首次调用时打一条 warn。
   *
   * 用于「鸿蒙平台不支持 X」的提示：既不静默 no-op（用户能发现），
   * 也不抛异常打断跨平台代码，也不会因为业务反复调用而刷满日志。
   */
  static warnOnce(key: string, message: string): void {
    if (PluginLog.warnedOnce.has(key)) {
      return;
    }
    PluginLog.warnedOnce.add(key);
    PluginLog.warn(message);
  }

  /** 生成「该能力鸿蒙不支持」的标准提示语 */
  static unsupported(api: string, reason: string): void {
    PluginLog.warnOnce(
      api,
      `[platform difference] ${api}() is NOT supported on HarmonyOS and does nothing. ${reason}`,
    );
  }
}
