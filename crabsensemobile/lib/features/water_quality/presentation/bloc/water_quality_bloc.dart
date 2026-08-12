import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/water_quality.dart';
import '../../domain/entities/water_quality_thresholds.dart';
import '../../domain/repositories/water_quality_repository.dart';
import '../../domain/usecases/get_current_readings_usecase.dart';
import '../../domain/usecases/get_historical_data_usecase.dart';
import 'water_quality_event.dart';
import 'water_quality_state.dart';

/// BLoC for the water quality feature.
///
/// Handles [WaterQualityEvent]s and emits [WaterQualityState]s for the
/// water quality screen to render.
///
/// Event → State transitions:
/// - [WaterQualityLoadRequested] → [WaterQualityLoading] →
///   [WaterQualityLoaded] or [WaterQualityError]
/// - [WaterQualityRefreshRequested] → keeps current [WaterQualityLoaded]
///   with isRefreshing:true → [WaterQualityLoaded] (fresh) or
///   [WaterQualityError]
/// - [WaterQualityFarmChanged] → [WaterQualityLoading] →
///   [WaterQualityLoaded] or [WaterQualityError]
///
/// Requirements: 8.1, 8.7, 8.8, 8.9, 8.10
class WaterQualityBloc extends Bloc<WaterQualityEvent, WaterQualityState> {
  WaterQualityBloc({
    required this.getCurrentReadings,
    required this.getHistoricalData,
    required this.repository,
  }) : super(const WaterQualityInitial()) {
    on<WaterQualityLoadRequested>(_onLoadRequested);
    on<WaterQualityRefreshRequested>(_onRefreshRequested);
    on<WaterQualityFarmChanged>(_onFarmChanged);
  }

  final GetCurrentReadingsUseCase getCurrentReadings;
  final GetHistoricalDataUseCase getHistoricalData;
  final WaterQualityRepository repository;

  /// Default thresholds used for all readings (const, no network fetch).
  static const _thresholds = WaterQualityThresholds();

  // ── WaterQualityLoadRequested ──────────────────────────────────────────

  /// Handles initial load.
  ///
  /// Emits [WaterQualityLoading] first so the UI shows skeleton
  /// placeholders (Requirement 8.1), then fetches readings and checks
  /// device status for the first sensor found (Requirement 8.8).
  ///
  /// Requirements: 8.1, 8.8, 8.10
  Future<void> _onLoadRequested(
    WaterQualityLoadRequested event,
    Emitter<WaterQualityState> emit,
  ) async {
    emit(const WaterQualityLoading());
    await _fetchAndEmit(emit, farmId: event.farmId, pondId: event.pondId);
  }

  // ── WaterQualityRefreshRequested ───────────────────────────────────────

  /// Handles pull-to-refresh and auto-refresh.
  ///
  /// Marks the current [WaterQualityLoaded] state as refreshing so the UI
  /// can show a refresh indicator while keeping the previous data visible,
  /// then forces a fresh API call (Requirement 8.7).
  ///
  /// If the current state is not [WaterQualityLoaded], falls back to a
  /// normal load with the default farm id.
  ///
  /// Requirements: 8.7
  Future<void> _onRefreshRequested(
    WaterQualityRefreshRequested event,
    Emitter<WaterQualityState> emit,
  ) async {
    var farmId = 'default';
    String? pondId;

    if (state is WaterQualityLoaded) {
      final loaded = state as WaterQualityLoaded;
      farmId = loaded.farmId;
      pondId = loaded.pondId;
      emit(loaded.copyWith(isRefreshing: true));
    }

    await _fetchAndEmit(emit, farmId: farmId, pondId: pondId);
  }

  // ── WaterQualityFarmChanged ────────────────────────────────────────────

  /// Handles farm/pond selection changes.
  ///
  /// Treats the change as a brand-new load for the new farmId/pondId
  /// (Requirement 8.9).
  ///
  /// Requirements: 8.9
  Future<void> _onFarmChanged(
    WaterQualityFarmChanged event,
    Emitter<WaterQualityState> emit,
  ) async {
    emit(const WaterQualityLoading());
    await _fetchAndEmit(emit, farmId: event.farmId, pondId: event.pondId);
  }

  // ── Shared fetch helper ────────────────────────────────────────────────

  /// Fetches current + historical readings and checks device status.
  Future<void> _fetchAndEmit(
    Emitter<WaterQualityState> emit, {
    required String farmId,
    String? pondId,
  }) async {
    final result = await getCurrentReadings(
      GetCurrentReadingsParams(farmId: farmId, pondId: pondId),
    );

    // History for charts — load 30d once; UI filters by selected period.
    final historyResult = await getHistoricalData(
      GetHistoricalDataParams(
        farmId: farmId,
        pondId: pondId,
        period: HistoricalPeriod.last30Days,
      ),
    );
    final historical = historyResult.fold<List<WaterQuality>>(
      (_) => const <WaterQuality>[],
      (list) => list,
    );

    await result.fold(
      (failure) async => emit(
        WaterQualityError(
          message: failure.message,
          isOffline: failure is NetworkFailure,
        ),
      ),
      (readings) async {
        // Check device status for the first sensor found (Req 8.8).
        // Default to false if no readings (device is unknown, not offline).
        // ignore: omit_local_variable_types
        var isDeviceOffline = false;
        if (readings.isNotEmpty && readings.first.sensorId.isNotEmpty) {
          final statusResult = await repository.checkDeviceStatus(
            sensorId: readings.first.sensorId,
          );
          statusResult.fold(
            (_) => isDeviceOffline = false, // Cannot determine — show as online
            (isOnline) => isDeviceOffline = !isOnline,
          );
        }

        emit(
          WaterQualityLoaded(
            readings: readings,
            historicalReadings: historical,
            thresholds: _thresholds,
            farmId: farmId,
            pondId: pondId,
            isDeviceOffline: isDeviceOffline,
            lastRefreshedAt: DateTime.now(),
          ),
        );
      },
    );
  }
}
