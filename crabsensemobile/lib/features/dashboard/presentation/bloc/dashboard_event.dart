import 'package:equatable/equatable.dart';

import '../../domain/usecases/get_dashboard_summary_usecase.dart' show GetDashboardSummaryUseCase;

/// Base class for all dashboard events.
///
/// Events trigger actions in [DashboardBloc]. Each event represents an action
/// the user or system wants to perform on the dashboard.
///
/// Requirements: 2.1–2.10
abstract class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object?> get props => [];
}

/// Event triggered to load the dashboard summary for the first time.
///
/// This event:
/// - Emits [DashboardLoading] while fetching data
/// - Calls [GetDashboardSummaryUseCase] with forceRefresh: false
/// - Falls back to cached data if network is unavailable (Req 2.6)
/// - Emits [DashboardLoaded] on success or [DashboardError] on failure
///
/// Requirements: 2.1, 2.6, 2.10
class DashboardLoadRequested extends DashboardEvent {
  const DashboardLoadRequested();
}

/// Event triggered when the user performs pull-to-refresh.
///
/// This event:
/// - Calls [GetDashboardSummaryUseCase] with forceRefresh: true
/// - Bypasses cache and forces a fresh fetch from the API
/// - Emits [DashboardLoaded] on success or [DashboardError] on failure
/// - Does NOT emit [DashboardLoading] (refresh indicator shown by UI)
///
/// Requirements: 2.7
class DashboardRefreshRequested extends DashboardEvent {
  const DashboardRefreshRequested();
}
