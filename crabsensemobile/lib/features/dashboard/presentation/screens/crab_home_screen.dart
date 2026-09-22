import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/cupertino.dart';

import '../../../../app/routes.dart';
import '../../../../widgets/branded_loading_screen.dart';
import '../../../home/domain/models/home_models.dart';
import '../../../home/presentation/providers/home_provider.dart';

class CrabHomeScreen extends ConsumerStatefulWidget {
  const CrabHomeScreen({super.key});

  @override
  ConsumerState<CrabHomeScreen> createState() => _CrabHomeScreenState();
}

class _CrabHomeScreenState extends ConsumerState<CrabHomeScreen> {
  static const navy = Color(0xFF123968);
  static const blue = Color(0xFF168BE5);
  static const page = Colors.white;
  final Set<String> _completedTaskIds = <String>{};

  String _headerAsset() {
    return 'assets/images/desktop/background_chao_user.png';
  }

  Widget _desktopIcon(String file, {double size = 22}) => Image.asset(
    'assets/images/desktop/$file',
    width: size,
    height: size,
    fit: BoxFit.contain,
  );

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(homeStateProvider);
    return homeState.when(
      loading: () => const BrandedLoadingScreen(
        message: 'Đang tải trang trại...',
        subtitle: 'Đang đồng bộ dữ liệu hộp nuôi',
        showBackground: false,
      ),
      error: (error, _) {
        final unauthorized =
            error is DioException && error.response?.statusCode == 401;
        if (unauthorized) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              context.go(RoutePaths.login);
              Future<void>.microtask(() => ref.invalidate(homeStateProvider));
            }
          });
        }
        return Scaffold(
          body: Center(
            child: Text(
              unauthorized
                  ? 'Phiên đăng nhập đã hết hạn. Đang chuyển về Login...'
                  : 'Không tải được dữ liệu Home. Vui lòng thử lại.',
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
      data: _buildHome,
    );
  }

  Widget _buildHome(HomeStateData data) {
    return Scaffold(
      backgroundColor: page,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _header(data)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 150),
              sliver: SliverList.list(
                children: [
                  _overview(data),
                  const SizedBox(height: 10),
                  _tasksAndQuick(data),
                  const SizedBox(height: 10),
                  if (data.recentActivities.isNotEmpty) ...[
                    _recentActivityCard(data),
                    const SizedBox(height: 10),
                  ],
                  _chartAndWater(data),
                  const SizedBox(height: 10),
                  _alerts(data),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(HomeStateData data) => SizedBox(
    height: 245,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Column(
        children: [
          Row(
            children: [
              Image.asset(
                'assets/images/crabsense_desktop_logo.png',
                width: 38,
                height: 38,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 7),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CrabSense',
                    style: TextStyle(
                      color: navy,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Trại nuôi cua thông minh',
                    style: TextStyle(color: Color(0xFF78909C), fontSize: 9),
                  ),
                ],
              ),
              const Spacer(),
              _iconButton(
                Icons.notifications_none_rounded,
                badge: data.unreadNotificationsCount > 0
                    ? '${data.unreadNotificationsCount}'
                    : null,
              ),
              const SizedBox(width: 7),
              CircleAvatar(
                radius: 17,
                backgroundColor: const Color(0xFF17B77A),
                child: Text(
                  data.operatorName.isEmpty
                      ? 'D'
                      : data.operatorName.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _headerPill(
                  icon: Icons.location_on_rounded,
                  text: data.selectedFarmName,
                  trailing: Icons.chevron_right_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _headerPill(
                  icon: Icons.wb_sunny_rounded,
                  text: '--°C',
                  subtitle: 'Trời nắng nhẹ',
                  trailing: Icons.chevron_right_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            height: 105,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF159BAA).withValues(alpha: .16),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    _headerAsset(),
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xF5FFFFFF),
                          Color(0x38FFFFFF),
                          Colors.transparent,
                        ],
                        stops: [0, .42, .72],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 12, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Chào bạn!',
                          style: TextStyle(
                            color: navy,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Chúc bạn một ngày làm việc hiệu quả!',
                          style: TextStyle(
                            color: navy.withValues(alpha: .82),
                            fontSize: 10,
                            shadows: [
                              Shadow(
                                color: Colors.white.withValues(alpha: .8),
                                blurRadius: 3,
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Align(
                          alignment: Alignment.bottomLeft,
                          child: SizedBox(
                            width: 120,
                            height: 32,
                            child: Image.asset(
                              'assets/images/crabsense_splash_slogan.png',
                              fit: BoxFit.contain,
                              alignment: Alignment.bottomLeft,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _headerPill({
    required IconData icon,
    required String text,
    String? subtitle,
    IconData? trailing,
  }) => Container(
    height: 42,
    padding: const EdgeInsets.symmetric(horizontal: 10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFFE2F0E9)),
    ),
    child: Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: icon == Icons.wb_sunny_rounded
              ? const Color(0xFFF3A51B)
              : const Color(0xFF176D70),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: navy,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: const TextStyle(color: Color(0xFF78909C), fontSize: 8),
                ),
            ],
          ),
        ),
        if (trailing != null)
          const Icon(
            Icons.chevron_right_rounded,
            size: 17,
            color: Color(0xFF90A4AE),
          ),
      ],
    ),
  );

  Widget _overview(HomeStateData data) => _card(
    title: 'Tổng quan trại nuôi',
    action: 'Xem chi tiết',
    onAction: () => context.push(RoutePaths.boxes),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 3,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 98,
                height: 98,
                child: CustomPaint(
                  painter: _DonutPainter(
                    normal: data.boxStatusCounts['normal'] ?? 0,
                    watch: data.boxStatusCounts['watch'] ?? 0,
                    molting: data.boxStatusCounts['molting'] ?? 0,
                    alert: data.boxStatusCounts['alert'] ?? 0,
                    empty:
                        data.boxStatusCounts['empty'] ??
                        (data.farmSummary.totalBoxes -
                            data.farmSummary.activeBoxes),
                  ),
                  child: Center(
                    child: Text(
                      '${data.farmSummary.totalCrabs}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: navy,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Tổng số cua',
                style: TextStyle(fontSize: 9, color: navy),
              ),
              const SizedBox(height: 3),
              _Legend(
                'Bình thường',
                _legendValue(
                  data.boxStatusCounts['normal'] ?? 0,
                  data.farmSummary.totalBoxes,
                ),
                const Color(0xFF16A66A),
              ),
              _Legend(
                'Cần theo dõi',
                _legendValue(
                  data.boxStatusCounts['watch'] ?? 0,
                  data.farmSummary.totalBoxes,
                ),
                const Color(0xFFF09A27),
              ),
              _Legend(
                'Lột xác',
                _legendValue(
                  data.boxStatusCounts['molting'] ?? 0,
                  data.farmSummary.totalBoxes,
                ),
                const Color(0xFF8B5CF6),
              ),
              _Legend(
                'Cảnh báo',
                _legendValue(
                  data.boxStatusCounts['alert'] ?? 0,
                  data.farmSummary.totalBoxes,
                ),
                const Color(0xFFE34850),
              ),
              _Legend(
                'Hộp trống',
                _legendValue(
                  data.boxStatusCounts['empty'] ??
                      (data.farmSummary.totalBoxes -
                          data.farmSummary.activeBoxes),
                  data.farmSummary.totalBoxes,
                ),
                const Color(0xFF9AA7B2),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _OverviewTile(
                    'Tổng số hộp',
                    '${data.farmSummary.totalBoxes}',
                    'tab_crab_management.png',
                    blue,
                  ),
                  const SizedBox(width: 5),
                  _OverviewTile(
                    'Tổng số cua',
                    '${data.farmSummary.totalCrabs}',
                    'iocn-crab-normal.png',
                    const Color(0xFF168BE5),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _OverviewTile(
                    'Cần theo dõi',
                    '${data.boxStatusCounts['watch'] ?? 0}',
                    'icon-carb-warning.png',
                    const Color(0xFFF09A27),
                  ),
                  const SizedBox(width: 5),
                  _OverviewTile(
                    'Lột xác',
                    '${data.boxStatusCounts['molting'] ?? 0}',
                    'icon-crab-lt.png',
                    const Color(0xFFF3EAFE),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _OverviewTile(
                    'Bình thường',
                    '${data.boxStatusCounts['normal'] ?? 0}',
                    'iocn-crab-normal.png',
                    const Color(0xFF16A66A),
                  ),
                  const SizedBox(width: 5),
                  _OverviewTile(
                    'Hộp trống',
                    '${data.farmSummary.totalBoxes - data.farmSummary.activeBoxes}',
                    'icon-box-empty.png',
                    const Color(0xFF9AA7B2),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _waterAndChart(HomeStateData data) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(child: _waterCard(data)),
      const SizedBox(width: 10),
      Expanded(child: _chartCard(data)),
    ],
  );

  Widget _chartAndWater(HomeStateData data) => Column(
    children: [
      _chartCard(data),
      const SizedBox(height: 10),
      _boxStatusHistoryCard(data),
      const SizedBox(height: 10),
      _waterCard(data),
    ],
  );

  Widget _tasksAndQuick(HomeStateData data) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: _tasksCard(data)),
        const SizedBox(width: 10),
        Expanded(child: _quickActions()),
      ],
    ),
  );

  Widget _recentActivityCard(HomeStateData data) => _card(
    title: 'Nhật ký hoạt động gần đây',
    action: 'Xem tất cả',
    onAction: () => context.push(RoutePaths.operationHistory),
    child: Column(
      children: [
        for (final activity in data.recentActivities.take(5))
          _activityRow(activity),
      ],
    ),
  );

  Widget _activityRow(RecentActivityItem activity) {
    final text = '${activity.title} ${activity.description}'.toLowerCase();
    final icon =
        text.contains('chuyển') ||
            text.contains('move') ||
            text.contains('transfer')
        ? Icons.swap_horiz_rounded
        : text.contains('thêm') ||
              text.contains('add') ||
              text.contains('assign')
        ? Icons.person_add_alt_1_rounded
        : text.contains('qr')
        ? Icons.qr_code_scanner_rounded
        : text.contains('thu hoạch') || text.contains('harvest')
        ? Icons.inventory_2_outlined
        : Icons.history_rounded;
    final color = text.contains('cảnh báo') || text.contains('alert')
        ? const Color(0xFFE34850)
        : const Color(0xFF159BAA);

    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 17, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: navy,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  activity.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF708090),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _activityTime(activity.timestamp),
            style: const TextStyle(color: Color(0xFF90A4AE), fontSize: 9),
          ),
        ],
      ),
    );
  }

  String _activityTime(DateTime timestamp) {
    final local = timestamp.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  String _metric(HomeStateData data, String code, String unit) {
    final metric = data.waterMetrics.cast<WaterMetricItem?>().firstWhere(
      (item) =>
          item != null &&
          (item.code.toLowerCase().contains(code) ||
              item.name.toLowerCase().contains(code)),
      orElse: () => null,
    );
    if (metric == null) return '--';
    final value = metric.currentValue == metric.currentValue.roundToDouble()
        ? metric.currentValue.toStringAsFixed(0)
        : metric.currentValue.toStringAsFixed(1);
    return '$value$unit';
  }

  String _legendValue(int value, int total) {
    final percent = total <= 0 ? 0 : (value * 100 / total).round();
    return '$value  $percent%';
  }

  List<TodayTaskItem> _tasksForDisplay(HomeStateData data) {
    return data.todayTasks;
  }

  Widget _waterCard(HomeStateData data) => _card(
    title: 'Chất lượng nước',
    action: 'Ổn định',
    actionColor: const Color(0xFF169B62),
    onAction: () => context.push(RoutePaths.waterQuality),
    child: Column(
      children: [
        Row(
          children: [
            _WaterMetric(
              '🌡',
              _metric(data, 'temperature', '°C'),
              'Nhiệt độ',
              '--',
            ),
            _WaterMetric('pH', _metric(data, 'ph', ''), 'pH', '--'),
            _WaterMetric('≋', _metric(data, 'salinity', '‰'), 'Độ mặn', '--'),
          ],
        ),
        const SizedBox(height: 9),
        Row(
          children: [
            _WaterMetric('Ca', _metric(data, 'calcium', 'ppm'), 'Canxi', '--'),
            _WaterMetric(
              'Mg',
              _metric(data, 'magnesium', 'ppm'),
              'Magie',
              '--',
            ),
            _WaterMetric('NO₂', _metric(data, 'no2', 'mg/L'), 'Nitrit', '--'),
          ],
        ),
        const SizedBox(height: 9),
        Row(
          children: [
            _WaterMetric('NO₃', _metric(data, 'no3', 'mg/L'), 'Nitrat', '--'),
            const Expanded(child: SizedBox()),
            const Expanded(child: SizedBox()),
          ],
        ),
        const SizedBox(height: 10),
        _smallStatus('Chất lượng nước đang ổn định'),
      ],
    ),
  );

  Widget _chartCard(HomeStateData data) {
    final history = [...data.feedingHistory];
    while (history.isNotEmpty &&
        history.last.many + history.last.little + history.last.none == 0) {
      history.removeLast();
    }
    return _card(
      title: 'Lịch sử cho ăn (7 ngày)',
      child: history.isEmpty
          ? const SizedBox(
              height: 120,
              child: Center(
                child: Text(
                  'Chưa có dữ liệu lịch sử cho ăn từ API',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF708090), fontSize: 11),
                ),
              ),
            )
          : Column(
              children: [
                SizedBox(
                  height: 150,
                  child: CustomPaint(
                    painter: _FeedingHistoryPainter(history),
                    child: const SizedBox.expand(),
                  ),
                ),
                const SizedBox(height: 8),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ChartLegend('Ăn nhiều', Color(0xFF159BAA)),
                    SizedBox(width: 14),
                    _ChartLegend('Ăn ít', Color(0xFFF09A27)),
                    SizedBox(width: 14),
                    _ChartLegend('Không ăn', Color(0xFF9AA7B2)),
                  ],
                ),
                const SizedBox(height: 8),
                _feedingSummary(history.last),
              ],
            ),
    );
  }

  Widget _feedingSummary(FeedingHistoryDay latest) {
    final entries = [
      ('Ăn nhiều', latest.many, const Color(0xFF159BAA)),
      ('Ăn ít', latest.little, const Color(0xFFF09A27)),
      ('Không ăn', latest.none, const Color(0xFF9AA7B2)),
    ];
    return Row(
      children: [
        for (var i = 0; i < entries.length; i++)
          Expanded(
            child: Container(
              margin: EdgeInsets.only(left: i == 0 ? 0 : 5),
              padding: const EdgeInsets.symmetric(vertical: 5),
              decoration: BoxDecoration(
                color: entries[i].$3.withValues(alpha: .10),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Column(
                children: [
                  Text(
                    entries[i].$1,
                    style: TextStyle(fontSize: 8, color: entries[i].$3),
                  ),
                  Text(
                    '${entries[i].$2}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: entries[i].$3,
                    ),
                  ),
                  const Text(
                    'con',
                    style: TextStyle(fontSize: 8, color: Color(0xFF708090)),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _boxStatusHistoryCard(HomeStateData data) => _card(
    title: 'Tình trạng cua (7 ngày)',
    child: data.boxStatusHistory.isEmpty
        ? const SizedBox(
            height: 120,
            child: Center(
              child: Text(
                'Chưa có lịch sử trạng thái từ API',
                style: TextStyle(color: Color(0xFF708090), fontSize: 11),
              ),
            ),
          )
        : Column(
            children: [
              SizedBox(
                height: 95,
                child: CustomPaint(
                  painter: _BoxStatusHistoryPainter(data.boxStatusHistory),
                  child: const SizedBox.expand(),
                ),
              ),
              _statusHistoryLegend(_latestStatusHistory(data.boxStatusHistory)),
              const SizedBox(height: 8),
              _statusHistorySummary(
                _latestStatusHistory(data.boxStatusHistory),
              ),
            ],
          ),
  );

  BoxStatusHistoryDay _latestStatusHistory(List<BoxStatusHistoryDay> history) =>
      history.lastWhere(
        (day) =>
            day.normal + day.watch + day.molting + day.alert + day.empty > 0,
        orElse: () => history.last,
      );

  Widget _statusHistoryLegend(BoxStatusHistoryDay latest) {
    final entries = [
      ('Bình thường', latest.normal, const Color(0xFF16A66A)),
      ('Cần theo dõi', latest.watch, const Color(0xFFF09A27)),
      ('Lột xác', latest.molting, const Color(0xFF8B5CF6)),
      ('Cảnh báo', latest.alert, const Color(0xFFE34850)),
      ('Hộp trống', latest.empty, const Color(0xFF9AA7B2)),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final entry in entries)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: entry.$3,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  entry.$1,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF708090),
                  ),
                ),
                const SizedBox(width: 12),
              ],
            ),
        ],
      ),
    );
  }

  Widget _statusHistorySummary(BoxStatusHistoryDay latest) {
    final entries = [
      ('Bình thường', latest.normal, const Color(0xFF16A66A)),
      ('Cần theo dõi', latest.watch, const Color(0xFFF09A27)),
      ('Lột xác', latest.molting, const Color(0xFF8B5CF6)),
      ('Cảnh báo', latest.alert, const Color(0xFFE34850)),
      ('Hộp trống', latest.empty, const Color(0xFF9AA7B2)),
    ];

    return Row(
      children: [
        for (final entry in entries)
          Expanded(
            child: Container(
              height: 56,
              margin: const EdgeInsets.only(right: 3),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: entry.$3.withValues(alpha: .10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, size: 10, color: entry.$3),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          entry.$1,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 6.5, color: entry.$3),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${entry.$2} hộp',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: entry.$3,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _statusAndTasks(HomeStateData data) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(child: _statusCard(data)),
      const SizedBox(width: 10),
      Expanded(child: _tasksCard(data)),
    ],
  );

  Widget _statusCard(HomeStateData data) => _card(
    title: 'Tình trạng hộp cua',
    child: Column(
      children: [
        SizedBox(
          width: 110,
          height: 110,
          child: CustomPaint(
            painter: _DonutPainter(
              normal: data.boxStatusCounts['normal'] ?? 0,
              watch: data.boxStatusCounts['watch'] ?? 0,
              molting: data.boxStatusCounts['molting'] ?? 0,
              alert: data.boxStatusCounts['alert'] ?? 0,
              empty:
                  data.boxStatusCounts['empty'] ??
                  (data.farmSummary.totalBoxes - data.farmSummary.activeBoxes),
            ),
            child: Center(
              child: Text(
                '${data.farmSummary.totalBoxes}\nhộp cua',
                textAlign: TextAlign.center,
                style: TextStyle(color: navy, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 2,
          children: [
            _Legend(
              'Bình thường',
              '${data.boxStatusCounts['normal'] ?? 0}',
              const Color(0xFF16A66A),
            ),
            _Legend(
              'Cần theo dõi',
              '${data.boxStatusCounts['watch'] ?? 0}',
              Color(0xFFF09A27),
            ),
            _Legend(
              'Lột xác',
              '${data.boxStatusCounts['molting'] ?? 0}',
              Color(0xFF7B3FE4),
            ),
            _Legend(
              'Cảnh báo',
              '${data.boxStatusCounts['alert'] ?? 0}',
              Color(0xFFE34850),
            ),
            _Legend(
              'Hộp trống',
              '${data.boxStatusCounts['empty'] ?? 0}',
              Color(0xFF9AA6B2),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _tasksCard(HomeStateData data) => _card(
    title: 'Việc cần làm hôm nay',
    action: 'Xem tất cả',
    onAction: () => context.push(RoutePaths.scheduledTasks),
    child: Column(
      children: [
        _ProgressLine(
          completed: data.todayTasks.where((task) => task.isCompleted).length,
          total: data.todayTasks.length,
        ),
        ..._tasksForDisplay(data)
            .take(5)
            .map(
              (task) => _Task(
                task.title,
                task.target,
                task.isCompleted || _completedTaskIds.contains(task.id),
                onTap: () => setState(() {
                  if (_completedTaskIds.contains(task.id)) {
                    _completedTaskIds.remove(task.id);
                  } else {
                    _completedTaskIds.add(task.id);
                  }
                }),
              ),
            ),
      ],
    ),
  );

  Widget _quickActions() => _card(
    title: 'Thao tác nhanh',
    child: Wrap(
      alignment: WrapAlignment.center,
      spacing: 4,
      runSpacing: 7,
      children: [
        _Quick(
          'Farm Box',
          _desktopIcon('tab_crab_management.png', size: 42),
          () => context.push(RoutePaths.boxes),
        ),
        _Quick(
          'Thêm cua',
          _desktopIcon('tab_manage_controll.png', size: 42),
          () => context.push(RoutePaths.boxes),
        ),
        _Quick(
          'Chăm sóc\nhộp',
          _desktopIcon('tab_dashboard.png', size: 42),
          () => context.push(RoutePaths.operations),
        ),
        _Quick(
          'Chất lượng\nnước',
          _desktopIcon('tab_water_analysis.png', size: 42),
          () => context.push(RoutePaths.waterQuality),
        ),
        _Quick(
          'Pha nước\n& khoáng',
          _desktopIcon('tab_RAS_control.png', size: 42),
          () => context.push(RoutePaths.mineralDosing),
        ),
        _Quick(
          'Thu hoạch',
          _desktopIcon('tab_manage_controll.png', size: 42),
          () => context.push(RoutePaths.harvest),
        ),
        _Quick(
          'AI lột\nxác',
          _desktopIcon('logo-ai.png', size: 42),
          () => context.push(RoutePaths.aiCenter),
        ),
      ],
    ),
  );

  Widget _alerts(HomeStateData data) => _card(
    title: 'Cảnh báo gần đây',
    action: 'Xem tất cả',
    child: Column(
      children: data.topAlerts.take(3).map((alert) {
        final color = switch (alert.severity) {
          AlertSeverityLevel.critical => const Color(0xFFE64C4C),
          AlertSeverityLevel.warning => const Color(0xFFF09A27),
          AlertSeverityLevel.info => const Color(0xFF7B3FE4),
        };
        return _Alert(
          '${alert.title} ${alert.location}',
          '${alert.timestamp.hour.toString().padLeft(2, '0')}:${alert.timestamp.minute.toString().padLeft(2, '0')}',
          color,
          Icons.warning_rounded,
        );
      }).toList(),
    ),
  );

  Widget _card({
    required String title,
    Widget? child,
    String? action,
    Widget? actionWidget,
    Color actionColor = blue,
    VoidCallback? onAction,
  }) => Container(
    padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Color(0xFFBFE8D0), width: 1.2),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: navy,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (actionWidget != null) actionWidget,
            if (action != null)
              InkWell(
                onTap: onAction,
                child: Text(
                  action,
                  style: TextStyle(
                    color: actionColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (child != null) child,
      ],
    ),
  );

  Widget _smallStatus(String text) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(7),
    decoration: BoxDecoration(
      color: const Color(0xFFE9F8F0),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      text,
      style: const TextStyle(
        color: Color(0xFF168B59),
        fontSize: 10,
        fontWeight: FontWeight.w700,
      ),
    ),
  );

  Widget _iconButton(IconData icon, {String? badge}) => Stack(
    clipBehavior: Clip.none,
    children: [
      Container(
        padding: const EdgeInsets.all(7),
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: navy, size: 20),
      ),
      if (badge != null)
        Positioned(
          right: -2,
          top: -4,
          child: CircleAvatar(
            radius: 7,
            backgroundColor: Colors.red,
            child: Text(
              badge,
              style: const TextStyle(color: Colors.white, fontSize: 8),
            ),
          ),
        ),
    ],
  );

  Widget _bottomNavigation() => NavigationBar(
    height: 72,
    backgroundColor: Colors.white,
    selectedIndex: 0,
    onDestinationSelected: (_) {},
    destinations: const [
      NavigationDestination(
        icon: Icon(CupertinoIcons.house),
        selectedIcon: Icon(CupertinoIcons.house_fill),
        label: 'Trang chủ',
      ),
      NavigationDestination(
        icon: Icon(CupertinoIcons.archivebox),
        label: 'Farm Box',
      ),
      NavigationDestination(
        icon: Icon(CupertinoIcons.add_circled_solid, size: 42, color: blue),
        label: 'Ghi nhận',
      ),
      NavigationDestination(
        icon: Icon(CupertinoIcons.chart_bar),
        label: 'Thống kê',
      ),
      NavigationDestination(
        icon: Icon(CupertinoIcons.person),
        label: 'Cá nhân',
      ),
    ],
  );
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });
  final String value;
  final String label;
  final Widget icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        icon,
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF123968),
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF50657A), fontSize: 8),
        ),
      ],
    ),
  );
}

