import 'package:flutter/foundation.dart';

import '../models/auth_models.dart';
import '../models/farm_activity_log.dart';
import 'cloud_api_client.dart';

class FarmLogService extends ChangeNotifier {
  FarmLogService({required AuthSession session, CloudApiClient? api})
      : _session = session,
        _api = api ?? CloudApiClient();

  AuthSession _session;
  final CloudApiClient _api;

  List<FarmActivityLogEntry> _entries = [];
  String _timeFilter = 'Hôm nay';
  String _typeFilter = 'Tất cả';
  String _performerFilter = 'Tất cả';
  String _areaFilter = 'Tất cả';
  String _batchFilter = 'Tất cả';
  String _search = '';
  String? _selectedId;
  bool _timelineView = false;
  bool loading = false;
  String? error;

  FarmLogKpi get kpi {
    final today = DateTime.now();
    bool isToday(FarmActivityLogEntry e) {
      final p = e.logDate.split('/');
      if (p.length != 3) return true;
      return int.tryParse(p[0]) == today.day &&
          int.tryParse(p[1]) == today.month &&
          int.tryParse(p[2]) == today.year;
    }

    final t = _entries.where(isToday);
    int n(FarmLogType type) => t.where((e) => e.type == type).length;
    return FarmLogKpi(
      totalToday: t.length,
      feeding: n(FarmLogType.feeding),
      molting: n(FarmLogType.molting),
      weighing: n(FarmLogType.weightUpdate),
      treatment: n(FarmLogType.disease) + n(FarmLogType.medication),
      maintenance: n(FarmLogType.maintenance),
      harvest: n(FarmLogType.harvest),
    );
  }

  FarmLogAiSummary get aiSummary {
    final feeding = _entries.where((e) => e.type == FarmLogType.feeding).length;
    final molting = _entries.where((e) => e.type == FarmLogType.molting).length;
    final disease = _entries
        .where((e) =>
            e.type == FarmLogType.disease || e.type == FarmLogType.medication)
        .length;
    final maintenance =
        _entries.where((e) => e.type == FarmLogType.maintenance).length;
    return FarmLogAiSummary(
      feeding7d: feeding,
      molting7d: molting,
      disease7d: disease,
      maintenance7d: maintenance,
      recommendation: _entries.isEmpty
          ? 'Chưa có nhật ký trên CrabSenseBE.'
          : 'Có ${_entries.length} thao tác. Ưu tiên theo dõi hộp có cảnh báo.',
    );
  }

  String get timeFilter => _timeFilter;
  String get typeFilter => _typeFilter;
  String get performerFilter => _performerFilter;
  String get areaFilter => _areaFilter;
  String get batchFilter => _batchFilter;
  bool get timelineView => _timelineView;

  FarmActivityLogEntry? get selectedEntry {
    if (_entries.isEmpty) return null;
    if (_selectedId == null) return _entries.first;
    try {
      return _entries.firstWhere((e) => e.id == _selectedId);
    } catch (_) {
      return _entries.first;
    }
  }

  List<FarmActivityLogEntry> get filteredEntries {
    var list = _entries;
    if (_typeFilter != 'Tất cả') {
      list = list.where((e) => e.type.label == _typeFilter).toList();
    }
    if (_performerFilter != 'Tất cả') {
      list = list.where((e) => e.performer == _performerFilter).toList();
    }
    if (_areaFilter != 'Tất cả') {
      list = list
          .where((e) => e.area.toLowerCase().contains(_areaFilter.toLowerCase()))
          .toList();
    }
    if (_batchFilter != 'Tất cả') {
      list = list.where((e) => e.batchId == _batchFilter).toList();
    }
    if (_search.trim().isNotEmpty) {
      final q = _search.toLowerCase();
      list = list
          .where(
            (e) =>
                e.content.toLowerCase().contains(q) ||
                e.crabId.toLowerCase().contains(q) ||
                e.performer.toLowerCase().contains(q),
          )
          .toList();
    }
    return list;
  }

