import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/farm_alert.dart';
import '../../services/alert_service.dart';
import '../../theme/dashboard_theme.dart';
import '../../widgets/alerts/alert_system_widgets.dart';

class AlertSystemPage extends StatefulWidget {
  const AlertSystemPage({super.key, required this.service});

  final AlertService service;

  @override
  State<AlertSystemPage> createState() => _AlertSystemPageState();
}

class _AlertSystemPageState extends State<AlertSystemPage> {
  @override
  void initState() {
    super.initState();
    widget.service.addListener(_onUpdate);
    widget.service.load();
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
    final alerts = service.filteredAlerts;
    final selected = service.selectedAlert;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Hệ Thống Cảnh Báo',
            style: GoogleFonts.notoSans(
              color: DashboardColors.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Theo dõi và xử lý cảnh báo realtime',
            style: GoogleFonts.notoSans(
              color: DashboardColors.textMuted,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          AlertQuickStatsBar(kpi: service.kpi),
          const SizedBox(height: 20),
          AlertKpiStrip(kpi: service.kpi),
          const SizedBox(height: 16),
          AlertFilterChips(
            selected: service.filter,
            onSelect: service.setFilter,
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, c) {
              final wide = c.maxWidth > 1100;
              final main = _MainContent(
                service: service,
                alerts: alerts,
                selected: selected,
              );
              final side = _SideContent(service: service);
              if (wide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: main),
                    const SizedBox(width: 16),
                    Expanded(flex: 2, child: side),
                  ],
                );
              }
              return Column(
                children: [
                  main,
                  const SizedBox(height: 16),
                  side,
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MainContent extends StatelessWidget {
  const _MainContent({
    required this.service,
    required this.alerts,
    required this.selected,
  });

  final AlertService service;
  final List<FarmAlert> alerts;
  final FarmAlert? selected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AlertTable(
          alerts: alerts,
          service: service,
          selectedId: selected?.id,
        ),
        if (selected != null) ...[
          const SizedBox(height: 16),
          AlertDetailPanel(alert: selected!, service: service),
        ],
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, c) {
            final cols = c.maxWidth > 700 ? 2 : 1;
            final open = service.filteredAlerts
                .where((a) => a.isOpen && a.level == AlertLevel.critical)
                .take(4)
                .toList();
            if (open.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Card cảnh báo',
                  style: GoogleFonts.notoSans(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 10),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.35,
                  ),
                  itemCount: open.length,
                  itemBuilder: (_, i) => AlertCardPreview(
                    alert: open[i],
                    service: service,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        AlertHistoryTable(rows: service.history),
        const SizedBox(height: 16),
        AlertNotificationRules(rules: service.channelRules),
      ],
    );
  }
}

class _SideContent extends StatelessWidget {
  const _SideContent({required this.service});

  final AlertService service;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AlertSpotlightCard(
          alert: service.spotlight,
          service: service,
        ),
        const SizedBox(height: 16),
        AlertAssistantPanel(
          insight: service.aiInsight,
          recommendations: service.aiRecommendations,
          onActionTap: (action) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Đã chọn: $action')),
            );
          },
        ),
        const SizedBox(height: 16),
        AlertFrequencyChart(points: service.frequency),
      ],
    );
  }
}
