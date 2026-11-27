import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import '../lib/models/auth_models.dart';
import '../lib/models/water_quality.dart';
import '../lib/services/cloud_api_client.dart';
import '../lib/services/qualified_live_water.dart';
import '../lib/services/water_quality_service.dart';

const a=FarmSummary(id:'area-a',code:'A',name:'A');
const b=FarmSummary(id:'area-b',code:'B',name:'B');
const session=AuthSession(token:'fixture',user:AuthUser(id:'manager',email:'',
  displayName:'Manager',role:UserRoles.farmManager),farms:[a,b],selectedFarm:a,isOrgAdmin:false);
Map<String,dynamic> row(DateTime now,{String id='s1',String area='area-a',
    String type='Salinity',String unit='ppt',Object? value=0}) => {
  'sensorId':id,'sensorCode':id,'farmingAreaId':area,'sensorType':type,
  'unit':unit,'latestValue':value,'isActive':true,'dataQuality':'Realtime',
  'status':'Online','latestMeasuredAt':now.subtract(const Duration(seconds:2)).toIso8601String(),
  'lastReceivedAt':now.subtract(const Duration(seconds:1)).toIso8601String(),
};

class FakeApi extends CloudApiClient {
  final calls=<String?>[];
  final pending=<Completer<List<Map<String,dynamic>>>>[];
  @override
  Future<List<Map<String,dynamic>>> fetchIotLive(String token,{String? farmingAreaId}) {
    calls.add(farmingAreaId);
    final c=Completer<List<Map<String,dynamic>>>();
    pending.add(c);
    return c.future;
  }
  @override
  Future<List<Map<String,dynamic>>> fetchSensorHistory(String token,{required String sensorId,
      DateTime? from,DateTime? to,int pageSize=2000}) async {
    fail('Legacy history must not be called');
  }
}

void main() {
  test('strict scope, separate TDS, true zero, no guessed thresholds or unknown sensor type', () {
    final now=DateTime.now().toUtc();
    final rows=decodeQualifiedDesktopLive([
      row(now),row(now,id:'tds',type:'TDS',unit:'ppm',value:1200),
      row(now,id:'wrong',area:'area-b'),row(now,id:'bad-unit',unit:'ppm'),
      row(now,id:'unknown',type:'unknown',unit:'°C'),
      row(now,id:'chem',type:'NO2',unit:'mg/L'),
      {...row(now,id:'missing'),'lastReceivedAt':null},
      row(now,id:'duplicate'),row(now,id:'duplicate'),
    ],areaId:a.id,now:now);
    expect(rows,hasLength(2));
    final sal=rows.singleWhere((r)=>r.type==WaterSensorType.salinity);
    expect(sal.value,0);
    expect(sal.threshold.min,isNull);
    expect(sal.status,WaterSensorStatus.monitoring);
    expect(rows.singleWhere((r)=>r.type==WaterSensorType.tds).unit,'ppm');
    expect(decodeQualifiedDesktopLive([row(now)],areaId:'',now:now),isEmpty);
  });

  test('configured single-sided limit, stale and offline remain distinct', () {
    final now=DateTime.now().toUtc();
    final readings=decodeQualifiedDesktopLive([
      {...row(now),'minThreshold':10},
      {...row(now,id:'old',value:12),'minThreshold':10,
        'latestMeasuredAt':now.subtract(const Duration(minutes:6)).toIso8601String()},
      {...row(now,id:'offline',value:12),'minThreshold':10,'status':'Offline'},
    ],areaId:a.id,now:now);
    expect(readings.singleWhere((r)=>r.sensorId=='s1').status,WaterSensorStatus.exceeded);
    expect(readings.singleWhere((r)=>r.sensorId=='old').status,WaterSensorStatus.monitoring);
    expect(readings.singleWhere((r)=>r.sensorId=='offline').offline,isTrue);
  });

  test('area switch rejects late response; silent denial clears readings; no legacy history', () async {
    final api=FakeApi();
    final svc=WaterQualityService(session:session,api:api);
    addTearDown(svc.dispose);
    final now=DateTime.now().toUtc();
    final old=svc.refresh();
    svc.setAreaId(b.id);
    expect(api.calls,[a.id,b.id]);
    api.pending[1].complete([row(now,area:b.id,id:'new')]);
    await Future<void>.delayed(Duration.zero);
    api.pending[0].complete([row(now)]);
    await old;
    expect(svc.allReadings.single.sensorId,'new');
    final denied=svc.refresh(full:false);
    api.pending[2].completeError(CloudApiException('denied',statusCode:403));
    await denied;
    expect(svc.allReadings,isEmpty);
    expect(svc.cloudLive,isFalse);
    await svc.refreshTrend();
    await svc.refreshRecent();
    expect(svc.chartSeries,isEmpty);
    expect(svc.recentRows,isEmpty);
  });
}
