import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/farm_activity_log.dart';
import '../../services/farm_log_service.dart';
import '../../theme/dashboard_theme.dart';
import '../../widgets/logs/farm_log_dialogs.dart';
import '../../widgets/logs/farm_log_widgets.dart';

class FarmActivityLogPage extends StatefulWidget {
  const FarmActivityLogPage({super.key, required this.service});

  final FarmLogService service;

  @override
  State<FarmActivityLogPage> createState() => _FarmActivityLogPageState();
}

class _FarmActivityLogPageState extends State<FarmActivityLogPage> {
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

  void _openDetail(FarmActivityLogEntry entry) {
    FarmLogDetailSheet.show(context, entry);
  }

  @override
  Widget build(BuildContext context) {
    final service = widget.service;
    final entries = service.filteredEntries;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Nhật Ký Nuôi',
            style: GoogleFonts.notoSans(
              color: DashboardColors.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          FarmLogKpiStrip(kpi: service.kpi),
          const SizedBox(height: 20),
          FarmLogToolbar(
            service: service,
            onAdd: () => showAddFarmLogDialog(context, service),
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, c) {
              final wide = c.maxWidth > 1050;
              final table = FarmLogTable(
                entries: entries,
                service: service,
                selectedId: service.selectedEntry?.id,
                onViewDetail: _openDetail,
              );
              final ai = FarmLogAiPanel(summary: service.aiSummary);

              if (wide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 7, child: table),
                    const SizedBox(width: 20),
                    SizedBox(width: 300, child: ai),
                  ],
                );
              }
              return Column(
                children: [
                  table,
                  const SizedBox(height: 16),
                  ai,
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
