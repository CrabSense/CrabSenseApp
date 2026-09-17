import 'package:crabsensemobile/features/mineral_dosing/data/models/salinity_mix_models.dart';
import 'package:flutter_test/flutter_test.dart';

/// Test bám đúng hợp đồng dữ liệu với BE: `null` phải ở lại `null` (nghĩa là "chưa
/// tính được"), không được hoá thành 0. Đây là lỗi đã từng xảy ra ở màn liều khoáng
/// và làm nông dân tưởng hệ thống tính sai gam.
void main() {
  group('SalinityDirection.fromApi', () {
    test('đọc đúng 4 hướng BE trả', () {
      expect(
        SalinityDirection.fromApi('INCREASE'),
        SalinityDirection.increase,
      );
      expect(
        SalinityDirection.fromApi('decrease'),
        SalinityDirection.decrease,
      );
      expect(SalinityDirection.fromApi('HOLD'), SalinityDirection.hold);
    });

    test('giá trị lạ / rỗng ⇒ unknown, không đoán', () {
      expect(SalinityDirection.fromApi(null), SalinityDirection.unknown);
      expect(SalinityDirection.fromApi(''), SalinityDirection.unknown);
      expect(SalinityDirection.fromApi('xyz'), SalinityDirection.unknown);
    });

    test('chỉ hướng increase mới cần muối, decrease mới cần nước ngọt', () {
      expect(SalinityDirection.increase.needsSalt, isTrue);
      expect(SalinityDirection.increase.needsFreshwater, isFalse);
      expect(SalinityDirection.decrease.needsFreshwater, isTrue);
      expect(SalinityDirection.decrease.needsSalt, isFalse);
      expect(SalinityDirection.hold.needsSalt, isFalse);
      expect(SalinityDirection.hold.needsFreshwater, isFalse);
    });
  });

  group('SalinityMixResult.fromJson — giữ null là null', () {
    test('khi tăng độ mặn: có muối, KHÔNG có nước ngọt', () {
      final r = SalinityMixResult.fromJson(const {
        'direction': 'INCREASE',
        'directionLabel': 'Cần TĂNG 10‰',
        'currentSalinityPpt': 10,
        'targetSalinityPpt': 20,
        'deltaPpt': 10,
        'waterVolumeL': 1000,
        'theoreticalSaltKg': 10.0,
        'actualSaltKg': 11.11,
        'saltPurityPercent': 90,
        'purityAssumed': false,
        'saltType': 'raw',
        'saltTypeLabel': 'Muối thô (muối biển phơi)',
        'saltTypeNote': 'ghi chú',
        'freshwaterToAddL': null,
        'finalVolumeL': null,
        'waterToReplaceL': null,
        'maxChangePerBatchPpt': 3,
        'batchCount': 4,
        'saltKgPerBatch': 2.78,
        'freshwaterLPerBatch': null,
        'batchIntervalHours': 12,
        'instructions': ['b1', 'b2'],
        'warnings': ['c1'],
        'nextSteps': ['n1', 'n2', 'n3'],
      });

      expect(r.direction, SalinityDirection.increase);
      expect(r.actualSaltKg, 11.11);
      expect(r.theoreticalSaltKg, 10.0);
      expect(r.saltPurityPercent, 90);
      expect(r.purityAssumed, isFalse);
      expect(r.batchCount, 4);
      expect(r.saltKgPerBatch, 2.78);
      expect(r.nextSteps, hasLength(3));
      // Không được biến null thành 0: UI dựa vào null để ẩn cả thẻ.
      expect(r.freshwaterToAddL, isNull);
      expect(r.finalVolumeL, isNull);
      expect(r.waterToReplaceL, isNull);
      expect(r.freshwaterLPerBatch, isNull);
    });

    test('khi giảm độ mặn: có nước ngọt, KHÔNG có muối', () {
      final r = SalinityMixResult.fromJson(const {
        'direction': 'DECREASE',
        'directionLabel': 'Cần GIẢM 10‰',
        'deltaPpt': -10,
        'waterVolumeL': 1000,
        'theoreticalSaltKg': null,
        'actualSaltKg': null,
        'saltPurityPercent': null,
        'freshwaterToAddL': 1000.0,
        'finalVolumeL': 2000.0,
        'waterToReplaceL': 500.0,
        'batchCount': 4,
        'freshwaterLPerBatch': 250.0,
        'saltKgPerBatch': null,
      });

      expect(r.direction, SalinityDirection.decrease);
      expect(r.freshwaterToAddL, 1000.0);
      expect(r.finalVolumeL, 2000.0);
      expect(r.waterToReplaceL, 500.0);
      expect(r.freshwaterLPerBatch, 250.0);
      expect(r.actualSaltKg, isNull);
      expect(r.saltKgPerBatch, isNull);
      expect(r.saltPurityPercent, isNull);
    });

    test('thiếu khoá / thiếu dữ liệu ⇒ giá trị an toàn, không ném lỗi', () {
      final r = SalinityMixResult.fromJson(const {'direction': 'UNKNOWN'});

      expect(r.direction, SalinityDirection.unknown);
      expect(r.directionLabel, '');
      expect(r.batchCount, 0);
      expect(r.deltaPpt, 0);
      expect(r.instructions, isEmpty);
      expect(r.warnings, isEmpty);
      expect(r.nextSteps, isEmpty);
      expect(r.actualSaltKg, isNull);
    });

    test('purityAssumed phải là true khi BE nói chưa biết độ tinh khiết', () {
      final r = SalinityMixResult.fromJson(const {
        'direction': 'INCREASE',
        'purityAssumed': true,
        'actualSaltKg': 10.0,
      });
      expect(r.purityAssumed, isTrue);
      expect(r.saltPurityPercent, isNull);
    });
  });

  group('SalinityMixRequest.toJson', () {
    test('bỏ hẳn khoá khi người dùng để trống, không gửi 0', () {
      final json = const SalinityMixRequest(
        waterVolumeL: 1000,
        currentSalinityPpt: 10,
      ).toJson();

      expect(json['waterVolumeL'], 1000);
      expect(json['currentSalinityPpt'], 10);
      expect(json['saltType'], 'raw');
      // Gửi 0 lên BE sẽ bị hiểu là "độ mặn mục tiêu 0‰" thay vì "chưa nhập".
      expect(json.containsKey('targetSalinityPpt'), isFalse);
      expect(json.containsKey('saltPurityPercent'), isFalse);
    });

    test('gửi đủ số khi người dùng đã nhập', () {
      final json = const SalinityMixRequest(
        waterVolumeL: 1000,
        currentSalinityPpt: 10,
        targetSalinityPpt: 20,
        saltType: 'sea_salt_mix',
        saltPurityPercent: 90,
      ).toJson();

      expect(json['targetSalinityPpt'], 20);
      expect(json['saltType'], 'sea_salt_mix');
      expect(json['saltPurityPercent'], 90);
    });
  });

  group('SaltType.fromJson', () {
    test('không có số tinh khiết ⇒ null (buộc phải đo lại)', () {
      final t = SaltType.fromJson(const {
        'key': 'raw',
        'label': 'Muối thô',
        'note': 'ghi chú',
        'typicalPurityPercent': null,
      });
      expect(t.key, 'raw');
      expect(t.typicalPurityPercent, isNull);
    });

    test('đọc được số tinh khiết khi BE có đưa', () {
      final t = SaltType.fromJson(const {
        'key': 'table',
        'label': 'Muối ăn',
        'typicalPurityPercent': 99,
      });
      expect(t.typicalPurityPercent, 99.0);
    });
  });
}
