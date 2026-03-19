// 测试总入口文件
//
// 汇总所有单元测试，方便一次性运行

import 'cos_test.dart' as cos_test;
import 'cos_service_test.dart' as cos_service_test;
import 'cos_transfer_manger_test.dart' as cos_transfer_manger_test;
import 'transfer_task_test.dart' as transfer_task_test;
import 'impl_flutter_cos_api_test.dart' as impl_flutter_cos_api_test;
import 'pigeon_models_test.dart' as pigeon_models_test;
import 'exceptions_test.dart' as exceptions_test;
import 'enums_test.dart' as enums_test;
import 'extensions_test.dart' as extensions_test;
import 'fetch_credentials_test.dart' as fetch_credentials_test;
import 'fetch_dns_test.dart' as fetch_dns_test;

void main() {
  // Cos 主类测试
  cos_test.main();
  
  // CosService 测试
  cos_service_test.main();
  
  // CosTransferManger 测试
  cos_transfer_manger_test.main();
  
  // TransferTask 测试
  transfer_task_test.main();
  
  // ImplFlutterCosApi 测试
  impl_flutter_cos_api_test.main();
  
  // Pigeon 数据模型测试
  pigeon_models_test.main();
  
  // 异常类测试
  exceptions_test.main();
  
  // 枚举类测试
  enums_test.main();
  
  // 扩展方法测试
  extensions_test.main();
  
  // 凭证接口测试
  fetch_credentials_test.main();
  
  // DNS 接口测试
  fetch_dns_test.main();
}
