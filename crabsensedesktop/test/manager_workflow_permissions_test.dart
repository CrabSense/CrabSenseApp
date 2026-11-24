import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import '../lib/models/auth_models.dart';
import '../lib/services/cloud_api_client.dart';
import '../lib/services/ras_flow_service.dart';

void main() {
  const farm = FarmSummary(id: 'test-area', code: 'A', name: 'Test');
  const session = AuthSession(
    token: 'test-token',
    user: AuthUser(id: 'manager', email: '', displayName: 'Manager', role: UserRoles.farmManager),
    farms: [farm], selectedFarm: farm, isOrgAdmin: false,
  );
  test('Manager cannot change RAS topology or hardware mapping', () async {
    final service = RasFlowService(session: session);
    addTearDown(service.dispose);
    expect(await service.addFlow(areaId: farm.id, fromId: 'a', toId: 'b'), isFalse);
    expect(await service.deleteNode(areaId: farm.id, nodeId: 'a'), isFalse);
    expect(await service.updateNodeRelay(areaId: farm.id, nodeId: 'a'), isFalse);
  });
  test('disposing RAS service suppresses queued listener notifications', () async {
    final service = RasFlowService(session: session);
    var notifications = 0;
    service.addListener(() => notifications++);
    service.stopLiveRefresh();
    service.dispose();
    await Future<void>.delayed(Duration.zero);
    expect(notifications, 0);
  });
  test('Report requests reject an unassigned area or unsupported endpoint', () async {
    final api = CloudApiClient(client: MockClient((r) async {
      fail('Unexpected HTTP request');
    }));
    await expectLater(api.fetchManagerReport('token', 'harvest', areaId: ''), throwsA(isA<CloudApiException>()));
    await expectLater(api.fetchManagerReport('token', '../users', areaId: 'a'), throwsA(isA<CloudApiException>()));
  });
}
