import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../models/camera_device.dart';
import '../../../models/crab_lifecycle_event.dart';
import '../../../models/production_models.dart';
import '../../../services/crab_profile_service.dart';
import '../../../theme/dashboard_theme.dart';
import '../../crab/crab_overview_cards.dart';
import '../../shared/mgmt_ui.dart';
import 'box_labels.dart';

enum BoxHistoryType {
  feeding,
  inspection,
  crabIn,
  crabOut,
  transfer,
  camera,
  sensor,
  alert,
  device,
  maintenance,
  boxUpdated,
  system,
}

enum BoxHistorySource { all, user, cameraAi, sensor, controller, esp32, system }

enum BoxHistoryRange { h24, d7, d30, d90, all, custom }

enum BoxHistorySort { newest, oldest }

class BoxHistoryEvent {
  const BoxHistoryEvent({
    required this.id,
    required this.at,
    required this.type,
    required this.title,
    required this.summary,
    required this.source,
    this.actorName,
    this.actorRole,
    this.crabId,
    this.crabCode,
    this.deviceCode,
    this.note,
    this.before = const {},
    this.after = const {},
    this.meta = const {},
    this.mediaUrls = const [],
  });

  final String id;
  final DateTime at;
  final BoxHistoryType type;
  final String title;
  final String summary;
  final BoxHistorySource source;
  final String? actorName;
  final String? actorRole;
  final String? crabId;
  final String? crabCode;
  final String? deviceCode;
  final String? note;
  final Map<String, String> before;
  final Map<String, String> after;
  final Map<String, String> meta;
  final List<String> mediaUrls;
}

class BoxHistoryTab extends StatefulWidget {
  const BoxHistoryTab({
    super.key,
    required this.box,
    required this.profileService,
    required this.areaId,
    required this.areaCode,
    required this.areaName,
    required this.rowLabel,
    this.crabId,
    this.crabCode,
    this.camera,
    this.onOpenCrab,
    this.onOpenCamera,
    this.onOpenSensors,
    this.onOpenAlerts,
  });

  final BoxRecord box;
  final CrabProfileService profileService;
  final String areaId;
  final String areaCode;
  final String areaName;
  final String rowLabel;
  final String? crabId;
  final String? crabCode;
  final CameraDevice? camera;
  final void Function(String crabId)? onOpenCrab;
  final VoidCallback? onOpenCamera;
  final VoidCallback? onOpenSensors;
  final VoidCallback? onOpenAlerts;

  @override
  State<BoxHistoryTab> createState() => _BoxHistoryTabState();
}

class _BoxHistoryTabState extends State<BoxHistoryTab> {
  final _search = TextEditingController();
  Timer? _debounce;
  List<BoxHistoryEvent> _all = const [];
  var _loading = true;
  String? _error;
  BoxHistoryType? _type;
  var _crabChange = false;
  BoxHistorySource _source = BoxHistorySource.all;
  BoxHistoryRange _range = BoxHistoryRange.d7;
  DateTimeRange? _custom;
  BoxHistorySort _sort = BoxHistorySort.newest;
  String _query = '';
  String? _selectedId;
  var _visible = 20;

