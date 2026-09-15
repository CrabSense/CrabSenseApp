// Check cho hợp đồng BE ↔ model mobile của bộ tính liều khoáng Ca/Mg.
//
// Payload bên dưới là JSON THẬT chụp từ BE đang chạy (`/api/mineral-dosing`),
// nên test này fail ngay khi BE đổi tên trường hoặc mobile đọc sai khoá —
// đúng thứ dễ vỡ nhất khi nối FE với BE.

import 'dart:convert';

import 'package:crabsensemobile/features/mineral_dosing/data/models/mineral_dose_models.dart';
import 'package:flutter_test/flutter_test.dart';

/// `GET /api/mineral-dosing/targets?salinityPpt=10`
const _targetsAt10Ppt = r'''
{"success":true,"data":{
  "salinityPpt":10,
  "recommendedCalciumMgL":300,
  "recommendedMagnesiumMgL":900,
  "recommendedCaMgRatio":"1:3",
  "calciumMagnesiumTotalMgL":1200,
  "note":"Đây là mục tiêu ĐỀ XUẤT theo độ mặn, không phải giá trị bắt buộc.",
  "warnings":["Tổng Ca+Mg 1200 mg/L vượt xa vùng đã kiểm chứng (600 mg/L ở 1,5‰)."]
}}''';

/// `POST /api/mineral-dosing/calculate` — 1,5‰, đã đo CẢ Ca và Mg.
const _calculateFull = r'''
{"success":true,"data":{
  "targetMode":"auto",
  "usedRecommendedTargets":true,
  "recommendedCalciumMgL":150,
  "recommendedMagnesiumMgL":450,
  "recommendedCaMgRatio":"1:3",
  "calciumTargetMgL":150,
  "magnesiumTargetMgL":450,
  "calciumMagnesiumTotalTargetMgL":600,
  "calciumCurrentMgL":90,
  "magnesiumCurrentMgL":300,
  "calciumCurrentSource":"measured",
  "magnesiumCurrentSource":"measured",
  "calciumMagnesiumTotalCurrentMgL":390,
  "calciumDeficitMgL":60,
  "magnesiumDeficitMgL":150,
  "caCl2DoseGrams":229.3,
  "mgCl2DoseGrams":1273.3,
  "caCl2Product":"CaCl2·2H2O 96%",
  "mgCl2Product":"MgCl2·6H2O 98,5%",
  "salinityStatus":"SALINITY_LOW",
  "salinityStatusLabel":"Độ mặn thấp hơn mức tiêu (1,5 < 3‰)",
  "maxIncreasePerDoseMgL":50,
  "doseCount":3,
  "caCl2GramsPerDose":76.4,
  "mgCl2GramsPerDose":424.4,
  "doseIntervalHours":24,
  "dosingInstructions":["Chia thành 3 lần, cách nhau tối thiểu 24 giờ (1 lần/ngày).","Hoà tan RIÊNG từng muối trong hai xô nước bể."],
  "warnings":["Độ mặn 1,5‰ → 150/450."]
}}''';

/// Cùng endpoint nhưng KHÔNG gửi Mg — BE phải bỏ hẳn các trường phụ thuộc Mg.
const _calculateNoMagnesium = r'''
{"success":true,"data":{
  "targetMode":"auto",
  "usedRecommendedTargets":true,
  "recommendedCalciumMgL":300,
  "recommendedMagnesiumMgL":900,
  "recommendedCaMgRatio":"1:3",
  "calciumTargetMgL":300,
  "magnesiumTargetMgL":900,
  "calciumMagnesiumTotalTargetMgL":1200,
  "calciumCurrentMgL":200,
  "calciumCurrentSource":"measured",
  "magnesiumCurrentSource":"missing",
  "calciumDeficitMgL":100,
  "caCl2DoseGrams":382.1,
  "caCl2Product":"CaCl2·2H2O 96%",
  "mgCl2Product":"MgCl2·6H2O 98,5%",
  "salinityStatus":"SALINITY_UNKNOWN",
  "salinityStatusLabel":"Chưa đủ dữ liệu độ mặn",
  "warnings":["Chưa đo Mg — KHÔNG tính được liều MgCl2. Hệ thống không suy Mg từ Ca; cần test Mg."]
}}''';

