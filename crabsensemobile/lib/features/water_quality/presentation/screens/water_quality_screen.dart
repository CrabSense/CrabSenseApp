// ignore_for_file: lines_longer_than_80_chars

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/utils/app_back.dart';
import '../../../home/data/repositories/home_repository_impl.dart';
import '../../../home/domain/models/home_models.dart' show WaterMetricItem;
import '../../../home/presentation/widgets/home_palette.dart';
import '../../domain/entities/water_quality_thresholds.dart';
import '../bloc/water_quality_bloc.dart';
import '../bloc/water_quality_event.dart';
import '../bloc/water_quality_state.dart';
import '../models/farm_filter_model.dart';
import '../widgets/farm_pond_filter_widget.dart';
import '../../data/repositories/scoped_history_service.dart';
import '../widgets/scoped_history_chart.dart';
import '../widgets/nine_water_metrics.dart';

class WaterQualityScreen extends StatelessWidget {
  const WaterQualityScreen({super.key, this.farmId, this.pondId});

  final String? farmId;
  final String? pondId;

  @override
  Widget build(BuildContext context) => BlocProvider<WaterQualityBloc>(
        create: (_) => sl<WaterQualityBloc>()
          ..add(
            WaterQualityLoadRequested(
              farmId: farmId ?? 'default',
              pondId: pondId,
            ),
          ),
        child: _WaterQualityView(farmId: farmId, pondId: pondId),
      );
}

class _WaterQualityView extends StatefulWidget {
  const _WaterQualityView({this.farmId, this.pondId});

  final String? farmId;
  final String? pondId;

  @override
  State<_WaterQualityView> createState() => _WaterQualityViewState();
}

class _WaterQualityViewState extends State<_WaterQualityView> {
  Timer? _refreshTimer;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  bool _wasOffline = false;

  @override
  void initState() {
    super.initState();
    _startAutoRefreshTimer();
    _listenToConnectivity();
  }

  void _startAutoRefreshTimer() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      if (!mounted) return;
      final isOnline = await sl<NetworkInfo>().isConnected;
      if (isOnline && mounted) {
        context.read<WaterQualityBloc>().add(const WaterQualityRefreshRequested());
      }
    });
  }

  void _listenToConnectivity() {
    _connectivitySubscription =
        sl<Connectivity>().onConnectivityChanged.listen((result) {
      if (!mounted) return;
      final isOnline = result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.ethernet ||
          result == ConnectivityResult.vpn;
      if (isOnline && _wasOffline) {
        context.read<WaterQualityBloc>().add(const WaterQualityRefreshRequested());
      }
      _wasOffline = !isOnline;
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final navPad = MediaQuery.paddingOf(context).bottom + 88;
    return Scaffold(
      backgroundColor: kHomeBg,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: kHomeBg,
        title: const Text('Giám sát môi trường'),
        actions: [TextButton.icon(
          key: const Key('open-water-bench'),
          onPressed: () => context.push(Uri(path: RoutePaths.waterBench,
            queryParameters: {if (context.read<WaterQualityBloc>().state is WaterQualityLoaded)
              'farmingAreaId': (context.read<WaterQualityBloc>().state as WaterQualityLoaded).farmId}).toString()),
          icon: const Icon(Icons.science_outlined), label: const Text('Phân tích nước'))],
      ),
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<WaterQualityBloc, WaterQualityState>(
          builder: (context, state) {
            if (state is WaterQualityLoading || state is WaterQualityInitial) {
              return _SkeletonBody(bottom: navPad);
            }
            if (state is WaterQualityError) {
              return _ErrorBody(
                isOffline: state.isOffline,
                message: state.message,
                onRetry: () => context.read<WaterQualityBloc>().add(
                      const WaterQualityRefreshRequested(),
                    ),
              );
            }
            if (state is WaterQualityLoaded) {
              return RefreshIndicator(
                color: kHomePrimary,
                onRefresh: () async {
                  final bloc = context.read<WaterQualityBloc>();
                  // Subscribe before dispatch; bounded UI wait even on route disposal.
                  final finished = bloc.stream.firstWhere(
                    (s) => (s is WaterQualityLoaded && !s.isRefreshing) || s is WaterQualityError,
                  );
                  bloc.add(const WaterQualityRefreshRequested());
                  try {
                    await finished.timeout(const Duration(seconds: 60));
                  } on TimeoutException {
                    // The BLoC continues to own the in-flight request.
                  } on StateError {
                    // The BLoC was closed when the screen was disposed.
                  }
                },
                child: _WaterQualityContent(state: state, bottomPad: navPad),
              );
            }
            return _SkeletonBody(bottom: navPad);
          },
        ),
      ),
    );
  }
}

