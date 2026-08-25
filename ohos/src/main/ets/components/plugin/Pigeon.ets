/*
* Copyright (C) 2024 Huawei Device Co., Ltd.
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
*     http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*/
import StandardMessageCodec from '@ohos/flutter_ohos/src/main/ets/plugin/common/StandardMessageCodec';
import BasicMessageChannel, { Reply } from '@ohos/flutter_ohos/src/main/ets/plugin/common/BasicMessageChannel';
import { BinaryMessenger } from '@ohos/flutter_ohos/src/main/ets/plugin/common/BinaryMessenger';
import MessageCodec from '@ohos/flutter_ohos/src/main/ets/plugin/common/MessageCodec';
import { ByteBuffer } from '@ohos/flutter_ohos/src/main/ets/util/ByteBuffer';


/** Error class for passing custom error details to Flutter via a thrown PlatformException. */
export class FlutterError implements Error {

  /** The error code. */
  public code: string;

  /** The error name. */
  public name: string;

  /** The error message. */
  public message: string;
  /** The error stack. */
  public stack?: string;

  constructor(code: string, name: string, message: string, stack?: string) {
    this.code = code;
    this.name = name;
    this.message = message;
    this.stack = stack;
  }
}

function wrapError(error: Error): Array<Object | null> {
  let errorList: Array<Object | null> = new Array<Object | null>(3);
  if (error instanceof FlutterError) {
    let err: FlutterError = error as FlutterError;
    errorList[0] = err.code;
    errorList[1] = err.name;
    errorList[2] = err.message;
  } else {
    errorList[0] = error.toString();
    errorList[1] = error.name;
    errorList[2] = "Cause: " + error.message + ", Stacktrace: " + error.stack;
  }
  return errorList;
}

/*
*  日志级别枚举
* 
*  Generated enum from Pigeon that represents data sent in messages.
*/
export enum LogLevel {
  VERBOSE,
  DEBUG,
  INFO,
  WARN,
  ERROR
}

/*
*  日志级别枚举
* 
*  Generated enum Companion class from Pigeon that represents data sent 
   in messages.Do not delete otherwise enum type data transfer will be failed
*/
export class LogLevelEnum {
  index: string | null = null;
  constructor(index: string) {
    this.index = index;
  }
}

/* Generated enum from Pigeon that represents data sent in messages.*/
export enum LogCategory {
  PROCESS,
  RESULT,
  NETWORK,
  PROBE,
  ERROR
}

/* Generated enum Companion class from Pigeon that represents data sent 
   in messages.Do not delete otherwise enum type data transfer will be failed*/
export class LogCategoryEnum {
  index: string | null = null;
  constructor(index: string) {
    this.index = index;
  }
}

/* Generated class from Pigeon that represents data sent in messages.*/
export class CosXmlServiceConfig {
  private region?: string;

  public setRegion(region: string | undefined): void {
    this.region = region;
  }

  getRegion(): string | undefined {
    return this.region;
  }

  private connectionTimeout?: number;

  public setConnectionTimeout(connectionTimeout: number | undefined): void {
    this.connectionTimeout = connectionTimeout;
  }

  getConnectionTimeout(): number | undefined {
    return this.connectionTimeout;
  }

  private socketTimeout?: number;

  public setSocketTimeout(socketTimeout: number | undefined): void {
    this.socketTimeout = socketTimeout;
  }

  getSocketTimeout(): number | undefined {
    return this.socketTimeout;
  }

  private isHttps?: boolean;

  public setIsHttps(isHttps: boolean | undefined): void {
    this.isHttps = isHttps;
  }

  getIsHttps(): boolean | undefined {
    return this.isHttps;
  }

  private host?: string;

  public setHost(host: string | undefined): void {
    this.host = host;
  }

  getHost(): string | undefined {
    return this.host;
  }

  private hostFormat?: string;

  public setHostFormat(hostFormat: string | undefined): void {
    this.hostFormat = hostFormat;
  }

  getHostFormat(): string | undefined {
    return this.hostFormat;
  }

  private port?: number;

  public setPort(port: number | undefined): void {
    this.port = port;
  }

  getPort(): number | undefined {
    return this.port;
  }

  private isDebuggable?: boolean;

  public setIsDebuggable(isDebuggable: boolean | undefined): void {
    this.isDebuggable = isDebuggable;
  }

  getIsDebuggable(): boolean | undefined {
    return this.isDebuggable;
  }

  private signInUrl?: boolean;

  public setSignInUrl(signInUrl: boolean | undefined): void {
    this.signInUrl = signInUrl;
  }

  getSignInUrl(): boolean | undefined {
    return this.signInUrl;
  }

  private userAgent?: string;

  public setUserAgent(userAgent: string | undefined): void {
    this.userAgent = userAgent;
  }

  getUserAgent(): string | undefined {
    return this.userAgent;
  }

  private dnsCache?: boolean;

  public setDnsCache(dnsCache: boolean | undefined): void {
    this.dnsCache = dnsCache;
  }

  getDnsCache(): boolean | undefined {
    return this.dnsCache;
  }

  private accelerate?: boolean;

  public setAccelerate(accelerate: boolean | undefined): void {
    this.accelerate = accelerate;
  }

  getAccelerate(): boolean | undefined {
    return this.accelerate;
  }

  private domainSwitch?: boolean;

  public setDomainSwitch(domainSwitch: boolean | undefined): void {
    this.domainSwitch = domainSwitch;
  }

  getDomainSwitch(): boolean | undefined {
    return this.domainSwitch;
  }

  private customHeaders?: Map<string | undefined, string | undefined>;

  public setCustomHeaders(customHeaders: Map<string | undefined, string | undefined> | undefined): void {
    this.customHeaders = customHeaders;
  }

  getCustomHeaders(): Map<string | undefined, string | undefined> | undefined {
    return this.customHeaders;
  }

  private noSignHeaders?: Array<string | undefined>;

  public setNoSignHeaders(noSignHeaders: Array<string | undefined> | undefined): void {
    this.noSignHeaders = noSignHeaders;
  }

  getNoSignHeaders(): Array<string | undefined> | undefined {
    return this.noSignHeaders;
  }

  constructor(region?: string, connectionTimeout?: number, socketTimeout?: number, isHttps?: boolean, host?: string, hostFormat?: string, port?: number, isDebuggable?: boolean, signInUrl?: boolean, userAgent?: string, dnsCache?: boolean, accelerate?: boolean, domainSwitch?: boolean, customHeaders?: Map<string | undefined, string | undefined>, noSignHeaders?: Array<string | undefined>) {
    this.region = region;
    this.connectionTimeout = connectionTimeout;
    this.socketTimeout = socketTimeout;
    this.isHttps = isHttps;
    this.host = host;
    this.hostFormat = hostFormat;
    this.port = port;
    this.isDebuggable = isDebuggable;
    this.signInUrl = signInUrl;
    this.userAgent = userAgent;
    this.dnsCache = dnsCache;
    this.accelerate = accelerate;
    this.domainSwitch = domainSwitch;
    this.customHeaders = customHeaders;
    this.noSignHeaders = noSignHeaders;
  }

  toList(): Array<Object | null> {
    let arr: Array<Object | null> = new Array<Object | null>();
    if (this.region === undefined || this.region === null) {
      arr.push(null);
    } else {
      arr.push(this.region);
    }
    if (this.connectionTimeout === undefined || this.connectionTimeout === null) {
      arr.push(null);
    } else {
      arr.push(this.connectionTimeout);
    }
    if (this.socketTimeout === undefined || this.socketTimeout === null) {
      arr.push(null);
    } else {
      arr.push(this.socketTimeout);
    }
    if (this.isHttps === undefined || this.isHttps === null) {
      arr.push(null);
    } else {
      arr.push(this.isHttps);
    }
    if (this.host === undefined || this.host === null) {
      arr.push(null);
    } else {
      arr.push(this.host);
    }
    if (this.hostFormat === undefined || this.hostFormat === null) {
      arr.push(null);
    } else {
      arr.push(this.hostFormat);
    }
    if (this.port === undefined || this.port === null) {
      arr.push(null);
    } else {
      arr.push(this.port);
    }
    if (this.isDebuggable === undefined || this.isDebuggable === null) {
      arr.push(null);
    } else {
      arr.push(this.isDebuggable);
    }
    if (this.signInUrl === undefined || this.signInUrl === null) {
      arr.push(null);
    } else {
      arr.push(this.signInUrl);
    }
    if (this.userAgent === undefined || this.userAgent === null) {
      arr.push(null);
    } else {
      arr.push(this.userAgent);
    }
    if (this.dnsCache === undefined || this.dnsCache === null) {
      arr.push(null);
    } else {
      arr.push(this.dnsCache);
    }
    if (this.accelerate === undefined || this.accelerate === null) {
      arr.push(null);
    } else {
      arr.push(this.accelerate);
    }
    if (this.domainSwitch === undefined || this.domainSwitch === null) {
      arr.push(null);
    } else {
      arr.push(this.domainSwitch);
    }
    if (this.customHeaders === undefined || this.customHeaders === null) {
      arr.push(null);
    } else {
      arr.push(this.customHeaders);
    }
    if (this.noSignHeaders === undefined || this.noSignHeaders === null) {
      arr.push(null);
    } else {
      arr.push(this.noSignHeaders);
    }
    return arr;
  }

  static fromList(arr: Object[]): CosXmlServiceConfig {
    let region: string | undefined = undefined;
    if (arr[0] !== null && arr[0] !== undefined) {
      let regionObject: Object = arr[0];
      region = regionObject as string | undefined;
    }
    let connectionTimeout: number | undefined = undefined;
    if (arr[1] !== null && arr[1] !== undefined) {
      let connectionTimeoutObject: Object = arr[1];
      connectionTimeout = connectionTimeoutObject as number | undefined;
    }
    let socketTimeout: number | undefined = undefined;
    if (arr[2] !== null && arr[2] !== undefined) {
      let socketTimeoutObject: Object = arr[2];
      socketTimeout = socketTimeoutObject as number | undefined;
    }
    let isHttps: boolean | undefined = undefined;
    if (arr[3] !== null && arr[3] !== undefined) {
      let isHttpsObject: Object = arr[3];
      isHttps = isHttpsObject as boolean | undefined;
    }
    let host: string | undefined = undefined;
    if (arr[4] !== null && arr[4] !== undefined) {
      let hostObject: Object = arr[4];
      host = hostObject as string | undefined;
    }
    let hostFormat: string | undefined = undefined;
    if (arr[5] !== null && arr[5] !== undefined) {
      let hostFormatObject: Object = arr[5];
      hostFormat = hostFormatObject as string | undefined;
    }
    let port: number | undefined = undefined;
    if (arr[6] !== null && arr[6] !== undefined) {
      let portObject: Object = arr[6];
      port = portObject as number | undefined;
    }
    let isDebuggable: boolean | undefined = undefined;
    if (arr[7] !== null && arr[7] !== undefined) {
      let isDebuggableObject: Object = arr[7];
      isDebuggable = isDebuggableObject as boolean | undefined;
    }
    let signInUrl: boolean | undefined = undefined;
    if (arr[8] !== null && arr[8] !== undefined) {
      let signInUrlObject: Object = arr[8];
      signInUrl = signInUrlObject as boolean | undefined;
    }
    let userAgent: string | undefined = undefined;
    if (arr[9] !== null && arr[9] !== undefined) {
      let userAgentObject: Object = arr[9];
      userAgent = userAgentObject as string | undefined;
    }
    let dnsCache: boolean | undefined = undefined;
    if (arr[10] !== null && arr[10] !== undefined) {
      let dnsCacheObject: Object = arr[10];
      dnsCache = dnsCacheObject as boolean | undefined;
    }
    let accelerate: boolean | undefined = undefined;
    if (arr[11] !== null && arr[11] !== undefined) {
      let accelerateObject: Object = arr[11];
      accelerate = accelerateObject as boolean | undefined;
    }
    let domainSwitch: boolean | undefined = undefined;
    if (arr[12] !== null && arr[12] !== undefined) {
      let domainSwitchObject: Object = arr[12];
      domainSwitch = domainSwitchObject as boolean | undefined;
    }
    let customHeaders: Map<string | undefined, string | undefined> | undefined = undefined;
    if (arr[13] !== null && arr[13] !== undefined) {
      let customHeadersObject: Object = arr[13];
      customHeaders = customHeadersObject as Map<string | undefined, string | undefined> | undefined;
    }
    let noSignHeaders: Array<string | undefined> | undefined = undefined;
    if (arr[14] !== null && arr[14] !== undefined) {
      let noSignHeadersObject: Object = arr[14];
      noSignHeaders = noSignHeadersObject as Array<string | undefined> | undefined;
    }
    return new CosXmlServiceConfig(region, connectionTimeout, socketTimeout, isHttps, host, hostFormat, port, isDebuggable, signInUrl, userAgent, dnsCache, accelerate, domainSwitch, customHeaders, noSignHeaders);
  }
}

/* Generated class from Pigeon that represents data sent in messages.*/
export class TransferConfig {
  private forceSimpleUpload?: boolean;

  public setForceSimpleUpload(forceSimpleUpload: boolean | undefined): void {
    this.forceSimpleUpload = forceSimpleUpload;
  }

  getForceSimpleUpload(): boolean | undefined {
    return this.forceSimpleUpload;
  }

  private enableVerification?: boolean;

  public setEnableVerification(enableVerification: boolean | undefined): void {
    this.enableVerification = enableVerification;
  }

  getEnableVerification(): boolean | undefined {
    return this.enableVerification;
  }

  private divisionForUpload?: number;

  public setDivisionForUpload(divisionForUpload: number | undefined): void {
    this.divisionForUpload = divisionForUpload;
  }

  getDivisionForUpload(): number | undefined {
    return this.divisionForUpload;
  }

  private sliceSizeForUpload?: number;

  public setSliceSizeForUpload(sliceSizeForUpload: number | undefined): void {
    this.sliceSizeForUpload = sliceSizeForUpload;
  }

  getSliceSizeForUpload(): number | undefined {
    return this.sliceSizeForUpload;
  }

  constructor(forceSimpleUpload?: boolean, enableVerification?: boolean, divisionForUpload?: number, sliceSizeForUpload?: number) {
    this.forceSimpleUpload = forceSimpleUpload;
    this.enableVerification = enableVerification;
    this.divisionForUpload = divisionForUpload;
    this.sliceSizeForUpload = sliceSizeForUpload;
  }

