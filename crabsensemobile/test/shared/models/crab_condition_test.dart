import 'package:crabsensemobile/core/theme/app_colors.dart';
import 'package:crabsensemobile/features/box_management/domain/models/boxes_models.dart';
import 'package:crabsensemobile/shared/models/crab_condition.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Nông dân đã yêu cầu rõ: bảng đánh dấu tình trạng và bảng trạng thái màu bên
/// ngoài phải là MỘT, và chỉ có 5 nhãn — Bình thường / Cần theo dõi / Lột xác /
/// Cảnh báo / Hộp trống. Không được còn "Sắp lột", "Đang lột", "Cua lột mềm",
/// "Có vấn đề", "Cua yếu" như những nhãn riêng.
void main() {
  const dayDu = ['Bình thường', 'Cần theo dõi', 'Lột xác', 'Cảnh báo', 'Hộp trống'];
  const camKy = [
    'Sắp lột',
    'Đang lột',
    'Cua lột mềm',
    'Có vấn đề',
    'Cua yếu',
    'Trống',
  ];

  group('nhãn — chỉ 5 nhãn, hết chữ cũ', () {
    test('đúng bộ chữ của app desktop', () {
      expect(BoxStatus.normal.label, 'Bình thường');
      expect(BoxStatus.watch.label, 'Cần theo dõi');
      expect(BoxStatus.molting.label, 'Lột xác');
      expect(BoxStatus.alert.label, 'Cảnh báo');
      expect(BoxStatus.empty.label, 'Hộp trống');
    });

    test('không nhãn nào còn là chữ cũ', () {
      const boCu = {'Healthy', 'Warning', 'Critical', 'Offline'};
      for (final s in BoxStatus.values) {
        expect(camKy.contains(s.label), isFalse, reason: '${s.name} = ${s.label}');
        expect(boCu.contains(s.label), isFalse, reason: s.name);
      }
      for (final f in BoxQuickFilter.values) {
        expect(boCu.contains(f.label), isFalse, reason: f.name);
      }
    });

    test('mọi tình trạng cua đều ra nhãn nằm trong bộ 5', () {
      for (final c in CrabCondition.values) {
        expect(
          dayDu.contains(c.displayStatus.label),
          isTrue,
          reason: '${c.name} → ${c.displayStatus.label}',
        );
      }
    });
  });

  group('displayStatusOf — gộp đúng như nông dân yêu cầu', () {
    test('sắp lột / đang lột / lột mềm đều là "Lột xác"', () {
      for (final c in [
        CrabCondition.premolt,
        CrabCondition.molting,
        CrabCondition.softshell,
      ]) {
        expect(c.displayStatus, BoxStatus.molting, reason: c.name);
      }
    });

    test('có vấn đề là "Cảnh báo"', () {
      expect(CrabCondition.problem.displayStatus, BoxStatus.alert);
    });

    test('cua yếu là "Cần theo dõi" — đúng quy ước "yếu và cần chú ý là một"', () {
      expect(CrabCondition.weak.displayStatus, BoxStatus.watch);
    });

    test('chết / sổng / thu hoạch / bán đều là "Hộp trống"', () {
      for (final k in ['dead', 'escaped', 'harvested', 'sold']) {
        expect(displayStatusOf(CrabCondition.tryParse(k)), BoxStatus.empty, reason: k);
      }
    });

    test('không đọc được gì (cua thêm trước khi có trường này) ⇒ Bình thường', () {
      expect(displayStatusOf(null), BoxStatus.normal);
      expect(boxStatusFromCrabCondition(null), BoxStatus.normal);
      expect(boxStatusFromCrabCondition(''), BoxStatus.normal);
      expect(boxStatusFromCrabCondition('xyz'), BoxStatus.normal);
    });
  });

  group('bảng đánh dấu = bảng trạng thái (LÀ 1)', () {
    test('mỗi mức đánh dấu ra một nhãn khác nhau — không hai mức nào trùng nhãn', () {
      final nhan = <String>{};
      for (final c in CrabCondition.selectable) {
        expect(
          nhan.add(c.displayStatus.label),
          isTrue,
          reason: '${c.name} trùng nhãn ${c.displayStatus.label}',
        );
      }
      expect(nhan.length, CrabCondition.selectable.length);
    });

    test('nhãn đánh dấu nằm trong bộ 5, và không mức nào ra "Hộp trống"', () {
      for (final c in CrabCondition.selectable) {
        expect(dayDu.contains(c.displayStatus.label), isTrue, reason: c.name);
        // "Hộp trống" là kết quả khi cua kết thúc, không phải mức để chọn.
        expect(c.displayStatus, isNot(BoxStatus.empty), reason: c.name);
      }
    });

    test('đánh dấu key nào thì đọc lại ra đúng nhãn đó', () {
      for (final c in CrabCondition.selectable) {
        expect(
          boxStatusFromCrabCondition(c.apiKey),
          c.displayStatus,
          reason: c.apiKey,
        );
      }
    });

    test('key gửi lên BE đều là key BE hiểu', () {
      const beHieu = {'normal', 'weak', 'molting', 'problem'};
      expect(
        CrabCondition.selectable.map((c) => c.apiKey).toSet(),
        beHieu,
      );
    });

    test('mã màu dùng chung với thẻ hộp (DashboardColors)', () {
      expect(CrabCondition.normal.displayStatus.color, const Color(0xFF22C55E));
      expect(CrabCondition.weak.displayStatus.color, const Color(0xFFEAB308));
      expect(CrabCondition.premolt.displayStatus.color, const Color(0xFFA78BFA));
      expect(CrabCondition.molting.displayStatus.color, const Color(0xFFA78BFA));
      expect(CrabCondition.softshell.displayStatus.color, const Color(0xFFA78BFA));
      expect(CrabCondition.problem.displayStatus.color, const Color(0xFFEF4444));
      expect(CrabCondition.empty.displayStatus.color, const Color(0xFF64748B));
    });

    test('4 nhóm sống khác màu nhau', () {
      final mau = {
        CrabCondition.normal.displayStatus.color,
        CrabCondition.weak.displayStatus.color,
        CrabCondition.molting.displayStatus.color,
        CrabCondition.problem.displayStatus.color,
      };
      expect(mau.length, 4);
    });

    test('nền nhạt cùng tông với màu chữ', () {
      expect(CrabCondition.normal.displayStatus.background, CrabSenseColors.statusNormalBg);
      expect(CrabCondition.molting.displayStatus.background, CrabSenseColors.moltLight);
      expect(CrabCondition.problem.displayStatus.background, CrabSenseColors.statusRiskBg);
      expect(CrabCondition.weak.displayStatus.background, CrabSenseColors.statusWatchBg);
    });
  });

  group('tryParse — đọc dữ liệu cũ và dữ liệu app desktop', () {
    test('nhận key không phân biệt hoa thường / gạch', () {
      expect(CrabCondition.tryParse('  PRE_MOLT '), CrabCondition.premolt);
      expect(CrabCondition.tryParse('hard-shell'), CrabCondition.normal);
    });

    test('cua do desktop ghi (premolt / softshell) vẫn hiện đúng nhóm', () {
      expect(CrabCondition.tryParse('premolt'), CrabCondition.premolt);
      expect(CrabCondition.tryParse('softshell'), CrabCondition.softshell);
      expect(boxStatusFromCrabCondition('premolt'), BoxStatus.molting);
      expect(boxStatusFromCrabCondition('softshell'), BoxStatus.molting);
    });

    test('"attention" cũ phải là Cảnh báo, KHÔNG được thành Bình thường', () {
      final c = CrabCondition.tryParse('attention');
      expect(c, CrabCondition.problem);
      expect(c!.displayStatus, BoxStatus.alert);
    });

    test('giá trị lạ / rỗng ⇒ null', () {
      expect(CrabCondition.tryParse(null), isNull);
      expect(CrabCondition.tryParse(''), isNull);
      expect(CrabCondition.tryParse('xyz'), isNull);
    });

    test('trống không gửi lên BE: apiKey rỗng', () {
      expect(CrabCondition.empty.apiKey, '');
    });
  });
}
