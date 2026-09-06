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
  String _locationFilter = 'Tất cả';
  String _search = '';
  String? _selectedId;
  bool loading = false;
  String? error;

  String get performerName => _session.user.displayName;
  String get token => _session.token;

  FarmLogKpi get kpi {
    final today = DateTime.now();
    bool isToday(FarmActivityLogEntry e) {
      final a = e.at;
      return a.year == today.year && a.month == today.month && a.day == today.day;
    }

    final t = _entries.where(isToday);
    int n(FarmLogType type) => t.where((e) => e.type == type).length;
    return FarmLogKpi(
      totalToday: t.length,
      feeding: n(FarmLogType.feeding),
      molting: n(FarmLogType.molting) + n(FarmLogType.preMolt),
      weighing: n(FarmLogType.weightUpdate),
      treatment: n(FarmLogType.disease) + n(FarmLogType.medication),
      maintenance: n(FarmLogType.maintenance) + n(FarmLogType.cleanBox),
      harvest: n(FarmLogType.harvest),
    );
  }

  FarmLogAiSummary get aiSummary {
    final feeding = _entries.where((e) => e.type == FarmLogType.feeding).length;
    final molting = _entries
        .where((e) => e.type == FarmLogType.molting || e.type == FarmLogType.preMolt)
        .length;
    final disease = _entries
        .where((e) =>
            e.type == FarmLogType.disease || e.type == FarmLogType.medication)
        .length;
    final maintenance = _entries
        .where((e) =>
            e.type == FarmLogType.maintenance || e.type == FarmLogType.cleanBox)
        .length;
    return FarmLogAiSummary(
      feeding7d: feeding,
      molting7d: molting,
      disease7d: disease,
      maintenance7d: maintenance,
      recommendation: _entries.isEmpty
          ? 'Chưa có nhật ký trên CrabSenseBE.'
          : 'Có ${_entries.length} sự kiện. Ưu tiên xem bản ghi tự động từ AI / RAS.',
    );
  }

  String get timeFilter => _timeFilter;
  String get typeFilter => _typeFilter;
  String get locationFilter => _locationFilter;
  String get performerFilter => 'Tất cả';
  String get areaFilter => _locationFilter;
  String get batchFilter => 'Tất cả';
  bool get timelineView => true;

  FarmActivityLogEntry? get selectedEntry {
    if (_entries.isEmpty) return null;
    if (_selectedId == null) return _entries.first;
    try {
      return _entries.firstWhere((e) => e.id == _selectedId);
    } catch (_) {
      return _entries.first;
    }
  }

  List<String> get locationOptions {
    final set = <String>{};
    for (final e in _entries) {
      if (e.area.trim().isNotEmpty) set.add(e.area.trim());
    }
    return ['Tất cả', ...set.toList()..sort()];
  }

  List<FarmActivityLogEntry> get filteredEntries {
    var list = List<FarmActivityLogEntry>.of(_entries);
    final now = DateTime.now();
    final start = switch (_timeFilter) {
      'Hôm nay' => DateTime(now.year, now.month, now.day),
      '7 ngày' => now.subtract(const Duration(days: 7)),
      '30 ngày' => now.subtract(const Duration(days: 30)),
      _ => null,
    };
    if (start != null) {
      list = list.where((e) => !e.at.isBefore(start)).toList();
    }
    if (_typeFilter != 'Tất cả') {
      list = list.where((e) => e.type.label == _typeFilter).toList();
    }
    if (_locationFilter != 'Tất cả') {
      list = list
          .where((e) =>
              e.placeLabel.toLowerCase().contains(_locationFilter.toLowerCase()) ||
              e.area.toLowerCase().contains(_locationFilter.toLowerCase()))
          .toList();
    }
    if (_search.trim().isNotEmpty) {
      final q = _search.toLowerCase();
      list = list
          .where(
            (e) =>
                e.content.toLowerCase().contains(q) ||
                e.placeLabel.toLowerCase().contains(q) ||
                e.crabId.toLowerCase().contains(q) ||
                e.performer.toLowerCase().contains(q),
          )
          .toList();
    }
    list.sort((a, b) => b.at.compareTo(a.at));
    return list;
  }

  Map<String, List<FarmActivityLogEntry>> groupedByDay() {
    final map = <String, List<FarmActivityLogEntry>>{};
    for (final e in filteredEntries) {
      map.putIfAbsent(_dayKey(e.at), () => []).add(e);
    }
    return map;
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
      final merged = <FarmActivityLogEntry>[
        for (final row in raw) _fromApi(row),
      ];
      final seen = merged.map((e) => e.id).toSet();

      try {
        final recent = await _api.fetchOperationsRecent(
          _session.token,
          farmingAreaId: _session.selectedFarm.id,
        );
        for (final row in recent) {
          final type = (row['type'] ?? row['Type'] ?? '').toString().toLowerCase();
          if (type.contains('sensor')) continue;
          final entry = _fromRecent(row);
          if (seen.add(entry.id)) merged.add(entry);
        }
      } catch (_) {}

      try {
        final wa = await _api.fetchWaterAnalysis(
          _session.token,
          _session.selectedFarm.id,
        );
        final latest = wa['latest'] ?? wa['Latest'];
        if (latest is Map) {
          final entry = _fromWaterAnalysis(Map<String, dynamic>.from(latest));
          if (entry != null && seen.add(entry.id)) merged.add(entry);
        }
      } catch (_) {}

      merged.sort((a, b) => b.at.compareTo(a.at));
      _entries = merged;
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

  void setLocationFilter(String v) {
    _locationFilter = v;
    notifyListeners();
  }

  void setPerformerFilter(String v) {}
  void setAreaFilter(String v) => setLocationFilter(v);
  void setBatchFilter(String v) {}
  void setTimelineView(bool v) {}

  void selectEntry(String id) {
    _selectedId = id;
    notifyListeners();
  }

  Future<String?> uploadPhoto(String path, {String? boxId}) {
    return _api.uploadOperationPhoto(_session.token, path, boxId: boxId);
  }

  Future<void> addEntry({
    required FarmLogType type,
    required String content,
    required DateTime occurredAt,
    String? locationLabel,
    List<String> boxIds = const [],
    String crabId = '',
    List<String> photoUrls = const [],
  }) async {
    try {
      await _api.createOperation(
        _session.token,
        type: _toApiType(type),
        notes: [
          content,
          if (crabId.isNotEmpty) 'Cua: $crabId',
        ].join(' — '),
        operatorName: performerName,
        boxIds: boxIds,
        timestamp: occurredAt,
        photoUrls: photoUrls,
        source: 'manual',
        locationLabel: locationLabel,
      );
      await load();
    } on CloudApiException catch (e) {
      error = e.message;
      notifyListeners();
      rethrow;
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
    final photos = json['photoUrls'] ?? json['PhotoUrls'];
    final urls = photos is List
        ? photos.map((e) => e.toString()).where((e) => e.isNotEmpty).toList()
        : const <String>[];
    final sourceRaw = (json['source'] ?? json['Source'] ?? 'manual').toString();
    final loc = (json['locationLabel'] ?? json['LocationLabel'] ?? '').toString();
    final type = _fromApiType((json['type'] ?? json['Type'] ?? '').toString());
    return FarmActivityLogEntry(
      id: (json['id'] ?? json['Id']).toString(),
      logCode: 'OP-${at.month.toString().padLeft(2, '0')}${at.day.toString().padLeft(2, '0')}',
      time: _hhmm(at),
      logDate: _dmy(at),
      occurredAt: at,
      type: type,
      content: notes,
      performer: (json['operatorName'] ?? json['OperatorName'] ?? '').toString(),
      area: loc.isNotEmpty ? loc.split('→').first.trim() : _session.selectedFarm.name,
      boxId: boxId,
      locationPath: loc,
      note: notes,
      subjectDetail: notes,
      source: sourceRaw.toLowerCase() == 'auto'
          ? FarmLogSource.auto
          : FarmLogSource.manual,
      imageUrls: urls,
      evidenceType: urls.isEmpty ? EvidenceType.none : EvidenceType.photo,
      evidenceLabel: urls.isEmpty ? '' : '${urls.length} ảnh',
    );
  }

  FarmActivityLogEntry _fromRecent(Map<String, dynamic> json) {
    final at = DateTime.tryParse(
          (json['timestamp'] ?? json['Timestamp'] ?? '').toString(),
        )?.toLocal() ??
        DateTime.now();
    final title = (json['title'] ?? json['Title'] ?? 'Hoạt động hệ thống').toString();
    final desc = (json['description'] ?? json['Description'] ?? '').toString();
    final rawType = (json['type'] ?? json['Type'] ?? '').toString();
    return FarmActivityLogEntry(
      id: 'auto-${json['id'] ?? json['Id'] ?? at.millisecondsSinceEpoch}',
      logCode: 'SYS-${at.day.toString().padLeft(2, '0')}',
      time: _hhmm(at),
      logDate: _dmy(at),
      occurredAt: at,
      type: _fromRecentType(rawType, title),
      content: desc.isEmpty ? title : '$title\n$desc',
      performer: 'Hệ thống',
      area: _session.selectedFarm.name,
      source: FarmLogSource.auto,
      subjectDetail: title,
    );
  }

  FarmActivityLogEntry? _fromWaterAnalysis(Map<String, dynamic> json) {
    final at = DateTime.tryParse(
          (json['completedAt'] ?? json['CompletedAt'] ?? json['startedAt'] ?? '')
              .toString(),
        )?.toLocal();
    if (at == null) return null;
    final metrics = json['metrics'] ?? json['Metrics'];
    final buf = StringBuffer('Hoàn thành phân tích nước.');
    if (metrics is List) {
      for (final m in metrics.whereType<Map>()) {
        final label = m['label'] ?? m['Label'];
        final value = m['value'] ?? m['Value'];
        if (label != null && value != null) buf.write('\n$label: $value');
      }
    }
    return FarmActivityLogEntry(
      id: 'wa-${json['id'] ?? json['Id'] ?? at.millisecondsSinceEpoch}',
      logCode: 'WA-${at.day.toString().padLeft(2, '0')}',
      time: _hhmm(at),
      logDate: _dmy(at),
      occurredAt: at,
      type: FarmLogType.waterAnalysis,
      content: buf.toString(),
      performer: 'Hệ thống',
      area: _session.selectedFarm.name,
      source: FarmLogSource.auto,
    );
  }

  String _toApiType(FarmLogType t) => switch (t) {
        FarmLogType.feeding => 'feeding',
        FarmLogType.waterChange => 'waterChange',
        FarmLogType.medication || FarmLogType.disease => 'medication',
        FarmLogType.maintenance ||
        FarmLogType.cleanBox ||
        FarmLogType.cleanSystem =>
          'cleaning',
        FarmLogType.weightUpdate ||
        FarmLogType.observation ||
        FarmLogType.inspectCrab ||
        FarmLogType.waterCheck =>
          'inspection',
        FarmLogType.harvest => 'harvest',
        FarmLogType.molting => 'molting',
        FarmLogType.preMolt => 'preMolt',
        FarmLogType.deathRecord => 'death',
        FarmLogType.crabInbound => 'inbound',
        FarmLogType.placeInBox => 'placeBox',
        FarmLogType.moveBox => 'moveBox',
        FarmLogType.anomaly => 'anomaly',
        FarmLogType.watch => 'watch',
        FarmLogType.waterAnalysis => 'waterAnalysis',
        FarmLogType.rasControl => 'ras',
        FarmLogType.aiEvent => 'ai',
        _ => 'note',
      };

  FarmLogType _fromApiType(String raw) {
    final s = raw.toLowerCase();
    if (s.contains('feed')) return FarmLogType.feeding;
    if (s.contains('wateranalysis') || s.contains('water_analysis')) {
      return FarmLogType.waterAnalysis;
    }
    if (s.contains('watercheck') || s.contains('water_check')) {
      return FarmLogType.waterCheck;
    }
    if (s.contains('water')) return FarmLogType.waterChange;
    if (s.contains('med')) return FarmLogType.medication;
    if (s.contains('clean') || s.contains('maint')) return FarmLogType.maintenance;
    if (s.contains('inspect') || s.contains('check')) return FarmLogType.inspectCrab;
    if (s.contains('premolt') || s.contains('pre_molt')) return FarmLogType.preMolt;
    if (s.contains('molt')) return FarmLogType.molting;
    if (s.contains('harvest')) return FarmLogType.harvest;
    if (s.contains('death') || s.contains('dead')) return FarmLogType.deathRecord;
    if (s.contains('inbound')) return FarmLogType.crabInbound;
    if (s.contains('place')) return FarmLogType.placeInBox;
    if (s.contains('move')) return FarmLogType.moveBox;
    if (s.contains('anomal')) return FarmLogType.anomaly;
    if (s.contains('watch')) return FarmLogType.watch;
    if (s.contains('ras')) return FarmLogType.rasControl;
    if (s.contains('ai')) return FarmLogType.aiEvent;
    return FarmLogType.other;
  }

  FarmLogType _fromRecentType(String raw, String title) {
    final t = '${raw.toLowerCase()} ${title.toLowerCase()}';
    if (t.contains('ai') || t.contains('phát hiện')) return FarmLogType.aiEvent;
    if (t.contains('ras') || t.contains('bơm') || t.contains('skimmer')) {
      return FarmLogType.rasControl;
    }
    if (t.contains('alert') || t.contains('cảnh báo')) return FarmLogType.anomaly;
    if (t.contains('harvest')) return FarmLogType.harvest;
    return FarmLogType.other;
  }

  static String _hhmm(DateTime at) =>
      '${at.hour.toString().padLeft(2, '0')}:${at.minute.toString().padLeft(2, '0')}';

  static String _dmy(DateTime at) =>
      '${at.day.toString().padLeft(2, '0')}/${at.month.toString().padLeft(2, '0')}/${at.year}';

  static String _dayKey(DateTime at) {
    final now = DateTime.now();
    if (at.year == now.year && at.month == now.month && at.day == now.day) {
      return 'Hôm nay';
    }
    final y = now.subtract(const Duration(days: 1));
    if (at.year == y.year && at.month == y.month && at.day == y.day) {
      return 'Hôm qua';
    }
    return _dmy(at);
  }
}
