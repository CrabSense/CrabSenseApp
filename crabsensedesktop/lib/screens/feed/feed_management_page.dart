import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/feed_service.dart';
import '../../theme/dashboard_theme.dart';
import '../../widgets/feed/feed_dialogs.dart';
import '../../widgets/feed/feed_management_widgets.dart';

class FeedManagementPage extends StatefulWidget {
  const FeedManagementPage({super.key, required this.service});

  final FeedService service;

  @override
  State<FeedManagementPage> createState() => _FeedManagementPageState();
}

class _FeedManagementPageState extends State<FeedManagementPage> {
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

    return Stack(
      children: [
        SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Quản Lý Thức Ăn',
            style: GoogleFonts.notoSans(
              color: DashboardColors.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (service.error != null) ...[
            const SizedBox(height: 12),
            Text(
              service.error!,
              style: GoogleFonts.notoSans(
                color: DashboardColors.risk,
                fontSize: 13,
              ),
            ),
          ],
          const SizedBox(height: 20),
          FeedKpiStrip(kpi: service.kpi),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, c) {
              final wide = c.maxWidth > 1050;
              final left = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FeedInventoryCard(
                    items: service.inventory,
                    onImport: () => showFeedImportDialog(context, service),
                    onExport: () => showFeedExportDialog(context, service),
                  ),
                  const SizedBox(height: 16),
                  FeedConsumptionCard(service: service),
                ],
              );
              final right = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FeedAssistantCard(
                    insight: service.aiInsight,
                    recommendation: service.aiRecommendation,
                  ),
                  const SizedBox(height: 16),
                  FeedScheduleCard(
                    schedule: service.schedule,
                    service: service,
                    onCreateSchedule: () =>
                        showCreateFeedingScheduleDialog(context, service),
                  ),
                ],
              );

              if (wide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: left),
                    const SizedBox(width: 20),
                    Expanded(flex: 2, child: right),
                  ],
                );
              }
              return Column(
                children: [
                  left,
                  const SizedBox(height: 16),
                  right,
                ],
              );
            },
          ),
        ],
      ),
    ),
        if (service.loading)
          const Positioned.fill(
            child: ColoredBox(
              color: Color(0x44000000),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }
}
