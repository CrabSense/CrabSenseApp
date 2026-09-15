import 'package:flutter_test/flutter_test.dart';
import 'package:crabsensemobile/features/box_management/domain/models/boxes_models.dart';

/// Lưới vẽ theo thứ tự đọc (trái→phải, trên→xuống). Test mô phỏng đúng cách
/// GridView tiêu thụ danh sách rồi kiểm tra số hộp tăng theo hướng đã chọn.
List<List<String>> _render(List<String> out, int columns) {
  final rows = <List<String>>[];
  for (var i = 0; i < out.length; i += columns) {
    final end = i + columns > out.length ? out.length : i + columns;
    rows.add(out.sublist(i, end));
  }
  return rows;
}

void main() {
  // 7 hộp, 4 cột → dòng cuối thiếu ô (đúng ca khó của lưới thật).
  final boxes = [for (var i = 1; i <= 7; i++) 'BOX-${i.toString().padLeft(4, '0')}'];

  test('rowLtr giữ nguyên thứ tự', () {
    expect(applyBoxLayoutOrder(boxes, BoxLayoutOrder.rowLtr, 4), boxes);
  });

  test('rowRtl đảo từng dòng, vẫn xuống dòng theo dòng', () {
    final out = applyBoxLayoutOrder(boxes, BoxLayoutOrder.rowRtl, 4);
    expect(_render(out, 4), [
      ['BOX-0004', 'BOX-0003', 'BOX-0002', 'BOX-0001'],
      ['BOX-0007', 'BOX-0006', 'BOX-0005'],
    ]);
  });

  test('columnLtr: đọc dọc trên→xuống, cột trái→phải', () {
    final out = applyBoxLayoutOrder(boxes, BoxLayoutOrder.columnLtr, 4);
    // 2 dòng: cột 0 = 1,2; cột 1 = 3,4; cột 2 = 5,6; cột 3 = 7.
    expect(_render(out, 4), [
      ['BOX-0001', 'BOX-0003', 'BOX-0005', 'BOX-0007'],
      ['BOX-0002', 'BOX-0004', 'BOX-0006'],
    ]);
  });

  test('columnRtl: đọc dọc trên→xuống, cột phải→trái', () {
    final out = applyBoxLayoutOrder(boxes, BoxLayoutOrder.columnRtl, 4);
    // Cột 3 (phải nhất) chỉ có 1 ô: 1. Cột 2: 2,3. Cột 1: 4,5. Cột 0: 6,7.
    expect(_render(out, 4), [
      ['BOX-0006', 'BOX-0004', 'BOX-0002', 'BOX-0001'],
      ['BOX-0007', 'BOX-0005', 'BOX-0003'],
    ]);
  });

  test('mọi hướng đều giữ đủ phần tử', () {
    for (final order in BoxLayoutOrder.values) {
      final out = applyBoxLayoutOrder(boxes, order, 4);
      expect(out.length, boxes.length, reason: '$order');
      expect(out.toSet(), boxes.toSet(), reason: '$order');
    }
  });
}
