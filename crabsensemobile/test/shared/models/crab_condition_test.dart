import 'package:crabsensemobile/core/theme/app_colors.dart';
import 'package:crabsensemobile/shared/models/crab_condition.dart';
import 'package:flutter_test/flutter_test.dart';

/// Bảng màu/nhãn tình trạng cua là nguồn duy nhất cho lưới hộp, chú giải, phiếu
/// chăm sóc và chi tiết cua. Test này khoá đúng những chỗ từng gây rối:
/// cùng một tình trạng hiển thị khác màu ở các màn, và key 'attention' bị BE
/// hiểu thành 'normal'.
void main() {
  group('màu theo nhóm tình trạng', () {
    test('lột (sắp lột / đang lột / lột mềm) dùng chung một màu tím', () {
      const molting = [
        CrabCondition.premolt,
        CrabCondition.molting,
        CrabCondition.softshell,
      ];
      for (final c in molting) {
        expect(c.color, CrabSenseColors.molt, reason: '${c.name} phải là tím');
      }
    });

    test('nguy cơ (có vấn đề / cua yếu) dùng chung một màu đỏ', () {
      for (final c in [CrabCondition.problem, CrabCondition.weak]) {
        expect(c.color, CrabSenseColors.danger, reason: '${c.name} phải là đỏ');
      }
    });

    test('bình thường = xanh lá, trống = xám, và 4 nhóm khác màu nhau', () {
      expect(CrabCondition.normal.color, CrabSenseColors.success);
      expect(CrabCondition.empty.color, CrabSenseColors.textHint);

      final distinct = {
        CrabCondition.empty.color,
        CrabCondition.normal.color,
        CrabCondition.premolt.color,
        CrabCondition.problem.color,
      };
      expect(distinct.length, 4, reason: '4 nhóm phải khác màu để không gây rối');
    });

    test('nền nhạt cùng tông với màu chữ, không trùng nhau', () {
      expect(CrabCondition.normal.background, CrabSenseColors.successLight);
      expect(CrabCondition.premolt.background, CrabSenseColors.moltLight);
      expect(CrabCondition.problem.background, CrabSenseColors.dangerLight);
      for (final c in CrabCondition.values) {
        expect(c.background, isNot(c.color));
      }
    });
  });

  group('nhãn', () {
    test('khớp đúng bộ chữ của app desktop', () {
      expect(CrabCondition.empty.label, 'Trống');
      expect(CrabCondition.normal.label, 'Bình thường');
      expect(CrabCondition.premolt.label, 'Sắp lột');
      expect(CrabCondition.molting.label, 'Đang lột');
      expect(CrabCondition.softshell.label, 'Cua lột mềm');
      expect(CrabCondition.problem.label, 'Có vấn đề');
      expect(CrabCondition.weak.label, 'Cua yếu');
    });
  });

  group('tryParse', () {
    test('key cũ "attention" phải là có vấn đề, KHÔNG được thành bình thường', () {
      // Đây là lỗi thật: BE không hiểu 'attention' nên Parse rơi về 'normal',
      // nông dân bấm "Cần chú ý" mà hệ thống ghi thành "Bình thường".
      expect(CrabCondition.tryParse('attention'), CrabCondition.problem);
    });

    test('key BE trả về đọc đúng', () {
      expect(CrabCondition.tryParse('premolt'), CrabCondition.premolt);
      expect(CrabCondition.tryParse('molting'), CrabCondition.molting);
      expect(CrabCondition.tryParse('softshell'), CrabCondition.softshell);
      expect(CrabCondition.tryParse('problem'), CrabCondition.problem);
      expect(CrabCondition.tryParse('weak'), CrabCondition.weak);
      expect(CrabCondition.tryParse('normal'), CrabCondition.normal);
    });

    test('cua chết / đã bán / đã thu hoạch ⇒ hộp trống', () {
      for (final key in ['dead', 'harvested', 'sold']) {
        expect(CrabCondition.tryParse(key), CrabCondition.empty, reason: key);
      }
    });

    test('chịu được hoa thường, gạch dưới, gạch nối và khoảng trắng', () {
      expect(CrabCondition.tryParse('  PRE_MOLT '), CrabCondition.premolt);
      expect(CrabCondition.tryParse('hard-shell'), CrabCondition.normal);
    });

    test('giá trị lạ / rỗng ⇒ null để nơi gọi tự chọn màu dự phòng', () {
      expect(CrabCondition.tryParse(null), isNull);
      expect(CrabCondition.tryParse(''), isNull);
      expect(CrabCondition.tryParse('xyz'), isNull);
    });

    test('apiKey gửi lên BE đọc lại ra đúng tình trạng', () {
      for (final c in CrabCondition.selectable) {
        expect(CrabCondition.tryParse(c.apiKey), c, reason: c.name);
      }
    });

    test('trống không gửi lên BE: apiKey rỗng, và chuỗi rỗng không phải "trống"', () {
      // '' nghĩa là "không đánh dấu gì" nên phải là null để lưới hộp rơi về màu
      // theo điểm sức khỏe, chứ không phải hộp trống.
      expect(CrabCondition.empty.apiKey, '');
      expect(CrabCondition.tryParse(CrabCondition.empty.apiKey), isNull);
      expect(CrabCondition.tryParse('empty'), CrabCondition.empty);
    });

    test('apiKey khớp CrabConditions.ToApi của BE', () {
      expect(
        CrabCondition.selectable.map((c) => c.apiKey).toSet(),
        {'normal', 'premolt', 'molting', 'softshell', 'problem', 'weak'},
      );
    });
  });
}
