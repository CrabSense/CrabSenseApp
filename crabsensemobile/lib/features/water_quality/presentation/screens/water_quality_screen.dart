import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/network_info.dart';
import '../../../../shared/widgets/errors/error_state_widget.dart';
import '../../../../shared/widgets/loading/skeleton_loader.dart';
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

/// The water quality monitoring screen of the CrabSense application.
///
/// Provides:
/// 1. Real-time sensor readings: temperature, pH, dissolved oxygen, salinity
/// 2. Threshold-based warning indicators for out-of-range values
/// 3. Offline/device offline status banners
/// 4. Pull-to-refresh and 30-second auto-refresh
/// 5. Historical data charts with period selector (task 13.4)
///
/// Requirements: 8.1–8.10
class WaterQualityScreen extends StatelessWidget {
  const WaterQualityScreen({super.key, this.farmId, this.pondId});

  /// The farm to display water quality readings for.
  final String? farmId;

  /// Optional specific pond within the farm.
  final String? pondId;

  @override
  Widget build(BuildContext context) => BlocProvider<WaterQualityBloc>(
    create: (_) =>
        sl<WaterQualityBloc>()
          ..add(WaterQualityLoadRequested(farmId: farmId ?? 'default', pondId: pondId)),
    child: _WaterQualityView(farmId: farmId, pondId: pondId),
  );
}

