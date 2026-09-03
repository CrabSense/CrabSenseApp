import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/harvest_sales_service.dart';
import '../../theme/dashboard_theme.dart';
import '../../widgets/harvest/harvest_sales_dialogs.dart';
import '../../widgets/harvest/harvest_sales_widgets.dart';

class HarvestSalesPage extends StatefulWidget {
  const HarvestSalesPage({super.key, required this.service});

  final HarvestSalesService service;

  @override
  State<HarvestSalesPage> createState() => _HarvestSalesPageState();
}

class _HarvestSalesPageState extends State<HarvestSalesPage> {
  @override
  void initState() {
    super.initState();
    widget.service.addListener(_onUpdate);
  }

  @override
  void dispose() {
    widget.service.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final service = widget.service;
    final kpi = service.kpi;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Thu Hoạch & Bán Hàng',
            style: GoogleFonts.notoSans(
              color: DashboardColors.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          HarvestKpiStrip(kpi: kpi),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, c) {
              final wide = c.maxWidth > 1100;
              final main = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LayoutBuilder(
                    builder: (context, inner) {
                      final chartWide = inner.maxWidth > 700;
                      final charts = [
                        HarvestRevenueChartCard(points: service.monthlyFinance),
                        HarvestSizePieCard(
                          segments: service.sizeDistribution,
                          totalCount: kpi.qualifiedCrabCount,
                        ),
                      ];
                      if (chartWide) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 3, child: charts[0]),
                            const SizedBox(width: 16),
                            Expanded(flex: 2, child: charts[1]),
                          ],
                        );
                      }
                      return Column(
                        children: [
                          charts[0],
                          const SizedBox(height: 16),
                          charts[1],
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, inner) {
                      if (inner.maxWidth > 700) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: QualifiedCrabsTableCard(
                                crabs: service.qualifiedCrabs,
                                onViewAll: () {},
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: RecentOrdersTableCard(
                                orders: service.orders,
                                onOrderTap: (o) =>
                                    showSalesOrderDetailDialog(context, o),
                                onFilter: () {},
                              ),
                            ),
                          ],
                        );
                      }
                      return Column(
                        children: [
                          QualifiedCrabsTableCard(
                            crabs: service.qualifiedCrabs,
                            onViewAll: () {},
                          ),
                          const SizedBox(height: 16),
                          RecentOrdersTableCard(
                            orders: service.orders,
                            onOrderTap: (o) =>
                                showSalesOrderDetailDialog(context, o),
                            onFilter: () {},
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  HarvestBatchProfitCard(points: service.batchProfits),
                ],
              );

              final side = HarvestAssistantPanel(
                insight: service.aiInsight,
                recommendation: service.aiRecommendation,
                market: service.market,
                onCreateHarvest: () =>
                    showCreateHarvestSlipDialog(context, service),
              );

              if (wide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: main),
                    const SizedBox(width: 20),
                    Expanded(flex: 2, child: side),
                  ],
                );
              }
              return Column(
                children: [
                  side,
                  const SizedBox(height: 16),
                  main,
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
