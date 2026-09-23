import 'package:flutter/material.dart';

import '../theme/dashboard_theme.dart';
import '../widgets/shared/mgmt_ui.dart';

const kHistBlue = Color(0xFF2495E8);
const kHistAmber = Color(0xFFF5B700);
const kHistPurple = Color(0xFF7C3AED);
const kHistCyan = Color(0xFF0EA5E9);

enum CrabHistoryPeriod {
  h24('24 giờ', Duration(hours: 24)),
  d7('7 ngày', Duration(days: 7)),
  d30('30 ngày', Duration(days: 30)),
  d90('90 ngày', Duration(days: 90)),
  all('Toàn bộ', null),
  custom('Tùy chọn ngày', null);

  const CrabHistoryPeriod(this.label, this.duration);
  final String label;
  final Duration? duration;
}

enum CrabHistorySort {
  newest('Mới nhất trước'),
  oldest('Cũ nhất trước');

  const CrabHistorySort(this.label);
  final String label;
}

enum CrabHistoryEventFilter {
  all('Tất cả sự kiện', 'ALL'),
  feeding('Cho ăn', 'FEEDING'),
  growth('Sinh trưởng', 'GROWTH_UPDATE'),
  molt('Lột xác', 'MOLT'),
  health('Sức khỏe', 'HEALTH_CHECK'),
  transfer('Chuyển hộp', 'BOX_TRANSFER'),
  ai('AI phát hiện', 'AI_DETECTION'),
  alert('Cảnh báo', 'ALERT'),
  harvest('Thu hoạch', 'HARVEST'),
  system('Hệ thống', 'SYSTEM'),
  note('Ghi chú', 'NOTE_UPDATED');

  const CrabHistoryEventFilter(this.label, this.api);
  final String label;
  final String api;
}

enum CrabLifecycleEventType {
  feeding,
  growth,
  health,
  moltStart,
  moltComplete,
  transfer,
  ai,
  alertCreated,
  alertResolved,
  harvestReady,
  harvested,
  dead,
  note,
  profile,
  created,
  system,
  unknown;

  static CrabLifecycleEventType parse(String? raw) {
    switch ((raw ?? '').trim().toUpperCase()) {
      case 'FEEDING':
        return feeding;
      case 'GROWTH_UPDATE':
        return growth;
      case 'HEALTH_CHECK':
        return health;
      case 'MOLT_START':
        return moltStart;
      case 'MOLT_COMPLETE':
        return moltComplete;
      case 'BOX_TRANSFER':
        return transfer;
      case 'AI_DETECTION':
        return ai;
      case 'ALERT_CREATED':
        return alertCreated;
      case 'ALERT_RESOLVED':
        return alertResolved;
      case 'HARVEST_READY':
        return harvestReady;
      case 'HARVESTED':
        return harvested;
      case 'DEAD':
        return dead;
      case 'NOTE_UPDATED':
        return note;
      case 'CRAB_PROFILE_UPDATED':
        return profile;
      case 'CRAB_CREATED':
        return created;
      case 'SYSTEM':
        return system;
      default:
        return unknown;
    }
  }

  String get label => switch (this) {
        feeding => 'Cho ăn',
        growth => 'Cập nhật sinh trưởng',
        health => 'Kiểm tra sức khỏe',
        moltStart => 'Bắt đầu lột xác',
        moltComplete => 'Hoàn tất lột xác',
        transfer => 'Chuyển hộp',
        ai => 'AI phát hiện',
        alertCreated => 'Cảnh báo',
        alertResolved => 'Xác nhận cảnh báo',
        harvestReady => 'Sẵn sàng thu hoạch',
        harvested => 'Thu hoạch',
        dead => 'Ghi nhận chết',
        note => 'Ghi chú',
        profile => 'Cập nhật thông tin cua',
        created => 'Tạo cá thể',
        system => 'Hệ thống',
        unknown => 'Sự kiện',
      };

  Color get color => switch (this) {
        feeding => DashboardColors.brand,
        growth => kHistBlue,
        health => DashboardColors.brandGreen,
        moltStart || moltComplete => kHistPurple,
        transfer => kHistCyan,
        ai => kHistBlue,
        alertCreated => kHistAmber,
        alertResolved => DashboardColors.brandGreen,
        harvestReady || harvested => kHistAmber,
        dead => DashboardColors.risk,
        note => kMgmtSlate,
        profile => DashboardColors.brand,
        created => DashboardColors.brand,
        system => kMgmtSlate,
        unknown => kMgmtSlate,
      };

