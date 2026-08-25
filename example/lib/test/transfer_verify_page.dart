// 鸿蒙侧传输链路自动验证页（P3-7）
//
// 目的：传输链路上有三个「静态查不出、手点 UI 也难稳定复现」的高危点，
// 需要可复现、可断言的验证：
//   T-A  byteArr(Uint8List) 上传 —— ArkTS 侧 pigeon 把 Uint8List 声明为 number[]，
//        运行时实际是 Uint8Array，且可能是整条 pigeon 消息 ByteBuffer 上的**视图**。
//        若直接取 .buffer 会把整条消息当文件上传（静默数据损坏）。
//        断言方式：上传已知内容，再 HEAD 取 Content-Length 与源字节数比对。
//   T-B  T1 拦截 —— 鸿蒙 pause()/cancel() 会触发 onFail，插件层必须拦截，
//        不得上抛为 resultFailCallback（否则用户点暂停会收到"传输失败"）。
//        断言方式：pause 后检查是否收到 fail 回调。
//   T-C  状态机跃迁 —— SDK 1.2.5 刚放开 onState，需确认序列正确且
//        pause 后的在途请求失败不会把 PAUSED 覆写成 FAILED。
//
// 用法：
//   1) 构建：flutter build hap --debug --dart-define=COS_VERIFY=true
//      （注意值必须是 "true"，`bool.fromEnvironment` 不认 "1"）
//   2) 装到模拟器（无需签名证书）：
//      hdc file send entry-default-unsigned.hap data/local/tmp/x
//      hdc shell bm install -p data/local/tmp/x
//      hdc shell aa start -a EntryAbility -b <bundleName> -m entry
//   3) 读结果，两种都可以：
//      · hdc shell hilog -x | grep COSVERIFY
//        （鸿蒙上 Dart print 落在 tag `XComFlutterOHOS_Native` 的
//         "flutter settings log message:" 里，而**不是**常见的 `flutter:`）
//      · hdc shell snapshot_display -f /data/local/tmp/v.jpeg 截屏看 UI 汇总
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:tencentcloud_cos_sdk_plugin/cos.dart';
import 'package:tencentcloud_cos_sdk_plugin/cos_service.dart';
import 'package:tencentcloud_cos_sdk_plugin/cos_transfer_manger.dart';
import 'package:tencentcloud_cos_sdk_plugin/enums.dart';
import 'package:tencentcloud_cos_sdk_plugin/pigeon.dart';
import 'package:tencentcloud_cos_sdk_plugin/transfer_task.dart';

/// 统一前缀，便于 hilog 过滤。
///
/// 鸿蒙上 Dart 的 `print` 会落到 hilog，但 tag 是
/// `XComFlutterOHOS_Native: flutter settings log message:`，
/// 不是常见的 `flutter:`，按后者过滤会以为"没有输出"。
/// UI 渲染仍保留，作为截屏读取的备用通道。
void _log(String msg) {
  developer.log('COSVERIFY|$msg', name: 'COSVERIFY');
  // ignore: avoid_print
  print('COSVERIFY|$msg');
}

/// 断言结果收集器。
/// 因为 print/developer.log 在鸿蒙上都不可见，断言必须进入 UI 才能被截屏读到，
/// 所以这里集中收集，由页面统一渲染。
final List<String> _assertions = <String>[];

/// 页面注册的刷新回调，_assert 触发后立即上屏
void Function()? _onAssertionAdded;

void _assert(String name, bool ok, String detail) {
  final String line = '${ok ? "PASS" : "FAIL"}|$name|$detail';
  _log(line);
  _assertions.add(line);
  _onAssertionAdded?.call();
}

/// 选中的测试桶及其真实地域
class _BucketPick {
  const _BucketPick(this.name, this.region);
  final String name;
  final String region;
}

/// T-A 上传的内容，T-D 下载后用它做端到端比对
final String _expectedPayload = 'harmony-bytearr-verify-${'x' * 333}';

class TransferVerifyPage extends StatefulWidget {
  const TransferVerifyPage({Key? key}) : super(key: key);

  @override
  State<TransferVerifyPage> createState() => _TransferVerifyPageState();
}

class _TransferVerifyPageState extends State<TransferVerifyPage> {
  final List<String> _lines = <String>[];

  void _ui(String s) {
    _log(s);
    if (mounted) {
      setState(() => _lines.add(s));
    }
  }

