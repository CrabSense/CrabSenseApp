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

const assessmentId='44444444-4444-4444-4444-444444444444';
const connection='55555555-5555-5555-5555-555555555555';
Map<String,dynamic> receiptFixture()=> {
  'stationId':station,'bootId':boot,'batchId':batch,
  'inventoryComplete':true,'receiptBasis':'persisted_backend_evidence',
  'timelineStatus':'firmware_complete_reported','total':3,
  'timelineCount':2,'mediaCount':1,'nh3Count':0,
  'items':[
    {'receiptId':'66666666-6666-6666-6666-666666666666',
      'eventId':'77777777-7777-7777-7777-777777777777',
      'connectionId':connection,'serverPayloadSha256':List.filled(64,'a').join(),
      'kind':'batch','evidenceKind':'batch_start'},
    {'receiptId':sessionReceipt,'eventId':'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
      'connectionId':connection,'serverPayloadSha256':List.filled(64,'d').join(),
      'kind':'batch','evidenceKind':'session','analyte':'NO2','sessionId':'s'},
    {'receiptId':'88888888-8888-8888-8888-888888888888',
      'eventId':'99999999-9999-9999-9999-999999999999',
      'connectionId':connection,'serverPayloadSha256':List.filled(64,'b').join(),
      'kind':'media','evidenceKind':'jpeg','analyte':'NO2','sessionId':'s','captureId':1,'privateMediaMetadataPresent':true,'mediaId':'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
      'sha256':List.filled(64,'c').join()},
  ],
};


const sessionReceipt='cccccccc-cccc-cccc-cccc-cccccccccccc';
const imageReceipt='88888888-8888-8888-8888-888888888888';
const mediaId='aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
const requestId='dddddddd-dddd-dddd-dddd-dddddddddddd';
const calId='eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee';
Map<String,dynamic> estimateFixture()=>{'id':assessmentId,'requestId':requestId,
  'sessionEvidenceId':sessionReceipt,'imageEvidenceId':imageReceipt,'mediaId':mediaId,
  'calibrationId':calId,'status':'estimate_review_required','estimatedValue':0,'unit':'mg/L NO2','holdoutError':0.1};
Map<String,dynamic> evidenceFixture(){
  final rows=benchRows(receiptFixture()['items']);
  return {'assessmentId':assessmentId,'requestId':requestId,'status':'estimate_review_required',
    'candidateValue':0,'unit':'mg/L NO2','holdoutError':0.1,'chemicalResultValidated':false,'productionPublished':false,
    'session':rows[1],'image':rows[2],'calibration':{'id':calId},'provenanceStatus':'snapshot_verified',
    'provenanceSha256':List.filled(64,'f').join(),'provenance':{
      'contract':'water-bench-ai-evidence-v1','assessmentId':assessmentId,'requestId':requestId,
      'requestSha256':List.filled(64,'e').join(),'stationId':station,'bootId':boot,'batchId':batch,
      'analyte':'NO2','connectionId':connection,'sessionId':'s','captureId':1,
      'sessionReceiptId':sessionReceipt,'imageReceiptId':imageReceipt,'mediaId':mediaId,'calibrationId':calId,
      'sessionPayloadSha256':rows[1]['serverPayloadSha256'],'imagePayloadSha256':rows[2]['serverPayloadSha256'],
      'imageSha256':rows[2]['sha256']}};
}

