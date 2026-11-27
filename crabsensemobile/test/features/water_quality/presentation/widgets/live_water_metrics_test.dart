import 'package:crabsensemobile/features/water_quality/data/datasources/water_quality_remote_data_source.dart';
import 'package:crabsensemobile/features/water_quality/domain/entities/water_quality.dart';
import 'package:crabsensemobile/features/water_quality/presentation/widgets/live_water_metrics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final now = DateTime.now().toUtc();
Map<String,dynamic> row({String sensor='s1', String type='Salinity',
    String unit='ppt', Object? value=0, String area='area', String location='row',
    String status='Online', DateTime? at}) {
  final time = at ?? now.subtract(const Duration(seconds: 20));
  return {
    'sensorId':sensor,'sensorCode':sensor,'sensorType':type,'unit':unit,
    'farmingAreaId':area,'farmingRowId':location,'latestValue':value,
    'latestMeasuredAt':time.toIso8601String(),
    'lastReceivedAt':time.add(const Duration(seconds: 1)).toIso8601String(),
    'isActive':true,'dataQuality':'Realtime','status':status,
  };
}
WaterQuality decode(Map<String,dynamic> data) =>
    decodeLiveWaterReading(data,farmId:'area')!.toEntity();

void main() {
  test('zero and TDS keep separate kinds and exact units through entity conversion', () {
    final sal = decode(row());
    final tds = decode(row(sensor:'s2',type:'TDS',unit:'ppm',value:1200));
    expect(sal.liveMetric!.value,0);
    expect(sal.liveMetric!.kind,LiveWaterKind.salinity);
    expect(tds.liveMetric!.kind,LiveWaterKind.tds);
    expect(tds.liveMetric!.unit,'ppm');
    expect(tds.salinity,isNull);
    expect(decodeLiveWaterReading(row(type:'Salinity',unit:'ppm'),farmId:'area'),isNull);
    expect(decodeLiveWaterReading(row(type:'NO2',unit:'mg/L'),farmId:'area'),isNull);
  });

  test('missing and unqualified receipt never become displayed readings', () {
    expect(decodeLiveWaterReading(row(value:null),farmId:'area'),isNull);
    for(final changed in [
      {'lastReceivedAt':null},
      {'lastReceivedAt':now.subtract(const Duration(days:1)).toIso8601String()},
      {'latestValue':'0'},
    ]) {
      final r=decode({...row(),...changed});
      expect(r.liveMetric,isNull);
      expect(scopedLiveMetrics('area',null,[r],now),isEmpty);
    }
  });

  test('thresholds only from configuration, stale and offline not safe', () {
    final noLimit=decode(row());
    expect(liveMetricAssessment(noLimit,now),'Chưa có ngưỡng cấu hình');
    final outside=decode({...row(),'minThreshold':10,'maxThreshold':20});
    expect(liveMetricAssessment(outside,now),'Cảnh báo từ cấu hình');
    final invalid=decode({...row(),'minThreshold':20,'maxThreshold':10});
    expect(invalid.liveMetric!.hasConfiguredThreshold,isFalse);
    final stale=decode(row(at:now.subtract(const Duration(minutes:6))));
    expect(liveMetricAssessment(stale,now),'Dữ liệu cũ');
    final offline=decode(row(status:'Offline'));
    expect(liveMetricAssessment(offline,now),'Chưa xác minh hiện trạng');
    final inside=decode({...row(value:12),'minThreshold':10,'maxThreshold':20});
    expect(liveMetricAssessment(inside,now),'Trong giới hạn đã cấu hình');
  });

  test('explicit scope and separate sensors, reject duplicate identities', () {
    final a=decode(row());
    final b=decode(row(sensor:'s2',location:'other-row'));
    expect(scopedLiveMetrics('default',null,[a,b],now),isEmpty);
    expect(scopedLiveMetrics('area','row',[a,b],now),[a]);
    expect(scopedLiveMetrics('area',null,[a,b],now),hasLength(2));
    expect(scopedLiveMetrics('area',null,[a,a,b],now),[b]);
  });

  testWidgets('shows per sensor timestamps and hides values when offline', (tester) async {
    final readings=[decode(row()),decode(row(sensor:'s2',type:'TDS',unit:'ppm',value:1200))];
    Widget view(bool online)=>MaterialApp(home:Scaffold(body:SingleChildScrollView(
      child:LiveWaterMetrics(areaId:'area',rowId:'row',readings:readings,online:online,now:now),
    )));
    await tester.pumpWidget(view(true));
    expect(find.byKey(const ValueKey('live-sensor-s1')),findsOneWidget);
    expect(find.text('0 ppt'),findsOneWidget);
    expect(find.text('1200.0 ppm'),findsOneWidget);
    expect(find.textContaining('Đo:'),findsNWidgets(2));
    expect(find.textContaining('Nhận:'),findsNWidgets(2));
    await tester.pumpWidget(view(false));
    expect(find.byKey(const ValueKey('live-sensor-s1')),findsNothing);
    expect(find.text('0 ppt'),findsNothing);
  });
}
