import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import '../lib/models/auth_models.dart';
import '../lib/services/cloud_api_client.dart';
import '../lib/services/harvest_sales_service.dart';

void main() {
  const farm = FarmSummary(id: 'area-a', code: 'A', name: 'A');
  const session = AuthSession(token: 'test',
    user: AuthUser(id: 'manager', email: '', displayName: 'Manager', role: UserRoles.farmManager),
    farms: [farm], selectedFarm: farm, isOrgAdmin: false);
  final frozen = DateTime(2026, 11, 24);
  final expiry = DateTime(2027, 1, 24);
  final lot = <String, dynamic>{'id':'lot-a', 'farmingAreaId':'area-a',
    'quantity':2, 'weightKg':0.25, 'status':'Available'};
  setUp(() => dotenv.testLoad(fileInput: 'CLOUD_API_URL=http://localhost:5080'));

  test('new lot starts with zero inventory and selected assigned area', () async {
    final client = CloudApiClient(client: MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/api/frozen-lots');
      final body = jsonDecode(request.body) as Map;
      expect(body['farmingAreaId'], 'area-a');
      expect(body['quantity'], 0);
      expect(body['weightKg'], 0);
      expect(body['lotCode'], 'LOT-A');
      return http.Response('{"success":true}', 201);
    }));
    final service = HarvestSalesService(session: session, api: client);
    addTearDown(service.dispose);
    await service.createFrozenLot(expectedArea: 'area-a', code: ' LOT-A ',
      frozenDate: frozen, expiryDate: expiry);
  });

  test('editing metadata preserves existing stock and status', () async {
    final client = CloudApiClient(client: MockClient((request) async {
      expect(request.method, 'PUT');
      expect(request.url.path, '/api/frozen-lots/lot-a');
      final body = jsonDecode(request.body) as Map;
      expect(body['quantity'], 2);
      expect(body['weightKg'], 0.25);
      expect(body['status'], 'Available');
      expect(body['storageLocation'], 'A1');
      return http.Response('{"success":true}', 200);
    }));
    final service = HarvestSalesService(session: session, api: client);
    addTearDown(service.dispose);
    await service.editFrozenLot(lot, frozenDate: frozen, expiryDate: expiry, location: 'A1');
  });

  test('invalid dates, cross area, occupied lot deletion and invalid opening balance are rejected locally', () async {
    final client = CloudApiClient(client: MockClient((_) async { fail('Unexpected HTTP request'); }));
    final service = HarvestSalesService(session: session, api: client);
    addTearDown(service.dispose);
    await expectLater(service.createFrozenLot(expectedArea: 'area-b', code:'LOT-A',
      frozenDate: frozen, expiryDate: expiry), throwsA(isA<CloudApiException>()));
    await expectLater(service.createFrozenLot(expectedArea: 'area-a', code:'LOT-A',
      frozenDate: expiry, expiryDate: frozen), throwsA(isA<CloudApiException>()));
    await expectLater(service.editFrozenLot({...lot,'farmingAreaId':'area-b'},
      frozenDate: frozen, expiryDate: expiry), throwsA(isA<CloudApiException>()));
    await expectLater(service.deleteFrozenLot(lot), throwsA(isA<CloudApiException>()));
    await expectLater(service.reconcileFrozenLot(lot, ['item','item'], 'audit'), throwsA(isA<CloudApiException>()));
    await expectLater(service.verifyFrozenOpeningBalance({
      'id':'balance-a','farmingAreaId':'area-a','verificationStatus':'Pending',
      'recordedQuantityDelta':1,'recordedWeightDeltaKg':0.1,
      'actualCurrentQuantity':2,'actualCurrentWeightKg':0.25,
    }, 3, 0.5, 'audit'), throwsA(isA<CloudApiException>()));
  });

  test('verified opening balance sends correct request without adjusting inventory', () async {
    final client = CloudApiClient(client: MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/api/frozen-opening-balances/balance-a/verify');
      final body = jsonDecode(request.body) as Map;
      expect(body['openingQuantity'], 1);
      expect(body['openingWeightKg'], 0.15);
      expect(body['reason'], 'verified ledger');
      return http.Response('{"success":true}', 200);
    }));
    final service = HarvestSalesService(session: session, api: client);
    addTearDown(service.dispose);
    await service.verifyFrozenOpeningBalance({
      'id':'balance-a','farmingAreaId':'area-a','verificationStatus':'Pending',
      'recordedQuantityDelta':1,'recordedWeightDeltaKg':0.1,
      'actualCurrentQuantity':2,'actualCurrentWeightKg':0.25,
    }, 1, 0.15, 'verified ledger');
  });
}