Map<String, dynamic> _data(String raw) =>
    (jsonDecode(raw) as Map<String, dynamic>)['data']
        as Map<String, dynamic>;

void main() {
  group('MineralTargetRecommendation', () {
    test('đọc đúng mục tiêu đề xuất theo độ mặn 10‰', () {
      final rec = MineralTargetRecommendation.fromJson(_data(_targetsAt10Ppt));

      expect(rec.salinityPpt, 10);
      expect(rec.calciumMgL, 300);
      expect(rec.magnesiumMgL, 900);
      expect(rec.ratio, '1:3');
      expect(rec.totalMgL, 1200);
      expect(rec.hasTargets, isTrue);
      expect(rec.note, isNotEmpty);
      expect(rec.warnings, isNotEmpty);
    });

    test('thiếu độ mặn ⇒ không có mục tiêu, không phải 0', () {
      final rec = MineralTargetRecommendation.fromJson(
        _data(r'{"success":true,"data":{"salinityPpt":null,'
            r'"recommendedCalciumMgL":null,"recommendedMagnesiumMgL":null,'
            r'"recommendedCaMgRatio":null,"calciumMagnesiumTotalMgL":null,'
            r'"note":"Chưa đủ dữ liệu để đề xuất.","warnings":[]}}'),
      );

      expect(rec.calciumMgL, isNull);
      expect(rec.magnesiumMgL, isNull);
      expect(rec.hasTargets, isFalse);
    });
  });

  group('MineralDoseResult', () {
    test('đọc đủ liều CaCl2/MgCl2 và tổng khi đã đo cả Ca lẫn Mg', () {
      final r = MineralDoseResult.fromJson(_data(_calculateFull));

      expect(r.targetMode, 'auto');
      expect(r.usedRecommendedTargets, isTrue);

      expect(r.calciumTargetMgL, 150);
      expect(r.magnesiumTargetMgL, 450);
      expect(r.calciumMagnesiumTotalTargetMgL, 600);

      expect(r.calciumCurrentSource, ValueSource.measured);
      expect(r.magnesiumCurrentSource, ValueSource.measured);
      expect(r.calciumMagnesiumTotalCurrentMgL, 390);

      expect(r.calciumDeficitMgL, 60);
      expect(r.magnesiumDeficitMgL, 150);

      expect(r.caCl2DoseGrams, closeTo(229.3, 0.001));
      expect(r.mgCl2DoseGrams, closeTo(1273.3, 0.001));
      expect(r.caCl2Product, contains('CaCl2'));
      expect(r.mgCl2Product, contains('MgCl2'));

      expect(r.salinityStatus, 'SALINITY_LOW');
      expect(r.calciumMissing, isFalse);
      expect(r.magnesiumMissing, isFalse);

      // Kế hoạch chia liều — để không sốc cua. Mg thiếu 150 mg/L ⇒ 150/50 = 3 lần.
      expect(r.needsDosing, isTrue);
      expect(r.doseCount, 3);
      expect(r.maxIncreasePerDoseMgL, 50);
      expect(r.caCl2GramsPerDose, closeTo(76.4, 0.001));
      expect(r.mgCl2GramsPerDose, closeTo(424.4, 0.001));
      expect(r.doseIntervalHours, 24);
      expect(r.dosingInstructions, hasLength(2));
      expect(r.dosingInstructions.first, contains('3 lần'));
    });

    test('Ca/Mg đã đủ ⇒ doseCount 0, KHÔNG hiện kế hoạch châm', () {
      final r = MineralDoseResult.fromJson(
        _data(r'{"success":true,"data":{"targetMode":"auto",'
            r'"usedRecommendedTargets":true,"caCl2DoseGrams":0,"mgCl2DoseGrams":0,'
            r'"doseCount":0,"maxIncreasePerDoseMgL":50,"doseIntervalHours":24,'
            r'"dosingInstructions":["Không cần châm: Ca/Mg đã đạt hoặc vượt mục tiêu."]}}'),
      );

      expect(r.needsDosing, isFalse);
      expect(r.doseCount, 0);
      expect(r.caCl2GramsPerDose, isNull);
      expect(r.dosingInstructions.first, contains('Không cần châm'));
    });

    test('BE cũ chưa trả kế hoạch chia liều ⇒ giá trị mặc định an toàn', () {
      final r = MineralDoseResult.fromJson(
        _data(r'{"success":true,"data":{"targetMode":"auto",'
            r'"usedRecommendedTargets":false}}'),
      );

      expect(r.doseCount, 0);
      expect(r.needsDosing, isFalse);
      expect(r.maxIncreasePerDoseMgL, 0);
      expect(r.doseIntervalHours, 24);
      expect(r.dosingInstructions, isEmpty);
      expect(r.caCl2GramsPerDose, isNull);
    });

    test('THIẾU Mg ⇒ không suy từ Ca: liều MgCl2 là null và báo "chưa đo"', () {
      final r = MineralDoseResult.fromJson(_data(_calculateNoMagnesium));

      expect(r.magnesiumMissing, isTrue);
      expect(r.magnesiumCurrentMgL, isNull);
      expect(r.magnesiumCurrentSource, ValueSource.missing);
      expect(r.magnesiumCurrentSource.labelVi, 'Chưa đo');

      // Cốt lõi: không được bịa ra liều MgCl2.
      expect(r.mgCl2DoseGrams, isNull);
      expect(r.magnesiumDeficitMgL, isNull);
      expect(r.calciumMagnesiumTotalCurrentMgL, isNull);

      // Ca vẫn tính được bình thường.
      expect(r.calciumMissing, isFalse);
      expect(r.caCl2DoseGrams, closeTo(382.1, 0.001));

      expect(r.warnings.join(' '), contains('không suy Mg từ Ca'));
    });

    test('trường vắng mặt trong JSON ⇒ null, không phải 0', () {
      final r = MineralDoseResult.fromJson(
        _data(r'{"success":true,"data":{"targetMode":"manual",'
            r'"usedRecommendedTargets":false,"calciumCurrentSource":"estimated"}}'),
      );

      expect(r.caCl2DoseGrams, isNull);
      expect(r.mgCl2DoseGrams, isNull);
      expect(r.calciumMagnesiumTotalTargetMgL, isNull);
      expect(r.caCl2Product, isEmpty);
      expect(r.warnings, isEmpty);
      expect(r.usedRecommendedTargets, isFalse);
    });
  });

  group('ValueSource', () {
    test('ánh xạ khoá API; khoá lạ ⇒ missing (không đoán bừa)', () {
      expect(ValueSource.fromApi('measured'), ValueSource.measured);
      expect(ValueSource.fromApi('estimated'), ValueSource.estimated);
      expect(ValueSource.fromApi('missing'), ValueSource.missing);
      expect(ValueSource.fromApi(null), ValueSource.missing);
      expect(ValueSource.fromApi('bịa'), ValueSource.missing);
    });
  });

  group('MineralDoseRequest.toJson', () {
    test('chế độ auto: bỏ mục tiêu để BE tự chọn theo độ mặn', () {
      final json = const MineralDoseRequest(
        waterVolumeL: 1000,
        salinityCurrentPpt: 10,
        calciumCurrentMgL: 200,
      ).toJson();

      expect(json['waterVolumeL'], 1000);
      expect(json['salinityCurrentPpt'], 10);
      expect(json['targetMode'], 'auto');
      // Không gửi mục tiêu ⇒ chỉ BE quyết định mục tiêu.
      expect(json.containsKey('calciumTargetMgL'), isFalse);
      expect(json.containsKey('magnesiumTargetMgL'), isFalse);
      // Không bịa số đo chưa có.
      expect(json.containsKey('magnesiumCurrentMgL'), isFalse);
    });

    test('chế độ manual: gửi mục tiêu người dùng nhập', () {
      final json = const MineralDoseRequest(
        waterVolumeL: 500,
        calciumTargetMgL: 320,
        magnesiumTargetMgL: 880,
        targetMode: MineralTargetMode.manual,
      ).toJson();

      expect(json['targetMode'], 'manual');
      expect(json['calciumTargetMgL'], 320);
      expect(json['magnesiumTargetMgL'], 880);
    });
  });
}
