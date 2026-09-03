import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/mock_harvest_sales_data.dart';
import '../../models/harvest_sales.dart';
import '../../services/harvest_sales_service.dart';
import '../../theme/dashboard_theme.dart';

const _batches = ['CFM-2026-001', 'CFM-2026-002', 'CFM-2026-003'];
const _areas = ['Khu A', 'Khu B', 'Khu C'];

Future<void> showCreateHarvestSlipDialog(
  BuildContext context,
  HarvestSalesService service,
) {
  var batch = _batches.first;
  var area = _areas.first;
  final dateCtrl = TextEditingController(text: '24/05/2026');
  final qtyCtrl = TextEditingController(text: '850');
  final weightCtrl = TextEditingController(text: '168');
  final performerCtrl = TextEditingController(text: 'Admin Manager');
  final noteCtrl = TextEditingController();

  return showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setLocal) => AlertDialog(
        backgroundColor: DashboardColors.card,
        title: Text(
          'Tạo phiếu thu hoạch',
          style: GoogleFonts.notoSans(fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: dateCtrl,
                  decoration: const InputDecoration(labelText: 'Ngày thu hoạch'),
                ),
                _dd('Lứa nuôi', batch, _batches, (v) => setLocal(() => batch = v!)),
                _dd('Khu nuôi', area, _areas, (v) => setLocal(() => area = v!)),
                TextField(
                  controller: qtyCtrl,
                  decoration: const InputDecoration(labelText: 'Số lượng (con)'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: weightCtrl,
                  decoration: const InputDecoration(labelText: 'Tổng trọng lượng (kg)'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: performerCtrl,
                  decoration: const InputDecoration(labelText: 'Người thực hiện'),
                ),
                TextField(
                  controller: noteCtrl,
                  decoration: const InputDecoration(labelText: 'Ghi chú'),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          FilledButton(
            onPressed: () {
              service.createHarvestSlip(
                harvestDate: dateCtrl.text.trim(),
                batchId: batch,
                area: area,
                quantity: int.tryParse(qtyCtrl.text) ?? 0,
                totalWeightKg: double.tryParse(weightCtrl.text) ?? 0,
                performedBy: performerCtrl.text.trim(),
                note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
              );
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã tạo phiếu thu hoạch')),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: DashboardColors.cyan),
            child: const Text('Tạo phiếu'),
          ),
        ],
      ),
    ),
  );
}

Future<void> showSalesOrderDetailDialog(BuildContext context, SalesOrder order) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: DashboardColors.card,
      title: Text(
        'Chi tiết đơn ${order.code}',
        style: GoogleFonts.notoSans(fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _row('Khách hàng', order.customerName),
          _row('Ngày', order.orderDate),
          _row('Loại', order.productType),
          _row('Khối lượng', '${order.totalWeightKg.round()} kg'),
          _row('Giá', '${MockHarvestSalesData.formatVndFull(order.pricePerKg)}/kg'),
          _row('Tổng', MockHarvestSalesData.formatVndFull(order.revenueVnd)),
          _row('Trạng thái', order.status.label),
          _row('Lứa', order.batchId),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng')),
      ],
    ),
  );
}

Widget _row(String k, String v) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(k, style: GoogleFonts.notoSans(color: DashboardColors.textMuted, fontSize: 12)),
          ),
          Expanded(child: Text(v, style: GoogleFonts.notoSans(fontSize: 12, fontWeight: FontWeight.w600))),
        ],
      ),
    );

Widget _dd(
  String label,
  String value,
  List<String> items,
  ValueChanged<String?> onChanged,
) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
    ),
  );
}
