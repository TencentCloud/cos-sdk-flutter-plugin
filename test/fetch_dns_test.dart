// Fetch DNS 接口测试
//
// 测试 IFetchDns 接口

import 'package:flutter_test/flutter_test.dart';
import 'package:tencentcloud_cos_sdk_plugin/fetch_dns.dart';

// Mock IFetchDns 实现 - 返回固定 IP
class TestFetchDns implements IFetchDns {
  int callCount = 0;
  String? lastDomain;
  
  @override
  Future<List<String>?> fetchDns(String domain) async {
    callCount++;
    lastDomain = domain;
    return ['192.168.1.1', '192.168.1.2'];
  }
}

// Mock IFetchDns 实现 - 返回 null
class TestFetchDnsNull implements IFetchDns {
  @override
  Future<List<String>?> fetchDns(String domain) async {
    return null;
  }
}

// Mock IFetchDns 实现 - 返回空列表
class TestFetchDnsEmpty implements IFetchDns {
  @override
  Future<List<String>?> fetchDns(String domain) async {
    return [];
  }
}

// Mock IFetchDns 实现 - 根据域名返回不同 IP
class TestFetchDnsDynamic implements IFetchDns {
  @override
  Future<List<String>?> fetchDns(String domain) async {
    if (domain.contains('guangzhou')) {
      return ['10.0.0.1', '10.0.0.2'];
    } else if (domain.contains('beijing')) {
      return ['20.0.0.1', '20.0.0.2'];
    }
    return ['30.0.0.1'];
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('IFetchDns 接口测试', () {
    test('fetchDns 应该返回 IP 列表', () async {
      final fetcher = TestFetchDns();
      
      final ips = await fetcher.fetchDns('example.cos.ap-guangzhou.myqcloud.com');
      
      expect(ips, isNotNull);
      expect(ips?.length, equals(2));
      expect(ips?[0], equals('192.168.1.1'));
      expect(ips?[1], equals('192.168.1.2'));
      expect(fetcher.callCount, equals(1));
    });

    test('fetchDns 应该记录请求的域名', () async {
      final fetcher = TestFetchDns();
      
      await fetcher.fetchDns('test.example.com');
      
      expect(fetcher.lastDomain, equals('test.example.com'));
    });

    test('fetchDns 应该能返回 null', () async {
      final fetcher = TestFetchDnsNull();
      
      final ips = await fetcher.fetchDns('example.com');
      
      expect(ips, isNull);
    });

    test('fetchDns 应该能返回空列表', () async {
      final fetcher = TestFetchDnsEmpty();
      
      final ips = await fetcher.fetchDns('example.com');
      
      expect(ips, isNotNull);
      expect(ips?.isEmpty, isTrue);
    });

    test('fetchDns 应该能根据域名返回不同 IP', () async {
      final fetcher = TestFetchDnsDynamic();
      
      final guangzhouIps = await fetcher.fetchDns('bucket.cos.ap-guangzhou.myqcloud.com');
      final beijingIps = await fetcher.fetchDns('bucket.cos.ap-beijing.myqcloud.com');
      final otherIps = await fetcher.fetchDns('bucket.cos.ap-shanghai.myqcloud.com');
      
      expect(guangzhouIps?[0], equals('10.0.0.1'));
      expect(beijingIps?[0], equals('20.0.0.1'));
      expect(otherIps?[0], equals('30.0.0.1'));
    });

    test('多次调用 fetchDns 应该正确计数', () async {
      final fetcher = TestFetchDns();
      
      await fetcher.fetchDns('domain1.com');
      await fetcher.fetchDns('domain2.com');
      await fetcher.fetchDns('domain3.com');
      
      expect(fetcher.callCount, equals(3));
      expect(fetcher.lastDomain, equals('domain3.com'));
    });
  });

  group('IFetchDns 边界条件测试', () {
    test('fetchDns 应该处理空域名', () async {
      final fetcher = TestFetchDns();
      
      final ips = await fetcher.fetchDns('');
      
      expect(ips, isNotNull);
      expect(fetcher.lastDomain, equals(''));
    });

    test('fetchDns 应该处理特殊字符域名', () async {
      final fetcher = TestFetchDns();
      
      final ips = await fetcher.fetchDns('test-bucket_123.cos.ap-guangzhou.myqcloud.com');
      
      expect(ips, isNotNull);
      expect(fetcher.lastDomain, contains('test-bucket_123'));
    });

    test('fetchDns 应该处理 IP 地址作为域名', () async {
      final fetcher = TestFetchDns();
      
      final ips = await fetcher.fetchDns('192.168.1.1');
      
      expect(ips, isNotNull);
    });
  });
}
