import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import '../lib/models/area_environment_metric.dart';
import '../lib/models/auth_models.dart';
import '../lib/services/area_environment_service.dart';
import '../lib/services/cloud_api_client.dart';

const a=FarmSummary(id:'a',code:'A',name:'A');
const b=FarmSummary(id:'b',code:'B',name:'B');
const session=AuthSession(token:'fixture',user:AuthUser(id:'u',email:'',
 displayName:'Manager',role:UserRoles.farmManager),farms:[a,b],selectedFarm:a,isOrgAdmin:false);

Map<String,dynamic> reading(String id,{String area='b',String? row,
 String type='Salinity',String unit='ppt',num value=0}){
 final now=DateTime.now().toUtc();
 return {'sensorId':id,'sensorCode':id,'farmingAreaId':area,'farmingRowId':row,
  'sensorType':type,'unit':unit,'latestValue':value,'isActive':true,
  'dataQuality':'Realtime','status':'Online',
  'latestMeasuredAt':now.subtract(const Duration(seconds:2)).toIso8601String(),
  'lastReceivedAt':now.subtract(const Duration(seconds:1)).toIso8601String()};
}
class Probe extends CloudApiClient {
 final calls=<String?>[];
 final pending=<Completer<List<Map<String,dynamic>>>>[];
 @override
 Future<List<Map<String,dynamic>>> fetchIotLive(String token,{String? farmingAreaId}){
   calls.add(farmingAreaId);final c=Completer<List<Map<String,dynamic>>>();pending.add(c);return c.future;
 }
 @override
 Future<List<Map<String,dynamic>>> fetchSensorHistory(String token,{required String sensorId,
 DateTime? from,DateTime? to,int pageSize=2000}) async => throw StateError('legacy history must not run');
}

void main(){
 test('same area RAS references for every box, keep inlet/outlet independent',(){
  final input=[reading('inlet',row:'r1'),reading('outlet',row:'r2',value:18),
    reading('wrong',area:'a'),reading('tds',type:'TDS',unit:'mg/L',value:123),
    reading('ph',type:'pH',unit:'pH',value:0.8),reading('chemical',type:'NO2',unit:'mg/L')];
  final area=AreaSensorLatestData.fromIotLive(areaId:'b',live:input);
  final box1=AreaSensorLatestData.fromIotLive(areaId:'b',live:input,boxId:'box1');
  final box2=AreaSensorLatestData.fromIotLive(areaId:'b',live:input,boxId:'box2');
  expect(area.metrics.map((m)=>m.sensorId),unorderedEquals(['inlet','outlet','tds','ph']));
  expect(box1.metrics.map((m)=>m.sensorId),area.metrics.map((m)=>m.sensorId));
  expect(box2.metrics.map((m)=>m.value),area.metrics.map((m)=>m.value));
  expect(box1.isBoxInherited,isTrue);
  expect(box1.metrics.singleWhere((m)=>m.sensorId=='inlet').value,0);
  expect(box1.metrics.singleWhere((m)=>m.sensorId=='ph').value,0.8);
  expect(box1.metrics.singleWhere((m)=>m.sensorId=='tds').unit,'mg/L');
  expect(box1.metrics.first.minThreshold,isNull);
 });
 test('explicit area, no selected farm fallback; silent denial clears and legacy history disabled',()async{
  final api=Probe();final svc=AreaEnvironmentService(session:session,api:api);addTearDown(svc.dispose);
  await svc.loadByBox('box');expect(api.calls,isEmpty);
  final load=svc.loadByBox('box',areaId:'b');
  expect(api.calls,['b']);
  api.pending[0].complete([reading('inlet'),reading('other',area:'a')]);
  await load;expect(svc.dataForBox('b','box')!.metrics.single.sensorId,'inlet');
  expect(svc.dataForBox('a','box'),isNull);
  expect(svc.dataForBox('b','another'),isNull);
  final denied=svc.loadByBox('box',areaId:'b',silent:true);
  api.pending[1].completeError(CloudApiException('denied',statusCode:403));
  await denied;expect(svc.metrics,isEmpty);expect(svc.data,isNull);
  expect(await svc.fetchSensorHistory('inlet',from:DateTime.now(),to:DateTime.now()),isEmpty);
 });
 test('late result cannot restore after box or session change',()async{
  final api=Probe();final svc=AreaEnvironmentService(session:session,api:api);addTearDown(svc.dispose);
  final old=svc.loadByBox('old',areaId:'b');
  final next=svc.loadByBox('new',areaId:'a');
  api.pending[1].complete([reading('new-sensor',area:'a')]);await next;
  api.pending[0].complete([reading('old-sensor')]);await old;
  expect(svc.dataForBox('a','new')!.metrics.single.sensorId,'new-sensor');
  final pending=svc.loadByBox('new',areaId:'a');
  svc.updateSession(session.copyWith(token:'other'));
  api.pending[2].complete([reading('new-sensor',area:'a')]);await pending;
  expect(svc.data,isNull);
 });
}
