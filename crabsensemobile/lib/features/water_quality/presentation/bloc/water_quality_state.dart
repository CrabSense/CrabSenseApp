import 'package:equatable/equatable.dart';

import '../../domain/entities/water_quality.dart';
import '../../domain/entities/water_quality_thresholds.dart';

/// Base class for all water quality states.
///
/// States represent the current condition of the water quality feature.
/// All states use [Equatable] for value equality.
///
/// Requirements: 8.1–8.10
abstract class WaterQualityState extends Equatable {
  const WaterQualityState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any load has been requested.
///
/// The screen is freshly created; no data has been fetched yet.
class WaterQualityInitial extends WaterQualityState {
  const WaterQualityInitial();
}

/// State emitted while the initial water quality data is being loaded.
///
/// The UI should show skeleton/shimmer placeholders (Requirement 8.1).
class WaterQualityLoading extends WaterQualityState {
  const WaterQualityLoading();
}

/// State emitted when water quality data has been successfully loaded.
///
/// Contains the sensor [readings] and [thresholds] used to determine
/// if values are within acceptable ranges (Requirement 8.4).
///
/// When [isOffline] is true the UI should display a network offline banner
/// showing cached readings (Requirement 8.10).
///
/// When [isDeviceOffline] is true the UI should display a sensor offline
/// banner (Requirement 8.8).
///
/// The [lastRefreshedAt] timestamp drives the 30-second auto-refresh
/// timer (Requirement 8.7).
///
/// Requirements: 8.1–8.4, 8.7, 8.8, 8.10
class WaterQualityLoaded extends WaterQualityState {
  const WaterQualityLoaded({
    required this.readings,
    required this.thresholds,
    required this.farmId,
    this.pondId,
    this.isOffline = false,
    this.isDeviceOffline = false,
    this.isRefreshing = false,
    this.lastRefreshedAt,
  });

  /// The most recent sensor readings to display.
  final List<WaterQuality> readings;

  /// Threshold values used to determine if readings are out of range.
  final WaterQualityThresholds thresholds;

  /// The farm these readings belong to.
  final String farmId;

  /// Optional pond filter that was active when readings were fetched.
  final String? pondId;

  /// True when readings come from local cache (no internet).
  ///
  /// Displays a network offline banner when true (Requirement 8.10).
  final bool isOffline;

  /// True when the IoT sensor is not responding.
  ///
  /// Displays a sensor offline banner when true (Requirement 8.8).
  final bool isDeviceOffline;

  /// True while a background refresh is in flight.
  ///
  /// Allows the UI to keep showing the previous data while the
  /// pull-to-refresh indicator is visible (Requirement 8.7).
  final bool isRefreshing;

  /// Timestamp of the most recent successful data fetch.
  final DateTime? lastRefreshedAt;

  /// Returns a copy of this state with selected fields replaced.
  WaterQualityLoaded copyWith({
    List<WaterQuality>? readings,
    WaterQualityThresholds? thresholds,
    String? farmId,
    String? pondId,
    bool? isOffline,
    bool? isDeviceOffline,
    bool? isRefreshing,
    DateTime? lastRefreshedAt,
  }) => WaterQualityLoaded(
    readings: readings ?? this.readings,
    thresholds: thresholds ?? this.thresholds,
    farmId: farmId ?? this.farmId,
    pondId: pondId ?? this.pondId,
    isOffline: isOffline ?? this.isOffline,
    isDeviceOffline: isDeviceOffline ?? this.isDeviceOffline,
    isRefreshing: isRefreshing ?? this.isRefreshing,
    lastRefreshedAt: lastRefreshedAt ?? this.lastRefreshedAt,
  );

  @override
  List<Object?> get props => [
    readings,
    thresholds,
    farmId,
    pondId,
    isOffline,
    isDeviceOffline,
    isRefreshing,
    lastRefreshedAt,
  ];
}

/// State emitted when loading water quality data fails.
///
/// - [message]: human-readable error description shown to the user.
/// - [isOffline]: true when the failure is a connectivity error.
///   The UI shows a more specific offline message in this case.
///
/// Requirements: 8.1, 8.10
class WaterQualityError extends WaterQualityState {
  const WaterQualityError({required this.message, this.isOffline = false});

  /// User-facing error message.
  final String message;

  /// Whether the failure is a connectivity error vs a server/cache error.
  final bool isOffline;

  @override
  List<Object?> get props => [message, isOffline];
}
