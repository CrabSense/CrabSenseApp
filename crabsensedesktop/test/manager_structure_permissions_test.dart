import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import '../lib/models/auth_models.dart';
import '../lib/services/area_management_service.dart';
import '../lib/services/row_management_service.dart';
import '../lib/services/production_management_service.dart';
import '../lib/services/cloud_api_client.dart';

void main() {
  const farm = FarmSummary(id: 'area-test', code: 'A', name: 'Test');
  const session = AuthSession(
    token: 'test-token',
    user: AuthUser(id: 'manager', email: '', displayName: 'Manager', role: UserRoles.farmManager),
    farms: [farm], selectedFarm: farm, isOrgAdmin: false,
  );

  test('Manager cannot send structure creation requests from desktop services', () async {
    final api = CloudApiClient(client: MockClient((request) async {
      fail('Unexpected HTTP request: ${request.method} ${request.url}');
    }));
    final areas = AreaManagementService(session: session, api: api);
    final rows = RowManagementService(session: session, api: api);
    final production = ProductionManagementService(session: session, api: api);
    addTearDown(areas.dispose);
    addTearDown(rows.dispose);
    addTearDown(production.dispose);
    await expectLater(areas.createArea(areaName: 'No'), throwsA(isA<CloudApiException>()));
    await expectLater(rows.create(areaId: farm.id, name: 'No'), throwsA(isA<CloudApiException>()));
    await expectLater(production.createBox(), throwsA(isA<CloudApiException>()));
    await expectLater(production.createBoxes(count: 2), throwsA(isA<CloudApiException>()));
  });
}