  CrabProfileService get _svc => widget.profileService;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant BoxHistoryTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.box.id != widget.box.id) _load();
  }

  @override
  void dispose() {
    _search.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final items = <BoxHistoryEvent>[];
    try {
      await Future.wait([
        _addStatus(items),
        _addAllocations(items),
        _addLifecycle(items),
        _addFeeding(items),
        _addAlerts(items),
        _addDetections(items),
        _addOperations(items),
      ]);
      _addCamera(items);
      items.sort((a, b) => b.at.compareTo(a.at));
      final seen = <String>{};
      final uniq = <BoxHistoryEvent>[];
      for (final e in items) {
        final k = '${e.at.millisecondsSinceEpoch ~/ 60000}|${e.type}|${e.title}|${e.crabCode ?? ''}|${e.summary}';
        if (seen.add(k)) uniq.add(e);
      }
      if (!mounted) return;
      setState(() {
        _all = uniq;
        _loading = false;
        _selectedId ??= uniq.isEmpty ? null : uniq.first.id;
        _visible = 20;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  Future<void> _addStatus(List<BoxHistoryEvent> out) async {
    try {
      final rows = await _svc.fetchBoxStatusHistory(widget.box.id);
      for (final raw in rows) {
        final at = DateTime.tryParse((raw['changedAt'] ?? raw['ChangedAt'] ?? '').toString());
        if (at == null) continue;
        final oldS = (raw['oldStatus'] ?? raw['OldStatus'] ?? '').toString();
        final newS = (raw['newStatus'] ?? raw['NewStatus'] ?? '').toString();
        final reason = (raw['reason'] ?? raw['Reason'] ?? '').toString();
        final type = _boxChangeType(oldS, newS, reason);
        out.add(BoxHistoryEvent(
          id: 'st-${raw['id'] ?? raw['Id'] ?? at.millisecondsSinceEpoch}',
          at: at.toLocal(),
          type: type,
          title: type == BoxHistoryType.maintenance
              ? (isBoxLocked(newS) ? 'Bắt đầu bảo trì' : 'Kết thúc bảo trì')
              : 'Cập nhật thông tin hộp',
          summary: [
            if (oldS.isNotEmpty && newS.isNotEmpty) '${boxOperationalLabel(oldS)} → ${boxOperationalLabel(newS)}',
            if (reason.trim().isNotEmpty) reason,
          ].join(' · '),
          source: BoxHistorySource.system,
          actorName: 'Hệ thống',
          actorRole: 'Hệ thống',
          before: {if (oldS.isNotEmpty) 'Trạng thái': boxOperationalLabel(oldS)},
          after: {if (newS.isNotEmpty) 'Trạng thái': boxOperationalLabel(newS)},
          note: reason.trim().isEmpty ? null : reason,
        ));
      }
    } catch (_) {}
  }

  Future<void> _addAllocations(List<BoxHistoryEvent> out) async {
    try {
      final rows = await _svc.fetchBoxAllocations(widget.box.id);
      final codes = <String, String>{};
      if (widget.crabId != null && (widget.crabCode ?? '').isNotEmpty) {
        codes[widget.crabId!] = widget.crabCode!;
      }
      for (final raw in rows) {
        final crabId = (raw['crabId'] ?? raw['CrabId'] ?? '').toString();
        if (crabId.isEmpty || codes.containsKey(crabId)) continue;
        try {
          final d = await _svc.fetchCrabDetail(crabId);
          codes[crabId] = (d['code'] ?? d['Code'] ?? d['tag'] ?? d['Tag'] ?? crabId).toString();
        } catch (_) {
          codes[crabId] = crabId;
        }
      }
      for (final raw in rows) {
        final crabId = (raw['crabId'] ?? raw['CrabId'] ?? '').toString();
        final start = DateTime.tryParse((raw['startTime'] ?? raw['StartTime'] ?? '').toString());
        if (crabId.isEmpty || start == null) continue;
        final note = (raw['notes'] ?? raw['Notes'] ?? raw['note'] ?? raw['Note'] ?? '').toString();
        final code = codes[crabId] ?? crabId;
        final lot = (raw['lotCode'] ?? raw['LotCode'] ?? raw['sourceLot'] ?? '').toString();
        out.add(BoxHistoryEvent(
          id: 'in-$crabId-${start.millisecondsSinceEpoch}',
          at: start.toLocal(),
          type: note.toLowerCase().contains('chuyển') || note.toLowerCase().contains('transfer')
              ? BoxHistoryType.transfer
              : BoxHistoryType.crabIn,
          title: note.toLowerCase().contains('chuyển') ? 'Cua được chuyển vào hộp' : 'Cua được đưa vào hộp',
          summary: [code, if (lot.isNotEmpty) 'Nguồn: $lot'].join(' · '),
          source: BoxHistorySource.user,
          actorName: (raw['operatorName'] ?? raw['OperatorName'] ?? '').toString().trim().isEmpty
              ? 'Hệ thống'
              : (raw['operatorName'] ?? raw['OperatorName']).toString(),
          actorRole: 'Nhân viên vận hành',
          crabId: crabId,
          crabCode: code,
          note: note.trim().isEmpty ? null : note,
          meta: {
            if (lot.isNotEmpty) 'Nguồn': lot,
            'Hộp': widget.box.boxCode,
          },
        ));
        final end = DateTime.tryParse((raw['endTime'] ?? raw['EndTime'] ?? '').toString());
        if (end == null) continue;
        final n = note.toLowerCase();
        final outType = n.contains('chết')
            ? BoxHistoryType.crabOut
            : (n.contains('thu hoạch') || n.contains('harvest') ? BoxHistoryType.crabOut : BoxHistoryType.transfer);
        out.add(BoxHistoryEvent(
          id: 'out-$crabId-${end.millisecondsSinceEpoch}',
          at: end.toLocal(),
          type: outType,
          title: boxOccupancyEventLabel(n.contains('chết')
              ? 'DEAD_REMOVED'
              : (n.contains('thu hoạch') ? 'HARVESTED' : 'TRANSFERRED_OUT')),
          summary: [code, if (note.trim().isNotEmpty) note].join(' · '),
          source: BoxHistorySource.user,
          actorName: (raw['operatorName'] ?? raw['OperatorName'] ?? '').toString().trim().isEmpty
              ? 'Hệ thống'
              : (raw['operatorName'] ?? raw['OperatorName']).toString(),
          actorRole: 'Nhân viên vận hành',
          crabId: crabId,
          crabCode: code,
          note: note.trim().isEmpty ? null : note,
          meta: {
            'Từ': widget.box.boxCode,
            if ((raw['toBoxCode'] ?? raw['ToBoxCode'] ?? '').toString().isNotEmpty) 'Đến': (raw['toBoxCode'] ?? raw['ToBoxCode']).toString(),
            if (note.trim().isNotEmpty) 'Lý do': note,
          },
        ));
      }
    } catch (_) {}
  }

  Future<void> _addLifecycle(List<BoxHistoryEvent> out) async {
    final crabId = widget.crabId;
    if (crabId == null || crabId.isEmpty) return;
    try {
      final page = await _svc.fetchCrabLifecycle(crabId, take: 80);
      for (final e in page.items) {
        if (!_lifecycleInBox(e)) continue;
        out.add(BoxHistoryEvent(
          id: 'lc-${e.id}',
          at: e.occurredAt.isUtc ? e.occurredAt.toLocal() : e.occurredAt,
          type: _fromLifecycle(e.eventType),
          title: _humanTitle(e.title.isEmpty ? e.eventType.label : e.title, e.eventType),
          summary: e.summary,
          source: _sourceOf(e.source, e.actor.name),
          actorName: _actorName(e.actor.name),
          actorRole: _actorRole(e.actor.type, e.actor.name),
          crabId: e.crabId.isEmpty ? crabId : e.crabId,
          crabCode: e.crabCode.isEmpty ? widget.crabCode : e.crabCode,
          deviceCode: e.cameraId,
          note: e.note,
          before: {
            for (final en in e.changes.entries)
              if (en.value.before != null) _fieldLabel(en.key): '${en.value.before}',
          },
          after: {
            for (final en in e.changes.entries)
              if (en.value.after != null) _fieldLabel(en.key): '${en.value.after}',
          },
          meta: {
            for (final en in e.metadata.entries)
              if ('${en.value}'.isNotEmpty && '${en.value}' != 'null') _fieldLabel(en.key): '${en.value}',
          },
          mediaUrls: e.mediaUrls.where((u) => u.startsWith('http')).toList(),
        ));
      }
    } catch (_) {}
  }

  Future<void> _addFeeding(List<BoxHistoryEvent> out) async {
    final crabId = widget.crabId;
    if (crabId == null || crabId.isEmpty) return;
    try {
      final data = await _svc.fetchCrabFeeding(crabId, days: 90, limit: 50);
      for (final f in data.events) {
        if (f.boxIds.isNotEmpty && !f.boxIds.contains(widget.box.id) && !f.boxIds.contains(widget.box.boxCode)) {
          continue;
        }
        out.add(BoxHistoryEvent(
          id: 'feed-${f.id}',
          at: f.time,
          type: BoxHistoryType.feeding,
          title: 'Cho ăn',
          summary: [
            widget.crabCode,
            if (f.servedGram != null) 'Khẩu phần: ${f.servedGram!.toStringAsFixed(0)} g',
            if (f.eatenGram != null) 'Đã ăn: ${f.eatenGram!.toStringAsFixed(0)} g',
            if (f.feedingPercent != null) 'Mức ăn: ${f.feedingPercent}%',
          ].whereType<String>().join(' · '),
          source: _sourceOf(f.source, f.operatorName),
          actorName: _actorName(f.operatorName),
          actorRole: _actorRole('', f.operatorName),
          crabId: crabId,
          crabCode: widget.crabCode,
          deviceCode: f.cameraId,
          note: f.note,
          meta: {
            if (f.servedGram != null) 'Khẩu phần': '${f.servedGram!.toStringAsFixed(0)} g',
            if (f.eatenGram != null) 'Đã ăn': '${f.eatenGram!.toStringAsFixed(0)} g',
            if (f.feedingPercent != null) 'Mức ăn': '${f.feedingPercent}%',
            if (f.foodType.isNotEmpty) 'Loại thức ăn': f.foodType,
          },
          mediaUrls: f.photoUrls.where((u) => u.startsWith('http')).toList(),
        ));
      }
    } catch (_) {}
    final crab = _svc.data;
    if (crab == null) return;
    for (final f in crab.feedingLogs) {
      final at = DateTime.tryParse(f.fedAt);
      if (at == null) continue;
      out.add(BoxHistoryEvent(
        id: 'flog-${f.fedAt}-${f.quantity}',
        at: at.toLocal(),
        type: BoxHistoryType.feeding,
        title: 'Cho ăn',
        summary: '${widget.crabCode ?? ''} · Lượng: ${f.quantity.toStringAsFixed(0)} ${f.unit}',
        source: BoxHistorySource.user,
        actorName: 'Hệ thống',
        crabId: crabId,
        crabCode: widget.crabCode,
        meta: {'Khẩu phần': '${f.quantity.toStringAsFixed(0)} ${f.unit}'},
      ));
    }
  }

  Future<void> _addAlerts(List<BoxHistoryEvent> out) async {
    try {
      final rows = await _svc.fetchBoxAlerts(boxId: widget.box.id, farmingAreaId: widget.areaId);
      for (final j in rows) {
        final at = DateTime.tryParse((j['createdAt'] ?? j['CreatedAt'] ?? '').toString());
        if (at == null) continue;
        final title = (j['title'] ?? j['Title'] ?? j['message'] ?? j['Message'] ?? '').toString();
        final msg = (j['message'] ?? j['Message'] ?? '').toString();
        final hay = '$title $msg'.toLowerCase();
        final type = hay.contains('camera')
            ? BoxHistoryType.camera
            : (hay.contains('ph') || hay.contains('nhiệt') || hay.contains('temp') || hay.contains('tds') || hay.contains('do')
                ? BoxHistoryType.sensor
                : (hay.contains('esp32') || hay.contains('controller') ? BoxHistoryType.device : BoxHistoryType.alert));
        final code = (j['sensorCode'] ?? j['SensorCode'] ?? '').toString();
        final trigger = j['triggerValue'] ?? j['TriggerValue'];
        final min = j['thresholdMin'] ?? j['ThresholdMin'];
        final max = j['thresholdMax'] ?? j['ThresholdMax'];
        out.add(BoxHistoryEvent(
          id: 'al-${j['id'] ?? j['Id'] ?? at.millisecondsSinceEpoch}',
          at: at.toLocal(),
          type: type,
          title: _alertTitle(title, hay),
          summary: [
            if (trigger != null) 'Giá trị: $trigger',
            if (min != null || max != null) 'Ngưỡng: ${min ?? ''}–${max ?? ''}',
            if (code.isNotEmpty) code,
          ].join(' · '),
          source: type == BoxHistoryType.camera
              ? BoxHistorySource.cameraAi
              : (type == BoxHistoryType.sensor ? BoxHistorySource.sensor : BoxHistorySource.system),
          actorName: 'Hệ thống',
          actorRole: 'Hệ thống',
          deviceCode: code.isEmpty ? widget.camera?.cameraCode : code,
          meta: {
            if (trigger != null) 'Giá trị': '$trigger',
            if (min != null || max != null) 'Ngưỡng': '${min ?? ''}–${max ?? ''}',
            if (code.isNotEmpty) 'Nguồn': code,
            if (widget.areaCode.isNotEmpty) 'Phạm vi': 'Nước tuần hoàn chung ${widget.areaCode}',
            'Trạng thái': _alertStatus((j['status'] ?? j['Status'] ?? '').toString()),
          },
        ));
      }
    } catch (_) {}
  }

  Future<void> _addDetections(List<BoxHistoryEvent> out) async {
    try {
      final rows = await _svc.fetchAiDetections(boxId: widget.box.id, take: 20);
      for (final j in rows) {
        final at = DateTime.tryParse((j['detectedAt'] ?? j['DetectedAt'] ?? '').toString());
        if (at == null) continue;
        final type = (j['detectionType'] ?? j['DetectionType'] ?? '').toString();
        final img = (j['imagePath'] ?? j['ImagePath'] ?? j['imageUrl'] ?? '').toString();
        out.add(BoxHistoryEvent(
          id: 'ai-${j['id'] ?? j['Id'] ?? at.millisecondsSinceEpoch}',
          at: at.toLocal(),
          type: BoxHistoryType.camera,
          title: 'Camera AI',
          summary: _aiSummary(type, j),
          source: BoxHistorySource.cameraAi,
          actorName: 'Hệ thống',
          actorRole: 'Hệ thống',
          crabCode: (j['crabTag'] ?? j['CrabTag'] ?? widget.crabCode)?.toString(),
          deviceCode: (j['deviceCode'] ?? j['DeviceCode'] ?? widget.camera?.cameraCode)?.toString(),
          meta: {
            if ((j['deviceCode'] ?? j['DeviceCode']) != null) 'Camera': '${j['deviceCode'] ?? j['DeviceCode']}',
            if (j['confidence'] != null) 'Confidence': _pct(j['confidence']),
          },
          mediaUrls: img.startsWith('http') ? [img] : const [],
        ));
      }
    } catch (_) {}
  }

  Future<void> _addOperations(List<BoxHistoryEvent> out) async {
    try {
      final rows = await _svc.fetchAreaOperations(widget.areaId);
      for (final raw in rows) {
        if (!_opMatches(raw)) continue;
        final at = DateTime.tryParse((raw['timestamp'] ?? raw['Timestamp'] ?? '').toString());
        if (at == null) continue;
        final typeRaw = (raw['type'] ?? raw['Type'] ?? raw['title'] ?? raw['Title'] ?? '').toString();
        final notes = (raw['notes'] ?? raw['Notes'] ?? raw['description'] ?? raw['Description'] ?? '').toString();
        final actor = (raw['operatorName'] ?? raw['OperatorName'] ?? '').toString();
        final type = _opType(typeRaw, notes);
        out.add(BoxHistoryEvent(
          id: 'op-${raw['id'] ?? raw['Id'] ?? at.millisecondsSinceEpoch}',
          at: at.toLocal(),
          type: type,
          title: _opTitle(type, typeRaw),
          summary: notes,
          source: BoxHistorySource.user,
          actorName: _actorName(actor),
          actorRole: _actorRole('OPERATOR', actor),
          crabCode: widget.crabCode,
          crabId: widget.crabId,
          note: notes.trim().isEmpty ? null : notes,
          meta: _inspectionMeta(raw),
        ));
      }
    } catch (_) {}
  }

  void _addCamera(List<BoxHistoryEvent> out) {
    final cam = widget.camera;
    if (cam?.lastSeenAt == null || cam!.isOnline) return;
    out.add(BoxHistoryEvent(
      id: 'cam-${cam.id}-${cam.lastSeenAt!.millisecondsSinceEpoch}',
      at: cam.lastSeenAt!,
      type: BoxHistoryType.camera,
      title: 'Camera mất kết nối',
      summary: cam.cameraCode,
      source: BoxHistorySource.cameraAi,
      actorName: 'Hệ thống',
      actorRole: 'Hệ thống',
      deviceCode: cam.cameraCode,
      meta: {
        'Camera': cam.cameraCode,
        'Trạng thái': 'Mất kết nối',
        if (cam.lastSeenAt != null) 'Lần nhận frame cuối': _hm(cam.lastSeenAt!),
      },
    ));
  }

  bool _lifecycleInBox(CrabLifecycleEvent e) {
    final id = e.location?.boxId;
    final code = e.location?.boxCode;
    if ((id == null || id.isEmpty) && (code == null || code.isEmpty)) return true;
    return id == widget.box.id || code == widget.box.boxCode;
  }

  bool _opMatches(Map<String, dynamic> raw) {
    final ids = raw['boxIds'] ?? raw['BoxIds'];
    if (ids is List && ids.map((e) => e.toString()).contains(widget.box.id)) return true;
    final one = (raw['boxId'] ?? raw['BoxId'] ?? '').toString();
    if (one == widget.box.id || one == widget.box.boxCode) return true;
    final loc = '${raw['locationLabel'] ?? raw['LocationLabel'] ?? raw['notes'] ?? raw['Notes'] ?? ''}';
    return loc.contains(widget.box.boxCode);
  }

  List<BoxHistoryEvent> get _filtered {
    final now = DateTime.now();
    DateTime? from;
    DateTime? to;
    switch (_range) {
      case BoxHistoryRange.h24:
        from = now.subtract(const Duration(hours: 24));
      case BoxHistoryRange.d7:
        from = now.subtract(const Duration(days: 7));
      case BoxHistoryRange.d30:
        from = now.subtract(const Duration(days: 30));
      case BoxHistoryRange.d90:
        from = now.subtract(const Duration(days: 90));
      case BoxHistoryRange.all:
        break;
      case BoxHistoryRange.custom:
        from = _custom?.start;
        to = _custom == null ? null : DateTime(_custom!.end.year, _custom!.end.month, _custom!.end.day, 23, 59, 59);
    }
    final q = _query.trim().toLowerCase();
    var list = _all.where((e) {
      if (_crabChange) {
        if (e.type != BoxHistoryType.crabIn && e.type != BoxHistoryType.crabOut && e.type != BoxHistoryType.transfer) {
          return false;
        }
      } else if (_type != null && e.type != _type) {
        return false;
      }
      if (_source != BoxHistorySource.all && e.source != _source) return false;
      if (from != null && e.at.isBefore(from)) return false;
      if (to != null && e.at.isAfter(to)) return false;
      if (q.isEmpty) return true;
      final hay = [
        e.title,
        e.summary,
        e.actorName,
        e.crabCode,
        e.deviceCode,
        widget.box.boxCode,
        historyTypeLabel(e.type),
        sourceLabel(e.source),
        e.note,
      ].whereType<String>().join(' ').toLowerCase();
      return hay.contains(q);
    }).toList();
    list.sort((a, b) => _sort == BoxHistorySort.newest ? b.at.compareTo(a.at) : a.at.compareTo(b.at));
    return list;
  }

  BoxHistoryEvent? get _selected {
    final id = _selectedId;
    if (id == null) return null;
    return _filtered.where((e) => e.id == id).firstOrNull ?? _filtered.firstOrNull;
  }

  void _onSearch(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      setState(() {
        _query = v;
        _visible = 20;
      });
    });
  }

  void _clear() {
    _search.clear();
    setState(() {
      _type = null;
      _crabChange = false;
      _source = BoxHistorySource.all;
      _range = BoxHistoryRange.d7;
      _custom = null;
      _query = '';
      _visible = 20;
    });
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now,
      initialDateRange: _custom ?? DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now),
    );
    if (picked == null) return;
    setState(() {
      _range = BoxHistoryRange.custom;
      _custom = picked;
      _visible = 20;
    });
  }

  Future<void> _export(String format) async {
    final rows = _filtered;
    if (rows.isEmpty) return;
    final now = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    final stamp = '${now.year}${two(now.month)}${two(now.day)}';
    final base = 'crabsense_lichsu_${widget.box.boxCode}_$stamp';
    late final String name;
    late final String ext;
    late final Object body;
    if (format == 'csv') {
      name = '$base.csv';
      ext = 'csv';
      body = '\uFEFF${_csv(rows)}';
    } else if (format == 'xls') {
      name = '$base.xls';
      ext = 'xls';
      body = _xls(rows);
    } else {
      name = '$base.pdf';
      ext = 'pdf';
      body = _pdf(rows);
    }
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Xuất lịch sử',
      fileName: name,
      type: FileType.custom,
      allowedExtensions: [ext],
    );
    if (path == null) return;
    if (body is List<int>) {
      await File(path).writeAsBytes(body);
    } else {
      await File(path).writeAsString(body as String);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đã xuất ${rows.length} sự kiện của ${widget.box.boxCode}.')));
  }

  void _openDetail(BoxHistoryEvent e, {required bool drawer}) {
    setState(() => _selectedId = e.id);
    if (!drawer) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SizedBox(
        height: MediaQuery.of(ctx).size.height * 0.88,
        child: BoxEventDetailPanel(
          event: e,
          box: widget.box,
          areaCode: widget.areaCode,
          areaName: widget.areaName,
          rowLabel: widget.rowLabel,
          onClose: () => Navigator.pop(ctx),
          onOpenCrab: e.crabId == null
              ? null
              : () {
                  Navigator.pop(ctx);
                  widget.onOpenCrab?.call(e.crabId!);
                },
          onOpenCamera: () {
            Navigator.pop(ctx);
            widget.onOpenCamera?.call();
          },
          onOpenSensors: () {
            Navigator.pop(ctx);
            widget.onOpenSensors?.call();
          },
          onOpenAlerts: () {
            Navigator.pop(ctx);
            widget.onOpenAlerts?.call();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rows = _filtered;
    final shown = rows.take(_visible).toList();
    final selected = _selected;
    return LayoutBuilder(
      builder: (context, c) {
        final desktop = c.maxWidth >= 1100;
        final tablet = c.maxWidth >= 760;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BoxHistoryHeader(boxCode: widget.box.boxCode, onExport: _export),
            const SizedBox(height: 12),
            BoxHistorySummary(
              items: _all,
              loading: _loading,
              active: _crabChange ? BoxHistoryType.transfer : _type,
              onTap: (t) => setState(() {
                _type = t;
                _crabChange = t == BoxHistoryType.transfer;
                if (_crabChange) _type = null;
                _visible = 20;
              }),
            ),
            const SizedBox(height: 12),
            BoxHistoryFilters(
              search: _search,
              type: _type,
              source: _source,
              range: _range,
              custom: _custom,
              onSearch: _onSearch,
              onType: (v) => setState(() {
                _type = v;
                _crabChange = false;
                _visible = 20;
              }),
              onSource: (v) => setState(() {
                _source = v ?? BoxHistorySource.all;
                _visible = 20;
              }),
              onRange: (v) {
                if (v == BoxHistoryRange.custom) {
                  _pickRange();
                  return;
                }
                setState(() {
                  _range = v ?? BoxHistoryRange.all;
                  _visible = 20;
                });
              },
              onPickRange: _pickRange,
              onClear: _clear,
            ),
            const SizedBox(height: 12),
            if (_loading)
              const _HistorySkeleton()
            else if (_error != null)
              OverviewCard(
                icon: Icons.warning_amber_rounded,
                title: 'Lịch sử hộp',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Không thể tải lịch sử hộp.', style: bvText(fontWeight: FontWeight.w700, color: const Color(0xFFEF4444))),
                    const SizedBox(height: 8),
                    MgmtPrimaryButton(icon: Icons.refresh_rounded, label: 'Thử lại', height: 38, onTap: _load),
                  ],
                ),
              )
            else if (desktop)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 66,
                    child: BoxTimeline(
                      boxCode: widget.box.boxCode,
                      items: shown,
                      total: rows.length,
                      sort: _sort,
                      selectedId: selected?.id,
                      filteredEmpty: rows.isEmpty && _all.isNotEmpty,
                      allEmpty: _all.isEmpty,
                      onSort: (s) => setState(() => _sort = s),
                      onSelect: (e) => _openDetail(e, drawer: false),
                      onLoadMore: shown.length < rows.length ? () => setState(() => _visible += 20) : null,
                      onClear: _clear,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 34,
                    child: selected == null
                        ? OverviewCard(
                            icon: Icons.event_note_outlined,
                            title: 'Chi tiết sự kiện',
                            child: Text('Chọn một sự kiện để xem chi tiết.', style: bvText(color: DashboardColors.textMuted)),
                          )
                        : BoxEventDetailPanel(
                            event: selected,
                            box: widget.box,
                            areaCode: widget.areaCode,
                            areaName: widget.areaName,
                            rowLabel: widget.rowLabel,
                            onClose: () => setState(() => _selectedId = null),
                            onOpenCrab: selected.crabId == null ? null : () => widget.onOpenCrab?.call(selected.crabId!),
                            onOpenCamera: widget.onOpenCamera,
                            onOpenSensors: widget.onOpenSensors,
                            onOpenAlerts: widget.onOpenAlerts,
                          ),
                  ),
                ],
              )
            else
              BoxTimeline(
                boxCode: widget.box.boxCode,
                items: shown,
                total: rows.length,
                sort: _sort,
                selectedId: selected?.id,
                filteredEmpty: rows.isEmpty && _all.isNotEmpty,
                allEmpty: _all.isEmpty,
                compact: !tablet,
                onSort: (s) => setState(() => _sort = s),
                onSelect: (e) => _openDetail(e, drawer: true),
                onLoadMore: shown.length < rows.length ? () => setState(() => _visible += 20) : null,
                onClear: _clear,
              ),
          ],
        );
      },
    );
  }

  String _csv(List<BoxHistoryEvent> rows) {
    String cell(String v) => v.contains(',') || v.contains('"') ? '"${v.replaceAll('"', '""')}"' : v;
    final sb = StringBuffer()..writeln('Thoi gian,Loai,Tieu de,Tom tat,Cua,Nguon,Nguoi thuc hien,Ghi chu');
    for (final e in rows) {
      sb.writeln([
        cell(fmtDateTimeVn(e.at)),
        cell(historyTypeLabel(e.type)),
        cell(e.title),
        cell(e.summary),
        cell(e.crabCode ?? ''),
        cell(sourceLabel(e.source)),
        cell(e.actorName ?? ''),
        cell(e.note ?? ''),
      ].join(','));
    }
    return sb.toString();
  }

  String _xls(List<BoxHistoryEvent> rows) {
    String esc(String v) => v.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;');
    final buf = StringBuffer();
    void row(List<String> cols) {
      buf.write('<Row>');
      for (final c in cols) {
        buf.write('<Cell><Data ss:Type="String">${esc(c)}</Data></Cell>');
      }
      buf.writeln('</Row>');
    }
    row(['BOX', widget.box.boxCode]);
    row(['Thời gian', 'Loại', 'Tiêu đề', 'Tóm tắt', 'Cua', 'Nguồn', 'Người thực hiện']);
    for (final e in rows) {
      row([fmtDateTimeVn(e.at), historyTypeLabel(e.type), e.title, e.summary, e.crabCode ?? '', sourceLabel(e.source), e.actorName ?? '']);
    }
    return '''<?xml version="1.0"?>
<?mso-application progid="Excel.Sheet"?>
<Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet" xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet">
<Worksheet ss:Name="Lich su"><Table>
$buf
</Table></Worksheet></Workbook>''';
  }

  List<int> _pdf(List<BoxHistoryEvent> rows) {
    final lines = <String>[
      'CrabSense - Lich su ${widget.box.boxCode}',
      'Tong: ${rows.length}',
      '',
      for (final e in rows) '${fmtDateTimeVn(e.at)} | ${e.title} | ${e.summary}',
    ];
    final content = StringBuffer('BT /F1 9 Tf 40 800 Td\n');
    for (var i = 0; i < lines.length && i < 48; i++) {
      final y = i == 0 ? '' : '0 -13 Td\n';
      final safe = lines[i].replaceAll('\\', '\\\\').replaceAll('(', '\\(').replaceAll(')', '\\)');
      content.write('$y($safe) Tj\n');
    }
    content.write('ET');
    final stream = content.toString();
    final objs = <String>[
      '1 0 obj << /Type /Catalog /Pages 2 0 R >> endobj\n',
      '2 0 obj << /Type /Pages /Kids [3 0 R] /Count 1 >> endobj\n',
      '3 0 obj << /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] /Contents 4 0 R /Resources << /Font << /F1 5 0 R >> >> >> endobj\n',
      '4 0 obj << /Length ${stream.length} >> stream\n$stream\nendstream endobj\n',
      '5 0 obj << /Type /Font /Subtype /Type1 /BaseFont /Helvetica >> endobj\n',
    ];
    final buf = StringBuffer('%PDF-1.4\n');
    final offsets = <int>[];
    for (final o in objs) {
      offsets.add(buf.length);
      buf.write(o);
    }
    final xref = buf.length;
    buf.write('xref\n0 6\n0000000000 65535 f \n');
    for (final off in offsets) {
      buf.write('${off.toString().padLeft(10, '0')} 00000 n \n');
    }
    buf.write('trailer << /Size 6 /Root 1 0 R >>\nstartxref\n$xref\n%%EOF');
    return buf.toString().codeUnits;
  }
}