/// Internal stateful view that owns the 30-second auto-refresh timer
/// and connectivity listener.
///
/// Requirements: 8.7, 8.10
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

  // Tracks whether we were previously offline so we can refresh on reconnect.
  bool _wasOffline = false;

  @override
  void initState() {
    super.initState();
    _startAutoRefreshTimer();
    _listenToConnectivity();
  }

  /// Starts the 30-second auto-refresh timer.
  ///
  /// Only dispatches [WaterQualityRefreshRequested] when the device is
  /// online. Requirement 8.7: auto-refresh every 30 seconds when screen
  /// is active.
  void _startAutoRefreshTimer() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      if (!mounted) return;
      final networkInfo = sl<NetworkInfo>();
      final isOnline = await networkInfo.isConnected;
      if (isOnline && mounted) {
        context.read<WaterQualityBloc>().add(const WaterQualityRefreshRequested());
      }
    });
  }

  /// Subscribes to connectivity changes.
  ///
  /// When the device comes back online after being offline, triggers an
  /// immediate refresh to fetch fresh data (Requirement 8.10).
  void _listenToConnectivity() {
    _connectivitySubscription = sl<Connectivity>().onConnectivityChanged.listen((result) {
      if (!mounted) return;
      final isOnline =
          result == ConnectivityResult.mobile ||
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
    backgroundColor: CrabSenseColors.background,
    appBar: AppBar(
      title: const Text('Water Quality'),
      backgroundColor: CrabSenseColors.surface,
      foregroundColor: CrabSenseColors.textPrimary,
    ),
    body: BlocBuilder<WaterQualityBloc, WaterQualityState>(
      builder: (context, state) {
        if (state is WaterQualityLoading || state is WaterQualityInitial) {
          return const _SkeletonWaterQuality();
        }

        if (state is WaterQualityError) {
          return ErrorStateWidget(
            icon: state.isOffline ? Icons.wifi_off : Icons.error_outline,
            title: state.isOffline ? 'No Connection' : 'Something went wrong',
            message: state.message,
            onRetry: () => context.read<WaterQualityBloc>().add(
              WaterQualityLoadRequested(farmId: widget.farmId ?? 'default', pondId: widget.pondId),
            ),
          );
        }

        if (state is WaterQualityLoaded) {
          return RefreshIndicator(
            color: CrabSenseColors.primary,
            backgroundColor: CrabSenseColors.surface,
            onRefresh: () async {
              context.read<WaterQualityBloc>().add(const WaterQualityRefreshRequested());
              await context.read<WaterQualityBloc>().stream.firstWhere(
                (s) => (s is WaterQualityLoaded && !s.isRefreshing) || s is WaterQualityError,
              );
            },
            child: _WaterQualityContent(state: state),
          );
        }

        return const _SkeletonWaterQuality();
      },
    ),
  );
}

// ── Loaded content ────────────────────────────────────────────────────────────

/// Scrollable content rendered when [WaterQualityLoaded] is the current
/// state.
///
/// Maintains local [_selectedPeriod] state for the historical chart period
/// selector and filters readings client-side before passing them to
/// [HistoricalChart].
///
/// Shows a [FarmPondFilterWidget] at the top so the user can switch between
/// farms and optionally narrow to a specific pond (Requirement 8.9). Farm
/// or pond selection dispatches [WaterQualityFarmChanged] to the BLoC,
/// which triggers a full re-fetch for the new location.
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
        final areaId = (map['farmingAreaId'] ?? map['FarmingAreaId'] ?? '').toString();
        if (areaId.isEmpty) continue;
        final pond = PondOption(
          id: (map['id'] ?? '').toString(),
          name: (map['name'] ?? map['code'] ?? 'Row').toString(),
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
            name: (map['name'] ?? map['code'] ?? 'Farm').toString(),
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
                  name: 'Current farm',
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
          FarmOption(id: widget.state.farmId, name: 'Current farm', ponds: const []),
        ];
        _farmsLoading = false;
      });
    }
  }

  /// Filters [readings] to only include entries within the given [period].
  List<WaterQuality> _filterByPeriod(List<WaterQuality> readings, HistoricalPeriod period) {
    final now = DateTime.now();
    final cutoff = switch (period) {
      HistoricalPeriod.last24Hours => now.subtract(const Duration(hours: 24)),
      HistoricalPeriod.last7Days => now.subtract(const Duration(days: 7)),
      HistoricalPeriod.last30Days => now.subtract(const Duration(days: 30)),
    };
    return readings.where((r) => r.timestamp.isAfter(cutoff)).toList();
  }

  /// Returns the farm id to display in the filter.
  String _resolvedFarmId() {
    final stateId = widget.state.farmId;
    if (_farms.any((f) => f.id == stateId)) return stateId;
    return _farms.isNotEmpty ? _farms.first.id : stateId;
  }

  void _onFilterChanged(BuildContext context, String farmId, String? pondId) {
    context.read<WaterQualityBloc>().add(WaterQualityFarmChanged(farmId: farmId, pondId: pondId));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final readings = widget.state.readings;
    final thresholds = widget.state.thresholds;

    final latestTimestamp = readings.isNotEmpty ? readings.first.timestamp : null;
    final historicalReadings = _filterByPeriod(readings, _selectedPeriod);
    final resolvedFarmId = _resolvedFarmId();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // ── Farm / Pond filter ────────────────────────────────────────
        if (_farmsLoading)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: LinearProgressIndicator(minHeight: 2),
          )
        else
          FarmPondFilterWidget(
            farms: _farms,
            selectedFarmId: resolvedFarmId,
            selectedPondId: widget.state.pondId,
          isLoading: widget.state.isRefreshing,
          onSelectionChanged: (farmId, pondId) => _onFilterChanged(context, farmId, pondId),
        ),
        const SizedBox(height: 16),

        // ── Offline banners ───────────────────────────────────────────
        if (widget.state.isDeviceOffline) ...[
          const _StatusBanner(
            title: 'Sensor Offline',
            subtitle: 'IoT sensor is not responding',
            icon: Icons.sensors_off,
            color: CrabSenseColors.error,
          ),
          const SizedBox(height: 8),
        ],
        if (widget.state.isOffline) ...[
          _OfflineBanner(lastRefreshedAt: widget.state.lastRefreshedAt),
          const SizedBox(height: 8),
        ],

        // ── Last updated row ──────────────────────────────────────────
        if (latestTimestamp != null) ...[
          _LastUpdatedRow(timestamp: latestTimestamp),
          const SizedBox(height: 16),
        ],

        // ── Section title ─────────────────────────────────────────────
        Text(
          'Current Readings',
          style: theme.textTheme.titleSmall?.copyWith(
            color: CrabSenseColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),

        // ── 2×2 grid of sensor reading cards ─────────────────────────
        if (readings.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Text(
                'No readings available',
                style: theme.textTheme.bodyMedium?.copyWith(color: CrabSenseColors.textSecondary),
              ),
            ),
          )
        else
          _SensorGrid(readings: readings, thresholds: thresholds),

        const SizedBox(height: 24),

        // ── Historical data chart ─────────────────────────────────────
        Text(
          'Historical Data',
          style: theme.textTheme.titleSmall?.copyWith(
            color: CrabSenseColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
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

// ── Sensor grid (2 columns) ───────────────────────────────────────────────────

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
        label: 'Temperature',
        value: reading.temperature.toStringAsFixed(1),
        unit: '°C',
        icon: Icons.thermostat_outlined,
        isNormal: thresholds.isTemperatureNormal(reading.temperature),
        rangeLabel:
            '${thresholds.minTemperature.toStringAsFixed(0)}–'
            '${thresholds.maxTemperature.toStringAsFixed(0)}°C',
        timestamp: timestampLabel,
      ),
      SensorReadingCard(
        label: 'pH Level',
        value: reading.ph.toStringAsFixed(1),
        unit: 'pH',
        icon: Icons.science_outlined,
        isNormal: thresholds.isPhNormal(reading.ph),
        rangeLabel:
            '${thresholds.minPh.toStringAsFixed(1)}–'
            '${thresholds.maxPh.toStringAsFixed(1)}',
        timestamp: timestampLabel,
      ),
      SensorReadingCard(
        label: 'Dissolved O₂',
        value: reading.dissolvedOxygen.toStringAsFixed(1),
        unit: 'mg/L',
        icon: Icons.water_outlined,
        isNormal: thresholds.isDissolvedOxygenNormal(reading.dissolvedOxygen),
        rangeLabel: '≥${thresholds.minDissolvedOxygen.toStringAsFixed(0)} mg/L',
        timestamp: timestampLabel,
      ),
      SensorReadingCard(
        label: 'Salinity',
        value: reading.salinity.toStringAsFixed(1),
        unit: 'ppt',
        icon: Icons.waves_outlined,
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
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }
}

