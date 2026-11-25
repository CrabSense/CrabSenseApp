import 'dart:async';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import '../lib/models/auth_models.dart';
import '../lib/models/ras_flow.dart';
import '../lib/services/ras_flow_service.dart';

void main() {
  const a = FarmSummary(id: 'area-a', code: 'A', name: 'A');
  const b = FarmSummary(id: 'area-b', code: 'B', name: 'B');
  const session = AuthSession(token: 'test',
    user: AuthUser(id: 'manager', email: '', displayName: 'Manager', role: UserRoles.farmManager),
    farms: [a, b], selectedFarm: a, isOrgAdmin: false);
  setUp(() => dotenv.testLoad(fileInput: 'CLOUD_API_URL=http://localhost:5080'));

  http.Response diagram(String area, {bool disabled = false, String? status, bool? on = false}) =>
    http.Response(jsonEncode({'success':true,'data':{
      'areaId':area,'areaCode':area,'areaName':area,'hardwareControlDisabled':disabled,
      'nodes':[{'id':'relay-a','nodeCode':'pump','displayLabel':'Pump','hasRelay':true,
        'isOnline':true,'isOn':on,'relayDeviceId':'controller-a','relayChannel':'1',
        'lastReportedAt':'2026-11-24T07:00:00Z','commandStatus':status,'desiredIsOn':true}]
    }}),200);

  test('old response cannot overwrite new selected area', () async {
    final old = Completer<http.Response>();
    final client = MockClient((request) async {
      if (request.url.path.contains('/area-a/')) return old.future;
      return diagram('area-b');
    });
    final svc = RasFlowService(session:session,client:client);
    addTearDown(svc.dispose);
    final request = svc.loadDiagram('area-a');
    svc.updateSession(session.copyWith(selectedFarm:b));
    await svc.loadDiagram('area-b');
    old.complete(diagram('area-a'));
    await request;
    expect(svc.diagram?.areaId, 'area-b');
  });

  test('disabled hardware and cross-area command do not hit command endpoint', () async {
    final client = MockClient((request) async {
      expect(request.method, 'GET');
      return diagram('area-a',disabled:true);
    });
    final svc = RasFlowService(session:session,client:client);
    addTearDown(svc.dispose);
    await svc.loadDiagram('area-a');
    expect(svc.canOperate,isFalse);
    expect(await svc.sendCommand(areaId:'area-a',nodeId:'relay-a',command:'on'),isFalse);
    expect(await svc.sendCommand(areaId:'area-b',nodeId:'relay-a',command:'on'),isFalse);
  });

  test('pending command is not a physical acknowledgement and prevents duplicate command', () async {
    var posts = 0;
    final client = MockClient((request) async {
      if (request.method == 'POST') {
        posts++;
        expect(jsonDecode(request.body)['command'],'on');
        return diagram('area-a',status:'pending',on:false);
      }
      return diagram('area-a');
    });
    final svc = RasFlowService(session:session,client:client);
    addTearDown(svc.dispose);
    await svc.loadDiagram('area-a');
    expect(await svc.sendCommand(areaId:'area-a',nodeId:'relay-a',command:'on'),isTrue);
    final node = svc.diagram!.nodes.single;
    expect(node.observedOn,isFalse);
    expect(node.desiredIsOn,isTrue);
    expect(node.commandPending,isTrue);
    expect(await svc.sendCommand(areaId:'area-a',nodeId:'relay-a',command:'on'),isFalse);
    expect(posts,1);
  });

  test('unknown or unreported hardware observation is not OFF', () {
    final node = RasFlowNodeLive.fromJson({'id':'n','nodeCode':'pump',
      'displayLabel':'Pump','hasRelay':true,'isOnline':true,'isOn':false});
    expect(node.observedOn,isNull);
    expect(node.runLabel,'Chưa xác nhận');
    final pending = RasFlowNodeLive.fromJson({'id':'n','nodeCode':'pump',
      'displayLabel':'Pump','hasRelay':true,'commandStatus':'awaiting_report'});
    expect(pending.commandPending,isTrue);
  });
}
