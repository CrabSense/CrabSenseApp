import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes.dart';
import '../../../../core/errors/error_mapper.dart';
import '../providers/home_provider.dart';

import '../widgets/home_header.dart';
import '../widgets/farm_overview_hero_card.dart';
import '../widgets/farm_health_score_card.dart';
import '../widgets/farm_health_analysis_sheet.dart';
import '../widgets/ai_recommendation_card.dart';
import '../widgets/ai_recommendation_detail_sheet.dart';
import '../widgets/quick_actions_grid.dart';
import '../widgets/alert_summary_section.dart';
import '../widgets/water_quality_overview.dart';
import '../widgets/today_tasks_section.dart';
import '../widgets/device_status_section.dart';
import '../widgets/recent_activity_section.dart';
import '../widgets/home_skeleton.dart';
import '../widgets/home_palette.dart';
import '../widgets/offline_banner.dart';
import '../widgets/section_error_card.dart';
import '../../../notifications/presentation/providers/unread_notifications_provider.dart';

/// Farm Command Center — Home (layout cũ, palette Neofarm)
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: kHomePrimaryDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final homeAsyncState = ref.watch(homeStateProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;

    return Scaffold(
      backgroundColor: kHomeBg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/home_pattern.jpg'),
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                opacity: 0.55,
              ),
            ),
          ),
          // Wash nhẹ để card/text vẫn đọc rõ trên pattern
          const ColoredBox(color: Color(0xCCF4F7F2)),
          SafeArea(
            child: homeAsyncState.when(
          loading: () => const HomeSkeleton(),
          error: (error, stackTrace) => Center(
            child: SectionErrorCard(
              sectionTitle: 'Trang chủ Command Center',
              errorMessage: ErrorMapper.userFacingMessage(error),
              onRetry: () => ref.read(homeStateProvider.notifier).loadData(forceRefresh: true),
            ),
          ),
          data: (data) {
            return RefreshIndicator(
              onRefresh: () => ref.read(homeStateProvider.notifier).refresh(),
              color: kHomePrimary,
              backgroundColor: kHomeSurface,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1000),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Offline Banner (if data is from offline cache)
                        if (data.isOfflineCached || !data.isOnline)
                          OfflineBanner(
                            lastSyncedAt: data.lastSyncedAt,
                            onRetryPressed: () =>
                                ref.read(homeStateProvider.notifier).refresh(),
                          ),
                        if (data.isOfflineCached || !data.isOnline)
                          const SizedBox(height: 12),

                        // Header (Greeting, Farm Switcher, Avatar, Bell)
                        HomeHeader(
                          data: data,
                          onFarmSwitched: (farmId) {
                            final name = data.availableFarms
                                .where((f) => f.id == farmId)
                                .map((f) => f.name)
                                .firstOrNull;
                            ref.read(homeStateProvider.notifier).switchFarm(farmId);
                            _showSnackBar('Đã chuyển sang ${name ?? farmId}');
                          },
                          onNotificationPressed: () async {
                            await context.push(RoutePaths.alerts);
                            if (context.mounted) {
                              ref.invalidate(unreadNotificationsCountProvider);
                            }
                          },
                        ),
                        const SizedBox(height: 16),

                        // Farm Overview Hero Card
                        FarmOverviewHeroCard(summary: data.farmSummary),
                        const SizedBox(height: 16),

                        // 3 MANDATORY KEY HIGHLIGHTS
                        if (isTablet)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: FarmHealthScoreCard(
                                  healthScore: data.healthScore,
                                  onAnalysisPressed: () => showFarmHealthAnalysisSheet(
                                    context,
                                    healthScore: data.healthScore,
                                    farmName: data.selectedFarmName,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: AiRecommendationCard(
                                  recommendation: data.aiRecommendation,
                                  onExecutePressed: () =>
                                      context.push(RoutePaths.harvest),
                                  onDetailPressed: () =>
                                      showAiRecommendationDetailSheet(
                                    context,
                                    recommendation: data.aiRecommendation,
                                    onExecutePressed: () =>
                                        context.push(RoutePaths.harvest),
                                    onRemindLaterPressed: () =>
                                        _showSnackBar('Sẽ nhắc lại sau 1 giờ'),
                                    onDismissPressed: () => ref
                                        .read(homeStateProvider.notifier)
                                        .dismissRecommendation(
                                            data.aiRecommendation.id),
                                  ),
                                  onDismissPressed: () => ref
                                      .read(homeStateProvider.notifier)
                                      .dismissRecommendation(data.aiRecommendation.id),
                                  onRemindLaterPressed: () =>
                                      _showSnackBar('Sẽ nhắc lại sau 1 giờ'),
                                  onHistoryPressed: () =>
                                      context.push(RoutePaths.operationHistory),
                                ),
                              ),
                            ],
                          )
                        else ...[
                          // Highlight #1: Farm Health Score
                          FarmHealthScoreCard(
                            healthScore: data.healthScore,
                            onAnalysisPressed: () => showFarmHealthAnalysisSheet(
                              context,
                              healthScore: data.healthScore,
                              farmName: data.selectedFarmName,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Highlight #2: AI Recommendation
                          AiRecommendationCard(
                            recommendation: data.aiRecommendation,
                            onExecutePressed: () =>
                                context.push(RoutePaths.harvest),
                            onDetailPressed: () =>
                                showAiRecommendationDetailSheet(
                              context,
                              recommendation: data.aiRecommendation,
                              onExecutePressed: () =>
                                  context.push(RoutePaths.harvest),
                              onRemindLaterPressed: () =>
                                  _showSnackBar('Sẽ nhắc lại sau 1 giờ'),
                              onDismissPressed: () => ref
                                  .read(homeStateProvider.notifier)
                                  .dismissRecommendation(
                                      data.aiRecommendation.id),
                            ),
                            onDismissPressed: () => ref
                                .read(homeStateProvider.notifier)
                                .dismissRecommendation(data.aiRecommendation.id),
                            onRemindLaterPressed: () =>
                                _showSnackBar('Sẽ nhắc lại sau 1 giờ'),
                            onHistoryPressed: () =>
                                context.push(RoutePaths.operationHistory),
                          ),
                        ],
                        const SizedBox(height: 18),

                        // Highlight #3: Quick Actions Grid (2x2 phone / 1x4 tablet)
                        QuickActionsGrid(
                          onScanQrPressed: () => context.push(RoutePaths.scanner),
                          onRecordVideoPressed: () {
                            context.push(RoutePaths.boxes);
                          },
                          onWaterTestPressed: () {
                            final areaId = data.selectedFarmId;
                            if (areaId != null && areaId.isNotEmpty) {
                              context.go(
                                '${RoutePaths.waterQuality}?farmingAreaId=$areaId',
                              );
                            } else {
                              context.go(RoutePaths.waterQuality);
                            }
                          },
                          onHarvestPressed: () =>
                              context.push(RoutePaths.harvest),
                          onTrackingPressed: () =>
                              context.push(RoutePaths.crabTracking),
                          onMineralDosingPressed: () =>
                              context.push(RoutePaths.mineralDosing),
                        ),
                        const SizedBox(height: 24),

                        // SUPPLEMENTARY SECTIONS
                        // Section A: Alert Summary
                        AlertSummarySection(
                          alerts: data.topAlerts,
                          onViewAllPressed: () =>
                              context.push(RoutePaths.alerts),
                        ),
                        const SizedBox(height: 24),

                        // Section B: Water Quality Overview
                        WaterQualityOverview(
                          metrics: data.waterMetrics,
                          onViewDetailsPressed: () {
                            final areaId = data.selectedFarmId;
                            if (areaId != null && areaId.isNotEmpty) {
                              context.go(
                                '${RoutePaths.waterQuality}?farmingAreaId=$areaId',
                              );
                            } else {
                              context.go(RoutePaths.waterQuality);
                            }
                          },
                        ),
                        const SizedBox(height: 24),

                        // Section C: Today's Tasks
                        TodayTasksSection(
                          tasks: data.todayTasks,
                          onViewAllPressed: () =>
                              context.push(RoutePaths.operations),
                        ),
                        const SizedBox(height: 24),

                        // Section D: Device Status
                        DeviceStatusSection(
                          devices: data.deviceSummary,
                          onViewDevicesPressed: () =>
                              context.push(RoutePaths.devices),
                        ),
                        const SizedBox(height: 24),

                        // Section E: Recent Activity
                        RecentActivitySection(
                          activities: data.recentActivities,
                          onViewAllPressed: () =>
                              context.push(RoutePaths.operationHistory),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
            ),
          ),
        ],
      ),
    );
  }
}
