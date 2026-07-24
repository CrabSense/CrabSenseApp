import 'dart:collection';

import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/notification_history_item.dart';

/// Base class for all notification history states.
abstract class NotificationHistoryState extends Equatable {
  const NotificationHistoryState();

  @override
  List<Object?> get props => [];
}

/// Initial state — no load has been requested yet.
class NotificationHistoryInitial extends NotificationHistoryState {
  const NotificationHistoryInitial();
}

/// State emitted while items are being loaded.
///
/// The UI shows skeleton placeholders.
class NotificationHistoryLoading extends NotificationHistoryState {
  const NotificationHistoryLoading();
}

/// State emitted when items have been successfully loaded.
///
/// Exposes the flat [items] list (newest first) and a [groupedByDate]
/// map keyed by a human-readable date label.
///
/// Requirements: 14.6
class NotificationHistoryLoaded extends NotificationHistoryState {
  const NotificationHistoryLoaded({required this.items});

  /// All history items sorted by [receivedAt] descending (newest first).
  final List<NotificationHistoryItem> items;

  /// Returns items grouped under human-readable date headers.
  ///
  /// Keys:
  ///   - "Today" — items received today
  ///   - "Yesterday" — items received yesterday
  ///   - Formatted date, e.g. "Dec 12" — older items
  ///
  /// A [LinkedHashMap] is used to preserve insertion order so the newest
  /// group always appears first in the UI.
  Map<String, List<NotificationHistoryItem>> get groupedByDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final result = <String, List<NotificationHistoryItem>>{};

    for (final item in items) {
      final itemDate = DateTime(item.receivedAt.year, item.receivedAt.month, item.receivedAt.day);

      final String label;
      if (itemDate == today) {
        label = 'Today';
      } else if (itemDate == yesterday) {
        label = 'Yesterday';
      } else {
        label = DateFormat('MMM d').format(item.receivedAt);
      }

      result.putIfAbsent(label, () => []).add(item);
    }

    return result;
  }

  /// True when there are no items.
  bool get isEmpty => items.isEmpty;

  NotificationHistoryLoaded copyWith({List<NotificationHistoryItem>? items}) =>
      NotificationHistoryLoaded(items: items ?? this.items);

  @override
  List<Object?> get props => [items];
}

/// State emitted when loading fails.
class NotificationHistoryError extends NotificationHistoryState {
  const NotificationHistoryError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}
