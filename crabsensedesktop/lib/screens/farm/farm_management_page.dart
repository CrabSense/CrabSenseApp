import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/farm_record.dart';
import '../../services/farm_management_service.dart';
import '../../theme/dashboard_theme.dart';
import '../../widgets/farm/farm_cards.dart';
import '../../widgets/farm/farm_dialogs.dart';

class FarmManagementPage extends StatefulWidget {
  const FarmManagementPage({
    super.key,
    required this.service,
    this.onFarmsChanged,
  });

  final FarmManagementService service;
  final VoidCallback? onFarmsChanged;

  @override
  State<FarmManagementPage> createState() => _FarmManagementPageState();
}

class _FarmManagementPageState extends State<FarmManagementPage> {
  late final TextEditingController _searchCtrl;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
    widget.service.addListener(_onUpdate);
    if (widget.service.farms.isEmpty && !widget.service.loading) {
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

  @override
  Widget build(BuildContext context) {
    final svc = widget.service;
    final items = svc.pagedFarms;
    final total = svc.filteredCount;
    final start = total == 0 ? 0 : (svc.currentPage - 1) * FarmManagementService.pageSize + 1;
    final end = total == 0
        ? 0
        : ((svc.currentPage - 1) * FarmManagementService.pageSize + items.length)
            .clamp(0, total);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Quản lý khu',
            style: GoogleFonts.notoSans(
              color: DashboardColors.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _FarmToolbar(
            searchCtrl: _searchCtrl,
            service: svc,
            onAdd: svc.canManageFarms
                ? () async {
                    await showCreateFarmDialog(context, svc);
                    widget.onFarmsChanged?.call();
                  }
                : null,
            onReload: () async {
              await svc.load();
              widget.onFarmsChanged?.call();
            },
          ),
          const SizedBox(height: 20),
          if (svc.error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                svc.error!,
                style: GoogleFonts.notoSans(color: DashboardColors.risk),
              ),
            ),
          Text(
            'Danh sách khu ($total)',
            style: GoogleFonts.notoSans(
              color: DashboardColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          if (svc.loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            )
          else if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                total == 0 && svc.farms.isNotEmpty
                    ? 'Không tìm thấy khu phù hợp.'
                    : 'Chưa có khu nào.',
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSans(color: DashboardColors.textMuted),
              ),
            )
          else ...[
            _FarmCardGrid(
              farms: items,
              onEdit: (farm) async {
                await showEditFarmDialog(context, svc, farm);
                widget.onFarmsChanged?.call();
              },
              onDelete: svc.canManageFarms
                  ? (farm) async {
                      await showDeleteFarmDialog(context, svc, farm);
                      widget.onFarmsChanged?.call();
                    }
                  : null,
            ),
            const SizedBox(height: 16),
            _FarmPaginationBar(
              start: start,
              end: end,
              total: total,
              current: svc.currentPage,
              totalPages: svc.totalPages,
              onPage: svc.goToPage,
            ),
          ],
        ],
      ),
    );
  }
}

class _FarmToolbar extends StatelessWidget {
  const _FarmToolbar({
    required this.searchCtrl,
    required this.service,
    required this.onReload,
    this.onAdd,
  });

