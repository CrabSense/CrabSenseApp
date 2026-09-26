import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/harvest_sales.dart';
import '../../services/harvest_sales_service.dart';
import '../../theme/dashboard_theme.dart';
import 'create_harvest_modal.dart';
import 'create_sale_modal.dart';

Future<void> showCreateHarvestSlipDialog(
  BuildContext context,
  HarvestSalesService service, {
  bool softshellMode = false,
  List<HarvestableCrab>? initialCrabs,
}) {
  return showCreateHarvestModal(
    context,
    service,
    softshellMode: softshellMode,
    initialCrabs: initialCrabs,
  );
}

Future<bool?> showCompleteHarvestDialog(
  BuildContext context,
  HarvestSlipDetail slip,
) {
  return showDialog<bool>(
    context: context,
    barrierColor: const Color.fromRGBO(15, 35, 30, 0.45),
    builder: (ctx) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Hoàn tất phiếu thu hoạch?',
        style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w800),
      ),
      content: Text(
        '${slip.code}\n'
        '${slip.quantity} cua\n'
        'Tổng KL thực tế: ${slip.totalWeightKg.toStringAsFixed(2)} kg\n\n'
        'Sau khi hoàn tất:\n'
        '• ${slip.quantity} cua chuyển sang Đã thu hoạch\n'
        '• Các BOX tương ứng trở thành Trống\n'
        '• Phiếu chuyển sang Chờ bán\n'
        '• Không thể chỉnh sửa tùy tiện',
        style: GoogleFonts.beVietnamPro(height: 1.5),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Hủy'),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.pop(ctx, true),
          style: FilledButton.styleFrom(backgroundColor: DashboardColors.brand),
          icon: const Icon(Icons.check_rounded, size: 16),
          label: const Text('Hoàn tất thu hoạch'),
        ),
      ],
    ),
  );
}

Future<bool?> showCancelSaleDialog(
  BuildContext context,
  SalesOrderDetail order,
) {
  return showDialog<bool>(
    context: context,
    barrierColor: const Color.fromRGBO(15, 35, 30, 0.45),
    builder: (ctx) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Hủy đơn ${order.code}?',
        style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w800),
      ),
      content: Text(
        'Cua trong đơn sẽ trở lại kho chờ bán nếu đã được ghi nhận bán.',
        style: GoogleFonts.beVietnamPro(height: 1.45),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Không'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: FilledButton.styleFrom(backgroundColor: DashboardColors.risk),
          child: const Text('Hủy đơn'),
        ),
      ],
    ),
  );
}

Future<void> showHarvestSlipDetailDialog(
  BuildContext context,
  HarvestSlipDetail slip,
) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: DashboardColors.card,
      title: Text(
        slip.code,
        style: GoogleFonts.notoSans(fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: 640,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _kv('Trạng thái', slip.statusLabel),
              _kv('Ngày giờ', slip.harvestDate),
              _kv('Người thực hiện', slip.performedBy.isEmpty ? '—' : slip.performedBy),
              _kv('Khu', slip.area),
              if (slip.note != null && slip.note!.isNotEmpty)
                _kv('Ghi chú', slip.note!),
              const SizedBox(height: 10),
              Text(
                'Danh sách cua',
                style: GoogleFonts.notoSans(fontWeight: FontWeight.w800, fontSize: 13),
              ),
              const SizedBox(height: 6),
              for (final line in slip.lines)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    '${line.crabCode.isEmpty ? '—' : line.crabCode}  ·  ${line.locationLine}\n'
                    '${line.weightG}g  ·  Loại ${line.grade.isEmpty ? '—' : line.grade}'
                    '${line.lotCode.isEmpty ? '' : '  ·  Lô ${line.lotCode}'}'
                    '${line.isSoftshell ? '  ·  Cua lột' : ''}'
                    '  ·  ${line.passed ? 'Đạt' : 'Không đạt'}',
                    style: GoogleFonts.notoSans(fontSize: 12),
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                'Tổng ${slip.quantity} con  ·  ${slip.totalWeightKg.toStringAsFixed(2)} kg  ·  '
                'TB ${slip.averageWeightG.toStringAsFixed(0)}g  ·  '
                'Đạt ${slip.passedCount}'
                '${slip.failedCount > 0 ? '  ·  Không đạt ${slip.failedCount}' : ''}',
                style: GoogleFonts.notoSans(fontWeight: FontWeight.w700, fontSize: 12),
              ),
              if (slip.photoUrls.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Ảnh thu hoạch: ${slip.photoUrls.length} tệp',
                  style: GoogleFonts.notoSans(
                    color: DashboardColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng')),
      ],
    ),
  );
}

