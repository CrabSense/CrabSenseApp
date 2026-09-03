import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/crab_status.dart';
import '../../services/crab_service.dart';
import '../../theme/dashboard_theme.dart';
import '../../widgets/crab/crab_detail_widgets.dart';
import '../../widgets/crab/crab_dialogs.dart';

class CrabDetailPage extends StatelessWidget {
  const CrabDetailPage({
    super.key,
    required this.crabId,
    required this.service,
    required this.onBack,
    this.onOpenHealth,
  });

  final String crabId;
  final CrabService service;
  final VoidCallback onBack;
  final VoidCallback? onOpenHealth;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: service,
      builder: (context, _) {
        final crab = service.getById(crabId);
        if (crab == null) {
          return Center(
            child: Text(
              'Không tìm thấy cá thể',
              style: GoogleFonts.notoSans(color: DashboardColors.textMuted),
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(
                    'Cá thể cua',
                    style: GoogleFonts.notoSans(color: DashboardColors.textMuted, fontSize: 13),
                  ),
                  Text('  >  ', style: GoogleFonts.notoSans(color: DashboardColors.textMuted)),
                  Text(
                    crab.id,
                    style: GoogleFonts.notoSans(color: DashboardColors.cyan, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Hồ sơ cua: ${crab.id}',
                    style: GoogleFonts.notoSans(
                      color: DashboardColors.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Hộp ${crab.boxId} | Lứa ${crab.batchId}',
                    style: GoogleFonts.notoSans(color: DashboardColors.textMuted, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Trọng lượng: ${crab.weightGram.toStringAsFixed(0)}g · Sức khỏe: ${crab.healthStatus.label}',
                    style: GoogleFonts.notoSans(color: DashboardColors.cyan, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (onOpenHealth != null)
                        FilledButton.icon(
                          onPressed: onOpenHealth,
                          icon: const Icon(Icons.monitor_heart_outlined, size: 18),
                          label: const Text('Giám sát sức khỏe AI'),
                          style: FilledButton.styleFrom(
                            backgroundColor: DashboardColors.cyan,
                          ),
                        ),
                      OutlinedButton(
                        onPressed: () => showUpdateWeightDialog(context, service, crab),
                        child: const Text('Cập nhật cân nặng'),
                      ),
                      OutlinedButton(
                        onPressed: () => showRecordMoltDialog(context, service, crab),
                        child: const Text('Ghi nhận lột xác'),
                      ),
                      OutlinedButton(
                        onPressed: () => showRecordDiseaseDialog(context, service, crab),
                        child: const Text('Lưu bệnh án'),
                      ),
                      OutlinedButton(
                        onPressed: () => showUpdateStatusDialog(context, service, crab),
                        child: const Text('Trạng thái'),
                      ),
                      if (crab.lifeStatus != CrabLifeStatus.dead)
                        OutlinedButton(
                          onPressed: () => showMarkDeadDialog(context, service, crab),
                          style: OutlinedButton.styleFrom(foregroundColor: DashboardColors.risk),
                          child: const Text('Đánh dấu chết'),
                        ),
                      FilledButton.icon(
                        onPressed: () => showMarkReadyForSaleDialog(context, service, crab),
                        icon: const Icon(Icons.sell_outlined, size: 18),
                        label: const Text('Sẵn sàng bán'),
                        style: FilledButton.styleFrom(
                          backgroundColor: DashboardColors.purple,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              CrabHealthHeaderBadge(crab: crab),
              const SizedBox(height: 24),
              CrabDetailKpiRow(crab: crab),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, c) {
                  final wide = c.maxWidth > 1100;
                  if (wide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 280,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CrabPhotoCard(crab: crab),
                              const SizedBox(height: 16),
                              CrabInfoCard(crab: crab),
                              const SizedBox(height: 16),
                              CrabQuickNoteCard(crab: crab),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Flexible(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CrabWeightChart(crab: crab),
                              const SizedBox(height: 16),
                              CrabFeedingTable(crab: crab),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        SizedBox(
                          width: 300,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CrabMoltTimeline(crab: crab),
                              const SizedBox(height: 16),
                              CrabDiseaseList(crab: crab),
                              const SizedBox(height: 16),
                              CrabEnvironmentCard(crab: crab),
                            ],
                          ),
                        ),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      CrabPhotoCard(crab: crab),
                      const SizedBox(height: 16),
                      CrabInfoCard(crab: crab),
                      const SizedBox(height: 16),
                      CrabQuickNoteCard(crab: crab),
                      const SizedBox(height: 16),
                      CrabWeightChart(crab: crab),
                      const SizedBox(height: 16),
                      CrabFeedingTable(crab: crab),
                      const SizedBox(height: 16),
                      CrabMoltTimeline(crab: crab),
                      const SizedBox(height: 16),
                      CrabDiseaseList(crab: crab),
                      const SizedBox(height: 16),
                      CrabEnvironmentCard(crab: crab),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