class _WaterQualityContent extends StatefulWidget {
  const _WaterQualityContent({required this.state, required this.bottomPad});

  final WaterQualityLoaded state;
  final double bottomPad;

  @override
  State<_WaterQualityContent> createState() => _WaterQualityContentState();
}

class _WaterQualityContentState extends State<_WaterQualityContent> {
  List<FarmOption> _farms = const [];
  List<WaterMetricItem> _metrics = const [];
  bool _farmsLoading = true;
  int _metricsGeneration = 0;

  @override
  void initState() {
    super.initState();
    _loadFarms();
    _loadMetrics();
  }

  @override
  void didUpdateWidget(covariant _WaterQualityContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.farmId != widget.state.farmId ||
        oldWidget.state.pondId != widget.state.pondId ||
        oldWidget.state.lastRefreshedAt != widget.state.lastRefreshedAt) {
      _metrics = const [];
      _loadMetrics();
    }
  }

  Future<void> _loadMetrics() async {
    final farmId = widget.state.farmId;
    final generation = ++_metricsGeneration;
    if (widget.state.pondId != null || farmId.isEmpty || farmId == 'default') {
      if (mounted) setState(() => _metrics = const []);
      return; // Home summary is not row-scoped.
    }
    try {
      final data = await HomeRepositoryImpl(api: sl<ApiClient>()).getHomeSummary(
        forceRefresh: true,
        farmingAreaId:
            farmId.isEmpty || farmId == 'default' ? null : farmId,
      );
      if (!mounted || generation != _metricsGeneration) return;
      setState(() => _metrics = data.selectedFarmId == farmId && !data.isOfflineCached ? data.waterMetrics : const []);
    } on Exception {
      if (!mounted || generation != _metricsGeneration) return;
      setState(() => _metrics = const []);
    }
  }

  Future<void> _loadFarms() async {
    try {
      final areasResult = await sl<ApiClient>()
          .safeGet<Map<String, dynamic>>(ApiConstants.farmingAreas);
      final rowsResult = await sl<ApiClient>()
          .safeGet<Map<String, dynamic>>(ApiConstants.farmingRows);

      List<dynamic> extract(Map<String, dynamic>? body) {
        if (body == null) return const [];
        if (body['data'] is List) return body['data'] as List;
        if (body['items'] is List) return body['items'] as List;
        return const [];
      }

      final areas = extract(areasResult.data.data);
      final rows = extract(rowsResult.data.data);

      final pondsByArea = <String, List<PondOption>>{};
      for (final raw in rows) {
        final map = Map<String, dynamic>.from(raw as Map);
        final areaId =
            (map['farmingAreaId'] ?? map['FarmingAreaId'] ?? '').toString();
        if (areaId.isEmpty) continue;
        pondsByArea.putIfAbsent(areaId, () => <PondOption>[]).add(PondOption(
          id: (map['id'] ?? '').toString(),
          name: (map['name'] ?? map['code'] ?? 'Dãy').toString(),
        ));
      }

      final farms = <FarmOption>[];
      for (final raw in areas) {
        final map = Map<String, dynamic>.from(raw as Map);
        final id = (map['id'] ?? '').toString();
        if (id.isEmpty) continue;
        farms.add(FarmOption(
          id: id,
          name: (map['name'] ?? map['code'] ?? 'Khu').toString(),
          ponds: pondsByArea[id] ?? const [],
        ));
      }

      if (!mounted) return;
      setState(() {
        _farms = farms.isEmpty
            ? [FarmOption(id: widget.state.farmId, name: 'Khu hiện tại', ponds: const [])]
            : farms;
        _farmsLoading = false;
      });
    } on Exception {
      if (!mounted) return;
      setState(() {
        _farms = [FarmOption(id: widget.state.farmId, name: 'Khu hiện tại', ponds: const [])];
        _farmsLoading = false;
      });
    }
  }

  void _onFilterChanged(String farmId, String? pondId) {
    context.read<WaterQualityBloc>().add(
          WaterQualityFarmChanged(farmId: farmId, pondId: pondId),
        );
  }

  void _showThresholds(WaterQualityThresholds t) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: kHomeSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ngưỡng khuyến nghị',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: kHomePrimaryDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ngưỡng tham khảo mặc định; chưa xác minh cấu hình của khu.',
              style: TextStyle(color: kHomeTextSub, fontSize: 13),
            ),
            const SizedBox(height: 14),
            Text('pH: ${t.minPh} – ${t.maxPh}'),
            Text('Oxy hòa tan: ≥ ${t.minDissolvedOxygen} mg/L'),
            Text('Nhiệt độ: ${t.minTemperature} – ${t.maxTemperature} °C'),
            Text('Độ mặn: ${t.minSalinity} – ${t.maxSalinity} ppt'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final readings = widget.state.readings;
    final thresholds = widget.state.thresholds;
    final latestTimestamp =
        readings.isNotEmpty ? readings.first.timestamp : null;
    final resolvedFarmId = widget.state.farmId;
    final bool? online = widget.state.isOffline ? false : null;
    // A single sensor status cannot establish connectivity for the entire area.

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: _HeroHeader(
            onBack: () => appBack(context),
            onRefresh: () => context
                .read<WaterQualityBloc>()
                .add(const WaterQualityRefreshRequested()),
            filter: _farmsLoading
                ? const LinearProgressIndicator(
                    minHeight: 2,
                    color: kHomePrimary,
                    backgroundColor: kHomePrimaryBg,
                  )
                : FarmPondFilterWidget(
                    farms: _farms,
                    selectedFarmId: resolvedFarmId,
                    selectedPondId: widget.state.pondId,
                    isLoading: widget.state.isRefreshing,
                    embedded: true,
                    onSelectionChanged: _onFilterChanged,
                  ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, widget.bottomPad),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              if (widget.state.isDeviceOffline) ...[
                const _Banner(
                  icon: Icons.sensors_off_rounded,
                  title: 'Cảm biến ngoại tuyến',
                  subtitle: 'Thiết bị IoT không phản hồi',
                  color: kHomeDanger,
                ),
                const SizedBox(height: 10),
              ],
              if (widget.state.isOffline) ...[
                const _Banner(
                  icon: Icons.wifi_off_rounded,
                  title: 'Mất kết nối mạng',
                  subtitle: 'Không hiển thị lịch sử khi chưa xác minh quyền.',
                  color: kHomeWarning,
                ),
                const SizedBox(height: 10),
              ],
              _SensorStatusRow(
                timestamp: latestTimestamp,
                online: online,
              ),
              const SizedBox(height: 16),
              _CurrentMetricsSection(
                metrics: _metrics,
                onRecommend: () => _showThresholds(thresholds),
              ),
              const SizedBox(height: 16),
              ScopedHistoryChart(
                areaId: resolvedFarmId,
                rowId: widget.state.pondId,
                readings: readings,
                online: !widget.state.isOffline,
                fetch: sl<ScopedHistoryService>().fetchOnline,
                revision: () => sl<ScopedHistoryService>().revision,
                invalidations: sl<ScopedHistoryService>().invalidations,
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({
    required this.onBack,
    required this.onRefresh,
    required this.filter,
  });

  final VoidCallback onBack;
  final VoidCallback onRefresh;
  final Widget filter;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Column(
          children: [
            SizedBox(
              height: 210,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/background_chao_user.png',
                    fit: BoxFit.cover,
                    alignment: const Alignment(0, -0.35),
                    errorBuilder: (_, __, ___) => const ColoredBox(
                      color: Color(0xFFBFE8D4),
                    ),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [0.0, 0.55, 1.0],
                        colors: [
                          Color(0x33FFFFFF),
                          Color(0x00FFFFFF),
                          Color(0xCCF7FCFA),
                        ],
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(6, 10, 14, 0),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: onBack,
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 16,
                              color: Color(0xFF1F6B4A),
                            ),
                          ),
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: const Color(0xFFD4F5C4),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.water_drop_rounded,
                              size: 20,
                              color: Color(0xFF2F8A4E),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Chất lượng nước',
                                  style: TextStyle(
                                    color: Color(0xFF163A2C),
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    height: 1.15,
                                  ),
                                ),
                                Text(
                                  'Cảm biến khu nuôi',
                                  style: TextStyle(
                                    color: Color(0xFF5A7A6C),
                                    fontSize: 12,
                                    height: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Material(
                            color: Colors.white.withValues(alpha: 0.92),
                            shape: const CircleBorder(),
                            child: InkWell(
                              onTap: onRefresh,
                              customBorder: const CircleBorder(),
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFFD5E8DC),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.refresh_rounded,
                                  size: 20,
                                  color: Color(0xFF2F8A4E),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: filter,
          ),
        ),
      ],
    );
  }
}