  toList(): Array<Object | null> {
    let arr: Array<Object | null> = new Array<Object | null>();
    if (this.forceSimpleUpload === undefined || this.forceSimpleUpload === null) {
      arr.push(null);
    } else {
      arr.push(this.forceSimpleUpload);
    }
    if (this.enableVerification === undefined || this.enableVerification === null) {
      arr.push(null);
    } else {
      arr.push(this.enableVerification);
    }
    if (this.divisionForUpload === undefined || this.divisionForUpload === null) {
      arr.push(null);
    } else {
      arr.push(this.divisionForUpload);
    }
    if (this.sliceSizeForUpload === undefined || this.sliceSizeForUpload === null) {
      arr.push(null);
    } else {
      arr.push(this.sliceSizeForUpload);
    }
    return arr;
  }

  static fromList(arr: Object[]): TransferConfig {
    let forceSimpleUpload: boolean | undefined = undefined;
    if (arr[0] !== null && arr[0] !== undefined) {
      let forceSimpleUploadObject: Object = arr[0];
      forceSimpleUpload = forceSimpleUploadObject as boolean | undefined;
    }
    let enableVerification: boolean | undefined = undefined;
    if (arr[1] !== null && arr[1] !== undefined) {
      let enableVerificationObject: Object = arr[1];
      enableVerification = enableVerificationObject as boolean | undefined;
    }
    let divisionForUpload: number | undefined = undefined;
    if (arr[2] !== null && arr[2] !== undefined) {
      let divisionForUploadObject: Object = arr[2];
      divisionForUpload = divisionForUploadObject as number | undefined;
    }
    let sliceSizeForUpload: number | undefined = undefined;
    if (arr[3] !== null && arr[3] !== undefined) {
      let sliceSizeForUploadObject: Object = arr[3];
      sliceSizeForUpload = sliceSizeForUploadObject as number | undefined;
    }
    return new TransferConfig(forceSimpleUpload, enableVerification, divisionForUpload, sliceSizeForUpload);
  }
}

/* Generated class from Pigeon that represents data sent in messages.*/
export class STSCredentialScope {
  private action: string;

  public setAction(action: string): void {
    this.action = action;
  }

  getAction(): string {
    return this.action;
  }

  private region: string;

  public setRegion(region: string): void {
    this.region = region;
  }

  getRegion(): string {
    return this.region;
  }

  private bucket?: string;

  public setBucket(bucket: string | undefined): void {
    this.bucket = bucket;
  }

  getBucket(): string | undefined {
    return this.bucket;
  }

  private prefix?: string;

  public setPrefix(prefix: string | undefined): void {
    this.prefix = prefix;
  }

  getPrefix(): string | undefined {
    return this.prefix;
  }

  constructor(action: string, region: string, bucket?: string, prefix?: string) {
    this.action = action;
    this.region = region;
    this.bucket = bucket;
    this.prefix = prefix;
  }

  toList(): Array<Object | null> {
    let arr: Array<Object | null> = new Array<Object | null>();
    if (this.action === undefined || this.action === null) {
      arr.push(null);
    } else {
      arr.push(this.action);
    }
    if (this.region === undefined || this.region === null) {
      arr.push(null);
    } else {
      arr.push(this.region);
    }
    if (this.bucket === undefined || this.bucket === null) {
      arr.push(null);
    } else {
      arr.push(this.bucket);
    }
    if (this.prefix === undefined || this.prefix === null) {
      arr.push(null);
    } else {
      arr.push(this.prefix);
    }
    return arr;
  }

  static fromList(arr: Object[]): STSCredentialScope {
    let actionObject: Object = arr[0];
    const action: string = actionObject as string;
    let regionObject: Object = arr[1];
    const region: string = regionObject as string;
    let bucket: string | undefined = undefined;
    if (arr[2] !== null && arr[2] !== undefined) {
      let bucketObject: Object = arr[2];
      bucket = bucketObject as string | undefined;
    }
    let prefix: string | undefined = undefined;
    if (arr[3] !== null && arr[3] !== undefined) {
      let prefixObject: Object = arr[3];
      prefix = prefixObject as string | undefined;
    }
    return new STSCredentialScope(action, region, bucket, prefix);
  }
}

/* Generated class from Pigeon that represents data sent in messages.*/
export class SessionQCloudCredentials {
  private secretId: string;

  public setSecretId(secretId: string): void {
    this.secretId = secretId;
  }

  getSecretId(): string {
    return this.secretId;
  }

  private secretKey: string;

  public setSecretKey(secretKey: string): void {
    this.secretKey = secretKey;
  }

  getSecretKey(): string {
    return this.secretKey;
  }

  private token: string;

  public setToken(token: string): void {
    this.token = token;
  }

  getToken(): string {
    return this.token;
  }

  private startTime?: number;

  public setStartTime(startTime: number | undefined): void {
    this.startTime = startTime;
  }

  getStartTime(): number | undefined {
    return this.startTime;
  }

  private expiredTime: number;

  public setExpiredTime(expiredTime: number): void {
    this.expiredTime = expiredTime;
  }

  getExpiredTime(): number {
    return this.expiredTime;
  }

  constructor(secretId: string, secretKey: string, token: string, expiredTime: number, startTime?: number) {
    this.secretId = secretId;
    this.secretKey = secretKey;
    this.token = token;
    this.startTime = startTime;
    this.expiredTime = expiredTime;
  }

  toList(): Array<Object | null> {
    let arr: Array<Object | null> = new Array<Object | null>();
    if (this.secretId === undefined || this.secretId === null) {
      arr.push(null);
    } else {
      arr.push(this.secretId);
    }
    if (this.secretKey === undefined || this.secretKey === null) {
      arr.push(null);
    } else {
      arr.push(this.secretKey);
    }
    if (this.token === undefined || this.token === null) {
      arr.push(null);
    } else {
      arr.push(this.token);
    }
    if (this.startTime === undefined || this.startTime === null) {
      arr.push(null);
    } else {
      arr.push(this.startTime);
    }
    if (this.expiredTime === undefined || this.expiredTime === null) {
      arr.push(null);
    } else {
      arr.push(this.expiredTime);
    }
    return arr;
  }

  static fromList(arr: Object[]): SessionQCloudCredentials {
    let secretIdObject: Object = arr[0];
    const secretId: string = secretIdObject as string;
    let secretKeyObject: Object = arr[1];
    const secretKey: string = secretKeyObject as string;
    let tokenObject: Object = arr[2];
    const token: string = tokenObject as string;
    let startTime: number | undefined = undefined;
    if (arr[3] !== null && arr[3] !== undefined) {
      let startTimeObject: Object = arr[3];
      startTime = startTimeObject as number | undefined;
    }
    let expiredTimeObject: Object = arr[4];
    const expiredTime: number = expiredTimeObject as number;
    return new SessionQCloudCredentials(secretId, secretKey, token, expiredTime, startTime);
  }
}

/* Generated class from Pigeon that represents data sent in messages.*/
export class CosXmlResult {
  private eTag?: string;

  public setETag(eTag: string | undefined): void {
    this.eTag = eTag;
  }

  getETag(): string | undefined {
    return this.eTag;
  }

  private accessUrl?: string;

  public setAccessUrl(accessUrl: string | undefined): void {
    this.accessUrl = accessUrl;
  }

  getAccessUrl(): string | undefined {
    return this.accessUrl;
  }

  private callbackResult?: CallbackResult;

  public setCallbackResult(callbackResult: CallbackResult | undefined): void {
    this.callbackResult = callbackResult;
  }

  getCallbackResult(): CallbackResult | undefined {
    return this.callbackResult;
  }

  constructor(eTag?: string, accessUrl?: string, callbackResult?: CallbackResult) {
    this.eTag = eTag;
    this.accessUrl = accessUrl;
    this.callbackResult = callbackResult;
  }

  toList(): Array<Object | null> {
    let arr: Array<Object | null> = new Array<Object | null>();
    if (this.eTag === undefined || this.eTag === null) {
      arr.push(null);
    } else {
      arr.push(this.eTag);
    }
    if (this.accessUrl === undefined || this.accessUrl === null) {
      arr.push(null);
    } else {
      arr.push(this.accessUrl);
    }
    if (this.callbackResult === undefined || this.callbackResult === null) {
      arr.push(null);
    } else {
      arr.push(this.callbackResult);
    }
    return arr;
  }

  static fromList(arr: Object[]): CosXmlResult {
    let eTag: string | undefined = undefined;
    if (arr[0] !== null && arr[0] !== undefined) {
      let eTagObject: Object = arr[0];
      eTag = eTagObject as string | undefined;
    }
    let accessUrl: string | undefined = undefined;
    if (arr[1] !== null && arr[1] !== undefined) {
      let accessUrlObject: Object = arr[1];
      accessUrl = accessUrlObject as string | undefined;
    }
    let callbackResult: CallbackResult | undefined = undefined;
    if (arr[2] !== null && arr[2] !== undefined) {
      let callbackResultObject: Object = arr[2];
      callbackResult = callbackResultObject as CallbackResult | undefined;
    }
    return new CosXmlResult(eTag, accessUrl, callbackResult);
  }
}

/* Generated class from Pigeon that represents data sent in messages.*/
export class CallbackResult {
  private status: number;

  public setStatus(status: number): void {
    this.status = status;
  }

  getStatus(): number {
    return this.status;
  }

  private callbackBody?: string;

  public setCallbackBody(callbackBody: string | undefined): void {
    this.callbackBody = callbackBody;
  }

  getCallbackBody(): string | undefined {
    return this.callbackBody;
  }

  private error?: CallbackResultError;

  public setError(error: CallbackResultError | undefined): void {
    this.error = error;
  }

  getError(): CallbackResultError | undefined {
    return this.error;
  }

  constructor(status: number, callbackBody?: string, error?: CallbackResultError) {
    this.status = status;
    this.callbackBody = callbackBody;
    this.error = error;
  }

  toList(): Array<Object | null> {
    let arr: Array<Object | null> = new Array<Object | null>();
    if (this.status === undefined || this.status === null) {
      arr.push(null);
    } else {
      arr.push(this.status);
    }
    if (this.callbackBody === undefined || this.callbackBody === null) {
      arr.push(null);
    } else {
      arr.push(this.callbackBody);
    }
    if (this.error === undefined || this.error === null) {
      arr.push(null);
    } else {
      arr.push(this.error);
    }
    return arr;
  }

  static fromList(arr: Object[]): CallbackResult {
    let statusObject: Object = arr[0];
    const status: number = statusObject as number;
    let callbackBody: string | undefined = undefined;
    if (arr[1] !== null && arr[1] !== undefined) {
      let callbackBodyObject: Object = arr[1];
      callbackBody = callbackBodyObject as string | undefined;
    }
    let error: CallbackResultError | undefined = undefined;
    if (arr[2] !== null && arr[2] !== undefined) {
      let errorObject: Object = arr[2];
      error = errorObject as CallbackResultError | undefined;
    }
    return new CallbackResult(status, callbackBody, error);
  }
}

/* Generated class from Pigeon that represents data sent in messages.*/
export class CallbackResultError {
  private code?: string;

  public setCode(code: string | undefined): void {
    this.code = code;
  }

  getCode(): string | undefined {
    return this.code;
  }

  private message?: string;

  public setMessage(message: string | undefined): void {
    this.message = message;
  }

  getMessage(): string | undefined {
    return this.message;
  }

  constructor(code?: string, message?: string) {
    this.code = code;
    this.message = message;
  }

  toList(): Array<Object | null> {
    let arr: Array<Object | null> = new Array<Object | null>();
    if (this.code === undefined || this.code === null) {
      arr.push(null);
    } else {
      arr.push(this.code);
    }
    if (this.message === undefined || this.message === null) {
      arr.push(null);
    } else {
      arr.push(this.message);
    }
    return arr;
  }

  static fromList(arr: Object[]): CallbackResultError {
    let code: string | undefined = undefined;
    if (arr[0] !== null && arr[0] !== undefined) {
      let codeObject: Object = arr[0];
      code = codeObject as string | undefined;
    }
    let message: string | undefined = undefined;
    if (arr[1] !== null && arr[1] !== undefined) {
      let messageObject: Object = arr[1];
      message = messageObject as string | undefined;
    }
    return new CallbackResultError(code, message);
  }
}

/* Generated class from Pigeon that represents data sent in messages.*/
export class CosXmlClientException {
  private errorCode: number;

  public setErrorCode(errorCode: number): void {
    this.errorCode = errorCode;
  }

  getErrorCode(): number {
    return this.errorCode;
  }

  private message?: string;

  public setMessage(message: string | undefined): void {
    this.message = message;
  }

  getMessage(): string | undefined {
    return this.message;
  }

  private details?: string;

  public setDetails(details: string | undefined): void {
    this.details = details;
  }

  getDetails(): string | undefined {
    return this.details;
  }

  constructor(errorCode: number, message?: string, details?: string) {
    this.errorCode = errorCode;
    this.message = message;
    this.details = details;
  }

  toList(): Array<Object | null> {
    let arr: Array<Object | null> = new Array<Object | null>();
    if (this.errorCode === undefined || this.errorCode === null) {
      arr.push(null);
    } else {
      arr.push(this.errorCode);
    }
    if (this.message === undefined || this.message === null) {
      arr.push(null);
    } else {
      arr.push(this.message);
    }
    if (this.details === undefined || this.details === null) {
      arr.push(null);
    } else {
      arr.push(this.details);
    }
    return arr;
  }

  static fromList(arr: Object[]): CosXmlClientException {
    let errorCodeObject: Object = arr[0];
    const errorCode: number = errorCodeObject as number;
    let message: string | undefined = undefined;
    if (arr[1] !== null && arr[1] !== undefined) {
      let messageObject: Object = arr[1];
      message = messageObject as string | undefined;
    }
    let details: string | undefined = undefined;
    if (arr[2] !== null && arr[2] !== undefined) {
      let detailsObject: Object = arr[2];
      details = detailsObject as string | undefined;
    }
    return new CosXmlClientException(errorCode, message, details);
  }
}

/* Generated class from Pigeon that represents data sent in messages.*/
export class CosXmlServiceException {
  private statusCode: number;

  public setStatusCode(statusCode: number): void {
    this.statusCode = statusCode;
  }

  getStatusCode(): number {
    return this.statusCode;
  }

  private httpMsg?: string;

  public setHttpMsg(httpMsg: string | undefined): void {
    this.httpMsg = httpMsg;
  }

  getHttpMsg(): string | undefined {
    return this.httpMsg;
  }

  private requestId?: string;

