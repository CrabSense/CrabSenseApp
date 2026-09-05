import 'package:flutter/foundation.dart';

import '../models/auth_models.dart';
import '../models/farm_alert.dart';
import 'cloud_api_client.dart';

class AlertService extends ChangeNotifier {
  AlertService({required AuthSession session, CloudApiClient? api})
      : _session = session,
        _api = api ?? CloudApiClient();

  AuthSession _session;
  final CloudApiClient _api;

  List<FarmAlert> _alerts = [];
  List<AlertHistoryRow> _history = [];
  bool loading = false;
  String? error;

  String _filter = 'Tất cả';
  String _search = '';
  String? _selectedId;

  void updateSession(AuthSession session) {
    _session = session;
    _alerts = [];
    _history = [];
    _selectedId = null;
  }

  AlertKpi get kpi {
    final open = _alerts.where((a) => a.isOpen).toList();
    return AlertKpi(
      active: open.length,
      critical: open.where((a) => a.level == AlertLevel.critical).length,
      warning: open.where((a) => a.level == AlertLevel.warning).length,
      info: open.where((a) => a.level == AlertLevel.info).length,
      resolvedToday: _alerts
          .where((a) => a.status == AlertWorkflowStatus.resolved)
          .length,
      avgResponseMinutes: 0,
    );
  }

  FarmAlert get spotlight =>
      selectedAlert ??
      (_alerts.isNotEmpty
          ? _alerts.first
          : const FarmAlert(
              id: '',
              time: '',
              level: AlertLevel.info,
              type: AlertTypeCategory.other,
              title: 'Không có cảnh báo',
              location: '',
              device: '',
              status: AlertWorkflowStatus.resolved,
              handler: '',
              currentValue: '—',
              threshold: '—',
              recommendations: [],
              suggestedActions: [],
            ));

  List<AlertHistoryRow> get history => List.unmodifiable(_history);
  List<AlertFrequencyPoint> get frequency => const [];
  List<NotificationChannelConfig> get channelRules => const [];
  String get aiInsight => error ?? 'Cảnh báo lấy từ CrabSenseBE.';
  List<String> get aiRecommendations => const [];
  String get filter => _filter;

  FarmAlert? get selectedAlert {
    if (_selectedId == null) return _alerts.isEmpty ? null : _alerts.first;
    try {
      return _alerts.firstWhere((a) => a.id == _selectedId);
    } catch (_) {
      return _alerts.isNotEmpty ? _alerts.first : null;
    }
  }

  List<FarmAlert> get filteredAlerts {
    var list = _alerts;
    switch (_filter) {
      case 'Info':
        list = list.where((a) => a.level == AlertLevel.info).toList();
      case 'Warning':
        list = list.where((a) => a.level == AlertLevel.warning).toList();
      case 'Critical':
        list = list.where((a) => a.level == AlertLevel.critical).toList();
      case 'Chưa xử lý':
        list = list.where((a) => a.isOpen).toList();
      case 'Đã xử lý':
        list = list
            .where((a) => a.status == AlertWorkflowStatus.resolved)
            .toList();
    }
    if (_search.trim().isNotEmpty) {
      final q = _search.toLowerCase();
      list = list
          .where(
            (a) =>
                a.title.toLowerCase().contains(q) ||
                a.location.toLowerCase().contains(q) ||
                a.device.toLowerCase().contains(q),
          )
          .toList();
    }
    return list;
  }

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final farmId = _session.selectedFarm.id;
      final active = await _api.fetchAlerts(
        _session.token,
        farmingAreaId: farmId,
        activeOnly: false,
      );
      _alerts = active.map(_fromDto).toList();
      if (_alerts.isNotEmpty) {
        _selectedId ??= _alerts.first.id;
      }
      try {
        final hist = await _api.fetchAlertHistory(
          _session.token,
          farmingAreaId: farmId,
        );
        _history = hist.map(_historyFromDto).toList();
      } catch (_) {}
      error = null;
    } on CloudApiException catch (e) {
      error = e.message;
    } catch (e) {
      error = '$e';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void setSearch(String v) {
    _search = v;
    notifyListeners();
  }

  void setFilter(String v) {
    _filter = v;
    notifyListeners();
  }

  void selectAlert(String id) {
    _selectedId = id;
    notifyListeners();
  }

  Future<void> markInProgress(String id, {String handler = 'Admin'}) async {
    try {
      await _api.acknowledgeAlert(_session.token, id);
      await load();
    } catch (e) {
      error = '$e';
      notifyListeners();
    }
  }

  Future<void> markResolved(String id, {String handler = 'Admin'}) async {
    try {
      await _api.resolveAlert(_session.token, id);
      await load();
    } catch (e) {
      error = '$e';
      notifyListeners();
    }
  }

  void markIgnored(String id) {
    markResolved(id);
  }

  static FarmAlert _fromDto(Map<String, dynamic> m) {
    final severity = (m['severity'] ?? '').toString().toLowerCase();
    final status = (m['status'] ?? '').toString().toLowerCase();
    final created = DateTime.tryParse((m['createdAt'] ?? '').toString());
    final min = m['thresholdMin'];
    final max = m['thresholdMax'];
    return FarmAlert(
      id: (m['id'] ?? '').toString(),
      time: created == null
          ? ''
          : '${created.toLocal().hour.toString().padLeft(2, '0')}:${created.toLocal().minute.toString().padLeft(2, '0')}',
      level: switch (severity) {
        'critical' || 'danger' || 'error' => AlertLevel.critical,
        'info' || 'low' => AlertLevel.info,
        _ => AlertLevel.warning,
      },
      type: AlertTypeCategory.other,
      title: (m['title'] ?? m['message'] ?? '').toString(),
      location: (m['locationLabel'] ?? m['farmingAreaName'] ?? '').toString(),
      device: (m['sensorCode'] ?? m['sensorType'] ?? '').toString(),
      status: switch (status) {
        'acknowledged' || 'notified' => AlertWorkflowStatus.notified,
        'resolved' || 'closed' => AlertWorkflowStatus.resolved,
        _ => AlertWorkflowStatus.newAlert,
      },
      handler: '',
      currentValue: '${m['triggerValue'] ?? '—'}',
      threshold: (min == null && max == null) ? '—' : '$min – $max',
      recommendations: [
        if ((m['aiRecommendation'] ?? '').toString().isNotEmpty)
          m['aiRecommendation'].toString(),
      ],
      suggestedActions: const [],
      detectedAt: created?.toLocal().toString() ?? '',
      note: (m['priorityExplanation'] ?? '').toString(),
    );
  }

  static AlertHistoryRow _historyFromDto(Map<String, dynamic> m) {
    final created = DateTime.tryParse((m['createdAt'] ?? '').toString());
    final severity = (m['severity'] ?? '').toString().toLowerCase();
    return AlertHistoryRow(
      date: created?.toLocal().toString() ?? '',
      typeLabel: (m['title'] ?? m['category'] ?? '').toString(),
      level: switch (severity) {
        'critical' || 'danger' => AlertLevel.critical,
        'info' => AlertLevel.info,
        _ => AlertLevel.warning,
      },
      location: (m['locationLabel'] ?? '').toString(),
      responseTime: '',
      result: (m['status'] ?? '').toString(),
    );
  }
}
