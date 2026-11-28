import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/models/health_monitoring.dart';
import '../lib/screens/health/health_monitoring_page.dart';

void main() {
  test('missing assessment never enables report export', () {
    const selected = HealthMonitoringState.unavailable(crabId: 'crab-a');
    const absent = HealthMonitoringState.unavailable(crabId: null);
    const blank = HealthMonitoringState.unavailable(crabId: '  ');
    expect(selected.hasSelection, isTrue);
    expect(selected.canExport, isFalse);
    expect(absent.hasSelection, isFalse);
    expect(blank.hasSelection, isFalse);
    expect(absent.canExport, isFalse);
    expect(blank.canExport, isFalse);
  });

  testWidgets('selected crab has neutral unavailable data and disabled export',
      (tester) async {
    var back = 0, history = 0;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body:
      HealthMonitoringPage(crabId:'crab-a',
        onBack: () => back++, onOpenHistory: () => history++))));
    expect(find.text('Cua đang chọn: crab-a'), findsOneWidget);
    expect(find.text('Chưa có hồ sơ sức khỏe xác minh'), findsOneWidget);
    final export = find.byKey(const ValueKey('health-export'));
    expect(tester.widget<FilledButton>(export).onPressed, isNull);
    await tester.tap(export);
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Sao chép'), findsNothing);
    expect(find.textContaining('/100'), findsNothing);
    expect(find.text('Optimum'), findsNothing);
    expect(find.text('LIVE MONITOR'), findsNothing);
    expect(find.text('Cảnh báo khẩn cấp'), findsNothing);
    await tester.tap(find.text('Hồ sơ cua'));
    await tester.tap(find.text('Quay lại'));
    expect(history, 1);
    expect(back, 1);
  });

  testWidgets('missing selection cannot show a sample crab or export report',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body:
      HealthMonitoringPage(crabId:null))));
    expect(find.text('Chưa chọn cua'), findsWidgets);
    expect(find.textContaining('CRAB-A01-001'), findsNothing);
    expect(find.text('Hồ sơ cua'), findsNothing);
    expect(tester.widget<FilledButton>(
      find.byKey(const ValueKey('health-export'))).onPressed, isNull);
    expect(find.text('Điểm sức khỏe'), findsNothing);
  });
}