  public setRequestId(requestId: string | undefined): void {
    this.requestId = requestId;
  }

  getRequestId(): string | undefined {
    return this.requestId;
  }

  private errorCode?: string;

  public setErrorCode(errorCode: string | undefined): void {
    this.errorCode = errorCode;
  }

  getErrorCode(): string | undefined {
    return this.errorCode;
  }

  private errorMessage?: string;

  public setErrorMessage(errorMessage: string | undefined): void {
    this.errorMessage = errorMessage;
  }

  getErrorMessage(): string | undefined {
    return this.errorMessage;
  }

  private serviceName?: string;

  public setServiceName(serviceName: string | undefined): void {
    this.serviceName = serviceName;
  }

  getServiceName(): string | undefined {
    return this.serviceName;
  }

  private details?: string;

  public setDetails(details: string | undefined): void {
    this.details = details;
  }

  getDetails(): string | undefined {
    return this.details;
  }

  constructor(statusCode: number, httpMsg?: string, requestId?: string, errorCode?: string, errorMessage?: string, serviceName?: string, details?: string) {
    this.statusCode = statusCode;
    this.httpMsg = httpMsg;
    this.requestId = requestId;
    this.errorCode = errorCode;
    this.errorMessage = errorMessage;
    this.serviceName = serviceName;
    this.details = details;
  }

  toList(): Array<Object | null> {
    let arr: Array<Object | null> = new Array<Object | null>();
    if (this.statusCode === undefined || this.statusCode === null) {
      arr.push(null);
    } else {
      arr.push(this.statusCode);
    }
    if (this.httpMsg === undefined || this.httpMsg === null) {
      arr.push(null);
    } else {
      arr.push(this.httpMsg);
    }
    if (this.requestId === undefined || this.requestId === null) {
      arr.push(null);
    } else {
      arr.push(this.requestId);
    }
    if (this.errorCode === undefined || this.errorCode === null) {
      arr.push(null);
    } else {
      arr.push(this.errorCode);
    }
    if (this.errorMessage === undefined || this.errorMessage === null) {
      arr.push(null);
    } else {
      arr.push(this.errorMessage);
    }
    if (this.serviceName === undefined || this.serviceName === null) {
      arr.push(null);
    } else {
      arr.push(this.serviceName);
    }
    if (this.details === undefined || this.details === null) {
      arr.push(null);
    } else {
      arr.push(this.details);
    }
    return arr;
  }

  static fromList(arr: Object[]): CosXmlServiceException {
    let statusCodeObject: Object = arr[0];
    const statusCode: number = statusCodeObject as number;
    let httpMsg: string | undefined = undefined;
    if (arr[1] !== null && arr[1] !== undefined) {
      let httpMsgObject: Object = arr[1];
      httpMsg = httpMsgObject as string | undefined;
    }
    let requestId: string | undefined = undefined;
    if (arr[2] !== null && arr[2] !== undefined) {
      let requestIdObject: Object = arr[2];
      requestId = requestIdObject as string | undefined;
    }
    let errorCode: string | undefined = undefined;
    if (arr[3] !== null && arr[3] !== undefined) {
      let errorCodeObject: Object = arr[3];
      errorCode = errorCodeObject as string | undefined;
    }
    let errorMessage: string | undefined = undefined;
    if (arr[4] !== null && arr[4] !== undefined) {
      let errorMessageObject: Object = arr[4];
      errorMessage = errorMessageObject as string | undefined;
    }
    let serviceName: string | undefined = undefined;
    if (arr[5] !== null && arr[5] !== undefined) {
      let serviceNameObject: Object = arr[5];
      serviceName = serviceNameObject as string | undefined;
    }
    let details: string | undefined = undefined;
    if (arr[6] !== null && arr[6] !== undefined) {
      let detailsObject: Object = arr[6];
      details = detailsObject as string | undefined;
    }
    return new CosXmlServiceException(statusCode, httpMsg, requestId, errorCode, errorMessage, serviceName, details);
  }
}

/* Generated class from Pigeon that represents data sent in messages.*/
export class Owner {
  private id: string;

  public setId(id: string): void {
    this.id = id;
  }

  getId(): string {
    return this.id;
  }

  private disPlayName?: string;

  public setDisPlayName(disPlayName: string | undefined): void {
    this.disPlayName = disPlayName;
  }

  getDisPlayName(): string | undefined {
    return this.disPlayName;
  }

  constructor(id: string, disPlayName?: string) {
    this.id = id;
    this.disPlayName = disPlayName;
  }

  toList(): Array<Object | null> {
    let arr: Array<Object | null> = new Array<Object | null>();
    if (this.id === undefined || this.id === null) {
      arr.push(null);
    } else {
      arr.push(this.id);
    }
    if (this.disPlayName === undefined || this.disPlayName === null) {
      arr.push(null);
    } else {
      arr.push(this.disPlayName);
    }
    return arr;
  }

  static fromList(arr: Object[]): Owner {
    let idObject: Object = arr[0];
    const id: string = idObject as string;
    let disPlayName: string | undefined = undefined;
    if (arr[1] !== null && arr[1] !== undefined) {
      let disPlayNameObject: Object = arr[1];
      disPlayName = disPlayNameObject as string | undefined;
    }
    return new Owner(id, disPlayName);
  }
}

/* Generated class from Pigeon that represents data sent in messages.*/
export class LogEntity {
  private timestamp: number;

  public setTimestamp(timestamp: number): void {
    this.timestamp = timestamp;
  }

  getTimestamp(): number {
    return this.timestamp;
  }

  private level: LogLevel;

  public setLevel(level: LogLevel): void {
    this.level = level;
  }

  getLevel(): LogLevel {
    return this.level;
  }

  private category: LogCategory;

  public setCategory(category: LogCategory): void {
    this.category = category;
  }

  getCategory(): LogCategory {
    return this.category;
  }

  private tag: string;

  public setTag(tag: string): void {
    this.tag = tag;
  }

  getTag(): string {
    return this.tag;
  }

  private message: string;

  public setMessage(message: string): void {
    this.message = message;
  }

  getMessage(): string {
    return this.message;
  }

  private threadName: string;

  public setThreadName(threadName: string): void {
    this.threadName = threadName;
  }

  getThreadName(): string {
    return this.threadName;
  }

  private extras?: Map<string | undefined, string | undefined>;

  public setExtras(extras: Map<string | undefined, string | undefined> | undefined): void {
    this.extras = extras;
  }

  getExtras(): Map<string | undefined, string | undefined> | undefined {
    return this.extras;
  }

  private throwable?: string;

  public setThrowable(throwable: string | undefined): void {
    this.throwable = throwable;
  }

  getThrowable(): string | undefined {
    return this.throwable;
  }

  constructor(timestamp: number, level: LogLevel, category: LogCategory, tag: string, message: string, threadName: string, extras?: Map<string | undefined, string | undefined>, throwable?: string) {
    this.timestamp = timestamp;
    this.level = level;
    this.category = category;
    this.tag = tag;
    this.message = message;
    this.threadName = threadName;
    this.extras = extras;
    this.throwable = throwable;
  }

  toList(): Array<Object | null> {
    let arr: Array<Object | null> = new Array<Object | null>();
    if (this.timestamp === undefined || this.timestamp === null) {
      arr.push(null);
    } else {
      arr.push(this.timestamp);
    }
    if (this.level === undefined || this.level === null) {
      arr.push(null);
    } else {
      const levelStr = LogLevel[this.level as number];
      arr.push(new LogLevelEnum(levelStr));
    }
    if (this.category === undefined || this.category === null) {
      arr.push(null);
    } else {
      const categoryStr = LogCategory[this.category as number];
      arr.push(new LogCategoryEnum(categoryStr));
    }
    if (this.tag === undefined || this.tag === null) {
      arr.push(null);
    } else {
      arr.push(this.tag);
    }
    if (this.message === undefined || this.message === null) {
      arr.push(null);
    } else {
      arr.push(this.message);
    }
    if (this.threadName === undefined || this.threadName === null) {
      arr.push(null);
    } else {
      arr.push(this.threadName);
    }
    if (this.extras === undefined || this.extras === null) {
      arr.push(null);
    } else {
      arr.push(this.extras);
    }
    if (this.throwable === undefined || this.throwable === null) {
      arr.push(null);
    } else {
      arr.push(this.throwable);
    }
    return arr;
  }

  static fromList(arr: Object[]): LogEntity {
    let timestampObject: Object = arr[0];
    const timestamp: number = timestampObject as number;
    const levelStr: string = arr[1] as string;
    const level: LogLevel = LogLevel[levelStr];
    const categoryStr: string = arr[2] as string;
    const category: LogCategory = LogCategory[categoryStr];
    let tagObject: Object = arr[3];
    const tag: string = tagObject as string;
    let messageObject: Object = arr[4];
    const message: string = messageObject as string;
    let threadNameObject: Object = arr[5];
    const threadName: string = threadNameObject as string;
    let extras: Map<string | undefined, string | undefined> | undefined = undefined;
    if (arr[6] !== null && arr[6] !== undefined) {
      let extrasObject: Object = arr[6];
      extras = extrasObject as Map<string | undefined, string | undefined> | undefined;
    }
    let throwable: string | undefined = undefined;
    if (arr[7] !== null && arr[7] !== undefined) {
      let throwableObject: Object = arr[7];
      throwable = throwableObject as string | undefined;
    }
    return new LogEntity(timestamp, level, category, tag, message, threadName, extras, throwable);
  }
}

/* Generated class from Pigeon that represents data sent in messages.*/
export class Bucket {
  private name: string;

  public setName(name: string): void {
    this.name = name;
  }

  getName(): string {
    return this.name;
  }

  private location?: string;

  public setLocation(location: string | undefined): void {
    this.location = location;
  }

  getLocation(): string | undefined {
    return this.location;
  }

  private createDate?: string;

  public setCreateDate(createDate: string | undefined): void {
    this.createDate = createDate;
  }

  getCreateDate(): string | undefined {
    return this.createDate;
  }

  private type?: string;

  public setType(type: string | undefined): void {
    this.type = type;
  }

  getType(): string | undefined {
    return this.type;
  }

  constructor(name: string, location?: string, createDate?: string, type?: string) {
    this.name = name;
    this.location = location;
    this.createDate = createDate;
    this.type = type;
  }

  toList(): Array<Object | null> {
    let arr: Array<Object | null> = new Array<Object | null>();
    if (this.name === undefined || this.name === null) {
      arr.push(null);
    } else {
      arr.push(this.name);
    }
    if (this.location === undefined || this.location === null) {
      arr.push(null);
    } else {
      arr.push(this.location);
    }
    if (this.createDate === undefined || this.createDate === null) {
      arr.push(null);
    } else {
      arr.push(this.createDate);
    }
    if (this.type === undefined || this.type === null) {
      arr.push(null);
    } else {
      arr.push(this.type);
    }
    return arr;
  }

  static fromList(arr: Object[]): Bucket {
    let nameObject: Object = arr[0];
    const name: string = nameObject as string;
    let location: string | undefined = undefined;
    if (arr[1] !== null && arr[1] !== undefined) {
      let locationObject: Object = arr[1];
      location = locationObject as string | undefined;
    }
    let createDate: string | undefined = undefined;
    if (arr[2] !== null && arr[2] !== undefined) {
      let createDateObject: Object = arr[2];
      createDate = createDateObject as string | undefined;
    }
    let type: string | undefined = undefined;
    if (arr[3] !== null && arr[3] !== undefined) {
      let typeObject: Object = arr[3];
      type = typeObject as string | undefined;
    }
    return new Bucket(name, location, createDate, type);
  }
}

/* Generated class from Pigeon that represents data sent in messages.*/
export class ListAllMyBuckets {
  private owner: Owner;

  public setOwner(owner: Owner): void {
    this.owner = owner;
  }

  getOwner(): Owner {
    return this.owner;
  }

  private buckets: Array<Bucket | undefined>;

  public setBuckets(buckets: Array<Bucket | undefined>): void {
    this.buckets = buckets;
  }

  getBuckets(): Array<Bucket | undefined> {
    return this.buckets;
  }

  constructor(owner: Owner, buckets: Array<Bucket | undefined>) {
    this.owner = owner;
    this.buckets = buckets;
  }

  toList(): Array<Object | null> {
    let arr: Array<Object | null> = new Array<Object | null>();
    if (this.owner === undefined || this.owner === null) {
      arr.push(null);
    } else {
      arr.push(this.owner);
    }
    if (this.buckets === undefined || this.buckets === null) {
      arr.push(null);
    } else {
      arr.push(this.buckets);
    }
    return arr;
  }

  static fromList(arr: Object[]): ListAllMyBuckets {
    let ownerObject: Object = arr[0];
    const owner: Owner = ownerObject as Owner;
    let bucketsObject: Object = arr[1];
    const buckets: Array<Bucket | undefined> = bucketsObject as Array<Bucket | undefined>;
    return new ListAllMyBuckets(owner, buckets);
  }
}

/* Generated class from Pigeon that represents data sent in messages.*/
export class CommonPrefixes {
  private prefix: string;

  public setPrefix(prefix: string): void {
    this.prefix = prefix;
  }

  getPrefix(): string {
    return this.prefix;
  }

  constructor(prefix: string) {
    this.prefix = prefix;
  }

  toList(): Array<Object | null> {
    let arr: Array<Object | null> = new Array<Object | null>();
    if (this.prefix === undefined || this.prefix === null) {
      arr.push(null);
    } else {
      arr.push(this.prefix);
    }
    return arr;
  }

  static fromList(arr: Object[]): CommonPrefixes {
    let prefixObject: Object = arr[0];
    const prefix: string = prefixObject as string;
    return new CommonPrefixes(prefix);
  }
}

/* Generated class from Pigeon that represents data sent in messages.*/
export class Content {
  private key: string;

  public setKey(key: string): void {
    this.key = key;
  }

  getKey(): string {
    return this.key;
  }

  private lastModified: string;

  public setLastModified(lastModified: string): void {
    this.lastModified = lastModified;
  }

  getLastModified(): string {
    return this.lastModified;
  }

  private eTag: string;

  public setETag(eTag: string): void {
    this.eTag = eTag;
  }

  getETag(): string {
    return this.eTag;
  }

  private size: number;

  public setSize(size: number): void {
    this.size = size;
  }

  getSize(): number {
    return this.size;
  }

  private owner: Owner;

  public setOwner(owner: Owner): void {
    this.owner = owner;
  }

  getOwner(): Owner {
    return this.owner;
  }

