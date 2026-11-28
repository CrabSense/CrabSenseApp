import 'package:crabsensemobile/features/reports/data/reports_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crabsensemobile/features/reports/data/models/report_models.dart';
import 'package:crabsensemobile/features/reports/presentation/providers/reports_provider.dart';
import 'package:crabsensemobile/features/reports/presentation/screens/reports_hub_screen.dart';

const empty = <String, dynamic>{
  'cohortBasis': 'stockedAt-current-status-v1', 'farmingAreaId': 'area-a',
  'totalCrabs': 0, 'aliveCrabs': 0, 'moltingCrabs': 0, 'moltedCrabs': 0,
  'harvestedCrabs': 0, 'deadCrabs': 0, 'unclassifiedCrabs': 0,
  'healthScore': 30,
};

void main() {
  test('efficiency rejects wrong area, legacy and zero denominator rates', () {
    final result = verifyEfficiencyReport(empty, 'area-a');
    expect(result['healthScore'], isNull);
    expect(result['harvestRate'], isNull);
    expect(() => verifyEfficiencyReport(empty, 'area-b'), throwsFormatException);
    expect(() => verifyEfficiencyReport({...empty, 'cohortBasis': null}, 'area-a'), throwsFormatException);
    expect(() => verifyEfficiencyReport({...empty, 'harvestRate': 0}, 'area-a'), throwsFormatException);
  });
  test('efficiency preserves actual zero with valid denominator', () {
    final known = {...empty, 'totalCrabs': 1, 'aliveCrabs': 1,
      'survivalRate': 100, 'aliveRate': 100, 'moltingRate': 0,
      'harvestRate': 0, 'mortalityRate': 0};
    expect(verifyEfficiencyReport(known, 'area-a')['harvestRate'], 0);
    expect(() => verifyEfficiencyReport({...known, 'harvestRate': false}, 'area-a'), throwsFormatException);
  });

  testWidgets('Farm Staff deep links never expose management report exports', (tester) async {
    for (final kind in ReportKind.values) {
      await tester.pumpWidget(MaterialApp(home: ReportsHubScreen(initialKind: kind)));
      expect(find.byKey(const ValueKey('management-report-forbidden')), findsOneWidget);
      expect(find.byIcon(Icons.download_rounded), findsNothing);
      expect(find.byType(RefreshIndicator), findsNothing);
    }
    await tester.pumpWidget(const MaterialApp(home: ReportsHubScreen()));
    expect(find.text(ReportKind.efficiency.titleVi), findsNothing);
    expect(find.text('Chất lượng nước'), findsOneWidget);
  });

  test('management report provider denies before resolving an HTTP repository', () async {
    final container = ProviderContainer(overrides: [
      reportsRepositoryProvider.overrideWith((ref) => throw StateError('Unexpected repository access')),
    ]);
    addTearDown(container.dispose);
    for (final kind in ReportKind.values) {
      await expectLater(container.read(reportDetailProvider(kind).future),
          throwsA(isA<StateError>().having((e) => e.message, 'message',
              'Farm Staff không có quyền xem báo cáo quản trị.')));
    }
  });
}
