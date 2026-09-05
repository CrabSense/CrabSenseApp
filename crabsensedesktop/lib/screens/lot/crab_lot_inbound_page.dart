import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/crab_individual.dart';
import '../../models/crab_lot_status.dart';
import '../../models/production_models.dart';
import '../../navigation/app_route.dart';
import '../../services/crab_lot_inbound_service.dart';
import '../../services/crab_service.dart';
import '../../theme/dashboard_theme.dart';
import '../../widgets/area/area_list_toolbar.dart';
import '../../widgets/crab/crab_bulk_add_dialog.dart';
import '../../widgets/crab/crab_lot_import_dialog.dart';
import '../../widgets/crab/crab_summary_kpi.dart';
import '../../widgets/dashboard/glass_card.dart';
import '../../widgets/lot/crab_lot_inbound_table.dart';

class CrabLotInboundPage extends StatefulWidget {
  const CrabLotInboundPage({
    super.key,
    required this.service,
    required this.crabService,
    this.onNavigate,
    this.onOpenDetail,
  });

  final CrabLotInboundService service;
  final CrabService crabService;
  final void Function(AppRoute route)? onNavigate;
  final void Function(FarmingBatchRecord lot)? onOpenDetail;

  @override
  State<CrabLotInboundPage> createState() => _CrabLotInboundPageState();
}

class _CrabLotInboundPageState extends State<CrabLotInboundPage> {
  final _searchCtrl = TextEditingController();

  CrabLotInboundService get _svc => widget.service;