  private storageClass: string;

  public setStorageClass(storageClass: string): void {
    this.storageClass = storageClass;
  }

  getStorageClass(): string {
    return this.storageClass;
  }

  constructor(key: string, lastModified: string, eTag: string, size: number, owner: Owner, storageClass: string) {
    this.key = key;
    this.lastModified = lastModified;
    this.eTag = eTag;
    this.size = size;
    this.owner = owner;
    this.storageClass = storageClass;
  }

  toList(): Array<Object | null> {
    let arr: Array<Object | null> = new Array<Object | null>();
    if (this.key === undefined || this.key === null) {
      arr.push(null);
    } else {
      arr.push(this.key);
    }
    if (this.lastModified === undefined || this.lastModified === null) {
      arr.push(null);
    } else {
      arr.push(this.lastModified);
    }
    if (this.eTag === undefined || this.eTag === null) {
      arr.push(null);
    } else {
      arr.push(this.eTag);
    }
    if (this.size === undefined || this.size === null) {
      arr.push(null);
    } else {
      arr.push(this.size);
    }
    if (this.owner === undefined || this.owner === null) {
      arr.push(null);
    } else {
      arr.push(this.owner);
    }
    if (this.storageClass === undefined || this.storageClass === null) {
      arr.push(null);
    } else {
      arr.push(this.storageClass);
    }
    return arr;
  }

  static fromList(arr: Object[]): Content {
    let keyObject: Object = arr[0];
    const key: string = keyObject as string;
    let lastModifiedObject: Object = arr[1];
    const lastModified: string = lastModifiedObject as string;
    let eTagObject: Object = arr[2];
    const eTag: string = eTagObject as string;
    let sizeObject: Object = arr[3];
    const size: number = sizeObject as number;
    let ownerObject: Object = arr[4];
    const owner: Owner = ownerObject as Owner;
    let storageClassObject: Object = arr[5];
    const storageClass: string = storageClassObject as string;
    return new Content(key, lastModified, eTag, size, owner, storageClass);
  }
}

/* Generated class from Pigeon that represents data sent in messages.*/
export class BucketContents {
  private name: string;

  public setName(name: string): void {
    this.name = name;
  }

  getName(): string {
    return this.name;
  }

  private encodingType?: string;

  public setEncodingType(encodingType: string | undefined): void {
    this.encodingType = encodingType;
  }

  getEncodingType(): string | undefined {
    return this.encodingType;
  }

  private prefix?: string;

  public setPrefix(prefix: string | undefined): void {
    this.prefix = prefix;
  }

  getPrefix(): string | undefined {
    return this.prefix;
  }

  private marker?: string;

  public setMarker(marker: string | undefined): void {
    this.marker = marker;
  }

  getMarker(): string | undefined {
    return this.marker;
  }

  private maxKeys: number;

  public setMaxKeys(maxKeys: number): void {
    this.maxKeys = maxKeys;
  }

  getMaxKeys(): number {
    return this.maxKeys;
  }

  private isTruncated: boolean;

  public setIsTruncated(isTruncated: boolean): void {
    this.isTruncated = isTruncated;
  }

  getIsTruncated(): boolean {
    return this.isTruncated;
  }

  private nextMarker?: string;

  public setNextMarker(nextMarker: string | undefined): void {
    this.nextMarker = nextMarker;
  }

  getNextMarker(): string | undefined {
    return this.nextMarker;
  }

  private contentsList: Array<Content | undefined>;

  public setContentsList(contentsList: Array<Content | undefined>): void {
    this.contentsList = contentsList;
  }

  getContentsList(): Array<Content | undefined> {
    return this.contentsList;
  }

  private commonPrefixesList: Array<CommonPrefixes | undefined>;

  public setCommonPrefixesList(commonPrefixesList: Array<CommonPrefixes | undefined>): void {
    this.commonPrefixesList = commonPrefixesList;
  }

  getCommonPrefixesList(): Array<CommonPrefixes | undefined> {
    return this.commonPrefixesList;
  }

  private delimiter?: string;

  public setDelimiter(delimiter: string | undefined): void {
    this.delimiter = delimiter;
  }

  getDelimiter(): string | undefined {
    return this.delimiter;
  }

  constructor(name: string, maxKeys: number, isTruncated: boolean, contentsList: Array<Content | undefined>, commonPrefixesList: Array<CommonPrefixes | undefined>, encodingType?: string, prefix?: string, marker?: string, nextMarker?: string, delimiter?: string) {
    this.name = name;
    this.encodingType = encodingType;
    this.prefix = prefix;
    this.marker = marker;
    this.maxKeys = maxKeys;
    this.isTruncated = isTruncated;
    this.nextMarker = nextMarker;
    this.contentsList = contentsList;
    this.commonPrefixesList = commonPrefixesList;
    this.delimiter = delimiter;
  }

  toList(): Array<Object | null> {
    let arr: Array<Object | null> = new Array<Object | null>();
    if (this.name === undefined || this.name === null) {
      arr.push(null);
    } else {
      arr.push(this.name);
    }
    if (this.encodingType === undefined || this.encodingType === null) {
      arr.push(null);
    } else {
      arr.push(this.encodingType);
    }
    if (this.prefix === undefined || this.prefix === null) {
      arr.push(null);
    } else {
      arr.push(this.prefix);
    }
    if (this.marker === undefined || this.marker === null) {
      arr.push(null);
    } else {
      arr.push(this.marker);
    }
    if (this.maxKeys === undefined || this.maxKeys === null) {
      arr.push(null);
    } else {
      arr.push(this.maxKeys);
    }
    if (this.isTruncated === undefined || this.isTruncated === null) {
      arr.push(null);
    } else {
      arr.push(this.isTruncated);
    }
    if (this.nextMarker === undefined || this.nextMarker === null) {
      arr.push(null);
    } else {
      arr.push(this.nextMarker);
    }
    if (this.contentsList === undefined || this.contentsList === null) {
      arr.push(null);
    } else {
      arr.push(this.contentsList);
    }
    if (this.commonPrefixesList === undefined || this.commonPrefixesList === null) {
      arr.push(null);
    } else {
      arr.push(this.commonPrefixesList);
    }
    if (this.delimiter === undefined || this.delimiter === null) {
      arr.push(null);
    } else {
      arr.push(this.delimiter);
    }
    return arr;
  }

  static fromList(arr: Object[]): BucketContents {
    let nameObject: Object = arr[0];
    const name: string = nameObject as string;
    let encodingType: string | undefined = undefined;
    if (arr[1] !== null && arr[1] !== undefined) {
      let encodingTypeObject: Object = arr[1];
      encodingType = encodingTypeObject as string | undefined;
    }
    let prefix: string | undefined = undefined;
    if (arr[2] !== null && arr[2] !== undefined) {
      let prefixObject: Object = arr[2];
      prefix = prefixObject as string | undefined;
    }
    let marker: string | undefined = undefined;
    if (arr[3] !== null && arr[3] !== undefined) {
      let markerObject: Object = arr[3];
      marker = markerObject as string | undefined;
    }
    let maxKeysObject: Object = arr[4];
    const maxKeys: number = maxKeysObject as number;
    let isTruncatedObject: Object = arr[5];
    const isTruncated: boolean = isTruncatedObject as boolean;
    let nextMarker: string | undefined = undefined;
    if (arr[6] !== null && arr[6] !== undefined) {
      let nextMarkerObject: Object = arr[6];
      nextMarker = nextMarkerObject as string | undefined;
    }
    let contentsListObject: Object = arr[7];
    const contentsList: Array<Content | undefined> = contentsListObject as Array<Content | undefined>;
    let commonPrefixesListObject: Object = arr[8];
    const commonPrefixesList: Array<CommonPrefixes | undefined> = commonPrefixesListObject as Array<CommonPrefixes | undefined>;
    let delimiter: string | undefined = undefined;
    if (arr[9] !== null && arr[9] !== undefined) {
      let delimiterObject: Object = arr[9];
      delimiter = delimiterObject as string | undefined;
    }
    return new BucketContents(name, maxKeys, isTruncated, contentsList, commonPrefixesList, encodingType, prefix, marker, nextMarker, delimiter);
  }
}

export class PigeonCodec extends StandardMessageCodec {
  static readonly INSTANCE: PigeonCodec = new PigeonCodec();

  getByte(n: number): number {
    let byteArray = new Uint8Array(1);
    byteArray[0] = n;
    return byteArray[0] as number;
  }
  private constructor() {
    super();
  }

  readValueOfType(type: number, buffer: ByteBuffer): ESObject {
    switch (type) {
      case this.getByte(129): {
        let value: Object = super.readValue(buffer);
        return value == null ? null : LogLevel[value as number];
      }
      case this.getByte(130): {
        let value: Object = super.readValue(buffer);
        return value == null ? null : LogCategory[value as number];
      }
      case this.getByte(131):
        return CosXmlServiceConfig.fromList(super.readValue(buffer) as Object[]);
      case this.getByte(132):
        return TransferConfig.fromList(super.readValue(buffer) as Object[]);
      case this.getByte(133):
        return STSCredentialScope.fromList(super.readValue(buffer) as Object[]);
      case this.getByte(134):
        return SessionQCloudCredentials.fromList(super.readValue(buffer) as Object[]);
      case this.getByte(135):
        return CosXmlResult.fromList(super.readValue(buffer) as Object[]);
      case this.getByte(136):
        return CallbackResult.fromList(super.readValue(buffer) as Object[]);
      case this.getByte(137):
        return CallbackResultError.fromList(super.readValue(buffer) as Object[]);
      case this.getByte(138):
        return CosXmlClientException.fromList(super.readValue(buffer) as Object[]);
      case this.getByte(139):
        return CosXmlServiceException.fromList(super.readValue(buffer) as Object[]);
      case this.getByte(140):
        return Owner.fromList(super.readValue(buffer) as Object[]);
      case this.getByte(141):
        return LogEntity.fromList(super.readValue(buffer) as Object[]);
      case this.getByte(142):
        return Bucket.fromList(super.readValue(buffer) as Object[]);
      case this.getByte(143):
        return ListAllMyBuckets.fromList(super.readValue(buffer) as Object[]);
      case this.getByte(144):
        return CommonPrefixes.fromList(super.readValue(buffer) as Object[]);
      case this.getByte(145):
        return Content.fromList(super.readValue(buffer) as Object[]);
      case this.getByte(146):
        return BucketContents.fromList(super.readValue(buffer) as Object[]);
      default:
        return super.readValueOfType(type, buffer);
    }
  }

  writeValue(stream: ByteBuffer, value: ESObject): ESObject {
    if (value instanceof LogLevelEnum) {
      stream.writeUint8(this.getByte(129));
      this.writeValue(stream, value == null ? null : LogLevel[value.index as string]);
    } else if (value instanceof LogCategoryEnum) {
      stream.writeUint8(this.getByte(130));
      this.writeValue(stream, value == null ? null : LogCategory[value.index as string]);
    } else if (value instanceof CosXmlServiceConfig) {
      stream.writeUint8(this.getByte(131));
      this.writeValue(stream, (value as CosXmlServiceConfig).toList());
    } else if (value instanceof TransferConfig) {
      stream.writeUint8(this.getByte(132));
      this.writeValue(stream, (value as TransferConfig).toList());
    } else if (value instanceof STSCredentialScope) {
      stream.writeUint8(this.getByte(133));
      this.writeValue(stream, (value as STSCredentialScope).toList());
    } else if (value instanceof SessionQCloudCredentials) {
      stream.writeUint8(this.getByte(134));
      this.writeValue(stream, (value as SessionQCloudCredentials).toList());
    } else if (value instanceof CosXmlResult) {
      stream.writeUint8(this.getByte(135));
      this.writeValue(stream, (value as CosXmlResult).toList());
    } else if (value instanceof CallbackResult) {
      stream.writeUint8(this.getByte(136));
      this.writeValue(stream, (value as CallbackResult).toList());
    } else if (value instanceof CallbackResultError) {
      stream.writeUint8(this.getByte(137));
      this.writeValue(stream, (value as CallbackResultError).toList());
    } else if (value instanceof CosXmlClientException) {
      stream.writeUint8(this.getByte(138));
      this.writeValue(stream, (value as CosXmlClientException).toList());
    } else if (value instanceof CosXmlServiceException) {
      stream.writeUint8(this.getByte(139));
      this.writeValue(stream, (value as CosXmlServiceException).toList());
    } else if (value instanceof Owner) {
      stream.writeUint8(this.getByte(140));
      this.writeValue(stream, (value as Owner).toList());
    } else if (value instanceof LogEntity) {
      stream.writeUint8(this.getByte(141));
      this.writeValue(stream, (value as LogEntity).toList());
    } else if (value instanceof Bucket) {
      stream.writeUint8(this.getByte(142));
      this.writeValue(stream, (value as Bucket).toList());
    } else if (value instanceof ListAllMyBuckets) {
      stream.writeUint8(this.getByte(143));
      this.writeValue(stream, (value as ListAllMyBuckets).toList());
    } else if (value instanceof CommonPrefixes) {
      stream.writeUint8(this.getByte(144));
      this.writeValue(stream, (value as CommonPrefixes).toList());
    } else if (value instanceof Content) {
      stream.writeUint8(this.getByte(145));
      this.writeValue(stream, (value as Content).toList());
    } else if (value instanceof BucketContents) {
      stream.writeUint8(this.getByte(146));
      this.writeValue(stream, (value as BucketContents).toList());
    } else {
      super.writeValue(stream, value);
    }
  }
}


export interface Result<T> {
  success(result: T): void;

  error(error: Error): void;
}
/* Generated abstract class from Pigeon that represents a handler of messages from Flutter.*/
export abstract class CosApi {

  abstract initWithPlainSecret(secretId: string, secretKey: string): void;

  abstract initWithSessionCredential(): void;

  abstract initWithScopeLimitCredential(): void;

  abstract initCustomerDNS(dnsMap: Map<string, Array<string>>): void;

  abstract initCustomerDNSFetch(): void;

  abstract forceInvalidationCredential(): void;

  abstract setCloseBeacon(isCloseBeacon: boolean): void;

  abstract registerDefaultService(config: CosXmlServiceConfig, result: Result<string>): void;

  abstract registerDefaultTransferManger(config: CosXmlServiceConfig, transferConfig: TransferConfig | undefined, result: Result<string>): void;

  abstract registerService(key: string, config: CosXmlServiceConfig, result: Result<string>): void;

  abstract registerTransferManger(key: string, config: CosXmlServiceConfig, transferConfig: TransferConfig | undefined, result: Result<string>): void;

