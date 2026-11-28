import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import '../lib/models/farm_dashboard_overview.dart';
import '../lib/services/cloud_api_client.dart';

void main() {
  setUp(() => dotenv.testLoad(fileInput: 'CLOUD_API_URL=http://localhost:5080'));
  test('canonical overview does not query metrics or infer missing business counts', () async {
    final requests = <Uri>[];
    final api = CloudApiClient(client: MockClient((request) async {
      requests.add(request.url);
      expect(request.url.path, '/api/dashboard/overview');
      expect(request.url.queryParameters['farmingAreaId'], 'area-a');
      return http.Response(jsonEncode({'success':true,'data':{
        'totalBoxes':0, 'totalCrabs':null, 'activeBoxes':null,
        'openAlerts':0, 'iotOnlinePercentage':100,
        'healthScore':99, 'waterQualityScore':95,
      }}),200);
    }));
    final data = await api.fetchFarmDashboardOverview('token','area-a');
    expect(requests, hasLength(1));
    expect(data.healthScore, isNull);
    expect(data.alertCount, 0);
    expect(data.devicesOnline, '—');
    expect(data.summaryKpis.map((k)=>k.value), ['0','—','—','0']);
    expect(data.environmentParams, isEmpty);
    expect(data.statusSegments, isEmpty);
  });
  test('strict counts distinguish unknown from actual zero', () {
    for(final raw in [null, '0', -1, false, 1.5]) {
      expect(dashboardCount(raw), isNull);
    }
    expect(dashboardCount(0), 0);
    final data = FarmDashboardOverview.fromCrabSense(
      totalBoxes:null,totalCrabs:null,activeBoxes:null,openAlerts:null,
      iotOnlinePercentage:null);
    expect(data.alertCount, isNull);
    expect(data.summaryKpis.every((k)=>k.value=='—'),isTrue);
  });
}