  @override
  void initState() {
    super.initState();
    _assertions.clear();
    _onAssertionAdded = () {
      if (mounted) setState(() {});
    };
    WidgetsBinding.instance.addPostFrameCallback((_) => _runAll());
  }

  @override
  void dispose() {
    _onAssertionAdded = null;
    super.dispose();
  }

  Future<void> _runAll() async {
    _ui('==== transfer verify start ====');
    try {
      // 动态取一个真实 bucket，避免硬编码猜错；同时顺带验证 ModelConverter
      final _BucketPick? pick = await _pickBucket();
      if (pick == null) {
        _assert('precondition.bucket', false, 'no usable bucket found');
        return;
      }
      _ui('using bucket=${pick.name} region=${pick.region}');

      await _caseByteArrUpload(pick);
      await _casePauseResumeCancel(pick);
      await _caseDownload(pick);
      await _caseBooleanBothWays(pick);
    } catch (e, st) {
      _assert('runAll', false, 'unexpected: $e\n$st');
    }
    _ui('==== transfer verify done ====');
  }

  /// 选一个**真实可用**的测试桶。
  ///
  /// 踩过两个坑，都记在这里：
  /// 1) `getService` 因分页只返回前 2000 个桶，其中可能有已删除的，不能直接拿来用。
  /// 2) **不能用 `doesBucketExist` 探测**：它的 pigeon 签名没有 region 参数
  ///    （Android 也一样），内部会回落到 `config.region`。拿一个 ap-chengdu 的桶
  ///    去探测就会拼成 `xxx.cos.ap-guangzhou.myqcloud.com` 而真 404 -> 返回 false。
  ///    这是接口的既有限制而非缺陷。
  /// 所以这里用**带 region 的 headBucket**（region 取自 `bucket.location`）来探测。
  Future<_BucketPick?> _pickBucket() async {
    try {
      final ListAllMyBuckets result = await Cos().getDefaultService().getService();
      final List<Bucket?> buckets = result.buckets;
      _assert('getService', buckets.isNotEmpty, 'bucketCount=${buckets.length}');
      if (buckets.isEmpty) return null;

      final Bucket b = buckets.first!;
      // ModelConverter 里做过字段改名：creationDate->createDate、bucketType->type、
      // displayName->disPlayName。漏一个就会静默丢字段，这里逐一断言非空。
      _assert('model.Bucket.name', b.name.isNotEmpty, 'name=${b.name}');
      _assert('model.Bucket.createDate', (b.createDate ?? '').isNotEmpty,
          'createDate=${b.createDate}');
      _assert('model.Owner.id', result.owner.id.isNotEmpty, 'ownerId=${result.owner.id}');
      _assert('model.Bucket.location', (b.location ?? '').isNotEmpty,
          'location=${b.location}');

      // 用带 region 的 headBucket 探测，最多试 12 个
      int probed = 0;
      for (final Bucket? item in buckets) {
        if (item == null || (item.location ?? '').isEmpty) continue;
        if (probed >= 12) break;
        probed++;
        try {
          await Cos()
              .getDefaultService()
              .headBucket(item.name, region: item.location);
          _ui('probe ${item.name}@${item.location} -> OK');
          _assert('headBucket', true, '${item.name}@${item.location}');
          return _BucketPick(item.name, item.location!);
        } catch (e) {
          _ui('probe ${item.name}@${item.location} -> $e');
        }
      }
      _assert('precondition.usableBucket', false, 'probed=$probed, none usable');
      return null;
    } catch (e) {
      _assert('getService', false, '$e');
      return null;
    }
  }

