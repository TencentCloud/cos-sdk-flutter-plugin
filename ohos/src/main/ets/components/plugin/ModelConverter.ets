/*
 * Copyright (c) 2026 Tencent Cloud. All rights reserved.
 * Licensed under the Apache License, Version 2.0 (the "License").
 */

/**
 * 结果模型映射层：鸿蒙 `@tencentcloud/cos` 的 Result → pigeon 数据类。
 *
 * 这是「错一个字段名就静默丢数据」的高危逻辑，独立成文件便于 review。
 *
 * ## 两端字段名差异（逐条核实过，勿"顺手改回去"）
 *
 * | 鸿蒙                    | Flutter pigeon         | 说明 |
 * | ----------------------- | ---------------------- | ---- |
 * | `Bucket.creationDate`   | `Bucket.createDate`    | 鸿蒙多一个 ion |
 * | `Bucket.bucketType`     | `Bucket.type`          | |
 * | `Owner.displayName`     | `Owner.disPlayName`    | **P 大写**，Flutter/Android 侧的既有拼写，不是笔误 |
 * | `ListBuckets.buckets`   | `ListAllMyBuckets.buckets` | |
 * | `ListObjects.contents`  | `BucketContents.contentsList` | |
 * | `ListObjects.commonPrefixes` | `BucketContents.commonPrefixesList` | |
 *
 * ## 类型差异
 *
 * 鸿蒙用 `@ohos.util.List`（`List<Bucket>` / `List<Content>`），
 * pigeon 用 `Array<T | undefined>`。`List` 支持 `for...of`，遍历后 push 进 Array。
 *
 * ## 空安全差异（重要）
 *
 * 鸿蒙侧模型**所有字段都是可选**（`name?: string` 等，`initWithJson` 从 XML 解析，
 * 缺节点即 undefined）；而 pigeon/Dart 侧有一批**非空**字段
 * （`Bucket.name` / `Content.key` / `BucketContents.name` / `Owner.id` ...）。
 *
 * Dart 侧 `decode` 用的是 `result[0]! as String`，**传 null 会直接抛异常**，
 * 因此这里对所有 Dart 非空字段都做「undefined → 默认值」的兜底（字符串兜 `''`，
 * 数字兜 `0`，bool 兜 `false`），保证 codec 一定能解出来，而不是让 Flutter 侧崩在
 * pigeon 解码里（那种崩溃现场完全看不出是哪个字段缺了）。
 */

import {
  ListBucketsResult,
  ListBuckets,
  Bucket as HarmonyBucket,
  ListObjectsResult,
  ListObjects,
  Content as HarmonyContent,
  CommonPrefixes as HarmonyCommonPrefixes,
  Owner as HarmonyOwner,
} from '@tencentcloud/cos';
import {
  ListAllMyBuckets,
  Bucket as PigeonBucket,
  BucketContents,
  Content as PigeonContent,
  CommonPrefixes as PigeonCommonPrefixes,
  Owner as PigeonOwner,
} from './Pigeon';
import { PluginLog } from './PluginLog';

/**
 * Dart 侧 `Content.storageClass` 是**非空** String（`result[5]! as String`），
 * 而鸿蒙 `Content` 根本没有该字段（详见 toContent 的注释），只能填这个占位值。
 *
 * 用空串而不是 'STANDARD'：后者是**猜测出来的错误数据**（对象可能实际是
 * STANDARD_IA / ARCHIVE），会误导按存储类型分支的业务逻辑；
 * 空串至少能被判定为「本平台拿不到」。
 */
const STORAGE_CLASS_UNAVAILABLE: string = '';

export class ModelConverter {
  // ------------------------------------------------------------------
  // getService: ListBucketsResult → ListAllMyBuckets
  // ------------------------------------------------------------------

