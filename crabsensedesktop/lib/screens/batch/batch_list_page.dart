import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/mock_batch_data.dart';
import '../../models/crab_batch.dart';
import '../../services/batch_service.dart';
import '../../theme/dashboard_theme.dart';
import '../../widgets/batch/batch_dialogs.dart';
import '../../widgets/batch/batch_summary_kpi.dart';
import '../../widgets/batch/batch_table.dart';
import '../../widgets/dashboard/glass_card.dart';

class BatchListPage extends StatelessWidget {
  const BatchListPage({
    super.key,
    required this.service,
    required this.onViewBatch,
  });

  final BatchService service;
  final ValueChanged<CrabBatch> onViewBatch;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: service,
      builder: (context, _) {
        final kpis = MockBatchData.summaryKpis(service.batches);
        final pageItems = service.paginatedBatches;
        final start = service.totalCount == 0
            ? 0
            : (service.currentPage - 1) * service.pageSize + 1;
        final end = (service.currentPage * service.pageSize)
            .clamp(0, service.totalCount);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quản Lý Lứa Nuôi',
                          style: GoogleFonts.notoSans(
                            color: DashboardColors.textPrimary,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Theo dõi và tối ưu hóa hiệu suất nuôi trồng theo từng đợt.',
                          style: GoogleFonts.notoSans(
                            color: DashboardColors.textMuted,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => showCreateBatchDialog(context, service),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Tạo lứa mới'),
                    style: FilledButton.styleFrom(
                      backgroundColor: DashboardColors.purple,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              BatchSummaryKpiRow(items: kpis),
              const SizedBox(height: 28),
              GlassCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Danh sách chi tiết',
                          style: GoogleFonts.notoSans(
                            color: DashboardColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.filter_list, size: 16),
                          label: const Text('Lọc'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: DashboardColors.textMuted,
                            side: BorderSide(color: DashboardColors.cardBorder),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.download_outlined, size: 16),
                          label: const Text('Xuất báo cáo'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: DashboardColors.textMuted,
                            side: BorderSide(color: DashboardColors.cardBorder),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    BatchDataTable(
                      batches: pageItems,
                      onAction: (batch, action) => _handleAction(
                        context,
                        batch,
                        action,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text(
                          'Hiển thị $start–$end trên tổng số ${service.totalCount} lứa',
                          style: GoogleFonts.notoSans(
                            color: DashboardColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        _Pagination(
                          current: service.currentPage,
                          total: service.totalPages,
                          onPage: service.goToPage,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleAction(BuildContext context, CrabBatch batch, BatchAction action) {
    switch (action) {
      case BatchAction.view:
      case BatchAction.stats:
        onViewBatch(batch);
      case BatchAction.edit:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Chỉnh sửa ${batch.id} — đang phát triển'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      case BatchAction.end:
        showEndBatchDialog(context, service, batch);
    }
  }
}

class _Pagination extends StatelessWidget {
  const _Pagination({
    required this.current,
    required this.total,
    required this.onPage,
  });

  final int current;
  final int total;
  final ValueChanged<int> onPage;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _pageBtn(Icons.chevron_left, current > 1 ? () => onPage(current - 1) : null),
        for (var i = 1; i <= total; i++) ...[
          const SizedBox(width: 4),
          _numBtn(i, i == current),
        ],
        const SizedBox(width: 4),
        _pageBtn(
          Icons.chevron_right,
          current < total ? () => onPage(current + 1) : null,
        ),
      ],
    );
  }

  Widget _pageBtn(IconData icon, VoidCallback? onTap) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, size: 20, color: DashboardColors.textMuted),
      style: IconButton.styleFrom(
        backgroundColor: DashboardColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _numBtn(int page, bool active) {
    return Material(
      color: active ? DashboardColors.purple : DashboardColors.card,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: active ? null : () => onPage(page),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          child: Text(
            '$page',
            style: GoogleFonts.notoSans(
              color: active ? Colors.white : DashboardColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