  /// T-A：byteArr 上传 + 用 HEAD 校验字节数，证明没有把整条 pigeon 消息当文件传
  Future<void> _caseByteArrUpload(_BucketPick pick) async {
    final String bucket = pick.name;
    const String cosPath = 'harmony_verify/bytearr.txt';
    // 用可辨识内容，长度刻意不是 2 的幂，便于发现越界/截断
    final Uint8List bytes = Uint8List.fromList(utf8.encode(_expectedPayload));
    _ui('T-A byteArr upload: expect ${bytes.length} bytes');

    final CosTransferManger tm = Cos().getDefaultTransferManger();
    bool done = false;
    String failMsg = '';

    void onSuccess(Map<String?, String?>? header, CosXmlResult? result) {
      done = true;
      _ui('T-A upload success eTag=${result?.eTag}');
    }

    void onFail(CosXmlClientException? ce, CosXmlServiceException? se) {
      done = true;
      failMsg = 'client=${ce?.errorCode}/${ce?.message} service=${se?.statusCode}/${se?.errorMessage}';
    }

    await tm.upload(bucket, cosPath,
        region: pick.region,
        byteArr: bytes,
        resultListener: ResultListener(onSuccess, onFail));

    await _waitUntil(() => done, const Duration(seconds: 60));
    _assert('T-A.upload', failMsg.isEmpty && done, failMsg.isEmpty ? 'ok' : failMsg);
    if (failMsg.isNotEmpty) return;

    // 关键断言：服务端记录的长度必须等于源字节数。
    // 若 ArkTS 侧误用了 .buffer（整条 pigeon 消息），这里会明显偏大。
    try {
      final Map<String?, String?> head =
          await Cos().getDefaultService().headObject(bucket, cosPath, region: pick.region);
      final String? len = head['content-length'] ?? head['Content-Length'];
      _assert('T-A.contentLength', len == '${bytes.length}',
          'expect=${bytes.length} actual=$len');
    } catch (e) {
      _assert('T-A.contentLength', false, 'headObject failed: $e');
    }
  }

  /// T-B + T-C：pause 不得触发 fail 回调；状态序列正确；cancel 同理
  Future<void> _casePauseResumeCancel(_BucketPick pick) async {
    final String bucket = pick.name;
    const String cosPath = 'harmony_verify/pause_resume.bin';
    // 需要足够大才能在传输中途暂停；6MB 会走分块上传（阈值 1MB）
    final Uint8List big = Uint8List(6 * 1024 * 1024);
    for (int i = 0; i < big.length; i++) {
      big[i] = i & 0xFF;
    }
    _ui('T-B/T-C pause-resume-cancel: ${big.length} bytes');

    final CosTransferManger tm = Cos().getDefaultTransferManger();
    final List<String> states = <String>[];
    int failCount = 0;
    String failDetail = '';
    bool finished = false;
    String? uploadId;

    void onSuccess(Map<String?, String?>? header, CosXmlResult? result) {
      finished = true;
      _ui('T-B upload finished (unexpected for cancel case) eTag=${result?.eTag}');
    }

    void onFail(CosXmlClientException? ce, CosXmlServiceException? se) {
      failCount++;
      failDetail = 'client=${ce?.errorCode}/${ce?.message} service=${se?.statusCode}';
      _ui('T-B got FAIL callback #$failCount: $failDetail');
    }

    void onState(TransferState s) {
      states.add(s.name);
      _ui('T-C state -> ${s.name}');
    }

    final TransferTask task = await tm.upload(bucket, cosPath,
        region: pick.region,
        byteArr: big,
        resultListener: ResultListener(onSuccess, onFail),
        stateCallback: onState,
        initMultipleUploadCallback: (String b, String k, String id) {
          uploadId = id;
          _ui('T-C initMultipleUpload uploadId=$id');
        });

    // 等到真正开始传输再暂停
    await _waitUntil(() => states.contains('IN_PROGRESS'), const Duration(seconds: 20));
    _assert('T-C.state.IN_PROGRESS', states.contains('IN_PROGRESS'), 'states=$states');

    await task.pause();
    // 给在途分块的失败回调留出时间——这正是「PAUSED 被覆写成 FAILED」的窗口
    await Future<void>.delayed(const Duration(seconds: 5));

    _assert('T-B.pauseNoFailCallback', failCount == 0,
        'failCount=$failCount detail=$failDetail');
    _assert('T-C.state.PAUSED', states.contains('PAUSED'), 'states=$states');
    _assert('T-C.pausedNotOverwritten', states.last == 'PAUSED',
        'last=${states.last} states=$states');

    // resume 后应回到 IN_PROGRESS
    final int beforeResume = states.length;
    await task.resume();
    await _waitUntil(
        () => states.length > beforeResume, const Duration(seconds: 20));
    _assert('T-C.resume', states.length > beforeResume,
        'states=$states (uploadId=$uploadId)');

    // cancel 同样不应触发 fail 回调
    final int failBeforeCancel = failCount;
    await task.cancel();
    await Future<void>.delayed(const Duration(seconds: 5));
    _assert('T-B.cancelNoFailCallback', failCount == failBeforeCancel,
        'failCount=$failCount detail=$failDetail');
    _assert('T-C.state.CANCELED', states.contains('CANCELED'), 'states=$states');
    _ui('T-C final states=$states finished=$finished');
  }

