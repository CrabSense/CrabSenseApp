import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/mock_batch_data.dart';
import '../../models/farming_batch_group.dart';
import '../../models/batch_status.dart';
import '../../navigation/app_route.dart';
import '../../services/batch_management_service.dart';
import '../../services/production_management_service.dart';
import '../../theme/dashboard_theme.dart';
import '../../widgets/area/area_list_toolbar.dart';
import '../../widgets/batch/batch_summary_kpi.dart';
import '../../widgets/batch/farming_batch_form_dialog.dart';
import '../../widgets/batch/farming_batch_table.dart';
import '../../widgets/dashboard/glass_card.dart';
import '../../widgets/production/production_dialogs.dart' show confirmDelete;

class FarmingBatchManagementPage extends StatefulWidget {
  const FarmingBatchManagementPage({
    super.key,
    required this.service,
    required this.productionService,
    this.onNavigate,
    this.onOpenDetail,
  });

  final BatchManagementService service;
  final ProductionManagementService productionService;
  final void Function(AppRoute route)? onNavigate;
  final void Function(FarmingBatchGroup group)? onOpenDetail;

  @override
  State<FarmingBatchManagementPage> createState() =>
      _FarmingBatchManagementPageState();
}

class _FarmingBatchManagementPageState extends State<FarmingBatchManagementPage> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.service.addListener(_onUpdate);
    _searchCtrl.text = widget.service.search;
    if (!widget.service.loading && widget.service.items.isEmpty) {
      widget.service.load();
    }
  }

  @override
  void dispose() {
    widget.service.removeListener(_onUpdate);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onUpdate() => setState(() {});

  Future<void> _onAction(
    FarmingBatchGroup group,
    FarmingBatchAction action,
  ) async {
    final svc = widget.service;
    switch (action) {
      case FarmingBatchAction.view:
        widget.onOpenDetail?.call(group);
      case FarmingBatchAction.edit:
        await showFarmingBatchFormDialog(
          context,
          batchSvc: svc,
          prodSvc: widget.productionService,
          existing: group.primary,
        );
      case FarmingBatchAction.end:
        if (!await confirmDelete(
          context,
          title: 'Kết thúc đợt?',
          message:
              'Kết thúc ${group.batchCode} (${group.boxCount} hộp)?',
        )) {
          return;
        }
        try {
          await svc.endGroup(group);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Đã kết thúc đợt nuôi')),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$e')),
            );
          }
        }
      case FarmingBatchAction.delete:
        if (!await confirmDelete(
          context,
          title: 'Xóa đợt?',
          message: '${group.batchCode} — ${group.boxCount} hộp',
        )) {
          return;
        }
        try {
          await svc.deleteGroup(group);
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$e')),
            );
          }
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final svc = widget.service;
    final s = svc.summary;
    final kpis = [
      BatchSummaryKpi(
        label: 'Tổng số đợt',
        value: '${s.total}',
        subtext: 'Hệ thống',
        icon: Icons.layers_outlined,
        accentColor: DashboardColors.purple,
      ),
      BatchSummaryKpi(
        label: 'Đang nuôi',
        value: '${s.active}',
        subtext: 'Live Metrics',
        icon: Icons.water_drop_outlined,
        accentColor: DashboardColors.seaGreen,
      ),
      BatchSummaryKpi(
        label: 'Đã thu hoạch',
        value: '${s.harvested}',
        subtext: 'Success',
        icon: Icons.check_circle_outline,
        accentColor: DashboardColors.oceanBlue,
      ),
      BatchSummaryKpi(
        label: 'Thất bại',
        value: '${s.failed}',
        subtext: 'Cần xử lý',
        icon: Icons.warning_amber_rounded,
        accentColor: DashboardColors.risk,
      ),
    ];

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
                      'Quản lý Đợt Nuôi',
                      style: GoogleFonts.notoSans(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: DashboardColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Giám sát và tối ưu hiệu suất các đợt nuôi cua theo thời gian thực.',
                      style: GoogleFonts.notoSans(
                        color: DashboardColors.textMuted,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: svc.loading
                    ? null
                    : () => showFarmingBatchFormDialog(
                          context,
                          batchSvc: svc,
                          prodSvc: widget.productionService,
                        ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Thêm Đợt Nuôi'),
                style: FilledButton.styleFrom(
                  backgroundColor: DashboardColors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          BatchSummaryKpiRow(items: kpis),
          const SizedBox(height: 24),
          if (svc.error != null)
            Text(svc.error!, style: TextStyle(color: DashboardColors.risk)),
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _Toolbar(svc: svc, searchCtrl: _searchCtrl),
                const SizedBox(height: 16),
                if (svc.loading)
                  const Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  )
                else
                  FarmingBatchDataTable(
                    groups: svc.pagedGroups,
                    onAction: _onAction,
                  ),
                const SizedBox(height: 16),
                AreaListPagination(
                  page: svc.page,
                  pageSize: BatchManagementService.pageSize,
                  itemCount: svc.pagedGroups.length,
                  totalItems: svc.filteredGroups.length,
                  totalPages: svc.totalPages,
                  onPageChanged: svc.setPage,
                  itemLabel: 'đợt nuôi',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _InsightCards(),
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
        InkWell(onTap: () => onNavigate?.call(AppRoute.farmManagement), child: Text('Quản lý khu', style: link)),
        Text('  >  ', style: muted),
        Text('Quản lý Đợt Nuôi', style: muted.copyWith(color: DashboardColors.textPrimary)),
      ],
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({required this.svc, required this.searchCtrl});
  final BatchManagementService svc;
  final TextEditingController searchCtrl;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Wrap(
          spacing: 8,
          children: [
            for (final f in BatchStatusFilter.values)
              FilterChip(
                label: Text(f.label),
                selected: svc.statusFilter == f,
                onSelected: (_) => svc.setStatusFilter(f),
                selectedColor: DashboardColors.seaGreen.withValues(alpha: 0.2),
                checkmarkColor: DashboardColors.seaGreen,
              ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: TextField(
                controller: searchCtrl,
                onChanged: svc.setSearch,
                decoration: InputDecoration(
                  hintText: 'Tìm mã đợt, số hộp...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: DashboardColors.darkNavy,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<String?>(
                value: svc.areaFilterId,
                decoration: const InputDecoration(labelText: 'Khu'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Tất cả')),
                  ...svc.areas.map((a) => DropdownMenuItem(
                        value: a.id,
                        child: Text(a.areaCode),
                      )),
                ],
                onChanged: svc.loading ? null : svc.selectArea,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<String?>(
                value: svc.rowFilterId,
                decoration: const InputDecoration(labelText: 'Dãy'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Tất cả')),
                  ...svc.rows.map((r) => DropdownMenuItem(
                        value: r.id,
                        child: Text(r.rowCode),
                      )),
                ],
                onChanged: svc.areaFilterId == null ? null : svc.selectRow,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<String?>(
                value: svc.boxFilterId,
                decoration: const InputDecoration(labelText: 'Hộp'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Tất cả')),
                  ...svc.boxes.map((b) => DropdownMenuItem(
                        value: b.id,
                        child: Text(b.boxCode),
                      )),
                ],
                onChanged: svc.rowFilterId == null ? null : svc.selectBox,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _InsightCards extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth > 800;
        final tip = GlassCard(
          child: Row(
            children: [
              const Icon(Icons.lightbulb_outline, color: DashboardColors.cyan),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  MockBatchData.aiTip,
                  style: GoogleFonts.notoSans(
                    color: DashboardColors.textMuted,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        );
        final market = GlassCard(
          child: Row(
            children: [
              const Icon(Icons.trending_up, color: DashboardColors.purple),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  MockBatchData.marketForecast,
                  style: GoogleFonts.notoSans(
                    color: DashboardColors.textMuted,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        );
        if (!wide) {
          return Column(children: [tip, const SizedBox(height: 12), market]);
        }
        return Row(
          children: [
            Expanded(child: tip),
            const SizedBox(width: 16),
            Expanded(child: market),
          ],
        );
      },
    );
  }
}