  abstract enableLogcat(enable: boolean): void;

  abstract enableLogFile(enable: boolean): void;

  abstract addLogListener(key: number): void;

  abstract removeLogListener(key: number): void;

  abstract setMinLevel(minLevel: LogLevel): void;

  abstract setLogcatMinLevel(minLevel: LogLevel): void;

  abstract setFileMinLevel(minLevel: LogLevel): void;

  abstract setClsMinLevel(minLevel: LogLevel): void;

  abstract setDeviceID(deviceID: string): void;

  abstract setDeviceModel(deviceModel: string): void;

  abstract setAppVersion(appVersion: string): void;

  abstract setExtras(extras: Map<string, string>): void;

  abstract setLogFileEncryptionKey(key: number[], iv: number[]): void;

  abstract getLogRootDir(): string;

  abstract setCLsChannelAnonymous(topicId: string, endpoint: string): void;

  abstract setCLsChannelStaticKey(topicId: string, endpoint: string, secretId: string, secretKey: string): void;

  abstract setCLsChannelSessionCredential(topicId: string, endpoint: string): void;

  abstract addSensitiveRule(ruleName: string, regex: string): void;

  abstract removeSensitiveRule(ruleName: string): void;
  /** The codec used by CosApi. */
  static getCodec(): MessageCodec<Object> {
    return PigeonCodec.INSTANCE;
  }
  /*Sets up an instance of `CosApi` to handle messages through the `binaryMessenger`.*/
  static setup(binaryMessenger: BinaryMessenger, api: CosApi | null, messageChannelSuffix: string = ''): void {
    const separatedMessageChannelSuffix: string = messageChannelSuffix !== '' ? '.' + messageChannelSuffix : '';
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, 'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosApi.initWithPlainSecret' + separatedMessageChannelSuffix, CosApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object, reply: Reply<Object>) {
              if (!(Array.isArray(message))) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected List.')));
                  return;
              }
              let args: Array<Object> = message as Array<Object>;
              if (args.length < 2) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected at least 2 argument(s).')));
                  return;
              }
              let res: Array<Object | null> = [];
              try {
                api!.initWithPlainSecret(args[0] as string, args[1] as string);
                res.push(null);
              } catch (error) {
                let wrappedError: Array<Object | null> = wrapError(error);
                res = wrappedError;
              }
              reply.reply(res);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, 'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosApi.initWithSessionCredential' + separatedMessageChannelSuffix, CosApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object, reply: Reply<Object>) {
              let res: Array<Object | null> = [];
              try {
                api!.initWithSessionCredential();
                res.push(null);
              } catch (error) {
                let wrappedError: Array<Object | null> = wrapError(error);
                res = wrappedError;
              }
              reply.reply(res);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, 'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosApi.initWithScopeLimitCredential' + separatedMessageChannelSuffix, CosApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object, reply: Reply<Object>) {
              let res: Array<Object | null> = [];
              try {
                api!.initWithScopeLimitCredential();
                res.push(null);
              } catch (error) {
                let wrappedError: Array<Object | null> = wrapError(error);
                res = wrappedError;
              }
              reply.reply(res);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, 'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosApi.initCustomerDNS' + separatedMessageChannelSuffix, CosApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object, reply: Reply<Object>) {
              if (!(Array.isArray(message))) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected List.')));
                  return;
              }
              let args: Array<Object> = message as Array<Object>;
              if (args.length < 1) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected at least 1 argument(s).')));
                  return;
              }
              let res: Array<Object | null> = [];
              try {
                api!.initCustomerDNS(args[0] as Map<string, Array<string>>);
                res.push(null);
              } catch (error) {
                let wrappedError: Array<Object | null> = wrapError(error);
                res = wrappedError;
              }
              reply.reply(res);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, 'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosApi.initCustomerDNSFetch' + separatedMessageChannelSuffix, CosApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object, reply: Reply<Object>) {
              let res: Array<Object | null> = [];
              try {
                api!.initCustomerDNSFetch();
                res.push(null);
              } catch (error) {
                let wrappedError: Array<Object | null> = wrapError(error);
                res = wrappedError;
              }
              reply.reply(res);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, 'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosApi.forceInvalidationCredential' + separatedMessageChannelSuffix, CosApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object, reply: Reply<Object>) {
              let res: Array<Object | null> = [];
              try {
                api!.forceInvalidationCredential();
                res.push(null);
              } catch (error) {
                let wrappedError: Array<Object | null> = wrapError(error);
                res = wrappedError;
              }
              reply.reply(res);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, 'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosApi.setCloseBeacon' + separatedMessageChannelSuffix, CosApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object, reply: Reply<Object>) {
              if (!(Array.isArray(message))) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected List.')));
                  return;
              }
              let args: Array<Object> = message as Array<Object>;
              if (args.length < 1) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected at least 1 argument(s).')));
                  return;
              }
              let res: Array<Object | null> = [];
              try {
                api!.setCloseBeacon(args[0] as boolean);
                res.push(null);
              } catch (error) {
                let wrappedError: Array<Object | null> = wrapError(error);
                res = wrappedError;
              }
              reply.reply(res);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, 'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosApi.registerDefaultService' + separatedMessageChannelSuffix, CosApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object, reply: Reply<Object>) {
              if (!(Array.isArray(message))) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected List.')));
                  return;
              }
              let args: Array<Object> = message as Array<Object>;
              if (args.length < 1) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected at least 1 argument(s).')));
                  return;
              }
              class ResultImp implements Result<string>{
                    success(result: string): void {
                      let res: Array<Object | null> = [];
                      res.push(result);
                      reply.reply(res);
                    }

                    error(error: Error): void {
                      let wrappedError: Array<Object | null> = wrapError(error);
                      reply.reply(wrappedError);
                    }
              }
              let resultCallback: Result<string> = new ResultImp();

              api!.registerDefaultService(args[0] as CosXmlServiceConfig, resultCallback);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, 'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosApi.registerDefaultTransferManger' + separatedMessageChannelSuffix, CosApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object, reply: Reply<Object>) {
              if (!(Array.isArray(message))) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected List.')));
                  return;
              }
              let args: Array<Object> = message as Array<Object>;
              if (args.length < 2) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected at least 2 argument(s).')));
                  return;
              }
              class ResultImp implements Result<string>{
                    success(result: string): void {
                      let res: Array<Object | null> = [];
                      res.push(result);
                      reply.reply(res);
                    }

                    error(error: Error): void {
                      let wrappedError: Array<Object | null> = wrapError(error);
                      reply.reply(wrappedError);
                    }
              }
              let resultCallback: Result<string> = new ResultImp();

              api!.registerDefaultTransferManger(args[0] as CosXmlServiceConfig, args[1] as TransferConfig | undefined, resultCallback);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, 'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosApi.registerService' + separatedMessageChannelSuffix, CosApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object, reply: Reply<Object>) {
              if (!(Array.isArray(message))) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected List.')));
                  return;
              }
              let args: Array<Object> = message as Array<Object>;
              if (args.length < 2) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected at least 2 argument(s).')));
                  return;
              }
              class ResultImp implements Result<string>{
                    success(result: string): void {
                      let res: Array<Object | null> = [];
                      res.push(result);
                      reply.reply(res);
                    }

                    error(error: Error): void {
                      let wrappedError: Array<Object | null> = wrapError(error);
                      reply.reply(wrappedError);
                    }
              }
              let resultCallback: Result<string> = new ResultImp();

              api!.registerService(args[0] as string, args[1] as CosXmlServiceConfig, resultCallback);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, 'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosApi.registerTransferManger' + separatedMessageChannelSuffix, CosApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object, reply: Reply<Object>) {
              if (!(Array.isArray(message))) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected List.')));
                  return;
              }
              let args: Array<Object> = message as Array<Object>;
              if (args.length < 3) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected at least 3 argument(s).')));
                  return;
              }
              class ResultImp implements Result<string>{
                    success(result: string): void {
                      let res: Array<Object | null> = [];
                      res.push(result);
                      reply.reply(res);
                    }

                    error(error: Error): void {
                      let wrappedError: Array<Object | null> = wrapError(error);
                      reply.reply(wrappedError);
                    }
              }
              let resultCallback: Result<string> = new ResultImp();

              api!.registerTransferManger(args[0] as string, args[1] as CosXmlServiceConfig, args[2] as TransferConfig | undefined, resultCallback);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, 'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosApi.enableLogcat' + separatedMessageChannelSuffix, CosApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object, reply: Reply<Object>) {
              if (!(Array.isArray(message))) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected List.')));
                  return;
              }
              let args: Array<Object> = message as Array<Object>;
              if (args.length < 1) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected at least 1 argument(s).')));
                  return;
              }
              let res: Array<Object | null> = [];
              try {
                api!.enableLogcat(args[0] as boolean);
                res.push(null);
              } catch (error) {
                let wrappedError: Array<Object | null> = wrapError(error);
                res = wrappedError;
              }
              reply.reply(res);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, 'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosApi.enableLogFile' + separatedMessageChannelSuffix, CosApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object, reply: Reply<Object>) {
              if (!(Array.isArray(message))) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected List.')));
                  return;
              }
              let args: Array<Object> = message as Array<Object>;
              if (args.length < 1) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected at least 1 argument(s).')));
                  return;
              }
              let res: Array<Object | null> = [];
              try {
                api!.enableLogFile(args[0] as boolean);
                res.push(null);
              } catch (error) {
                let wrappedError: Array<Object | null> = wrapError(error);
                res = wrappedError;
              }
              reply.reply(res);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, 'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosApi.addLogListener' + separatedMessageChannelSuffix, CosApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object, reply: Reply<Object>) {
              if (!(Array.isArray(message))) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected List.')));
                  return;
              }
              let args: Array<Object> = message as Array<Object>;
              if (args.length < 1) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected at least 1 argument(s).')));
                  return;
              }
              let res: Array<Object | null> = [];
              try {
                api!.addLogListener(args[0] as number);
                res.push(null);
              } catch (error) {
                let wrappedError: Array<Object | null> = wrapError(error);
                res = wrappedError;
              }
              reply.reply(res);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, 'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosApi.removeLogListener' + separatedMessageChannelSuffix, CosApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object, reply: Reply<Object>) {
              if (!(Array.isArray(message))) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected List.')));
                  return;
              }
              let args: Array<Object> = message as Array<Object>;
              if (args.length < 1) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected at least 1 argument(s).')));
                  return;
              }
              let res: Array<Object | null> = [];
              try {
                api!.removeLogListener(args[0] as number);
                res.push(null);
              } catch (error) {
                let wrappedError: Array<Object | null> = wrapError(error);
                res = wrappedError;
              }
              reply.reply(res);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, 'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosApi.setMinLevel' + separatedMessageChannelSuffix, CosApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object, reply: Reply<Object>) {
              if (!(Array.isArray(message))) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected List.')));
                  return;
              }
              let args: Array<Object> = message as Array<Object>;
              if (args.length < 1) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected at least 1 argument(s).')));
                  return;
              }
              let res: Array<Object | null> = [];
              try {
                api!.setMinLevel(LogLevel[args[0] as string]);
                res.push(null);
              } catch (error) {
                let wrappedError: Array<Object | null> = wrapError(error);
                res = wrappedError;
              }
              reply.reply(res);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, 'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosApi.setLogcatMinLevel' + separatedMessageChannelSuffix, CosApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object, reply: Reply<Object>) {
              if (!(Array.isArray(message))) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected List.')));
                  return;
              }
              let args: Array<Object> = message as Array<Object>;
              if (args.length < 1) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected at least 1 argument(s).')));
                  return;
              }
              let res: Array<Object | null> = [];
              try {
                api!.setLogcatMinLevel(LogLevel[args[0] as string]);
                res.push(null);
              } catch (error) {
                let wrappedError: Array<Object | null> = wrapError(error);
                res = wrappedError;
              }
              reply.reply(res);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, 'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosApi.setFileMinLevel' + separatedMessageChannelSuffix, CosApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object, reply: Reply<Object>) {
              if (!(Array.isArray(message))) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected List.')));
                  return;
              }
              let args: Array<Object> = message as Array<Object>;
              if (args.length < 1) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected at least 1 argument(s).')));
                  return;
              }
              let res: Array<Object | null> = [];
              try {
                api!.setFileMinLevel(LogLevel[args[0] as string]);
                res.push(null);
              } catch (error) {
                let wrappedError: Array<Object | null> = wrapError(error);
                res = wrappedError;
              }
              reply.reply(res);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, 'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosApi.setClsMinLevel' + separatedMessageChannelSuffix, CosApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object, reply: Reply<Object>) {
              if (!(Array.isArray(message))) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected List.')));
                  return;
              }
              let args: Array<Object> = message as Array<Object>;
              if (args.length < 1) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected at least 1 argument(s).')));
                  return;
              }
              let res: Array<Object | null> = [];
              try {
                api!.setClsMinLevel(LogLevel[args[0] as string]);
                res.push(null);
              } catch (error) {
                let wrappedError: Array<Object | null> = wrapError(error);
                res = wrappedError;
              }
              reply.reply(res);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, 'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosApi.setDeviceID' + separatedMessageChannelSuffix, CosApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object, reply: Reply<Object>) {
              if (!(Array.isArray(message))) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected List.')));
                  return;
              }
              let args: Array<Object> = message as Array<Object>;
              if (args.length < 1) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected at least 1 argument(s).')));
                  return;
              }
              let res: Array<Object | null> = [];
              try {
                api!.setDeviceID(args[0] as string);
                res.push(null);
              } catch (error) {
                let wrappedError: Array<Object | null> = wrapError(error);
                res = wrappedError;
              }
              reply.reply(res);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, 'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosApi.setDeviceModel' + separatedMessageChannelSuffix, CosApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object, reply: Reply<Object>) {
              if (!(Array.isArray(message))) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected List.')));
                  return;
              }
              let args: Array<Object> = message as Array<Object>;
              if (args.length < 1) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected at least 1 argument(s).')));
                  return;
              }
              let res: Array<Object | null> = [];
              try {
                api!.setDeviceModel(args[0] as string);
                res.push(null);
              } catch (error) {
                let wrappedError: Array<Object | null> = wrapError(error);
                res = wrappedError;
              }
              reply.reply(res);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, 'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosApi.setAppVersion' + separatedMessageChannelSuffix, CosApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object, reply: Reply<Object>) {
              if (!(Array.isArray(message))) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected List.')));
                  return;
              }
              let args: Array<Object> = message as Array<Object>;
              if (args.length < 1) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected at least 1 argument(s).')));
                  return;
              }
              let res: Array<Object | null> = [];
              try {
                api!.setAppVersion(args[0] as string);
                res.push(null);
              } catch (error) {
                let wrappedError: Array<Object | null> = wrapError(error);
                res = wrappedError;
              }
              reply.reply(res);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, 'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosApi.setExtras' + separatedMessageChannelSuffix, CosApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object, reply: Reply<Object>) {
              if (!(Array.isArray(message))) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected List.')));
                  return;
              }
              let args: Array<Object> = message as Array<Object>;
              if (args.length < 1) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected at least 1 argument(s).')));
                  return;
              }
              let res: Array<Object | null> = [];
              try {
                api!.setExtras(args[0] as Map<string, string>);
                res.push(null);
              } catch (error) {
                let wrappedError: Array<Object | null> = wrapError(error);
                res = wrappedError;
              }
              reply.reply(res);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, 'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosApi.setLogFileEncryptionKey' + separatedMessageChannelSuffix, CosApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object, reply: Reply<Object>) {
              if (!(Array.isArray(message))) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected List.')));
                  return;
              }
              let args: Array<Object> = message as Array<Object>;
              if (args.length < 2) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected at least 2 argument(s).')));
                  return;
              }
              let res: Array<Object | null> = [];
              try {
                api!.setLogFileEncryptionKey(args[0] as number[], args[1] as number[]);
                res.push(null);
              } catch (error) {
                let wrappedError: Array<Object | null> = wrapError(error);
                res = wrappedError;
              }
              reply.reply(res);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, 'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosApi.getLogRootDir' + separatedMessageChannelSuffix, CosApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object, reply: Reply<Object>) {
              let res: Array<Object | null> = [];
              try {
                let output: string = api!.getLogRootDir();
                res.push(output);
              } catch (error) {
                let wrappedError: Array<Object | null> = wrapError(error);
                res = wrappedError;
              }
              reply.reply(res);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, 'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosApi.setCLsChannelAnonymous' + separatedMessageChannelSuffix, CosApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object, reply: Reply<Object>) {
              if (!(Array.isArray(message))) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected List.')));
                  return;
              }
              let args: Array<Object> = message as Array<Object>;
              if (args.length < 2) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected at least 2 argument(s).')));
                  return;
              }
              let res: Array<Object | null> = [];
              try {
                api!.setCLsChannelAnonymous(args[0] as string, args[1] as string);
                res.push(null);
              } catch (error) {
                let wrappedError: Array<Object | null> = wrapError(error);
                res = wrappedError;
              }
              reply.reply(res);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, 'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosApi.setCLsChannelStaticKey' + separatedMessageChannelSuffix, CosApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object, reply: Reply<Object>) {
              if (!(Array.isArray(message))) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected List.')));
                  return;
              }
              let args: Array<Object> = message as Array<Object>;
              if (args.length < 4) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected at least 4 argument(s).')));
                  return;
              }
              let res: Array<Object | null> = [];
              try {
                api!.setCLsChannelStaticKey(args[0] as string, args[1] as string, args[2] as string, args[3] as string);
                res.push(null);
              } catch (error) {
                let wrappedError: Array<Object | null> = wrapError(error);
                res = wrappedError;
              }
              reply.reply(res);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, 'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosApi.setCLsChannelSessionCredential' + separatedMessageChannelSuffix, CosApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object, reply: Reply<Object>) {
              if (!(Array.isArray(message))) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected List.')));
                  return;
              }
              let args: Array<Object> = message as Array<Object>;
              if (args.length < 2) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected at least 2 argument(s).')));
                  return;
              }
              let res: Array<Object | null> = [];
              try {
                api!.setCLsChannelSessionCredential(args[0] as string, args[1] as string);
                res.push(null);
              } catch (error) {
                let wrappedError: Array<Object | null> = wrapError(error);
                res = wrappedError;
              }
              reply.reply(res);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, 'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosApi.addSensitiveRule' + separatedMessageChannelSuffix, CosApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object, reply: Reply<Object>) {
              if (!(Array.isArray(message))) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected List.')));
                  return;
              }
              let args: Array<Object> = message as Array<Object>;
              if (args.length < 2) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected at least 2 argument(s).')));
                  return;
              }
              let res: Array<Object | null> = [];
              try {
                api!.addSensitiveRule(args[0] as string, args[1] as string);
                res.push(null);
              } catch (error) {
                let wrappedError: Array<Object | null> = wrapError(error);
                res = wrappedError;
              }
              reply.reply(res);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, 'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosApi.removeSensitiveRule' + separatedMessageChannelSuffix, CosApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object, reply: Reply<Object>) {
              if (!(Array.isArray(message))) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected List.')));
                  return;
              }
              let args: Array<Object> = message as Array<Object>;
              if (args.length < 1) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected at least 1 argument(s).')));
                  return;
              }
              let res: Array<Object | null> = [];
              try {
                api!.removeSensitiveRule(args[0] as string);
                res.push(null);
              } catch (error) {
                let wrappedError: Array<Object | null> = wrapError(error);
                res = wrappedError;
              }
              reply.reply(res);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
  }
}
/* Generated abstract class from Pigeon that represents a handler of messages from Flutter.*/
export abstract class CosServiceApi {