  /// 下载链路 + 进度回调
  Future<void> _caseDownload(_BucketPick pick) async {
    final String bucket = pick.name;
    const String cosPath = 'harmony_verify/bytearr.txt';
    _ui('T-D download start');
    final CosTransferManger tm = Cos().getDefaultTransferManger();

    bool done = false;
    String failMsg = '';
    int lastComplete = 0;
    int lastTarget = 0;
    final List<String> states = <String>[];

    // 下载到应用沙箱目录。
    // 注意：**鸿蒙上 path_provider 没有实现**（实测 MissingPluginException:
    // getApplicationDocumentsDirectory on channel plugins.flutter.io/path_provider），
    // 所以这里不能用 path_provider，改用鸿蒙应用沙箱的固定路径。
    // el2/base/haps/entry/files 是 entry 模块的私有可写目录。
    const String savePath =
        '/data/storage/el2/base/haps/entry/files/cos_verify_download.txt';
    _ui('T-D savePath=$savePath');

    await tm.download(bucket, cosPath, savePath,
        region: pick.region,
        resultListener: ResultListener((h, r) {
          done = true;
          _ui('T-D download success');
        }, (ce, se) {
          done = true;
          failMsg = 'client=${ce?.errorCode}/${ce?.message} service=${se?.statusCode}/${se?.errorMessage}';
        }),
        stateCallback: (TransferState s) => states.add(s.name),
        progressCallBack: (int complete, int target) {
          lastComplete = complete;
          lastTarget = target;
        });

    await _waitUntil(() => done, const Duration(seconds: 60));
    _assert('T-D.download', failMsg.isEmpty && done, failMsg.isEmpty ? 'ok' : failMsg);
    _assert('T-D.progress', lastTarget > 0 && lastComplete > 0,
        'complete=$lastComplete target=$lastTarget');
    _assert('T-D.state.COMPLETED', states.contains('COMPLETED'), 'states=$states');

    // 端到端内容校验：下载回来的内容必须与 T-A 上传的完全一致。
    // 这比只看 Content-Length 更强 —— 能一并证明 ArkTS 侧 byteArr 的
    // Uint8Array 视图裁剪没有取错偏移（取错会得到等长但内容错乱的数据）。
    if (failMsg.isEmpty) {
      try {
        final String got = await File(savePath).readAsString();
        _assert('T-A.contentRoundTrip', got == _expectedPayload,
            'len=${got.length} expect=${_expectedPayload.length} '
            'head=${got.length > 24 ? got.substring(0, 24) : got}');
      } catch (e) {
        _assert('T-A.contentRoundTrip', false, 'read downloaded file failed: $e');
      }
    }
  }