  final TextEditingController searchCtrl;
  final FarmManagementService service;
  final VoidCallback onReload;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: searchCtrl,
            onChanged: service.setSearch,
            style: GoogleFonts.notoSans(
              color: DashboardColors.textPrimary,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              hintText: 'Tìm kiếm theo tên khu, mã khu hoặc vị trí...',
              hintStyle: GoogleFonts.notoSans(
                color: DashboardColors.textMuted,
                fontSize: 13,
              ),
              prefixIcon: Icon(Icons.search, color: DashboardColors.textMuted),
              filled: true,
              fillColor: DashboardColors.card,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: DashboardColors.cardBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: DashboardColors.cardBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: DashboardColors.purple, width: 1.2),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 220,
          child: DropdownButtonFormField<String>(
            isExpanded: true,
            value: service.statusFilter?.name ?? 'all',
            dropdownColor: DashboardColors.card,
            style: GoogleFonts.notoSans(
              color: DashboardColors.textPrimary,
              fontSize: 13,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: DashboardColors.card,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: DashboardColors.cardBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: DashboardColors.cardBorder),
              ),
            ),
            items: const [
              DropdownMenuItem(value: 'all', child: Text('Tất cả')),
              DropdownMenuItem(value: 'active', child: Text('🟢 Đang hoạt động')),
              DropdownMenuItem(value: 'suspended', child: Text('🟡 Tạm ngưng')),
              DropdownMenuItem(value: 'closed', child: Text('🔴 Ngừng hoạt động')),
            ],
            onChanged: (v) {
              if (v == null || v == 'all') {
                service.setStatusFilter(null);
              } else {
                service.setStatusFilter(FarmStatus.values.byName(v));
              }
            },
          ),
        ),
        const SizedBox(width: 12),
        if (onAdd != null)
          FilledButton.icon(
            onPressed: service.loading ? null : onAdd,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Thêm khu'),
            style: FilledButton.styleFrom(
              backgroundColor: DashboardColors.purple,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            ),
          ),
        IconButton(
          onPressed: service.loading ? null : onReload,
          tooltip: 'Tải lại',
          icon: Icon(Icons.refresh, color: DashboardColors.textMuted),
        ),
      ],
    );
  }
}

class _FarmCardGrid extends StatelessWidget {
  const _FarmCardGrid({
    required this.farms,
    required this.onEdit,
    this.onDelete,
  });

  final List<FarmRecord> farms;
  final void Function(FarmRecord farm) onEdit;
  final void Function(FarmRecord farm)? onDelete;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 960 ? 3 : width >= 640 ? 2 : 1;
        final gap = 16.0;
        final cardWidth = (width - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: farms.map((farm) {
            return SizedBox(
              width: cardWidth,
              child: FarmOverviewCard(
                farm: farm,
                onOpen: () => showFarmDetailDialog(
                  context,
                  farm: farm,
                  onEdit: () => onEdit(farm),
                  onDelete: onDelete == null ? null : () => onDelete!(farm),
                ),
                onEdit: () => onEdit(farm),
                onDelete: onDelete == null ? null : () => onDelete!(farm),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _FarmPaginationBar extends StatelessWidget {
  const _FarmPaginationBar({
    required this.start,
    required this.end,
    required this.total,
    required this.current,
    required this.totalPages,
    required this.onPage,
  });

  final int start;
  final int end;
  final int total;
  final int current;
  final int totalPages;
  final ValueChanged<int> onPage;

  List<int> get _pages {
    final last = totalPages.clamp(1, 99);
    if (last <= 7) return [for (var i = 1; i <= last; i++) i];
    final set = <int>{1, last, current - 1, current, current + 1};
    return set.where((p) => p >= 1 && p <= last).toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    final pages = _pages;
    return Row(
      children: [
        Text(
          total == 0
              ? 'Không có dữ liệu'
              : 'Hiển thị $start–$end của $total khu',
          style: GoogleFonts.notoSans(
            color: DashboardColors.textMuted,
            fontSize: 13,
          ),
        ),
        const Spacer(),
        IconButton(
          tooltip: 'Trang trước',
          onPressed: current > 1 ? () => onPage(current - 1) : null,
          icon: Icon(
            Icons.chevron_left,
            color: current > 1
                ? DashboardColors.textPrimary
                : DashboardColors.textMuted.withValues(alpha: 0.4),
          ),
        ),
        for (var i = 0; i < pages.length; i++) ...[
          if (i > 0 && pages[i] - pages[i - 1] > 1)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                '…',
                style: GoogleFonts.notoSans(color: DashboardColors.textMuted),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Material(
              color: pages[i] == current
                  ? DashboardColors.purple
                  : DashboardColors.card,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                onTap: pages[i] == current ? null : () => onPage(pages[i]),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  child: Text(
                    '${pages[i]}',
                    style: GoogleFonts.notoSans(
                      color: pages[i] == current
                          ? Colors.white
                          : DashboardColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
        IconButton(
          tooltip: 'Trang sau',
          onPressed: current < totalPages ? () => onPage(current + 1) : null,
          icon: Icon(
            Icons.chevron_right,
            color: current < totalPages
                ? DashboardColors.textPrimary
                : DashboardColors.textMuted.withValues(alpha: 0.4),
          ),
        ),
      ],
    );
  }
}