  abstract headObject(serviceKey: string, bucket: string, region: string | undefined, cosPath: string, versionId: string | undefined, sessionCredentials: SessionQCloudCredentials | undefined, result: Result<Map<string | undefined, string | undefined>>): void;

  abstract deleteObject(serviceKey: string, bucket: string, region: string | undefined, cosPath: string, versionId: string | undefined, sessionCredentials: SessionQCloudCredentials | undefined, result: Result<void>): void;

  abstract getObjectUrl(bucket: string, region: string, cosPath: string, serviceKey: string): string;

  abstract getPresignedUrl(serviceKey: string, bucket: string, cosPath: string, signValidTime: number | undefined, signHost: boolean | undefined, parameters: Map<string | undefined, string | undefined> | undefined, region: string | undefined, sessionCredentials: SessionQCloudCredentials | undefined, result: Result<string>): void;

  abstract preBuildConnection(bucket: string, serviceKey: string, result: Result<void>): void;

  abstract getService(serviceKey: string, sessionCredentials: SessionQCloudCredentials | undefined, result: Result<ListAllMyBuckets>): void;

  abstract getBucket(serviceKey: string, bucket: string, region: string | undefined, prefix: string | undefined, delimiter: string | undefined, encodingType: string | undefined, marker: string | undefined, maxKeys: number | undefined, sessionCredentials: SessionQCloudCredentials | undefined, result: Result<BucketContents>): void;

  abstract putBucket(serviceKey: string, bucket: string, region: string | undefined, enableMAZ: boolean | undefined, cosacl: string | undefined, readAccount: string | undefined, writeAccount: string | undefined, readWriteAccount: string | undefined, sessionCredentials: SessionQCloudCredentials | undefined, result: Result<void>): void;

  abstract headBucket(serviceKey: string, bucket: string, region: string | undefined, sessionCredentials: SessionQCloudCredentials | undefined, result: Result<Map<string | undefined, string | undefined>>): void;

  abstract deleteBucket(serviceKey: string, bucket: string, region: string | undefined, sessionCredentials: SessionQCloudCredentials | undefined, result: Result<void>): void;

  abstract getBucketAccelerate(serviceKey: string, bucket: string, region: string | undefined, sessionCredentials: SessionQCloudCredentials | undefined, result: Result<boolean>): void;

  abstract putBucketAccelerate(serviceKey: string, bucket: string, region: string | undefined, enable: boolean, sessionCredentials: SessionQCloudCredentials | undefined, result: Result<void>): void;

  abstract getBucketLocation(serviceKey: string, bucket: string, region: string | undefined, sessionCredentials: SessionQCloudCredentials | undefined, result: Result<string>): void;

  abstract getBucketVersioning(serviceKey: string, bucket: string, region: string | undefined, sessionCredentials: SessionQCloudCredentials | undefined, result: Result<boolean>): void;

  abstract putBucketVersioning(serviceKey: string, bucket: string, region: string | undefined, enable: boolean, sessionCredentials: SessionQCloudCredentials | undefined, result: Result<void>): void;

  abstract doesBucketExist(serviceKey: string, bucket: string, result: Result<boolean>): void;

  abstract doesObjectExist(serviceKey: string, bucket: string, cosPath: string, result: Result<boolean>): void;

