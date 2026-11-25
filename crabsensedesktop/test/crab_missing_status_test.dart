import 'package:crab_farm_monitor_desktop/models/crab_status.dart';
import 'package:crab_farm_monitor_desktop/models/crab_lifecycle_event.dart';
import 'package:crab_farm_monitor_desktop/theme/dashboard_theme.dart';
import 'package:crab_farm_monitor_desktop/utils/crab_management_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
