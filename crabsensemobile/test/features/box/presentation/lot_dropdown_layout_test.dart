import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Chặn hồi quy layout cho dropdown chọn lô trong phiếu nhập cua.
///
/// Ô đã chọn của DropdownButton chỉ cao 24px, nên nhồi Column 2 dòng vào
/// DropdownMenuItem làm tràn 15px (chỉ lộ lúc render, build vẫn xanh).
/// Cách đúng: bản 1 dòng cho ô đã chọn qua `selectedItemBuilder`,
/// bản 2 dòng chỉ dùng trong menu.
void main() {
  // Nhãn như lotOptionLabel/lotOptionMeta sinh ra, không import để test độc lập layout.
  const labels = ['LOT-20260907-001 · Cua Cù Mau', 'ZZ-LOT-132703'];
  const metas = ['còn 0/24 · 07/09', 'còn 2/2 · 04/09'];

  Widget buildDropdown({required bool withSelectedItemBuilder}) {
    final selected = <String, String>{labels[0]: metas[0], labels[1]: metas[1]};
    return MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: DropdownButtonFormField<String>(
            value: labels[0],
            isExpanded: true,
            selectedItemBuilder: withSelectedItemBuilder
                ? (_) => [
                      for (final l in labels)
                        Text(l, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ]
                : null,
            items: [
              for (final l in labels)
                DropdownMenuItem(
                  value: l,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l, maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(selected[l]!, maxLines: 1),
                    ],
                  ),
                ),
            ],
            onChanged: (_) {},
          ),
        ),
      ),
    );
  }

  testWidgets('o da chon 2 dong gay tran - day la ly do phai co ban 1 dong',
      (tester) async {
    await tester.pumpWidget(buildDropdown(withSelectedItemBuilder: false));
    await tester.pump();

    expect(
      tester.takeException(),
      isFlutterError,
      reason: 'Nếu test này fail nghĩa là Flutter đã hết giới hạn 24px — '
          'khi đó có thể bỏ selectedItemBuilder cho gọn.',
    );
  });

  testWidgets('ban 1 dong cho o da chon render sach', (tester) async {
    await tester.pumpWidget(buildDropdown(withSelectedItemBuilder: true));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text(labels[0]), findsOneWidget);
  });

  testWidgets('mo menu van hien du 2 dong cho tung lo', (tester) async {
    await tester.pumpWidget(buildDropdown(withSelectedItemBuilder: true));
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();

    // Mỗi lô 2 dòng -> cả nhãn lẫn dòng phụ đều phải có mặt trong menu.
    for (var i = 0; i < labels.length; i++) {
      expect(find.text(labels[i]), findsWidgets);
      expect(find.text(metas[i]), findsWidgets);
    }
  });
}
