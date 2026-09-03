import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/feed_service.dart';
import '../../theme/dashboard_theme.dart';

const _times = ['06:00', '08:00', '12:00', '13:00', '18:00', '20:00'];
const _repeatRules = ['Hàng ngày', 'Thứ 2 – Thứ 6', 'Cuối tuần', 'Một lần'];

Future<void> showCreateFeedingScheduleDialog(
  BuildContext context,
  FeedService service,
) {
  var selectedDate = service.selectedDay;
  var time = '08:00';
  final areas = service.areas;
  final batches = service.batchCodes;
  final feeds = service.feedNames.isNotEmpty
      ? service.feedNames
      : const ['Thức ăn viên 40% đạm'];
  var area = areas.isNotEmpty ? areas.first : '';
  var batch = batches.isNotEmpty ? batches.first : '';
  var feed = feeds.isNotEmpty ? feeds.first : 'Thức ăn viên';
  var repeat = _repeatRules.first;
  final portionCtrl = TextEditingController(text: '12');

  return showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setLocal) {
        return AlertDialog(
          backgroundColor: DashboardColors.card,
          title: Text(
            'Tạo lịch cho ăn',
            style: GoogleFonts.notoSans(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Ngày: ${selectedDate.day.toString().padLeft(2, '0')}/'
                      '${selectedDate.month.toString().padLeft(2, '0')}/'
                      '${selectedDate.year}',
                      style: GoogleFonts.notoSans(fontSize: 13),
                    ),
                    trailing: const Icon(Icons.calendar_today_outlined, size: 18),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: selectedDate,
                        firstDate: DateTime(2026, 1, 1),
                        lastDate: DateTime(2027, 12, 31),
                      );
                      if (picked != null) {
                        setLocal(() => selectedDate = picked);
                      }
                    },
                  ),
                  _dropdown(
                    label: 'Giờ cho ăn',
                    value: time,
                    items: _times,
                    onChanged: (v) => setLocal(() => time = v!),
                  ),
                  if (!service.canCreateSchedule)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Trại chưa có lứa nuôi. Vào Sản xuất → Hộp/Lứa nuôi '
                        'hoặc Quản lý cua để tạo lứa trước.',
                        style: GoogleFonts.notoSans(
                          fontSize: 12,
                          color: DashboardColors.risk,
                        ),
                      ),
                    ),
                  if (areas.isNotEmpty)
                    _dropdown(
                      label: 'Khu nuôi',
                      value: area.isEmpty ? areas.first : area,
                      items: areas,
                      onChanged: (v) => setLocal(() => area = v!),
                    ),
                  if (batches.isNotEmpty)
                    _dropdown(
                      label: 'Lứa nuôi',
                      value: batch.isEmpty ? batches.first : batch,
                      items: batches,
                      onChanged: (v) => setLocal(() => batch = v!),
                    ),
                  _dropdown(
                    label: 'Loại thức ăn',
                    value: feed,
                    items: feeds,
                    onChanged: (v) => setLocal(() => feed = v!),
                  ),
                  TextField(
                    controller: portionCtrl,
                    decoration: const InputDecoration(labelText: 'Khẩu phần (kg)'),
                    keyboardType: TextInputType.number,
                  ),
                  _dropdown(
                    label: 'Lặp lại',
                    value: repeat,
                    items: _repeatRules,
                    onChanged: (v) => setLocal(() => repeat = v!),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            FilledButton(
              onPressed: service.canCreateSchedule
                  ? () async {
                      try {
                        await service.addSchedule(
                          date: selectedDate,
                          time: time,
                          area: area,
                          batchId: batch,
                          feedName: feed,
                          portionKg: double.tryParse(portionCtrl.text) ?? 12,
                          repeatRule: repeat,
                        );
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Đã tạo lịch cho ăn'),
                          ),
                        );
                      } catch (e) {
                        if (!ctx.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              service.error ?? 'Không tạo được lịch: $e',
                            ),
                            backgroundColor: DashboardColors.risk,
                          ),
                        );
                      }
                    }
                  : null,
              style: FilledButton.styleFrom(backgroundColor: DashboardColors.purple),
              child: const Text('Tạo lịch'),
            ),
          ],
        );
      },
    ),
  );
}

Widget _dropdown({
  required String label,
  required String value,
  required List<String> items,
  required ValueChanged<String?> onChanged,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(labelText: label),
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
    ),
  );
}

Future<void> showFeedImportDialog(BuildContext context, FeedService service) {
  final codeCtrl = TextEditingController(text: 'FEED-001');
  final qtyCtrl = TextEditingController(text: '50');

  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: DashboardColors.card,
      title: Text('Nhập kho', style: GoogleFonts.notoSans(fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: codeCtrl,
            decoration: const InputDecoration(labelText: 'Mã thức ăn'),
          ),
          TextField(
            controller: qtyCtrl,
            decoration: const InputDecoration(labelText: 'Số lượng (kg)'),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
        FilledButton(
          onPressed: () async {
            final kg = double.tryParse(qtyCtrl.text) ?? 0;
            await service.importStock(codeCtrl.text.trim(), kg);
            if (ctx.mounted) Navigator.pop(ctx);
          },
          style: FilledButton.styleFrom(backgroundColor: DashboardColors.purple),
          child: const Text('Lưu nhập kho'),
        ),
      ],
    ),
  );
}

Future<void> showFeedExportDialog(BuildContext context, FeedService service) {
  final codeCtrl = TextEditingController(text: 'FEED-001');
  final qtyCtrl = TextEditingController(text: '10');

  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: DashboardColors.card,
      title: Text('Xuất kho', style: GoogleFonts.notoSans(fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: codeCtrl,
            decoration: const InputDecoration(labelText: 'Mã thức ăn'),
          ),
          TextField(
            controller: qtyCtrl,
            decoration: const InputDecoration(labelText: 'Số lượng xuất (kg)'),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
        FilledButton(
          onPressed: () async {
            final kg = double.tryParse(qtyCtrl.text) ?? 0;
            await service.exportStock(codeCtrl.text.trim(), kg);
            if (ctx.mounted) Navigator.pop(ctx);
          },
          child: const Text('Xác nhận xuất'),
        ),
      ],
    ),
  );
}