class _OverviewTile extends StatelessWidget {
  const _OverviewTile(this.label, this.value, this.asset, this.color);

  final String label;
  final String value;
  final String asset;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 62,
    height: 64,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/desktop/$asset',
            width: 20,
            height: 20,
            fit: BoxFit.contain,
          ),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF123968),
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 7, color: Color(0xFF50657A)),
          ),
        ],
      ),
    ),
  );
}

class _ChartLegend extends StatelessWidget {
  const _ChartLegend(this.label, this.color);

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 4),
      Text(
        label,
        style: const TextStyle(fontSize: 9, color: Color(0xFF123968)),
      ),
    ],
  );
}

class _WaterMetric extends StatelessWidget {
  const _WaterMetric(this.icon, this.value, this.label, this.range);
  final String icon;
  final String value;
  final String label;
  final String range;
  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Text(
          icon,
          style: const TextStyle(
            color: Color(0xFF168BE5),
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF123968),
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Color(0xFF50657A), fontSize: 9),
        ),
        Text(
          '($range)',
          style: const TextStyle(color: Color(0xFF8495A5), fontSize: 7),
        ),
      ],
    ),
  );
}

class _Legend extends StatelessWidget {
  const _Legend(this.label, this.value, this.color);
  final String label;
  final String value;
  final Color color;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        CircleAvatar(radius: 4, backgroundColor: color),
        const SizedBox(width: 5),
        SizedBox(
          width: 82,
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 9, height: 1.1),
          ),
        ),
        const SizedBox(width: 3),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 8, color: Color(0xFF50657A)),
          ),
        ),
      ],
    ),
  );
}