  void updateSession(AuthSession session) {
    _session = session;
    _entries = [];
    _selectedId = null;
  }

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final raw = await _api.fetchOperations(
        _session.token,
        farmingAreaId: _session.selectedFarm.id,
      );
      _entries = raw.map(_fromApi).toList();
      _selectedId = _entries.isEmpty ? null : _entries.first.id;
      error = null;
    } on CloudApiException catch (e) {
      error = e.message;
      _entries = [];
    } catch (e) {
      error = '$e';
      _entries = [];
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void setSearch(String v) {
    _search = v;
    notifyListeners();
  }

  void setTimeFilter(String v) {
    _timeFilter = v;
    notifyListeners();
  }

  void setTypeFilter(String v) {
    _typeFilter = v;
    notifyListeners();
  }

  void setPerformerFilter(String v) {
    _performerFilter = v;
    notifyListeners();
  }

  void setAreaFilter(String v) {
    _areaFilter = v;
    notifyListeners();
  }

  void setBatchFilter(String v) {
    _batchFilter = v;
    notifyListeners();
  }

  void setTimelineView(bool v) {
    _timelineView = v;
    notifyListeners();
  }

  void selectEntry(String id) {
    _selectedId = id;
    notifyListeners();
  }

  Future<void> addEntry({
    required String typeLabel,
    required String performer,
    required String area,
    required String content,
    String batchId = '',
    String crabId = '',
    String note = '',
  }) async {
    final type = _typeFromLabel(typeLabel);
    try {
      await _api.createOperation(
        _session.token,
        type: _toApiType(type),
        notes: [
          content,
          if (note.isNotEmpty) note,
          if (area.isNotEmpty) 'Khu: $area',
          if (batchId.isNotEmpty) 'Lô: $batchId',
          if (crabId.isNotEmpty) 'Cua: $crabId',
        ].join(' — '),
        operatorName: performer,
      );
      await load();
    } on CloudApiException catch (e) {
      error = e.message;
      notifyListeners();
    }
  }

  FarmActivityLogEntry _fromApi(Map<String, dynamic> json) {
    final at = DateTime.tryParse(
          (json['timestamp'] ?? json['Timestamp'] ?? '').toString(),
        )?.toLocal() ??
        DateTime.now();
    final boxes = json['boxIds'] ?? json['BoxIds'];
    final boxId = boxes is List && boxes.isNotEmpty ? boxes.first.toString() : '';
    final notes = (json['notes'] ?? json['Notes'] ?? '').toString();
    final type = _fromApiType((json['type'] ?? json['Type'] ?? '').toString());
    return FarmActivityLogEntry(
      id: (json['id'] ?? json['Id']).toString(),
      logCode: 'OP-${at.month.toString().padLeft(2, '0')}${at.day.toString().padLeft(2, '0')}',
      time: '${at.hour.toString().padLeft(2, '0')}:${at.minute.toString().padLeft(2, '0')}',
      logDate:
          '${at.day.toString().padLeft(2, '0')}/${at.month.toString().padLeft(2, '0')}/${at.year}',
      type: type,
      content: notes,
      performer: (json['operatorName'] ?? json['OperatorName'] ?? '').toString(),
      area: _session.selectedFarm.name,
      boxId: boxId,
      note: notes,
      subjectDetail: notes,
    );
  }

  FarmLogType _typeFromLabel(String label) {
    for (final t in FarmLogType.values) {
      if (t.label == label) return t;
    }
    if (label == 'Điều trị bệnh') return FarmLogType.disease;
    return FarmLogType.other;
  }

  String _toApiType(FarmLogType t) => switch (t) {
        FarmLogType.feeding => 'feeding',
        FarmLogType.waterChange => 'waterChange',
        FarmLogType.medication || FarmLogType.disease => 'medication',
        FarmLogType.maintenance => 'cleaning',
        FarmLogType.weightUpdate || FarmLogType.observation => 'inspection',
        FarmLogType.harvest => 'note',
        _ => 'note',
      };

  FarmLogType _fromApiType(String raw) {
    final s = raw.toLowerCase();
    if (s.contains('feed')) return FarmLogType.feeding;
    if (s.contains('water')) return FarmLogType.waterChange;
    if (s.contains('med')) return FarmLogType.medication;
    if (s.contains('clean') || s.contains('maint')) return FarmLogType.maintenance;
    if (s.contains('inspect')) return FarmLogType.observation;
    if (s.contains('molt')) return FarmLogType.molting;
    if (s.contains('harvest')) return FarmLogType.harvest;
    return FarmLogType.other;
  }
}
