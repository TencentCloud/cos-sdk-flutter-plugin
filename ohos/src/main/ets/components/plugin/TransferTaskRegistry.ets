/*
 * Copyright (c) 2026 Tencent Cloud. All rights reserved.
 * Licensed under the Apache License, Version 2.0 (the "License").
 */

/**
 * 传输任务表：taskId(string) → UploadTask | DownloadTask。
 *
 * 对齐 Android 的 `Map<String, COSXMLTask> taskMap`。
 *
 * ## taskId 的生成方式
 *
 * Android 用 `String.valueOf(task.hashCode())`，ArkTS 没有 hashCode，
 * 这里用**单调自增计数器**。相比 `Date.now()` / `Math.random()`：
 *  - 自增天然无碰撞（Date.now 在同一毫秒内连发两个任务会撞）；
 *  - 结果可复现，便于排查与写测试。
 *
 * taskId 只在插件进程内有效，Flutter 侧把它当作不透明字符串使用，不解析其含义。
 *
 * ## 为什么要区分 upload / download
 *
 * `UploadTask` 与 `DownloadTask` 都继承自泛型基类 `TransferTask<T1, T2>`，
 * 但两者的 T1/T2 不同，ArkTS 里无法用一个 `TransferTask<?, ?>` 变量同时装下二者。
 * 因此本表用两个 Map 分开存，对外用 `pause/resume/cancel` 三个方法统一分派。
 */

import { UploadTask, DownloadTask } from '@tencentcloud/cos';

export class TransferTaskRegistry {
  private uploads: Map<string, UploadTask> = new Map<string, UploadTask>();
  private downloads: Map<string, DownloadTask> = new Map<string, DownloadTask>();

  /** 单调自增的 taskId 序号。不用时间戳/随机数，理由见类注释 */
  private nextId: number = 1;

  /** 生成一个进程内唯一的 taskId */
  generateTaskId(): string {
    const id: number = this.nextId;
    this.nextId = this.nextId + 1;
    return `${id}`;
  }

  putUpload(taskId: string, task: UploadTask): void {
    this.uploads.set(taskId, task);
  }

  putDownload(taskId: string, task: DownloadTask): void {
    this.downloads.set(taskId, task);
  }

  /**
   * 任务结束（成功/失败）时移除，避免 Map 无限增长。
   * 对齐 Android 在 onSuccess/onFail 里 `taskMap.remove(taskKey)` 的做法。
   *
   * ⚠️ 注意**不能**在 pause 时移除：暂停后还要能 resume，Android 同样保留。
   */
  remove(taskId: string): void {
    this.uploads.delete(taskId);
    this.downloads.delete(taskId);
  }

  getUpload(taskId: string): UploadTask | undefined {
    return this.uploads.get(taskId);
  }

  getDownload(taskId: string): DownloadTask | undefined {
    return this.downloads.get(taskId);
  }

  has(taskId: string): boolean {
    return this.uploads.has(taskId) || this.downloads.has(taskId);
  }

  /** onDetachedFromEngine 时清理 */
  clear(): void {
    this.uploads.clear();
    this.downloads.clear();
  }
}