  /**
   * `listBucket()` 的结果 → pigeon `ListAllMyBuckets`。
   *
   * 对齐 Android `CosPlugin.getService()`：只映射 owner + buckets 两个字段。
   *
   * ⚠️ 鸿蒙 `ListBuckets` 还有 `marker` / `isTruncated` / `nextMarker` 三个字段，
   * 但 pigeon `ListAllMyBuckets` 只有 owner/buckets 两个字段，**无处安放**，
   * Android 侧同样如此。也就是说鸿蒙侧的分页信息会被丢弃 —— 这是 pigeon
   * 接口定义本身的限制，非本层的实现缺陷。
   */
  static toListAllMyBuckets(result: ListBucketsResult): ListAllMyBuckets {
    const buckets: ListBuckets | undefined = result.buckets;
    const bucketList: Array<PigeonBucket | undefined> = new Array<PigeonBucket | undefined>();
    if (buckets !== undefined && buckets !== null &&
      buckets.buckets !== undefined && buckets.buckets !== null) {
      // 鸿蒙是 @ohos.util.List，支持 for...of
      for (const bucket of buckets.buckets) {
        bucketList.push(ModelConverter.toBucket(bucket));
      }
    }
    // owner 在 pigeon 侧是**非空**字段，鸿蒙可能没解析出来 → 兜一个空 Owner
    const owner: PigeonOwner = ModelConverter.toOwner(
      buckets !== undefined && buckets !== null ? buckets.owner : undefined,
    );
    return new ListAllMyBuckets(owner, bucketList);
  }

  /**
   * 鸿蒙 `Bucket` → pigeon `Bucket`。
   *
   * ⚠️ 字段名差异全在这里：`creationDate`→`createDate`、`bucketType`→`type`。
   */
  private static toBucket(bucket: HarmonyBucket): PigeonBucket {
    // name 在 pigeon 侧非空
    const name: string = bucket.name !== undefined && bucket.name !== null ? bucket.name! : '';
    return new PigeonBucket(
      name,
      bucket.location,
      // 鸿蒙 creationDate ←→ Flutter createDate
      bucket.creationDate,
      // 鸿蒙 bucketType ←→ Flutter type
      bucket.bucketType,
    );
  }

  // ------------------------------------------------------------------
  // getBucket: ListObjectsResult → BucketContents
  // ------------------------------------------------------------------

  /**
   * `listObject()` 的结果 → pigeon `BucketContents`。
   *
   * 对齐 Android `CosPlugin.getBucket()` 的字段集合。
   */
  static toBucketContents(result: ListObjectsResult): BucketContents {
    const objects: ListObjects | undefined = result.objects;

    const contents: Array<PigeonContent | undefined> = new Array<PigeonContent | undefined>();
    const commonPrefixes: Array<PigeonCommonPrefixes | undefined> =
      new Array<PigeonCommonPrefixes | undefined>();

    if (objects === undefined || objects === null) {
      // 响应体解析不出来（如空 body）：返回一个字段齐全的空结果而不是抛错，
      // 与鸿蒙 SDK「解析失败即 objects=undefined」的宽松语义保持一致。
      return new BucketContents('', 0, false, contents, commonPrefixes,
        undefined, undefined, undefined, undefined, undefined);
    }

    if (objects.contents !== undefined && objects.contents !== null) {
      for (const content of objects.contents) {
        contents.push(ModelConverter.toContent(content));
      }
    }
    if (objects.commonPrefixes !== undefined && objects.commonPrefixes !== null) {
      for (const prefix of objects.commonPrefixes) {
        commonPrefixes.push(ModelConverter.toCommonPrefixes(prefix));
      }
    }

    // 以下三个在 pigeon 侧是非空字段，鸿蒙均为可选 → 兜底
    const name: string = objects.name !== undefined && objects.name !== null ? objects.name! : '';
    const maxKeys: number =
      objects.maxKeys !== undefined && objects.maxKeys !== null ? objects.maxKeys! : 0;
    const isTruncated: boolean =
      objects.isTruncated !== undefined && objects.isTruncated !== null ? objects.isTruncated! : false;

    return new BucketContents(
      name,
      maxKeys,
      isTruncated,
      contents,
      commonPrefixes,
      objects.encodingType,
      objects.prefix,
      objects.marker,
      objects.nextMarker,
      objects.delimiter,
    );
  }