class BoxHistoryHeader extends StatelessWidget {
  const BoxHistoryHeader({super.key, required this.boxCode, required this.onExport});
  final String boxCode;
  final ValueChanged<String> onExport;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Lịch sử & Nhật ký hộp', style: bvText(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text('Theo dõi toàn bộ sự kiện, thay đổi và hoạt động của $boxCode.', style: bvText(fontSize: 13, color: DashboardColors.textMuted)),
            ],
          ),
        ),
        PopupMenuButton<String>(
          tooltip: 'Xuất lịch sử',
          onSelected: onExport,
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'csv', child: Text('CSV')),
            PopupMenuItem(value: 'xls', child: Text('Excel')),
            PopupMenuItem(value: 'pdf', child: Text('PDF')),
          ],
          child: Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: DashboardColors.brand.withValues(alpha: 0.55)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.download_rounded, size: 17, color: DashboardColors.brand),
                const SizedBox(width: 6),
                Text('Xuất lịch sử', style: bvText(fontSize: 12.5, fontWeight: FontWeight.w700, color: DashboardColors.brand)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class BoxHistorySummary extends StatelessWidget {
  const BoxHistorySummary({
    super.key,
    required this.items,
    required this.loading,
    required this.active,
    required this.onTap,
  });

  final List<BoxHistoryEvent> items;
  final bool loading;
  final BoxHistoryType? active;
  final ValueChanged<BoxHistoryType?> onTap;

  @override
  Widget build(BuildContext context) {
    if (loading && items.isEmpty) {
      return Row(children: [
        for (var i = 0; i < 5; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(child: Container(height: 86, decoration: BoxDecoration(color: DashboardColors.lightMint, borderRadius: BorderRadius.circular(14)))),
        ],
      ]);
    }
    final now = DateTime.now();
    final d7 = now.subtract(const Duration(days: 7));
    final d14 = now.subtract(const Duration(days: 14));
    String delta(bool Function(BoxHistoryEvent) test) {
      final cur = items.where((e) => test(e) && e.at.isAfter(d7)).length;
      final prev = items.where((e) => test(e) && e.at.isAfter(d14) && !e.at.isAfter(d7)).length;
      if (prev == 0 && cur == 0) return 'Không đổi';
      if (prev == 0) return '↑ $cur so với 7 ngày trước';
      final pct = (((cur - prev) / prev) * 100).round();
      if (pct == 0) return 'Không đổi';
      return pct > 0 ? '↑ $pct% so với 7 ngày trước' : '↓ ${-pct}% so với 7 ngày trước';
    }

    String countDelta(bool Function(BoxHistoryEvent) test) {
      final cur = items.where((e) => test(e) && e.at.isAfter(d7)).length;
      final prev = items.where((e) => test(e) && e.at.isAfter(d14) && !e.at.isAfter(d7)).length;
      final d = cur - prev;
      if (d == 0) return 'Không đổi';
      return d > 0 ? '↑ $d so với 7 ngày trước' : '↓ ${-d} so với 7 ngày trước';
    }

    final cards = [
      _Kpi('TỔNG SỰ KIỆN', '${items.length}', delta((_) => true), DashboardColors.brand, active == null, () => onTap(null)),
      _Kpi('CHO ĂN', '${items.where((e) => e.type == BoxHistoryType.feeding).length}', countDelta((e) => e.type == BoxHistoryType.feeding), DashboardColors.brand, active == BoxHistoryType.feeding, () => onTap(BoxHistoryType.feeding)),
      _Kpi('KIỂM TRA HỘP', '${items.where((e) => e.type == BoxHistoryType.inspection).length}', countDelta((e) => e.type == BoxHistoryType.inspection), const Color(0xFF2495E8), active == BoxHistoryType.inspection, () => onTap(BoxHistoryType.inspection)),
      _Kpi('CẢNH BÁO', '${items.where((e) => e.type == BoxHistoryType.alert).length}', countDelta((e) => e.type == BoxHistoryType.alert), const Color(0xFFF5B700), active == BoxHistoryType.alert, () => onTap(BoxHistoryType.alert)),
      _Kpi('THAY ĐỔI CUA', '${items.where((e) => e.type == BoxHistoryType.crabIn || e.type == BoxHistoryType.crabOut || e.type == BoxHistoryType.transfer).length}', countDelta((e) => e.type == BoxHistoryType.crabIn || e.type == BoxHistoryType.crabOut || e.type == BoxHistoryType.transfer), const Color(0xFF0D9488), active == BoxHistoryType.transfer, () => onTap(BoxHistoryType.transfer)),
    ];
    return LayoutBuilder(builder: (context, c) {
      if (c.maxWidth < 760) {
        return Wrap(spacing: 10, runSpacing: 10, children: cards.map((e) => SizedBox(width: (c.maxWidth - 10) / 2, child: e)).toList());
      }
      return Row(children: [
        for (var i = 0; i < cards.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(child: cards[i]),
        ],
      ]);
    });
  }
}

class _Kpi extends StatelessWidget {
  const _Kpi(this.label, this.value, this.hint, this.color, this.active, this.onTap);
  final String label;
  final String value;
  final String hint;
  final Color color;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? DashboardColors.lightMint : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: active ? DashboardColors.brand.withValues(alpha: 0.45) : DashboardColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: bvText(fontSize: 11, fontWeight: FontWeight.w800, color: DashboardColors.textMuted)),
              const SizedBox(height: 4),
              Text(value, style: bvText(fontSize: 26, fontWeight: FontWeight.w800, color: color)),
              Text(hint, style: bvText(fontSize: 11.5, color: DashboardColors.textMuted)),
            ],
          ),
        ),
      ),
    );
  }
}

