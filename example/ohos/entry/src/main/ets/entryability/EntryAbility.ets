
import {
  FlutterAbility,
  FlutterEngine,
  MethodChannel,
  MethodCall,
  MethodResult,
  Log,
} from '@ohos/flutter_ohos';
import { GeneratedPluginRegistrant } from '../plugins/GeneratedPluginRegistrant';
import picker from '@ohos.file.picker';
import fs from '@ohos.file.fs';

const TAG = 'EntryAbility';
const FILE_PICKER_CHANNEL = 'example/file_picker';

export default class EntryAbility extends FlutterAbility {
  configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    GeneratedPluginRegistrant.registerWith(flutterEngine)
    this.registerFilePickerChannel(flutterEngine)
  }

  /**
   * 为 example 提供「选择文件」能力。
   *
   * file_picker 插件没有鸿蒙实现（点击无反应），这里用 DocumentViewPicker
   * 选文件后复制到应用沙箱，把沙箱路径回传给 Dart 侧，COS SDK 直接用
   * fs.openSync 读这个路径即可上传。
   */
  private registerFilePickerChannel(flutterEngine: FlutterEngine): void {
    const channel = new MethodChannel(
      flutterEngine.getDartExecutor().getBinaryMessenger(),
      FILE_PICKER_CHANNEL
    );
    channel.setMethodCallHandler({
      onMethodCall: (call: MethodCall, result: MethodResult): void => {
        if (call.method === 'pickFile') {
          this.handlePickFile(result);
        } else {
          result.notImplemented();
        }
      }
    });
  }

  private handlePickFile(result: MethodResult): void {
    this.pickAndCopyFile()
      .then((path: string): void => {
        result.success(path);
      })
      .catch((err: Error): void => {
        Log.e(TAG, 'pick file failed: ' + err.message);
        result.error('PICK_FAILED', err.message ?? 'pick file failed', null);
      });
  }

  private async pickAndCopyFile(): Promise<string> {
    // DocumentViewPicker 必须在 UIAbility context 下创建
    const documentPicker = new picker.DocumentViewPicker(this.context);
    const options = new picker.DocumentSelectOptions();
    options.maxSelectNumber = 1;
    const uris: Array<string> = await documentPicker.select(options);
    if (uris.length === 0) {
      return ''; // 用户取消
    }
    const srcUri: string = uris[0];
    const rawName: string = srcUri.substring(srcUri.lastIndexOf('/') + 1);
    let fileName: string = rawName;
    try {
      // picker 会把中文等字符转义成 %XX，这里解码还原真实文件名
      fileName = decodeURIComponent(rawName);
    } catch (e) {
      fileName = rawName;
    }
    const destPath: string = `${this.context.filesDir}/${fileName}`;
    // DocumentViewPicker 返回 file:// URI，fs.copyFile 无法直接识别该 URI
    // （会抛 13900002 No such file or directory），需先 open 得到 fd，再以 fd 复制到沙箱
    const srcFile = await fs.open(srcUri, fs.OpenMode.READ_ONLY);
    try {
      await fs.copyFile(srcFile.fd, destPath);
    } finally {
      await fs.close(srcFile);
    }
    return destPath;
  }
}