  IconData get icon => switch (this) {
        feeding => Icons.restaurant_rounded,
        growth => Icons.monitor_weight_outlined,
        health => Icons.favorite_rounded,
        moltStart || moltComplete => Icons.autorenew_rounded,
        transfer => Icons.swap_horiz_rounded,
        ai => Icons.smart_toy_outlined,
        alertCreated => Icons.warning_amber_rounded,
        alertResolved => Icons.check_circle_outline_rounded,
        harvestReady || harvested => Icons.inventory_2_outlined,
        dead => Icons.heart_broken_outlined,
        note => Icons.notes_rounded,
        profile => Icons.edit_outlined,
        created => Icons.add_circle_outline_rounded,
        system => Icons.settings_suggest_outlined,
        unknown => Icons.circle_outlined,
      };

  CrabHistoryEventFilter get filter => switch (this) {
        feeding => CrabHistoryEventFilter.feeding,
        growth => CrabHistoryEventFilter.growth,
        moltStart || moltComplete => CrabHistoryEventFilter.molt,
        health => CrabHistoryEventFilter.health,
        transfer => CrabHistoryEventFilter.transfer,
        ai => CrabHistoryEventFilter.ai,
        alertCreated || alertResolved => CrabHistoryEventFilter.alert,
        harvestReady || harvested || dead => CrabHistoryEventFilter.harvest,
        system => CrabHistoryEventFilter.system,
        note => CrabHistoryEventFilter.note,
        profile => CrabHistoryEventFilter.system,
        created => CrabHistoryEventFilter.system,
        unknown => CrabHistoryEventFilter.all,
      };
}

class CrabLifecycleChange {
  const CrabLifecycleChange({this.before, this.after});

  final dynamic before;
  final dynamic after;

  factory CrabLifecycleChange.fromJson(Map<String, dynamic> json) => CrabLifecycleChange(
        before: json['before'] ?? json['Before'],
        after: json['after'] ?? json['After'],
      );
}

class CrabLifecycleLocation {
  const CrabLifecycleLocation({
    this.farmAreaId,
    this.farmAreaCode,
    this.rowId,
    this.rowCode,
    this.boxId,
    this.boxCode,
  });

  final String? farmAreaId;
  final String? farmAreaCode;
  final String? rowId;
  final String? rowCode;
  final String? boxId;
  final String? boxCode;

  factory CrabLifecycleLocation.fromJson(Map<String, dynamic> json) => CrabLifecycleLocation(
        farmAreaId: _opt(json['farmAreaId'] ?? json['FarmAreaId']),
        farmAreaCode: _opt(json['farmAreaCode'] ?? json['FarmAreaCode']),
        rowId: _opt(json['rowId'] ?? json['RowId']),
        rowCode: _opt(json['rowCode'] ?? json['RowCode']),
        boxId: _opt(json['boxId'] ?? json['BoxId']),
        boxCode: _opt(json['boxCode'] ?? json['BoxCode']),
      );
}

class CrabLifecycleActor {
  const CrabLifecycleActor({required this.type, this.id, required this.name});

  final String type;
  final String? id;
  final String name;

  factory CrabLifecycleActor.fromJson(Map<String, dynamic> json) => CrabLifecycleActor(
        type: _str(json, const ['type', 'Type'], fallback: 'SYSTEM'),
        id: _opt(json['id'] ?? json['Id']),
        name: _str(json, const ['name', 'Name'], fallback: 'System'),
      );
}

class CrabLifecycleEvent {
  const CrabLifecycleEvent({
    required this.id,
    required this.crabId,
    required this.crabCode,
    required this.eventType,
    required this.occurredAt,
    required this.title,
    required this.summary,
    this.location,
    required this.actor,
    required this.source,
    this.cameraId,
    this.changes = const {},
    this.metadata = const {},
    this.mediaUrls = const [],
    this.note,
    this.severity,
  });

  final String id;
  final String crabId;
  final String crabCode;
  final CrabLifecycleEventType eventType;
  final DateTime occurredAt;
  final String title;
  final String summary;
  final CrabLifecycleLocation? location;
  final CrabLifecycleActor actor;
  final String source;
  final String? cameraId;
  final Map<String, CrabLifecycleChange> changes;
  final Map<String, dynamic> metadata;
  final List<String> mediaUrls;
  final String? note;
  final String? severity;

