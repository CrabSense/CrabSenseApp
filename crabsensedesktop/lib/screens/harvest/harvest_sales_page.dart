import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/harvest_sales.dart';
import '../../services/harvest_sales_service.dart';
import '../../theme/dashboard_theme.dart';
import '../../widgets/dashboard/glass_card.dart';
import '../../widgets/harvest/harvest_sales_dialogs.dart';

class HarvestSalesPage extends StatefulWidget {
  const HarvestSalesPage({super.key, required this.service});

  final HarvestSalesService service;

  @override
  State<HarvestSalesPage> createState() => _HarvestSalesPageState();
}

class _HarvestSalesPageState extends State<HarvestSalesPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    widget.service.addListener(_onUpdate);
  }

  @override
  void dispose() {
    widget.service.removeListener(_onUpdate);
    _tabs.dispose();
    super.dispose();
  }

  void _onUpdate() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final service = widget.service;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          child: Text(
            'Thu hoạch & Bán hàng',
            style: GoogleFonts.notoSans(
              color: DashboardColors.textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: TabBar(
            controller: _tabs,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: DashboardColors.cyan,
            labelColor: DashboardColors.cyan,
            unselectedLabelColor: DashboardColors.textMuted,
            labelStyle: GoogleFonts.notoSans(
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
            tabs: const [
              Tab(text: 'Thu hoạch'),
              Tab(text: 'Bán hàng'),
            ],
          ),
        ),
        if (service.error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
            child: Text(
              service.error!,
              style: GoogleFonts.notoSans(color: DashboardColors.risk),
            ),
          ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              _HarvestTab(service: service),
              _SalesTab(service: service),
            ],
          ),
        ),
      ],
    );
  }
}

class _HarvestTab extends StatelessWidget {
  const _HarvestTab({required this.service});

  final HarvestSalesService service;

  @override
  Widget build(BuildContext context) {
    final kpi = service.harvestKpi;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _KpiCard('Tổng cua có thể thu hoạch', '${kpi.harvestable}', 'con'),
            _KpiCard(
              'Cua lột chờ xuất',
              '${service.softshellHarvestable.length}',
              'con',
            ),
            _KpiCard('Đã thu hoạch hôm nay', '${kpi.harvestedToday}', 'con'),
            _KpiCard('Chờ bán', '${kpi.waitingSale}', 'con'),
            _KpiCard(
              'Tổng trọng lượng thu hoạch',
              kpi.totalWeightKg.toStringAsFixed(2),
              'kg',
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            FilledButton.icon(
              onPressed: () => showCreateHarvestSlipDialog(context, service),
              style: FilledButton.styleFrom(
                backgroundColor: DashboardColors.cyan,
              ),
              icon: const Icon(Icons.add),
              label: const Text('+ Tạo phiếu thu hoạch'),
            ),
            FilledButton.icon(
              onPressed: () => showCreateHarvestSlipDialog(
                context,
                service,
                softshellMode: true,
              ),
              style: FilledButton.styleFrom(
                backgroundColor: DashboardColors.purple,
              ),
              icon: const Icon(Icons.outbox_outlined),
              label: const Text('Xuất cua lột'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (service.loading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          )
        else if (service.harvestSlips.isEmpty)
          GlassCard(
            child: Text(
              'Chưa có phiếu. Thu hoạch cứng hoặc Xuất cua lột để đưa cua vào tồn kho.',
              style: GoogleFonts.notoSans(color: DashboardColors.textMuted),
            ),
          )
        else
          for (final slip in service.harvestSlips) ...[
            _HarvestSlipCard(slip: slip),
            const SizedBox(height: 10),
          ],
      ],
    );
  }
}

class _SalesTab extends StatelessWidget {
  const _SalesTab({required this.service});

  final HarvestSalesService service;

