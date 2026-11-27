import 'package:flutter/material.dart';
import 'package:crabsensemobile/features/water_quality/presentation/widgets/water_history_unavailable.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crabsensemobile/features/water_bench/presentation/water_bench_screen.dart';
import 'package:crabsensemobile/features/authentication/domain/entities/user.dart';
import 'package:crabsensemobile/features/water_bench/data/water_bench_model.dart';
import 'package:crabsensemobile/features/water_bench/data/water_bench_service.dart';
const area='11111111-1111-1111-1111-111111111111',other='22222222-2222-2222-2222-222222222222';
const station='33333333-3333-3333-3333-333333333333',boot='0123456789abcdef',batch='abcdef0123456789';
final user=User(id:'staff',email:'',name:'Staff',role:UserRole.farmStaff,assignedFarmIds:[],createdAt:DateTime.utc(2026));
Map<String,dynamic> ok(Object? d)=>{'success':true,'data':d};
void main(){
 test('server-scoped areas, staff only, strict identity and missing != zero',()async{
  final calls=<String>[];
  final svc=StaffWaterBenchService.testing((p,q)async{
    calls.add(p);
    if(p=='/farming-areas')return ok({'items':[{'id':area,'name':'A'}],'totalCount':1});
    expect(p,startsWith('/areas/$area/water-bench'));
    if(p.endsWith('/station'))return ok(null);
    if(p.endsWith('/batches'))return ok([{'stationId':station,'bootId':boot,'firmwareBatchId':batch}]);
    if(p.endsWith('/$batch'))return ok({'timeline':{'stationId':station,'bootId':boot,'batchId':batch,'channels':[]},'observationStale':true});
    if(p.endsWith('/results'))return ok({'channels':[{'analyte':'NO2','assessment':{'id':'a','status':'estimate_review_required','estimatedValue':0,'unit':'mg/L NO2'}}]});
    if(p.endsWith('/NO2/review'))return ok({'assessmentId':'a','status':'pending_review'});
    return ok({'channels':[]});
  });
  await expectLater(svc.overview(user,area),throwsStateError);
  final areas=await svc.areas(user);expect(areas.single['id'],area);
  await expectLater(svc.overview(user,other),throwsStateError);
  final overview=await svc.overview(user,area);
  final detail=await svc.detail(user,area,overview.batches.single);
  expect(detail.stale,isTrue);expect(detail.channels.first.estimate,0);expect(detail.channels.last.estimate,isNull);
  expect(calls.any((p)=>p.contains('/review')),isTrue);
  for(final role in [UserRole.farmManager,UserRole.farmAdministrator,UserRole.systemAdministrator,UserRole.unknown]){
    await expectLater(svc.areas(user.copyWith(role:role)),throwsStateError);
  }
  expect(()=>BenchBatch.fromJson({'stationId':station,'bootId':'../x','firmwareBatchId':batch}),throwsFormatException);
 });
 test('NH3 measurand and publication scope never inferred',(){
  final c=BenchChannel('NH3',null,{'assessment':{'status':'estimate_review_required','estimatedValue':1,'unit':'mg/L TAN-N'}},null,null,{'status':'published','publication':{'value':2,'unit':'mg/L NH3'}},false);
  expect(c.unit,'mg/L TAN-N');expect(c.publishedReference,isNull);
 });

  testWidgets('unassigned deep link cannot fetch batch or station', (tester) async {
    final calls=<String>[];
    final svc=StaffWaterBenchService.testing((path,query) async {
      calls.add(path);
      expect(path,'/farming-areas');
      return ok({'items':[{'id':area,'name':'Area A'}],'totalCount':1});
    });
    await tester.pumpWidget(MaterialApp(home:WaterBenchScreen(
      user:user,api:null,service:svc,initialAreaId:other,
    )));
    await tester.pumpAndSettle();
    expect(find.text('Chọn khu hợp lệ để xem dữ liệu.'),findsOneWidget);
    expect(calls,['/farming-areas']);
    expect(find.text('Trạm và lịch'),findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('staff sees stale observations, retest and distinct publication without admin controls', (tester) async {
    final svc=StaffWaterBenchService.testing((path,query) async {
      if(path=='/farming-areas'){
        return ok({'items':[{'id':area,'name':'Area A'}],'totalCount':1});
      }
      expect(path,startsWith('/areas/$area/water-bench'));
      if(path.endsWith('/station'))return ok({'enabled':true,'times':['08:00'],'timezone':'UTC+07:00'});
      if(path.endsWith('/batches'))return ok([{'stationId':station,'bootId':boot,'firmwareBatchId':batch}]);
      if(path.endsWith('/$batch'))return ok({'observationStale':true,'timeline':{
        'stationId':station,'bootId':boot,'batchId':batch,'status':'firmware_complete_reported',
        'channels':[{'analyte':'NO2','status':'drained_reported'}]}});
      if(path.endsWith('/results'))return ok({'channels':[
        {'analyte':'NO2','status':'estimate_review_required','assessment':{
          'id':'a','status':'estimate_review_required','estimatedValue':0,'unit':'mg/L NO2'}},
        {'analyte':'NH3','status':'needs_retest'}
      ]});
      if(path.endsWith('/NO2/review'))return ok({
        'assessmentId':'a','status':'published','publicationScope':'water_bench_reviewed_record',
        'productionSensorPublished':false,'publication':{
          'value':0.2,'unit':'mg/L NO2','source':'operator_attested_independent_reference',
          'productionSensorPublished':false}
      });
      if(path.endsWith('/receipts'))return ok({'total':4,'mediaCount':1});
      return ok({'channels':[]});
    });
    await tester.binding.setSurfaceSize(const Size(420,2200));
    addTearDown(()=>tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(home:WaterBenchScreen(
      user:user,api:null,service:svc,initialAreaId:area,
    )));
    await tester.pumpAndSettle();
    expect(find.text('Phân tích nước'),findsOneWidget);
    expect(find.textContaining('Quan sát đã cũ hoặc không rõ.'),findsOneWidget);
    expect(find.text('Ước tính: 0 mg/L NO2'),findsOneWidget);
    expect(find.text('Đối chứng đã công bố: 0.2 mg/L NO2'),findsOneWidget);
    expect(find.text('Ước tính: —'),findsNWidgets(2));
    expect(find.textContaining('Cần đo lại: báo Farm Manager/Farm Admin'),findsOneWidget);
    for(final label in ['Hiệu chuẩn','Retry AI','Xét duyệt','Công bố','Bắt đầu','Dừng']){
      expect(find.widgetWithText(ElevatedButton,label),findsNothing);
      expect(find.widgetWithText(OutlinedButton,label),findsNothing);
      expect(find.widgetWithText(TextButton,label),findsNothing);
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });

  test('revoked area does not reuse previous area grant', () async {
    var assigned=true;
    final svc=StaffWaterBenchService.testing((path,query) async {
      expect(path,'/farming-areas');
      return ok({'items':assigned?[{'id':area,'name':'Area A'}]:[],'totalCount':assigned?1:0});
    });
    await svc.areas(user);
    assigned=false;
    expect(await svc.areas(user),isEmpty);
    await expectLater(svc.overview(user,area),throwsStateError);
  });

  testWidgets('legacy history explicitly unavailable rather than synthetic values', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: WaterHistoryUnavailable())));
    expect(find.byKey(const Key('water-history-unavailable')),findsOneWidget);
    expect(find.text('Chưa đủ dữ liệu lịch sử đã xác minh để vẽ biểu đồ.'),findsOneWidget);
    expect(find.textContaining('Không sử dụng dữ liệu giả'),findsOneWidget);
  });
}
