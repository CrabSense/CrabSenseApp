import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import '../lib/models/auth_models.dart';
import '../lib/models/water_bench_monitor.dart';
import '../lib/screens/environment/water_bench_monitor_page.dart';
import '../lib/services/cloud_api_client.dart';
import '../lib/services/water_bench_monitor_service.dart';

const a = FarmSummary(id:'11111111-1111-1111-1111-111111111111',code:'A',name:'Area A');
const b = FarmSummary(id:'22222222-2222-2222-2222-222222222222',code:'B',name:'Area B');
const station = '33333333-3333-3333-3333-333333333333';
const boot = '0123456789abcdef', batchId = 'abcdef0123456789';
const assessmentId = '44444444-4444-4444-4444-444444444444';
const session = AuthSession(token:'test',user:AuthUser(id:'manager',email:'',displayName:'Manager',role:UserRoles.farmManager),
  farms:[a,b],selectedFarm:a,isOrgAdmin:false);
final batchJson = {'stationId':station,'bootId':boot,'firmwareBatchId':batchId,
  'createdAt':'2026-11-26T01:00:00Z','start':{'mode':'scheduled'}};
http.Response ok(Object? data) => http.Response(jsonEncode({'success':true,'data':data}),200,
  headers:{'content-type':'application/json'});
http.Response fixture(http.Request request) {
  expect(request.method,'GET');
  final path=request.url.path;
  expect(request.headers['authorization'],'Bearer test');
  if(path.endsWith('/station')) return ok({'configurationVersion':1,'times':['08:00'],'enabled':true});
  if(path.endsWith('/batches')) return ok([batchJson]);
  if(path.endsWith('/$batchId')) return ok({'observationStale':true,'timeline':{
    'stationId':station,'bootId':boot,'batchId':batchId,'connectionId':connection,'status':'firmware_complete_reported',
    'channels':[{'analyte':'NO2','status':'drained_reported'}]}});
  if(path.endsWith('/results')) return ok({'channels':[{'analyte':'NO2','status':'estimate_review_required',
    'sessionId':'s','captureId':1,'assessment':estimateFixture()}]});
  if(path.endsWith('/ai-readiness')) return ok({'channels':[]});
  if(path.endsWith('/retry-status')) return ok({'channels':[{'analyte':'NO2','status':'retry_available','attempts':1,'maxAttempts':3}]});
  if(path.endsWith('/receipts')) return ok(receiptFixture());
  if(path.endsWith('/NO2/evidence')) return ok(evidenceFixture());
  if(path.endsWith('/NO2/review')) return ok({'assessmentId':assessmentId,'status':'published',
    'publicationScope':'water_bench_reviewed_record','publication':{'source':'operator_attested_independent_reference',
      'assessmentId':assessmentId,'productionSensorPublished':false,'value':0.2,'unit':'mg/L NO2'}});
  fail('Unexpected endpoint $path');
}


const connection='55555555-5555-5555-5555-555555555555';
Map<String,dynamic> receiptFixture()=> {
  'stationId':station,'bootId':boot,'batchId':batchId,
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
      'requestSha256':List.filled(64,'e').join(),'stationId':station,'bootId':boot,'batchId':batchId,
      'analyte':'NO2','connectionId':connection,'sessionId':'s','captureId':1,
      'sessionReceiptId':sessionReceipt,'imageReceiptId':imageReceipt,'mediaId':mediaId,'calibrationId':calId,
      'sessionPayloadSha256':rows[1]['serverPayloadSha256'],'imagePayloadSha256':rows[2]['serverPayloadSha256'],
      'imageSha256':rows[2]['sha256']}};
}

