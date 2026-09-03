import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/water_quality_service.dart';
import '../../theme/dashboard_theme.dart';
import '../../widgets/environment/water_quality_widgets.dart';

class WaterQualityPage extends StatefulWidget {
  const WaterQualityPage({super.key, required this.service});

  final WaterQualityService service;

  @override
  State<WaterQualityPage> createState() => _WaterQualityPageState();
}

class _WaterQualityPageState extends State<WaterQualityPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    widget.service.addListener(_onUpdate);
    widget.service.startLiveUpdates();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) setState(() {});
  }

  @override
  void dispose() {
    widget.service.stopLiveUpdates();
    widget.service.removeListener(_onUpdate);
    _tabController.dispose();
    super.dispose();
  }

  void _onUpdate() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final service = widget.service;
    final readings = service.readings;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, c) {
              final wide = c.maxWidth > 900;
              if (wide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _PageHeader(service: service),
                    ),
                    WaterQualityFilterBar(service: service),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _PageHeader(service: service),
                  const SizedBox(height: 16),
                  WaterQualityFilterBar(service: service),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          if (service.isLoading)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: LinearProgressIndicator(),
            ),
          WaterGaugeGrid(readings: readings),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, c) {
              final wide = c.maxWidth > 1000;
              if (wide) {
                return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: WaterTrendChartCard(
                          points: service.trendPoints,
                          rangeIndex: service.chartRangeIndex,
                          rangeLabel: service.chartRangeLabel,
                          rangeMinutes: service.chartRangeMinutesValue,
                          loading: service.chartLoading,
                          cloudLive: service.cloudLive,
                          onRangeChanged: service.setChartRangeIndex,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: CrabAssistantWaterCard(
                          insight: service.aiInsight,
                          recommendations: service.aiRecommendations,
                        ),
                      ),
                    ],
                  );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  WaterTrendChartCard(
                    points: service.trendPoints,
                    rangeIndex: service.chartRangeIndex,
                    rangeLabel: service.chartRangeLabel,
                    rangeMinutes: service.chartRangeMinutesValue,
                    loading: service.chartLoading,
                    cloudLive: service.cloudLive,
                    onRangeChanged: service.setChartRangeIndex,
                  ),
                  const SizedBox(height: 16),
                  CrabAssistantWaterCard(
                    insight: service.aiInsight,
                    recommendations: service.aiRecommendations,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          _BottomTabs(controller: _tabController),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _buildTabBody(service),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBody(WaterQualityService service) {
    return switch (_tabController.index) {
      0 => WaterStatusTable(
          key: const ValueKey('status'),
          readings: service.statusFilter == 'Tất cả'
              ? service.readings
              : service.filteredReadings,
        ),
      1 => WaterHistoryTable(
          key: const ValueKey('history'),
          rows: service.history,
        ),
      _ => const WaterAlertLegend(key: ValueKey('alerts')),
    };
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.service});

  final WaterQualityService service;

  @override
  Widget build(BuildContext context) {
    final last = service.lastRealtimeAt;
    final lastStr = last != null
        ? '${last.hour.toString().padLeft(2, '0')}:'
            '${last.minute.toString().padLeft(2, '0')}:'
            '${last.second.toString().padLeft(2, '0')}'
        : '—';
    final subtitle = service.cloudLive
        ? 'Cloud realtime 3s · ${service.deviceMac ?? "—"}'
            '${service.deviceCode != null ? " (${service.deviceCode})" : ""}'
            ' · cập nhật $lastStr'
        : service.cloudError != null
            ? 'Mock (Cloud lỗi: ${service.cloudError})'
            : 'Theo dõi chất lượng nước — đang tải Cloud...';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Cảm Biến Môi Trường',
                style: GoogleFonts.notoSans(
                  color: DashboardColors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (service.cloudLive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: DashboardColors.healthy.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: DashboardColors.healthy.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  'Cloud',
                  style: GoogleFonts.notoSans(
                    color: DashboardColors.healthy,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            IconButton(
              tooltip: 'Tải lại từ Cloud',
              onPressed: service.isLoading
                  ? null
                  : () => service.refresh(full: true),
              icon: const Icon(Icons.refresh, size: 20),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: GoogleFonts.notoSans(
            color: DashboardColors.textMuted,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class _BottomTabs extends StatelessWidget {
  const _BottomTabs({required this.controller});

  final TabController controller;

  @override
  Widget build(BuildContext context) {
    return TabBar(
      controller: controller,
      isScrollable: true,
      labelColor: DashboardColors.textPrimary,
      unselectedLabelColor: DashboardColors.textMuted,
      indicatorColor: DashboardColors.purple,
      labelStyle: GoogleFonts.notoSans(fontWeight: FontWeight.w600, fontSize: 13),
      unselectedLabelStyle: GoogleFonts.notoSans(fontSize: 13),
      tabs: const [
        Tab(text: 'Biểu đồ & Trạng thái'),
        Tab(text: 'Lịch sử dữ liệu'),
        Tab(text: 'Cảnh báo'),
      ],
    );
  }
}
