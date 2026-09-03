import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/mock_batch_data.dart';
import '../../models/batch_status.dart';
import '../../models/crab_batch.dart';
import '../../services/batch_service.dart';
import '../../theme/dashboard_theme.dart';

Future<void> showCreateBatchDialog(
  BuildContext context,
  BatchService service,
) async {
  final formKey = GlobalKey<FormState>();
  final idCtrl = TextEditingController(text: service.generateNextId());
  final nameCtrl = TextEditingController();
  final sourceCtrl = TextEditingController();
  final qtyCtrl = TextEditingController();
  final weightCtrl = TextEditingController();
  final notesCtrl = TextEditingController();
  DateTime releaseDate = DateTime.now();
  String? farmArea = MockBatchData.farmAreas.first;
  String? pond = MockBatchData.ponds.first;

  await showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
      backgroundColor: DashboardColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Tạo lứa mới',
        style: GoogleFonts.notoSans(color: DashboardColors.textPrimary),
      ),
      content: SizedBox(
        width: 480,
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _sectionTitle('Thông tin cơ bản'),
                _field(idCtrl, 'Mã lứa *', validator: _required),
                _field(nameCtrl, 'Tên lứa'),
                _dateField(ctx, releaseDate, (d) {
                  releaseDate = d;
                  setDialogState(() {});
                }),
                _field(sourceCtrl, 'Nguồn giống *', validator: _required),
                const SizedBox(height: 12),
                _sectionTitle('Số lượng'),
                _field(qtyCtrl, 'Số lượng ban đầu *',
                    keyboard: TextInputType.number, validator: _required),
                _field(weightCtrl, 'Trọng lượng ban đầu (gram/con) *',
                    keyboard: TextInputType.number, validator: _required),
                const SizedBox(height: 12),
                _sectionTitle('Khu nuôi'),
                _dropdown(
                  'Khu nuôi',
                  farmArea!,
                  MockBatchData.farmAreas,
                  (v) => farmArea = v,
                ),
                const SizedBox(height: 8),
                _dropdown('Bể nuôi', pond!, MockBatchData.ponds, (v) => pond = v),
                const SizedBox(height: 12),
                _sectionTitle('Ghi chú'),
                _field(notesCtrl, 'Ghi chú', maxLines: 3),
              ],
            ),
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
            if (!formKey.currentState!.validate()) return;
            final qty = int.parse(qtyCtrl.text);
            final weight = double.parse(weightCtrl.text);
            service.addBatch(
              CrabBatch(
                id: idCtrl.text.trim(),
                name: nameCtrl.text.trim().isEmpty ? null : nameCtrl.text.trim(),
                releaseDate: releaseDate,
                initialQuantity: qty,
                aliveCount: qty,
                initialWeightGram: weight,
                avgWeightGram: weight,
                source: sourceCtrl.text.trim(),
                farmArea: farmArea,
                pond: pond,
                status: BatchStatus.raising,
                notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text,
                cycleProgress: 0.05,
              ),
            );
            Navigator.pop(ctx);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Đã tạo lứa mới thành công'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          style: FilledButton.styleFrom(backgroundColor: DashboardColors.purple),
          child: const Text('Tạo lứa'),
        ),
      ],
    ),
    ),
  );

  idCtrl.dispose();
  nameCtrl.dispose();
  sourceCtrl.dispose();
  qtyCtrl.dispose();
  weightCtrl.dispose();
  notesCtrl.dispose();
}

Future<void> showEndBatchDialog(
  BuildContext context,
  BatchService service,
  CrabBatch batch,
) async {
  final harvestCtrl = TextEditingController(text: '${batch.aliveCount}');
  final weightCtrl = TextEditingController();
  final revenueCtrl = TextEditingController();
  final costCtrl = TextEditingController();

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: DashboardColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Kết thúc lứa',
        style: GoogleFonts.notoSans(color: DashboardColors.textPrimary),
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bạn có chắc muốn kết thúc lứa ${batch.id}?',
              style: GoogleFonts.notoSans(color: DashboardColors.textMuted),
            ),
            const SizedBox(height: 16),
            _field(harvestCtrl, 'Số lượng thu hoạch'),
            _field(weightCtrl, 'Khối lượng (kg)'),
            _field(revenueCtrl, 'Doanh thu (triệu)'),
            _field(costCtrl, 'Chi phí (triệu)'),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: FilledButton.styleFrom(backgroundColor: DashboardColors.risk),
          child: const Text('Xác nhận'),
        ),
      ],
    ),
  );

  if (confirmed == true) {
    service.endBatch(
      batch.id,
      harvestQty: int.tryParse(harvestCtrl.text) ?? batch.aliveCount,
      weightKg: double.tryParse(weightCtrl.text) ?? 0,
      revenue: double.tryParse(revenueCtrl.text) ?? batch.revenueMillion,
      cost: double.tryParse(costCtrl.text) ?? 0,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã kết thúc lứa ${batch.id}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  harvestCtrl.dispose();
  weightCtrl.dispose();
  revenueCtrl.dispose();
  costCtrl.dispose();
}

Widget _sectionTitle(String t) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        t,
        style: GoogleFonts.notoSans(
          color: DashboardColors.purple,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );

Widget _field(
  TextEditingController ctrl,
  String label, {
  String? Function(String?)? validator,
  TextInputType? keyboard,
  int maxLines = 1,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextFormField(
      controller: ctrl,
      validator: validator,
      keyboardType: keyboard,
      maxLines: maxLines,
      style: GoogleFonts.notoSans(color: DashboardColors.textPrimary, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.notoSans(color: DashboardColors.textMuted, fontSize: 12),
        filled: true,
        fillColor: DashboardColors.darkNavy,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: DashboardColors.cardBorder),
        ),
      ),
    ),
  );
}

Widget _dropdown(
  String label,
  String value,
  List<String> items,
  ValueChanged<String> onChanged,
) {
  return DropdownButtonFormField<String>(
    value: value,
    dropdownColor: DashboardColors.card,
    style: GoogleFonts.notoSans(color: DashboardColors.textPrimary, fontSize: 13),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.notoSans(color: DashboardColors.textMuted, fontSize: 12),
      filled: true,
      fillColor: DashboardColors.darkNavy,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    ),
    items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
    onChanged: (v) {
      if (v != null) onChanged(v);
    },
  );
}

Widget _dateField(
  BuildContext context,
  DateTime value,
  ValueChanged<DateTime> onChanged,
) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Ngày thả *',
          labelStyle:
              GoogleFonts.notoSans(color: DashboardColors.textMuted, fontSize: 12),
          filled: true,
          fillColor: DashboardColors.darkNavy,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text(
          '${value.day}/${value.month}/${value.year}',
          style: GoogleFonts.notoSans(color: DashboardColors.textPrimary),
        ),
      ),
    ),
  );
}

String? _required(String? v) =>
    v == null || v.trim().isEmpty ? 'Bắt buộc' : null;