  /// 布尔参数双向用例（与 integration_test/cos_consistency_test.dart 同源）。
  ///
  /// 鸿蒙上 `flutter test integration_test` 走签名路径无法直接跑，
  /// 所以把同一组断言并入本页，用 `bm install` 路径覆盖。
  /// 每个布尔项都测 true / false 两侧 —— 只测一侧会漏掉
  /// 「指针→BOOL 静默转换」与「ABI 失配」这两类失效形态。
  Future<void> _caseBooleanBothWays(_BucketPick pick) async {
    _ui('T-E boolean both ways');

    // isHttps 双向：必须真的产出 http:// 与 https://
    try {
      final CosService httpSvc = await Cos().registerService(
        'vp_http',
        CosXmlServiceConfig(region: pick.region, isHttps: false),
      );
      final String httpUrl =
          await httpSvc.getObjectUrl(pick.name, pick.region, 'it/probe.txt');
      _assert('T-E.isHttps.false', httpUrl.startsWith('http://'),
          'url=$httpUrl');

      final CosService httpsSvc = await Cos().registerService(
        'vp_https',
        CosXmlServiceConfig(region: pick.region, isHttps: true),
      );
      final String httpsUrl =
          await httpsSvc.getObjectUrl(pick.name, pick.region, 'it/probe.txt');
      _assert('T-E.isHttps.true', httpsUrl.startsWith('https://'),
          'url=$httpsUrl');
    } catch (e) {
      _assert('T-E.isHttps', false, '$e');
    }

    // domainSwitch 双向（实现里有取反）
    for (final bool v in <bool>[true, false]) {
      try {
        final CosService s = await Cos().registerService(
          'vp_domain_$v',
          CosXmlServiceConfig(region: pick.region, domainSwitch: v),
        );
        await s.headBucket(pick.name, region: pick.region);
        _assert('T-E.domainSwitch.$v', true, 'ok');
      } catch (e) {
        _assert('T-E.domainSwitch.$v', false, '$e');
      }
    }

    // accelerate=false 显式传（区分 nil 与"装箱的 NO"）
    try {
      final CosService s = await Cos().registerService(
        'vp_accel_false',
        CosXmlServiceConfig(region: pick.region, accelerate: false),
      );
      final String url =
          await s.getObjectUrl(pick.name, pick.region, 'it/probe.txt');
      _assert('T-E.accelerate.false', !url.contains('accelerate'), 'url=$url');
    } catch (e) {
      _assert('T-E.accelerate.false', false, '$e');
    }

    // signHost 双向（鸿蒙默认不签 Host，与 Android 相反 —— 陷阱 T2）
    for (final bool v in <bool>[false, true]) {
      try {
        final String url = await Cos().getDefaultService().getPresignedUrl(
              pick.name,
              'it/probe.txt',
              region: pick.region,
              signHost: v,
              signValidTime: 600,
            );
        _assert('T-E.signHost.$v',
            url.contains('q-signature') && url.contains('q-sign-algorithm'),
            'url=${url.length > 80 ? url.substring(0, 80) : url}');
      } catch (e) {
        _assert('T-E.signHost.$v', false, '$e');
      }
    }

    // versioning 双向读写（iOS 上 true 曾 SIGSEGV，鸿蒙是本次新补的 API）
    try {
      final CosService s = Cos().getDefaultService();
      for (final bool v in <bool>[false, true]) {
        await s.putBucketVersioning(pick.name, v, region: pick.region);
        final bool got =
            await s.getBucketVersioning(pick.name, region: pick.region);
        _assert('T-E.versioning.$v', got == v, 'expect=$v actual=$got');
      }
      await s.putBucketVersioning(pick.name, false, region: pick.region);
    } catch (e) {
      _assert('T-E.versioning', false, '$e');
    }

    // accelerate 双向读写（与 versioning 并列的 ABI 失配原发处；本次新补的 API）
    try {
      final CosService s = Cos().getDefaultService();
      for (final bool v in <bool>[false, true]) {
        await s.putBucketAccelerate(pick.name, v, region: pick.region);
        final bool got =
            await s.getBucketAccelerate(pick.name, region: pick.region);
        _assert('T-E.accelerateRW.$v', got == v, 'expect=$v actual=$got');
      }
      await s.putBucketAccelerate(pick.name, false, region: pick.region);
    } catch (e) {
      _assert('T-E.accelerateRW', false, '$e');
    }

    // isTruncated 必须双向可变（只断言 isA<bool> 抓不到"恒为 true"的缺陷）
    try {
      final CosService s = Cos().getDefaultService();
      for (final String path in <String>['it/trunc/a.txt', 'it/trunc/b.txt']) {
        bool done = false;
        await Cos().getDefaultTransferManger().upload(
              pick.name, path,
              region: pick.region,
              byteArr: Uint8List.fromList('x'.codeUnits),
              resultListener: ResultListener(
                (Map<String?, String?>? h, CosXmlResult? r) => done = true,
                (CosXmlClientException? ce, CosXmlServiceException? se) =>
                    done = true,
              ),
            );
        await _waitUntil(() => done, const Duration(seconds: 60));
      }
      // COS 列举有最终一致性窗口，先等两个对象都可见再断言，避免偶发失败
      final DateTime ld = DateTime.now().add(const Duration(seconds: 30));
      while (DateTime.now().isBefore(ld)) {
        final BucketContents probe = await s.getBucket(pick.name,
            region: pick.region, prefix: 'it/trunc/', maxKeys: 1000);
        if (probe.contentsList.length >= 2) break;
        await Future<void>.delayed(const Duration(seconds: 1));
      }

      final BucketContents t = await s.getBucket(pick.name,
          region: pick.region, prefix: 'it/trunc/', maxKeys: 1);
      _assert('T-E.isTruncated.true', t.isTruncated == true,
          'maxKeys=1 时应截断，actual=${t.isTruncated}');
      final BucketContents nt = await s.getBucket(pick.name,
          region: pick.region, prefix: 'it/trunc/', maxKeys: 1000);
      _assert('T-E.isTruncated.false', nt.isTruncated == false,
          'maxKeys=1000 时不应截断，actual=${nt.isTruncated}（恒为 true 说明缺陷复发）');
    } catch (e) {
      _assert('T-E.isTruncated', false, '$e');
    }

    // 预签名 URL 结构（q-header-list 直接反映 Host 是否入签 —— 陷阱 T2），
    // 打印出来与 Android/iOS 的 PRESIGN-SHAPE 逐字段比对
    for (final bool signHost in <bool>[true, false]) {
      try {
        final String url = await Cos().getDefaultService().getPresignedUrl(
              pick.name, 'it/presign_probe.txt',
              region: pick.region, signHost: signHost, signValidTime: 600,
            );
        final Uri uri = Uri.parse(url);
        final Map<String, String> q = uri.queryParameters;
        final bool ok = q.containsKey('q-sign-algorithm') &&
            q.containsKey('q-signature') &&
            q.containsKey('q-header-list');
        _assert('T-E.presign.$signHost', ok,
            'headerList=${q['q-header-list']} algorithm=${q['q-sign-algorithm']}');
        _ui('PRESIGN-SHAPE|signHost=$signHost|scheme=${uri.scheme}'
            '|headerList=${q['q-header-list']}'
            '|urlParamList=${q['q-url-param-list']}'
            '|algorithm=${q['q-sign-algorithm']}');
      } catch (e) {
        _assert('T-E.presign.$signHost', false, '$e');
      }
    }

    // 日志开关与 setCloseBeacon 双向（鸿蒙是空实现+warn，不得崩）
    try {
      for (final bool v in <bool>[false, true]) {
        await Cos().enableLogcat(v);
        await Cos().enableLogFile(v);
        await Cos().setCloseBeacon(v);
      }
      _assert('T-E.logSwitches', true, 'ok');
    } catch (e) {
      _assert('T-E.logSwitches', false, '$e');
    }

    // 已终结任务的 pause/resume/cancel 必须幂等（三端统一为静默返回）
    try {
      bool done = false;
      final TransferTask t = await Cos().getDefaultTransferManger().upload(
            pick.name, 'it/idempotent.txt',
            region: pick.region,
            byteArr: Uint8List.fromList('idempotent-probe'.codeUnits),
            resultListener: ResultListener(
              (Map<String?, String?>? h, CosXmlResult? r) => done = true,
              (CosXmlClientException? ce, CosXmlServiceException? se) =>
                  done = true,
            ),
          );
      await _waitUntil(() => done, const Duration(seconds: 90));
      await Future<void>.delayed(const Duration(seconds: 2));
      await t.cancel();
      await t.pause();
      await t.resume();
      _assert('T-E.terminalTaskIdempotent', true, 'ok');
    } catch (e) {
      _assert('T-E.terminalTaskIdempotent', false, '$e');
    }

    // addLogListener / removeLogListener 往返（非 0 key）
    try {
      void listener(LogEntity e) {}
      await Cos().addLogListener(listener);
      await Cos().removeLogListener(listener);
      _assert('T-E.logListener', true, 'ok');
    } catch (e) {
      _assert('T-E.logListener', false, '$e');
    }
  }

