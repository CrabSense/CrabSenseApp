import 'dart:async';

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
  String? detailError;

  String _search = '';
  String? _severity;
  String? _status;
  String? _kind;
  String? _area;
  String? _device;
  String? _range; // 24h, 7d, 30d
  String _sort = 'priority';
  String? _selectedId;
  final Set<String> _checked = {};
  int page = 1;
  int pageSize = 50;
  int _newCount = 0;
  bool soundOn = true;
  DateTime? muteUntil;
  Timer? _poll;

  void updateSession(AuthSession session) {
    _session = session;
    _alerts = [];
    _history = [];
    _selectedId = null;
    _checked.clear();
  }

  String get search => _search;
  String? get severityFilter => _severity;
  String? get statusFilter => _status;
  String? get kindFilter => _kind;
  String? get areaFilter => _area;
  String? get deviceFilter => _device;
  String? get rangeFilter => _range;
  String get sort => _sort;
  int get newCount => _newCount;
  Set<String> get checked => _checked;
  bool get isMuted =>
      !soundOn || (muteUntil != null && DateTime.now().isBefore(muteUntil!));

  List<FarmAlert> get alerts => List.unmodifiable(_alerts);
  List<AlertHistoryRow> get history => List.unmodifiable(_history);

  List<String> get areaOptions {
    final set = <String>{};
    for (final a in _alerts) {
      if (a.areaLabel.isNotEmpty) set.add(a.areaLabel);
    }
    return set.toList()..sort();
  }

  List<String> get deviceOptions {
    final set = <String>{};
    for (final a in _alerts) {
      if (a.deviceCode.isNotEmpty) set.add(a.deviceCode);
      if (a.device.isNotEmpty) set.add(a.device);
    }
    return set.toList()..sort();
  }

  AlertKpi get kpi {
    final open = _alerts.where((a) => a.isOpen).toList();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yday = today.subtract(const Duration(days: 1));
    int createdOn(DateTime day, bool Function(FarmAlert) pred) => _alerts
        .where((a) =>
            pred(a) &&
            a.createdAt != null &&
            a.createdAt!.toLocal().year == day.year &&
            a.createdAt!.toLocal().month == day.month &&
            a.createdAt!.toLocal().day == day.day)
        .length;

    final acked = _alerts.where((a) =>
        a.status == AlertWorkflowStatus.notified ||
        a.status == AlertWorkflowStatus.inProgress);
    final resolvedToday = _alerts.where((a) =>
        (a.status == AlertWorkflowStatus.resolved ||
            a.status == AlertWorkflowStatus.falseAlarm) &&
        a.resolvedAt != null &&
        a.resolvedAt!.toLocal().year == today.year &&
        a.resolvedAt!.toLocal().month == today.month &&
        a.resolvedAt!.toLocal().day == today.day);

    final responses = _alerts
        .where((a) => a.createdAt != null && a.acknowledgedAt != null)
        .map((a) => a.acknowledgedAt!.difference(a.createdAt!).inMinutes)
        .where((m) => m >= 0)
        .toList();

    return AlertKpi(
      active: open.length,
      critical: open.where((a) => a.level == AlertLevel.critical).length,
      warning: open.where((a) => a.level == AlertLevel.warning).length,
      info: open.where((a) => a.level == AlertLevel.info).length,
      acknowledged: acked.length,
      resolvedToday: resolvedToday.length,
      avgResponseMinutes: responses.isEmpty
          ? null
          : (responses.reduce((a, b) => a + b) / responses.length).round(),
      activeDelta: createdOn(today, (a) => a.isOpen) -
          createdOn(yday, (a) => a.isOpen),
      criticalDelta: createdOn(today, (a) => a.level == AlertLevel.critical) -
          createdOn(yday, (a) => a.level == AlertLevel.critical),
      warningDelta: createdOn(today, (a) => a.level == AlertLevel.warning) -
          createdOn(yday, (a) => a.level == AlertLevel.warning),
      acknowledgedDelta: createdOn(
            today,
            (a) =>
                a.status == AlertWorkflowStatus.notified ||
                a.status == AlertWorkflowStatus.inProgress,
          ) -
          createdOn(
            yday,
            (a) =>
                a.status == AlertWorkflowStatus.notified ||
                a.status == AlertWorkflowStatus.inProgress,
          ),
      resolvedDelta: resolvedToday.length -
          _alerts
              .where((a) =>
                  (a.status == AlertWorkflowStatus.resolved ||
                      a.status == AlertWorkflowStatus.falseAlarm) &&
                  a.resolvedAt != null &&
                  a.resolvedAt!.toLocal().year == yday.year &&
                  a.resolvedAt!.toLocal().month == yday.month &&
                  a.resolvedAt!.toLocal().day == yday.day)
              .length,
    );
  }

  FarmAlert? get selectedAlert {
    if (_alerts.isEmpty) return null;
    if (_selectedId == null) return _alerts.first;
    for (final a in _alerts) {
      if (a.id == _selectedId) return a;
    }
    return _alerts.first;
  }

  List<FarmAlert> get filteredAlerts {
    var list = List<FarmAlert>.from(_alerts);
    if (_severity != null) {
      list = list.where((a) => a.level.name == _severity).toList();
    }
    if (_status != null) {
      list = list.where((a) => a.status.name == _status).toList();
    }
    if (_kind != null) {
      list = list.where((a) => a.kind.name == _kind).toList();
    }
    if (_area != null) {
      list = list.where((a) => a.areaLabel == _area).toList();
    }
    if (_device != null) {
      list = list
          .where((a) => a.deviceCode == _device || a.device == _device)
          .toList();
    }
    if (_range != null) {
      final hours = switch (_range) {
        '24h' => 24,
        '7d' => 24 * 7,
        '30d' => 24 * 30,
        _ => 24 * 365,
      };
      final cut = DateTime.now().subtract(Duration(hours: hours));
      list = list
          .where((a) => a.createdAt == null || a.createdAt!.isAfter(cut))
          .toList();
    }
    if (_search.trim().isNotEmpty) {
      final q = _search.toLowerCase();
      list = list.where((a) {
        final hay =
            '${a.title} ${a.description} ${a.device} ${a.deviceCode} ${a.location} ${a.areaLabel} ${a.areaCode} ${a.displayCode} ${a.sourceLabel} ${a.kind.label}'
                .toLowerCase();
        return hay.contains(q);
      }).toList();
    }
    list.sort((a, b) {
      switch (_sort) {
        case 'oldest':
          return (a.createdAt ?? DateTime(0))
              .compareTo(b.createdAt ?? DateTime(0));
        case 'longest':
          return (b.openDuration?.inSeconds ?? 0)
              .compareTo(a.openDuration?.inSeconds ?? 0);
        case 'status':
          return a.status.index.compareTo(b.status.index);
        case 'severity':
          return b.level.index.compareTo(a.level.index);
        default:
          final sev = b.level.index.compareTo(a.level.index);
          if (sev != 0) return sev;
          return (b.createdAt ?? DateTime(0))
              .compareTo(a.createdAt ?? DateTime(0));
      }
    });
    return list;
  }

  List<FarmAlert> get pagedAlerts {
    final all = filteredAlerts;
    final start = ((page - 1) * pageSize).clamp(0, all.length);
    final end = (start + pageSize).clamp(0, all.length);
    return all.sublist(start, end);
  }

  int get filteredCount => filteredAlerts.length;

  FarmAlert get spotlight =>
      selectedAlert ??
      const FarmAlert(
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
      );

  List<AlertFrequencyPoint> get frequency => const [];
  List<NotificationChannelConfig> get channelRules => const [];
  String get aiInsight => error ?? '';
  List<String> get aiRecommendations => const [];
  String get filter => _severity ?? 'Tất cả';

  void startPolling() {
    _poll?.cancel();
    _poll = Timer.periodic(const Duration(seconds: 20), (_) {
      unawaited(load(silent: true));
    });
  }

  void stopPolling() => _poll?.cancel();

  Future<void> load({bool silent = false}) async {
    if (!silent) {
      loading = true;
      error = null;
      notifyListeners();
    }
    try {
      final farmId = _session.selectedFarm.id;
      final active = await _api.fetchAlerts(
        _session.token,
        farmingAreaId: farmId,
        activeOnly: false,
      );
      final mapped = active.map(_fromDto).toList();
      final grouped = _groupIncidents(mapped);
      if (silent && grouped.length > _alerts.length) {
        _newCount += grouped.length - _alerts.length;
      }
      _alerts = grouped;
      if (_alerts.isNotEmpty) _selectedId ??= _alerts.first.id;
      try {
        final hist = await _api.fetchAlertHistory(
          _session.token,
          farmingAreaId: farmId,
        );
        _history = hist.map(_historyFromDto).toList();
      } catch (_) {}
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

  void showNew() {
    _newCount = 0;
    notifyListeners();
  }

  void setSearch(String v) {
    _search = v;
    page = 1;
    notifyListeners();
  }

  void setFilter(String v) {
    _severity = switch (v) {
      'Critical' || 'critical' => 'critical',
      'Warning' || 'warning' => 'warning',
      'Info' || 'info' => 'info',
      _ => null,
    };
    if (v == 'Chưa xử lý') _status = 'newAlert';
    if (v == 'Đã xử lý') _status = 'resolved';
    page = 1;
    notifyListeners();
  }

  void setSeverity(String? v) {
    _severity = v;
    page = 1;
    notifyListeners();
  }

  void setStatus(String? v) {
    _status = v;
    page = 1;
    notifyListeners();
  }

  void setKind(String? v) {
    _kind = v;
    page = 1;
    notifyListeners();
  }

  void setArea(String? v) {
    _area = v;
    page = 1;
    notifyListeners();
  }

  void setDevice(String? v) {
    _device = v;
    page = 1;
    notifyListeners();
  }

  void setRange(String? v) {
    _range = v;
    page = 1;
    notifyListeners();
  }

  void setSort(String v) {
    _sort = v;
    notifyListeners();
  }

  void clearFilters() {
    _search = '';
    _severity = null;
    _status = null;
    _kind = null;
    _area = null;
    _device = null;
    _range = null;
    page = 1;
    notifyListeners();
  }

  bool get hasFilters =>
      _search.isNotEmpty ||
      _severity != null ||
      _status != null ||
      _kind != null ||
      _area != null ||
      _device != null ||
      _range != null;

  void selectAlert(String id) {
    _selectedId = id;
    detailError = null;
    notifyListeners();
  }

  void toggleCheck(String id) {
    if (_checked.contains(id)) {
      _checked.remove(id);
    } else {
      _checked.add(id);
    }
    notifyListeners();
  }

  void toggleCheckAll(Iterable<String> ids) {
    final allSelected = ids.every(_checked.contains);
    if (allSelected) {
      _checked.removeAll(ids);
    } else {
      _checked.addAll(ids);
    }
    notifyListeners();
  }

  void toggleSound(bool on) {
    soundOn = on;
    if (on) muteUntil = null;
    notifyListeners();
  }

  void muteFor(Duration d) {
    soundOn = false;
    muteUntil = d.inDays > 30 ? null : DateTime.now().add(d);
    notifyListeners();
  }

  void setPage(int p) {
    page = p;
    notifyListeners();
  }

  void setPageSize(int n) {
    pageSize = n;
    page = 1;
    notifyListeners();
  }

  Future<void> markInProgress(String id, {String handler = 'Admin'}) async {
    try {
      await _api.startAlertProcessing(
        _session.token,
        id,
        userId: _session.user.id,
      );
      await load(silent: true);
    } catch (e) {
      error = '$e';
      notifyListeners();
    }
  }

  Future<bool> acknowledge(String id) async {
    try {
      await _api.acknowledgeAlert(
        _session.token,
        id,
        userId: _session.user.id,
      );
      await load(silent: true);
      return true;
    } catch (e) {
      error = '$e';
      notifyListeners();
      return false;
    }
  }

  Future<void> acknowledgeChecked() async {
    for (final id in _checked.toList()) {
      await acknowledge(id);
    }
    _checked.clear();
  }

  Future<void> processChecked() async {
    for (final id in _checked.toList()) {
      await markInProgress(id);
    }
    _checked.clear();
  }

  Future<void> markResolved(String id, {String handler = 'Admin'}) async {
    await resolve(id);
  }

  Future<bool> resolve(
    String id, {
    String? reason,
    String? action,
    String? note,
    bool recovered = false,
  }) async {
    try {
      await _api.resolveAlert(
        _session.token,
        id,
        reason: reason,
        action: action,
        note: note,
        recovered: recovered,
        userId: _session.user.id,
      );
      await load(silent: true);
      return true;
    } catch (e) {
      error = '$e';
      notifyListeners();
      return false;
    }
  }

  void markIgnored(String id) {
    markResolved(id);
  }

  static List<FarmAlert> _groupIncidents(List<FarmAlert> raw) {
    final connection = raw.where((a) =>
        a.kind == AlertKind.controller &&
        a.title.toLowerCase().contains('mất kết nối'));
    final byDevice = <String, List<FarmAlert>>{};
    for (final a in raw) {
      if (a.kind == AlertKind.sensor &&
          a.title.toLowerCase().contains('mất kết nối')) {
        final key = a.areaLabel;
        byDevice.putIfAbsent(key, () => []).add(a);
      }
    }
    if (connection.isEmpty) return raw;
    final hide = <String>{};
    final out = <FarmAlert>[];
    for (final c in raw) {
      if (hide.contains(c.id)) continue;
      if (c.kind == AlertKind.controller &&
          c.title.toLowerCase().contains('mất kết nối')) {
        final sensors = byDevice[c.areaLabel] ?? const <FarmAlert>[];
        for (final s in sensors) {
          hide.add(s.id);
        }
        out.add(c.copyWith(
          affected: sensors
              .map((s) => s.device.isEmpty ? s.title : s.device)
              .toList(),
          occurrenceCount:
              c.occurrenceCount > 1 ? c.occurrenceCount : 1 + sensors.length,
        ));
      } else {
        out.add(c);
      }
    }
    return out;
  }

  static FarmAlert _fromDto(Map<String, dynamic> m) {
    final severity = (m['severity'] ?? '').toString().toLowerCase();
    final status = (m['status'] ?? '').toString().toLowerCase();
    final created = DateTime.tryParse((m['createdAt'] ?? m['CreatedAt'] ?? '').toString());
    final acked = DateTime.tryParse(
        (m['acknowledgedAt'] ?? m['AcknowledgedAt'] ?? '').toString());
    final resolved = DateTime.tryParse(
        (m['resolvedAt'] ?? m['ResolvedAt'] ?? '').toString());
    final min = m['thresholdMin'] ?? m['ThresholdMin'];
    final max = m['thresholdMax'] ?? m['ThresholdMax'];
    final trigger = m['triggerValue'] ?? m['TriggerValue'];
    final kindRaw = (m['kind'] ?? m['Kind'] ?? '').toString();
    final title = (m['title'] ?? m['Title'] ?? m['message'] ?? m['Message'] ?? '')
        .toString();
    final message = (m['description'] ?? m['Description'] ?? m['message'] ?? m['Message'] ?? '')
        .toString();
    final deviceCode =
        (m['deviceCode'] ?? m['DeviceCode'] ?? m['sensorCode'] ?? m['SensorCode'] ?? '')
            .toString();
    final kind = _kindOf(kindRaw, title, message);
    return FarmAlert(
      id: (m['id'] ?? m['Id'] ?? '').toString(),
      time: created == null
          ? ''
          : '${created.toLocal().hour.toString().padLeft(2, '0')}:${created.toLocal().minute.toString().padLeft(2, '0')}',
      level: switch (severity) {
        'critical' || 'danger' || 'error' => AlertLevel.critical,
        'info' || 'low' => AlertLevel.info,
        _ => AlertLevel.warning,
      },
      type: AlertTypeCategory.other,
      title: _friendlyTitle(title, message),
      location: (m['locationLabel'] ?? m['LocationLabel'] ?? m['farmingAreaName'] ?? m['FarmingAreaName'] ?? '')
          .toString(),
      device: deviceCode.isNotEmpty
          ? deviceCode
          : (m['sensorType'] ?? m['SensorType'] ?? '').toString(),
      status: switch (status) {
        'acknowledged' || 'notified' => AlertWorkflowStatus.notified,
        'inprogress' || 'in_progress' => AlertWorkflowStatus.inProgress,
        'resolved' || 'closed' => AlertWorkflowStatus.resolved,
        'recovered' => AlertWorkflowStatus.falseAlarm,
        'cancelled' || 'ignored' => AlertWorkflowStatus.ignored,
        'active' || 'open' || 'newalert' => AlertWorkflowStatus.newAlert,
        _ => AlertWorkflowStatus.newAlert,
      },
      handler: '',
      currentValue: trigger == null ? '' : '$trigger',
      threshold: (min == null && max == null) ? '' : '$min – $max',
      recommendations: [
        if ((m['aiRecommendation'] ?? m['AiRecommendation'] ?? '').toString().isNotEmpty)
          (m['aiRecommendation'] ?? m['AiRecommendation']).toString(),
      ],
      suggestedActions: const [],
      detectedAt: created?.toLocal().toString() ?? '',
      note: (m['priorityExplanation'] ?? m['PriorityExplanation'] ?? '').toString(),
      createdAt: created,
      acknowledgedAt: acked,
      resolvedAt: resolved,
      description: _friendlyTitle(message, title),
      sourceLabel: (m['sourceLabel'] ?? m['SourceLabel'] ?? '').toString().isEmpty
          ? _sourceOf(kind)
          : (m['sourceLabel'] ?? m['SourceLabel']).toString(),
      kind: kind,
      areaCode: (m['areaCode'] ?? m['AreaCode'] ?? '').toString(),
      areaName: (m['farmingAreaName'] ?? m['FarmingAreaName'] ?? '').toString(),
      deviceCode: deviceCode,
      deviceKindLabel: kind.label,
      unit: (m['unit'] ?? m['Unit'] ?? '').toString(),
      measuredValue: trigger is num ? trigger.toDouble() : null,
      thresholdMin: min is num ? min.toDouble() : null,
      thresholdMax: max is num ? max.toDouble() : null,
      occurrenceCount: (m['occurrenceCount'] ?? m['OccurrenceCount'] as num?)?.toInt() ?? 1,
      lastOccurredAt: DateTime.tryParse(
          (m['lastOccurredAt'] ?? m['LastOccurredAt'] ?? '').toString()),
      analysisTestId: _extractTestId(message),
      aiConfidence: () {
        final v = m['aiConfidence'] ?? m['AiConfidence'];
        if (v is num && v > 1) return v.toDouble() / 100;
        if (v is num) return v.toDouble();
        return null;
      }(),
      incidentId: (m['incidentId'] ?? m['IncidentId'] ?? '').toString().isEmpty
          ? null
          : (m['incidentId'] ?? m['IncidentId']).toString(),
      ruleKey: (m['category'] ?? m['Category'] ?? '').toString(),
      farmingAreaId: (m['farmingAreaId'] ?? m['FarmingAreaId'] ?? '').toString(),
      aiRecommendation:
          (m['aiRecommendation'] ?? m['AiRecommendation'] ?? '').toString(),
    );
  }

  static AlertKind _kindOf(String raw, String title, String message) {
    final t = '$raw $title $message'.toLowerCase();
    if (t.contains('wateranalysis') || t.contains('no2') || t.contains('nh3') || t.contains('phân tích')) {
      return AlertKind.waterAnalysis;
    }
    if (t.contains('camera')) return AlertKind.camera;
    if (t.contains('pump') || t.contains('bơm') || t.contains('ras') || t.contains('van')) {
      return AlertKind.ras;
    }
    if (t.contains('crab') || t.contains('cua') || t.contains('hộp')) return AlertKind.crab;
    if (t.contains('controller') || t.contains('esp32') || t.contains('heartbeat') || t.contains('crabsense-c')) {
      return AlertKind.controller;
    }
    if (t.contains('sensor') || t.contains('nhiệt') || t.contains('pH') || t.contains('tds')) {
      return AlertKind.sensor;
    }
    switch (raw) {
      case 'controller':
        return AlertKind.controller;
      case 'camera':
        return AlertKind.camera;
      case 'sensor':
        return AlertKind.sensor;
      case 'ras':
        return AlertKind.ras;
      case 'waterAnalysis':
        return AlertKind.waterAnalysis;
      case 'crab':
        return AlertKind.crab;
    }
    return AlertKind.system;
  }

  static String _sourceOf(AlertKind k) => switch (k) {
        AlertKind.controller => 'Controller Monitor',
        AlertKind.camera => 'Camera AI',
        AlertKind.sensor => 'Realtime Sensor',
        AlertKind.ras => 'RAS',
        AlertKind.waterAnalysis => 'Water Analysis',
        AlertKind.crab => 'Crab AI',
        AlertKind.system => 'System',
      };

  static String _friendlyTitle(String title, String fallback) {
    var t = title.trim();
    if (t.isEmpty) t = fallback;
    const raw = {
      'realtime_sensor': 'Cảm biến vượt ngưỡng',
      'controller_disconnect': 'Controller mất kết nối',
      'sensor_timeout': 'Sensor không gửi dữ liệu',
      'ras_component_error': 'Thiết bị RAS lỗi',
    };
    final lower = t.toLowerCase();
    for (final e in raw.entries) {
      if (lower == e.key || lower.contains(e.key)) return e.value;
    }
    return t;
  }

  static String? _extractTestId(String text) {
    final m = RegExp(r'TEST-\d{8}-\d+').firstMatch(text);
    return m?.group(0);
  }

  static AlertHistoryRow _historyFromDto(Map<String, dynamic> m) {
    final created = DateTime.tryParse((m['createdAt'] ?? m['CreatedAt'] ?? '').toString());
    final severity = (m['severity'] ?? '').toString().toLowerCase();
    return AlertHistoryRow(
      date: created?.toLocal().toString() ?? '',
      typeLabel: _friendlyTitle(
        (m['title'] ?? m['Title'] ?? m['category'] ?? '').toString(),
        '',
      ),
      level: switch (severity) {
        'critical' || 'danger' => AlertLevel.critical,
        'info' => AlertLevel.info,
        _ => AlertLevel.warning,
      },
      location: (m['locationLabel'] ?? m['LocationLabel'] ?? '').toString(),
      responseTime: '',
      result: (m['status'] ?? m['Status'] ?? '').toString(),
    );
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }
}
