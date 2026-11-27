import 'dart:async';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import '../lib/models/auth_models.dart';
import '../lib/services/cloud_api_client.dart';
import '../lib/services/water_quality_service.dart';

const area='11111111-1111-1111-1111-111111111111';
const sensor='22222222-2222-2222-2222-222222222222';
const rowId='33333333-3333-3333-3333-333333333333';
const farm=FarmSummary(id:area,code:'A',name:'A');
const session=AuthSession(token:'fixture',user:AuthUser(id:'manager',email:'',
  displayName:'Manager',role:UserRoles.farmManager),farms:[farm],selectedFarm:farm,isOrgAdmin:false);
Map<String,dynamic> live() {
  final now=DateTime.now().toUtc();
  return {'sensorId':sensor,'sensorCode':'S01','farmingAreaId':area,
    'farmingRowId':rowId,'sensorType':'Salinity','unit':'ppt','latestValue':0,
    'isActive':true,'dataQuality':'Realtime','status':'Online',
    'latestMeasuredAt':now.subtract(const Duration(seconds:2)).toIso8601String(),
    'lastReceivedAt':now.subtract(const Duration(seconds:1)).toIso8601String()};
}
Map<String,dynamic> page(Map<String,String> q) {
  final t=DateTime.parse(q['to']!);
  final at=t.subtract(const Duration(seconds:5)).toIso8601String();
  return {'contract':'scoped-sensor-history-v1','farmingAreaId':area,
    'sensorId':sensor,'farmingRowId':rowId,'sensorType':'Salinity','unit':'ppt',
    'sensorActive':true,'from':q['from'],'to':q['to'],'asOf':q['to'],
    'page':1,'pageSize':250,'hasMore':false,'legacyUnqualifiedExcluded':true,
    'scopeBasis':'configured_location_at_ingest','physicalLocationVerified':false,
    'databaseSnapshotGuaranteed':false,'chemicalResultIncluded':false,
    'items':[{'id':'44444444-4444-4444-4444-444444444444','sensorId':sensor,
      'farmingAreaId':area,'farmingRowId':rowId,'sensorType':'Salinity','unit':'ppt',
      'value':0,'measuredAt':at,'receivedAt':at,'dataQuality':'Realtime','source':'edge'}]};
}
http.Response ok(Object? data)=>http.Response(jsonEncode({'success':true,'data':data}),200,
  headers:{'content-type':'application/json'});

