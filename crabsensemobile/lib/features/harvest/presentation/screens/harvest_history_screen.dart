import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme.dart';
import '../../../../core/di/injection.dart';
import '../../domain/entities/harvest.dart';
import '../bloc/harvest_history_bloc.dart';
import '../bloc/harvest_history_event.dart';
import '../bloc/harvest_history_state.dart';
import '../widgets/harvest_summary_card.dart';

/// Screen displaying Harvest History with filterable date range, weekly cumulative weight analytics,
/// quality grade breakdown, and CSV export functionality.
///
/// Requirements: 11.9, 11.10
class HarvestHistoryScreen extends StatelessWidget {
  const HarvestHistoryScreen({
    this.initialFarmId,
    this.initialBoxId,
    this.initialStartDate,
    this.initialEndDate,
    super.key,
  });

  final String? initialFarmId;
  final String? initialBoxId;
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<HarvestHistoryBloc>(
      create: (_) => sl<HarvestHistoryBloc>()
        ..add(
          LoadHarvestHistory(
            farmId: initialFarmId,
            boxId: initialBoxId,
            startDate: initialStartDate,
            endDate: initialEndDate,
          ),
        ),
      child: const _HarvestHistoryView(),
    );
  }
}

class _HarvestHistoryView extends StatefulWidget {
  const _HarvestHistoryView();

  @override
  State<_HarvestHistoryView> createState() => _HarvestHistoryViewState();
}

class _HarvestHistoryViewState extends State<_HarvestHistoryView> {
  final TextEditingController _farmController = TextEditingController();
  bool _showSummary = true;