  factory CrabLifecycleEvent.fromJson(Map<String, dynamic> json) {
    final locRaw = json['location'] ?? json['Location'];
    final actorRaw = json['actor'] ?? json['Actor'];
    return CrabLifecycleEvent(
      id: _str(json, const ['id', 'Id']),
      crabId: _str(json, const ['crabId', 'CrabId']),
      crabCode: _str(json, const ['crabCode', 'CrabCode']),
      eventType: CrabLifecycleEventType.parse(_str(json, const ['eventType', 'EventType'])),
      occurredAt: _date(json['occurredAt'] ?? json['OccurredAt']) ?? DateTime.now(),
      title: _str(json, const ['title', 'Title']),
      summary: _str(json, const ['summary', 'Summary']),
      location: locRaw is Map ? CrabLifecycleLocation.fromJson(Map<String, dynamic>.from(locRaw)) : null,
      actor: actorRaw is Map
          ? CrabLifecycleActor.fromJson(Map<String, dynamic>.from(actorRaw))
          : const CrabLifecycleActor(type: 'SYSTEM', name: 'System'),
      source: _str(json, const ['source', 'Source'], fallback: 'SYSTEM'),
      cameraId: _opt(json['cameraId'] ?? json['CameraId']),
      changes: _changes(json['changes'] ?? json['Changes']),
      metadata: _meta(json['metadata'] ?? json['Metadata']),
      mediaUrls: _urls(json['mediaUrls'] ?? json['MediaUrls']),
      note: _opt(json['note'] ?? json['Note']),
      severity: _opt(json['severity'] ?? json['Severity']),
    );
  }

  String get boxLabel => location?.boxCode ?? '—';
  String get actorLabel => actor.name.isEmpty ? '—' : actor.name;
  String sourceLabel() {
    switch (source.toUpperCase()) {
      case 'MANUAL':
        return 'Manual';
      case 'AI_CAMERA':
        return 'AI Camera';
      case 'MANUAL_AI':
        return 'Manual + AI Camera';
      case 'CONTROLLER':
        return 'Controller';
      case 'IMPORT':
        return 'Import';
      case 'SYSTEM':
        return 'System';
      default:
        return source;
    }
  }

  dynamic meta(String key) => metadata[key] ?? metadata[key[0].toUpperCase() + key.substring(1)];

  num? metaNum(String key) {
    final v = meta(key);
    if (v is num) return v;
    return num.tryParse('$v');
  }

  String? metaStr(String key) {
    final v = meta(key);
    if (v == null) return null;
    final s = '$v'.trim();
    return s.isEmpty || s == 'null' ? null : s;
  }
}

class CrabLifecycleSummary {
  const CrabLifecycleSummary({
    this.total = 0,
    this.feeding = 0,
    this.growth = 0,
    this.molt = 0,
    this.health = 0,
    this.transfer = 0,
    this.ai = 0,
    this.alert = 0,
    this.harvest = 0,
    this.system = 0,
    this.note = 0,
  });

  final int total;
  final int feeding;
  final int growth;
  final int molt;
  final int health;
  final int transfer;
  final int ai;
  final int alert;
  final int harvest;
  final int system;
  final int note;

  factory CrabLifecycleSummary.fromJson(Map<String, dynamic> json) => CrabLifecycleSummary(
        total: _int(json, const ['total', 'Total']),
        feeding: _int(json, const ['feeding', 'Feeding']),
        growth: _int(json, const ['growth', 'Growth']),
        molt: _int(json, const ['molt', 'Molt']),
        health: _int(json, const ['health', 'Health']),
        transfer: _int(json, const ['transfer', 'Transfer']),
        ai: _int(json, const ['ai', 'Ai']),
        alert: _int(json, const ['alert', 'Alert']),
        harvest: _int(json, const ['harvest', 'Harvest']),
        system: _int(json, const ['system', 'System']),
        note: _int(json, const ['note', 'Note']),
      );