class _Task extends StatelessWidget {
  const _Task(this.title, this.detail, this.done, {this.onTap});
  final String title;
  final String detail;
  final bool done;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_box : Icons.check_box_outline_blank,
            color: done ? Colors.green : Colors.grey,
            size: 16,
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  detail,
                  style: const TextStyle(fontSize: 8, color: Color(0xFF708090)),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _ProgressLine extends StatelessWidget {
  const _ProgressLine({required this.completed, required this.total});
  final int completed;
  final int total;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      children: [
        Expanded(
          child: Text(
            '$completed/$total công việc đã hoàn thành',
            style: const TextStyle(fontSize: 8, color: Color(0xFF708090)),
          ),
        ),
        Text(
          total == 0 ? '--' : '${(completed / total * 100).round()}%',
          style: const TextStyle(fontSize: 8, color: Color(0xFF708090)),
        ),
      ],
    ),
  );
}

class _Quick extends StatelessWidget {
  const _Quick(this.label, this.icon, this.onTap);
  final String label;
  final Widget icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: SizedBox(
      width: 70,
      child: Column(
        children: [
          icon,
          const SizedBox(height: 3),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: const TextStyle(
              color: Color(0xFF123968),
              fontSize: 8.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}

class _Alert extends StatelessWidget {
  const _Alert(this.text, this.time, this.color, this.icon);
  final String text;
  final String time;
  final Color color;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 5),
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Row(
      children: [
        Icon(icon, color: color, size: 15),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 9))),
        Text(
          time,
          style: const TextStyle(fontSize: 8, color: Color(0xFF708090)),
        ),
      ],
    ),
  );
}