Future<void> showCreateSalesOrderDialog(
  BuildContext context,
  HarvestSalesService service, {
  HarvestSlipDetail? fromSlip,
  List<InventoryCrab>? initialCrabs,
}) {
  return showCreateSaleModal(
    context,
    service,
    fromSlip: fromSlip,
    initialCrabs: initialCrabs,
  );
}

Future<void> showSalesOrderDetailDialog(
  BuildContext context,
  Object order, {
  HarvestSalesService? service,
}) {
  if (order is SalesOrderDetail) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => _SalesOrderDetailDialog(
        order: order,
        service: service,
      ),
    );
  }
  if (order is SalesOrder) {
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
            _kv('Khách hàng', order.customerName),
            _kv('Ngày', order.orderDate),
            _kv('Tổng', formatVnd(order.revenueVnd)),
            _kv('Trạng thái', order.status.label),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }
  return Future.value();
}


class _SalesOrderDetailDialog extends StatefulWidget {
  const _SalesOrderDetailDialog({required this.order, this.service});

  final SalesOrderDetail order;
  final HarvestSalesService? service;

  @override
  State<_SalesOrderDetailDialog> createState() => _SalesOrderDetailDialogState();
}

class _SalesOrderDetailDialogState extends State<_SalesOrderDetailDialog> {
  var _busy = false;

  Future<void> _run(Future<void> Function() action, String ok) async {
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok)));
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final service = widget.service;
    return AlertDialog(
      backgroundColor: DashboardColors.card,
      title: Text(
        'Đơn ${order.code}',
        style: GoogleFonts.notoSans(fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _kv('Trạng thái đơn', order.orderStatusLabel),
              _kv('Ngày giờ', formatHarvestDateTime(order.orderDate)),
              _kv('Người bán', order.sellerName.isEmpty ? '—' : order.sellerName),
              _kv('Khách hàng', order.customerName),
              if (order.customerPhone.isNotEmpty)
                _kv('Số điện thoại', order.customerPhone),
              if (order.customerAddress.isNotEmpty)
                _kv('Địa chỉ', order.customerAddress),
              _kv('Thanh toán', order.paymentStatusLabel),
              _kv('Phương thức', order.paymentMethodLabel),
              _kv('Giao hàng', order.deliveryStatusLabel),
              if (order.notes != null && order.notes!.isNotEmpty)
                _kv('Ghi chú', order.notes!),
              const SizedBox(height: 10),
              Text(
                'Danh sách cua',
                style: GoogleFonts.notoSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 6),
              for (final line in order.lines)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    '${line.crabCode}  ·  ${line.weightG}g  ·  ${line.typeLabel}'
                    '${line.grade.isEmpty ? '' : '  ·  Loại ${line.grade}'}\n'
                    '${formatVnd(line.unitPricePerKg)}/kg  →  ${formatVnd(line.totalVnd)}',
                    style: GoogleFonts.notoSans(fontSize: 12),
                  ),
                ),
              const SizedBox(height: 8),
              _kv('Tổng trọng lượng', '${order.totalWeightKg.toStringAsFixed(2)} kg'),
              _kv('Tạm tính', formatVnd(order.subtotalVnd)),
              if (order.discountVnd > 0) _kv('Giảm giá', formatVnd(order.discountVnd)),
              if (order.shippingVnd > 0)
                _kv('Phí vận chuyển', formatVnd(order.shippingVnd)),
              _kv('Tổng cộng', formatVnd(order.revenueVnd)),
              if (order.isPartial) _kv('Đã thu', formatVnd(order.paidVnd)),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: const Text('Đóng'),
        ),
        if (service != null && !order.isCancelled && order.isDraft)
          FilledButton(
            onPressed: _busy
                ? null
                : () => _run(
                      () => service.completeSaleOrder(order.id),
                      'Đã xác nhận bán. Cua chuyển sang Đã bán.',
                    ),
            style: FilledButton.styleFrom(backgroundColor: DashboardColors.purple),
            child: Text(_busy ? 'Đang lưu…' : 'Xác nhận bán hàng'),
          ),
        if (service != null && !order.isCancelled)
          TextButton(
            onPressed: _busy
                ? null
                : () => _run(
                      () => service.cancelSaleOrder(order.id),
                      'Đã hủy đơn. Cua trở lại kho nếu đã bán.',
                    ),
            child: const Text('Hủy đơn'),
          ),
      ],
    );
  }
}


Widget _kv(String k, String v) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              k,
              style: GoogleFonts.notoSans(
                color: DashboardColors.textMuted,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              v,
              style: GoogleFonts.notoSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