class BoxHistoryFilters extends StatelessWidget {
  const BoxHistoryFilters({
    super.key,
    required this.search,
    required this.type,
    required this.source,
    required this.range,
    required this.custom,
    required this.onSearch,
    required this.onType,
    required this.onSource,
    required this.onRange,
    required this.onPickRange,
    required this.onClear,
  });

  final TextEditingController search;
  final BoxHistoryType? type;
  final BoxHistorySource source;
  final BoxHistoryRange range;
  final DateTimeRange? custom;
  final ValueChanged<String> onSearch;
  final ValueChanged<BoxHistoryType?> onType;
  final ValueChanged<BoxHistorySource?> onSource;
  final ValueChanged<BoxHistoryRange?> onRange;
  final VoidCallback onPickRange;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final shownRange = _displayRange();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 240,
          height: 40,
          child: TextField(
            controller: search,
            onChanged: onSearch,
            style: bvText(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Tìm kiếm sự kiện...',
              prefixIcon: const Icon(Icons.search_rounded, size: 18),
              filled: true,
              fillColor: Colors.white,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: DashboardColors.cardBorder)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: DashboardColors.cardBorder)),
            ),
          ),
        ),
        _drop<BoxHistoryType?>(
          value: type,
          items: [
            const DropdownMenuItem(value: null, child: Text('Tất cả loại sự kiện')),
            ...BoxHistoryType.values.map((e) => DropdownMenuItem(value: e, child: Text(historyTypeLabel(e)))),
          ],
          onChanged: onType,
        ),
        _drop<BoxHistorySource>(
          value: source,
          items: BoxHistorySource.values.map((e) => DropdownMenuItem(value: e, child: Text(e == BoxHistorySource.all ? 'Tất cả nguồn' : sourceLabel(e)))).toList(),
          onChanged: onSource,
        ),
        _drop<BoxHistoryRange>(
          value: range,
          items: const [
            DropdownMenuItem(value: BoxHistoryRange.h24, child: Text('24 giờ')),
            DropdownMenuItem(value: BoxHistoryRange.d7, child: Text('7 ngày qua')),
            DropdownMenuItem(value: BoxHistoryRange.d30, child: Text('30 ngày')),
            DropdownMenuItem(value: BoxHistoryRange.d90, child: Text('90 ngày')),
            DropdownMenuItem(value: BoxHistoryRange.all, child: Text('Toàn bộ')),
            DropdownMenuItem(value: BoxHistoryRange.custom, child: Text('Tùy chỉnh')),
          ],
          onChanged: onRange,
        ),
        if (shownRange != null)
          InkWell(
            onTap: onPickRange,
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: DashboardColors.cardBorder),
              ),
              alignment: Alignment.center,
              child: Text('${fmtDateVn(shownRange.start)} → ${fmtDateVn(shownRange.end)}', style: bvText(fontSize: 12.5, fontWeight: FontWeight.w600)),
            ),
          ),
        TextButton(onPressed: onClear, child: Text('Xóa lọc', style: bvText(fontWeight: FontWeight.w700, color: DashboardColors.brand))),
      ],
    );
  }

  DateTimeRange? _displayRange() {
    final now = DateTime.now();
    final end = DateTime(now.year, now.month, now.day);
    switch (range) {
      case BoxHistoryRange.h24:
        return DateTimeRange(start: now.subtract(const Duration(hours: 24)), end: now);
      case BoxHistoryRange.d7:
        return DateTimeRange(start: end.subtract(const Duration(days: 6)), end: end);
      case BoxHistoryRange.d30:
        return DateTimeRange(start: end.subtract(const Duration(days: 29)), end: end);
      case BoxHistoryRange.d90:
        return DateTimeRange(start: end.subtract(const Duration(days: 89)), end: end);
      case BoxHistoryRange.custom:
        return custom;
      case BoxHistoryRange.all:
        return null;
    }
  }

  Widget _drop<T>({required T value, required List<DropdownMenuItem<T>> items, required ValueChanged<T?> onChanged}) {
    return SizedBox(
      width: 188,
      height: 40,
      child: InputDecorator(
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: DashboardColors.cardBorder)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: DashboardColors.cardBorder)),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            value: value,
            isExpanded: true,
            items: items,
            onChanged: onChanged,
            style: bvText(fontSize: 12.5, color: DashboardColors.textPrimary),
          ),
        ),
      ),
    );
  }
}

