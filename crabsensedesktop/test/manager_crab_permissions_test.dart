import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import '../lib/models/auth_models.dart';
import '../lib/models/crab_growth_molt.dart';
import '../lib/models/production_models.dart';
import '../lib/services/cloud_api_client.dart';
import '../lib/services/crab_service.dart';
import '../lib/services/crab_lot_inbound_service.dart';
import '../lib/services/crab_growth_molt_controller.dart';

void main() {
  const a = FarmSummary(id:'area-a',code:'A',name:'A');
  const b = FarmSummary(id:'area-b',code:'B',name:'B');
  const session = AuthSession(token:'test', user:AuthUser(id:'manager',email:'',displayName:'Manager',role:UserRoles.farmManager),
    farms:[a,b],selectedFarm:a,isOrgAdmin:false);
  setUp(() => dotenv.testLoad(fileInput:'CLOUD_API_URL=http://localhost:5080'));

  test('Manager creates an inbound lot with explicit selected area', () async {
    final api = CloudApiClient(client:MockClient((req) async {
      expect(req.method,'POST');
      expect(req.url.path,'/api/crab-lots');
      final body = jsonDecode(req.body) as Map;
      expect(body['farmingAreaId'],a.id);
      return http.Response(jsonEncode({'success':true,'data':{
        'id':'lot-a','lotCode':'LOT-A','name':'Lot A','quantity':10,'placedCount':0,
        'importDate':'2026-11-24T00:00:00Z','status':'Pending','farmingAreaIds':[a.id],
      }}),200);
    }));
    final svc = CrabService(session:session,api:api);
    addTearDown(svc.dispose);
    final lot = await svc.importLot(name:'Lot A',importDate:DateTime(2026,11,24),quantity:10);
    expect(lot?.farmingAreaIds,[a.id]);
    expect(svc.lots.single.id,'lot-a');
  });

  test('unknown crab cannot be deleted and unassigned Manager cannot import', () async {
    final api = CloudApiClient(client:MockClient((_) async { fail('Unexpected HTTP request'); }));
    final svc = CrabService(session:session,api:api);
    addTearDown(svc.dispose);
    expect(await svc.deleteCrab('other'),isFalse);
    svc.updateSession(session.copyWith(farms:[]));
    expect(await svc.importLot(name:'Lot',importDate:DateTime(2026,11,24),quantity:1),isNull);
  });

  test('partial-scope and outside-area lot mutations are blocked', () async {
    final api = CloudApiClient(client:MockClient((_) async { fail('Unexpected HTTP request'); }));
    final svc = CrabLotInboundService(session:session,api:api);
    addTearDown(svc.dispose);
    FarmingBatchRecord lot(String id,List<String> areas,{bool partial=false}) =>
      FarmingBatchRecord.fromJson({'id':id,'lotCode':id,'quantity':10,'placedCount':0,
        'status':'Pending','farmingAreaIds':areas,'isPartialScope':partial});
    final partial = lot('partial',[a.id],partial:true);
    await svc.upsert(partial);
    expect(svc.canManageLot(partial),isFalse);
    expect(await svc.cancel('partial'),isNull);
    await svc.upsert(lot('other',[b.id]));
    expect(svc.findById('other'),isNull);
    expect(await svc.updateInfo('other',name:'No'),isNull);
  });

  test('weight note correction without scoped permission does not hit API', () async {
    final api = CloudApiClient(client:MockClient((_) async { fail('Unexpected HTTP request'); }));
    final controller = CrabGrowthMoltController(crabId:'other',api:api,tokenProvider:()=> 'test',canCorrect:()=>false);
    addTearDown(controller.dispose);
    expect(await controller.updateNote(GrowthMeasurement(id:'weight',measuredAt:DateTime(2026,11,24),weightGram:100),'note'),isNotNull);
  });
}