  abstract cancelAll(serviceKey: string): void;
  /** The codec used by CosServiceApi. */
  static getCodec(): MessageCodec<Object> {
    return PigeonCodec.INSTANCE;
  }
  /*Sets up an instance of `CosServiceApi` to handle messages through the `binaryMessenger`.*/
  static setup(binaryMessenger: BinaryMessenger, api: CosServiceApi | null, messageChannelSuffix: string = ''): void {
    const separatedMessageChannelSuffix: string = messageChannelSuffix !== '' ? '.' + messageChannelSuffix : '';
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, 'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosServiceApi.headObject' + separatedMessageChannelSuffix, CosServiceApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object, reply: Reply<Object>) {
              if (!(Array.isArray(message))) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected List.')));
                  return;
              }
              let args: Array<Object> = message as Array<Object>;
              if (args.length < 6) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected at least 6 argument(s).')));
                  return;
              }
              class ResultImp implements Result<Map<string | undefined, string | undefined>>{
                    success(result: Map<string | undefined, string | undefined>): void {
                      let res: Array<Object | null> = [];
                      res.push(result);
                      reply.reply(res);
                    }

                    error(error: Error): void {
                      let wrappedError: Array<Object | null> = wrapError(error);
                      reply.reply(wrappedError);
                    }
              }
              let resultCallback: Result<Map<string | undefined, string | undefined>> = new ResultImp();

              api!.headObject(args[0] as string, args[1] as string, args[2] as string | undefined, args[3] as string, args[4] as string | undefined, args[5] as SessionQCloudCredentials | undefined, resultCallback);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, 'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosServiceApi.deleteObject' + separatedMessageChannelSuffix, CosServiceApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object, reply: Reply<Object>) {
              if (!(Array.isArray(message))) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected List.')));
                  return;
              }
              let args: Array<Object> = message as Array<Object>;
              if (args.length < 6) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected at least 6 argument(s).')));
                  return;
              }
              class ResultImp implements Result<void>{
                    success(result: void): void {
                      let res: Array<Object | null> = [];
                      res.push(null);
                      reply.reply(res);
                    }

                    error(error: Error): void {
                      let wrappedError: Array<Object | null> = wrapError(error);
                      reply.reply(wrappedError);
                    }
              }
              let resultCallback: Result<void> = new ResultImp();

              api!.deleteObject(args[0] as string, args[1] as string, args[2] as string | undefined, args[3] as string, args[4] as string | undefined, args[5] as SessionQCloudCredentials | undefined, resultCallback);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, 'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosServiceApi.getObjectUrl' + separatedMessageChannelSuffix, CosServiceApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object, reply: Reply<Object>) {
              if (!(Array.isArray(message))) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected List.')));
                  return;
              }
              let args: Array<Object> = message as Array<Object>;
              if (args.length < 4) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected at least 4 argument(s).')));
                  return;
              }
              let res: Array<Object | null> = [];
              try {
                let output: string = api!.getObjectUrl(args[0] as string, args[1] as string, args[2] as string, args[3] as string);
                res.push(output);
              } catch (error) {
                let wrappedError: Array<Object | null> = wrapError(error);
                res = wrappedError;
              }
              reply.reply(res);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, 'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosServiceApi.getPresignedUrl' + separatedMessageChannelSuffix, CosServiceApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object, reply: Reply<Object>) {
              if (!(Array.isArray(message))) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected List.')));
                  return;
              }
              let args: Array<Object> = message as Array<Object>;
              if (args.length < 8) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected at least 8 argument(s).')));
                  return;
              }
              class ResultImp implements Result<string>{
                    success(result: string): void {
                      let res: Array<Object | null> = [];
                      res.push(result);
                      reply.reply(res);
                    }

                    error(error: Error): void {
                      let wrappedError: Array<Object | null> = wrapError(error);
                      reply.reply(wrappedError);
                    }
              }
              let resultCallback: Result<string> = new ResultImp();

              api!.getPresignedUrl(args[0] as string, args[1] as string, args[2] as string, args[3] as number | undefined, args[4] as boolean | undefined, args[5] as Map<string | undefined, string | undefined> | undefined, args[6] as string | undefined, args[7] as SessionQCloudCredentials | undefined, resultCallback);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, 'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosServiceApi.preBuildConnection' + separatedMessageChannelSuffix, CosServiceApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object, reply: Reply<Object>) {
              if (!(Array.isArray(message))) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected List.')));
                  return;
              }
              let args: Array<Object> = message as Array<Object>;
              if (args.length < 2) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected at least 2 argument(s).')));
                  return;
              }
              class ResultImp implements Result<void>{
                    success(result: void): void {
                      let res: Array<Object | null> = [];
                      res.push(null);
                      reply.reply(res);
                    }

                    error(error: Error): void {
                      let wrappedError: Array<Object | null> = wrapError(error);
                      reply.reply(wrappedError);
                    }
              }
              let resultCallback: Result<void> = new ResultImp();

              api!.preBuildConnection(args[0] as string, args[1] as string, resultCallback);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, 'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosServiceApi.getService' + separatedMessageChannelSuffix, CosServiceApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object, reply: Reply<Object>) {
              if (!(Array.isArray(message))) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected List.')));
                  return;
              }
              let args: Array<Object> = message as Array<Object>;
              if (args.length < 2) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected at least 2 argument(s).')));
                  return;
              }
              class ResultImp implements Result<ListAllMyBuckets>{
                    success(result: ListAllMyBuckets): void {
                      let res: Array<Object | null> = [];
                      res.push(result);
                      reply.reply(res);
                    }

                    error(error: Error): void {
                      let wrappedError: Array<Object | null> = wrapError(error);
                      reply.reply(wrappedError);
                    }
              }
              let resultCallback: Result<ListAllMyBuckets> = new ResultImp();

              api!.getService(args[0] as string, args[1] as SessionQCloudCredentials | undefined, resultCallback);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, 'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosServiceApi.getBucket' + separatedMessageChannelSuffix, CosServiceApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object, reply: Reply<Object>) {
              if (!(Array.isArray(message))) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected List.')));
                  return;
              }
              let args: Array<Object> = message as Array<Object>;
              if (args.length < 9) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected at least 9 argument(s).')));
                  return;
              }
              class ResultImp implements Result<BucketContents>{
                    success(result: BucketContents): void {
                      let res: Array<Object | null> = [];
                      res.push(result);
                      reply.reply(res);
                    }

                    error(error: Error): void {
                      let wrappedError: Array<Object | null> = wrapError(error);
                      reply.reply(wrappedError);
                    }
              }
              let resultCallback: Result<BucketContents> = new ResultImp();

              api!.getBucket(args[0] as string, args[1] as string, args[2] as string | undefined, args[3] as string | undefined, args[4] as string | undefined, args[5] as string | undefined, args[6] as string | undefined, args[7] as number | undefined, args[8] as SessionQCloudCredentials | undefined, resultCallback);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, 'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosServiceApi.putBucket' + separatedMessageChannelSuffix, CosServiceApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object, reply: Reply<Object>) {
              if (!(Array.isArray(message))) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected List.')));
                  return;
              }
              let args: Array<Object> = message as Array<Object>;
              if (args.length < 9) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected at least 9 argument(s).')));
                  return;
              }
              class ResultImp implements Result<void>{
                    success(result: void): void {
                      let res: Array<Object | null> = [];
                      res.push(null);
                      reply.reply(res);
                    }

                    error(error: Error): void {
                      let wrappedError: Array<Object | null> = wrapError(error);
                      reply.reply(wrappedError);
                    }
              }
              let resultCallback: Result<void> = new ResultImp();

              api!.putBucket(args[0] as string, args[1] as string, args[2] as string | undefined, args[3] as boolean | undefined, args[4] as string | undefined, args[5] as string | undefined, args[6] as string | undefined, args[7] as string | undefined, args[8] as SessionQCloudCredentials | undefined, resultCallback);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, 'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosServiceApi.headBucket' + separatedMessageChannelSuffix, CosServiceApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object, reply: Reply<Object>) {
              if (!(Array.isArray(message))) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected List.')));
                  return;
              }
              let args: Array<Object> = message as Array<Object>;
              if (args.length < 4) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected at least 4 argument(s).')));
                  return;
              }
              class ResultImp implements Result<Map<string | undefined, string | undefined>>{
                    success(result: Map<string | undefined, string | undefined>): void {
                      let res: Array<Object | null> = [];
                      res.push(result);
                      reply.reply(res);
                    }

                    error(error: Error): void {
                      let wrappedError: Array<Object | null> = wrapError(error);
                      reply.reply(wrappedError);
                    }
              }
              let resultCallback: Result<Map<string | undefined, string | undefined>> = new ResultImp();

              api!.headBucket(args[0] as string, args[1] as string, args[2] as string | undefined, args[3] as SessionQCloudCredentials | undefined, resultCallback);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, 'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosServiceApi.deleteBucket' + separatedMessageChannelSuffix, CosServiceApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object, reply: Reply<Object>) {
              if (!(Array.isArray(message))) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected List.')));
                  return;
              }
              let args: Array<Object> = message as Array<Object>;
              if (args.length < 4) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected at least 4 argument(s).')));
                  return;
              }
              class ResultImp implements Result<void>{
                    success(result: void): void {
                      let res: Array<Object | null> = [];
                      res.push(null);
                      reply.reply(res);
                    }

                    error(error: Error): void {
                      let wrappedError: Array<Object | null> = wrapError(error);
                      reply.reply(wrappedError);
                    }
              }
              let resultCallback: Result<void> = new ResultImp();

              api!.deleteBucket(args[0] as string, args[1] as string, args[2] as string | undefined, args[3] as SessionQCloudCredentials | undefined, resultCallback);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, 'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosServiceApi.getBucketAccelerate' + separatedMessageChannelSuffix, CosServiceApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object, reply: Reply<Object>) {
              if (!(Array.isArray(message))) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected List.')));
                  return;
              }
              let args: Array<Object> = message as Array<Object>;
              if (args.length < 4) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected at least 4 argument(s).')));
                  return;
              }
              class ResultImp implements Result<boolean>{
                    success(result: boolean): void {
                      let res: Array<Object | null> = [];
                      res.push(result);
                      reply.reply(res);
                    }

                    error(error: Error): void {
                      let wrappedError: Array<Object | null> = wrapError(error);
                      reply.reply(wrappedError);
                    }
              }
              let resultCallback: Result<boolean> = new ResultImp();

              api!.getBucketAccelerate(args[0] as string, args[1] as string, args[2] as string | undefined, args[3] as SessionQCloudCredentials | undefined, resultCallback);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, 'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosServiceApi.putBucketAccelerate' + separatedMessageChannelSuffix, CosServiceApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object, reply: Reply<Object>) {
              if (!(Array.isArray(message))) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected List.')));
                  return;
              }
              let args: Array<Object> = message as Array<Object>;
              if (args.length < 5) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected at least 5 argument(s).')));
                  return;
              }
              class ResultImp implements Result<void>{
                    success(result: void): void {
                      let res: Array<Object | null> = [];
                      res.push(null);
                      reply.reply(res);
                    }

                    error(error: Error): void {
                      let wrappedError: Array<Object | null> = wrapError(error);
                      reply.reply(wrappedError);
                    }
              }
              let resultCallback: Result<void> = new ResultImp();

              api!.putBucketAccelerate(args[0] as string, args[1] as string, args[2] as string | undefined, args[3] as boolean, args[4] as SessionQCloudCredentials | undefined, resultCallback);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, 'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosServiceApi.getBucketLocation' + separatedMessageChannelSuffix, CosServiceApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object, reply: Reply<Object>) {
              if (!(Array.isArray(message))) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected List.')));
                  return;
              }
              let args: Array<Object> = message as Array<Object>;
              if (args.length < 4) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected at least 4 argument(s).')));
                  return;
              }
              class ResultImp implements Result<string>{
                    success(result: string): void {
                      let res: Array<Object | null> = [];
                      res.push(result);
                      reply.reply(res);
                    }

                    error(error: Error): void {
                      let wrappedError: Array<Object | null> = wrapError(error);
                      reply.reply(wrappedError);
                    }
              }
              let resultCallback: Result<string> = new ResultImp();

              api!.getBucketLocation(args[0] as string, args[1] as string, args[2] as string | undefined, args[3] as SessionQCloudCredentials | undefined, resultCallback);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, 'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosServiceApi.getBucketVersioning' + separatedMessageChannelSuffix, CosServiceApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object, reply: Reply<Object>) {
              if (!(Array.isArray(message))) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected List.')));
                  return;
              }
              let args: Array<Object> = message as Array<Object>;
              if (args.length < 4) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected at least 4 argument(s).')));
                  return;
              }
              class ResultImp implements Result<boolean>{
                    success(result: boolean): void {
                      let res: Array<Object | null> = [];
                      res.push(result);
                      reply.reply(res);
                    }

                    error(error: Error): void {
                      let wrappedError: Array<Object | null> = wrapError(error);
                      reply.reply(wrappedError);
                    }
              }
              let resultCallback: Result<boolean> = new ResultImp();

              api!.getBucketVersioning(args[0] as string, args[1] as string, args[2] as string | undefined, args[3] as SessionQCloudCredentials | undefined, resultCallback);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, 'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosServiceApi.putBucketVersioning' + separatedMessageChannelSuffix, CosServiceApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object, reply: Reply<Object>) {
              if (!(Array.isArray(message))) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected List.')));
                  return;
              }
              let args: Array<Object> = message as Array<Object>;
              if (args.length < 5) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected at least 5 argument(s).')));
                  return;
              }
              class ResultImp implements Result<void>{
                    success(result: void): void {
                      let res: Array<Object | null> = [];
                      res.push(null);
                      reply.reply(res);
                    }

                    error(error: Error): void {
                      let wrappedError: Array<Object | null> = wrapError(error);
                      reply.reply(wrappedError);
                    }
              }
              let resultCallback: Result<void> = new ResultImp();

              api!.putBucketVersioning(args[0] as string, args[1] as string, args[2] as string | undefined, args[3] as boolean, args[4] as SessionQCloudCredentials | undefined, resultCallback);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, 'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosServiceApi.doesBucketExist' + separatedMessageChannelSuffix, CosServiceApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object, reply: Reply<Object>) {
              if (!(Array.isArray(message))) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected List.')));
                  return;
              }
              let args: Array<Object> = message as Array<Object>;
              if (args.length < 2) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected at least 2 argument(s).')));
                  return;
              }
              class ResultImp implements Result<boolean>{
                    success(result: boolean): void {
                      let res: Array<Object | null> = [];
                      res.push(result);
                      reply.reply(res);
                    }

                    error(error: Error): void {
                      let wrappedError: Array<Object | null> = wrapError(error);
                      reply.reply(wrappedError);
                    }
              }
              let resultCallback: Result<boolean> = new ResultImp();

              api!.doesBucketExist(args[0] as string, args[1] as string, resultCallback);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, 'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosServiceApi.doesObjectExist' + separatedMessageChannelSuffix, CosServiceApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object, reply: Reply<Object>) {
              if (!(Array.isArray(message))) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected List.')));
                  return;
              }
              let args: Array<Object> = message as Array<Object>;
              if (args.length < 3) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected at least 3 argument(s).')));
                  return;
              }
              class ResultImp implements Result<boolean>{
                    success(result: boolean): void {
                      let res: Array<Object | null> = [];
                      res.push(result);
                      reply.reply(res);
                    }

                    error(error: Error): void {
                      let wrappedError: Array<Object | null> = wrapError(error);
                      reply.reply(wrappedError);
                    }
              }
              let resultCallback: Result<boolean> = new ResultImp();

              api!.doesObjectExist(args[0] as string, args[1] as string, args[2] as string, resultCallback);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, 'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosServiceApi.cancelAll' + separatedMessageChannelSuffix, CosServiceApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object, reply: Reply<Object>) {
              if (!(Array.isArray(message))) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected List.')));
                  return;
              }
              let args: Array<Object> = message as Array<Object>;
              if (args.length < 1) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected at least 1 argument(s).')));
                  return;
              }
              let res: Array<Object | null> = [];
              try {
                api!.cancelAll(args[0] as string);
                res.push(null);
              } catch (error) {
                let wrappedError: Array<Object | null> = wrapError(error);
                res = wrappedError;
              }
              reply.reply(res);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
  }
}
/* Generated abstract class from Pigeon that represents a handler of messages from Flutter.*/
export abstract class CosTransferApi {

  abstract upload(transferKey: string, bucket: string, cosPath: string, region: string | undefined, filePath: string | undefined, byteArr: number[] | undefined, uploadId: string | undefined, stroageClass: string | undefined, trafficLimit: number | undefined, callbackParam: string | undefined, customHeaders: Map<string, string> | undefined, noSignHeaders: Array<string | undefined> | undefined, resultCallbackKey: number | undefined, stateCallbackKey: number | undefined, progressCallbackKey: number | undefined, initMultipleUploadCallbackKey: number | undefined, sessionCredentials: SessionQCloudCredentials | undefined): string;

  abstract download(transferKey: string, bucket: string, cosPath: string, region: string | undefined, savePath: string, versionId: string | undefined, trafficLimit: number | undefined, customHeaders: Map<string, string> | undefined, noSignHeaders: Array<string | undefined> | undefined, resultCallbackKey: number | undefined, stateCallbackKey: number | undefined, progressCallbackKey: number | undefined, sessionCredentials: SessionQCloudCredentials | undefined): string;

  abstract pause(taskId: string, transferKey: string): void;

  abstract resume(taskId: string, transferKey: string): void;

  abstract cancel(taskId: string, transferKey: string): void;
  /** The codec used by CosTransferApi. */
  static getCodec(): MessageCodec<Object> {
    return PigeonCodec.INSTANCE;
  }
  /*Sets up an instance of `CosTransferApi` to handle messages through the `binaryMessenger`.*/
  static setup(binaryMessenger: BinaryMessenger, api: CosTransferApi | null, messageChannelSuffix: string = ''): void {
    const separatedMessageChannelSuffix: string = messageChannelSuffix !== '' ? '.' + messageChannelSuffix : '';
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, 'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosTransferApi.upload' + separatedMessageChannelSuffix, CosTransferApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object, reply: Reply<Object>) {
              if (!(Array.isArray(message))) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected List.')));
                  return;
              }
              let args: Array<Object> = message as Array<Object>;
              if (args.length < 17) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected at least 17 argument(s).')));
                  return;
              }
              let res: Array<Object | null> = [];
              try {
                let output: string = api!.upload(args[0] as string, args[1] as string, args[2] as string, args[3] as string | undefined, args[4] as string | undefined, args[5] as number[] | undefined, args[6] as string | undefined, args[7] as string | undefined, args[8] as number | undefined, args[9] as string | undefined, args[10] as Map<string, string> | undefined, args[11] as Array<string | undefined> | undefined, args[12] as number | undefined, args[13] as number | undefined, args[14] as number | undefined, args[15] as number | undefined, args[16] as SessionQCloudCredentials | undefined);
                res.push(output);
              } catch (error) {
                let wrappedError: Array<Object | null> = wrapError(error);
                res = wrappedError;
              }
              reply.reply(res);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, 'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosTransferApi.download' + separatedMessageChannelSuffix, CosTransferApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object, reply: Reply<Object>) {
              if (!(Array.isArray(message))) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected List.')));
                  return;
              }
              let args: Array<Object> = message as Array<Object>;
              if (args.length < 13) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected at least 13 argument(s).')));
                  return;
              }
              let res: Array<Object | null> = [];
              try {
                let output: string = api!.download(args[0] as string, args[1] as string, args[2] as string, args[3] as string | undefined, args[4] as string, args[5] as string | undefined, args[6] as number | undefined, args[7] as Map<string, string> | undefined, args[8] as Array<string | undefined> | undefined, args[9] as number | undefined, args[10] as number | undefined, args[11] as number | undefined, args[12] as SessionQCloudCredentials | undefined);
                res.push(output);
              } catch (error) {
                let wrappedError: Array<Object | null> = wrapError(error);
                res = wrappedError;
              }
              reply.reply(res);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, 'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosTransferApi.pause' + separatedMessageChannelSuffix, CosTransferApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object, reply: Reply<Object>) {
              if (!(Array.isArray(message))) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected List.')));
                  return;
              }
              let args: Array<Object> = message as Array<Object>;
              if (args.length < 2) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected at least 2 argument(s).')));
                  return;
              }
              let res: Array<Object | null> = [];
              try {
                api!.pause(args[0] as string, args[1] as string);
                res.push(null);
              } catch (error) {
                let wrappedError: Array<Object | null> = wrapError(error);
                res = wrappedError;
              }
              reply.reply(res);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, 'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosTransferApi.resume' + separatedMessageChannelSuffix, CosTransferApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object, reply: Reply<Object>) {
              if (!(Array.isArray(message))) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected List.')));
                  return;
              }
              let args: Array<Object> = message as Array<Object>;
              if (args.length < 2) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected at least 2 argument(s).')));
                  return;
              }
              let res: Array<Object | null> = [];
              try {
                api!.resume(args[0] as string, args[1] as string);
                res.push(null);
              } catch (error) {
                let wrappedError: Array<Object | null> = wrapError(error);
                res = wrappedError;
              }
              reply.reply(res);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, 'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.CosTransferApi.cancel' + separatedMessageChannelSuffix, CosTransferApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object, reply: Reply<Object>) {
              if (!(Array.isArray(message))) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected List.')));
                  return;
              }
              let args: Array<Object> = message as Array<Object>;
              if (args.length < 2) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected at least 2 argument(s).')));
                  return;
              }
              let res: Array<Object | null> = [];
              try {
                api!.cancel(args[0] as string, args[1] as string);
                res.push(null);
              } catch (error) {
                let wrappedError: Array<Object | null> = wrapError(error);
                res = wrappedError;
              }
              reply.reply(res);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
  }
}
/* Generated class from Pigeon that represents Flutter messages that can be called from ArkTS.*/
export class FlutterCosApi {
  binaryMessenger: BinaryMessenger;
  private messageChannelSuffix: string;

