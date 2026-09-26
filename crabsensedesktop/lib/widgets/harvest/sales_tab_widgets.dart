import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../models/harvest_sales.dart';
import '../../services/harvest_sales_service.dart';
import '../../theme/dashboard_theme.dart';
import '../shared/mgmt_ui.dart';
import 'harvest_sales_dialogs.dart';
import 'harvest_tab_widgets.dart';

const _kAmber = Color(0xFFF5B700);
const _kRed = Color(0xFFEF4444);
const _kBlue = Color(0xFF2495E8);

class SalesKpiRow extends StatelessWidget {
  const SalesKpiRow({
    super.key,
    required this.kpi,
    required this.loading,
    required this.onTap,
  });

  final SalesKpi kpi;
  final bool loading;
  final ValueChanged<SalesKpiFocus> onTap;

  @override
  Widget build(BuildContext context) {
    Widget card({
      required SalesKpiFocus? focus,
      required IconData icon,
      required String label,
      required String value,
      String? suffix,
      required Color color,
      String? trend,
      Color? trendColor,
    }) {
      final inner = loading
          ? const _SalesKpiSkeleton()
          : _SalesKpiCard(
              icon: icon,
              label: label,
              value: value,
              suffix: suffix,
              color: color,
              trend: trend,
              trendColor: trendColor,
            );
      if (focus == null) return Expanded(child: inner);
      return Expanded(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onTap(focus),
            borderRadius: BorderRadius.circular(16),
            child: inner,
          ),
        ),
      );
    }

    String? trendUp(int n, String unit) => n == 0
        ? null
        : n > 0
            ? '↑ $n $unit so với hôm qua'
            : '↓ ${n.abs()} $unit so với hôm qua';
    String? pct(double v) {
      if (v == 0) return null;
      return v > 0
          ? '↑ ${v.toStringAsFixed(0)}% so với hôm qua'
          : '↓ ${v.abs().toStringAsFixed(0)}% so với hôm qua';
    }

    final children = [
      card(
        focus: SalesKpiFocus.sold,
        icon: Icons.payments_outlined,
        label: 'Doanh thu hôm nay',
        value: formatVnd(kpi.revenueTodayVnd),
        color: DashboardColors.brand,
        trend: pct(kpi.revenueTrendPercent),
        trendColor: kpi.revenueTrendPercent >= 0 ? DashboardColors.brand : _kRed,
      ),
      card(
        focus: SalesKpiFocus.sold,
        icon: Icons.set_meal_outlined,
        label: 'Đã bán',
        value: '${kpi.soldToday}',
        suffix: 'con',
        color: DashboardColors.brandGreen,
        trend: trendUp(kpi.soldTrend, 'con'),
        trendColor: kpi.soldTrend >= 0 ? DashboardColors.brand : _kRed,
      ),
      card(
        focus: SalesKpiFocus.waitingSale,
        icon: Icons.inventory_2_outlined,
        label: 'Cua chờ bán',
        value: '${kpi.inventory}',
        suffix: 'con',
        color: _kAmber,
      ),
      card(
        focus: SalesKpiFocus.ordersToday,
        icon: Icons.receipt_long_outlined,
        label: 'Đơn hôm nay',
        value: '${kpi.ordersToday}',
        suffix: 'đơn',
        color: _kBlue,
      ),
      card(
        focus: SalesKpiFocus.unpaid,
        icon: Icons.account_balance_wallet_outlined,
        label: 'Chưa thanh toán',
        value: formatVnd(kpi.unpaidVnd),
        color: _kRed,
        trend: trendUp(kpi.unpaidOrdersTrend, 'đơn'),
        trendColor: kpi.unpaidOrdersTrend <= 0 ? DashboardColors.brand : _kRed,
      ),
    ];

    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth >= 1100) {
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
            Row(children: [children[0], const SizedBox(width: 12), children[1], const SizedBox(width: 12), children[2]]),
            const SizedBox(height: 12),
            Row(children: [children[3], const SizedBox(width: 12), children[4]]),
          ],
        );
      },
    );
  }
}

