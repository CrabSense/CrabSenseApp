import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/crab_lot_status.dart';
import '../../navigation/app_route.dart';
import '../../services/crab_lot_inbound_service.dart';
import '../../services/crab_service.dart';
import '../../theme/dashboard_theme.dart';
import '../../widgets/crab/crab_bulk_add_dialog.dart';
import '../../widgets/dashboard/glass_card.dart';
import '../../widgets/lot/crab_lot_status_badge.dart';

class CrabLotInboundDetailPage extends StatefulWidget {
  const CrabLotInboundDetailPage({
    super.key,
    required this.lotId,
    required this.service,
    required this.crabService,
    required this.onBack,
    this.onNavigate,
    this.onOpenCrab,
  });

  final String lotId;
  final CrabLotInboundService service;
  final CrabService crabService;
  final VoidCallback onBack;
  final void Function(AppRoute route)? onNavigate;
  final void Function(String crabId)? onOpenCrab;

  @override
  State<CrabLotInboundDetailPage> createState() => _CrabLotInboundDetailPageState();
}

class _CrabLotInboundDetailPageState extends State<CrabLotInboundDetailPage> {
  var _loading = false;

  @override
  void initState() {
    super.initState();
    widget.service.addListener(_rebuild);
    widget.crabService.addListener(_rebuild);
    _refresh();
  }

