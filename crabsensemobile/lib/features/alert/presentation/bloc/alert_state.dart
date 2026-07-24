import 'package:equatable/equatable.dart';

import '../../domain/entities/alert.dart';
import '../../domain/entities/alert_enums.dart';

/// Holds the currently active filter values.
///
/// All fields are optional; null means "no filter for that dimension".
///
/// Requirements: 9.8
class AlertActiveFilters extends Equatable {
  const AlertActiveFilters({this.severity, this.type, this.status});

  final AlertSeverity? severity;
  final AlertType? type;
  final AlertStatus? status;

  /// Returns true when no filters are active.
  bool get isEmpty => severity == null && type == null && status == null;

  AlertActiveFilters copyWith({
    AlertSeverity? Function()? severity,
    AlertType? Function()? type,
    AlertStatus? Function()? status,
  }) => AlertActiveFilters(
    severity: severity != null ? severity() : this.severity,
    type: type != null ? type() : this.type,
    status: status != null ? status() : this.status,
  );

  @override
  List<Object?> get props => [severity, type, status];
}

// ── Base state ────────────────────────────────────────────────────────────────

/// Base class for all alert states.
///
/// States represent the current condition of the alert feature.
/// All states use [Equatable] for value equality.
///
/// Requirements: 9.1-9.10
abstract class AlertState extends Equatable {
  const AlertState();

  @override
  List<Object?> get props => [];
}

// ── Concrete states ───────────────────────────────────────────────────────────

/// Initial state before any load has been requested.
class AlertInitial extends AlertState {
  const AlertInitial();
}

/// State emitted while the initial alert list is being loaded.
///
/// The UI should show skeleton placeholders.
class AlertLoading extends AlertState {
  const AlertLoading();
}

/// State emitted when the alert list has been successfully loaded.
///
/// - [alerts]: filtered list sorted by [Alert.createdAt] descending (Req 9.4)
/// - [unreadCount]: total unread alerts for the navigation badge (Req 9.2)
/// - [activeFilters]: filters currently applied to the list (Req 9.8)
/// - [isRefreshing]: true while a pull-to-refresh is in flight
/// - [isOffline]: true when data is served from cache with no network
///
/// Requirements: 9.2, 9.4, 9.8, 9.10
class AlertLoaded extends AlertState {
  const AlertLoaded({
    required this.alerts,
    required this.unreadCount,
    required this.activeFilters,
    this.isRefreshing = false,
    this.isOffline = false,
  });

  /// Filtered + sorted alert list (newest first).
  final List<Alert> alerts;

  /// Total number of unread alerts across ALL filters (for badge).
  final int unreadCount;

  /// Currently active filter selection.
  final AlertActiveFilters activeFilters;

  /// True while a background refresh is in flight.
  final bool isRefreshing;

  /// True when data is coming from local cache (no network).
  final bool isOffline;

  AlertLoaded copyWith({
    List<Alert>? alerts,
    int? unreadCount,
    AlertActiveFilters? activeFilters,
    bool? isRefreshing,
    bool? isOffline,
  }) => AlertLoaded(
    alerts: alerts ?? this.alerts,
    unreadCount: unreadCount ?? this.unreadCount,
    activeFilters: activeFilters ?? this.activeFilters,
    isRefreshing: isRefreshing ?? this.isRefreshing,
    isOffline: isOffline ?? this.isOffline,
  );

  @override
  List<Object?> get props => [
    alerts,
    unreadCount,
    activeFilters,
    isRefreshing,
    isOffline,
  ];
}

/// State emitted when loading the alert list fails.
///
/// - [message]: human-readable error description.
/// - [isOffline]: true for connectivity failures.
///
/// Requirements: 9.10
class AlertError extends AlertState {
  const AlertError({required this.message, this.isOffline = false});

  /// User-facing error message.
  final String message;

  /// Whether the failure is a connectivity error.
  final bool isOffline;

  @override
  List<Object?> get props => [message, isOffline];
}

/// State emitted while an acknowledge or dismiss action is in progress.
///
/// Keeps the current list visible while the action is being processed,
/// and disables the buttons for the alert being acted upon.
///
/// Requirements: 9.7
class AlertActionInProgress extends AlertState {
  const AlertActionInProgress({
    required this.alerts,
    required this.unreadCount,
    required this.activeFilters,
    required this.processingAlertId,
  });

  /// The alert list visible while the action is in progress.
  final List<Alert> alerts;

  /// Current unread count.
  final int unreadCount;

  /// Active filters at the time the action was triggered.
  final AlertActiveFilters activeFilters;

  /// ID of the alert currently being acted upon.
  final String processingAlertId;

  @override
  List<Object?> get props => [
    alerts,
    unreadCount,
    activeFilters,
    processingAlertId,
  ];
}
