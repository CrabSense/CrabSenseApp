import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import '../lib/models/auth_models.dart';
import '../lib/models/crab_growth_molt.dart';
import '../lib/models/production_models.dart';
import '../lib/services/cloud_api_client.dart';
import '../lib/services/crab_lot_inbound_service.dart';

void main() {
  const a=FarmSummary(id:'area-a',code:'A',name:'A');
  const session=AuthSession(token:'test',user:AuthUser(id:'manager',email:'',displayName:'Manager',role:UserRoles.farmManager),farms:[a],selectedFarm:a,isOrgAdmin:false);
  setUp(()=>dotenv.testLoad(fileInput:'CLOUD_API_URL=http://localhost:5080'));
  Map<String,dynamic> lot({bool closed=false,int placed=0,bool partial=false})=> {
    'id':'lot-a','lotCode':'LOT-A','quantity':10,'placedCount':placed,'status':'Pending',
    'farmingAreaIds':[a.id],'isPartialScope':partial,'stockedAt':'2026-11-01T00:00:00Z',
    if(closed)'closedAt':'2026-11-24T00:00:00Z',
    if(closed)'closeDisposition':'keep raising',
    if(closed)'unmoltedCountAtClose':3,
  };
  test('close uses dedicated endpoint and retains authoritative snapshot',() async{
    final api=CloudApiClient(client:MockClient((req) async{
      expect(req.method,'POST');expect(req.url.path,'/api/crab-lots/lot-a/close');
      expect(jsonDecode(req.body),{'disposition':'keep raising'});
      return http.Response(jsonEncode({'success':true,'data':lot(closed:true)}),200);
    }));
    final svc=CrabLotInboundService(session:session,api:api);
    addTearDown(svc.dispose);
    await svc.upsert(FarmingBatchRecord.fromJson(lot(placed:10)));
    final record=await svc.close('lot-a','keep raising');
    expect(record?.isClosed,isTrue);
    expect(record?.closeCounts['unmoltedCountAtClose'],3);
    expect(svc.canCloseLot(record!),isFalse);
    expect(svc.canDeleteLot(record),isFalse);
    expect(await svc.cancel('lot-a'),isNull);
  });
  test('partial scope, registered crabs and missing disposition block relevant mutations',() async{
    final api=CloudApiClient(client:MockClient((_) async{fail('Unexpected request');}));
    final svc=CrabLotInboundService(session:session,api:api);
    addTearDown(svc.dispose);
    await svc.upsert(FarmingBatchRecord.fromJson(lot(partial:true)));
    expect(await svc.close('lot-a','reason'),isNull);
    await svc.upsert(FarmingBatchRecord.fromJson(lot(placed:1)));
    expect(await svc.deleteUnused('lot-a'),isFalse);
    expect(await svc.close('lot-a',' '),isNull);
  });
  test('void retains record metadata and API uses audit endpoint',() async{
    final api=CloudApiClient(client:MockClient((req) async{
      expect(req.method,'POST');expect(req.url.path,'/api/moltings/molt-a/void');
      expect(jsonDecode(req.body),{'reason':'duplicate event'});
      return http.Response('{"success":true}',200);
    }));
    await api.voidMolting('test','molt-a','area-a','duplicate event');
    final event=MoltEvent.fromJson({'id':'molt-a','result':'success','isVoided':true,'voidReason':'duplicate event'});
    expect(event.isVoided,isTrue);expect(event.voidReason,'duplicate event');
  });
  test('allocation correction does not implicitly close open allocation',() async{
    final api=CloudApiClient(client:MockClient((req) async{
      expect(req.method,'PUT');expect(req.url.path,'/api/allocations/alloc-a');
      final body=jsonDecode(req.body) as Map;
      expect(body.containsKey('endTime'),isFalse);
      expect(body['notes'],'corrected with reason');
      return http.Response('{"success":true}',200);
    }));
    await api.correctAllocation('test','alloc-a','area-a',notes:'corrected with reason');
  });
}