  Future<void> _waitUntil(bool Function() cond, Duration timeout) async {
    final DateTime deadline = DateTime.now().add(timeout);
    while (!cond() && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
  }

  @override
  Widget build(BuildContext context) {
    final int failCount =
        _assertions.where((String s) => s.startsWith('FAIL')).length;
    final int passCount =
        _assertions.where((String s) => s.startsWith('PASS')).length;
    return Scaffold(
      appBar: AppBar(title: const Text('鸿蒙传输链路验证')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // 汇总放顶部，截屏一眼可判定
          Container(
            width: double.infinity,
            color: failCount > 0 ? Colors.red.shade100 : Colors.green.shade100,
            padding: const EdgeInsets.all(10),
            child: Text(
              'PASS=$passCount  FAIL=$failCount',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          // 断言明细（失败标红）
          Expanded(
            flex: 3,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: _assertions.length,
              itemBuilder: (_, int i) => Text(
                _assertions[i],
                style: TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
                  color: _assertions[i].startsWith('FAIL')
                      ? Colors.red
                      : Colors.black87,
                ),
              ),
            ),
          ),
          const Divider(height: 1),
          // 过程日志
          Expanded(
            flex: 2,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: _lines.length,
              itemBuilder: (_, int i) => Text(
                _lines[i],
                style: const TextStyle(
                    fontSize: 10, fontFamily: 'monospace', color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
