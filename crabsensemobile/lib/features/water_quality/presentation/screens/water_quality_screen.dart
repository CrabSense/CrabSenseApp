// ignore_for_file: lines_longer_than_80_chars

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/network_info.dart';
import '../../../home/presentation/widgets/crab_hologram_painter.dart';
import '../../../home/presentation/widgets/home_palette.dart';
import '../../domain/entities/water_quality.dart';
import '../../domain/entities/water_quality_thresholds.dart';
import '../../domain/repositories/water_quality_repository.dart';
import '../bloc/water_quality_bloc.dart';
import '../bloc/water_quality_event.dart';
import '../bloc/water_quality_state.dart';
import '../models/farm_filter_model.dart';
import '../widgets/farm_pond_filter_widget.dart';
import '../widgets/historical_chart.dart';
import '../widgets/sensor_reading_card.dart';

/// Màn hình giám sát chất lượng nước + biểu đồ lịch sử.
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
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFF071426),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [kHomeNavyLift, kHomeNavy, kHomeNavyDeep],
              ),
              border: Border(
                bottom: BorderSide(
                  color: kHomeBorderBlue.withValues(alpha: 0.45),
                ),
              ),
            ),
          ),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.water_rounded,
                size: 18,
                color: kHomeCyan,
                shadows: [
                  Shadow(
                    color: kHomeCyan.withValues(alpha: 0.8),
                    blurRadius: 10,
                  ),
                ],
              ),
              const SizedBox(width: 8),
              const Text(
                'CHẤT LƯỢNG NƯỚC',
                style: TextStyle(
                  color: kHomeBlueLight,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          centerTitle: true,
        ),
        body: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: CrabHologramPainter(
                    color: kHomeCyan.withValues(alpha: 0.05),
                    trayExtent: 30,
                  ),
                ),
              ),
            ),
            BlocBuilder<WaterQualityBloc, WaterQualityState>(
              builder: (context, state) {
                if (state is WaterQualityLoading || state is WaterQualityInitial) {
                  return const _SkeletonWaterQuality();
                }

                if (state is WaterQualityError) {
                  return _ErrorBody(
                    isOffline: state.isOffline,
                    message: state.message,
                    onRetry: () => context.read<WaterQualityBloc>().add(
                          WaterQualityLoadRequested(
                            farmId: widget.farmId ?? 'default',
                            pondId: widget.pondId,
                          ),
                        ),
                  );
                }

                if (state is WaterQualityLoaded) {
                  return RefreshIndicator(
                    color: kHomeBlue,
                    backgroundColor: kHomeNavy,
                    onRefresh: () async {
                      context
                          .read<WaterQualityBloc>()
                          .add(const WaterQualityRefreshRequested());
                      await context.read<WaterQualityBloc>().stream.firstWhere(
                            (s) =>
                                (s is WaterQualityLoaded && !s.isRefreshing) ||
                                s is WaterQualityError,
                          );
                    },
                    child: _WaterQualityContent(state: state),
                  );
                }

                return const _SkeletonWaterQuality();
              },
            ),
          ],
        ),
      );
}

class _WaterQualityContent extends StatefulWidget {
  const _WaterQualityContent({required this.state});

  final WaterQualityLoaded state;

  @override
  State<_WaterQualityContent> createState() => _WaterQualityContentState();
}

