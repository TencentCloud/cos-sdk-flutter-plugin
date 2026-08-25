/*
 * Copyright (c) 2026 Tencent Cloud. All rights reserved.
 * Licensed under the Apache License, Version 2.0 (the "License").
 */

/**
 * 错误映射层：鸿蒙 `CosError` → pigeon 的 `CosXmlClientException` / `CosXmlServiceException`。
 *
 * 这是「错一条就静默丢信息」的高危逻辑，映射表以 Android 侧 `ClientErrorCode`
 * （qcloud-sdk-android `com.tencent.cos.xml.common.ClientErrorCode`）为权威基准。
 */

import { CosError, CosErrorType, CosErrorCode, CosClientError, CosServiceError } from '@tencentcloud/cos';
import { CosXmlClientException, CosXmlServiceException } from './Pigeon';

/**
 * 鸿蒙 `CosErrorCode`（字符串枚举，9 值）→ Flutter `CosXmlClientException.errorCode`（int）。
 *
 * 前 5 项与 Android `ClientErrorCode` 严格一致（已对照源码核实）：
 *   UNKNOWN(-10000) / INVALID_ARGUMENT(10000) / INVALID_CREDENTIALS(10001)
 *   POOR_NETWORK(20003, 鸿蒙叫 NETWORK) / USER_CANCELLED(30000)
 *
 * 后 4 项是**鸿蒙独有**的错误码，Android `ClientErrorCode` 中没有等价项。
 * 为避免与 Android 既有取值冲突（Android 已占用 -10000 / 1000x / 2000x / 3000x / 40000），
 * 这里统一放到 90000 段作为「鸿蒙扩展区」。Flutter 侧收到 9xxxx 即可判定为鸿蒙特有错误。
 */
export class ClientErrorCodeMapping {
  /** 未知错误。对齐 Android ClientErrorCode.UNKNOWN */
  static readonly UNKNOWN: number = -10000;
  /** 参数校验失败。对齐 Android ClientErrorCode.INVALID_ARGUMENT */
  static readonly INVALID_ARGUMENT: number = 10000;
  /** 密钥信息校验失败。对齐 Android ClientErrorCode.INVALID_CREDENTIALS */
  static readonly INVALID_CREDENTIALS: number = 10001;
  /** 网络异常。对齐 Android ClientErrorCode.POOR_NETWORK(20003, "NetworkError") */
  static readonly NETWORK: number = 20003;
  /** 用户取消。对齐 Android ClientErrorCode.USER_CANCELLED */
  static readonly USER_CANCELLED: number = 30000;

  /** 鸿蒙独有：服务端错误被当作 client error 上抛（正常路径下应走 CosXmlServiceException） */
  static readonly HARMONY_SERVICE_ERROR: number = 90001;
  /** 鸿蒙独有：任务调度层错误（QCloudTaskError） */
  static readonly HARMONY_TASK: number = 90002;
  /** 鸿蒙独有：用户暂停。注意通常应被 isUserPausedOrCancelled 拦截而非上抛 */
  static readonly HARMONY_USER_PAUSED: number = 90003;
  /** 鸿蒙独有：数据格式错误（如服务端响应不符合实体定义） */
  static readonly HARMONY_DATA_FORMAT: number = 90004;
}

/**
 * HTTP 状态码 → 标准 reason phrase。
 *
 * 鸿蒙 `CosServiceError` **没有** httpMsg 字段（rcp 的 onComplete 只回 statusCode），
 * 因此按 RFC 7231 / RFC 4918 的标准短语近似填充。这是显式降级，不是精确还原
 * 服务端返回的 status line。
 */
const HTTP_REASON_PHRASES: Map<number, string> = new Map<number, string>([
  [200, 'OK'],
  [201, 'Created'],
  [202, 'Accepted'],
  [204, 'No Content'],
  [206, 'Partial Content'],
  [301, 'Moved Permanently'],
  [302, 'Found'],
  [304, 'Not Modified'],
  [307, 'Temporary Redirect'],
  [400, 'Bad Request'],
  [401, 'Unauthorized'],
  [403, 'Forbidden'],
  [404, 'Not Found'],
  [405, 'Method Not Allowed'],
  [406, 'Not Acceptable'],
  [408, 'Request Timeout'],
  [409, 'Conflict'],
  [411, 'Length Required'],
  [412, 'Precondition Failed'],
  [413, 'Payload Too Large'],
  [416, 'Range Not Satisfiable'],
  [451, 'Unavailable For Legal Reasons'],
  [500, 'Internal Server Error'],
  [501, 'Not Implemented'],
  [502, 'Bad Gateway'],
  [503, 'Service Unavailable'],
  [504, 'Gateway Timeout'],
]);