class BoxTimeline extends StatelessWidget {
  const BoxTimeline({
    super.key,
    required this.boxCode,
    required this.items,
    required this.total,
    required this.sort,
    required this.onSort,
    required this.onSelect,
    required this.filteredEmpty,
    required this.allEmpty,
    this.selectedId,
    this.compact = false,
    this.onLoadMore,
    this.onClear,
  });

  final String boxCode;
  final List<BoxHistoryEvent> items;
  final int total;
  final BoxHistorySort sort;
  final ValueChanged<BoxHistorySort> onSort;
  final ValueChanged<BoxHistoryEvent> onSelect;
  final bool filteredEmpty;
  final bool allEmpty;
  final String? selectedId;
  final bool compact;
  final VoidCallback? onLoadMore;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: mgmtCardDeco(radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.timeline_rounded, size: 16, color: DashboardColors.brand),
              const SizedBox(width: 7),
              Text('Dòng thời gian', style: bvText(fontSize: 14, fontWeight: FontWeight.w800)),
              const Spacer(),
              MgmtInlineSort<BoxHistorySort>(
                value: sort,
                items: const [(BoxHistorySort.newest, 'Mới nhất trước'), (BoxHistorySort.oldest, 'Cũ nhất trước')],
                onChanged: onSort,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (allEmpty)
            _empty(Icons.schedule_outlined, 'Chưa có lịch sử', 'Các hoạt động của $boxCode sẽ xuất hiện tại đây.', null)
          else if (filteredEmpty)
            _empty(Icons.search_off_rounded, 'Không tìm thấy sự kiện', 'Không có lịch sử phù hợp với bộ lọc.', onClear)
          else ...[
            for (final g in _groups()) ...[
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 8),
                child: Text(g.$1, style: bvText(fontSize: 13, fontWeight: FontWeight.w800)),
              ),
              for (final e in g.$2)
                BoxEventRow(event: e, selected: e.id == selectedId, compact: compact, onTap: () => onSelect(e)),
            ],
            const SizedBox(height: 10),
            if (onLoadMore != null)
              Center(child: MgmtOutlineButton(icon: Icons.expand_more_rounded, label: 'Tải thêm sự kiện', onTap: onLoadMore))
            else
              Text('Đã hiển thị toàn bộ lịch sử của $boxCode.', textAlign: TextAlign.center, style: bvText(fontSize: 12, color: DashboardColors.textMuted)),
            if (onLoadMore != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('Đã hiển thị ${items.length} / $total sự kiện', textAlign: TextAlign.center, style: bvText(fontSize: 12, color: DashboardColors.textMuted)),
              ),
          ],
        ],
      ),
    );
  }

  List<(String, List<BoxHistoryEvent>)> _groups() {
    final map = <String, List<BoxHistoryEvent>>{};
    final order = <String>[];
    for (final e in items) {
      final key = '${fmtDateVn(e.at)} — ${_weekday(e.at)}';
      if (map.putIfAbsent(key, () => []).isEmpty) order.add(key);
      map[key]!.add(e);
    }
    return [for (final k in order) (k, map[k]!)];
  }

  Widget _empty(IconData icon, String title, String msg, VoidCallback? clear) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          Icon(icon, size: 36, color: DashboardColors.brand),
          const SizedBox(height: 8),
          Text(title, style: bvText(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(msg, textAlign: TextAlign.center, style: bvText(fontSize: 12.5, color: DashboardColors.textMuted)),
          if (clear != null) OverviewLinkButton(label: 'Xóa bộ lọc', onTap: clear),
        ],
      ),
    );
  }
}