  /**
   * 鸿蒙 `Content` → pigeon `Content`。
   *
   * `storageClass`：鸿蒙 SDK 1.2.5 起已补上该字段并在 `initWithJson` 中解析
   * `<StorageClass>` 节点（1.2.4 及之前缺失）。Dart 侧该字段是**非空** String
   * （`result[5]! as String`），传 null 会让 pigeon 解码直接抛异常，故仍保留空串兜底
   * ——服务端在极少数场景下可能不返回该节点。
   *
   * 注意**不要用 storageTier 顶替**：storageTier 是智能分层下的「当前所处层级」
   * （FREQUENT/INFREQUENT/ARCHIVE_ACCESS/...），与 storageClass（STANDARD/
   * STANDARD_IA/ARCHIVE/...）是两套不同的枚举，且仅在 StorageClass=
   * INTELLIGENT_TIERING 时才返回。混填会给出**语义错误**的值。
   */
  private static toContent(content: HarmonyContent): PigeonContent {
    // 以下四个在 pigeon 侧均为非空字段
    const key: string = content.key !== undefined && content.key !== null ? content.key! : '';
    const lastModified: string =
      content.lastModified !== undefined && content.lastModified !== null ? content.lastModified! : '';
    const eTag: string = content.eTag !== undefined && content.eTag !== null ? content.eTag! : '';
    // 鸿蒙 size 来自 XML 文本，initWithJson 直接赋值未做 parseInt，可能是字符串
    const size: number = ModelConverter.toNumber(content.size);
    // SDK 1.2.5 起提供 storageClass；服务端未返回该节点时兜底为空串（Dart 侧非空）
    const storageClass: string =
      content.storageClass !== undefined && content.storageClass !== null
        ? content.storageClass!
        : STORAGE_CLASS_UNAVAILABLE;
    return new PigeonContent(
      key,
      lastModified,
      eTag,
      size,
      ModelConverter.toOwner(content.owner),
      storageClass,
    );
  }

  private static toCommonPrefixes(prefix: HarmonyCommonPrefixes): PigeonCommonPrefixes {
    // pigeon 侧 prefix 非空
    return new PigeonCommonPrefixes(
      prefix.prefix !== undefined && prefix.prefix !== null ? prefix.prefix! : '',
    );
  }

  /**
   * 鸿蒙 `Owner` → pigeon `Owner`。
   *
   * ⚠️ 字段名差异：鸿蒙 `displayName` → Flutter `disPlayName`（**P 大写**）。
   * 这是 Flutter/Android 侧的既有拼写（见 `lib/pigeon.dart` 的 `Owner.disPlayName`
   * 与 Android `Pigeon.Owner.Builder.setDisPlayName`），不能"修正"。
   *
   * ⚠️ 鸿蒙 `Owner.initWithJson` 取的是 `json['iD']`（XmlUtils 把 `<ID>` 转成了
   * `iD`），所以 id 可能解析成功也可能为 undefined。pigeon 侧 id 非空 → 兜空串。
   */
  private static toOwner(owner: HarmonyOwner | undefined): PigeonOwner {
    if (owner === undefined || owner === null) {
      return new PigeonOwner('', undefined);
    }
    const id: string = owner.id !== undefined && owner.id !== null ? owner.id! : '';
    // 鸿蒙 displayName ←→ Flutter disPlayName
    return new PigeonOwner(id, owner.displayName);
  }

  /**
   * 鸿蒙模型里若干「声明为 number 但实际可能是 XML 文本字符串」的字段的安全转换。
   *
   * 例：`Content.size` 的 `initWithJson` 是 `result.size = json['size']`，
   * 未经 `StringUtils.parseInt`，XML 解析出来是字符串 `"1024"`。
   * 若直接透传，codec 会按 `typeof === 'string'` 发成字符串，
   * Dart 侧 `result[3]! as int` 会抛类型错误。
   */
  private static toNumber(value: ESObject): number {
    if (value === undefined || value === null) {
      return 0;
    }
    if (typeof value === 'number') {
      const n: number = value as number;
      return Number.isFinite(n) ? n : 0;
    }
    const parsed: number = Number.parseInt(`${value}`, 10);
    return Number.isNaN(parsed) ? 0 : parsed;
  }

  /**
   * 响应头 `Record<string, string>` → pigeon 的 `Map<string|undefined, string|undefined>`。
   *
   * 对齐 Android 的 `simplifyHeader()`：Android 侧的 headers 是
   * `Map<String, List<String>>`（OkHttp 多值头），取每个 key 的第一个值降成单值；
   * 鸿蒙 rcp 给的本来就是 `Record<string, string>` 单值，因此这里只做容器转换，
   * 不存在「丢掉重复头的后续值」的问题。
   */
  static toHeaderMap(
    headers: Record<string, string> | undefined,
  ): Map<string | undefined, string | undefined> {
    const map: Map<string | undefined, string | undefined> =
      new Map<string | undefined, string | undefined>();
    if (headers === undefined || headers === null) {
      return map;
    }
    // ArkTS 里 Record 的遍历用 Object.keys
    const keys: string[] = Object.keys(headers);
    for (const key of keys) {
      map.set(key, headers[key]);
    }
    return map;
  }
}