class _WaterQualityContentState extends State<_WaterQualityContent> {
  HistoricalPeriod _selectedPeriod = HistoricalPeriod.last24Hours;
  List<FarmOption> _farms = const [];
  bool _farmsLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFarms();
  }

  Future<void> _loadFarms() async {
    try {
      final areasResult = await sl<ApiClient>().safeGet<Map<String, dynamic>>(
        ApiConstants.farmingAreas,
      );
      final rowsResult = await sl<ApiClient>().safeGet<Map<String, dynamic>>(
        ApiConstants.farmingRows,
      );

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
        final pond = PondOption(
          id: (map['id'] ?? '').toString(),
          name: (map['name'] ?? map['code'] ?? 'Dãy').toString(),
        );
        pondsByArea.putIfAbsent(areaId, () => <PondOption>[]).add(pond);
      }

      final farms = <FarmOption>[];
      for (final raw in areas) {
        final map = Map<String, dynamic>.from(raw as Map);
        final id = (map['id'] ?? '').toString();
        if (id.isEmpty) continue;
        farms.add(
          FarmOption(
            id: id,
            name: (map['name'] ?? map['code'] ?? 'Khu').toString(),
            ponds: pondsByArea[id] ?? const [],
          ),
        );
      }

      if (!mounted) return;
      setState(() {
        _farms = farms.isEmpty
            ? [
                FarmOption(
                  id: widget.state.farmId,
                  name: 'Khu hiện tại',
                  ponds: const [],
                ),
              ]
            : farms;
        _farmsLoading = false;
      });
    } on Exception {
      if (!mounted) return;
      setState(() {
        _farms = [
          FarmOption(
            id: widget.state.farmId,
            name: 'Khu hiện tại',
            ponds: const [],
          ),
        ];
        _farmsLoading = false;
      });
    }
  }

  List<WaterQuality> _filterByPeriod(
    List<WaterQuality> readings,
    HistoricalPeriod period,
  ) {
    final now = DateTime.now();
    final cutoff = switch (period) {
      HistoricalPeriod.last24Hours => now.subtract(const Duration(hours: 24)),
      HistoricalPeriod.last7Days => now.subtract(const Duration(days: 7)),
      HistoricalPeriod.last30Days => now.subtract(const Duration(days: 30)),
    };
    return readings.where((r) => r.timestamp.isAfter(cutoff)).toList();
  }

  String _resolvedFarmId() {
    final stateId = widget.state.farmId;
    if (_farms.any((f) => f.id == stateId)) return stateId;
    return _farms.isNotEmpty ? _farms.first.id : stateId;
  }

  void _onFilterChanged(BuildContext context, String farmId, String? pondId) {
    context
        .read<WaterQualityBloc>()
        .add(WaterQualityFarmChanged(farmId: farmId, pondId: pondId));
  }

  @override
  Widget build(BuildContext context) {
    final readings = widget.state.readings;
    final thresholds = widget.state.thresholds;
    final latestTimestamp =
        readings.isNotEmpty ? readings.first.timestamp : null;
    final historicalSource = widget.state.historicalReadings.isNotEmpty
        ? widget.state.historicalReadings
        : readings;
    final historicalReadings =
        _filterByPeriod(historicalSource, _selectedPeriod);
    final resolvedFarmId = _resolvedFarmId();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        if (_farmsLoading)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: LinearProgressIndicator(
              minHeight: 2,
              color: kHomeBlue,
              backgroundColor: kHomeNavyLift,
            ),
          )
        else
          FarmPondFilterWidget(
            farms: _farms,
            selectedFarmId: resolvedFarmId,
            selectedPondId: widget.state.pondId,
            isLoading: widget.state.isRefreshing,
            onSelectionChanged: (farmId, pondId) =>
                _onFilterChanged(context, farmId, pondId),
          ),
        const SizedBox(height: 14),

        if (widget.state.isDeviceOffline) ...[
          const _StatusBanner(
            title: 'Cảm biến ngoại tuyến',
            subtitle: 'Thiết bị IoT không phản hồi',
            icon: Icons.sensors_off_rounded,
            color: Colors.redAccent,
          ),
          const SizedBox(height: 8),
        ],
        if (widget.state.isOffline) ...[
          _OfflineBanner(lastRefreshedAt: widget.state.lastRefreshedAt),
          const SizedBox(height: 8),
        ],

        if (latestTimestamp != null) ...[
          _LastUpdatedRow(timestamp: latestTimestamp),
          const SizedBox(height: 14),
        ],

        _SectionLabel(icon: Icons.sensors_rounded, title: 'CHỈ SỐ HIỆN TẠI'),
        const SizedBox(height: 12),

        if (readings.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
            decoration: BoxDecoration(
              color: kHomeNavyDeep.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: kHomeBorderBlue.withValues(alpha: 0.4),
              ),
            ),
            child: Text(
              'Chưa có chỉ số cảm biến',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        else
          _SensorGrid(readings: readings, thresholds: thresholds),

        const SizedBox(height: 24),

        _SectionLabel(icon: Icons.show_chart_rounded, title: 'BIỂU ĐỒ LỊCH SỬ'),
        const SizedBox(height: 12),
        HistoricalChart(
          readings: historicalReadings,
          thresholds: thresholds,
          selectedPeriod: _selectedPeriod,
          onPeriodChanged: (period) {
            setState(() => _selectedPeriod = period);
          },
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: kHomeBlueLight,
            shadows: [
              Shadow(
                color: kHomeBlueLight.withValues(alpha: 0.8),
                blurRadius: 10,
              ),
            ],
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              color: kHomeBlueLight,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
              fontSize: 12.5,
            ),
          ),
        ],
      );
}

class _SensorGrid extends StatelessWidget {
  const _SensorGrid({required this.readings, required this.thresholds});

  final List<WaterQuality> readings;
  final WaterQualityThresholds thresholds;

