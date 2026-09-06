// ignore_for_file: lines_longer_than_80_chars

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/network_info.dart';
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

/// Water Quality Screen — Light theme rebuild.
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
        backgroundColor: kHomeBg,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [kHomePrimary, kHomePrimaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.water_drop_rounded,
                          color: Colors.white, size: 16),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Chất lượng nước',
                      style: TextStyle(
                        color: kHomeTextMain,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                      onPressed: () => context
                          .read<WaterQualityBloc>()
                          .add(const WaterQualityRefreshRequested()),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: BlocBuilder<WaterQualityBloc, WaterQualityState>(
          builder: (context, state) {
            if (state is WaterQualityLoading || state is WaterQualityInitial) {
              return const _SkeletonBody();
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
                color: kHomePrimary,
                onRefresh: () async {
                  context.read<WaterQualityBloc>().add(
                        const WaterQualityRefreshRequested(),
                      );
                  await context.read<WaterQualityBloc>().stream.firstWhere(
                        (s) =>
                            (s is WaterQualityLoaded && !s.isRefreshing) ||
                            s is WaterQualityError,
                      );
                },
                child: _WaterQualityContent(state: state),
              );
            }
            return const _SkeletonBody();
          },
        ),
      );
}

// ─── Content ──────────────────────────────────────────────────────────────────

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

  List<WaterQuality> _filterByPeriod(List<WaterQuality> readings) {
    final now = DateTime.now();
    final cutoff = switch (_selectedPeriod) {
      HistoricalPeriod.last24Hours => now.subtract(const Duration(hours: 24)),
      HistoricalPeriod.last7Days => now.subtract(const Duration(days: 7)),
      HistoricalPeriod.last30Days => now.subtract(const Duration(days: 30)),
    };
    return readings.where((r) => r.timestamp.isAfter(cutoff)).toList();
  }

  void _onFilterChanged(String farmId, String? pondId) {
    context.read<WaterQualityBloc>().add(
          WaterQualityFarmChanged(farmId: farmId, pondId: pondId),
        );
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
    final historicalReadings = _filterByPeriod(historicalSource);
    final resolvedFarmId = widget.state.farmId;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // Farm dropdown selector
        Container(
          padding: const EdgeInsets.all(14),
          decoration: homeCardDecoration(),
          child: _farmsLoading
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
                  onSelectionChanged: _onFilterChanged,
                ),
        ),
        const SizedBox(height: 14),

        // Offline/device banners
        if (widget.state.isDeviceOffline) ...[
          _Banner(
            icon: Icons.sensors_off_rounded,
            title: 'Cảm biến ngoại tuyến',
            subtitle: 'Thiết bị IoT không phản hồi',
            color: kHomeDanger,
          ),
          const SizedBox(height: 8),
        ],
        if (widget.state.isOffline) ...[
          _Banner(
            icon: Icons.wifi_off_rounded,
            title: 'Mất kết nối mạng',
            subtitle: 'Đang hiển thị dữ liệu đã lưu',
            color: kHomeWarning,
          ),
          const SizedBox(height: 8),
        ],

        // Last updated
        if (latestTimestamp != null) ...[
          _LastUpdatedRow(timestamp: latestTimestamp),
          const SizedBox(height: 12),
        ],

        // Section: Current indicators
        const _SectionLabel(
          icon: Icons.sensors_rounded,
          title: 'Chỉ số hiện tại',
        ),
        const SizedBox(height: 10),

        // 2×2 grid
        if (readings.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 32),
            decoration: homeCardDecoration(),
            child: const Center(
              child: Text(
                'Chưa có chỉ số cảm biến',
                style: TextStyle(color: kHomeTextHint),
              ),
            ),
          )
        else
          _SensorGrid(readings: readings, thresholds: thresholds),

        const SizedBox(height: 20),

        // Period tabs + chart
        const _SectionLabel(
          icon: Icons.show_chart_rounded,
          title: 'Lịch sử',
        ),
        const SizedBox(height: 10),

        // Period selector tabs
        _PeriodSelector(
          selected: _selectedPeriod,
          onChanged: (p) => setState(() => _selectedPeriod = p),
        ),
        const SizedBox(height: 10),

        HistoricalChart(
          readings: historicalReadings,
          thresholds: thresholds,
          selectedPeriod: _selectedPeriod,
          onPeriodChanged: (p) => setState(() => _selectedPeriod = p),
        ),

        const SizedBox(height: 16),

        // Footer: last update time
        if (latestTimestamp != null)
          Center(
            child: Text(
              _formatLastUpdate(latestTimestamp),
              style: const TextStyle(fontSize: 12, color: kHomeTextHint),
            ),
          ),
      ],
    );
  }

  String _formatLastUpdate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Cập nhật vừa xong';
    if (diff.inMinutes < 60) return 'Cập nhật ${diff.inMinutes} phút trước';
    return 'Cập nhật ${diff.inHours} giờ trước';
  }
}

