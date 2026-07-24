import 'package:hive/hive.dart';

import '../models/notification_history_item_model.dart';

/// Hive box name for notification history storage.
///
/// This box MUST be opened in `main.dart` before [init()] is called:
/// ```dart
/// await Hive.openBox<Map>(kNotifHistoryBoxName);
/// ```
const String kNotifHistoryBoxName = 'notification_history';

/// Maximum number of items to keep in local storage.
///
/// When the limit is reached the oldest item is evicted to make room.
const int _kMaxItems = 200;

/// Retention period — items older than this are filtered out.
const Duration _kRetentionPeriod = Duration(days: 30);

/// Abstract contract for the local notification history data source.
abstract class NotificationHistoryLocalDataSource {
  /// Returns all stored items, newest first, filtered to [_kRetentionPeriod].
  Future<List<NotificationHistoryItemModel>> getHistory();

  /// Persists [item] to local storage, evicting the oldest entry when the
  /// [_kMaxItems] cap is reached.
  Future<void> addItem(NotificationHistoryItemModel item);

  /// Removes all stored items.
  Future<void> clearAll();

  /// Marks every stored item as read.
  Future<void> markAllRead();
}

/// Hive-backed implementation of [NotificationHistoryLocalDataSource].
///
/// Items are stored as [Map<String, dynamic>] keyed by [item.id].
class NotificationHistoryLocalDataSourceImpl implements NotificationHistoryLocalDataSource {
  NotificationHistoryLocalDataSourceImpl({required this._box});

  final Box _box;

  // ── NotificationHistoryLocalDataSource ───────────────────────────────────

  @override
  Future<List<NotificationHistoryItemModel>> getHistory() async {
    final cutoff = DateTime.now().subtract(_kRetentionPeriod);

    final items =
        _box.values
            .whereType<Map>()
            .map((raw) => NotificationHistoryItemModel.fromJson(Map<String, dynamic>.from(raw)))
            .where((item) => item.receivedAt.isAfter(cutoff))
            .toList()
          ..sort((a, b) => b.receivedAt.compareTo(a.receivedAt));

    return items;
  }

  @override
  Future<void> addItem(NotificationHistoryItemModel item) async {
    // Evict oldest entry when cap is reached.
    if (_box.length >= _kMaxItems) {
      await _evictOldest();
    }
    await _box.put(item.id, item.toJson());
  }

  @override
  Future<void> clearAll() async {
    await _box.clear();
  }

  @override
  Future<void> markAllRead() async {
    final updates = <String, Map<String, dynamic>>{};

    for (final key in _box.keys) {
      final raw = _box.get(key);
      if (raw is Map) {
        final json = Map<String, dynamic>.from(raw);
        if (json['isRead'] != true) {
          json['isRead'] = true;
          updates[key as String] = json;
        }
      }
    }

    if (updates.isNotEmpty) {
      await _box.putAll(updates);
    }
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  /// Removes the single oldest item from the box.
  Future<void> _evictOldest() async {
    NotificationHistoryItemModel? oldest;
    String? oldestKey;

    for (final key in _box.keys) {
      final raw = _box.get(key);
      if (raw is Map) {
        final model = NotificationHistoryItemModel.fromJson(Map<String, dynamic>.from(raw));
        if (oldest == null || model.receivedAt.isBefore(oldest.receivedAt)) {
          oldest = model;
          oldestKey = key as String;
        }
      }
    }

    if (oldestKey != null) {
      await _box.delete(oldestKey);
    }
  }
}