class _SalesKpiCard extends StatelessWidget {
  const _SalesKpiCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.suffix,
    this.trend,
    this.trendColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? suffix;
  final Color color;
  final String? trend;
  final Color? trendColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: mgmtCardDeco(radius: 16),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: bvText(fontSize: 12, fontWeight: FontWeight.w600, color: DashboardColors.textMuted)),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Flexible(
                      child: Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: bvText(fontSize: 20, fontWeight: FontWeight.w800, color: DashboardColors.textPrimary),
                      ),
                    ),
                    if (suffix != null) ...[
                      const SizedBox(width: 4),
                      Text(suffix!, style: bvText(fontSize: 13, fontWeight: FontWeight.w700)),
                    ],
                  ],
                ),
                if (trend != null)
                  Text(trend!, style: bvText(fontSize: 11, fontWeight: FontWeight.w600, color: trendColor ?? DashboardColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SalesKpiSkeleton extends StatelessWidget {
  const _SalesKpiSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 86,
      decoration: mgmtCardDeco(),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(width: 42, height: 42, decoration: BoxDecoration(color: DashboardColors.mint, borderRadius: BorderRadius.circular(12))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(height: 10, width: 80, color: DashboardColors.mint),
                const SizedBox(height: 8),
                Container(height: 16, width: 56, color: DashboardColors.lightMint),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SalesFilterToolbar extends StatelessWidget {
  const SalesFilterToolbar({
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
              hint: 'Tìm mã đơn, khách hàng, mã cua...',
            ),
          ),
          MgmtDropdown<SalesOrderUiStatus?>(
            width: 170,
            valueLabel: service.salesStatusFilter == null
                ? 'Tất cả'
                : salesOrderUiLabel(service.salesStatusFilter!),
            items: [
              (null, 'Tất cả'),
              (SalesOrderUiStatus.draft, 'Nháp'),
              (SalesOrderUiStatus.waiting, 'Chờ bán'),
              (SalesOrderUiStatus.pendingPayment, 'Chờ thanh toán'),
              (SalesOrderUiStatus.completed, 'Hoàn thành'),
              (SalesOrderUiStatus.cancelled, 'Đã hủy'),
            ],
            onSelected: service.setSalesStatusFilter,
          ),
          MgmtDropdown<String?>(
            width: 180,
            valueLabel: service.salesCustomer ?? 'Tất cả',
            items: [
              (null, 'Tất cả'),
              for (final n in service.customerNames) (n, n),
            ],
            onSelected: service.setSalesCustomer,
          ),
          MgmtDropdown<HarvestProductType>(
            width: 150,
            valueLabel: harvestProductFilterLabel(service.salesProductFilter),
            items: const [
              (HarvestProductType.all, 'Tất cả'),
              (HarvestProductType.meat, 'Cua thịt'),
              (HarvestProductType.softshell, 'Cua lột'),
              (HarvestProductType.other, 'Khác'),
            ],
            onSelected: service.setSalesProductFilter,
          ),
          MgmtDropdown<HarvestTimeRange>(
            width: 160,
            leading: Icons.calendar_today_outlined,
            valueLabel: harvestTimeLabel(service.salesTimeRange),
            items: const [
              (HarvestTimeRange.today, 'Hôm nay'),
              (HarvestTimeRange.d7, '7 ngày qua'),
              (HarvestTimeRange.d30, '30 ngày qua'),
              (HarvestTimeRange.all, 'Tất cả'),
            ],
            onSelected: service.setSalesTimeRange,
          ),
          MgmtOutlineButton(
            label: 'Xóa lọc',
            icon: Icons.filter_alt_off_outlined,
            onTap: () {
              search.clear();
              onClearSearch();
              service.clearSalesFilters();
            },
          ),
          if (onExport != null)
            MgmtOutlineButton(label: 'Xuất dữ liệu', icon: Icons.download_outlined, onTap: onExport),
          MgmtPrimaryButton(icon: Icons.add_rounded, label: 'Tạo đơn bán hàng', onTap: onCreate),
        ],
      ),
    );
  }
}

class ReadyToSellSection extends StatelessWidget {
  const ReadyToSellSection({
    super.key,
    required this.service,
    required this.selected,
    required this.showAll,
    required this.onToggleShowAll,
    required this.onToggle,
  });

  final HarvestSalesService service;
  final Set<String> selected;
  final bool showAll;
  final VoidCallback onToggleShowAll;
  final void Function(InventoryCrab crab, bool value) onToggle;

