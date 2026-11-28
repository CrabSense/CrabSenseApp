import 'package:crabsensemobile/features/reports/data/reports_repository.dart';
import 'package:flutter_test/flutter_test.dart';

const empty = <String, dynamic>{
  'cohortBasis': 'stockedAt-current-status-v1', 'farmingAreaId': 'area-a',
  'totalCrabs': 0, 'aliveCrabs': 0, 'moltingCrabs': 0, 'moltedCrabs': 0,
  'harvestedCrabs': 0, 'deadCrabs': 0, 'unclassifiedCrabs': 0,
  'healthScore': 30,
};

void main() {
  test('efficiency rejects wrong area, legacy and zero denominator rates', () {
    final result = verifyEfficiencyReport(empty, 'area-a');
    expect(result['healthScore'], isNull);
    expect(result['harvestRate'], isNull);
    expect(() => verifyEfficiencyReport(empty, 'area-b'), throwsFormatException);
    expect(() => verifyEfficiencyReport({...empty, 'cohortBasis': null}, 'area-a'), throwsFormatException);
    expect(() => verifyEfficiencyReport({...empty, 'harvestRate': 0}, 'area-a'), throwsFormatException);
  });
  test('efficiency preserves actual zero with valid denominator', () {
    final known = {...empty, 'totalCrabs': 1, 'aliveCrabs': 1,
      'survivalRate': 100, 'aliveRate': 100, 'moltingRate': 0,
      'harvestRate': 0, 'mortalityRate': 0};
    expect(verifyEfficiencyReport(known, 'area-a')['harvestRate'], 0);
    expect(() => verifyEfficiencyReport({...known, 'harvestRate': false}, 'area-a'), throwsFormatException);
  });
}