class BoxEventRow extends StatelessWidget {
  const BoxEventRow({super.key, required this.event, required this.selected, required this.onTap, this.compact = false});
  final BoxHistoryEvent event;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = historyTypeColor(event.type);
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF3FBF8) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 46,
              child: Text(_hm(event.at), style: bvText(fontSize: 12, fontWeight: FontWeight.w700, color: DashboardColors.textMuted)),
            ),
            Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 10),
            Icon(historyTypeIcon(event.type), size: 16, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: bvText(fontSize: 13, fontWeight: FontWeight.w700)),
                  if (event.summary.isNotEmpty)
                    Text(event.summary, maxLines: compact ? 2 : 1, overflow: TextOverflow.ellipsis, style: bvText(fontSize: 12, color: DashboardColors.textMuted)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(event.actorName ?? sourceLabel(event.source), style: bvText(fontSize: 11.5, fontWeight: FontWeight.w700)),
                if ((event.actorRole ?? '').isNotEmpty)
                  Text(event.actorRole!, style: bvText(fontSize: 11, color: DashboardColors.textMuted)),
              ],
            ),
            const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }
}

class BoxEventDetailPanel extends StatelessWidget {
  const BoxEventDetailPanel({
    super.key,
    required this.event,
    required this.box,
    required this.areaCode,
    required this.areaName,
    required this.rowLabel,
    this.onClose,
    this.onOpenCrab,
    this.onOpenCamera,
    this.onOpenSensors,
    this.onOpenAlerts,
  });

  final BoxHistoryEvent event;
  final BoxRecord box;
  final String areaCode;
  final String areaName;
  final String rowLabel;
  final VoidCallback? onClose;
  final VoidCallback? onOpenCrab;
  final VoidCallback? onOpenCamera;
  final VoidCallback? onOpenSensors;
  final VoidCallback? onOpenAlerts;

