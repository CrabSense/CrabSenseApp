import 'package:flutter/material.dart';

import '../../models/harvest_sales.dart';
import '../../services/harvest_sales_service.dart';
import '../../theme/dashboard_theme.dart';
import '../shared/mgmt_ui.dart';

const _kBlue = Color(0xFF2495E8);
const _kAmber = Color(0xFFF5B700);
const _kRed = Color(0xFFEF4444);

String harvestStatusFilterLabel(HarvestUiStatus? s) => s == null
    ? 'Tất cả'
    : harvestUiStatusLabel(s);

String harvestProductFilterLabel(HarvestProductType t) => switch (t) {
      HarvestProductType.all => 'Tất cả',
      HarvestProductType.meat => 'Cua thịt',
      HarvestProductType.softshell => 'Cua lột',
      HarvestProductType.other => 'Khác',
    };

String harvestTimeLabel(HarvestTimeRange t) => switch (t) {
      HarvestTimeRange.today => 'Hôm nay',
      HarvestTimeRange.d7 => '7 ngày qua',
      HarvestTimeRange.d30 => '30 ngày qua',
      HarvestTimeRange.all => 'Tất cả',
    };

String harvestSortLabel(HarvestSlipSort s) => switch (s) {
      HarvestSlipSort.newest => 'Mới nhất trước',
      HarvestSlipSort.oldest => 'Cũ nhất trước',
      HarvestSlipSort.mostCrabs => 'Nhiều cua nhất',
      HarvestSlipSort.mostWeight => 'Nặng nhất',
    };

String harvestEligibilityLabel(HarvestEligibility e) => switch (e) {
      HarvestEligibility.eligible => 'Đạt điều kiện',
      HarvestEligibility.monitoring => 'Cần xem xét',
      HarvestEligibility.notEligible => 'Không đủ điều kiện',
    };

Color harvestEligibilityColor(HarvestEligibility e) => switch (e) {
      HarvestEligibility.eligible => DashboardColors.brand,
      HarvestEligibility.monitoring => _kAmber,
      HarvestEligibility.notEligible => _kRed,
    };

class HarvestKpiRow extends StatelessWidget {
  const HarvestKpiRow({
    super.key,
    required this.kpi,
    required this.loading,
    required this.onTap,
  });

  final HarvestKpi kpi;
  final bool loading;
  final ValueChanged<HarvestKpiFocus> onTap;

  @override
  Widget build(BuildContext context) {
    final cards = [
      (
        HarvestKpiFocus.harvestable,
        Icons.set_meal_outlined,
        'Cua có thể thu hoạch',
        '${kpi.harvestable}',
        'con',
        DashboardColors.brand,
      ),
      (
        HarvestKpiFocus.softshell,
        Icons.water_drop_outlined,
        'Cua lột chờ xuất',
        '${kpi.softshellWaiting}',
        'con',
        _kBlue,
      ),
      (
        HarvestKpiFocus.harvestedToday,
        Icons.event_available_outlined,
        'Đã thu hoạch hôm nay',
        '${kpi.harvestedToday}',
        'con',
        DashboardColors.brandGreen,
      ),
      (
        HarvestKpiFocus.waitingSale,
        Icons.shopping_cart_outlined,
        'Chờ bán',
        '${kpi.waitingSale}',
        'con',
        _kAmber,
      ),
    ];
    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth >= 1100;
        final weight = _KpiTap(
          onTap: () => onTap(HarvestKpiFocus.harvestedToday),
          child: loading
              ? const _KpiSkeleton()
              : MgmtKpiCard(
                  icon: Icons.monitor_weight_outlined,
                  label: 'Tổng trọng lượng hôm nay',
                  value: kpi.totalWeightKg.toStringAsFixed(2),
                  suffix: 'kg',
                  color: DashboardColors.brand,
                ),
        );
        final children = [
          for (final e in cards)
            Expanded(
              child: _KpiTap(
                onTap: () => onTap(e.$1),
                child: loading
                    ? const _KpiSkeleton()
                    : MgmtKpiCard(
                        icon: e.$2,
                        label: e.$3,
                        value: e.$4,
                        suffix: e.$5,
                        color: e.$6,
                      ),
              ),
            ),
          Expanded(child: weight),
        ];
        if (wide) {
          return Row(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const SizedBox(width: 12),
                children[i],
              ],
            ],
          );
        }
        return Column(
          children: [
            Row(
              children: [
                children[0],
                const SizedBox(width: 12),
                children[1],
                const SizedBox(width: 12),
                children[2],
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                children[3],
                const SizedBox(width: 12),
                children[4],
              ],
            ),
          ],
        );
      },
    );
  }
}