  @override
  Widget build(BuildContext context) {
    final reading = readings.first;
    final timestampLabel = _formatTimestamp(reading.timestamp);

    final cards = [
      SensorReadingCard(
        label: 'Nhiệt độ',
        value: reading.temperature.toStringAsFixed(1),
        unit: '°C',
        icon: Icons.thermostat_rounded,
        isNormal: thresholds.isTemperatureNormal(reading.temperature),
        rangeLabel:
            '${thresholds.minTemperature.toStringAsFixed(0)}–'
            '${thresholds.maxTemperature.toStringAsFixed(0)}°C',
        timestamp: timestampLabel,
      ),
      SensorReadingCard(
        label: 'Độ pH',
        value: reading.ph.toStringAsFixed(1),
        unit: 'pH',
        icon: Icons.science_rounded,
        isNormal: thresholds.isPhNormal(reading.ph),
        rangeLabel:
            '${thresholds.minPh.toStringAsFixed(1)}–'
            '${thresholds.maxPh.toStringAsFixed(1)}',
        timestamp: timestampLabel,
      ),
      SensorReadingCard(
        label: 'Oxy hòa tan',
        value: reading.dissolvedOxygen.toStringAsFixed(1),
        unit: 'mg/L',
        icon: Icons.air_rounded,
        isNormal: thresholds.isDissolvedOxygenNormal(reading.dissolvedOxygen),
        rangeLabel: '≥${thresholds.minDissolvedOxygen.toStringAsFixed(0)} mg/L',
        timestamp: timestampLabel,
      ),
      SensorReadingCard(
        label: 'Độ mặn',
        value: reading.salinity.toStringAsFixed(1),
        unit: 'ppt',
        icon: Icons.waves_rounded,
        isNormal: thresholds.isSalinityNormal(reading.salinity),
        rangeLabel:
            '${thresholds.minSalinity.toStringAsFixed(0)}–'
            '${thresholds.maxSalinity.toStringAsFixed(0)} ppt',
        timestamp: timestampLabel,
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 0.9,
      children: cards,
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inSeconds < 60) return 'Vừa cập nhật';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    return '${diff.inHours} giờ trước';
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.15),
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner({this.lastRefreshedAt});

  final DateTime? lastRefreshedAt;

  @override
  Widget build(BuildContext context) {
    var subtitle = 'Đang hiển thị dữ liệu đã lưu';
    if (lastRefreshedAt != null) {
      final diff = DateTime.now().difference(lastRefreshedAt!);
      if (diff.inMinutes < 60) {
        subtitle = 'Đồng bộ lần cuối ${diff.inMinutes} phút trước';
      } else {
        subtitle = 'Đồng bộ lần cuối ${diff.inHours} giờ trước';
      }
    }

    return _StatusBanner(
      title: 'Mất kết nối mạng',
      subtitle: subtitle,
      icon: Icons.wifi_off_rounded,
      color: kHomeOrange,
    );
  }
}

class _LastUpdatedRow extends StatelessWidget {
  const _LastUpdatedRow({required this.timestamp});

  final DateTime timestamp;

  @override
  Widget build(BuildContext context) {
    final diff = DateTime.now().difference(timestamp);
    final label = diff.inSeconds < 60
        ? 'Cập nhật vừa xong'
        : diff.inMinutes < 60
            ? 'Cập nhật ${diff.inMinutes} phút trước'
            : 'Cập nhật ${diff.inHours} giờ trước';

    return Row(
      children: [
        Icon(
          Icons.access_time_rounded,
          size: 14,
          color: Colors.white.withValues(alpha: 0.4),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 12,
          ),
        ),
      ],
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
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: (isOffline ? kHomeOrange : Colors.redAccent)
                      .withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: (isOffline ? kHomeOrange : Colors.redAccent)
                        .withValues(alpha: 0.5),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isOffline ? kHomeOrange : Colors.redAccent)
                          .withValues(alpha: 0.3),
                      blurRadius: 14,
                    ),
                  ],
                ),
                child: Icon(
                  isOffline ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
                  size: 36,
                  color: isOffline ? kHomeOrange : Colors.redAccent,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isOffline ? 'Không có kết nối' : 'Đã xảy ra lỗi',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: onRetry,
                style: OutlinedButton.styleFrom(
                  foregroundColor: kHomeBlueLight,
                  side: BorderSide(
                    color: kHomeBorderBlue.withValues(alpha: 0.6),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
}

class _SkeletonWaterQuality extends StatelessWidget {
  const _SkeletonWaterQuality();

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _skel(height: 72, radius: 16),
          const SizedBox(height: 16),
          _skel(height: 14, width: 140, radius: 4),
          const SizedBox(height: 12),
          const Row(
            children: [
              Expanded(child: _SkelBox(height: 140)),
              SizedBox(width: 12),
              Expanded(child: _SkelBox(height: 140)),
            ],
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              Expanded(child: _SkelBox(height: 140)),
              SizedBox(width: 12),
              Expanded(child: _SkelBox(height: 140)),
            ],
          ),
          const SizedBox(height: 24),
          _skel(height: 14, width: 140, radius: 4),
          const SizedBox(height: 12),
          _skel(height: 280, radius: 16),
        ],
      );

  Widget _skel({required double height, double? width, double radius = 12}) =>
      Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: kHomeNavyLift.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: kHomeBorderBlue.withValues(alpha: 0.25)),
        ),
      );
}

class _SkelBox extends StatelessWidget {
  const _SkelBox({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) => Container(
        height: height,
        decoration: BoxDecoration(
          color: kHomeNavyLift.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kHomeBorderBlue.withValues(alpha: 0.25)),
        ),
      );
}
