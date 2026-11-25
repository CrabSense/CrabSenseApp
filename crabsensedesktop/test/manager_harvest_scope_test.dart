import 'dart:async';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import '../lib/models/auth_models.dart';
import '../lib/models/harvest_sales.dart';
import '../lib/models/production_models.dart';
import '../lib/services/cloud_api_client.dart';
import '../lib/services/harvest_sales_service.dart';

void main() {
  test('raw lifecycle stays distinct from normalized display status', () {
    final alive = CrabManagementListItem.fromJson({'id':'a','status':'Alive','condition':'Softshell'});
    final quarantine = CrabManagementListItem.fromJson({'id':'q','status':'Quarantined'});
    final missing = CrabManagementListItem.fromJson({'id':'m','Status':'Missing'});
    expect(alive.rawStatus, 'Alive');
    expect(quarantine.status, 'alive');
    expect(quarantine.rawStatus, 'Quarantined');
    expect(missing.rawStatus, 'Missing');
    expect(missing.status, 'missing');
  });
  const a=FarmSummary(id:'area-a',code:'A',name:'A');
  const b=FarmSummary(id:'area-b',code:'B',name:'B');
  const session=AuthSession(token:'test',user:AuthUser(id:'manager',email:'',displayName:'Manager',role:UserRoles.farmManager),farms:[a,b],selectedFarm:a,isOrgAdmin:false);
  setUp(()=>dotenv.testLoad(fileInput:'CLOUD_API_URL=http://localhost:5080'));
  http.Response ok(Object data)=>http.Response(jsonEncode({'success':true,'data':data}),200);
  Map<String,dynamic> voucher(String id,String? area,String creator)=>{'id':id,'voucherCode':id,'status':'PendingApproval','createdBy':creator,'farmingAreaId':area,'harvestDate':DateTime.now().toUtc().toIso8601String(),'lines':[{'crabId':'crab','weightGram':50}]};
  test('old area read cannot overwrite current area or KPI',()async{
    final gate=Completer<http.Response>();
    final api=CloudApiClient(client:MockClient((req)async{
      if(req.url.path=='/api/harvest-vouchers'){
        if (req.url.queryParameters['farmingAreaId'] == a.id) return await gate.future;
        return ok([voucher('B', b.id, 'staff')]);
      }
      if(req.url.path.endsWith('/overview'))return ok({'harvestableCount':7});
      return ok([]);
    }));
    final svc=HarvestSalesService(session:session,api:api);
    addTearDown(svc.dispose);
    final first=svc.reloadHarvests();
    svc.updateSession(session.copyWith(selectedFarm:b));
    await svc.reloadHarvests();
    gate.complete(ok([voucher('A',a.id,'staff')]));
    await first;
    expect(svc.harvests.map((s)=>s.id),['B']);
    expect(svc.harvestKpi.harvestable,7);
  });
  test('null area, foreign area and self-approved voucher cannot be mutated',()async{
    var writes=0;
    final api=CloudApiClient(client:MockClient((req)async{
      if(req.method!='GET'){writes++;return ok({});}
      if(req.url.path=='/api/harvest-vouchers')return ok([voucher('self',a.id,'manager'),voucher('foreign',b.id,'staff'),voucher('unknown',null,'staff'),{...voucher('adjusted',a.id,'staff'),'adjustmentRequestedByUserId':'manager'}]);
      if(req.url.path.endsWith('/overview'))return ok({});
      return ok([]);
    }));
    final svc=HarvestSalesService(session:session,api:api);
    addTearDown(svc.dispose);
    await svc.reloadHarvests();
    expect(svc.harvests.map((s)=>s.id),['self','adjusted']);
    for(final id in ['self','foreign','unknown','adjusted']){
      await expectLater(svc.approveHarvest(id),throwsA(isA<CloudApiException>()));
    }
    await expectLater(svc.deleteHarvest('foreign'),throwsA(isA<CloudApiException>()));
    expect(writes,0);
  });
  test('active task reservation uses scoped detail and ignores finished tasks',()async{
    final api=CloudApiClient(client:MockClient((req)async{
      if(req.url.path=='/api/harvest-assignments')return ok([{'id':'open','status':'Assigned','farmingAreaId':a.id},{'id':'review','status':'PendingReview','farmingAreaId':a.id},{'id':'closed','status':'Completed','farmingAreaId':a.id}]);
      if(req.url.path=='/api/harvest-assignments/review')return ok({'farmingAreaId':a.id,'lines':[{'crabId':'pending'}]});
      expect(req.url.path,'/api/harvest-assignments/open');
      return ok({'farmingAreaId':a.id,'lines':[{'crabId':'reserved'}]});
    }));
    expect(await api.fetchOpenHarvestAssignmentCrabIds('test',farmingAreaId:a.id),{'reserved','pending'});
  });
}
