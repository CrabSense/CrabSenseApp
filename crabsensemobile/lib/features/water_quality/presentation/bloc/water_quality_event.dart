import 'package:equatable/equatable.dart';

/// Base class for all water quality events.
///
/// Events trigger actions in [WaterQualityBloc]. Each event represents
/// an action the user or system wants to perform on the water quality screen.
///
/// Requirements: 8.1–8.10
abstract class WaterQualityEvent extends Equatable {
  const WaterQualityEvent();

  @override
  List<Object?> get props => [];
}

/// Event triggered to load water quality data for the first time.
///
/// This event:
/// - Emits [WaterQualityLoading] while fetching data
/// - Calls [GetCurrentReadingsUseCase] with the given farmId
/// - Checks device status on the first sensor found (Req 8.8)
/// - Falls back to cached data if offline (Req 8.10)
/// - Emits [WaterQualityLoaded] on success or [WaterQualityError] on failure
///
/// Requirements: 8.1, 8.8, 8.10
class WaterQualityLoadRequested extends WaterQualityEvent {
  const WaterQualityLoadRequested({required this.farmId, this.pondId});

  /// The farm to load water quality readings for.
  final String farmId;

  /// Optional specific pond within the farm.
  final String? pondId;

  @override
  List<Object?> get props => [farmId, pondId];
}

/// Event triggered for pull-to-refresh or auto-refresh every 30 seconds.
///
/// This event:
/// - Marks the current loaded state as refreshing (keeps data visible)
/// - Re-fetches current readings and device status
/// - Emits [WaterQualityLoaded] on success or [WaterQualityError] on failure
///
/// Requirements: 8.7
class WaterQualityRefreshRequested extends WaterQualityEvent {
  const WaterQualityRefreshRequested();
}

/// Event triggered when the selected farm or pond changes.
///
/// Treats the change as a new load for the given farmId/pondId.
///
/// Requirements: 8.9
class WaterQualityFarmChanged extends WaterQualityEvent {
  const WaterQualityFarmChanged({required this.farmId, this.pondId});

  /// The new farm to load water quality readings for.
  final String farmId;

  /// Optional specific pond within the new farm.
  final String? pondId;

  @override
  List<Object?> get props => [farmId, pondId];
}
