import 'package:equatable/equatable.dart';

import '../../domain/entities/notification_history_item.dart';

/// Base class for all notification history events.
abstract class NotificationHistoryEvent extends Equatable {
  const NotificationHistoryEvent();

  @override
  List<Object?> get props => [];
}

/// Triggers initial load of the notification history.
class NotificationHistoryLoadRequested extends NotificationHistoryEvent {
  const NotificationHistoryLoadRequested();
}

/// Adds a newly received notification item to the history.
///
/// Dispatched by the notification service whenever a new FCM message
/// arrives — keeps the in-memory state up to date without a full reload.
class NotificationHistoryItemAdded extends NotificationHistoryEvent {
  const NotificationHistoryItemAdded(this.item);

  final NotificationHistoryItem item;

  @override
  List<Object?> get props => [item];
}

/// Clears all items from the notification history.
class NotificationHistoryClearRequested extends NotificationHistoryEvent {
  const NotificationHistoryClearRequested();
}
