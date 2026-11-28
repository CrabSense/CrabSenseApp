import 'package:flutter_test/flutter_test.dart';
import '../lib/models/water_quality.dart';
import '../lib/services/dashboard_env_trend_service.dart';
import '../lib/widgets/dashboard/owner_dashboard_sections.dart';

void main(){
  test('legacy combined trend never invents points or accepts unscoped history',(){
    final service=DashboardEnvTrendService();addTearDown(service.dispose);
    final raw=WaterTrendPoint(xMinutes:0,label:'now',timestamp:DateTime.now(),
      temperature:40,ph:4,tds:0,flow:0);
    service.startLiveFromAnchor(ph:4,temp:40);
    expect(service.points,isEmpty);
    service.startLiveFromHistory([raw]);
    service.seedFromApi([raw],enableLive:true);
    service.appendLiveSample(raw);
    expect(service.points,isEmpty);expect(service.rawBuffer,isEmpty);
    expect(service.isLiveApi,isFalse);
  });
  test('dashboard cannot call missing or stale readings safe',(){
    final now=DateTime.now().toUtc();
    WaterSensorReading reading({DateTime? at, double? min, bool offline=false,
      WaterSensorStatus status=WaterSensorStatus.normal})=>WaterSensorReading(
      type:WaterSensorType.salinity,value:0,unit:'ppt',status:status,
      threshold:SensorThreshold(goodRangeLabel:'fixture',min:min),
      measuredAt:at,receivedAt:at,offline:offline);
    expect(dashboardWaterAssessment(reading(),now),'Chưa xác minh dữ liệu');
    expect(dashboardWaterAssessment(reading(at:now),now),'Chưa có ngưỡng cấu hình');
    expect(dashboardWaterAssessment(reading(at:now,offline:true),now),'Chưa xác minh hiện trạng');
    expect(dashboardWaterAssessment(reading(at:now.subtract(const Duration(minutes:6)),min:10),now),'Dữ liệu cũ / chưa xác minh');
    expect(dashboardWaterAssessment(reading(at:now,min:10,status:WaterSensorStatus.exceeded),now),'Cảnh báo từ cấu hình');
  });
}
