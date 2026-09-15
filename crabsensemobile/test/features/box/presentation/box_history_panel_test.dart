// Check cho logic gop phieu thanh diem bieu do cua `BoxHistoryPanel`.
//
// Day la cho de sai nhat va tung sai that: ngay KHONG co phieu bi tra ve 0, roi
// duoc ve thanh duong phang o "Khong an"/"Yeu" — trong nhu da theo doi va cua bo an.
// Test nay khoa su khac biet giua `null` (khong co so lieu) va `0` (da ghi "Khong an").

import 'package:crabsensemobile/features/box/presentation/widgets/box_history_panel.dart';
import 'package:flutter_test/flutter_test.dart';

BoxCareRecord _rec({
  required DateTime at,
  int? eat,
  int? act,
  double? grams,
}) =>
    BoxCareRecord(at: at, eat: eat, act: act, grams: grams);

void main() {
  final day = DateTime(2026, 9, 15);

  group('BoxHistoryPanelState.mergeDay', () {
    test('khong co phieu nao ⇒ null, KHONG phai 0', () {
      final p = BoxHistoryPanelState.mergeDay(day, const []);

      // Cot loi: 0 nghia la "da kiem tra, cua khong an". null nghia la "chua kiem tra".
      expect(p.eat, isNull);
      expect(p.act, isNull);
      expect(p.grams, 0);
      expect(p.day, day);
    });

    test('ghi "Khong an" ⇒ 0 that su (khac han chua kiem tra)', () {
      final p = BoxHistoryPanelState.mergeDay(
        day,
        [_rec(at: day, eat: 0, act: 0)],
      );

      expect(p.eat, 0);
      expect(p.act, 0);
      expect(p.eat, isNotNull); // 0 nhung PHAI khac null
    });

    test('phieu chi ghi gam, khong ghi muc an ⇒ an la null, gam van cong', () {
      final p = BoxHistoryPanelState.mergeDay(
        day,
        [_rec(at: day, grams: 12.5), _rec(at: day, grams: 7.5)],
      );

      expect(p.eat, isNull); // khong suy "khong an" tu viec thieu muc
      expect(p.act, isNull);
      expect(p.grams, 20);
    });

    test('nhieu phieu trong ngay: ban ghi sau nhat thang, gam cong don', () {
      final p = BoxHistoryPanelState.mergeDay(day, [
        _rec(at: day, eat: 0, act: 0, grams: 10),
        _rec(at: day, eat: 2, act: 2, grams: 5),
      ]);

      // Thu tu do noi goi sap xep theo thoi gian tang dan ⇒ ban cuoi la moi nhat.
      expect(p.eat, 2);
      expect(p.act, 2);
      expect(p.grams, 15);
    });

    test('chi mot muc duoc ghi ⇒ muc con lai van null', () {
      final p = BoxHistoryPanelState.mergeDay(day, [_rec(at: day, eat: 1)]);

      expect(p.eat, 1);
      expect(p.act, isNull);
    });

    test('gam null khong lam hong phep cong', () {
      final p = BoxHistoryPanelState.mergeDay(
        day,
        [_rec(at: day, eat: 2), _rec(at: day, grams: 8)],
      );

      expect(p.grams, 8);
      expect(p.eat, 2);
    });
  });
}