class _LinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF168BE5)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final points = [
      Offset(10, size.height * .68),
      Offset(size.width * .22, size.height * .68),
      Offset(size.width * .43, size.height * .45),
      Offset(size.width * .62, size.height * .16),
      Offset(size.width * .78, size.height * .42),
      Offset(size.width - 10, size.height * .55),
    ];
    final grid = Paint()
      ..color = const Color(0xFFE5EEF5)
      ..strokeWidth = 1;
    for (var i = 1; i < 5; i++)
      canvas.drawLine(
        Offset(0, size.height * i / 5),
        Offset(size.width, size.height * i / 5),
        grid,
      );
    const labelStyle = TextStyle(color: Color(0xFF708090), fontSize: 8);
    _label(canvas, '32', const Offset(0, 2), labelStyle);
    _label(canvas, '28', Offset(0, size.height * .45), labelStyle);
    _label(canvas, '24', Offset(0, size.height - 14), labelStyle);
    const times = ['0h', '4h', '8h', '12h', '16h', '20h'];
    for (var i = 0; i < times.length; i++) {
      _label(
        canvas,
        times[i],
        Offset(i * (size.width - 20) / 5 + 3, size.height - 2),
        labelStyle,
      );
    }
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++)
      path.lineTo(points[i].dx, points[i].dy);
    canvas.drawPath(path, paint);
    for (final point in points)
      canvas.drawCircle(point, 3, Paint()..color = const Color(0xFF168BE5));
  }

  void _label(Canvas canvas, String text, Offset offset, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FeedingHistoryPainter extends CustomPainter {
  const _FeedingHistoryPainter(this.days);

  final List<FeedingHistoryDay> days;

  @override
  void paint(Canvas canvas, Size size) {
    if (days.length < 2) return;
    const left = 24.0;
    const bottom = 22.0;
    final chartWidth = size.width - left;
    final chartHeight = size.height - bottom;
    final maxValue = days
        .expand((day) => [day.many, day.little, day.none])
        .fold<int>(1, math.max);
    final labelStyle = const TextStyle(color: Color(0xFF708090), fontSize: 8);
    final grid = Paint()
      ..color = const Color(0xFFE5EEF2)
      ..strokeWidth = 1;
    for (var i = 0; i <= 4; i++) {
      final y = chartHeight * i / 4;
      canvas.drawLine(Offset(left, y), Offset(size.width, y), grid);
      _label(
        canvas,
        '${(maxValue * (4 - i) / 4).round()}',
        Offset(0, y - 4),
        labelStyle,
      );
    }
    for (var i = 0; i < days.length; i++) {
      final x = left + i * chartWidth / (days.length - 1);
      final date = days[i].date;
      _label(
        canvas,
        '${date.day}/${date.month}',
        Offset(x - 10, chartHeight + 5),
        labelStyle,
      );
    }
    final colors = [
      const Color(0xFF159BAA),
      const Color(0xFFF09A27),
      const Color(0xFF9AA7B2),
    ];
    final values = [
      days.map((day) => day.many).toList(),
      days.map((day) => day.little).toList(),
      days.map((day) => day.none).toList(),
    ];
    for (var series = 0; series < values.length; series++) {
      final points = <Offset>[];
      for (var i = 0; i < values[series].length; i++) {
        points.add(
          Offset(
            left + i * chartWidth / (days.length - 1),
            chartHeight - values[series][i] / maxValue * chartHeight,
          ),
        );
      }
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (var i = 1; i < points.length; i++) {
        final previous = points[i - 1];
        final current = points[i];
        final middleX = (previous.dx + current.dx) / 2;
        path.cubicTo(
          middleX,
          previous.dy,
          middleX,
          current.dy,
          current.dx,
          current.dy,
        );
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = colors[series]
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
      );
      for (final point in points) {
        canvas.drawCircle(point, 2.5, Paint()..color = colors[series]);
      }
    }
  }

  void _label(Canvas canvas, String text, Offset offset, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _FeedingHistoryPainter oldDelegate) =>
      oldDelegate.days != days;
}

class _BoxStatusHistoryPainter extends CustomPainter {
  const _BoxStatusHistoryPainter(this.days);

  final List<BoxStatusHistoryDay> days;

  @override
  void paint(Canvas canvas, Size size) {
    if (days.length < 2) return;
    const left = 24.0;
    const bottom = 22.0;
    final width = size.width - left;
    final height = size.height - bottom;
    final values = [
      days.map((day) => day.normal).toList(),
      days.map((day) => day.watch).toList(),
      days.map((day) => day.molting).toList(),
      days.map((day) => day.alert).toList(),
      days.map((day) => day.empty).toList(),
    ];
    final colors = [
      const Color(0xFF16A66A),
      const Color(0xFFF09A27),
      const Color(0xFF8B5CF6),
      const Color(0xFFEF5350),
      const Color(0xFF9AA7B2),
    ];
    final maxValue = values.expand((series) => series).fold<int>(1, math.max);
    final grid = Paint()
      ..color = const Color(0xFFE5EEF2)
      ..strokeWidth = 1;
    for (var i = 0; i <= 4; i++) {
      final y = height * i / 4;
      canvas.drawLine(Offset(left, y), Offset(size.width, y), grid);
      _label(canvas, '${(maxValue * (4 - i) / 4).round()}', Offset(0, y - 4));
    }
    for (var i = 0; i < days.length; i++) {
      final x = left + i * width / (days.length - 1);
      final date = days[i].date;
      _label(canvas, '${date.day}/${date.month}', Offset(x - 10, height + 5));
    }
    for (var series = 0; series < values.length; series++) {
      final points = <Offset>[
        for (var i = 0; i < days.length; i++)
          Offset(
            left + i * width / (days.length - 1),
            height - values[series][i] / maxValue * height,
          ),
      ];
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (var i = 1; i < points.length; i++) {
        final previous = points[i - 1];
        final current = points[i];
        final middleX = (previous.dx + current.dx) / 2;
        path.cubicTo(
          middleX,
          previous.dy,
          middleX,
          current.dy,
          current.dx,
          current.dy,
        );
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = colors[series]
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
      );
      for (final point in points) {
        canvas.drawCircle(point, 2.5, Paint()..color = colors[series]);
      }
    }
  }

  void _label(Canvas canvas, String text, Offset offset) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(color: Color(0xFF708090), fontSize: 8),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _BoxStatusHistoryPainter oldDelegate) =>
      oldDelegate.days != days;
}

