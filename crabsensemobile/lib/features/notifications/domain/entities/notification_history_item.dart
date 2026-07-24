import 'package:equatable/equatable.dart';

import '../../../../shared/services/notification_service.dart' show NotificationCategory;

/// Domain entity representing a single notification in the history center.
///
/// Requirements: 14.6
class NotificationHistoryItem extends Equatable {
  const NotificationHistoryItem({
    required this.id,
    required this.title,
    required this.message,
    required this.category,
    required this.receivedAt,
    this.deepLink,
    this.isRead = false,
  });

  /// Unique identifier (FCM messageId or local UUID).
  final String id;

  /// Short notification title.
  final String title;

  /// Full notification body text.
  final String message;

  /// Notification category — one of the [NotificationCategory] constants.
  final String category;

  /// When the notification was received by the device.
  final DateTime receivedAt;

  /// Optional deep-link path for navigation on tap.
  final String? deepLink;

  /// Whether the user has tapped / viewed this notification.
  final bool isRead;

  /// Returns a copy of this item with the given fields replaced.
  NotificationHistoryItem copyWith({
    String? id,
    String? title,
    String? message,
    String? category,
    DateTime? receivedAt,
    String? Function()? deepLink,
    bool? isRead,
  }) => NotificationHistoryItem(
    id: id ?? this.id,
    title: title ?? this.title,
    message: message ?? this.message,
    category: category ?? this.category,
    receivedAt: receivedAt ?? this.receivedAt,
    deepLink: deepLink != null ? deepLink() : this.deepLink,
    isRead: isRead ?? this.isRead,
  );

  @override
  List<Object?> get props => [id, title, message, category, receivedAt, deepLink, isRead];
}
