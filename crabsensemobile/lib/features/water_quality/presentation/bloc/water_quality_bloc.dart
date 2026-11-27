import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
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
  int _generation = 0;
  bool _inFlight = false;
  String _farmId = 'default';
  String? _pondId;
  bool _current(int generation, Emitter<WaterQualityState> emit) =>
      !isClosed && !emit.isDone && generation == _generation;

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
    _farmId = event.farmId; _pondId = event.pondId;
    final generation = ++_generation;
    emit(const WaterQualityLoading());
    await _fetchAndEmit(emit, farmId: _farmId, pondId: _pondId, generation: generation);
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
    if (_inFlight) return;
    final generation = ++_generation;
    if (state is WaterQualityLoaded) {
      emit((state as WaterQualityLoaded).copyWith(isRefreshing: true));
    } else {
      emit(const WaterQualityLoading());
    }
    await _fetchAndEmit(emit, farmId: _farmId, pondId: _pondId, generation: generation);
  }

  // ── WaterQualityFarmChanged ────────────────────────────────────────────

  /// Handles area changes; optional pond ID is navigation context only.
  ///
  /// Treats the change as a brand-new load for the new farmId/pondId
  /// (Requirement 8.9).
  ///
  /// Requirements: 8.9
  Future<void> _onFarmChanged(
    WaterQualityFarmChanged event,
    Emitter<WaterQualityState> emit,
  ) async {
    _farmId = event.farmId; _pondId = event.pondId;
    final generation = ++_generation;
    emit(const WaterQualityLoading());
    await _fetchAndEmit(emit, farmId: _farmId, pondId: _pondId, generation: generation);
  }

  // ── Shared fetch helper ────────────────────────────────────────────────

  /// Fetches current + historical readings and checks device status.
  Future<void> _fetchAndEmit(
    Emitter<WaterQualityState> emit, {
    required String farmId,
    String? pondId,
    required int generation,
  }) async {
    _inFlight = true;
    try {
      final result = await getCurrentReadings(
        // Row/pond is navigation context, never a measurement filter for RAS.
        GetCurrentReadingsParams(farmId: farmId),
      );
      if (!_current(generation,emit)) return;
      await result.fold(
        (failure) async {
          if (_current(generation,emit)) emit(WaterQualityError(
            message: failure.message, isOffline: failure is NetworkFailure));
        },
        (readings) async {
          final scoped = readings.where((r)=>
            (farmId=='default'||farmId.isEmpty||r.farmId==farmId)).toList();
          bool? deviceOnline;
          if (scoped.isNotEmpty && scoped.first.sensorId.isNotEmpty) {
            final statusResult = await repository.checkDeviceStatus(sensorId:scoped.first.sensorId);
            deviceOnline=statusResult.fold<bool?>((_)=>null,(v)=>v);
          }
          if (!_current(generation,emit)) return;
          emit(WaterQualityLoaded(readings:scoped,thresholds:_thresholds,
            farmId:farmId,pondId:pondId,isDeviceOffline:deviceOnline==false,
            deviceStatusKnown:deviceOnline!=null,lastRefreshedAt:DateTime.now()));
        },
      );
    } catch (_) {
      if (_current(generation,emit)) emit(const WaterQualityError(message:'Không tải được dữ liệu cảm biến.'));
    } finally {
      if (generation==_generation) _inFlight=false;
    }
  }
}
