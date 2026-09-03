import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/mock_crab_data.dart';
import '../../models/crab_individual.dart';
import '../../models/crab_status.dart';
import '../../navigation/app_route.dart';
import '../../services/crab_service.dart';
import '../../theme/dashboard_theme.dart';
import '../../widgets/area/area_list_toolbar.dart';
import '../../widgets/crab/crab_management_dialogs.dart';
import '../../widgets/crab/crab_management_table.dart';
import '../../widgets/crab/crab_summary_kpi.dart';
import '../../widgets/dashboard/glass_card.dart';

class CrabManagementPage extends StatefulWidget {
  const CrabManagementPage({
    super.key,
    required this.service,
    this.onNavigate,
    this.onOpenDetail,
  });

  final CrabService service;
  final void Function(AppRoute route)? onNavigate;
  final void Function(CrabIndividual crab)? onOpenDetail;

  @override
  State<CrabManagementPage> createState() => _CrabManagementPageState();
}

class _CrabManagementPageState extends State<CrabManagementPage> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.service.addListener(_onUpdate);
    _searchCtrl.text = '';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.service.crabs.isEmpty && !widget.service.loading) {
        widget.service.load();
      }
    });
  }

  @override
  void dispose() {
    widget.service.removeListener(_onUpdate);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onUpdate() => setState(() {});

  Future<void> _onAction(CrabIndividual crab, CrabManagementAction action) async {
    final svc = widget.service;
    switch (action) {
      case CrabManagementAction.view:
        widget.onOpenDetail?.call(crab);
      case CrabManagementAction.edit:
        await showCrabManagementFormDialog(context, svc, existing: crab);
      case CrabManagementAction.recordHealth:
        await showRecordHealthDialog(context, svc, crab);
      case CrabManagementAction.recordMolt:
        await showRecordMoltDialog(context, svc, crab);
      case CrabManagementAction.recordDead:
        if (!await confirmCrabAction(
          context,
          title: 'Ghi nhận chết?',
          message: 'Xác nhận cua ${crab.code} đã chết?',
          confirmLabel: 'Ghi nhận',
          danger: true,
        )) {
          return;
        }
        final ok = await svc.markDead(crab.id, cause: 'Không rõ', date: DateTime.now());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(ok ? 'Đã ghi nhận chết' : (svc.error ?? 'Lỗi')),
            ),
          );
        }
      case CrabManagementAction.recordHarvest:
        if (!await confirmCrabAction(
          context,
          title: 'Ghi nhận thu hoạch?',
          message: 'Xác nhận thu hoạch cua ${crab.code}?',
        )) {
          return;
        }
        final ok = await svc.markHarvested(crab.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(ok ? 'Đã ghi nhận thu hoạch' : (svc.error ?? 'Lỗi')),
            ),
          );
        }
      case CrabManagementAction.delete:
        if (!await confirmCrabAction(
          context,
          title: 'Xóa cua?',
          message: 'Xóa ${crab.code} khỏi hệ thống?',
          confirmLabel: 'Xóa',
          danger: true,
        )) {
          return;
        }
        final ok = await svc.deleteCrab(crab.id);
        if (mounted && ok) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã xóa cua')),
          );
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final svc = widget.service;
    final kpis = MockCrabData.managementSummaryKpis(svc.summary);

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
                      'Quản lý Cua',
                      style: GoogleFonts.notoSans(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: DashboardColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Giám sát và quản lý trạng thái từng cá thể cua trong hệ thống.',
                      style: GoogleFonts.notoSans(
                        color: DashboardColors.textMuted,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: () => showCrabManagementFormDialog(context, svc),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Thêm Cua'),
                style: FilledButton.styleFrom(
                  backgroundColor: DashboardColors.oceanBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          CrabSummaryKpiRow(items: kpis),
          if (svc.error != null) ...[
            const SizedBox(height: 12),
            Text(
              svc.error!,
              style: GoogleFonts.notoSans(color: DashboardColors.risk, fontSize: 12),
            ),
          ],
          const SizedBox(height: 24),
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _Toolbar(service: svc, searchCtrl: _searchCtrl),
                const SizedBox(height: 16),
                if (svc.loading && svc.crabs.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (!svc.loading && svc.crabs.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        svc.error != null
                            ? 'Không tải được dữ liệu — thử mở lại tab'
                            : 'Chưa có cua — dùng Thêm Cua',
                        style: GoogleFonts.notoSans(color: DashboardColors.textMuted),
                      ),
                    ),
                  )
                else
                  CrabManagementDataTable(
                  crabs: svc.paginatedCrabs,
                    onAction: _onAction,
                  ),
                const SizedBox(height: 16),
                if (svc.crabs.isNotEmpty)
                  AreaListPagination(
                  page: svc.currentPage,
                  pageSize: svc.pageSize,
                  itemCount: svc.paginatedCrabs.length,
                  totalItems: svc.filteredCount,
                  totalPages: svc.totalPages,
                  onPageChanged: svc.goToPage,
                    itemLabel: 'cua',
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
        InkWell(onTap: () => onNavigate?.call(AppRoute.farmManagement), child: Text('Quản lý Trại', style: link)),
        Text('  >  ', style: muted),
        Text('Quản lý Cua', style: muted.copyWith(color: DashboardColors.textPrimary)),
      ],
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({required this.service, required this.searchCtrl});

  final CrabService service;
  final TextEditingController searchCtrl;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 220,
              child: TextField(
                controller: searchCtrl,
                onChanged: service.setSearch,
                style: GoogleFonts.notoSans(color: DashboardColors.textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Tìm mã cua (VD: CR-1025)',
                  hintStyle: GoogleFonts.notoSans(color: DashboardColors.textMuted, fontSize: 12),
                  prefixIcon: Icon(Icons.search, size: 18, color: DashboardColors.textMuted),
                  filled: true,
                  fillColor: DashboardColors.darkNavy.withValues(alpha: 0.4),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ),
            _filterDropdown('Khu', service.areaFilter, service.areaOptions, service.setAreaFilter),
            _filterDropdown('Dãy', service.rowFilter, service.rowOptions, service.setRowFilter),
            _filterDropdown('Hộp', service.boxFilter, service.boxOptions, service.setBoxFilter),
            _filterDropdown('Lô cua', service.batchFilter, service.batchOptions, service.setBatchFilter),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: CrabManagementStatusFilter.values.map((f) {
            final selected = service.statusFilter == f;
            return FilterChip(
              label: Text(f.label),
              selected: selected,
              onSelected: (_) => service.setStatusFilter(f),
              selectedColor: DashboardColors.oceanBlue.withValues(alpha: 0.25),
              checkmarkColor: DashboardColors.oceanBlue,
              labelStyle: GoogleFonts.notoSans(
                color: selected ? DashboardColors.oceanBlue : DashboardColors.textMuted,
                fontSize: 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
              side: BorderSide(
                color: selected ? DashboardColors.oceanBlue : DashboardColors.cardBorder,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _filterDropdown(
    String label,
    String value,
    List<String> options,
    ValueChanged<String> onChanged,
  ) {
    final unique = <String>[];
    final seen = <String>{};
    for (final e in options) {
      if (seen.add(e)) unique.add(e);
    }
    if (unique.isEmpty) return const SizedBox.shrink();
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 150, maxWidth: 200),
      child: DropdownButtonFormField<String>(
        isExpanded: true,
        value: unique.contains(value) ? value : unique.first,
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
        items: unique
            .map(
              (e) => DropdownMenuItem(
                value: e,
                child: Text(e, overflow: TextOverflow.ellipsis, maxLines: 1),
              ),
            )
            .toList(),
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    );
  }
}