  int of(CrabHistoryEventFilter f) => switch (f) {
        CrabHistoryEventFilter.all => total,
        CrabHistoryEventFilter.feeding => feeding,
        CrabHistoryEventFilter.growth => growth,
        CrabHistoryEventFilter.molt => molt,
        CrabHistoryEventFilter.health => health,
        CrabHistoryEventFilter.transfer => transfer,
        CrabHistoryEventFilter.ai => ai,
        CrabHistoryEventFilter.alert => alert,
        CrabHistoryEventFilter.harvest => harvest,
        CrabHistoryEventFilter.system => system,
        CrabHistoryEventFilter.note => note,
      };
}

class CrabLifecyclePage {
  const CrabLifecyclePage({
    required this.items,
    required this.total,
    required this.hasMore,
    required this.summary,
  });

  final List<CrabLifecycleEvent> items;
  final int total;
  final bool hasMore;
  final CrabLifecycleSummary summary;

  factory CrabLifecyclePage.fromJson(Map<String, dynamic> json) => CrabLifecyclePage(
        items: _list(json['items'] ?? json['Items'], CrabLifecycleEvent.fromJson),
        total: _int(json, const ['total', 'Total']),
        hasMore: json['hasMore'] == true || json['HasMore'] == true,
        summary: CrabLifecycleSummary.fromJson(_map(json['summary'] ?? json['Summary'])),
      );
}

String weekdayVn(DateTime dt) {
  const days = ['Thứ Hai', 'Thứ Ba', 'Thứ Tư', 'Thứ Năm', 'Thứ Sáu', 'Thứ Bảy', 'Chủ Nhật'];
  return days[dt.weekday - 1];
}

String historyDayLabel(DateTime dt) {
  final l = dt.isUtc ? dt.toLocal() : dt;
  return '${fmtDateVn(l)} (${weekdayVn(l)})';
}

String historyTimeLabel(DateTime dt) {
  final l = dt.isUtc ? dt.toLocal() : dt;
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(l.hour)}:${two(l.minute)}';
}

String fmtHistNum(num? v, {String suffix = ''}) {
  if (v == null) return '—';
  final n = v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);
  return suffix.isEmpty ? n : '$n $suffix';
}

String fmtHistSigned(num? v, {String suffix = 'g'}) {
  if (v == null) return '—';
  final sign = v > 0 ? '+' : '';
  return '$sign${fmtHistNum(v, suffix: suffix)}';
}

Map<String, dynamic> _map(dynamic raw) {
  if (raw is Map<String, dynamic>) return raw;
  if (raw is Map) return Map<String, dynamic>.from(raw);
  return {};
}

List<T> _list<T>(dynamic raw, T Function(Map<String, dynamic>) parse) {
  if (raw is! List) return const [];
  return [
    for (final e in raw)
      if (e is Map) parse(Map<String, dynamic>.from(e)),
  ];
}

Map<String, CrabLifecycleChange> _changes(dynamic raw) {
  if (raw is! Map) return const {};
  return {
    for (final e in raw.entries)
      if (e.value is Map)
        e.key.toString(): CrabLifecycleChange.fromJson(Map<String, dynamic>.from(e.value as Map)),
  };
}

Map<String, dynamic> _meta(dynamic raw) {
  if (raw is Map<String, dynamic>) return raw;
  if (raw is Map) return Map<String, dynamic>.from(raw);
  return const {};
}

List<String> _urls(dynamic raw) {
  if (raw is! List) return const [];
  return [
    for (final e in raw)
      if ('$e'.trim().isNotEmpty) '$e'.trim(),
  ];
}

String _str(Map<String, dynamic> json, List<String> keys, {String fallback = ''}) {
  for (final k in keys) {
    final v = json[k];
    if (v == null) continue;
    final s = v.toString().trim();
    if (s.isNotEmpty && s != '00000000-0000-0000-0000-000000000000') return s;
  }
  return fallback;
}

String? _opt(dynamic v) {
  if (v == null) return null;
  final s = v.toString().trim();
  if (s.isEmpty || s == 'null' || s == '00000000-0000-0000-0000-000000000000') return null;
  return s;
}

int _int(Map<String, dynamic> json, List<String> keys) {
  for (final k in keys) {
    final v = json[k];
    if (v is int) return v;
    if (v is num) return v.toInt();
    final n = int.tryParse('$v');
    if (n != null) return n;
  }
  return 0;
}

DateTime? _date(dynamic v) {
  if (v is DateTime) return v;
  if (v == null) return null;
  return DateTime.tryParse(v.toString());
}