void main() {
  setUp(() => dotenv.testLoad(fileInput:'CLOUD_API_URL=http://localhost:5080'));
  test('only scoped GET, exact identities and units; published reference distinct from estimate', () async {
    final svc=WaterBenchMonitorService(client:MockClient((r) async {
      expect(r.url.path,startsWith('/api/areas/${a.id}/water-bench'));
      return fixture(r);
    }));
    final overview=await svc.overview(session);
    final detail=await svc.detail(session,overview.batches.single);
    expect(detail.stale,isTrue);
    expect(detail.channels.first.estimate,0);
    expect(detail.channels.first.publishedReference,0.2);
    expect(detail.channels[1].estimate,isNull);
    expect(detail.channels[2].publishedReference,isNull);
    expect(() => BenchBatch.fromJson({...batchJson,'bootId':'../other'}),throwsFormatException);
    final invalid=BenchChannel('NH3',null,{'assessment':{'status':'estimate_review_required',
      'estimatedValue':1,'unit':'mg/L'}},null,null,null,false);
    expect(invalid.estimate,isNull);
  });
  test('other roles and unassigned areas rejected before HTTP', () async {
    final svc=WaterBenchMonitorService(client:MockClient((r) async {fail('Unexpected HTTP');}));
    for(final role in [UserRoles.farmAdministrator,UserRoles.farmStaff,UserRoles.systemAdministrator]){
      final other=session.copyWith(user:AuthUser(id:'x',email:'',displayName:'x',role:role));
      await expectLater(svc.overview(other),throwsA(isA<CloudApiException>()));
    }
    await expectLater(svc.overview(session.copyWith(farms:[b])),throwsA(isA<CloudApiException>()));
  });
  testWidgets('monitor is read-only, missing is not zero, stale and reference labels visible',(tester) async {
    final svc=WaterBenchMonitorService(client:MockClient((r) async=>fixture(r)));
    await tester.binding.setSurfaceSize(const Size(1440,1500));
    addTearDown(()=>tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(home:Scaffold(body:WaterBenchMonitorPage(session:session,service:svc))));
    await tester.pumpAndSettle();
    expect(find.text('Giám sát phân tích nước'),findsOneWidget);
    expect(find.textContaining('Quan sát đã cũ'),findsOneWidget);
    expect(find.text('Ước tính AI: 0 mg/L NO2'),findsOneWidget);
    expect(find.text('Đối chứng đã công bố: 0.2 mg/L NO2'),findsOneWidget);
    expect(find.text('Ước tính AI: —'),findsNWidgets(2));
    for(final label in ['Tạo hiệu chuẩn','Xét duyệt','Công bố','Retry AI','Bắt đầu','Dừng']){
      expect(find.widgetWithText(ElevatedButton,label),findsNothing);
      expect(find.widgetWithText(OutlinedButton,label),findsNothing);
    }
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('area change discards delayed old response',(tester) async {
    final delayed=Completer<http.Response>();
    final svc=WaterBenchMonitorService(client:MockClient((r) async {
      if(r.url.path.contains(a.id)&&r.url.path.endsWith('/station'))return delayed.future;
      if(r.url.path.contains(b.id)&&r.url.path.endsWith('/station'))return ok({'configurationVersion':99});
      return ok([]);
    }));
    Widget host(AuthSession s)=>MaterialApp(home:Scaffold(body:WaterBenchMonitorPage(session:s,service:svc)));
    await tester.pumpWidget(host(session));await tester.pump();
    await tester.pumpWidget(host(session.copyWith(selectedFarm:b)));await tester.pumpAndSettle();
    expect(find.text('Phiên bản cấu hình: 99'),findsOneWidget);
    delayed.complete(ok({'configurationVersion':1}));await tester.pumpAndSettle();
    expect(find.text('Phiên bản cấu hình: 1'),findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  test('snapshot rejects wrong batch, duplicate receipts and channel identities', () {
    final selected=BenchBatch.fromJson({'stationId':station,'bootId':boot,'firmwareBatchId':batchId});
    final timeline=<String,dynamic>{'stationId':station,'bootId':boot,'batchId':batchId,
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
    final selected=BenchBatch.fromJson({'stationId':station,'bootId':boot,'firmwareBatchId':batchId});
    final result={'sessionId':'s','captureId':1,'assessment':estimateFixture()};
    final evidence=evidenceFixture(), receipts=receiptFixture();
    verifyBenchEstimate(selected,'NO2',result,receipts,evidence);
    for(final patch in [{'provenanceStatus':'legacy_linkage_only'},{'candidateValue':1},
      {'provenance':{...benchMap(evidence['provenance']),'imageSha256':'wrong'}}]){
      expect(()=>verifyBenchEstimate(selected,'NO2',result,receipts,{...evidence,...patch}),throwsFormatException);
    }
    expect(()=>requireBenchCurrent(()=>false),throwsStateError);
  });

  test('cancelled detail does not issue evidence or review follow-up',() async {
    var active=true;
    final service=WaterBenchMonitorService(client:MockClient((r) async {
      expect(r.url.path.endsWith('/evidence')||r.url.path.endsWith('/review'),isFalse);
      if(r.url.path.endsWith('/receipts'))active=false;
      return fixture(r);
    }));
    await expectLater(service.detail(session,BenchBatch.fromJson(batchJson),current:()=>active),throwsStateError);
  });
}
