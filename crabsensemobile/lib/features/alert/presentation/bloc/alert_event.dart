import 'package:equatable/equatable.dart';

import '../../domain/entities/alert_enums.dart';
import 'alert_bloc.dart' show AlertBloc;

/// Base class for all alert events.
///
/// Events trigger actions in [AlertBloc]. Each event represents an
/// action the user or system wants to perform on the alert list.
///
/// Requirements: 9.1-9.10
abstract class AlertEvent extends Equatable {
  const AlertEvent();

  @override
  List<Object?> get props => [];
}

/// Event triggered to load the alert list for the first time.
///
/// Falls back to cached data if network is unavailable (Req 9.10).
///
/// Requirements: 9.4, 9.8, 9.9, 9.10
class AlertLoadRequested extends AlertEvent {
  const AlertLoadRequested();
}

/// Event triggered when the user performs pull-to-refresh.
///
/// Forces a fresh fetch from the API, bypassing cache.
///
/// Requirements: 9.4, 9.10
class AlertRefreshRequested extends AlertEvent {
  const AlertRefreshRequested();
}

/// Event triggered when the user changes filter selection.
///
/// Any of the three filters may be null (meaning "show all").
///
/// Requirements: 9.8
class AlertFiltersChanged extends AlertEvent {
  const AlertFiltersChanged({this.severity, this.type, this.status});

  /// Null means show all severities.
  final AlertSeverity? severity;

  /// Null means show all types.
  final AlertType? type;

  /// Null means show all statuses.
  final AlertStatus? status;

  @override
  List<Object?> get props => [severity, type, status];
}

/// Event triggered when the user taps the Acknowledge button on an alert.
///
/// Requirements: 9.6, 9.7, 9.10
class AlertAcknowledgeRequested extends AlertEvent {
  const AlertAcknowledgeRequested({
    required this.alertId,
    required this.acknowledgedBy,
  });

  /// ID of the alert to acknowledge.
  final String alertId;

  /// ID of the user performing the acknowledgement.
  final String acknowledgedBy;

  @override
  List<Object?> get props => [alertId, acknowledgedBy];
}

/// Event triggered when the user taps the Dismiss button on an alert.
///
/// Requirements: 9.6, 9.10
class AlertDismissRequested extends AlertEvent {
  const AlertDismissRequested({required this.alertId});

  /// ID of the alert to dismiss.
  final String alertId;

  @override
  List<Object?> get props => [alertId];
}

/// Internal event fired by the live unread-count stream.
///
/// Dispatched automatically inside [AlertBloc] when the local database
/// emits a new count. Not intended to be dispatched from outside the BLoC.
///
/// Requirements: 9.2
class AlertUnreadCountUpdated extends AlertEvent {
  const AlertUnreadCountUpdated(this.count);

  /// The new unread alert count.
  final int count;

  @override
  List<Object?> get props => [count];
}