  @override
  Widget build(BuildContext context) {
    final kpi = service.salesKpi;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _KpiCard(
              'Doanh thu hôm nay',
              formatVnd(kpi.revenueTodayVnd),
              '',
            ),
            _KpiCard('Đã bán', '${kpi.soldToday}', 'cua'),
            _KpiCard('Tồn kho', '${kpi.inventory}', 'cua'),
          ],
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.icon(
            onPressed: () => showCreateSalesOrderDialog(context, service),
            style: FilledButton.styleFrom(
              backgroundColor: DashboardColors.purple,
            ),
            icon: const Icon(Icons.point_of_sale_outlined),
            label: const Text('+ Tạo đơn bán hàng'),
          ),
        ),
        const SizedBox(height: 16),
        if (service.loading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          )
        else if (service.salesOrders.isEmpty)
          GlassCard(
            child: Text(
              'Chưa có đơn bán. Cua sau thu hoạch vào kho — chọn cua tồn kho để tạo SALE-001.',
              style: GoogleFonts.notoSans(color: DashboardColors.textMuted),
            ),
          )
        else
          for (final order in service.salesOrders) ...[
            _SalesOrderCard(order: order, service: service),
            const SizedBox(height: 10),
          ],
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard(this.title, this.value, this.unit);

  final String title;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.notoSans(
                color: DashboardColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text.rich(
              TextSpan(
                text: value,
                style: GoogleFonts.notoSans(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                children: [
                  if (unit.isNotEmpty)
                    TextSpan(
                      text: ' $unit',
                      style: GoogleFonts.notoSans(
                        fontSize: 12,
                        color: DashboardColors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HarvestSlipCard extends StatelessWidget {
  const _HarvestSlipCard({required this.slip});

  final HarvestSlipDetail slip;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: () => showHarvestSlipDetailDialog(context, slip),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  slip.code,
                  style: GoogleFonts.notoSans(fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                slip.statusLabel,
                style: GoogleFonts.notoSans(
                  color: DashboardColors.healthy,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            slip.harvestDate,
            style: GoogleFonts.notoSans(
              color: DashboardColors.textMuted,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${slip.area} · ${slip.quantity} cua · ${slip.totalWeightKg.toStringAsFixed(2)} kg'
            ' · TB ${slip.averageWeightG.toStringAsFixed(0)}g · Đạt ${slip.passedCount}'
            '${slip.lines.where((l) => l.isSoftshell).isEmpty ? '' : ' · Cua lột ${slip.lines.where((l) => l.isSoftshell).length}'}',
            style: GoogleFonts.notoSans(fontSize: 13),
          ),
          if (slip.performedBy.isNotEmpty)
            Text(
              'Người thực hiện: ${slip.performedBy}',
              style: GoogleFonts.notoSans(
                color: DashboardColors.textMuted,
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }
}

class _SalesOrderCard extends StatelessWidget {
  const _SalesOrderCard({required this.order, required this.service});

  final SalesOrderDetail order;
  final HarvestSalesService service;

  @override
  Widget build(BuildContext context) {
    final statusColor = order.isCancelled
        ? DashboardColors.risk
        : order.isDraft
            ? DashboardColors.monitoring
            : DashboardColors.healthy;
    final payColor = order.isPaid
        ? DashboardColors.healthy
        : order.isPartial
            ? DashboardColors.monitoring
            : DashboardColors.risk;
    return GlassCard(
      onTap: () => showSalesOrderDetailDialog(context, order, service: service),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      order.code,
                      style: GoogleFonts.notoSans(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      order.orderStatusLabel,
                      style: GoogleFonts.notoSans(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Khách: ${order.customerName}',
                  style: GoogleFonts.notoSans(fontSize: 13),
                ),
                Text(
                  '${order.crabCount} cua · ${order.totalWeightKg.toStringAsFixed(2)} kg'
                  ' · ${formatHarvestDateTime(order.orderDate)}',
                  style: GoogleFonts.notoSans(
                    color: DashboardColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatVnd(order.revenueVnd),
                style: GoogleFonts.notoSans(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                order.paymentStatusLabel,
                style: GoogleFonts.notoSans(
                  color: payColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