  @override
  void initState() {
    super.initState();
    _svc.addListener(_onUpdate);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_svc.lots.isEmpty && !_svc.loading) _svc.load();
    });
  }

  @override
  void dispose() {
    _svc.removeListener(_onUpdate);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onUpdate() => setState(() {});

  Future<void> _import() async {
    final lot = await showCrabLotImportDialog(context, widget.crabService);
    if (!mounted || lot == null) return;
    await _svc.upsert(lot);
    await widget.crabService.refreshLots();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã nhập ${lot.displayLabel}. Tiếp theo: phân cua vào hộp.')),
    );
    widget.onOpenDetail?.call(lot);
  }

  Future<void> _place(FarmingBatchRecord lot) async {
    await showCrabBulkAddDialog(
      context,
      widget.crabService,
      initialLotId: lot.id,
    );
    await _svc.load();
    await widget.crabService.load();
  }

  Future<void> _cancel(FarmingBatchRecord lot) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DashboardColors.card,
        title: Text('Hủy lô ${lot.batchCode}?', style: GoogleFonts.notoSans(color: DashboardColors.textPrimary)),
        content: Text(
          'Lô sẽ chuyển sang trạng thái Đã hủy. Cua đã thả (nếu có) vẫn giữ nguyên.',
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
    final updated = await _svc.cancel(lot.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(updated != null ? 'Đã hủy ${lot.batchCode}' : (_svc.error ?? 'Không hủy được lô'))),
    );
  }

  List<CrabSummaryKpi> _kpis() {
    final k = _svc.kpis;
    return [
      CrabSummaryKpi(
        label: 'TỔNG LÔ NHẬP',
        value: '${k.totalLots}',
        subtext: 'Phiếu nhập hàng',
        icon: Icons.inventory_2_outlined,
        accentColor: DashboardColors.oceanBlue,
      ),
      CrabSummaryKpi(
        label: 'TỔNG CUA NHẬP',
        value: _formatCount(k.totalCrabs),
        subtext: 'Số con khai báo',
        icon: Icons.set_meal_outlined,
        accentColor: DashboardColors.cyan,
      ),
      CrabSummaryKpi(
        label: 'ĐANG XỬ LÝ',
        value: '${k.inProgress}',
        subtext: 'Chờ xử lý + đang phân hộp',
        icon: Icons.timelapse,
        accentColor: DashboardColors.monitoring,
      ),
      CrabSummaryKpi(
        label: 'HOÀN TẤT',
        value: '${k.completed}',
        subtext: 'Đã phân đủ vào hộp',
        icon: Icons.check_circle_outline,
        accentColor: DashboardColors.healthy,
      ),
    ];
  }

  String _formatCount(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Breadcrumb(onNavigate: widget.onNavigate),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quản lý nhập hàng',
                      style: GoogleFonts.notoSans(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: DashboardColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Theo dõi lô cua nhập kho, tiến độ phân hộp và lịch sử nhà cung cấp.',
                      style: GoogleFonts.notoSans(
                        color: DashboardColors.textMuted,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: _import,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Nhập lô cua'),
                style: FilledButton.styleFrom(
                  backgroundColor: DashboardColors.oceanBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          CrabSummaryKpiRow(items: _kpis()),
          if (_svc.error != null) ...[
            const SizedBox(height: 12),
            Text(_svc.error!, style: GoogleFonts.notoSans(color: DashboardColors.risk, fontSize: 12)),
          ],
          const SizedBox(height: 24),
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _Toolbar(service: _svc, searchCtrl: _searchCtrl),
                const SizedBox(height: 16),
                if (_svc.loading && _svc.lots.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (!_svc.loading && _svc.filtered.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        _svc.error != null
                            ? 'Không tải được dữ liệu — thử mở lại tab'
                            : _svc.lots.isEmpty
                                ? 'Chưa có lô nhập — dùng Nhập lô cua'
                                : 'Không có lô khớp bộ lọc',
                        style: GoogleFonts.notoSans(color: DashboardColors.textMuted),
                      ),
                    ),
                  )
                else
                  CrabLotInboundTable(
                    lots: _svc.paged,
                    onAction: (lot, action) {
                      switch (action) {
                        case CrabLotInboundAction.view:
                          widget.onOpenDetail?.call(lot);
                        case CrabLotInboundAction.place:
                          _place(lot);
                        case CrabLotInboundAction.cancel:
                          _cancel(lot);
                      }
                    },
                  ),
                const SizedBox(height: 16),
                if (_svc.filtered.isNotEmpty)
                  AreaListPagination(
                    page: _svc.currentPage,
                    pageSize: _svc.pageSize,
                    itemCount: _svc.paged.length,
                    totalItems: _svc.filteredCount,
                    totalPages: _svc.totalPages,
                    onPageChanged: _svc.goToPage,
                    itemLabel: 'lô',
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Breadcrumb extends StatelessWidget {
  const _Breadcrumb({this.onNavigate});

  final void Function(AppRoute route)? onNavigate;

  @override
  Widget build(BuildContext context) {
    final link = GoogleFonts.notoSans(color: DashboardColors.oceanBlue, fontSize: 13);
    final muted = GoogleFonts.notoSans(color: DashboardColors.textMuted, fontSize: 13);
    return Wrap(
      children: [
        InkWell(onTap: () => onNavigate?.call(AppRoute.dashboard), child: Text('Dashboard', style: link)),
        Text('  >  ', style: muted),
        Text('Quản lý nhập hàng', style: muted.copyWith(color: DashboardColors.textPrimary)),
      ],
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({required this.service, required this.searchCtrl});

  final CrabLotInboundService service;
  final TextEditingController searchCtrl;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 320,
          child: TextField(
            controller: searchCtrl,
            onChanged: service.setSearch,
            style: GoogleFonts.notoSans(color: DashboardColors.textPrimary, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Tìm kiếm mã lô, tên lô hoặc nhà cung cấp...',
              hintStyle: GoogleFonts.notoSans(color: DashboardColors.textMuted, fontSize: 12),
              prefixIcon: Icon(Icons.search, size: 18, color: DashboardColors.textMuted),
              filled: true,
              fillColor: DashboardColors.darkNavy.withValues(alpha: 0.4),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ),
        _dropdown<CrabLotWorkflowStatus?>(
          label: 'Trạng thái',
          value: service.statusFilter,
          items: [
            const DropdownMenuItem(value: null, child: Text('Tất cả trạng thái')),
            for (final s in CrabLotWorkflowStatus.values)
              DropdownMenuItem(value: s, child: Text(s.label)),
          ],
          onChanged: service.setStatusFilter,
        ),
        _dropdown<CrabLotDateRange>(
          label: 'Thời gian',
          value: service.dateRange,
          items: [
            for (final r in CrabLotDateRange.values)
              DropdownMenuItem(value: r, child: Text(r.label)),
          ],
          onChanged: (v) {
            if (v != null) service.setDateRange(v);
          },
        ),
        _dropdown<String>(
          label: 'Nhà cung cấp',
          value: service.supplierFilter,
          items: [
            const DropdownMenuItem(value: '', child: Text('Tất cả NCC')),
            for (final s in service.supplierOptions)
              DropdownMenuItem(value: s, child: Text(s)),
          ],
          onChanged: (v) => service.setSupplierFilter(v ?? ''),
        ),
      ],
    );
  }

  Widget _dropdown<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 170, maxWidth: 220),
      child: DropdownButtonFormField<T>(
        key: ValueKey(value),
        isExpanded: true,
        initialValue: value,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.notoSans(fontSize: 11, color: DashboardColors.textMuted),
          filled: true,
          fillColor: DashboardColors.darkNavy.withValues(alpha: 0.4),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        dropdownColor: DashboardColors.card,
        style: GoogleFonts.notoSans(fontSize: 12, color: DashboardColors.textPrimary),
        items: items,
        onChanged: onChanged,
      ),
    );
  }
}
