import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart' show NetworkFailure;
import '../../domain/entities/dashboard_summary.dart';

/// Base class for all dashboard states.
///
/// States represent the current condition of the dashboard feature.
/// All states use [Equatable] for value equality.
///
/// Requirements: 2.1–2.10
abstract class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any load has been requested.
///
/// The dashboard is freshly created; no data has been fetched yet.
class DashboardInitial extends DashboardState {
  const DashboardInitial();
}

/// State emitted while the initial dashboard data is being loaded.
///
/// The UI should show skeleton / shimmer placeholders (Requirement 2.10).
class DashboardLoading extends DashboardState {
  const DashboardLoading();
}

/// State emitted when the dashboard data has been successfully loaded.
///
/// Contains a [DashboardSummary] with all metrics, alerts, video tasks,
/// water quality statuses, and harvest data.
///
/// When [summary.isFromCache] is true the UI should display an offline
/// banner (Requirement 2.6). The [summary.fetchedAt] timestamp drives
/// the 60-second auto-refresh timer (Requirement 2.7).
///
/// Requirements: 2.1–2.6, 2.8
class DashboardLoaded extends DashboardState {
  const DashboardLoaded({required this.summary, this.isRefreshing = false});

  /// The aggregated dashboard data to display.
  final DashboardSummary summary;

  /// True while a background refresh is in flight.
  ///
  /// Allows the UI to keep showing the previous data while the pull-to-
  /// refresh indicator is visible.
  final bool isRefreshing;

  /// Returns a copy of this state with selected fields replaced.
  DashboardLoaded copyWith({DashboardSummary? summary, bool? isRefreshing}) => DashboardLoaded(
    summary: summary ?? this.summary,
    isRefreshing: isRefreshing ?? this.isRefreshing,
  );

  @override
  List<Object?> get props => [summary, isRefreshing];
}

/// State emitted when loading the dashboard data fails.
///
/// - [message]: human-readable error description shown to the user.
/// - [isOffline]: true when the failure is due to no internet connectivity
///   (maps from [NetworkFailure]). The UI shows a more specific offline
///   message in this case.
///
/// Requirements: 2.9
class DashboardError extends DashboardState {
  const DashboardError({required this.message, this.isOffline = false});

  /// User-facing error message.
  final String message;

  /// Whether the failure is a connectivity error vs a server/cache error.
  final bool isOffline;

  @override
  List<Object?> get props => [message, isOffline];
}