class _SensorStatusRow extends StatelessWidget {
  const _SensorStatusRow({
    required this.timestamp,
    required this.online,
  });

  final DateTime? timestamp;
  final bool? online;

  @override
  Widget build(BuildContext context) {
    final time = timestamp == null
        ? 'Chưa có dữ liệu'
        : DateFormat('dd/MM/yyyy HH:mm').format(timestamp!.toLocal());
    return Row(
      children: [
        const Icon(Icons.access_time_rounded, size: 14, color: kHomeTextSub),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            'Cập nhật: $time',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: kHomeTextSub),
          ),
        ),
        Icon(
          Icons.circle,
          size: 8,
          color: online == true ? const Color(0xFF2BB673) : online == false ? kHomeDanger : kHomeTextSub,
        ),
        const SizedBox(width: 4),
        Text(
          online == true ? 'Trực tuyến' : online == false ? 'Ngoại tuyến' : 'Chưa xác minh',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: online == true ? kHomePrimaryDark : online == false ? kHomeDanger : kHomeTextSub,
          ),
        ),
      ],
    );
  }
}

class _CurrentMetricsSection extends StatelessWidget {
  const _CurrentMetricsSection({
    required this.metrics,
    required this.onRecommend,
  });

  final List<WaterMetricItem> metrics;
  final VoidCallback onRecommend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: homeCardDecoration(radius: 22),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.monitor_heart_outlined,
                  size: 18, color: kHomePrimaryDark),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Chỉ số hiện tại',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: kHomeTextMain,
                  ),
                ),
              ),
              TextButton(
                onPressed: onRecommend,
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: kHomeTextSub,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.info_outline, size: 14),
                    SizedBox(width: 4),
                    Text('Ngưỡng khuyến nghị >'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          NineWaterMetrics(metrics: metrics),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
                Text(subtitle,
                    style: const TextStyle(color: kHomeTextSub, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({
    required this.isOffline,
    required this.message,
    required this.onRetry,
  });

  final bool isOffline;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final color = isOffline ? kHomeWarning : kHomeDanger;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Không thể tải dữ liệu cảm biến',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: kHomeTextSub, fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: kHomePrimary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonBody extends StatelessWidget {
  const _SkeletonBody({required this.bottom});
  final double bottom;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(16, 12, 16, bottom),
      children: const [
        _Skel(height: 168),
        SizedBox(height: 12),
        _Skel(height: 88),
        SizedBox(height: 14),
        _Skel(height: 220),
        SizedBox(height: 14),
        _Skel(height: 240),
        SizedBox(height: 14),
        _Skel(height: 160),
      ],
    );
  }
}

class _Skel extends StatelessWidget {
  const _Skel({required this.height});
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: kHomeBorder.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(18),
      ),
    );
  }
}
