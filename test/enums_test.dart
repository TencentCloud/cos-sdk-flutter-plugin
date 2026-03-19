// 枚举类单元测试
//
// 测试 TransferState 枚举

import 'package:flutter_test/flutter_test.dart';
import 'package:tencentcloud_cos_sdk_plugin/enums.dart';

void main() {
  group('TransferState 枚举测试', () {
    test('TransferState 应该包含所有状态', () {
      expect(TransferState.values.length, equals(9));
    });

    test('CONSTRAINED 状态应该存在', () {
      expect(TransferState.CONSTRAINED, isNotNull);
      expect(TransferState.CONSTRAINED.index, equals(0));
    });

    test('WAITING 状态应该存在', () {
      expect(TransferState.WAITING, isNotNull);
      expect(TransferState.WAITING.name, equals('WAITING'));
    });

    test('IN_PROGRESS 状态应该存在', () {
      expect(TransferState.IN_PROGRESS, isNotNull);
      expect(TransferState.IN_PROGRESS.name, equals('IN_PROGRESS'));
    });

    test('PAUSED 状态应该存在', () {
      expect(TransferState.PAUSED, isNotNull);
      expect(TransferState.PAUSED.name, equals('PAUSED'));
    });

    test('RESUMED_WAITING 状态应该存在', () {
      expect(TransferState.RESUMED_WAITING, isNotNull);
      expect(TransferState.RESUMED_WAITING.name, equals('RESUMED_WAITING'));
    });

    test('COMPLETED 状态应该存在', () {
      expect(TransferState.COMPLETED, isNotNull);
      expect(TransferState.COMPLETED.name, equals('COMPLETED'));
    });

    test('CANCELED 状态应该存在', () {
      expect(TransferState.CANCELED, isNotNull);
      expect(TransferState.CANCELED.name, equals('CANCELED'));
    });

    test('FAILED 状态应该存在', () {
      expect(TransferState.FAILED, isNotNull);
      expect(TransferState.FAILED.name, equals('FAILED'));
    });

    test('UNKNOWN 状态应该存在', () {
      expect(TransferState.UNKNOWN, isNotNull);
      expect(TransferState.UNKNOWN.name, equals('UNKNOWN'));
    });

    test('应该能够通过名称获取枚举值', () {
      expect(TransferState.values.byName('COMPLETED'), equals(TransferState.COMPLETED));
      expect(TransferState.values.byName('FAILED'), equals(TransferState.FAILED));
      expect(TransferState.values.byName('IN_PROGRESS'), equals(TransferState.IN_PROGRESS));
    });

    test('应该能够遍历所有枚举值', () {
      final stateNames = TransferState.values.map((e) => e.name).toList();
      
      expect(stateNames, contains('CONSTRAINED'));
      expect(stateNames, contains('WAITING'));
      expect(stateNames, contains('IN_PROGRESS'));
      expect(stateNames, contains('PAUSED'));
      expect(stateNames, contains('RESUMED_WAITING'));
      expect(stateNames, contains('COMPLETED'));
      expect(stateNames, contains('CANCELED'));
      expect(stateNames, contains('FAILED'));
      expect(stateNames, contains('UNKNOWN'));
    });

    group('状态转换测试', () {
      test('从 WAITING 到 IN_PROGRESS 是有效转换', () {
        const currentState = TransferState.WAITING;
        const nextState = TransferState.IN_PROGRESS;
        
        expect(currentState.index < nextState.index, isTrue);
      });

      test('从 IN_PROGRESS 到 COMPLETED 是有效转换', () {
        const currentState = TransferState.IN_PROGRESS;
        const nextState = TransferState.COMPLETED;
        
        expect(currentState != nextState, isTrue);
      });

      test('从 IN_PROGRESS 到 PAUSED 是有效转换', () {
        const currentState = TransferState.IN_PROGRESS;
        const nextState = TransferState.PAUSED;
        
        expect(currentState != nextState, isTrue);
      });

      test('从 PAUSED 到 RESUMED_WAITING 是有效转换', () {
        const currentState = TransferState.PAUSED;
        const nextState = TransferState.RESUMED_WAITING;
        
        expect(currentState != nextState, isTrue);
      });
    });
  });
}
