import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'constant.dart';

class FileUtils {
  static Future<String> localParentPath() async {
    // 获取临时目录
    final directory = await getTemporaryDirectory();
    return directory.path;
  }

  static Future<String> localPath(String subPath) async {
    if (!subPath.startsWith("/")) {
      subPath = "/" + subPath;
    }

    return await localParentPath() + subPath;
  }

  static Future<String> createFile(String absolutePath, int fileLength) async {
    // 创建临时文件
    final file = File(absolutePath);
    // 写入指定大小的数据
    await file.writeAsBytes(List.filled(fileLength, 0));
    // 返回文件路径
    return file.path;
  }

  static Future<String> smallFilePath() async {
    String filePath = await localPath("temp_file");
    return createFile(filePath, Constant.PERSIST_BUCKET_SMALL_OBJECT_SIZE);
  }

  static Future<String> bigFilePath() async {
    String filePath = await localPath("temp_file");
    return createFile(filePath, Constant.PERSIST_BUCKET_BIG_OBJECT_SIZE);
  }

  static Future<String> big60mFilePath() async {
    String filePath = await localPath("temp_file");
    return createFile(filePath, Constant.PERSIST_BUCKET_BIG_60M_OBJECT_SIZE);
  }

  static Future<String> bigPlusFilePath() async {
    String filePath = await localPath("temp_file");
    return createFile(filePath, Constant.PERSIST_BUCKET_BIG_OBJECT_SIZE + 369);
  }
}