  @override
  Widget build(BuildContext context) {
    final e = event;
    return OverviewCard(
      icon: historyTypeIcon(e.type),
      iconColor: historyTypeColor(e.type),
      title: 'Chi tiết sự kiện',
      trailing: IconButton(onPressed: onClose, icon: const Icon(Icons.close_rounded, size: 18), visualDensity: VisualDensity.compact),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(e.title, style: bvText(fontSize: 15, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(fmtDateTimeVn(e.at), style: bvText(fontSize: 12.5, color: DashboardColors.textMuted)),
          const SizedBox(height: 8),
          MgmtStatusBadge(label: historyTypeLabel(e.type), color: historyTypeColor(e.type)),
          const SizedBox(height: 12),
          _kv('BOX liên quan', box.boxCode),
          if ((e.crabCode ?? '').isNotEmpty) _kv('Cua trong hộp', e.crabCode!),
          if (areaCode.isNotEmpty) _kv('Khu', areaCode),
          if (rowLabel.isNotEmpty) _kv('Dãy', rowLabel),
          if ((box.position ?? '').isNotEmpty) _kv('Vị trí', box.position!),
          if ((e.deviceCode ?? '').isNotEmpty) _kv(e.type == BoxHistoryType.camera ? 'Camera' : 'Thiết bị', e.deviceCode!),
          if ((e.actorName ?? '').isNotEmpty) _kv('Người thực hiện', e.actorName!),
          if ((e.actorRole ?? '').isNotEmpty) _kv('Vai trò', e.actorRole!),
          _kv('Nguồn', sourceLabel(e.source)),
          if ((e.note ?? '').isNotEmpty) _kv('Ghi chú', e.note!),
          for (final en in e.meta.entries)
            if (!(e.type == BoxHistoryType.inspection && const {'Mức ăn', 'Sức khỏe', 'Vận động'}.contains(en.key)))
              _kv(en.key, en.value),
          if (e.before.isNotEmpty || e.after.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Thay đổi', style: bvText(fontSize: 12.5, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            for (final k in {...e.before.keys, ...e.after.keys})
              _kv(k, '${e.before[k] ?? '—'}  →  ${e.after[k] ?? '—'}'),
          ],
          if (e.type == BoxHistoryType.inspection) ...[
            const SizedBox(height: 10),
            _inspectionBoxes(e),
          ],
          const SizedBox(height: 12),
          Text('Hình ảnh', style: bvText(fontSize: 12.5, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          if (e.mediaUrls.isEmpty)
            Text('Không có hình ảnh cho sự kiện này.', style: bvText(fontSize: 12.5, color: DashboardColors.textMuted))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final url in e.mediaUrls.take(3))
                  GestureDetector(
                    onTap: () => _lightbox(context, url),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(url, width: 84, height: 64, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(width: 84, height: 64, color: DashboardColors.lightMint, child: const Icon(Icons.image_outlined))),
                    ),
                  ),
              ],
            ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              if (e.crabId != null) OverviewLinkButton(label: 'Xem chi tiết cua', onTap: onOpenCrab),
              if (e.type == BoxHistoryType.camera) OverviewLinkButton(label: 'Xem Camera AI', onTap: onOpenCamera),
              if (e.type == BoxHistoryType.sensor) OverviewLinkButton(label: 'Xem cảm biến', onTap: onOpenSensors),
              if (e.type == BoxHistoryType.alert) OverviewLinkButton(label: 'Xem cảnh báo', onTap: onOpenAlerts),
            ],
          ),
        ],
      ),
    );
  }

  Widget _inspectionBoxes(BoxHistoryEvent e) {
    final eat = e.meta['Mức ăn'] ?? e.meta['feedingPercent'];
    final health = e.meta['Sức khỏe'] ?? e.meta['healthStatus'];
    final act = e.meta['Vận động'] ?? e.meta['activityScore'];
    Widget box(String k, String v, String s, Color c) => Expanded(
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: c.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(10), border: Border.all(color: DashboardColors.cardBorder)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(k, style: bvText(fontSize: 10.5, fontWeight: FontWeight.w800, color: DashboardColors.textMuted)),
                const SizedBox(height: 4),
                Text(v, style: bvText(fontSize: 16, fontWeight: FontWeight.w800)),
                Text('● $s', style: bvText(fontSize: 11, color: c, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        );
    return Row(
      children: [
        if (eat != null) box('MỨC ĂN', eat, _eatBand(eat), DashboardColors.brand),
        if (eat != null && (health != null || act != null)) const SizedBox(width: 8),
        if (health != null) box('SỨC KHỎE', _healthLabel(health), _healthLabel(health), DashboardColors.brand),
        if (health != null && act != null) const SizedBox(width: 8),
        if (act != null) box('VẬN ĐỘNG', act.contains('/') ? act : '$act / 100', _actBand(act), const Color(0xFF2495E8)),
      ],
    );
  }

  void _lightbox(BuildContext context, String url) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            InteractiveViewer(child: Image.network(url, fit: BoxFit.contain)),
            Positioned(right: 4, top: 4, child: IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close, color: Colors.white))),
          ],
        ),
      ),
    );
  }
}

class _HistorySkeleton extends StatelessWidget {
  const _HistorySkeleton();
  @override
  Widget build(BuildContext context) {
    Widget box(double h) => Container(height: h, decoration: BoxDecoration(color: DashboardColors.lightMint, borderRadius: BorderRadius.circular(12)));
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 66, child: Column(children: [for (var i = 0; i < 6; i++) Padding(padding: const EdgeInsets.only(bottom: 8), child: box(48))])),
        const SizedBox(width: 12),
        Expanded(flex: 34, child: box(280)),
      ],
    );
  }
}

Widget _kv(String k, String v) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 132, child: Text(k, style: bvText(fontSize: 12.5, color: DashboardColors.textMuted))),
        Expanded(child: Text(v, style: bvText(fontSize: 12.5, fontWeight: FontWeight.w700))),
      ],
    ),
  );
}

String historyTypeLabel(BoxHistoryType t) => switch (t) {
      BoxHistoryType.feeding => 'Cho ăn',
      BoxHistoryType.inspection => 'Kiểm tra hộp',
      BoxHistoryType.crabIn => 'Cua vào hộp',
      BoxHistoryType.crabOut => 'Cua ra khỏi hộp',
      BoxHistoryType.transfer => 'Chuyển cua',
      BoxHistoryType.camera => 'Camera AI',
      BoxHistoryType.sensor => 'Cảm biến',
      BoxHistoryType.alert => 'Cảnh báo',
      BoxHistoryType.device => 'Thiết bị',
      BoxHistoryType.maintenance => 'Bảo trì',
      BoxHistoryType.boxUpdated => 'Chỉnh sửa hộp',
      BoxHistoryType.system => 'Hệ thống',
    };

Color historyTypeColor(BoxHistoryType t) => switch (t) {
      BoxHistoryType.feeding => DashboardColors.brand,
      BoxHistoryType.inspection => const Color(0xFF2495E8),
      BoxHistoryType.crabIn || BoxHistoryType.crabOut || BoxHistoryType.transfer => const Color(0xFF0D9488),
      BoxHistoryType.camera => const Color(0xFF7C3AED),
      BoxHistoryType.sensor => const Color(0xFF0EA5E9),
      BoxHistoryType.alert => const Color(0xFFF5B700),
      BoxHistoryType.device => const Color(0xFFEF4444),
      BoxHistoryType.maintenance => const Color(0xFFF5B700),
      BoxHistoryType.boxUpdated || BoxHistoryType.system => const Color(0xFF94A3B8),
    };

IconData historyTypeIcon(BoxHistoryType t) => switch (t) {
      BoxHistoryType.feeding => Icons.restaurant_rounded,
      BoxHistoryType.inspection => Icons.search_rounded,
      BoxHistoryType.crabIn => Icons.south_west_rounded,
      BoxHistoryType.crabOut => Icons.north_east_rounded,
      BoxHistoryType.transfer => Icons.swap_horiz_rounded,
      BoxHistoryType.camera => Icons.videocam_outlined,
      BoxHistoryType.sensor => Icons.thermostat_outlined,
      BoxHistoryType.alert => Icons.warning_amber_rounded,
      BoxHistoryType.device => Icons.developer_board_outlined,
      BoxHistoryType.maintenance => Icons.build_outlined,
      BoxHistoryType.boxUpdated => Icons.edit_outlined,
      BoxHistoryType.system => Icons.settings_suggest_outlined,
    };

String sourceLabel(BoxHistorySource s) => switch (s) {
      BoxHistorySource.all => 'Tất cả nguồn',
      BoxHistorySource.user => 'Người dùng',
      BoxHistorySource.cameraAi => 'Camera AI',
      BoxHistorySource.sensor => 'Sensor',
      BoxHistorySource.controller => 'Controller',
      BoxHistorySource.esp32 => 'ESP32',
      BoxHistorySource.system => 'Hệ thống',
    };

