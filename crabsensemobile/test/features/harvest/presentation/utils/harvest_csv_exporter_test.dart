import 'package:crabsensemobile/features/harvest/domain/entities/harvest.dart';
import 'package:crabsensemobile/features/harvest/presentation/utils/harvest_csv_exporter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final sampleHarvests = [
    Harvest(
      id: 'harvest-1',
      boxId: 'BOX-001',
      farmId: 'FARM-A',
      totalWeight: 15.5,
      crabCount: 10,
      qualityGrade: QualityGrade.gradeA,
      harvestDate: DateTime(2026, 7, 20, 10, 30),
      operatorId: 'op-123',
      operatorName: 'John Operator',
      notes: 'Healthy batch, no issues',
      createdAt: DateTime(2026, 7, 20, 10, 35),
    ),
    Harvest(
      id: 'harvest-2',
      boxId: 'BOX-002',
      farmId: 'FARM-A',
      totalWeight: 8.0,
      crabCount: 5,
      qualityGrade: QualityGrade.gradeB,
      harvestDate: DateTime(2026, 7, 21, 14, 0),
      operatorId: 'op-456',
      operatorName: 'Jane Smith',
      notes: null,
      createdAt: DateTime(2026, 7, 21, 14, 05),
    ),
  ];

  group('HarvestCsvExporter', () {
    test('generateCsvString creates formatted CSV with headers and records', () {
      final csv = HarvestCsvExporter.generateCsvString(sampleHarvests);

      expect(csv, contains('ID,Harvest Date,Farm ID,Box ID,Total Weight (kg),Crab Count,Quality Grade,Operator ID,Operator Name,Notes'));
      expect(csv, contains('harvest-1,2026-07-20 10:30:00,FARM-A,BOX-001,15.50,10,Grade A,op-123,John Operator,"Healthy batch, no issues"'));
      expect(csv, contains('harvest-2,2026-07-21 14:00:00,FARM-A,BOX-002,8.00,5,Grade B,op-456,Jane Smith'));
    });

    test('generateCsvString handles empty harvest list', () {
      final csv = HarvestCsvExporter.generateCsvString([]);
      final lines = csv.trim().split('\n');

      expect(lines.length, 1);
      expect(lines.first, contains('ID,Harvest Date,Farm ID'));
    });
  });
}
