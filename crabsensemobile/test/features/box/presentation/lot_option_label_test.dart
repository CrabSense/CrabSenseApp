import 'package:crabsensemobile/features/box/presentation/screens/crab_list_screen.dart';
import 'package:flutter_test/flutter_test.dart';

/// Nhãn lô trong phiếu nhập cua: chỉ hiện mã lô thì người nuôi không nhận ra lô nào.
void main() {
  group('lotOptionLabel', () {
    test('ghép mã lô với tên lô', () {
      expect(
        lotOptionLabel(
          (id: 'x', code: 'LOT-20260907-001', name: 'Cua Cù Mau', meta: ''),
        ),
        'LOT-20260907-001 · Cua Cù Mau',
      );
    });

    test('lô không có tên thì chỉ hiện mã', () {
      expect(
        lotOptionLabel((id: 'x', code: 'ZZ-LOT-132703', name: '', meta: '')),
        'ZZ-LOT-132703',
      );
    });
  });

  group('lotOptionMeta', () {
    test('tính số còn lại = số lượng - đã thả', () {
      expect(lotOptionMeta(24, 24, ''), 'còn 0/24');
      expect(lotOptionMeta(2, 1, ''), 'còn 1/2');
      expect(lotOptionMeta(2, 0, ''), 'còn 2/2');
    });

    test('đã thả nhiều hơn số lượng thì kẹp về 0, không ra số âm', () {
      expect(lotOptionMeta(2, 5, ''), 'còn 0/2');
    });

    test('thiếu placedCount thì coi như chưa thả con nào', () {
      expect(lotOptionMeta(10, null, ''), 'còn 10/10');
    });

    test('ghép ngày nhập dạng dd/MM', () {
      expect(
        lotOptionMeta(24, 24, '2026-09-07T17:00:00Z'),
        'còn 0/24 · 07/09',
      );
    });

    test('ngày không đọc được thì bỏ qua, không vỡ nhãn', () {
      expect(lotOptionMeta(2, 1, 'khong-phai-ngay'), 'còn 1/2');
      expect(lotOptionMeta(2, 1, ''), 'còn 1/2');
    });

    test('thiếu số lượng thì chỉ còn ngày', () {
      expect(lotOptionMeta(null, null, '2026-09-04T06:27:05Z'), '04/09');
    });

    test('thiếu hết thì trả chuỗi rỗng để UI ẩn dòng phụ', () {
      expect(lotOptionMeta(null, null, ''), '');
      expect(lotOptionMeta('abc', 'xyz', 'nope'), '');
    });
  });
}