class _HistoryPainter extends CustomPainter {
  const _HistoryPainter({required this.values});

  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2 || size.width <= 0 || size.height <= 0) return;
    final min = values.reduce(math.min);
    final max = values.reduce(math.max);
    final range = (max - min).abs() < .001 ? 1 : max - min;
    final points = <Offset>[];
    for (var i = 0; i < values.length; i++) {
      final x = i * size.width / (values.length - 1);
      final y =
          size.height - ((values[i] - min) / range * size.height * .8) - 4;
      points.add(Offset(x, y));
    }
    final gridPaint = Paint()
      ..color = const Color(0xFFE5EEF2)
      ..strokeWidth = 1;
    for (var i = 0; i < 4; i++) {
      final y = i * size.height / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    final linePaint = Paint()
      ..color = const Color(0xFF159BAA)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(path, linePaint);
    for (final point in points) {
      canvas.drawCircle(point, 3, Paint()..color = const Color(0xFF2AA764));
    }
  }

  @override
  bool shouldRepaint(covariant _HistoryPainter oldDelegate) =>
      oldDelegate.values != values;
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({
    required this.normal,
    required this.watch,
    required this.molting,
    required this.alert,
    required this.empty,
  });

  final int normal;
  final int watch;
  final int molting;
  final int alert;
  final int empty;

  @override
  void paint(Canvas canvas, Size size) {
    final colors = [
      const Color(0xFF16A66A),
      const Color(0xFFF09A27),
      const Color(0xFF7B3FE4),
      const Color(0xFFE34850),
      const Color(0xFF9AA6B2),
    ];
    final values = [
      normal.toDouble(),
      watch.toDouble(),
      molting.toDouble(),
      alert.toDouble(),
      empty.toDouble(),
    ];
    final total = values.fold<double>(0, (sum, value) => sum + value);
    if (total == 0) return;
    final rect = Offset.zero & size;
    var start = -math.pi / 2;
    for (var i = 0; i < values.length; i++) {
      final sweep = values[i] / total * math.pi * 2;
      canvas.drawArc(
        rect.deflate(10),
        start,
        sweep,
        false,
        Paint()
          ..color = colors[i]
          ..style = PaintingStyle.stroke
          ..strokeWidth = 18,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
