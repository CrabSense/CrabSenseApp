import 'package:crabsensemobile/features/crab_management/data/datasources/crab_management_remote_datasource.dart';
import 'package:crabsensemobile/features/crab_management/data/models/crab_management_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('BE flat crab DTO maps scope and measures', () {
    final crab = CrabRecord.fromJson({
      'id': 'c', 'code': 'CRAB-1', 'farmingAreaId': 'a', 'farmingRowId': 'r',
      'areaName': 'A', 'boxId': 'b', 'crabLotId': 'lot', 'lotCode': 'LOT-1',
      'carapaceWidthMm': 92, 'carapaceLengthMm': 74, 'status': 'Alive',
      'condition': 'Normal', 'stockedAt': '2026-11-24T00:00:00Z',
    });
    expect(crab.code, 'CRAB-1');
    expect(crab.location.farmAreaId, 'a');
    expect(crab.location.rowId, 'r');
    expect(crab.batch.id, 'lot');
    expect(crab.shellWidthMm, 92);
    expect(crab.shellLengthMm, 74);
    expect(crab.lifecycleStatus, CrabLifecycleStatus.growing);
    expect(crab.canRecordOperations, isTrue);
  });
  test('softshell is a view classification, terminal/unknown cannot mutate', () {
    expect(CrabRecord.lifecycleFromBackend({'status':'Alive','condition':'softshell'}),
      CrabLifecycleStatus.readyToHarvest);
    for (final status in ['Dead','Sold','Harvested','Missing','Quarantined','invalid']) {
      expect(CrabRecord.fromJson({'status':status}).canRecordOperations, isFalse);
    }
  });
  test('mortality uses canonical cause and preserves unsupported reason', () {
    final at = DateTime.utc(2026, 11, 24);
    final payload = CrabManagementRemoteDataSourceImpl.mortalityPayload(
      'c', at, DeathReason.moltFailure, 'observed');
    expect(payload['crabId'], 'c');
    expect(payload['cause'], 7);
    expect(payload['mortalityDate'], at.toIso8601String());
    expect(payload['notes'], contains('Lột xác thất bại'));
    expect(payload['notes'], contains('observed'));
    expect(payload.containsKey('lifecycleStatus'), isFalse);
  });
}
