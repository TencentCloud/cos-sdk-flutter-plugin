import 'package:tencentcloud_cos_sdk_plugin/pigeon.dart';

class ObjectEntity {
  final int _type;//文件夹0 文件1
  final Content? _content;
  final CommonPrefixes? _commonPrefixes;

  ObjectEntity(this._type, this._content, this._commonPrefixes);

  int getType() {
    return _type;
  }

  Content? getContent() {
    return _content;
  }

  CommonPrefixes? getCommonPrefixes() {
    return _commonPrefixes;
  }

  static List<ObjectEntity> bucketContents2ObjectList(BucketContents bucketContents, String? prefix){
    List<ObjectEntity> list = <ObjectEntity>[];
      if(bucketContents.commonPrefixesList.isNotEmpty){
        for (CommonPrefixes? commonPrefixes in bucketContents.commonPrefixesList){
          if(commonPrefixes != null) {
            list.add(ObjectEntity(0, null, commonPrefixes));
          }
        }
      }
      if(bucketContents.contentsList.isNotEmpty){
        for (Content? content in bucketContents.contentsList){
          //文件夹内容过滤掉自身
          if(prefix == null || prefix.isEmpty || prefix != content!.key) {
            list.add(ObjectEntity(1, content, null));
          }
        }
      }
    return list;
  }
}