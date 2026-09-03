import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/crab_batch.dart';
import '../../services/batch_service.dart';
import '../../theme/dashboard_theme.dart';
import '../../widgets/batch/batch_detail_widgets.dart';
import '../../widgets/batch/batch_dialogs.dart';
import '../../widgets/batch/batch_status_badge.dart';

class BatchDetailPage extends StatelessWidget {
  const BatchDetailPage({
    super.key,
    required this.batch,
    required this.service,
    required this.onBack,
  });

  final CrabBatch batch;
  final BatchService service;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'Lứa nuôi',
                style: GoogleFonts.notoSans(
                  color: DashboardColors.textMuted,
                  fontSize: 13,
                ),
              ),
              Text(
                '  >  ',
                style: GoogleFonts.notoSans(color: DashboardColors.textMuted),
              ),
              Text(
                'Chi tiết',
                style: GoogleFonts.notoSans(
                  color: DashboardColors.cyan,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        'Chi tiết Lứa: ${batch.id}',
                        style: GoogleFonts.notoSans(
                          color: DashboardColors.textPrimary,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    BatchStatusBadge(status: batch.status),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.download_outlined, size: 18),
                label: const Text('Xuất báo cáo'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: DashboardColors.textMuted,
                  side: BorderSide(color: DashboardColors.cardBorder),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => showEndBatchDialog(context, service, batch),
                icon: const Icon(Icons.stop_circle_outlined, size: 18),
                label: const Text('Kết thúc lứa'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: DashboardColors.risk,
                  side: const BorderSide(color: DashboardColors.risk),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          BatchDetailKpiRow(batch: batch),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, c) {
              final wide = c.maxWidth > 1100;
              if (wide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 300, child: BatchInfoCard(batch: batch)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        children: [
                          WeightGrowthChart(batch: batch),
                          const SizedBox(height: 16),
                          SurvivalChart(batch: batch),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 300,
                      child: Column(
                        children: [
                          CrabDistributionChart(batch: batch),
                          const SizedBox(height: 16),
                          BatchTimelineWidget(batch: batch),
                        ],
                      ),
                    ),
                  ],
                );
              }
              return Column(
                children: [
                  BatchInfoCard(batch: batch),
                  const SizedBox(height: 16),
                  WeightGrowthChart(batch: batch),
                  const SizedBox(height: 16),
                  SurvivalChart(batch: batch),
                  const SizedBox(height: 16),
                  CrabDistributionChart(batch: batch),
                  const SizedBox(height: 16),
                  BatchTimelineWidget(batch: batch),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          _StatsPanel(batch: batch),
        ],
      ),
    );
  }
}

class _StatsPanel extends StatelessWidget {
  const _StatsPanel({required this.batch});

  final CrabBatch batch;

  @override
  Widget build(BuildContext context) {
    final survival = batch.survivalRate;
    final growth = batch.avgWeightGram - batch.initialWeightGram;
    final fcr = 1.35;
    final profit = batch.revenueMillion * 0.35;

    final stats = [
      ('Số lượng thả', '${batch.initialQuantity}'),
      ('Số lượng sống', '${batch.aliveCount}'),
      ('Số lượng chết', '${batch.deadCount}'),
      ('Tỷ lệ sống', '${survival.toStringAsFixed(1)}%'),
      ('Tăng trưởng TB', '+${growth.toStringAsFixed(0)}g'),
      ('FCR', fcr.toStringAsFixed(2)),
      ('Sản lượng', '${(batch.aliveCount * batch.avgWeightGram / 1000).toStringAsFixed(0)} kg'),
      ('Doanh thu', '${batch.revenueMillion.toStringAsFixed(0)} triệu'),
      ('Lợi nhuận', '${profit.toStringAsFixed(1)} triệu'),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DashboardColors.card.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DashboardColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thống kê lứa (tự động tính)',
            style: GoogleFonts.notoSans(
              color: DashboardColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 24,
            runSpacing: 12,
            children: stats
                .map(
                  (s) => SizedBox(
                    width: 180,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.$1,
                          style: GoogleFonts.notoSans(
                            color: DashboardColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          s.$2,
                          style: GoogleFonts.notoSans(
                            color: DashboardColors.cyan,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
