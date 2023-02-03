import 'dart:io' show Platform;

class TestConst {
  final String UT_TAG = "QCloudTest";

  late String COS_APPID;
  late String OWNER_UIN;
  late String SECRET_ID;
  late String SECRET_KEY;
  late String PERSIST_BUCKET_REGION;
  late String PERSIST_BUCKET;
  late String PERSIST_BUCKET_CDN_SIGN;
  late String PERSIST_BUCKET_PIC_PATH;
  late String PERSIST_BUCKET_QR_PATH;
  late String PERSIST_BUCKET_VIDEO_PATH;
  late String PERSIST_BUCKET_SELECT_JSON_PATH;
  late String PERSIST_BUCKET_SELECT_CSV_PATH;
  late String PERSIST_BUCKET_DOCUMENT_PATH;
  late String PERSIST_BUCKET_POST_OBJECT_PATH;
  late String PERSIST_BUCKET_APPEND_OBJECT_PATH;
  late String PERSIST_BUCKET_COPY_OBJECT_DST_PATH;
  late String PERSIST_BUCKET_DEEP_ARCHIVE_OBJECT_PATH;
  late String PERSIST_BUCKET_REPLICATION;
  late String PERSIST_BUCKET_REPLICATION_REGION;

  TestConst._internal(){
    COS_APPID = Platform.environment['COS_APPID']??"";
    OWNER_UIN = Platform.environment['OWNER_UIN']??"";
    SECRET_ID = Platform.environment['COS_SECRET_ID']??"";
    SECRET_KEY = Platform.environment['COS_SECRET_KEY']??"";
    PERSIST_BUCKET_REGION = Platform.environment['PERSIST_BUCKET_REGION']??"";
    PERSIST_BUCKET = Platform.environment['PERSIST_BUCKET']??"";
    PERSIST_BUCKET_CDN_SIGN = Platform.environment['PERSIST_BUCKET_CDN_SIGN']??"";
    PERSIST_BUCKET_PIC_PATH = "do_not_remove/image.png";
    PERSIST_BUCKET_QR_PATH = "do_not_remove/qr.png";
    PERSIST_BUCKET_VIDEO_PATH = "do_not_remove/video.mp4";
    PERSIST_BUCKET_SELECT_JSON_PATH = "do_not_remove/select.json";
    PERSIST_BUCKET_SELECT_CSV_PATH = "do_not_remove/select.csv";
    PERSIST_BUCKET_DOCUMENT_PATH = "do_not_remove/document.docx";
    PERSIST_BUCKET_POST_OBJECT_PATH = "do_not_remove/post_object";
    PERSIST_BUCKET_APPEND_OBJECT_PATH = "do_not_remove/append_object";
    PERSIST_BUCKET_COPY_OBJECT_DST_PATH = "do_not_remove/copy_dst_object";
    PERSIST_BUCKET_DEEP_ARCHIVE_OBJECT_PATH = "do_not_remove/small_object_archive";
    PERSIST_BUCKET_REPLICATION = Platform.environment['PERSIST_BUCKET_REPLICATION']??"";
    PERSIST_BUCKET_REPLICATION_REGION = Platform.environment['PERSIST_BUCKET_REPLICATION_REGION']??"";
  }
  factory TestConst() => _instance;
  static final TestConst _instance = TestConst._internal();
}