// ─── Period Selector ──────────────────────────────────────────────────────────

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({required this.selected, required this.onChanged});

  final HistoricalPeriod selected;
  final void Function(HistoricalPeriod) onChanged;

  @override
  Widget build(BuildContext context) {
    final labels = {
      HistoricalPeriod.last24Hours: '24h',
      HistoricalPeriod.last7Days: '7 ngày',
      HistoricalPeriod.last30Days: '30 ngày',
    };
    return Row(
      children: labels.entries.map((e) {
        final isSelected = selected == e.key;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(e.key),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? kHomePrimary : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? kHomePrimary : kHomeBorder,
                ),
              ),
              child: Text(
                e.value,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : kHomeTextSub,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Sensor Grid ──────────────────────────────────────────────────────────────

class _SensorGrid extends StatelessWidget {
  const _SensorGrid({required this.readings, required this.thresholds});

  final List<WaterQuality> readings;
  final WaterQualityThresholds thresholds;

  @override
  Widget build(BuildContext context) {
    final reading = readings.first;
    final ts = _formatTimestamp(reading.timestamp);

    final cards = [
      SensorReadingCard(
        label: 'Độ pH',
        value: reading.ph.toStringAsFixed(1),
        unit: 'pH',
        icon: Icons.science_rounded,
        isNormal: thresholds.isPhNormal(reading.ph),
        rangeLabel:
            '${thresholds.minPh.toStringAsFixed(1)}–${thresholds.maxPh.toStringAsFixed(1)}',
        timestamp: ts,
      ),
      SensorReadingCard(
        label: 'Oxy hòa tan',
        value: reading.dissolvedOxygen.toStringAsFixed(1),
        unit: 'mg/L',
        icon: Icons.air_rounded,
        isNormal: thresholds.isDissolvedOxygenNormal(reading.dissolvedOxygen),
        rangeLabel: '≥${thresholds.minDissolvedOxygen.toStringAsFixed(0)} mg/L',
        timestamp: ts,
      ),
      SensorReadingCard(
        label: 'Nhiệt độ',
        value: reading.temperature.toStringAsFixed(1),
        unit: '°C',
        icon: Icons.thermostat_rounded,
        isNormal: thresholds.isTemperatureNormal(reading.temperature),
        rangeLabel:
            '${thresholds.minTemperature.toStringAsFixed(0)}–${thresholds.maxTemperature.toStringAsFixed(0)}°C',
        timestamp: ts,
      ),
      SensorReadingCard(
        label: 'Độ mặn',
        value: reading.salinity.toStringAsFixed(1),
        unit: 'ppt',
        icon: Icons.waves_rounded,
        isNormal: thresholds.isSalinityNormal(reading.salinity),
        rangeLabel:
            '${thresholds.minSalinity.toStringAsFixed(0)}–${thresholds.maxSalinity.toStringAsFixed(0)} ppt',
        timestamp: ts,
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

  String _formatTimestamp(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Vừa cập nhật';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    return '${diff.inHours} giờ trước';
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: kHomePrimaryBg,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: kHomePrimary, size: 14),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: kHomeTextMain,
          ),
        ),
      ],
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
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.4)),
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
                    style:
                        const TextStyle(color: kHomeTextSub, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
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
        ? 'Vừa cập nhật'
        : diff.inMinutes < 60
            ? '${diff.inMinutes} phút trước'
            : '${diff.inHours} giờ trước';
    return Row(
      children: [
        const Icon(Icons.access_time_rounded, size: 13, color: kHomeTextHint),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(color: kHomeTextHint, fontSize: 12)),
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
  Widget build(BuildContext context) {
    final color = isOffline ? kHomeWarning : kHomeDanger;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
                border: Border.all(color: color.withOpacity(0.5)),
              ),
              child: Icon(
                isOffline ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
                size: 36,
                color: color,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isOffline ? 'Không có kết nối' : 'Đã xảy ra lỗi',
              style: const TextStyle(
                color: kHomeTextMain,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: kHomeTextSub, fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Thử lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kHomePrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonBody extends StatelessWidget {
  const _SkeletonBody();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _Skel(height: 72),
        const SizedBox(height: 14),
        const Row(
          children: [
            Expanded(child: _Skel(height: 140)),
            SizedBox(width: 12),
            Expanded(child: _Skel(height: 140)),
          ],
        ),
        const SizedBox(height: 12),
        const Row(
          children: [
            Expanded(child: _Skel(height: 140)),
            SizedBox(width: 12),
            Expanded(child: _Skel(height: 140)),
          ],
        ),
        const SizedBox(height: 20),
        _Skel(height: 14, width: 120),
        const SizedBox(height: 10),
        _Skel(height: 260),
      ],
    );
  }
}

class _Skel extends StatelessWidget {
  const _Skel({required this.height, this.width});

  final double height;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: kHomeBorder.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
