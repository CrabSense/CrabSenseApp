import '../../domain/entities/notification_history_item.dart';

/// Data Transfer Object for [NotificationHistoryItem].
///
/// Handles serialization to/from a Hive-compatible [Map<String, dynamic>].
/// Manual serialization is used intentionally to avoid build_runner
/// for a simple, stable model.
///
/// Requirements: 14.6
class NotificationHistoryItemModel extends NotificationHistoryItem {
  const NotificationHistoryItemModel({
    required super.id,
    required super.title,
    required super.message,
    required super.category,
    required super.receivedAt,
    super.deepLink,
    super.isRead,
  });

  // ── Factory constructors ──────────────────────────────────────────────────

  /// Creates a model from a raw JSON [Map].
  factory NotificationHistoryItemModel.fromJson(Map<String, dynamic> json) =>
      NotificationHistoryItemModel(
        id: json['id'] as String,
        title: json['title'] as String,
        message: json['message'] as String,
        category: json['category'] as String,
        receivedAt: DateTime.fromMillisecondsSinceEpoch(json['receivedAt'] as int),
        deepLink: json['deepLink'] as String?,
        isRead: (json['isRead'] as bool?) ?? false,
      );

  /// Creates a model from a domain [NotificationHistoryItem] entity.
  factory NotificationHistoryItemModel.fromEntity(NotificationHistoryItem entity) =>
      NotificationHistoryItemModel(
        id: entity.id,
        title: entity.title,
        message: entity.message,
        category: entity.category,
        receivedAt: entity.receivedAt,
        deepLink: entity.deepLink,
        isRead: entity.isRead,
      );

  // ── Serialization ─────────────────────────────────────────────────────────

  /// Converts this model to a [Map] suitable for Hive storage.
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'message': message,
    'category': category,
    'receivedAt': receivedAt.millisecondsSinceEpoch,
    'deepLink': deepLink,
    'isRead': isRead,
  };

  /// Converts this model to a domain entity.
  NotificationHistoryItem toEntity() => NotificationHistoryItem(
    id: id,
    title: title,
    message: message,
    category: category,
    receivedAt: receivedAt,
    deepLink: deepLink,
    isRead: isRead,
  );
}