void main(){
 test('server-scoped areas, staff only, strict identity and missing != zero',()async{
  final calls=<String>[];
  final svc=StaffWaterBenchService.testing((p,q)async{
    calls.add(p);
    if(p=='/farming-areas')return ok({'items':[{'id':area,'name':'A'}],'totalCount':1});
    expect(p,startsWith('/areas/$area/water-bench'));
    if(p.endsWith('/station'))return ok(null);
    if(p.endsWith('/batches'))return ok([{'stationId':station,'bootId':boot,'firmwareBatchId':batch}]);
    if(p.endsWith('/$batch'))return ok({'timeline':{'stationId':station,'bootId':boot,'batchId':batch,'connectionId':connection,'status':'firmware_complete_reported','channels':[]},'observationStale':true});
    if(p.endsWith('/results'))return ok({'channels':[{'analyte':'NO2','sessionId':'s','captureId':1,'assessment':estimateFixture()}]});
    if(p.endsWith('/NO2/evidence'))return ok(evidenceFixture());
    if(p.endsWith('/NO2/review'))return ok({'assessmentId':assessmentId,'status':'pending_review'});
    if(p.endsWith('/receipts'))return ok(receiptFixture());
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
        'stationId':station,'bootId':boot,'batchId':batch,'connectionId':connection,'status':'firmware_complete_reported',
        'channels':[{'analyte':'NO2','status':'drained_reported'}]}});
      if(path.endsWith('/results'))return ok({'channels':[
        {'analyte':'NO2','status':'estimate_review_required','sessionId':'s','captureId':1,'assessment':estimateFixture()},
        {'analyte':'NH3','status':'needs_retest'}
      ]});
      if(path.endsWith('/NO2/evidence'))return ok(evidenceFixture());
      if(path.endsWith('/NO2/review'))return ok({
        'assessmentId':assessmentId,'status':'published','publicationScope':'water_bench_reviewed_record',
        'productionSensorPublished':false,'publication':{
          'assessmentId':assessmentId,'value':0.2,'unit':'mg/L NO2','source':'operator_attested_independent_reference',
          'productionSensorPublished':false}
      });
      if(path.endsWith('/receipts'))return ok(receiptFixture());
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

  test('snapshot rejects wrong batch, duplicate receipts and channel identities', () {
    final selected=BenchBatch.fromJson({'stationId':station,'bootId':boot,'firmwareBatchId':batch});
    final timeline=<String,dynamic>{'stationId':station,'bootId':boot,'batchId':batch,
      'connectionId':connection,'status':'firmware_complete_reported','channels':[]};
    final receipts=receiptFixture();
    verifyBenchSnapshot(selected,timeline,receipts,[{'channels':[]}]);
    expect(()=>verifyBenchSnapshot(selected,timeline,{...receipts,'batchId':boot},[]),throwsFormatException);
    expect(()=>verifyBenchSnapshot(selected,timeline,{...receipts,'total':9},[]),throwsFormatException);
    final items=receipts['items'] as List;
    expect(()=>verifyBenchSnapshot(selected,timeline,{...receipts,'items':[items.first,items.first]},[]),throwsFormatException);
    expect(()=>verifyBenchSnapshot(selected,timeline,receipts,[{'channels':[{'analyte':'NO2'},{'analyte':'NO2'}]}]),throwsFormatException);
  });
  test('published reference must match the estimate assessment and measurand', () {
    BenchChannel channel(String id,String unit)=>BenchChannel('NH3',null,{'assessment':{
      'id':'assessment','status':'estimate_review_required','estimatedValue':0,'unit':'mg/L TAN-N'}},
      null,null,{'assessmentId':'assessment','status':'published','publicationScope':'water_bench_reviewed_record',
        'publication':{'assessmentId':id,'unit':unit,'value':0,'source':'operator_attested_independent_reference',
          'productionSensorPublished':false}},false);
    expect(channel('assessment','mg/L TAN-N').publishedReference,0);
    expect(channel('other','mg/L TAN-N').publishedReference,isNull);
    expect(channel('assessment','mg/L NH3').publishedReference,isNull);
  });

  test('estimate is bound to receipt, provenance and exact numeric value',(){
    final selected=BenchBatch.fromJson({'stationId':station,'bootId':boot,'firmwareBatchId':batch});
    final result={'sessionId':'s','captureId':1,'assessment':estimateFixture()};
    final evidence=evidenceFixture(), receipts=receiptFixture();
    verifyBenchEstimate(selected,'NO2',result,receipts,evidence);
    for(final patch in [{'provenanceStatus':'legacy_linkage_only'},{'candidateValue':1},
      {'provenance':{...benchMap(evidence['provenance']),'imageSha256':'wrong'}}]){
      expect(()=>verifyBenchEstimate(selected,'NO2',result,receipts,{...evidence,...patch}),throwsFormatException);
    }
    expect(()=>requireBenchCurrent(()=>false),throwsStateError);
  });

  test('cancelled staff detail stops before follow-up requests',() async {
    var active=true;
    final service=StaffWaterBenchService.testing((path,query)async {
      if(path=='/farming-areas')return ok([{'id':area}]);
      expect(path.endsWith('/evidence')||path.endsWith('/review'),isFalse);
      if(path.endsWith('/receipts'))active=false;
      return ok({});
    });
    await service.areas(user);
    await expectLater(service.detail(user,area,BenchBatch.fromJson({'stationId':station,'bootId':boot,'firmwareBatchId':batch}),current:()=>active),throwsStateError);
  });
}