/** Flutter 侧 CosXmlServiceException.serviceName 固定填 "cos"（鸿蒙 SDK 无该字段） */
const SERVICE_NAME: string = 'cos';

export class ErrorConverter {
  /**
   * 鸿蒙 `CosErrorCode` → Flutter int 错误码。
   */
  static toClientErrorCode(code: CosErrorCode | undefined): number {
    switch (code) {
      case CosErrorCode.INVALID_ARGUMENT:
        return ClientErrorCodeMapping.INVALID_ARGUMENT;
      case CosErrorCode.INVALID_CREDENTIALS:
        return ClientErrorCodeMapping.INVALID_CREDENTIALS;
      case CosErrorCode.NETWORK:
        return ClientErrorCodeMapping.NETWORK;
      case CosErrorCode.USER_CANCELLED:
        return ClientErrorCodeMapping.USER_CANCELLED;
      case CosErrorCode.SERVICE_ERROR:
        return ClientErrorCodeMapping.HARMONY_SERVICE_ERROR;
      case CosErrorCode.TASK:
        return ClientErrorCodeMapping.HARMONY_TASK;
      case CosErrorCode.USER_PAUSED:
        return ClientErrorCodeMapping.HARMONY_USER_PAUSED;
      case CosErrorCode.DATA_FORMAT:
        return ClientErrorCodeMapping.HARMONY_DATA_FORMAT;
      case CosErrorCode.UNKNOWN:
        return ClientErrorCodeMapping.UNKNOWN;
      default:
        return ClientErrorCodeMapping.UNKNOWN;
    }
  }

  /** statusCode → 标准 reason phrase，未收录时回退到 "HTTP <code>" */
  static httpReasonPhrase(statusCode: number): string {
    const phrase: string | undefined = HTTP_REASON_PHRASES.get(statusCode);
    return phrase !== undefined ? phrase : `HTTP ${statusCode}`;
  }

  /**
   * 该 error 是否属于「用户主动暂停/取消」。
   *
   * 鸿蒙 SDK 的 `pause()` / `cancel()` 会走 `onFail` 回调（`UploadTask` 抛
   * `CosTransferPauseError`，`DownloadTask` 抛 `QCloudUserCancelError` 转出的
   * `CosClientError(USER_CANCELLED)`）。传输层**必须**用本方法拦截，
   * 不要把它们当作传输失败上抛给 Flutter 的 `resultFailCallback`，
   * 否则暂停/取消会被 Flutter 侧误报为失败。
   */
  static isUserPausedOrCancelled(error: ESObject): boolean {
    if (error === null || error === undefined) {
      return false;
    }
    if (error instanceof CosError) {
      const cosError: CosError = error as CosError;
      return cosError.cosErrorCode === CosErrorCode.USER_PAUSED ||
        cosError.cosErrorCode === CosErrorCode.USER_CANCELLED;
    }
    return false;
  }

  /** 是否应构造 CosXmlServiceException（而非 ClientException） */
  static isServiceError(error: ESObject): boolean {
    if (error instanceof CosServiceError) {
      return true;
    }
    if (error instanceof CosError) {
      return (error as CosError).type === CosErrorType.Service;
    }
    return false;
  }