  @override
  void dispose() {
    _farmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Harvest History & Analytics',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFFFFFFF),
        foregroundColor: CrabSenseColors.textPrimary,
        elevation: 0,
        actions: [
          BlocConsumer<HarvestHistoryBloc, HarvestHistoryState>(
            listener: (context, state) {
              if (state is HarvestHistoryLoaded) {
                if (state.exportMessage != null) {
                  final isError = state.exportMessage!.startsWith('Failed');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.exportMessage!),
                      backgroundColor: isError ? CrabSenseColors.error : CrabSenseColors.success,
                      duration: const Duration(seconds: 4),
                      action: state.exportedFilePath != null
                          ? SnackBarAction(
                              label: 'OK',
                              textColor: Colors.white,
                              onPressed: () {},
                            )
                          : null,
                    ),
                  );
                }
              }
            },
            builder: (context, state) {
              final isExporting = state is HarvestHistoryLoaded && state.isExporting;
              return IconButton(
                icon: isExporting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: CrabSenseColors.primary,
                        ),
                      )
                    : const Icon(Icons.download_rounded, color: CrabSenseColors.primary),
                tooltip: 'Export CSV',
                onPressed: isExporting
                    ? null
                    : () {
                        context.read<HarvestHistoryBloc>().add(const ExportHarvestHistoryToCsv());
                      },
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<HarvestHistoryBloc, HarvestHistoryState>(
        builder: (context, state) {
          if (state is HarvestHistoryLoading || state is HarvestHistoryInitial) {
            return const Center(
              child: CircularProgressIndicator(color: CrabSenseColors.primary),
            );
          }

          if (state is HarvestHistoryError) {
            return _buildErrorView(context, state.message);
          }

          if (state is HarvestHistoryLoaded) {
            return Column(
              children: [
                _buildFilterBar(context, state),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      context.read<HarvestHistoryBloc>().add(
                            LoadHarvestHistory(
                              startDate: state.startDate,
                              endDate: state.endDate,
                              farmId: state.farmId,
                              qualityGrade: state.qualityGrade,
                            ),
                          );
                    },
                    color: CrabSenseColors.primary,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Toggle Summary / Analytics view
                          if (state.summary != null) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Summary Statistics',
                                  style: TextStyle(
                                    color: CrabSenseColors.textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _showSummary = !_showSummary;
                                    });
                                  },
                                  icon: Icon(
                                    _showSummary ? Icons.expand_less : Icons.expand_more,
                                    size: 18,
                                    color: CrabSenseColors.primary,
                                  ),
                                  label: Text(
                                    _showSummary ? 'Hide Summary' : 'Show Summary',
                                    style: const TextStyle(color: CrabSenseColors.primary),
                                  ),
                                ),
                              ],
                            ),
                            if (_showSummary) ...[
                              const SizedBox(height: 8),
                              HarvestSummaryCard(
                                summary: state.summary!,
                                weeklyCumulativeWeights: state.weeklyCumulativeWeights,
                              ),
                              const SizedBox(height: 20),
                            ],
                          ],

                          // History List Section Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Harvest History (${state.harvests.length})',
                                style: const TextStyle(
                                  color: CrabSenseColors.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (state.harvests.isNotEmpty)
                                Text(
                                  'Showing latest',
                                  style: const TextStyle(
                                    color: CrabSenseColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          if (state.harvests.isEmpty)
                            _buildEmptyState(context)
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: state.harvests.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                return _buildHarvestCard(context, state.harvests[index]);
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  // ── Filter Bar Component ──────────────────────────────────────────────────

  Widget _buildFilterBar(BuildContext context, HarvestHistoryLoaded state) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final hasDateFilter = state.startDate != null || state.endDate != null;
    final dateRangeLabel = hasDateFilter
        ? '${state.startDate != null ? dateFormat.format(state.startDate!) : "Start"} - ${state.endDate != null ? dateFormat.format(state.endDate!) : "Now"}'
        : 'Filter Date Range';

    return Container(
      color: const Color(0xFFFFFFFF),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Date Range Filter Chip
            ActionChip(
              avatar: Icon(
                Icons.date_range_rounded,
                size: 16,
                color: hasDateFilter ? CrabSenseColors.primary : CrabSenseColors.textSecondary,
              ),
              label: Text(
                dateRangeLabel,
                style: TextStyle(
                  color: hasDateFilter ? CrabSenseColors.primary : CrabSenseColors.textPrimary,
                  fontSize: 12,
                  fontWeight: hasDateFilter ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              backgroundColor: hasDateFilter
                  ? CrabSenseColors.primary.withValues(alpha: 0.1)
                  : const Color(0xFFF5F7FA),
              side: BorderSide(
                color: hasDateFilter ? CrabSenseColors.primary : CrabSenseColors.border,
              ),
              onPressed: () => _selectDateRange(context, state),
            ),
            const SizedBox(width: 8),

            // Grade Filter Dropdown
            DropdownButton<QualityGrade?>(
              value: state.qualityGrade,
              hint: const Text(
                'All Grades',
                style: TextStyle(color: CrabSenseColors.textSecondary, fontSize: 12),
              ),
              dropdownColor: const Color(0xFFFFFFFF),
              underline: const SizedBox(),
              icon: const Icon(Icons.arrow_drop_down, color: CrabSenseColors.textSecondary),
              items: [
                const DropdownMenuItem<QualityGrade?>(
                  value: null,
                  child: Text('All Grades', style: TextStyle(color: CrabSenseColors.textPrimary, fontSize: 12)),
                ),
                ...QualityGrade.values.map(
                  (grade) => DropdownMenuItem<QualityGrade?>(
                    value: grade,
                    child: Text(
                      grade.displayName,
                      style: const TextStyle(color: CrabSenseColors.textPrimary, fontSize: 12),
                    ),
                  ),
                ),
              ],
              onChanged: (grade) {
                context.read<HarvestHistoryBloc>().add(FilterQualityGradeChanged(qualityGrade: grade));
              },
            ),
            const SizedBox(width: 8),

            // Reset Filters Chip
            if (hasDateFilter || state.qualityGrade != null || state.farmId != null)
              ActionChip(
                avatar: const Icon(Icons.close_rounded, size: 14, color: CrabSenseColors.error),
                label: const Text(
                  'Reset',
                  style: TextStyle(color: CrabSenseColors.error, fontSize: 12),
                ),
                backgroundColor: CrabSenseColors.error.withValues(alpha: 0.1),
                side: const BorderSide(color: CrabSenseColors.error),
                onPressed: () {
                  context.read<HarvestHistoryBloc>().add(const LoadHarvestHistory());
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDateRange(BuildContext context, HarvestHistoryLoaded state) async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: state.startDate != null && state.endDate != null
          ? DateTimeRange(start: state.startDate!, end: state.endDate!)
          : DateTimeRange(
              start: DateTime.now().subtract(const Duration(days: 30)),
              end: DateTime.now(),
            ),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: CrabSenseColors.primary,
              onPrimary: Colors.black,
              surface: const Color(0xFFFFFFFF),
              onSurface: CrabSenseColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && context.mounted) {
      context.read<HarvestHistoryBloc>().add(
            FilterDateRangeChanged(
              startDate: picked.start,
              endDate: picked.end,
            ),
          );
    }
  }

  // ── Harvest Card ──────────────────────────────────────────────────────────

  Widget _buildHarvestCard(BuildContext context, Harvest harvest) {
    final dateFormat = DateFormat('MMM dd, yyyy · HH:mm');
    final gradeColor = _getGradeColor(harvest.qualityGrade);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CrabSenseColors.border),
      ),
      padding: const EdgeInsets.all(14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Box ID & Grade Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.widgets_rounded, size: 18, color: CrabSenseColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    'Box ${harvest.boxId}',
                    style: const TextStyle(
                      color: CrabSenseColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '(${harvest.farmId})',
                    style: const TextStyle(
                      color: CrabSenseColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: gradeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: gradeColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  harvest.qualityGrade.displayName,
                  style: TextStyle(
                    color: gradeColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Details Grid
          Row(
            children: [
              Expanded(
                child: _buildMiniDetail('Weight', '${harvest.totalWeight.toStringAsFixed(2)} kg'),
              ),
              Expanded(
                child: _buildMiniDetail('Crab Count', '${harvest.crabCount} crabs'),
              ),
              Expanded(
                child: _buildMiniDetail('Operator', harvest.operatorName),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Date & Notes Footer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dateFormat.format(harvest.harvestDate),
                style: const TextStyle(
                  color: CrabSenseColors.textSecondary,
                  fontSize: 11,
                ),
              ),
              if (harvest.photoUrls.isNotEmpty)
                Row(
                  children: [
                    const Icon(Icons.photo_camera_rounded, size: 14, color: CrabSenseColors.accent),
                    const SizedBox(width: 4),
                    Text(
                      '${harvest.photoUrls.length}',
                      style: const TextStyle(color: CrabSenseColors.accent, fontSize: 11),
                    ),
                  ],
                ),
            ],
          ),
          if (harvest.notes != null && harvest.notes!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Note: ${harvest.notes}',
              style: const TextStyle(
                color: CrabSenseColors.textSecondary,
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMiniDetail(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: CrabSenseColors.textSecondary,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: CrabSenseColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Color _getGradeColor(QualityGrade grade) {
    switch (grade) {
      case QualityGrade.gradeA:
        return CrabSenseColors.success;
      case QualityGrade.gradeB:
        return CrabSenseColors.primary;
      case QualityGrade.gradeC:
        return CrabSenseColors.warning;
      case QualityGrade.rejected:
        return CrabSenseColors.error;
    }
  }

  // ── States Views ─────────────────────────────────────────────────────────

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Icon(Icons.inbox_rounded, size: 48, color: CrabSenseColors.textSecondary),
          const SizedBox(height: 12),
          const Text(
            'No Harvest Records Found',
            style: TextStyle(
              color: CrabSenseColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Try adjusting your date range or filters.',
            style: TextStyle(color: CrabSenseColors.textSecondary, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              context.read<HarvestHistoryBloc>().add(const LoadHarvestHistory());
            },
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Reset Filters'),
            style: ElevatedButton.styleFrom(
              backgroundColor: CrabSenseColors.primary,
              foregroundColor: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: CrabSenseColors.error),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(color: CrabSenseColors.textPrimary, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                context.read<HarvestHistoryBloc>().add(const LoadHarvestHistory());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: CrabSenseColors.primary,
                foregroundColor: Colors.black,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