  constructor(binaryMessenger: BinaryMessenger, messageChannelSuffix: string = '') {
    this.binaryMessenger = binaryMessenger;
    this.messageChannelSuffix = messageChannelSuffix !== '' ? '.' + messageChannelSuffix : '';
  }

  /** The codec used by FlutterCosApi. */
  static getCodec(): MessageCodec<Object> {
    return PigeonCodec.INSTANCE;
  }

  fetchSessionCredentials(callback: Reply<SessionQCloudCredentials>):void {
    const channelName: string = 'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.FlutterCosApi.fetchSessionCredentials' + this.messageChannelSuffix;
    let channel: BasicMessageChannel<Object> = 
        new BasicMessageChannel<Object>(
            this.binaryMessenger, channelName, FlutterCosApi.getCodec());
    channel.send(
        null,
        channelReply => {
          if (Array.isArray(channelReply)) {
            let listReply: ESObject[] = channelReply as ESObject[];
            if (listReply.length > 1) {
              let arrFirst:string = listReply[0] as string;
              let arrSecond:string = listReply[1] as string;
              let arrThird:string = listReply[2] as string;
              let replyArr: ESObject = new FlutterError(arrFirst, arrSecond, arrThird);
              callback.reply(replyArr);
            } else if (listReply[0] == null) {
              let replyNull: ESObject = new FlutterError('null-error', 'Flutter api returned null value for non-null return value.', '');
              callback.reply(replyNull);
            } else {
              let output:SessionQCloudCredentials = listReply[0] as SessionQCloudCredentials;
              callback.reply(output);
            }
          } else {
            let connErr: ESObject = new FlutterError('channel-error', 'Unable to establish connection on channel: ' + channelName + '.', '');
            callback.reply(connErr);
          } 
        });
  }
  fetchScopeLimitCredentials(stsCredentialScopesArg: Array<STSCredentialScope | undefined>, callback: Reply<SessionQCloudCredentials>) {
    const channelName: string = 'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.FlutterCosApi.fetchScopeLimitCredentials' + this.messageChannelSuffix;
    let channel: BasicMessageChannel<Object> = 
        new BasicMessageChannel<Object>(
            this.binaryMessenger, channelName, FlutterCosApi.getCodec());
    channel.send(
        [stsCredentialScopesArg],
        channelReply => {
          if (Array.isArray(channelReply)) {
            let listReply: ESObject[] = channelReply as ESObject[];
            if (listReply.length > 1) {
              let arrFirst:string = listReply[0] as string;
              let arrSecond:string = listReply[1] as string;
              let arrThird:string = listReply[2] as string;
              let replyArr: ESObject = new FlutterError(arrFirst, arrSecond, arrThird);
              callback.reply(replyArr);
            } else if (listReply[0] == null) {
              let replyNull: ESObject = new FlutterError('null-error', 'Flutter api returned null value for non-null return value.', '');
              callback.reply(replyNull);
            } else {
              let output:SessionQCloudCredentials = listReply[0] as SessionQCloudCredentials;
              callback.reply(output);
            }
          } else {
            let connErr: ESObject = new FlutterError('channel-error', 'Unable to establish connection on channel: ' + channelName + '.', '');
            callback.reply(connErr);
          } 
        });
  }
  /*
  *  获取dns记录
  *  @param domain 域名
  *  @return ip集合
  */
  fetchDns(domainArg: string, callback: Reply<Array<string> | undefined>) {
    const channelName: string = 'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.FlutterCosApi.fetchDns' + this.messageChannelSuffix;
    let channel: BasicMessageChannel<Object> = 
        new BasicMessageChannel<Object>(
            this.binaryMessenger, channelName, FlutterCosApi.getCodec());
    channel.send(
        [domainArg],
        channelReply => {
          if (Array.isArray(channelReply)) {
            let listReply: ESObject[] = channelReply as ESObject[];
            if (listReply.length > 1) {
              let arrFirst:string = listReply[0] as string;
              let arrSecond:string = listReply[1] as string;
              let arrThird:string = listReply[2] as string;
              let replyArr: ESObject = new FlutterError(arrFirst, arrSecond, arrThird);
              callback.reply(replyArr);
            } else {
              let output:Array<string> | undefined = listReply[0] as Array<string> | undefined;
              callback.reply(output);
            }
          } else {
            let connErr: ESObject = new FlutterError('channel-error', 'Unable to establish connection on channel: ' + channelName + '.', '');
            callback.reply(connErr);
          } 
        });
  }
  resultSuccessCallback(transferKeyArg: string,keyArg: number,headerArg: Map<string | undefined, string | undefined> | undefined,resultArg: CosXmlResult | undefined, callback: Reply<void>) {
    const channelName: string = 'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.FlutterCosApi.resultSuccessCallback' + this.messageChannelSuffix;
    let channel: BasicMessageChannel<Object> = 
        new BasicMessageChannel<Object>(
            this.binaryMessenger, channelName, FlutterCosApi.getCodec());
    channel.send(
        [transferKeyArg, keyArg, headerArg, resultArg],
        channelReply => {
          if (Array.isArray(channelReply)) {
            let listReply: ESObject[] = channelReply as ESObject[];
            if (listReply.length > 1) {
              let arrFirst:string = listReply[0] as string;
              let arrSecond:string = listReply[1] as string;
              let arrThird:string = listReply[2] as string;
              let replyArr: ESObject = new FlutterError(arrFirst, arrSecond, arrThird);
              callback.reply(replyArr);
            } else {
              callback.reply();
            }
          } else {
            let connErr: ESObject = new FlutterError('channel-error', 'Unable to establish connection on channel: ' + channelName + '.', '');
            callback.reply(connErr);
          } 
        });
  }
  resultFailCallback(transferKeyArg: string,keyArg: number,clientExceptionArg: CosXmlClientException | undefined,serviceExceptionArg: CosXmlServiceException | undefined, callback: Reply<void>) {
    const channelName: string = 'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.FlutterCosApi.resultFailCallback' + this.messageChannelSuffix;
    let channel: BasicMessageChannel<Object> = 
        new BasicMessageChannel<Object>(
            this.binaryMessenger, channelName, FlutterCosApi.getCodec());
    channel.send(
        [transferKeyArg, keyArg, clientExceptionArg, serviceExceptionArg],
        channelReply => {
          if (Array.isArray(channelReply)) {
            let listReply: ESObject[] = channelReply as ESObject[];
            if (listReply.length > 1) {
              let arrFirst:string = listReply[0] as string;
              let arrSecond:string = listReply[1] as string;
              let arrThird:string = listReply[2] as string;
              let replyArr: ESObject = new FlutterError(arrFirst, arrSecond, arrThird);
              callback.reply(replyArr);
            } else {
              callback.reply();
            }
          } else {
            let connErr: ESObject = new FlutterError('channel-error', 'Unable to establish connection on channel: ' + channelName + '.', '');
            callback.reply(connErr);
          } 
        });
  }
  stateCallback(transferKeyArg: string,keyArg: number,stateArg: string, callback: Reply<void>) {
    const channelName: string = 'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.FlutterCosApi.stateCallback' + this.messageChannelSuffix;
    let channel: BasicMessageChannel<Object> = 
        new BasicMessageChannel<Object>(
            this.binaryMessenger, channelName, FlutterCosApi.getCodec());
    channel.send(
        [transferKeyArg, keyArg, stateArg],
        channelReply => {
          if (Array.isArray(channelReply)) {
            let listReply: ESObject[] = channelReply as ESObject[];
            if (listReply.length > 1) {
              let arrFirst:string = listReply[0] as string;
              let arrSecond:string = listReply[1] as string;
              let arrThird:string = listReply[2] as string;
              let replyArr: ESObject = new FlutterError(arrFirst, arrSecond, arrThird);
              callback.reply(replyArr);
            } else {
              callback.reply();
            }
          } else {
            let connErr: ESObject = new FlutterError('channel-error', 'Unable to establish connection on channel: ' + channelName + '.', '');
            callback.reply(connErr);
          } 
        });
  }
  progressCallback(transferKeyArg: string,keyArg: number,completeArg: number,targetArg: number, callback: Reply<void>) {
    const channelName: string = 'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.FlutterCosApi.progressCallback' + this.messageChannelSuffix;
    let channel: BasicMessageChannel<Object> = 
        new BasicMessageChannel<Object>(
            this.binaryMessenger, channelName, FlutterCosApi.getCodec());
    channel.send(
        [transferKeyArg, keyArg, completeArg, targetArg],
        channelReply => {
          if (Array.isArray(channelReply)) {
            let listReply: ESObject[] = channelReply as ESObject[];
            if (listReply.length > 1) {
              let arrFirst:string = listReply[0] as string;
              let arrSecond:string = listReply[1] as string;
              let arrThird:string = listReply[2] as string;
              let replyArr: ESObject = new FlutterError(arrFirst, arrSecond, arrThird);
              callback.reply(replyArr);
            } else {
              callback.reply();
            }
          } else {
            let connErr: ESObject = new FlutterError('channel-error', 'Unable to establish connection on channel: ' + channelName + '.', '');
            callback.reply(connErr);
          } 
        });
  }
  initMultipleUploadCallback(transferKeyArg: string,keyArg: number,bucketArg: string,cosKeyArg: string,uploadIdArg: string, callback: Reply<void>) {
    const channelName: string = 'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.FlutterCosApi.initMultipleUploadCallback' + this.messageChannelSuffix;
    let channel: BasicMessageChannel<Object> = 
        new BasicMessageChannel<Object>(
            this.binaryMessenger, channelName, FlutterCosApi.getCodec());
    channel.send(
        [transferKeyArg, keyArg, bucketArg, cosKeyArg, uploadIdArg],
        channelReply => {
          if (Array.isArray(channelReply)) {
            let listReply: ESObject[] = channelReply as ESObject[];
            if (listReply.length > 1) {
              let arrFirst:string = listReply[0] as string;
              let arrSecond:string = listReply[1] as string;
              let arrThird:string = listReply[2] as string;
              let replyArr: ESObject = new FlutterError(arrFirst, arrSecond, arrThird);
              callback.reply(replyArr);
            } else {
              callback.reply();
            }
          } else {
            let connErr: ESObject = new FlutterError('channel-error', 'Unable to establish connection on channel: ' + channelName + '.', '');
            callback.reply(connErr);
          } 
        });
  }
  onLog(keyArg: number,entityArg: LogEntity, callback: Reply<void>) {
    const channelName: string = 'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.FlutterCosApi.onLog' + this.messageChannelSuffix;
    let channel: BasicMessageChannel<Object> = 
        new BasicMessageChannel<Object>(
            this.binaryMessenger, channelName, FlutterCosApi.getCodec());
    channel.send(
        [keyArg, entityArg],
        channelReply => {
          if (Array.isArray(channelReply)) {
            let listReply: ESObject[] = channelReply as ESObject[];
            if (listReply.length > 1) {
              let arrFirst:string = listReply[0] as string;
              let arrSecond:string = listReply[1] as string;
              let arrThird:string = listReply[2] as string;
              let replyArr: ESObject = new FlutterError(arrFirst, arrSecond, arrThird);
              callback.reply(replyArr);
            } else {
              callback.reply();
            }
          } else {
            let connErr: ESObject = new FlutterError('channel-error', 'Unable to establish connection on channel: ' + channelName + '.', '');
            callback.reply(connErr);
          } 
        });
  }
  fetchClsSessionCredentials(callback: Reply<SessionQCloudCredentials>):void {
    const channelName: string = 'dev.flutter.pigeon.tencentcloud_cos_sdk_plugin.FlutterCosApi.fetchClsSessionCredentials' + this.messageChannelSuffix;
    let channel: BasicMessageChannel<Object> = 
        new BasicMessageChannel<Object>(
            this.binaryMessenger, channelName, FlutterCosApi.getCodec());
    channel.send(
        null,
        channelReply => {
          if (Array.isArray(channelReply)) {
            let listReply: ESObject[] = channelReply as ESObject[];
            if (listReply.length > 1) {
              let arrFirst:string = listReply[0] as string;
              let arrSecond:string = listReply[1] as string;
              let arrThird:string = listReply[2] as string;
              let replyArr: ESObject = new FlutterError(arrFirst, arrSecond, arrThird);
              callback.reply(replyArr);
            } else if (listReply[0] == null) {
              let replyNull: ESObject = new FlutterError('null-error', 'Flutter api returned null value for non-null return value.', '');
              callback.reply(replyNull);
            } else {
              let output:SessionQCloudCredentials = listReply[0] as SessionQCloudCredentials;
              callback.reply(output);
            }
          } else {
            let connErr: ESObject = new FlutterError('channel-error', 'Unable to establish connection on channel: ' + channelName + '.', '');
            callback.reply(connErr);
          } 
        });
  }
}
