import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import '../lib/models/auth_models.dart';
import '../lib/models/harvest_sales.dart';
import '../lib/services/cloud_api_client.dart';
import '../lib/services/harvest_assignment_service.dart';
import '../lib/services/harvest_sales_service.dart';

void main() {
  const farm = FarmSummary(id: 'area-a', code: 'A', name: 'A');
  const session = AuthSession(
    token: 'test', user: AuthUser(id: 'manager', email: '', displayName: 'Manager', role: UserRoles.farmManager),
    farms: [farm], selectedFarm: farm, isOrgAdmin: false,
  );
  final api = CloudApiClient(client: MockClient((r) async { fail('Unexpected HTTP request'); }));
  test('Manager assignment cannot target another area', () {
    final service = HarvestAssignmentService(session: session, api: api);
    expect(() => service.createAssignment(farmingAreaId: 'area-b', assignedToUserId: 'staff', crabIds: ['crab']), throwsA(isA<CloudApiException>()));
    expect(() => service.createAssignment(farmingAreaId: farm.id, assignedToUserId: 'staff', crabIds: ['crab', 'crab']), throwsA(isA<CloudApiException>()));
  });
  test('Invalid harvest decisions and missing rejection reasons never reach API', () async {
    await expectLater(api.decideHarvestVoucher('test', 'id', action: 'execute'), throwsA(isA<CloudApiException>()));
    await expectLater(api.decideHarvestVoucher('test', 'id', action: 'reject'), throwsA(isA<CloudApiException>()));
    await expectLater(api.decideFrozenTransaction('test', 'id', farmingAreaId: farm.id, approve: false), throwsA(isA<CloudApiException>()));
  });
  test('Manager cannot decide frozen transaction outside area or already approved', () async {
    final svc = HarvestSalesService(session: session, api: api);
    addTearDown(svc.dispose);
    await expectLater(svc.decideFrozen({'id':'id','farmingAreaId':'area-b','status':'PendingApproval'}, approve:true), throwsA(isA<CloudApiException>()));
    await expectLater(svc.decideFrozen({'id':'id','farmingAreaId':'area-a','status':'Approved'}, approve:true), throwsA(isA<CloudApiException>()));
  });
  test('Approved and rejected vouchers never appear completed', () {
    expect(parseHarvestUiStatus('Approved', stillInInventory: false), HarvestUiStatus.pending);
    expect(parseHarvestUiStatus('Rejected', stillInInventory: false), HarvestUiStatus.cancelled);
    expect(parseHarvestUiStatus('Unknown', stillInInventory: false), HarvestUiStatus.pending);
  });
}
