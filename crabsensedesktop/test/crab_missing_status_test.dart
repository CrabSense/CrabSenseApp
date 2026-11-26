import 'package:crab_farm_monitor_desktop/models/crab_status.dart';
import 'package:crab_farm_monitor_desktop/models/production_models.dart';
import 'package:crab_farm_monitor_desktop/models/crab_lifecycle_event.dart';
import 'package:crab_farm_monitor_desktop/theme/dashboard_theme.dart';
import 'package:crab_farm_monitor_desktop/utils/crab_management_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('closed lot missing count is independent of mortality and unknown stays absent', () {
    final lot = FarmingBatchRecord.fromJson({'id':'lot','quantity':10,'placedCount':4,'status':'Completed','closedAt':'2026-11-25T00:00:00Z','missingCountAtClose':2,'deadCountAtClose':1});
    expect(lot.closeCounts['missingCountAtClose'],2);
    expect(lot.closeCounts['deadCountAtClose'],1);
    final legacy = FarmingBatchRecord.fromJson({'id':'old','quantity':10,'placedCount':4,'status':'Completed','closedAt':'2026-11-25T00:00:00Z'});
    expect(legacy.closeCounts.containsKey('missingCountAtClose'),isFalse);
  });
  test('closed lot is not available for new registration', () {
    final lot = FarmingBatchRecord.fromJson({
      'id': 'lot-1', 'lotCode': 'LOT-1', 'quantity': 10, 'placedCount': 4,
      'status': 'Allocating', 'closedAt': '2026-11-25T00:00:00Z',
      'importDate': '2026-11-20T00:00:00Z',
    });
    expect(lot.isClosed, isTrue);
    expect(lot.remainingCount, 0);
  });
  test('Problem health is never presented as healthy', () {
    expect(mapHealthStatus('Problem'), CrabHealthStatus.atRisk);
    expect(mapDisplayHealth('Problem'), CrabDisplayHealth.alert);
  });
  test('recovered history is distinct and included in missing history filter', () {
    final event = CrabLifecycleEventType.parse('RECOVERED');
    expect(event, CrabLifecycleEventType.recovered);
    expect(event.filter, CrabHistoryEventFilter.missing);
    expect(event.label, 'Khôi phục cua tìm thấy');
    expect(CrabLifecycleSummary.fromJson({'missing': 2, 'recovered': 1})
        .of(CrabHistoryEventFilter.missing), 3);
  });
  test('missing lifecycle labels and colors are distinct from death', () {
    expect(resolveCrabLifecycleStatus({'status': 'Missing', 'isAlive': false}), 'missing');
    expect(mapLifeStatus('missing'), CrabLifeStatus.missing);
    expect(mapLifecycleStatus(status: 'missing'), CrabLifecycleStatus.missing);
    expect(CrabLifecycleStatus.missing.label, 'Thất lạc');
    expect(CrabLifecycleStatus.missing.color, DashboardColors.monitoring);
    expect(CrabLifeStatus.missing.label, 'Thất lạc');
    expect(CrabLifeStatus.missing.color, DashboardColors.monitoring);
    expect(CrabOperationalStatus.missing.label, 'THẤT LẠC');
    expect(CrabOperationalStatus.missing.color, DashboardColors.monitoring);
    expect(CrabManagementStatusFilter.missing.label, 'Thất lạc');
  });
  test('missing history count is not counted as harvest or mortality', () {
    final summary = CrabLifecycleSummary.fromJson({'total': 4, 'missing': 2, 'harvest': 1});
    expect(summary.of(CrabHistoryEventFilter.missing), 2);
    expect(summary.of(CrabHistoryEventFilter.harvest), 1);
    expect(CrabLifecycleEventType.parse('MISSING').filter, CrabHistoryEventFilter.missing);
  });
}
