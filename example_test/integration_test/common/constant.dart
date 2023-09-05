import 'package:cos_example_test/lib/pigeon.dart';

import '../config/config.dart';

class Constant {
  static final String PERSIST_BUCKET_REGION = TestConst().PERSIST_BUCKET_REGION;
  static final String PERSIST_BUCKET = "mobile-ut-1253960454";

  static final int PERSIST_BUCKET_SMALL_OBJECT_SIZE = 1024 * 1024;
  static final int PERSIST_BUCKET_BIG_OBJECT_SIZE = 10 * 1024 * 1024;
  static final int PERSIST_BUCKET_BIG_60M_OBJECT_SIZE = 60 * 1024 * 1024;
  static final String PERSIST_BUCKET_SMALL_OBJECT_PATH = "do_not_remove/small_object";
  static final String PERSIST_BUCKET_BIG_OBJECT_PATH = "do_not_remove/big_object";
  static final String PERSIST_BUCKET_BATCH_OBJECT_PATH = "do_not_remove//batch/small_object";
  static final String PERSIST_BUCKET_BIG_60M_OBJECT_PATH = "do_not_remove/big_60m_object";

  static final String TEMP_BUCKET_REGION = "ap-chengdu";
  static final String TEMP_BUCKET = "mobile-ut-temp-1253960454";

  static CosXmlServiceConfig serviceConfig = CosXmlServiceConfig(
    region: TestConst().PERSIST_BUCKET_REGION,
    isDebuggable: true,
  );
}
