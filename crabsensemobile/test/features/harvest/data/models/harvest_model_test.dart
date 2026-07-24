import 'dart:convert';

import 'package:crabsensemobile/core/database/database.dart' as db;
import 'package:crabsensemobile/features/harvest/data/models/harvest_model.dart';
import 'package:crabsensemobile/features/harvest/domain/entities/harvest.dart';
import 'package:crabsensemobile/features/harvest/domain/entities/harvest_summary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final tHarvestDate = DateTime.parse('2026-07-21T10:00:00.000Z');

  final tHarvestModel = HarvestModel(
    id: 'harvest-123',
    boxId: 'BOX-01',
    farmId: 'FARM-01',
    totalWeight: 15.5,
    crabCount: 30,
    qualityGrade: QualityGrade.gradeA,
    harvestDate: tHarvestDate,
    operatorId: 'op-001',
    operatorName: 'John Doe',
    photoUrls: const ['https://example.com/photo.jpg'],
    notes: 'Good condition',
    createdAt: tHarvestDate,
    isSynced: true,
    isDirty: false,
  );

  group('HarvestModel JSON Tests', () {
    test('fromJson parses camelCase and snake_case correctly', () {
      final jsonMap = {
        'id': 'harvest-123',
        'box_id': 'BOX-01',
        'farm_id': 'FARM-01',
        'total_weight': 15.5,
        'crab_count': 30,
        'quality_grade': 'GRADE_A',
        'harvest_date': '2026-07-21T10:00:00.000Z',
        'operator_id': 'op-001',
        'operator_name': 'John Doe',
        'photo_urls': ['https://example.com/photo.jpg'],
        'notes': 'Good condition',
        'is_synced': true,
      };

      final result = HarvestModel.fromJson(jsonMap);

      expect(result.id, 'harvest-123');
      expect(result.boxId, 'BOX-01');
      expect(result.farmId, 'FARM-01');
      expect(result.totalWeight, 15.5);
      expect(result.crabCount, 30);
      expect(result.qualityGrade, QualityGrade.gradeA);
      expect(result.operatorId, 'op-001');
      expect(result.photoUrls, ['https://example.com/photo.jpg']);
      expect(result.notes, 'Good condition');
    });

    test('toJson serializes to Map with correct types', () {
      final jsonMap = tHarvestModel.toJson();

      expect(jsonMap['id'], 'harvest-123');
      expect(jsonMap['boxId'], 'BOX-01');
      expect(jsonMap['farmId'], 'FARM-01');
      expect(jsonMap['totalWeight'], 15.5);
      expect(jsonMap['crabCount'], 30);
      expect(jsonMap['qualityGrade'], 'GRADE_A');
      expect(jsonMap['operatorId'], 'op-001');
    });
  });

  group('HarvestModel Drift & Entity Mapping Tests', () {
    test('toDriftCompanion creates valid Drift update companion', () {
      final companion = tHarvestModel.toDriftCompanion();

      expect(companion.id.value, 'harvest-123');
      expect(companion.boxId.value, 'BOX-01');
      expect(companion.totalWeight.value, 15.5);
      expect(companion.crabCount.value, 30);
      expect(companion.qualityGrade.value, 'GRADE_A');
      expect(companion.harvestedBy.value, 'op-001');
      expect(companion.photoUrls.value, jsonEncode(['https://example.com/photo.jpg']));
    });

    test('fromDrift maps Drift table row correctly', () {
      final row = db.Harvest(
        id: 'harvest-123',
        boxId: 'BOX-01',
        totalWeight: 15.5,
        crabCount: 30,
        qualityGrade: 'GRADE_A',
        harvestDate: tHarvestDate,
        harvestedBy: 'op-001',
        photoUrls: jsonEncode(['https://example.com/photo.jpg']),
        notes: 'Good condition',
        isDirty: false,
        cachedAt: tHarvestDate,
      );

      final model = HarvestModel.fromDrift(row, farmId: 'FARM-01', operatorName: 'John Doe');

      expect(model.id, 'harvest-123');
      expect(model.boxId, 'BOX-01');
      expect(model.farmId, 'FARM-01');
      expect(model.operatorName, 'John Doe');
      expect(model.qualityGrade, QualityGrade.gradeA);
    });

    test('toEntity and fromEntity convert domain entity seamlessly', () {
      final entity = tHarvestModel.toEntity();
      expect(entity, isA<Harvest>());
      expect(entity.id, tHarvestModel.id);

      final convertedModel = HarvestModel.fromEntity(entity, isDirty: false);
      expect(convertedModel.id, tHarvestModel.id);
    });
  });

  group('HarvestSummaryModel Tests', () {
    test('fromJson & toJson map HarvestSummary correctly', () {
      final jsonMap = {
        'farm_id': 'FARM-01',
        'farm_name': 'Main Farm',
        'start_date': '2026-07-14T00:00:00.000Z',
        'end_date': '2026-07-21T00:00:00.000Z',
        'total_weight': 120.0,
        'total_crab_count': 240,
        'total_harvests_count': 8,
        'grade_breakdown': {
          'GRADE_A': 70.0,
          'GRADE_B': 30.0,
          'GRADE_C': 20.0,
        },
      };

      final summaryModel = HarvestSummaryModel.fromJson(jsonMap);

      expect(summaryModel.farmId, 'FARM-01');
      expect(summaryModel.farmName, 'Main Farm');
      expect(summaryModel.totalWeight, 120.0);
      expect(summaryModel.totalCrabCount, 240);
      expect(summaryModel.totalHarvestsCount, 8);
      expect(summaryModel.gradeBreakdown[QualityGrade.gradeA], 70.0);

      final serialized = summaryModel.toJson();
      expect(serialized['farmId'], 'FARM-01');
      expect(serialized['totalWeight'], 120.0);

      final entity = summaryModel.toEntity();
      expect(entity, isA<HarvestSummary>());
      expect(entity.farmId, 'FARM-01');
    });
  });
}