void main(){
  setUp(()=>dotenv.testLoad(fileInput:'CLOUD_API_URL=http://localhost:5080'));
  test('explicit sensor request through HTTP pipeline preserves zero and exact scope',() async {
    var histories=0;
    final svc=WaterQualityService(session:session,api:CloudApiClient(client:MockClient((r)async{
      if(r.url.path=='/api/iot/live')return ok([live()]);
      histories++;
      expect(r.url.path,'/api/areas/$area/sensors/$sensor/history');
      expect(r.headers['authorization'],'Bearer fixture');
      expect(r.followRedirects,isFalse);
      expect(r.url.queryParameters['farmingRowId'],rowId);
      expect(r.url.queryParameters['pageSize'],'250');
      return ok(page(r.url.queryParameters));
    })));
    addTearDown(svc.dispose);
    await svc.refresh();
    expect(histories,0);
    svc.selectHistorySensor(sensor);
    await svc.refreshTrend();
    expect(histories,1);
    expect(svc.chartSeries.single.value,0);
    expect(svc.chartReading!.sensorId,sensor);
    svc.setChartRangeIndex(2);
    expect(svc.chartSeries,isEmpty);
  });

  test('reject mismatched metadata and HTTP denial without legacy fallback',() async {
    var denial=false;
    final svc=WaterQualityService(session:session,api:CloudApiClient(client:MockClient((r)async{
      if(r.url.path=='/api/iot/live')return ok([live()]);
      expect(r.url.path,endsWith('/history'));
      if(denial)return http.Response('denied',403);
      return ok({...page(r.url.queryParameters),'farmingRowId':null});
    })));
    addTearDown(svc.dispose);
    await svc.refresh();
    svc.selectHistorySensor(sensor);
    await svc.refreshTrend();
    expect(svc.chartSeries,isEmpty);
    expect(svc.historyError,isNotNull);
    denial=true;
    await svc.refreshTrend();
    expect(svc.chartSeries,isEmpty);
  });

  test('late history response after session change cannot restore chart',() async {
    final pending=Completer<http.Response>();
    final started=Completer<Map<String,String>>();
    final svc=WaterQualityService(session:session,api:CloudApiClient(client:MockClient((r)async{
      if(r.url.path=='/api/iot/live')return ok([live()]);
      started.complete(r.url.queryParameters);
      return pending.future;
    })));
    addTearDown(svc.dispose);
    await svc.refresh();
    svc.selectHistorySensor(sensor);
    final result=svc.refreshTrend();
    final q=await started.future;
    svc.updateSession(session.copyWith(token:'other'));
    pending.complete(ok(page(q)));
    await result;
    expect(svc.chartSeries,isEmpty);
    expect(svc.historySensorId,isNull);
    expect(svc.chartLoading,isFalse);
  });

  test('table and CSV share scoped snapshot and reject obsolete revision',() async {
    final svc=WaterQualityService(session:session,api:CloudApiClient(client:MockClient((r)async{
      if(r.url.path=='/api/iot/live')return ok([live()]);
      return ok(page(r.url.queryParameters));
    })));
    addTearDown(svc.dispose);
    await svc.refresh();
    svc.selectHistorySensor(sensor);
    await svc.refreshTrend();
    final table=svc.historyTable!;
    final row=table.rows.single;
    expect(table.sensorId,sensor);
    expect(table.rowId,rowId);
    expect(row.value,0);
    expect(svc.chartSeries.single.timestamp,DateTime.parse(row.measuredAt));
    expect(svc.chartSeries.single.value,row.value);
    final revision=svc.historyRevision;
    final csv=svc.exportScopedCsv(revision)!;
    expect(csv,contains('"$area","$rowId","$sensor","Salinity","ppt"'));
    expect(csv,contains(',0,"Realtime","edge"'));
    expect(csv,isNot(contains('fixture')));
    svc.setChartRangeIndex(2);
    expect(svc.historyTable,isNull);
    expect(svc.exportScopedCsv(revision),isNull);
    await svc.refreshTrend();
    expect(svc.historyTable,isNotNull);
    expect(svc.exportScopedCsv(revision),isNull);
    final next=svc.historyRevision;
    svc.updateSession(session.copyWith(token:'new-session'));
    expect(svc.historyTable,isNull);
    expect(svc.exportScopedCsv(next),isNull);
  });

  test('complete two-page table and CSV retain all rows and raw cutoff',() async {
    var requests=0;
    String? cutoff;
    final svc=WaterQualityService(session:session,api:CloudApiClient(client:MockClient((r)async{
      if(r.url.path=='/api/iot/live')return ok([live()]);
      final q=r.url.queryParameters;
      final data=page(q);
      final seed=(data['items'] as List).single as Map<String,dynamic>;
      final end=DateTime.parse(q['to']!);
      Map<String,dynamic> item(int i) => {
        ...seed,
        'id':'44444444-4444-4444-4444-'+(i+1).toString().padLeft(12,'0'),
        'measuredAt':end.subtract(Duration(seconds:i+1)).toIso8601String(),
        'receivedAt':end.subtract(Duration(seconds:i+1)).toIso8601String(),
        'value':i==0 ? 0 : -i,
      };
      requests++;
      if(q['page']=='1'){
        cutoff=q['to']!.replaceFirst('Z','0Z');
        return ok({...data,'asOf':cutoff,'hasMore':true,
          'items':[for(var i=0;i<250;i++)item(i)]});
      }
      expect(q['page'],'2');
      expect(q['asOf'],cutoff);
      return ok({...data,'asOf':cutoff,'page':2,'items':[item(250)]});
    })));
    addTearDown(svc.dispose);
    await svc.refresh();
    svc.selectHistorySensor(sensor);
    await svc.refreshTrend();
    expect(requests,2);
    final table=svc.historyTable!;
    expect(table.rows.length,251);
    expect(table.asOf,cutoff);
    expect(svc.chartSeries.length,251);
    expect(table.rows.last.value,-250);
    final csv=svc.exportScopedCsv(svc.historyRevision)!;
    expect(csv.trimRight().split('\r\n').length,252);
    expect(csv,contains(',-250,"Realtime"'));
    svc.stopLiveUpdates();
    expect(svc.historyTable,isNull);
    expect(svc.exportScopedCsv(svc.historyRevision),isNull);
  });

  test('denial on second page never exposes partial table or CSV',() async {
    final svc=WaterQualityService(session:session,api:CloudApiClient(client:MockClient((r)async{
      if(r.url.path=='/api/iot/live')return ok([live()]);
      final q=r.url.queryParameters;
      if(q['page']=='2')return http.Response('denied',403);
      final data=page(q);
      final seed=(data['items'] as List).single as Map<String,dynamic>;
      return ok({...data,'hasMore':true,'items':[
        for(var i=0;i<250;i++) {...seed,
          'id':'44444444-4444-4444-4444-'+(i+1).toString().padLeft(12,'0')},
      ]});
    })));
    addTearDown(svc.dispose);
    await svc.refresh();
    svc.selectHistorySensor(sensor);
    await svc.refreshTrend();
    expect(svc.chartSeries,isEmpty);
    expect(svc.historyTable,isNull);
    expect(svc.exportScopedCsv(svc.historyRevision),isNull);
    expect(svc.historyError,isNotNull);
  });

}