  @override
  void dispose() {
    widget.service.removeListener(_rebuild);
    widget.crabService.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() => setState(() {});

  Future<void> _refresh() async {
    setState(() => _loading = true);
    await widget.service.refreshOne(widget.lotId);
    if (widget.crabService.crabs.isEmpty) {
      await widget.crabService.load();
    }
    if (mounted) setState(() => _loading = false);
  }

  String _date(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$dd/$mm/${d.year}';
  }

  String _vnd(double? v) {
    if (v == null) return '—';
    final s = v.round().abs().toString();
    final buf = StringBuffer();
    if (v < 0) buf.write('-');
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return '$buf VNĐ';
  }

  Future<void> _place() async {
    await showCrabBulkAddDialog(
      context,
      widget.crabService,
      initialLotId: widget.lotId,
    );
    await _refresh();
  }

  Future<void> _cancel() async {
    final lot = widget.service.findById(widget.lotId);
    if (lot == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DashboardColors.card,
        title: Text('Hủy lô ${lot.batchCode}?', style: GoogleFonts.notoSans(color: DashboardColors.textPrimary)),
        content: Text(
          'Lô sẽ chuyển sang Đã hủy.',
          style: GoogleFonts.notoSans(color: DashboardColors.textMuted),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Không')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: DashboardColors.risk),
            child: const Text('Hủy lô'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await widget.service.cancel(widget.lotId);
  }

  @override
  Widget build(BuildContext context) {
    final lot = widget.service.findById(widget.lotId);
    if (lot == null) {
      return Center(
        child: _loading
            ? const CircularProgressIndicator()
            : Text('Không tìm thấy lô', style: GoogleFonts.notoSans(color: DashboardColors.textMuted)),
      );
    }

    final placed = lot.placedCount;
    final qty = lot.initialQuantity <= 0 ? 1 : lot.initialQuantity;
    final progress = (placed / qty).clamp(0.0, 1.0);
    final crabs = widget.crabService.crabsInLot(lotId: lot.id, lotCode: lot.batchCode);
    final canAct = lot.workflowStatus != CrabLotWorkflowStatus.cancelled &&
        lot.workflowStatus != CrabLotWorkflowStatus.completed;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            children: [
              InkWell(
                onTap: () => widget.onNavigate?.call(AppRoute.dashboard),
                child: Text('Dashboard', style: GoogleFonts.notoSans(color: DashboardColors.oceanBlue, fontSize: 13)),
              ),
              Text('  >  ', style: GoogleFonts.notoSans(color: DashboardColors.textMuted, fontSize: 13)),
              InkWell(
                onTap: widget.onBack,
                child: Text('Quản lý nhập hàng', style: GoogleFonts.notoSans(color: DashboardColors.oceanBlue, fontSize: 13)),
              ),
              Text('  >  ', style: GoogleFonts.notoSans(color: DashboardColors.textMuted, fontSize: 13)),
              Text(lot.batchCode, style: GoogleFonts.notoSans(color: DashboardColors.textPrimary, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              IconButton(onPressed: widget.onBack, icon: const Icon(Icons.arrow_back)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lot.name?.trim().isNotEmpty == true ? lot.name! : lot.batchCode,
                      style: GoogleFonts.notoSans(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: DashboardColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(lot.batchCode, style: GoogleFonts.notoSans(color: DashboardColors.textMuted, fontSize: 14)),
                  ],
                ),
              ),
              CrabLotStatusBadge(status: lot.workflowStatus),
              const SizedBox(width: 12),
              if (_loading)
                const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
              else
                IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
              if (canAct) ...[
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _cancel,
                  style: OutlinedButton.styleFrom(foregroundColor: DashboardColors.risk),
                  child: const Text('Hủy lô'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _place,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Phân cua vào hộp'),
                  style: FilledButton.styleFrom(backgroundColor: DashboardColors.oceanBlue),
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tiến độ phân hộp  $placed / ${lot.initialQuantity} con',
                  style: GoogleFonts.notoSans(
                    color: DashboardColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: DashboardColors.cardBorder,
                    valueColor: AlwaysStoppedAnimation(lot.workflowStatus.color),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, c) {
              final two = c.maxWidth > 720;
              final info = GlassCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _section('Thông tin lô'),
                    _kv('Ngày nhập', _date(lot.startDate)),
                    _kv('Số lượng nhập', '${lot.initialQuantity} con'),
                    _kv('Đã phân hộp', '$placed con'),
                    _kv('Tổng trọng lượng', lot.totalWeightKg == null ? '—' : '${lot.totalWeightKg} kg'),
                    _kv('TB / con', lot.averageWeightGram == null ? '—' : '${lot.averageWeightGram!.toStringAsFixed(0)} g'),
                    _kv(
                      'Khoảng trọng lượng',
                      lot.weightMinGram == null && lot.weightMaxGram == null
                          ? '—'
                          : '${lot.weightMinGram?.toStringAsFixed(0) ?? '—'} – ${lot.weightMaxGram?.toStringAsFixed(0) ?? '—'} g',
                    ),
                    _kv('Nhà cung cấp', lot.supplierName?.trim().isNotEmpty == true ? lot.supplierName! : '—'),
                    _kv('Tình trạng lúc nhập', _conditionLabel(lot.condition)),
                    _kv('Chết khi nhập', '${lot.deadOnArrival} con'),
                    if (lot.notes?.trim().isNotEmpty == true) _kv('Ghi chú', lot.notes!),
                  ],
                ),
              );
              final cost = GlassCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _section('Chi phí nhập'),
                    _kv('Giá / kg', _vnd(lot.unitPriceVndPerKg)),
                    _kv('Tiền cua', _vnd(lot.crabCostVnd)),
                    _kv('Vận chuyển', _vnd(lot.shippingCostVnd)),
                    _kv('Chi phí khác', _vnd(lot.otherCostVnd)),
                    const SizedBox(height: 8),
                    _kv('Tổng chi phí', _vnd(lot.totalCostVnd), emphasize: true),
                  ],
                ),
              );
              if (!two) return Column(children: [info, const SizedBox(height: 16), cost]);
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: info),
                  const SizedBox(width: 16),
                  Expanded(flex: 2, child: cost),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _section('Cua đã phân vào hộp'),
                if (crabs.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'Chưa có cua thuộc lô này. Dùng Phân cua vào hộp để bắt đầu theo dõi.',
                      style: GoogleFonts.notoSans(color: DashboardColors.textMuted),
                    ),
                  )
                else
                  ...crabs.map(
                    (c) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        c.code,
                        style: GoogleFonts.notoSans(
                          color: DashboardColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        '${c.areaName} · ${c.rowName} · ${c.boxName ?? c.boxId}',
                        style: GoogleFonts.notoSans(color: DashboardColors.textMuted, fontSize: 12),
                      ),
                      trailing: Text(
                        '${c.weightGram.toStringAsFixed(0)} g',
                        style: GoogleFonts.notoSans(color: DashboardColors.textPrimary),
                      ),
                      onTap: widget.onOpenCrab == null ? null : () => widget.onOpenCrab!(c.id),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _conditionLabel(String raw) {
    switch (raw.toLowerCase()) {
      case 'average':
        return 'Trung bình';
      case 'problem':
        return 'Có vấn đề';
      default:
        return 'Tốt';
    }
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.notoSans(
          color: DashboardColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _kv(String k, String v, {bool emphasize = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(k, style: GoogleFonts.notoSans(color: DashboardColors.textMuted, fontSize: 13)),
          ),
          Expanded(
            child: Text(
              v,
              style: GoogleFonts.notoSans(
                color: DashboardColors.textPrimary,
                fontSize: emphasize ? 15 : 13,
                fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
