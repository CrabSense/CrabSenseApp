import 'package:crabsensemobile/core/theme/app_colors.dart';
import 'package:crabsensemobile/features/box_management/domain/models/boxes_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Trạng thái hộp là nguồn duy nhất cho lưới, chú giải, chip lọc, huy hiệu và
/// thanh tổng quan. Test này khoá đúng hai lỗi từng có trên mobile: in ra nhãn
/// tiếng Anh không hề có trên desktop ("Healthy", "Warning", "Critical",
/// "Offline") và tô màu lệch tông với app desktop.
void main() {
  group('nhãn — không còn chữ tiếng Anh sót lại', () {
    test('đúng bộ chữ của app desktop', () {
      expect(BoxStatus.normal.label, 'Bình thường');
      expect(BoxStatus.watch.label, 'Cần theo dõi');
      expect(BoxStatus.molting.label, 'Lột xác');
      expect(BoxStatus.alert.label, 'Cảnh báo');
      expect(BoxStatus.deceased.label, 'Sự cố');
      expect(BoxStatus.empty.label, 'Hộp trống');
    });

    test('không trạng thái nào còn mang nhãn cũ', () {
      const boCu = {'Healthy', 'Warning', 'Critical', 'Offline'};
      for (final s in BoxStatus.values) {
        expect(boCu.contains(s.label), isFalse, reason: s.name);
      }
    });

    test('chip lọc nhanh cũng không còn nhãn cũ', () {
      const boCu = {'Healthy', 'Warning', 'Critical', 'Offline'};
      for (final f in BoxQuickFilter.values) {
        expect(boCu.contains(f.label), isFalse, reason: f.name);
      }
    });
  });

  group('màu — khớp app desktop', () {
    test('mã màu đúng DashboardColors của desktop', () {
      expect(BoxStatus.normal.color, const Color(0xFF22C55E));
      expect(BoxStatus.watch.color, const Color(0xFFEAB308));
      expect(BoxStatus.molting.color, const Color(0xFFA78BFA));
      expect(BoxStatus.alert.color, const Color(0xFFEF4444));
      expect(BoxStatus.empty.color, const Color(0xFF64748B));
    });

    test('lột = tím, nguy cơ = đỏ, và 4 nhóm khác màu nhau', () {
      expect(BoxStatus.molting.color, CrabSenseColors.molt);
      expect(BoxStatus.alert.color, CrabSenseColors.statusRisk);
      final distinct = {
        BoxStatus.normal.color,
        BoxStatus.watch.color,
        BoxStatus.molting.color,
        BoxStatus.alert.color,
      };
      expect(distinct.length, 4, reason: 'màu phải khác nhau mới không gây rối');
    });
  });

  group('boxStatusFromCrabCondition — suy như desktop', () {
    test('có vấn đề ⇒ cảnh báo', () {
      for (final k in ['problem', 'PROBLEM', 'quarantined']) {
        expect(boxStatusFromCrabCondition(k), BoxStatus.alert, reason: k);
      }
    });

    test('cua yếu ⇒ cần theo dõi (chưa phải sự cố)', () {
      for (final k in ['weak', 'WEAK', 'yeu']) {
        expect(boxStatusFromCrabCondition(k), BoxStatus.watch, reason: k);
      }
    });

    test('lột ⇒ lột xác', () {
      for (final k in ['premolt', 'molting', 'softshell']) {
        expect(boxStatusFromCrabCondition(k), BoxStatus.molting, reason: k);
      }
    });

    test('chết / đã bán / đã thu hoạch ⇒ hộp trống', () {
      for (final k in ['dead', 'harvested', 'sold']) {
        expect(boxStatusFromCrabCondition(k), BoxStatus.empty, reason: k);
      }
    });

    test('còn lại ⇒ bình thường', () {
      for (final String? k in ['normal', '', null, 'xyz']) {
        expect(boxStatusFromCrabCondition(k), BoxStatus.normal, reason: '$k');
      }
    });
  });

  group('boxStatusFromApi — suy như mapBoxApiStatus của desktop', () {
    test('trống / chưa gán', () {
      for (final k in ['', 'empty', 'available', 'vacant']) {
        expect(boxStatusFromApi(k), BoxStatus.empty, reason: '"$k"');
      }
    });

    test('đang nuôi và bảo trì', () {
      expect(boxStatusFromApi('active'), BoxStatus.normal);
      expect(boxStatusFromApi('farming'), BoxStatus.normal);
      expect(boxStatusFromApi('maintenance'), BoxStatus.watch);
    });

    test('cảnh báo và lột', () {
      expect(boxStatusFromApi('warning'), BoxStatus.alert);
      expect(boxStatusFromApi('quarantine'), BoxStatus.alert);
      expect(boxStatusFromApi('molting'), BoxStatus.molting);
    });
  });

  group('FarmBoxesOverview đếm theo trạng thái mới', () {
    test('hộp trống không tính vào nhóm đang nuôi', () {
      final overview = FarmBoxesOverview.fromBoxes([
        _box('A', BoxStatus.normal),
        _box('B', BoxStatus.normal),
        _box('C', BoxStatus.watch),
        _box('D', BoxStatus.molting),
        _box('E', BoxStatus.alert),
        _box('F', BoxStatus.empty),
      ]);
      expect(overview.total, 6);
      expect(overview.normal, 2);
      expect(overview.watch, 1);
      expect(overview.molting, 1);
      expect(overview.alert, 1);
    });
  });
}

BoxSummary _box(String code, BoxStatus status) => BoxSummary(
  id: code,
  code: code,
  name: code,
  qrCode: code,
  farmId: 'area',
  farmName: 'Khu',
  location: const BoxMapLocation(
    gridX: 0,
    gridY: 0,
    areaName: 'Khu',
    areaId: 'area',
  ),
  status: status,
  healthScore: BoxHealthScore.fromScore(80, 80, BoxTrend.stable),
  crabCount: 1,
  water: BoxWaterSnapshot.empty,
  devices: const BoxDeviceStatus(isOnline: true, onlineCount: 1, totalCount: 1),
  alerts: BoxAlertSummary.none,
  aiRecommendation: BoxAIRecommendation.none,
  lastUpdated: DateTime(2026),
  syncStatus: BoxSyncStatus.synced,
  priority: ActionPriorityLevel.low,
);
