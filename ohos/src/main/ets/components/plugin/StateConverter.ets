/*
 * Copyright (c) 2026 Tencent Cloud. All rights reserved.
 * Licensed under the Apache License, Version 2.0 (the "License").
 */

/**
 * 传输状态映射：鸿蒙 `TransferState`（6 值）→ Flutter `TransferState`（9 值，字符串名）。
 *
 * Flutter 侧 `lib/cos_transfer_manger.dart` 用 `TransferState.values.byName(state)`
 * 反解，因此这里必须返回**与 Dart enum 名字逐字一致**的字符串，
 * 见 `lib/enums.dart`。
 *
 * Flutter 侧的 CONSTRAINED / RESUMED_WAITING / UNKNOWN 三个值鸿蒙不产生
 * （鸿蒙无网络约束队列语义，resume 后直接回 Processing），这是已声明的平台差异。
 */

import { TransferState } from '@tencentcloud/cos';

export class FlutterTransferState {
  static readonly CONSTRAINED: string = 'CONSTRAINED';
  static readonly WAITING: string = 'WAITING';
  static readonly IN_PROGRESS: string = 'IN_PROGRESS';
  static readonly PAUSED: string = 'PAUSED';
  static readonly RESUMED_WAITING: string = 'RESUMED_WAITING';
  static readonly COMPLETED: string = 'COMPLETED';
  static readonly CANCELED: string = 'CANCELED';
  static readonly FAILED: string = 'FAILED';
  static readonly UNKNOWN: string = 'UNKNOWN';
}

export class StateConverter {
  /**
   * 鸿蒙 TransferState → Flutter TransferState 名字。
   *
   * | 鸿蒙        | Flutter       |
   * | ----------- | ------------- |
   * | Waiting     | WAITING       |
   * | Processing  | IN_PROGRESS   |
   * | Pause       | PAUSED        |
   * | Success     | COMPLETED     |
   * | Canceled    | CANCELED      |
   * | Error       | FAILED        |
   */
  static toFlutterStateName(state: TransferState): string {
    switch (state) {
      case TransferState.Waiting:
        return FlutterTransferState.WAITING;
      case TransferState.Processing:
        return FlutterTransferState.IN_PROGRESS;
      case TransferState.Pause:
        return FlutterTransferState.PAUSED;
      case TransferState.Success:
        return FlutterTransferState.COMPLETED;
      case TransferState.Canceled:
        return FlutterTransferState.CANCELED;
      case TransferState.Error:
        return FlutterTransferState.FAILED;
      default:
        // 鸿蒙 SDK 新增枚举值时不至于让 Flutter 侧 byName 抛异常
        return FlutterTransferState.UNKNOWN;
    }
  }
}
