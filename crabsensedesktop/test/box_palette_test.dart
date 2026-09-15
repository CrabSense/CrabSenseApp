import 'package:crab_farm_monitor_desktop/models/box_status.dart';
import 'package:crab_farm_monitor_desktop/models/crab_condition.dart';
import 'package:crab_farm_monitor_desktop/models/farm_layout.dart';
import 'package:crab_farm_monitor_desktop/models/production_models.dart';
import 'package:crab_farm_monitor_desktop/theme/dashboard_theme.dart';
import 'package:crab_farm_monitor_desktop/utils/farm_layout_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

/// Quy ước màu của Khánh: lột = tím, nguy cơ (có vấn đề / cua yếu) = đỏ,
/// bình thường = xanh, chết hoặc đã bán ⇒ BE trả hộp về trống.
///
/// Test này gãy nếu ai đó đổi lại bảng màu hoặc để mapper quay về chỉ đọc
/// `box.status` (khi đó mọi hộp đang nuôi đều xanh như lỗi trước đây).
void main() {
  group('mapCrabCondition', () {
    test('nguy cơ (problem / weak) => đỏ', () {
      expect(mapCrabCondition('problem'), BoxStatus.alert);
      expect(mapCrabCondition('weak'), BoxStatus.alert);
      expect(BoxStatus.alert.color, DashboardColors.risk);
    });

    test('lột (premolt / molting / softshell) => tím', () {
      for (final c in ['premolt', 'molting', 'softshell']) {
        expect(mapCrabCondition(c), BoxStatus.molting, reason: c);
        expect(BoxStatus.molting.color, DashboardColors.moltPurple, reason: c);
      }
    });

    test('chết / đã bán => trống hộp, không tô đỏ', () {
      for (final c in ['dead', 'harvested', 'sold']) {
        expect(mapCrabCondition(c), BoxStatus.empty, reason: c);
      }
      expect(mapBoxApiStatus('dead'), BoxStatus.empty);
      expect(mapBoxApiStatus('harvested'), BoxStatus.empty);
    });

    test('bình thường và giá trị lạ => xanh', () {
      expect(mapCrabCondition('normal'), BoxStatus.normal);
      expect(mapCrabCondition(null), BoxStatus.normal);
      expect(mapCrabCondition(''), BoxStatus.normal);
      expect(mapCrabCondition('khong-ton-tai'), BoxStatus.normal);
      expect(BoxStatus.normal.color, DashboardColors.healthy);
    });
  });

  group('toFarmMapBox — hộp active nhưng cua bệnh vẫn phải đổi màu', () {
    FarmMapBox map({required String boxStatus, int crabCount = 0, String? crabCondition}) {
      return toFarmMapBox(
        box: BoxRecord(
          id: 'box-1',
          rowId: 'row-1',
          boxCode: 'BOX-0001',
          status: boxStatus,
          crabCount: crabCount,
          crabCondition: crabCondition,
        ),
        area: const AreaRecord(
          id: 'area-1',
          farmId: 'farm-1',
          areaCode: 'FARM-005',
          areaName: 'Khu thuc',
        ),
        row: const RowRecord(
          id: 'row-1',
          areaId: 'area-1',
          rowCode: 'A11',
          rowName: 'A11',
        ),
      );
    }

    test('box.status=active + cua problem => đỏ', () {
      final item = map(boxStatus: 'active', crabCount: 1, crabCondition: 'problem');
      expect(item.display.status, BoxStatus.alert);
      expect(item.display.hasAlert, isTrue);
    });

    test('box.status=active + cua molting => tím', () {
      final item = map(boxStatus: 'active', crabCount: 1, crabCondition: 'molting');
      expect(item.display.status, BoxStatus.molting);
    });

    test('box.status=active + cua normal => xanh', () {
      final item = map(boxStatus: 'active', crabCount: 1, crabCondition: 'normal');
      expect(item.display.status, BoxStatus.normal);
    });

    test('hộp trống => trống', () {
      expect(map(boxStatus: 'empty').display.status, BoxStatus.empty);
    });
  });

  group('CrabConditionX — chip tình trạng trên thẻ hộp', () {
    CrabCondition parse(String condition) => CrabConditionX.parse(
          condition: condition,
          hasCrab: true,
        );

    test('weak được nhận và tô đỏ như problem', () {
      expect(parse('weak'), CrabCondition.weak);
      expect(CrabCondition.weak.color, DashboardColors.risk);
      expect(CrabCondition.problem.color, DashboardColors.risk);
    });

    test('cả 3 mức lột đều tím', () {
      for (final c in ['premolt', 'molting', 'softshell']) {
        expect(parse(c).color, DashboardColors.moltPurple, reason: c);
      }
    });

    test('cua đã chết / bán => trống hộp', () {
      expect(parse('dead'), CrabCondition.empty);
      expect(parse('sold'), CrabCondition.empty);
      expect(
        CrabConditionX.parse(crabStatus: 'dead', hasCrab: true),
        CrabCondition.empty,
      );
    });

    test('bộ lọc tình trạng có mục Cua yếu', () {
      expect(
        CrabConditionFilter.values.map((f) => f.condition),
        contains(CrabCondition.weak),
      );
    });
  });
}