class _KpiTap extends StatelessWidget {
  const _KpiTap({required this.onTap, required this.child});
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: child,
      ),
    );
  }
}

class _KpiSkeleton extends StatelessWidget {
  const _KpiSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 78,
      decoration: mgmtCardDeco(),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: DashboardColors.mint,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(height: 10, width: 90, color: DashboardColors.mint),
                const SizedBox(height: 8),
                Container(height: 16, width: 48, color: DashboardColors.lightMint),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class HarvestFilterToolbar extends StatelessWidget {
  const HarvestFilterToolbar({
    super.key,
    required this.search,
    required this.service,
    required this.onCreate,
    required this.onClearSearch,
    this.onExport,
  });

  final TextEditingController search;
  final HarvestSalesService service;
  final VoidCallback onCreate;
  final VoidCallback onClearSearch;
  final VoidCallback? onExport;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: mgmtCardDeco(radius: 16),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 280,
            child: MgmtSearchField(
              controller: search,
              onChanged: (_) {},
              hint: 'Tìm mã phiếu, mã cua...',
            ),
          ),
          MgmtDropdown<String?>(
            width: 200,
            valueLabel: service.areaFilterId == null
                ? service.areaName
                : (service.areaOptions
                        .where((a) => a.id == service.areaFilterId)
                        .map((a) => a.label)
                        .firstOrNull ??
                    service.areaName),
            items: [
              (null, service.areaName),
              for (final a in service.areaOptions) (a.id, a.label),
            ],
            onSelected: service.setAreaFilter,
          ),
          MgmtDropdown<HarvestUiStatus?>(
            width: 180,
            valueLabel: harvestStatusFilterLabel(service.statusFilter),
            items: [
              (null, 'Tất cả'),
              (HarvestUiStatus.draft, 'Nháp'),
              (HarvestUiStatus.pending, 'Chờ thực hiện'),
              (HarvestUiStatus.inProgress, 'Đang thực hiện'),
              (HarvestUiStatus.completed, 'Hoàn thành'),
              (HarvestUiStatus.waitingSale, 'Chờ bán'),
              (HarvestUiStatus.transferred, 'Đã chuyển bán hàng'),
              (HarvestUiStatus.cancelled, 'Đã hủy'),
            ],
            onSelected: service.setStatusFilter,
          ),
          MgmtDropdown<HarvestProductType>(
            width: 160,
            valueLabel: harvestProductFilterLabel(service.productFilter),
            items: [
              (HarvestProductType.all, 'Tất cả'),
              (HarvestProductType.meat, 'Cua thịt'),
              (HarvestProductType.softshell, 'Cua lột'),
              (HarvestProductType.other, 'Khác'),
            ],
            onSelected: service.setProductFilter,
          ),
          MgmtDropdown<HarvestTimeRange>(
            width: 160,
            leading: Icons.calendar_today_outlined,
            valueLabel: harvestTimeLabel(service.timeRange),
            items: [
              (HarvestTimeRange.today, 'Hôm nay'),
              (HarvestTimeRange.d7, '7 ngày qua'),
              (HarvestTimeRange.d30, '30 ngày qua'),
              (HarvestTimeRange.all, 'Tất cả'),
            ],
            onSelected: service.setTimeRange,
          ),
          MgmtOutlineButton(
            label: 'Xóa lọc',
            icon: Icons.filter_alt_off_outlined,
            onTap: () {
              search.clear();
              onClearSearch();
              service.clearFilters();
            },
          ),
          if (onExport != null)
            MgmtOutlineButton(
              label: 'Xuất dữ liệu',
              icon: Icons.download_outlined,
              onTap: onExport,
            ),
          MgmtPrimaryButton(
            icon: Icons.add_rounded,
            label: 'Tạo phiếu thu hoạch',
            onTap: onCreate,
          ),
        ],
      ),
    );
  }
}

class ReadyToHarvestSection extends StatelessWidget {
  const ReadyToHarvestSection({
    super.key,
    required this.service,
    required this.selected,
    required this.showAll,
    required this.onToggleShowAll,
    required this.onToggle,
    required this.onViewCrab,
  });

