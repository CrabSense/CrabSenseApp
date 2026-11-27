import 'package:crabsensemobile/features/home/data/repositories/home_repository_impl.dart';
import 'package:crabsensemobile/features/home/presentation/widgets/water_quality_overview.dart';
import 'package:crabsensemobile/features/water_quality/presentation/widgets/live_water_metrics.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String,dynamic> row(DateTime now,{String id='sensor-1',String area='area-a',
    String type='Salinity',String unit='ppt',Object? value=0}) => {
  'sensorId':id,'sensorCode':id,'farmingAreaId':area,'farmingRowId':'row-a',
  'sensorType':type,'unit':unit,'latestValue':value,'isActive':true,
  'dataQuality':'Realtime','status':'Online',
  'latestMeasuredAt':now.subtract(const Duration(seconds: 2)).toIso8601String(),
  'lastReceivedAt':now.subtract(const Duration(seconds: 1)).toIso8601String(),
};

void main() {
  test('home shares exact live decoder, keeps zero and separates TDS', () {
    final now=DateTime.now().toUtc();
    final metrics=decodeHomeWaterMetrics([
      row(now),row(now,id:'sensor-2',type:'TDS',unit:'ppm',value:1200),
      row(now,id:'bad-unit',unit:'ppm'),row(now,id:'chemical',type:'NO2',unit:'mg/L'),
      row(now,id:'wrong-area',area:'area-b'),row(now,id:'missing',value:null),
      {...row(now,id:'unqualified'),'lastReceivedAt':null},
    ],areaId:'area-a',revision:7);
    expect(metrics.map((m)=>m.currentValue),[0,1200]);
    expect(metrics.map((m)=>m.unit),['ppt','ppm']);
    expect(metrics.every((m)=>m.sessionRevision==7),isTrue);
    final readings=visibleHomeWaterReadings(metrics,areaId:'area-a',
      revision:7,online:true,now:now);
    expect(readings,hasLength(2));
    expect(liveMetricAssessment(readings.first,now),'Chưa có ngưỡng cấu hình');
  });

  test('home rejects duplicate IDs, old session, wrong area and offline', () {
    final now=DateTime.now().toUtc();
    expect(decodeHomeWaterMetrics([row(now),row(now)],areaId:'area-a',revision:7),isEmpty);
    final metrics=decodeHomeWaterMetrics([row(now)],areaId:'area-a',revision:7);
    expect(visibleHomeWaterReadings(metrics,areaId:'area-b',revision:7,online:true,now:now),isEmpty);
    expect(visibleHomeWaterReadings(metrics,areaId:'area-a',revision:8,online:true,now:now),isEmpty);
    expect(visibleHomeWaterReadings(metrics,areaId:'area-a',revision:7,online:false,now:now),isEmpty);
    final old=visibleHomeWaterReadings(metrics,areaId:'area-a',revision:7,
      online:true,now:now.add(const Duration(minutes:6))).single;
    expect(liveMetricAssessment(old,now.add(const Duration(minutes:6))),'Dữ liệu cũ');
  });
}
