import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/auth_models.dart';
import 'cloud_api_client.dart';

/// Một thông báo in-app do BE sinh ra (`be.Notifications`).
class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.isRead,
    this.alertId,
    this.createdAt,
  });

  final String id;
  final String title;
  final String body;
  final bool isRead;
  final String? alertId;
  final DateTime? createdAt;

  /// BE trả về cả camelCase và PascalCase tuỳ serializer — đọc cả hai.
  factory AppNotification.fromDto(Map<String, dynamic> m) {
    DateTime? parse(Object? raw) => raw == null ? null : DateTime.tryParse('$raw');
    String str(Object? raw) => raw?.toString() ?? '';
    return AppNotification(
      id: str(m['id'] ?? m['Id']),
      title: str(m['title'] ?? m['Title']),
      body: str(m['body'] ?? m['Body']),
      isRead: (m['isRead'] ?? m['IsRead']) == true,
      alertId: () {
        final v = str(m['alertId'] ?? m['AlertId']);
        return v.isEmpty ? null : v;
      }(),
      createdAt: parse(m['createdAt'] ?? m['CreatedAt']),
    );
  }
}

/// Notification Center phía Desktop: giữ danh sách + số chưa đọc, poll định kỳ.
class NotificationCenterService extends ChangeNotifier {
  NotificationCenterService({required AuthSession session, CloudApiClient? api})
      : _session = session,
        _api = api ?? CloudApiClient();

  AuthSession _session;
  final CloudApiClient _api;

  List<AppNotification> _items = const [];
  bool loading = false;
  String? error;
  Timer? _poll;

  List<AppNotification> get items => List.unmodifiable(_items);
  int get unreadCount => _items.where((n) => !n.isRead).length;

  void updateSession(AuthSession session) {
    _session = session;
    _items = const [];
    error = null;
  }

  void startPolling() {
    _poll?.cancel();
    _poll = Timer.periodic(const Duration(seconds: 30), (_) {
      unawaited(load(silent: true));
    });
  }

  void stopPolling() => _poll?.cancel();

  Future<void> load({bool silent = false}) async {
    if (!silent) {
      loading = true;
      notifyListeners();
    }
    try {
      final rows = await _api.fetchMyNotifications(_session.token);
      _items = rows.map(AppNotification.fromDto).toList()
        ..sort((a, b) => (b.createdAt ?? DateTime(0))
            .compareTo(a.createdAt ?? DateTime(0)));
      error = null;
    } on CloudApiException catch (e) {
      if (!silent) error = e.message;
    } catch (e) {
      if (!silent) error = '$e';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> markRead(AppNotification n) async {
    if (n.isRead) return;
    // Optimistic: đổi trạng thái ngay để badge tụt, lỗi thì load lại từ BE.
    _items = _items
        .map((e) => e.id == n.id
            ? AppNotification(
                id: e.id,
                title: e.title,
                body: e.body,
                isRead: true,
                alertId: e.alertId,
                createdAt: e.createdAt,
              )
            : e)
        .toList();
    notifyListeners();
    try {
      await _api.markNotificationRead(_session.token, n.id);
    } catch (_) {
      await load(silent: true);
    }
  }

  Future<void> markAllRead() async {
    if (unreadCount == 0) return;
    try {
      await _api.markAllNotificationsRead(_session.token);
      await load(silent: true);
    } catch (e) {
      error = '$e';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }
}