  final HarvestSalesService service;
  final Set<String> selected;
  final bool showAll;
  final VoidCallback onToggleShowAll;
  final void Function(HarvestableCrab crab, bool value) onToggle;
  final ValueChanged<HarvestableCrab>? onViewCrab;

  @override
  Widget build(BuildContext context) {
    final count = service.harvestKpi.harvestable;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: mgmtCardDeco(radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'Cua sẵn sàng thu hoạch ($count)',
                style: bvText(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: DashboardColors.textPrimary,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: onToggleShowAll,
                child: Text(
                  showAll ? 'Thu gọn' : 'Xem tất cả →',
                  style: bvText(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: DashboardColors.brand,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (service.readyError != null)
            _SectionError(
              message: 'Không thể tải danh sách cua sẵn sàng thu hoạch.',
              onRetry: service.reloadReady,
            )
          else if (service.readyLoading)
            const _ReadySkeleton()
          else if (service.readyCrabs.isEmpty)
            MgmtEmptyState(
              icon: Icons.set_meal_outlined,
              title: 'Chưa có cua sẵn sàng thu hoạch',
              message: 'Các cua đạt điều kiện sẽ xuất hiện tại đây.',
            )
          else
            _ReadyGrid(
              crabs: showAll
                  ? service.readyCrabs
                  : service.readyCrabs.take(8).toList(),
              selected: selected,
              onToggle: onToggle,
              onViewCrab: onViewCrab,
            ),
        ],
      ),
    );
  }
}

class _ReadyGrid extends StatelessWidget {
  const _ReadyGrid({
    required this.crabs,
    required this.selected,
    required this.onToggle,
    required this.onViewCrab,
  });

  final List<HarvestableCrab> crabs;
  final Set<String> selected;
  final void Function(HarvestableCrab crab, bool value) onToggle;
  final ValueChanged<HarvestableCrab>? onViewCrab;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final cols = c.maxWidth >= 1100
            ? 4
            : c.maxWidth >= 720
                ? 2
                : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: crabs.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: cols == 1 ? 2.4 : 1.85,
          ),
          itemBuilder: (_, i) => HarvestReadyCrabCard(
            crab: crabs[i],
            selected: selected.contains(crabs[i].id),
            onToggle: onToggle,
            onView: onViewCrab,
          ),
        );
      },
    );
  }
}

class HarvestReadyCrabCard extends StatelessWidget {
  const HarvestReadyCrabCard({
    super.key,
    required this.crab,
    required this.selected,
    required this.onToggle,
    this.onView,
  });

  final HarvestableCrab crab;
  final bool selected;
  final void Function(HarvestableCrab crab, bool value) onToggle;
  final ValueChanged<HarvestableCrab>? onView;

  @override
  Widget build(BuildContext context) {
    final healthColor = crab.eligibility == HarvestEligibility.monitoring
        ? _kAmber
        : crab.eligibility == HarvestEligibility.notEligible
            ? _kRed
            : DashboardColors.brand;
    final size = crab.widthMm != null && crab.lengthMm != null
        ? '${crab.widthMm!.round()} × ${crab.lengthMm!.round()} mm'
        : null;
    final card = Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: selected ? DashboardColors.lightMint : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected ? DashboardColors.brand.withValues(alpha: 0.35) : DashboardColors.cardBorder,
        ),
      ),
      child: Row(
        children: [
          Tooltip(
            message: crab.canSelect ? 'Chọn để tạo phiếu' : crab.disableReason,
            child: Checkbox(
              value: selected,
              onChanged: crab.canSelect
                  ? (v) => onToggle(crab, v == true)
                  : null,
              activeColor: DashboardColors.brand,
              visualDensity: VisualDensity.compact,
            ),
          ),
          _CrabThumb(url: crab.imageUrl),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  crab.code,
                  style: bvText(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: DashboardColors.textPrimary,
                  ),
                ),
                Text(
                  '${crab.boxCode.isEmpty ? '—' : crab.boxCode} • ${crab.weightG} g',
                  style: bvText(fontSize: 12, color: DashboardColors.textMuted),
                ),
                if (size != null)
                  Text(size, style: bvText(fontSize: 12, color: DashboardColors.textMuted)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(color: healthColor, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        crab.condition,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: bvText(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: healthColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                _EligibilityBadge(eligibility: crab.eligibility),
              ],
            ),
          ),
        ],
      ),
    );
    if (onView == null) return card;
    return InkWell(
      onTap: () => onView!(crab),
      borderRadius: BorderRadius.circular(14),
      child: card,
    );
  }
}