  /**
   * 构造 Flutter 侧的 `CosXmlServiceException`。
   *
   * 字段来源：
   *   statusCode   ← CosServiceError.httpCode
   *   httpMsg      ← 按 statusCode 查标准 reason phrase（鸿蒙无此字段，显式降级）
   *   requestId    ← CosServiceError.requestId
   *   errorCode    ← CosServiceError.code
   *   errorMessage ← CosServiceError.message
   *   serviceName  ← 固定 "cos"（鸿蒙无此字段）
   *   details      ← resource / traceId 汇总（便于排查）
   */
  static toServiceException(error: ESObject): CosXmlServiceException {
    if (error instanceof CosServiceError) {
      const e: CosServiceError = error as CosServiceError;
      const statusCode: number = e.httpCode;
      const detailParts: Array<string> = new Array<string>();
      if (e.resource !== undefined && e.resource !== null) {
        detailParts.push(`resource=${e.resource}`);
      }
      if (e.traceId !== undefined && e.traceId !== null) {
        detailParts.push(`traceId=${e.traceId}`);
      }
      return new CosXmlServiceException(
        statusCode,
        ErrorConverter.httpReasonPhrase(statusCode),
        e.requestId,
        e.code,
        e.message,
        SERVICE_NAME,
        detailParts.length > 0 ? detailParts.join(', ') : undefined,
      );
    }
    // 非 CosServiceError 但被判定为 Service 类：兜底成 500，不丢 message
    const message: string = ErrorConverter.messageOf(error);
    return new CosXmlServiceException(
      500,
      ErrorConverter.httpReasonPhrase(500),
      undefined,
      undefined,
      message,
      SERVICE_NAME,
      undefined,
    );
  }

  /**
   * 构造 Flutter 侧的 `CosXmlClientException`。
   */
  static toClientException(error: ESObject): CosXmlClientException {
    let code: number = ClientErrorCodeMapping.UNKNOWN;
    let details: string | undefined = undefined;
    if (error instanceof CosError) {
      code = ErrorConverter.toClientErrorCode((error as CosError).cosErrorCode);
    }
    if (error instanceof CosClientError) {
      const detail: ESObject = (error as CosClientError).detail;
      if (detail !== undefined && detail !== null) {
        details = ErrorConverter.stringifyDetail(detail);
      }
    }
    if (details === undefined && error instanceof Error) {
      details = (error as Error).stack;
    }
    return new CosXmlClientException(code, ErrorConverter.messageOf(error), details);
  }

  /**
   * 转成一个可直接丢给 pigeon `Result.error()` 的 Error 对象。
   *
   * pigeon 的 `Result<T>.error(error: Error)` 走 `wrapError()`，它只会取
   * `error.toString()` / `name` / `message`。所以这里返回一个 Error，其 message
   * 承载结构化信息，让 Flutter 侧的 PlatformException 至少可读。
   *
   * 说明：pigeon 生成的同步 HostApi 通道无法传结构化异常对象，只能传三元组
   * （code/name/message）。这是与 Android 侧一致的限制 —— Android 也是把
   * CosXmlClientException 作为 Throwable 丢给 result.error()。
   */
  static toFlutterError(error: ESObject): Error {
    if (ErrorConverter.isServiceError(error)) {
      const se: CosXmlServiceException = ErrorConverter.toServiceException(error);
      const err: Error = new Error(
        `CosXmlServiceException: statusCode=${se.getStatusCode()}` +
          `, errorCode=${se.getErrorCode()}` +
          `, errorMessage=${se.getErrorMessage()}` +
          `, requestId=${se.getRequestId()}`,
      );
      err.name = 'CosXmlServiceException';
      return err;
    }
    const ce: CosXmlClientException = ErrorConverter.toClientException(error);
    const err: Error = new Error(
      `CosXmlClientException: errorCode=${ce.getErrorCode()}, message=${ce.getMessage()}`,
    );
    err.name = 'CosXmlClientException';
    return err;
  }

  private static messageOf(error: ESObject): string {
    if (error === null || error === undefined) {
      return 'unknown error';
    }
    if (error instanceof Error) {
      const msg: string = (error as Error).message;
      return msg !== undefined && msg !== null && msg.length > 0 ? msg : (error as Error).name;
    }
    if (typeof error === 'string') {
      return error as string;
    }
    return `${error}`;
  }

  private static stringifyDetail(detail: ESObject): string {
    if (detail instanceof Error) {
      const e: Error = detail as Error;
      return e.stack !== undefined && e.stack !== null ? e.stack! : e.message;
    }
    try {
      return JSON.stringify(detail);
    } catch (e) {
      return `${detail}`;
    }
  }
}