// ── Status banners ────────────────────────────────────────────────────────────

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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
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
                Text(
                  title,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(color: CrabSenseColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner({this.lastRefreshedAt});

  final DateTime? lastRefreshedAt;

  @override
  Widget build(BuildContext context) {
    var subtitle = 'Showing cached readings';
    if (lastRefreshedAt != null) {
      final diff = DateTime.now().difference(lastRefreshedAt!);
      if (diff.inMinutes < 60) {
        subtitle = 'Last synced ${diff.inMinutes}m ago';
      } else {
        subtitle = 'Last synced ${diff.inHours}h ago';
      }
    }

    return _StatusBanner(
      title: 'Network Offline',
      subtitle: subtitle,
      icon: Icons.wifi_off,
      color: CrabSenseColors.warning,
    );
  }
}

// ── Last updated row ──────────────────────────────────────────────────────────

class _LastUpdatedRow extends StatelessWidget {
  const _LastUpdatedRow({required this.timestamp});

  final DateTime timestamp;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final diff = DateTime.now().difference(timestamp);
    String label;
    if (diff.inSeconds < 60) {
      label = 'Updated just now';
    } else if (diff.inMinutes < 60) {
      label = 'Updated ${diff.inMinutes}m ago';
    } else {
      label = 'Updated ${diff.inHours}h ago';
    }

    return Row(
      children: [
        const Icon(Icons.access_time, size: 14, color: CrabSenseColors.textDisabled),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(color: CrabSenseColors.textDisabled),
        ),
      ],
    );
  }
}

// ── Skeleton loading ──────────────────────────────────────────────────────────

/// Full-screen skeleton shown during the initial data load.
///
/// Requirement 8.1: display within 3 seconds, show loading state.
class _SkeletonWaterQuality extends StatelessWidget {
  const _SkeletonWaterQuality();

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
    children: const [
      SkeletonLoader(height: 14, width: 120, borderRadius: 4),
      SizedBox(height: 16),
      SkeletonLoader(height: 14, width: 100, borderRadius: 4),
      SizedBox(height: 12),
      Row(
        children: [
          Expanded(child: SkeletonLoader(height: 140, borderRadius: 16)),
          SizedBox(width: 12),
          Expanded(child: SkeletonLoader(height: 140, borderRadius: 16)),
        ],
      ),
      SizedBox(height: 12),
      Row(
        children: [
          Expanded(child: SkeletonLoader(height: 140, borderRadius: 16)),
          SizedBox(width: 12),
          Expanded(child: SkeletonLoader(height: 140, borderRadius: 16)),
        ],
      ),
      SizedBox(height: 24),
      SkeletonLoader(height: 14, width: 100, borderRadius: 4),
      SizedBox(height: 12),
      SkeletonLoader(height: 280, borderRadius: 16),
    ],
  );
}