class _EligibilityBadge extends StatelessWidget {
  const _EligibilityBadge({required this.eligibility});
  final HarvestEligibility eligibility;

  @override
  Widget build(BuildContext context) {
    final color = harvestEligibilityColor(eligibility);
    final icon = switch (eligibility) {
      HarvestEligibility.eligible => Icons.check_rounded,
      HarvestEligibility.monitoring => Icons.warning_amber_rounded,
      HarvestEligibility.notEligible => Icons.close_rounded,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
          Text(
            harvestEligibilityLabel(eligibility),
            style: bvText(fontSize: 11, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }
}

class _CrabThumb extends StatelessWidget {
  const _CrabThumb({this.url, this.size = 52});
  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: size,
        height: size,
        color: DashboardColors.lightMint,
        child: url == null || url!.isEmpty
            ? Icon(Icons.set_meal_outlined, color: DashboardColors.brandGreen, size: size * 0.45)
            : Image.network(
                url!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) => Icon(
                  Icons.set_meal_outlined,
                  color: DashboardColors.brandGreen,
                  size: size * 0.45,
                ),
              ),
      ),
    );
  }
}

class HarvestSelectionBar extends StatelessWidget {
  const HarvestSelectionBar({
    super.key,
    required this.crabs,
    required this.onCreate,
    required this.onClear,
  });

  final List<HarvestableCrab> crabs;
  final VoidCallback onCreate;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final grams = crabs.fold<int>(0, (s, c) => s + c.weightG);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: DashboardColors.mint,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DashboardColors.brand.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: DashboardColors.brand, size: 20),
          const SizedBox(width: 8),
          Text(
            'Đã chọn ${crabs.length} cua',
            style: bvText(fontWeight: FontWeight.w800, color: DashboardColors.textPrimary),
          ),
          const SizedBox(width: 16),
          Text(
            'Tổng trọng lượng dự kiến: $grams g',
            style: bvText(color: DashboardColors.textMuted),
          ),
          const Spacer(),
          TextButton(onPressed: onClear, child: const Text('Bỏ chọn')),
          const SizedBox(width: 8),
          MgmtPrimaryButton(
            icon: Icons.add_rounded,
            label: 'Tạo phiếu thu hoạch từ ${crabs.length} cua',
            onTap: onCreate,
          ),
        ],
      ),
    );
  }
}

class HarvestSlipTable extends StatelessWidget {
  const HarvestSlipTable({
    super.key,
    required this.service,
    required this.selectedId,
    required this.onSelect,
    required this.onAction,
    required this.rowSelected,
    required this.onToggleRow,
    required this.onToggleAll,
  });

  final HarvestSalesService service;
  final String? selectedId;
  final ValueChanged<HarvestSlipDetail> onSelect;
  final void Function(HarvestSlipDetail slip, HarvestRowAction action) onAction;
  final Set<String> rowSelected;
  final void Function(HarvestSlipDetail slip, bool value) onToggleRow;
  final ValueChanged<bool> onToggleAll;