  @override
  Widget build(BuildContext context) {
    final count = service.salesKpi.inventory;
    final crabs = showAll ? service.readyToSell : service.readyToSell.take(8).toList();
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: mgmtCardDeco(radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'Cua chờ bán ($count)',
                style: bvText(fontSize: 15, fontWeight: FontWeight.w800, color: DashboardColors.textPrimary),
              ),
              const Spacer(),
              TextButton(
                onPressed: onToggleShowAll,
                child: Text(
                  showAll ? 'Thu gọn' : 'Xem tất cả →',
                  style: bvText(fontSize: 12.5, fontWeight: FontWeight.w700, color: DashboardColors.brand),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (service.salesError != null && service.inventory.isEmpty)
            _SalesError(message: 'Không thể tải cua chờ bán.', onRetry: service.reloadSales)
          else if (service.salesLoading && service.inventory.isEmpty)
            const _ReadySellSkeleton()
          else if (crabs.isEmpty)
            const MgmtEmptyState(
              icon: Icons.set_meal_outlined,
              title: 'Không có cua chờ bán',
              message: 'Các cua đã thu hoạch và đủ điều kiện sẽ xuất hiện tại đây.',
            )
          else
            LayoutBuilder(
              builder: (context, c) {
                final cols = c.maxWidth >= 1100 ? 4 : c.maxWidth >= 720 ? 2 : 1;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: crabs.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: cols == 1 ? 2.6 : 1.9,
                  ),
                  itemBuilder: (_, i) => ReadyToSellCrabCard(
                    crab: crabs[i],
                    selected: selected.contains(crabs[i].id),
                    onToggle: onToggle,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class ReadyToSellCrabCard extends StatelessWidget {
  const ReadyToSellCrabCard({
    super.key,
    required this.crab,
    required this.selected,
    required this.onToggle,
  });

  final InventoryCrab crab;
  final bool selected;
  final void Function(InventoryCrab crab, bool value) onToggle;

  @override
  Widget build(BuildContext context) {
    final color = crab.eligibility == SaleEligibility.review ? _kAmber : DashboardColors.brand;
    return Container(
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
            message: crab.canSelect ? 'Chọn để tạo đơn' : crab.disableReason,
            child: Checkbox(
              value: selected,
              onChanged: crab.canSelect ? (v) => onToggle(crab, v == true) : null,
              activeColor: DashboardColors.brand,
              visualDensity: VisualDensity.compact,
            ),
          ),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: DashboardColors.lightMint,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.set_meal_outlined, color: DashboardColors.brandGreen),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(crab.code, style: bvText(fontWeight: FontWeight.w800, fontSize: 13.5)),
                Text(
                  crab.harvestCode.isEmpty ? '—' : crab.harvestCode,
                  style: bvText(fontSize: 12, color: DashboardColors.textMuted),
                ),
                Text('${crab.weightG} g', style: bvText(fontSize: 12.5, fontWeight: FontWeight.w600)),
                Text(
                  '${crab.productLabel} • ${crab.gradeLabel}',
                  style: bvText(fontSize: 11.5, color: DashboardColors.textMuted),
                ),
                const SizedBox(height: 4),
                MgmtStatusBadge(label: saleEligibilityLabel(crab.eligibility), color: color),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SalesSelectionBar extends StatelessWidget {
  const SalesSelectionBar({
    super.key,
    required this.crabs,
    required this.onCreate,
    required this.onClear,
  });

  final List<InventoryCrab> crabs;
  final VoidCallback onCreate;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final kg = crabs.fold<int>(0, (s, c) => s + c.weightG) / 1000;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: DashboardColors.mint,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DashboardColors.brand.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: DashboardColors.brand, size: 20),
          const SizedBox(width: 8),
          Text(
            'Đã chọn ${crabs.length} cua • ${kg.toStringAsFixed(2)} kg',
            style: bvText(fontWeight: FontWeight.w800),
          ),
          const Spacer(),
          TextButton(onPressed: onClear, child: const Text('Bỏ chọn')),
          const SizedBox(width: 8),
          MgmtPrimaryButton(
            icon: Icons.add_rounded,
            label: 'Tạo đơn bán hàng từ ${crabs.length} cua',
            onTap: onCreate,
          ),
        ],
      ),
    );
  }
}

enum SalesRowAction { detail, print, pdf, history, cancel, complete, refund }

class SalesOrderTable extends StatelessWidget {
  const SalesOrderTable({
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
  final ValueChanged<SalesOrderDetail> onSelect;
  final void Function(SalesOrderDetail order, SalesRowAction action) onAction;
  final Set<String> rowSelected;
  final void Function(SalesOrderDetail order, bool value) onToggleRow;
  final ValueChanged<bool> onToggleAll;

  @override
  Widget build(BuildContext context) {
    final rows = service.pagedSalesOrders;
    final allOn = rows.isNotEmpty && rows.every((r) => rowSelected.contains(r.id));
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
                  'Danh sách đơn bán hàng (${service.filteredSalesCount})',
                  style: bvText(fontSize: 15, fontWeight: FontWeight.w800),
                ),
                const Spacer(),
                MgmtInlineSort<SalesOrderSort>(
                  value: service.salesSort,
                  items: const [
                    (SalesOrderSort.newest, 'Mới nhất trước'),
                    (SalesOrderSort.oldest, 'Cũ nhất trước'),
                    (SalesOrderSort.mostAmount, 'Giá trị cao nhất'),
                    (SalesOrderSort.mostCrabs, 'Nhiều cua nhất'),
                  ],
                  onChanged: service.setSalesSort,
                ),
              ],
            ),
          ),
          if (service.salesError != null && service.allSalesOrders.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: _SalesError(message: 'Không thể tải danh sách đơn.', onRetry: service.reloadSales),
            )
          else if (service.salesLoading && service.allSalesOrders.isEmpty)
            const _SalesTableSkeleton()
          else if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: const MgmtEmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'Chưa có đơn bán hàng',
                message: 'Tạo đơn đầu tiên từ cua chờ bán.',
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 960),
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
                        value: allOn,
                        onChanged: (v) => onToggleAll(v == true),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    const DataColumn(label: Text('MÃ ĐƠN')),
                    const DataColumn(label: Text('NGÀY BÁN')),
                    const DataColumn(label: Text('KHÁCH HÀNG')),
                    const DataColumn(label: Text('SỐ CUA')),
                    const DataColumn(label: Text('TỔNG KL')),
                    const DataColumn(label: Text('TỔNG TIỀN')),
                    const DataColumn(label: Text('THANH TOÁN')),
                    const DataColumn(label: Text('TRẠNG THÁI')),
                    const DataColumn(label: Text('THAO TÁC')),
                  ],
                  rows: [
                    for (final o in rows)
                      DataRow(
                        selected: o.id == selectedId,
                        color: WidgetStateProperty.resolveWith((states) {
                          if (o.id == selectedId) return DashboardColors.mint.withValues(alpha: 0.55);
                          if (states.contains(WidgetState.hovered)) return DashboardColors.lightMint;
                          return null;
                        }),
                        onSelectChanged: (_) => onSelect(o),
                        cells: [
                          DataCell(Checkbox(
                            value: rowSelected.contains(o.id),
                            onChanged: (v) => onToggleRow(o, v == true),
                            visualDensity: VisualDensity.compact,
                          )),
                          DataCell(Text(o.code, style: bvText(fontWeight: FontWeight.w800))),
                          DataCell(Text(formatHarvestDateTime(o.orderDate), style: bvText(fontSize: 12.5))),
                          DataCell(Text(o.customerName.isEmpty ? '—' : o.customerName)),
                          DataCell(Text('${o.crabCount} con')),
                          DataCell(Text('${o.totalWeightKg.toStringAsFixed(2)} kg')),
                          DataCell(Text(formatVnd(o.revenueVnd), style: bvText(fontWeight: FontWeight.w700))),
                          DataCell(o.isCancelled
                              ? Text('—', style: bvText(color: DashboardColors.textMuted))
                              : MgmtStatusBadge(label: o.paymentStatusLabel, color: salesPaymentUiColor(o.paymentUi))),
                          DataCell(MgmtStatusBadge(label: o.orderStatusLabel, color: salesOrderUiColor(o.uiStatus))),
                          DataCell(
                            PopupMenuButton<SalesRowAction>(
                              tooltip: '',
                              icon: const Icon(Icons.more_vert_rounded, size: 18),
                              onSelected: (a) => onAction(o, a),
                              itemBuilder: (_) => [
                                const PopupMenuItem(value: SalesRowAction.detail, child: Text('Xem chi tiết')),
                                const PopupMenuItem(value: SalesRowAction.print, child: Text('In hóa đơn')),
                                const PopupMenuItem(value: SalesRowAction.pdf, child: Text('Tải PDF')),
                                const PopupMenuItem(value: SalesRowAction.history, child: Text('Xem lịch sử')),
                                if (o.isDraft)
                                  const PopupMenuItem(value: SalesRowAction.complete, child: Text('Hoàn tất đơn')),
                                if (!o.isCancelled)
                                  const PopupMenuItem(value: SalesRowAction.cancel, child: Text('Hủy đơn')),
                                if (o.isPaid && !o.isCancelled)
                                  const PopupMenuItem(value: SalesRowAction.refund, child: Text('Hoàn tiền')),
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
                    page: service.salesPage,
                    totalPages: service.salesTotalPages,
                    start: service.filteredSalesCount == 0 ? 0 : service.salesPage * service.salesPageSize + 1,
                    end: ((service.salesPage + 1) * service.salesPageSize).clamp(0, service.filteredSalesCount),
                    total: service.filteredSalesCount,
                    onPage: service.setSalesPage,
                    itemLabel: 'đơn',
                  ),
                ),
                MgmtDropdown<int>(
                  width: 120,
                  valueLabel: '${service.salesPageSize} / trang',
                  items: const [(10, '10 / trang'), (20, '20 / trang'), (50, '50 / trang')],
                  onSelected: service.setSalesPageSize,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SalesOrderDetailPanel extends StatefulWidget {
  const SalesOrderDetailPanel({
    super.key,
    required this.order,
    required this.onClose,
    required this.onPrint,
    required this.onPdf,
    required this.onCancel,
    required this.onComplete,
    this.onOpenHarvest,
  });

  final SalesOrderDetail? order;
  final VoidCallback onClose;
  final VoidCallback onPrint;
  final VoidCallback onPdf;
  final VoidCallback onCancel;
  final VoidCallback onComplete;
  final ValueChanged<String>? onOpenHarvest;

  @override
  State<SalesOrderDetailPanel> createState() => _SalesOrderDetailPanelState();
}

class _SalesOrderDetailPanelState extends State<SalesOrderDetailPanel> {
  var _tab = 0;

  @override
  void didUpdateWidget(covariant SalesOrderDetailPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.order?.id != widget.order?.id) _tab = 0;
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    if (o == null) {
      return Container(
        decoration: mgmtCardDeco(radius: 16),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Chi tiết đơn bán hàng', style: bvText(fontSize: 15, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            Text('Chọn một đơn để xem khách hàng, thanh toán và nguồn gốc cua.', style: bvText(color: DashboardColors.textMuted)),
          ],
        ),
      );
    }
    return Container(
      decoration: mgmtCardDeco(radius: 16),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
            child: Row(
              children: [
                Expanded(child: Text('Chi tiết đơn bán hàng', style: bvText(fontSize: 14.5, fontWeight: FontWeight.w800))),
                IconButton(onPressed: widget.onClose, icon: const Icon(Icons.close_rounded), visualDensity: VisualDensity.compact),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Row(
              children: [
                Text(o.code, style: bvText(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(width: 8),
                MgmtStatusBadge(label: o.orderStatusLabel, color: salesOrderUiColor(o.uiStatus)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(formatHarvestDateTime(o.orderDate), style: bvText(fontSize: 12.5, color: DashboardColors.textMuted)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                for (final e in [
                  (0, 'Thông tin chung'),
                  (1, 'Danh sách cua (${o.lines.length})'),
                  (2, 'Thanh toán'),
                  (3, 'Lịch sử'),
                ])
                  Expanded(
                    child: TextButton(
                      onPressed: () => setState(() => _tab = e.$1),
                      child: Text(
                        e.$2,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: bvText(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: _tab == e.$1 ? DashboardColors.brand : DashboardColors.textMuted,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              children: [
                if (_tab == 0) ..._info(o),
                if (_tab == 1) ..._crabs(o),
                if (_tab == 2) ..._pay(o),
                if (_tab == 3) ..._history(o),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    MgmtOutlineButton(icon: Icons.print_outlined, label: 'In hóa đơn', onTap: widget.onPrint),
                    MgmtOutlineButton(icon: Icons.download_outlined, label: 'Tải xuống PDF', onTap: widget.onPdf),
                    PopupMenuButton<String>(
                      tooltip: '',
                      onSelected: (v) {
                        if (v == 'cancel') widget.onCancel();
                        if (v == 'complete') widget.onComplete();
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(value: 'history', child: Text('Xem lịch sử')),
                        if (o.isDraft) const PopupMenuItem(value: 'complete', child: Text('Hoàn tất đơn')),
                        if (!o.isCancelled) const PopupMenuItem(value: 'cancel', child: Text('Hủy đơn')),
                      ],
                      child: MgmtOutlineButton(icon: Icons.more_horiz, label: 'Thao tác khác', onTap: null),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _info(SalesOrderDetail o) => [
        _kv('Khách hàng', o.customerName.isEmpty ? '—' : o.customerName),
        _kv('Số điện thoại', o.customerPhone.isEmpty ? '—' : o.customerPhone),
        _kv('Địa chỉ', o.customerAddress.isEmpty ? '—' : o.customerAddress),
        _kv('Loại khách', o.customerTypeLabel),
        const SizedBox(height: 8),
        _kv('Ngày bán', formatHarvestDateTime(o.orderDate)),
        _kv('Số cua', '${o.crabCount} con'),
        _kv('Tổng trọng lượng', '${o.totalWeightKg.toStringAsFixed(2)} kg'),
        _kv('Đơn giá TB', '${formatVnd(o.avgPricePerKg)}/kg'),
        _kv('Tạm tính', formatVnd(o.subtotalVnd)),
        _kv('Giảm giá', formatVnd(o.discountVnd)),
        _kv('Thành tiền', formatVnd(o.revenueVnd)),
        _kv('Ghi chú', (o.notes == null || o.notes!.trim().isEmpty) ? '—' : o.notes!),
        const SizedBox(height: 10),
        Text('Nguồn gốc', style: bvText(fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        if (o.harvestCodes.isEmpty)
          Text('—', style: bvText(color: DashboardColors.textMuted))
        else
          Wrap(
            spacing: 8,
            children: [
              for (final code in o.harvestCodes)
                ActionChip(
                  label: Text(code, style: bvText(fontSize: 12, fontWeight: FontWeight.w700, color: DashboardColors.brand)),
                  backgroundColor: DashboardColors.mint,
                  side: BorderSide.none,
                  onPressed: widget.onOpenHarvest == null ? null : () => widget.onOpenHarvest!(code),
                ),
            ],
          ),
      ];

  List<Widget> _crabs(SalesOrderDetail o) => [
        for (final l in o.lines) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: DashboardColors.lightMint, borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.set_meal_outlined, color: DashboardColors.brandGreen),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.crabCode.isEmpty ? '—' : l.crabCode, style: bvText(fontWeight: FontWeight.w800)),
                      Text(
                        '${l.boxCode.isEmpty ? '—' : l.boxCode}  ·  ${l.weightG} g',
                        style: bvText(fontSize: 12, color: DashboardColors.textMuted),
                      ),
                      Text(l.typeLabel, style: bvText(fontSize: 12)),
                      const SizedBox(height: 4),
                      MgmtStatusBadge(
                        label: o.isCancelled ? 'Chờ bán' : 'Đã bán',
                        color: o.isCancelled ? _kAmber : DashboardColors.brand,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ];

  List<Widget> _pay(SalesOrderDetail o) => [
        MgmtStatusBadge(label: o.paymentStatusLabel, color: salesPaymentUiColor(o.paymentUi)),
        const SizedBox(height: 10),
        _kv('Phương thức', o.paymentMethodLabel),
        _kv('Đã thanh toán', formatVnd(o.paidVnd)),
        _kv('Còn lại', formatVnd(o.remainingVnd)),
      ];

  List<Widget> _history(SalesOrderDetail o) => [
        _kv('Tạo đơn', formatHarvestDateTime(o.orderDate)),
        if (o.isCompleted) _kv('Hoàn thành', formatHarvestDateTime(o.orderDate)),
        if (o.isCancelled) _kv('Đã hủy', 'Đơn đã chuyển sang Đã hủy'),
        _kv('Người bán', o.sellerName.isEmpty ? '—' : o.sellerName),
      ];

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

class _ReadySellSkeleton extends StatelessWidget {
  const _ReadySellSkeleton();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.9,
      children: List.generate(
        4,
        (_) => Container(
          decoration: BoxDecoration(color: DashboardColors.lightMint, borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}

class _SalesTableSkeleton extends StatelessWidget {
  const _SalesTableSkeleton();

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
            decoration: BoxDecoration(color: DashboardColors.lightMint, borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ),
    );
  }
}

class _SalesError extends StatelessWidget {
  const _SalesError({required this.message, required this.onRetry});
  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: _kRed.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(12)),
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

class SalesTab extends StatefulWidget {
  const SalesTab({super.key, required this.service});

  final HarvestSalesService service;

  @override
  State<SalesTab> createState() => _SalesTabState();
}

class _SalesTabState extends State<SalesTab> {
  final _search = TextEditingController();
  final _scroll = ScrollController();
  final _readyKey = GlobalKey();
  final _selected = <String>{};
  final _rowSelected = <String>{};
  Timer? _debounce;
  SalesOrderDetail? _detail;
  var _showAll = false;

  HarvestSalesService get service => widget.service;

  @override
  void initState() {
    super.initState();
    _search.text = service.salesSearch;
    _search.addListener(_onSearch);
    if (service.pagedSalesOrders.isNotEmpty) {
      _detail = service.pagedSalesOrders.first;
    }
  }

  @override
  void dispose() {
    _search.removeListener(_onSearch);
    _search.dispose();
    _scroll.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearch() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      service.setSalesSearch(_search.text);
    });
  }

  List<InventoryCrab> get _picked =>
      service.readyToSell.where((c) => _selected.contains(c.id)).toList();

  void _onKpi(SalesKpiFocus focus) {
    service.applySalesKpi(focus);
    if (focus == SalesKpiFocus.waitingSale) {
      final ctx = _readyKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 350));
      }
    }
  }

  Future<void> _create({List<InventoryCrab>? crabs}) {
    return showCreateSalesOrderDialog(
      context,
      service,
      initialCrabs: crabs ?? _picked,
    );
  }

  Future<void> _export() async {
    final csv = service.exportSalesCsv();
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Xuất đơn bán hàng',
      fileName: 'sales-orders.csv',
      type: FileType.custom,
      allowedExtensions: const ['csv'],
    );
    if (path == null) return;
    await File(path).writeAsString(csv);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã xuất ${service.filteredSalesCount} đơn.')),
      );
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _cancel(SalesOrderDetail order) async {
    final ok = await showCancelSaleDialog(context, order);
    if (ok != true || !mounted) return;
    try {
      await service.cancelSaleOrder(order.id);
      if (mounted) _toast('Đã hủy ${order.code}. Cua trở lại chờ bán nếu đã bán.');
    } catch (e) {
      if (mounted) _toast('$e');
    }
  }

  Future<void> _complete(SalesOrderDetail order) async {
    try {
      await service.completeSaleOrder(order.id);
      if (mounted) _toast('Đã hoàn tất ${order.code}.');
    } catch (e) {
      if (mounted) _toast('$e');
    }
  }

  void _onAction(SalesOrderDetail order, SalesRowAction action) {
    setState(() => _detail = order);
    switch (action) {
      case SalesRowAction.detail:
        break;
      case SalesRowAction.print:
        _toast('In hóa đơn ${order.code}');
      case SalesRowAction.pdf:
        _toast('Tải PDF ${order.code}');
      case SalesRowAction.history:
        _toast('Lịch sử ${order.code}');
      case SalesRowAction.cancel:
        _cancel(order);
      case SalesRowAction.complete:
        _complete(order);
      case SalesRowAction.refund:
        _toast('Hoàn tiền cho ${order.code} cần xác nhận kế toán.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final svc = service;
    var detail = _detail;
    if (detail != null) {
      final still = svc.filteredSalesOrders.where((o) => o.id == detail!.id);
      detail = still.isEmpty
          ? (svc.pagedSalesOrders.isEmpty ? null : svc.pagedSalesOrders.first)
          : still.first;
    } else if (svc.pagedSalesOrders.isNotEmpty) {
      detail = svc.pagedSalesOrders.first;
    }

    return LayoutBuilder(
      builder: (context, box) {
        final desktop = box.maxWidth >= 1100;
        final tablet = box.maxWidth >= 800;
        return ListView(
          controller: _scroll,
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
          children: [
            SalesKpiRow(
              kpi: svc.salesKpi,
              loading: svc.salesLoading && svc.salesKpi.inventory == 0 && svc.allSalesOrders.isEmpty,
              onTap: _onKpi,
            ),
            const SizedBox(height: 14),
            SalesFilterToolbar(
              search: _search,
              service: svc,
              onCreate: () => _create(),
              onClearSearch: () => service.setSalesSearch(''),
              onExport: _export,
            ),
            const SizedBox(height: 14),
            KeyedSubtree(
              key: _readyKey,
              child: ReadyToSellSection(
                service: svc,
                selected: _selected,
                showAll: _showAll,
                onToggleShowAll: () => setState(() => _showAll = !_showAll),
                onToggle: (c, v) => setState(() {
                  if (v) {
                    _selected.add(c.id);
                  } else {
                    _selected.remove(c.id);
                  }
                }),
              ),
            ),
            if (_picked.isNotEmpty) ...[
              const SizedBox(height: 12),
              SalesSelectionBar(
                crabs: _picked,
                onCreate: () => _create(crabs: _picked),
                onClear: () => setState(_selected.clear),
              ),
            ],
            const SizedBox(height: 14),
            if (desktop)
              SizedBox(
                height: 620,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 7,
                      child: SalesOrderTable(
                        service: svc,
                        selectedId: detail?.id,
                        onSelect: (o) => setState(() => _detail = o),
                        onAction: _onAction,
                        rowSelected: _rowSelected,
                        onToggleRow: (o, v) => setState(() {
                          if (v) {
                            _rowSelected.add(o.id);
                          } else {
                            _rowSelected.remove(o.id);
                          }
                        }),
                        onToggleAll: (v) => setState(() {
                          if (v) {
                            _rowSelected.addAll(svc.pagedSalesOrders.map((e) => e.id));
                          } else {
                            for (final e in svc.pagedSalesOrders) {
                              _rowSelected.remove(e.id);
                            }
                          }
                        }),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: SalesOrderDetailPanel(
                        order: detail,
                        onClose: () => setState(() => _detail = null),
                        onPrint: () {
                          if (detail != null) _toast('In hóa đơn ${detail.code}');
                        },
                        onPdf: () {
                          if (detail != null) _toast('Tải PDF ${detail.code}');
                        },
                        onCancel: () {
                          if (detail != null) _cancel(detail);
                        },
                        onComplete: () {
                          if (detail != null) _complete(detail);
                        },
                        onOpenHarvest: (code) => _toast('Phiếu $code'),
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              SalesOrderTable(
                service: svc,
                selectedId: detail?.id,
                onSelect: (o) {
                  setState(() => _detail = o);
                  if (!tablet) _sheet(o);
                },
                onAction: _onAction,
                rowSelected: _rowSelected,
                onToggleRow: (o, v) => setState(() {
                  if (v) {
                    _rowSelected.add(o.id);
                  } else {
                    _rowSelected.remove(o.id);
                  }
                }),
                onToggleAll: (v) => setState(() {
                  if (v) {
                    _rowSelected.addAll(svc.pagedSalesOrders.map((e) => e.id));
                  } else {
                    for (final e in svc.pagedSalesOrders) {
                      _rowSelected.remove(e.id);
                    }
                  }
                }),
              ),
              if (tablet && detail != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 480,
                  child: SalesOrderDetailPanel(
                    order: detail,
                    onClose: () => setState(() => _detail = null),
                    onPrint: () => _toast('In hóa đơn ${detail!.code}'),
                    onPdf: () => _toast('Tải PDF ${detail!.code}'),
                    onCancel: () => _cancel(detail!),
                    onComplete: () => _complete(detail!),
                  ),
                ),
              ],
            ],
          ],
        );
      },
    );
  }

  void _sheet(SalesOrderDetail order) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (ctx) => SizedBox(
        height: MediaQuery.of(ctx).size.height * 0.88,
        child: SalesOrderDetailPanel(
          order: order,
          onClose: () => Navigator.pop(ctx),
          onPrint: () => _toast('In hóa đơn ${order.code}'),
          onPdf: () => _toast('Tải PDF ${order.code}'),
          onCancel: () {
            Navigator.pop(ctx);
            _cancel(order);
          },
          onComplete: () {
            Navigator.pop(ctx);
            _complete(order);
          },
        ),
      ),
    );
  }
}