BoxHistoryType _fromLifecycle(CrabLifecycleEventType t) => switch (t) {
      CrabLifecycleEventType.feeding => BoxHistoryType.feeding,
      CrabLifecycleEventType.health => BoxHistoryType.inspection,
      CrabLifecycleEventType.transfer => BoxHistoryType.transfer,
      CrabLifecycleEventType.ai => BoxHistoryType.camera,
      CrabLifecycleEventType.alertCreated || CrabLifecycleEventType.alertResolved => BoxHistoryType.alert,
      CrabLifecycleEventType.profile => BoxHistoryType.boxUpdated,
      CrabLifecycleEventType.harvested || CrabLifecycleEventType.harvestReady || CrabLifecycleEventType.dead => BoxHistoryType.crabOut,
      CrabLifecycleEventType.created => BoxHistoryType.crabIn,
      _ => BoxHistoryType.system,
    };

BoxHistoryType _boxChangeType(String oldS, String newS, String reason) {
  final hay = '$oldS $newS $reason'.toLowerCase();
  if (hay.contains('lock') || hay.contains('maint') || hay.contains('bảo trì') || hay.contains('khóa')) return BoxHistoryType.maintenance;
  return BoxHistoryType.boxUpdated;
}

BoxHistoryType _opType(String type, String notes) {
  final hay = '$type $notes'.toLowerCase();
  if (hay.contains('feed') || hay.contains('cho ăn') || hay.contains('ăn')) return BoxHistoryType.feeding;
  if (hay.contains('inspect') || hay.contains('kiểm tra') || hay.contains('health')) return BoxHistoryType.inspection;
  if (hay.contains('alert') || hay.contains('cảnh báo')) return BoxHistoryType.alert;
  if (hay.contains('camera')) return BoxHistoryType.camera;
  if (hay.contains('sensor') || hay.contains('nhiệt') || hay.contains('ph')) return BoxHistoryType.sensor;
  if (hay.contains('maint') || hay.contains('bảo trì')) return BoxHistoryType.maintenance;
  if (hay.contains('transfer') || hay.contains('chuyển')) return BoxHistoryType.transfer;
  return BoxHistoryType.inspection;
}

String _opTitle(BoxHistoryType type, String raw) {
  if (type == BoxHistoryType.inspection) return 'Kiểm tra hộp';
  if (type == BoxHistoryType.feeding) return 'Cho ăn';
  final t = raw.trim();
  if (t.isEmpty || RegExp(r'^[a-z0-9_]+$', caseSensitive: false).hasMatch(t)) return historyTypeLabel(type);
  return t;
}

String _humanTitle(String title, CrabLifecycleEventType type) {
  final t = title.trim();
  if (t.toLowerCase() == 'inspection') return 'Kiểm tra hộp';
  if (t.toLowerCase() == 'operator') return 'Kiểm tra hộp';
  if (RegExp(r'^[a-z0-9_]+$').hasMatch(t)) return type.label;
  return t.isEmpty ? type.label : t;
}

String _alertTitle(String title, String hay) {
  if (hay.contains('camera') && hay.contains('mất')) return 'Camera mất kết nối';
  if (hay.contains('nhiệt') || hay.contains('temp')) return 'Nhiệt độ vượt ngưỡng';
  if (hay.contains('ph')) return 'pH vượt ngưỡng';
  if (hay.contains('cảm biến') && hay.contains('mất')) return 'Cảm biến realtime mất kết nối';
  final t = title.trim();
  if (t.isEmpty || RegExp(r'^[a-z0-9_]+$').hasMatch(t)) return 'Cảnh báo';
  return t.split('(').first.trim();
}

String _alertStatus(String raw) {
  final s = raw.toLowerCase();
  return switch (s) {
    'acknowledged' || 'ack' => 'Đã xác nhận',
    'resolved' || 'closed' => 'Đã xử lý',
    'recovered' => 'Đã khôi phục',
    _ => 'Đang mở',
  };
}

String _aiSummary(String type, Map<String, dynamic> j) {
  final t = type.toLowerCase();
  if (t.contains('empty')) return 'Không phát hiện cua';
  if (t.contains('feed')) return 'Phát hiện hoạt động ăn';
  if (t.contains('abnormal')) return 'Cua di chuyển bất thường';
  if (t.contains('occupancy') || t.contains('health') || t.contains('normal')) return 'Cua hoạt động bình thường';
  final cam = (j['deviceCode'] ?? j['DeviceCode'] ?? '').toString();
  return cam.isEmpty ? 'Phát hiện AI' : cam;
}

BoxHistorySource _sourceOf(String raw, String actor) {
  final s = raw.toLowerCase();
  if (s.contains('camera') || s.contains('ai')) return BoxHistorySource.cameraAi;
  if (s.contains('sensor')) return BoxHistorySource.sensor;
  if (s.contains('controller')) return BoxHistorySource.controller;
  if (s.contains('esp32')) return BoxHistorySource.esp32;
  if (s.contains('manual') || actor.trim().isNotEmpty && actor.toLowerCase() != 'system') return BoxHistorySource.user;
  return BoxHistorySource.system;
}

String _actorName(String raw) {
  final s = raw.trim();
  if (s.isEmpty || s.toLowerCase() == 'system' || s.toLowerCase() == 'operator') return 'Hệ thống';
  if (s.toLowerCase() == 'admin') return 'Quản trị';
  return s;
}

String _actorRole(String type, String name) {
  final t = '$type $name'.toLowerCase();
  if (t.contains('admin')) return 'Quản trị';
  if (t.contains('operator') || t.contains('staff') || t.contains('user') || t.contains('manual')) return 'Nhân viên vận hành';
  if (t.contains('system') || t.contains('ai') || name.trim().isEmpty) return 'Hệ thống';
  return 'Nhân viên vận hành';
}

String _fieldLabel(String raw) {
  final s = raw.toLowerCase();
  return switch (s) {
    'position' => 'Vị trí',
    'status' => 'Trạng thái',
    'feedingpercent' || 'eatpercent' => 'Mức ăn',
    'healthstatus' || 'health' => 'Sức khỏe',
    'activityscore' || 'activity' => 'Vận động',
    'weight' || 'weightgram' => 'Cân nặng',
    _ => raw,
  };
}

Map<String, String> _inspectionMeta(Map<String, dynamic> raw) {
  final out = <String, String>{};
  void put(String key, List<String> names) {
    for (final n in names) {
      final v = raw[n];
      if (v != null && '$v'.isNotEmpty && '$v' != 'null') {
        out[key] = '$v';
        return;
      }
    }
  }
  put('Mức ăn', ['feedingPercent', 'FeedingPercent', 'eatPercent']);
  put('Sức khỏe', ['healthStatus', 'HealthStatus', 'health']);
  put('Vận động', ['activityScore', 'ActivityScore', 'activity']);
  return out;
}

String _eatBand(String raw) {
  final n = int.tryParse(raw.replaceAll(RegExp(r'[^0-9]'), ''));
  if (n == null) return '—';
  if (n >= 80) return 'Tốt';
  if (n >= 50) return 'Bình thường';
  return 'Thấp';
}

String _healthLabel(String raw) {
  final s = raw.toLowerCase();
  if (s.contains('health') || s.contains('good') || s.contains('khỏe') || s.contains('normal') || s.contains('bình')) return 'Bình thường';
  if (s.contains('watch') || s.contains('theo')) return 'Theo dõi';
  if (s.contains('alert') || s.contains('weak') || s.contains('yếu')) return 'Cảnh báo';
  if (RegExp(r'^[a-z_]+$').hasMatch(s)) return 'Bình thường';
  return raw;
}

String _actBand(String raw) {
  final n = int.tryParse(raw.replaceAll(RegExp(r'[^0-9]'), ''));
  if (n == null) return '—';
  if (n <= 30) return 'Thấp';
  if (n <= 70) return 'Bình thường';
  return 'Cao';
}

String _weekday(DateTime at) {
  const names = ['', 'Thứ Hai', 'Thứ Ba', 'Thứ Tư', 'Thứ Năm', 'Thứ Sáu', 'Thứ Bảy', 'Chủ Nhật'];
  return names[at.weekday];
}

String _hm(DateTime at) {
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(at.hour)}:${two(at.minute)}';
}

String _pct(Object? v) {
  if (v is num) {
    final n = v <= 1 ? v * 100 : v;
    return '${n.round()}%';
  }
  return '$v';
}