  @override
  Widget build(BuildContext context) {
    final rows = service.pagedHarvests;
    final allOnPage = rows.isNotEmpty && rows.every((r) => rowSelected.contains(r.id));
    return Container(
      decoration: mgmtCardDeco(radius: 16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Text(
                  'Danh sách phiếu thu hoạch (${service.filteredHarvestCount})',
                  style: bvText(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: DashboardColors.textPrimary,
                  ),
                ),
                const Spacer(),
                MgmtInlineSort<HarvestSlipSort>(
                  value: service.sort,
                  items: [
                    (HarvestSlipSort.newest, 'Mới nhất trước'),
                    (HarvestSlipSort.oldest, 'Cũ nhất trước'),
                    (HarvestSlipSort.mostCrabs, 'Nhiều cua nhất'),
                    (HarvestSlipSort.mostWeight, 'Nặng nhất'),
                  ],
                  onChanged: service.setSort,
                ),
              ],
            ),
          ),
          if (service.harvestsError != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: _SectionError(
                message: 'Không thể tải danh sách phiếu.',
                onRetry: service.reloadHarvests,
              ),
            )
          else if (service.harvestsLoading)
            const _TableSkeleton()
          else if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: MgmtEmptyState(
                icon: Icons.assignment_outlined,
                title: 'Chưa có phiếu thu hoạch',
                message: 'Tạo phiếu đầu tiên khi có cua đạt điều kiện.',
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 980),
                child: DataTable(
                  headingRowHeight: 42,
                  dataRowMinHeight: 52,
                  dataRowMaxHeight: 64,
                  headingTextStyle: bvText(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: DashboardColors.textMuted,
                    letterSpacing: 0.3,
                  ),
                  columns: [
                    DataColumn(
                      label: Checkbox(
                        value: allOnPage,
                        onChanged: (v) => onToggleAll(v == true),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    const DataColumn(label: Text('MÃ PHIẾU')),
                    const DataColumn(label: Text('THỜI GIAN')),
                    const DataColumn(label: Text('KHU VỰC')),
                    const DataColumn(label: Text('SỐ CUA')),
                    const DataColumn(label: Text('TỔNG KL')),
                    const DataColumn(label: Text('LOẠI SẢN PHẨM')),
                    const DataColumn(label: Text('PHÂN LOẠI')),
                    const DataColumn(label: Text('NGƯỜI THỰC HIỆN')),
                    const DataColumn(label: Text('TRẠNG THÁI')),
                    const DataColumn(label: Text('THAO TÁC')),
                  ],
                  rows: [
                    for (final slip in rows)
                      DataRow(
                        selected: slip.id == selectedId,
                        color: WidgetStateProperty.resolveWith((states) {
                          if (slip.id == selectedId) {
                            return DashboardColors.mint.withValues(alpha: 0.55);
                          }
                          if (states.contains(WidgetState.hovered)) {
                            return DashboardColors.lightMint;
                          }
                          return null;
                        }),
                        onSelectChanged: (_) => onSelect(slip),
                        cells: [
                          DataCell(
                            Checkbox(
                              value: rowSelected.contains(slip.id),
                              onChanged: (v) => onToggleRow(slip, v == true),
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                          DataCell(Text(slip.code, style: bvText(fontWeight: FontWeight.w800))),
                          DataCell(Text(slip.harvestDate, style: bvText(fontSize: 12.5))),
                          DataCell(
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  slip.areaCode.isNotEmpty ? slip.areaCode : (slip.farmingAreaId ?? slip.area),
                                  style: bvText(fontWeight: FontWeight.w700, fontSize: 12.5),
                                ),
                                if (slip.area.isNotEmpty)
                                  Text(slip.area, style: bvText(fontSize: 11, color: DashboardColors.textMuted)),
                              ],
                            ),
                          ),
                          DataCell(Text('${slip.quantity} con')),
                          DataCell(Text('${slip.totalWeightKg.toStringAsFixed(2)} kg')),
                          DataCell(Text(slip.productTypeLabel)),
                          DataCell(Text(slip.classificationLabel)),
                          DataCell(Text(slip.performedBy.isEmpty ? '—' : slip.performedBy)),
                          DataCell(
                            MgmtStatusBadge(
                              label: slip.statusLabel,
                              color: harvestUiStatusColor(slip.uiStatus),
                            ),
                          ),
                          DataCell(
                            PopupMenuButton<HarvestRowAction>(
                              tooltip: '',
                              icon: const Icon(Icons.more_vert_rounded, size: 18),
                              onSelected: (a) => onAction(slip, a),
                              itemBuilder: (_) => [
                                const PopupMenuItem(value: HarvestRowAction.detail, child: Text('Xem chi tiết')),
                                const PopupMenuItem(value: HarvestRowAction.print, child: Text('In phiếu')),
                                const PopupMenuItem(value: HarvestRowAction.pdf, child: Text('Tải PDF')),
                                if (slip.isDraft) ...[
                                  const PopupMenuItem(value: HarvestRowAction.edit, child: Text('Chỉnh sửa')),
                                  const PopupMenuItem(value: HarvestRowAction.cancel, child: Text('Hủy phiếu')),
                                ],
                                if (slip.canTransferToSale)
                                  const PopupMenuItem(
                                    value: HarvestRowAction.sale,
                                    child: Text('Chuyển sang bán hàng'),
                                  ),
                                if (slip.canComplete)
                                  const PopupMenuItem(
                                    value: HarvestRowAction.complete,
                                    child: Text('Hoàn tất thu hoạch'),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
            child: Row(
              children: [
                Expanded(
                  child: MgmtPagination(
                    page: service.page,
                    totalPages: service.totalPages,
                    start: service.filteredHarvestCount == 0
                        ? 0
                        : service.page * service.pageSize + 1,
                    end: ((service.page + 1) * service.pageSize)
                        .clamp(0, service.filteredHarvestCount),
                    total: service.filteredHarvestCount,
                    onPage: service.setPage,
                    itemLabel: 'phiếu',
                  ),
                ),
                MgmtDropdown<int>(
                  width: 120,
                  valueLabel: '${service.pageSize} / trang',
                  items: const [(10, '10 / trang'), (20, '20 / trang'), (50, '50 / trang')],
                  onSelected: service.setPageSize,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum HarvestRowAction { detail, print, pdf, edit, cancel, sale, complete }

class HarvestDetailPanel extends StatelessWidget {
  const HarvestDetailPanel({
    super.key,
    required this.slip,
    required this.onClose,
    required this.onTransfer,
    required this.onComplete,
    required this.onPrint,
    required this.onPdf,
    this.onViewCrab,
  });

  final HarvestSlipDetail? slip;
  final VoidCallback onClose;
  final VoidCallback onTransfer;
  final VoidCallback onComplete;
  final VoidCallback onPrint;
  final VoidCallback onPdf;
  final ValueChanged<HarvestLineItem>? onViewCrab;

  @override
  Widget build(BuildContext context) {
    if (slip == null) {
      return Container(
        decoration: mgmtCardDeco(radius: 16),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chi tiết phiếu thu hoạch',
              style: bvText(fontSize: 15, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 20),
            Text(
              'Chọn một phiếu để xem cua, truy xuất nguồn gốc và chuyển bán hàng.',
              style: bvText(color: DashboardColors.textMuted),
            ),
          ],
        ),
      );
    }
    final s = slip!;
    return Container(
      decoration: mgmtCardDeco(radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Chi tiết phiếu thu hoạch',
                    style: bvText(fontSize: 14.5, fontWeight: FontWeight.w800),
                  ),
                ),
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close_rounded),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                Row(
                  children: [
                    Text(s.code, style: bvText(fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(width: 8),
                    MgmtStatusBadge(
                      label: s.statusLabel,
                      color: harvestUiStatusColor(s.uiStatus),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(s.harvestDate, style: bvText(fontSize: 12.5, color: DashboardColors.textMuted)),
                const SizedBox(height: 14),
                _kv('Khu vực', '${s.areaCode.ifEmpty(s.farmingAreaId ?? '')}\n(${s.area})'),
                _kv('Người thực hiện', s.performedBy.isEmpty ? '—' : s.performedBy),
                _kv('Số cua thu hoạch', '${s.quantity} con'),
                _kv('Tổng trọng lượng', '${s.totalWeightKg.toStringAsFixed(2)} kg'),
                _kv('Loại sản phẩm', s.productTypeLabel),
                _kv('Phân loại', s.classificationLabel),
                _kv('Ghi chú', (s.note == null || s.note!.trim().isEmpty) ? '—' : s.note!),
                const SizedBox(height: 12),
                Text(
                  'Danh sách cua (${s.lines.length})',
                  style: bvText(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                for (final line in s.lines) ...[
                  _DetailCrabRow(line: line, onView: onViewCrab),
                  const SizedBox(height: 8),
                ],
                const SizedBox(height: 8),
                Text('Hình ảnh', style: bvText(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                if (s.photoUrls.isEmpty)
                  Text('Không có hình ảnh.', style: bvText(color: DashboardColors.textMuted))
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final url in s.photoUrls.take(4))
                        GestureDetector(
                          onTap: () => showHarvestLightbox(context, url),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              url,
                              width: 72,
                              height: 72,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stack) => Container(
                                width: 72,
                                height: 72,
                                color: DashboardColors.lightMint,
                                child: const Icon(Icons.image_outlined),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                const SizedBox(height: 16),
                if (s.canTransferToSale)
                  MgmtPrimaryButton(
                    icon: Icons.shopping_cart_outlined,
                    label: 'Chuyển sang bán hàng',
                    onTap: onTransfer,
                  ),
                if (s.canComplete) ...[
                  const SizedBox(height: 8),
                  MgmtPrimaryButton(
                    icon: Icons.check_rounded,
                    label: 'Hoàn tất thu hoạch',
                    onTap: onComplete,
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    MgmtOutlineButton(icon: Icons.print_outlined, label: 'In phiếu', onTap: onPrint),
                    const SizedBox(width: 8),
                    MgmtOutlineButton(icon: Icons.download_outlined, label: 'Tải xuống PDF', onTap: onPdf),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(k, style: bvText(fontSize: 11.5, color: DashboardColors.textMuted)),
          Text(v, style: bvText(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _DetailCrabRow extends StatelessWidget {
  const _DetailCrabRow({required this.line, this.onView});
  final HarvestLineItem line;
  final ValueChanged<HarvestLineItem>? onView;

  @override
  Widget build(BuildContext context) {
    final size = line.widthMm != null && line.lengthMm != null
        ? '${line.widthMm!.round()} × ${line.lengthMm!.round()} mm'
        : '—';
    final gender = line.gender.isEmpty ? '' : ' • ${line.gender}';
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: DashboardColors.lightMint,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _CrabThumb(url: line.imageUrl, size: 46),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(line.crabCode.isEmpty ? '—' : line.crabCode, style: bvText(fontWeight: FontWeight.w800)),
                Text(
                  '${line.boxCode.isEmpty ? '—' : line.boxCode}  ·  ${line.crabType.ifEmpty('Cua biển')}$gender',
                  style: bvText(fontSize: 11.5, color: DashboardColors.textMuted),
                ),
                Text(
                  'Trọng lượng thu hoạch: ${line.weightG} g',
                  style: bvText(fontSize: 12),
                ),
                Text('Kích thước: $size', style: bvText(fontSize: 12, color: DashboardColors.textMuted)),
                const SizedBox(height: 4),
                _EligibilityBadge(
                  eligibility: line.passed
                      ? HarvestEligibility.eligible
                      : HarvestEligibility.notEligible,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onView == null ? null : () => onView!(line),
            child: Text(
              'Xem cua →',
              style: bvText(fontSize: 12, fontWeight: FontWeight.w700, color: DashboardColors.brand),
            ),
          ),
        ],
      ),
    );
  }
}

class HarvestMobileSlipCard extends StatelessWidget {
  const HarvestMobileSlipCard({
    super.key,
    required this.slip,
    required this.selected,
    required this.onTap,
  });

  final HarvestSlipDetail slip;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? DashboardColors.mint : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: DashboardColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(slip.code, style: bvText(fontWeight: FontWeight.w800)),
                  const Spacer(),
                  MgmtStatusBadge(
                    label: slip.statusLabel,
                    color: harvestUiStatusColor(slip.uiStatus),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(slip.harvestDate, style: bvText(fontSize: 12, color: DashboardColors.textMuted)),
              Text(
                '${slip.area} · ${slip.quantity} con · ${slip.totalWeightKg.toStringAsFixed(2)} kg',
                style: bvText(fontSize: 12.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReadySkeleton extends StatelessWidget {
  const _ReadySkeleton();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final cols = c.maxWidth >= 1100 ? 4 : 2;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: cols,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.85,
          children: List.generate(
            4,
            (_) => Container(
              decoration: BoxDecoration(
                color: DashboardColors.lightMint,
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TableSkeleton extends StatelessWidget {
  const _TableSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: List.generate(
          6,
          (_) => Container(
            height: 42,
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: DashboardColors.lightMint,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionError extends StatelessWidget {
  const _SectionError({required this.message, required this.onRetry});
  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kRed.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: _kRed),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: bvText(color: _kRed))),
          TextButton(onPressed: onRetry, child: const Text('Thử lại')),
        ],
      ),
    );
  }
}

void showHarvestLightbox(BuildContext context, String url) {
  showDialog<void>(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.black,
      child: Stack(
        children: [
          InteractiveViewer(
            child: Image.network(url, fit: BoxFit.contain),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              onPressed: () => Navigator.pop(ctx),
              icon: const Icon(Icons.close, color: Colors.white),
            ),
          ),
        ],
      ),
    ),
  );
}

extension _EmptyStr on String {
  String ifEmpty(String fallback) => trim().isEmpty ? fallback : this;
}
