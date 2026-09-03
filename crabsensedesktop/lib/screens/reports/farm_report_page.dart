import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/mock_farm_report_data.dart';
import '../../models/farm_report.dart';
import '../../services/farm_report_service.dart';
import '../../theme/dashboard_theme.dart';
import '../../widgets/reports/farm_report_widgets.dart';

class FarmReportPage extends StatefulWidget {
  const FarmReportPage({super.key, required this.service});

  final FarmReportService service;

  @override
  State<FarmReportPage> createState() => _FarmReportPageState();
}

class _FarmReportPageState extends State<FarmReportPage> {
  static const _aiPanelWidth = 272.0;

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

  void _export(String type) {
    if (type == 'pdf') {
      widget.service.exportPdf();
    } else {
      widget.service.exportExcel();
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đang xuất báo cáo $type (demo)...')),
    );
  }

  Widget _chartsRow(FarmReportService service, FarmReportKpi kpi) {
    return LayoutBuilder(
      builder: (context, inner) {
        final bar = SurvivalGrowthBarChartCard(periods: service.survivalGrowthBars);
        final pie = ReportCostPieCard(
          segments: service.costAllocation,
          totalLabel: MockFarmReportData.formatVndShort(kpi.totalCostVnd),
        );
        final resources = ReportResourcesCard(items: service.resources);

        if (inner.maxWidth > 960) {
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 3, child: bar),
                const SizedBox(width: 14),
                Expanded(flex: 2, child: pie),
                const SizedBox(width: 14),
                Expanded(flex: 2, child: resources),
              ],
            ),
          );
        }
        if (inner.maxWidth > 560) {
          return Column(
            children: [
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(flex: 3, child: bar),
                    const SizedBox(width: 14),
                    Expanded(flex: 2, child: pie),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              resources,
            ],
          );
        }
        return Column(
          children: [
            bar,
            const SizedBox(height: 14),
            pie,
            const SizedBox(height: 14),
            resources,
          ],
        );
      },
    );
  }

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
            'Báo Cáo Thống Kê',
            style: GoogleFonts.notoSans(
              color: DashboardColors.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ReportToolbar(
            service: service,
            onExportPdf: () => _export('PDF'),
            onExportExcel: () => _export('Excel'),
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, c) {
              final wide = c.maxWidth > 1050;
              final main = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ReportKpiGrid(kpi: kpi),
                  const SizedBox(height: 16),
                  _chartsRow(service, kpi),
                  const SizedBox(height: 16),
                  ReportDailyTableCard(rows: service.dailyRows),
                ],
              );

              final aiPanel = ReportAiPanel(
                summary: service.aiSummary,
                analysis: service.aiAnalysis,
                actions: service.aiActions,
                onChat: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Mở chat AI (demo)')),
                  );
                },
              );

              if (wide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: main),
                    const SizedBox(width: 16),
                    SizedBox(width: _aiPanelWidth, child: aiPanel),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  main,
                  const SizedBox(height: 16),
                  aiPanel,
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
