import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/mock_farm_activity_log_data.dart';
import '../../services/farm_log_service.dart';
import '../../theme/dashboard_theme.dart';

Future<void> showAddFarmLogDialog(
  BuildContext context,
  FarmLogService service,
) async {
  final typeCtrl = TextEditingController();
  final performerCtrl = TextEditingController(text: 'Nguyễn Văn A');
  final areaCtrl = TextEditingController(text: 'Khu A');
  final batchCtrl = TextEditingController();
  final crabCtrl = TextEditingController();
  final contentCtrl = TextEditingController();
  final noteCtrl = TextEditingController();
  String selectedType = MockFarmActivityLogData.logTypeOptions.first;

  await showDialog<void>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setLocal) {
          return AlertDialog(
            backgroundColor: DashboardColors.card,
            title: Text(
              'Thêm Nhật Ký',
              style: GoogleFonts.notoSans(fontWeight: FontWeight.bold),
            ),
            content: SizedBox(
              width: 480,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _field(
                      'Loại thao tác',
                      DropdownButtonFormField<String>(
                        value: selectedType,
                        dropdownColor: DashboardColors.card,
                        items: MockFarmActivityLogData.logTypeOptions
                            .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) setLocal(() => selectedType = v);
                        },
                      ),
                    ),
                    _field('Người thực hiện', TextField(controller: performerCtrl)),
                    _field('Khu vực', TextField(controller: areaCtrl)),
                    _field('Lứa nuôi', TextField(controller: batchCtrl)),
                    _field('Mã cua', TextField(controller: crabCtrl)),
                    _field('Nội dung', TextField(controller: contentCtrl, maxLines: 3)),
                    _field('Ghi chú', TextField(controller: noteCtrl, maxLines: 2)),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.upload_file, size: 18),
                      label: const Text('Ảnh đính kèm'),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Hủy'),
              ),
              FilledButton(
                onPressed: () {
                  if (contentCtrl.text.trim().isEmpty) return;
                  service.addEntry(
                    typeLabel: selectedType,
                    performer: performerCtrl.text.trim(),
                    area: areaCtrl.text.trim(),
                    content: contentCtrl.text.trim(),
                    batchId: batchCtrl.text.trim(),
                    crabId: crabCtrl.text.trim(),
                    note: noteCtrl.text.trim(),
                  );
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã lưu nhật ký')),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: DashboardColors.purple,
                ),
                child: const Text('Lưu nhật ký'),
              ),
            ],
          );
        },
      );
    },
  );

  typeCtrl.dispose();
  performerCtrl.dispose();
  areaCtrl.dispose();
  batchCtrl.dispose();
  crabCtrl.dispose();
  contentCtrl.dispose();
  noteCtrl.dispose();
}

Widget _field(String label, Widget child) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.notoSans(
            color: DashboardColors.textMuted,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        child,
      ],
    ),
  );
}
