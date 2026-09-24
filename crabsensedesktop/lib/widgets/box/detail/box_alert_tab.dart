import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../models/production_models.dart';
import '../../../services/crab_profile_service.dart';
import '../../../theme/dashboard_theme.dart';
import '../../crab/crab_overview_cards.dart';
import '../../shared/mgmt_ui.dart';

enum BoxAlertStatus { open, acknowledged, inProgress, resolved, recovered }

enum BoxAlertSeverity { critical, high, medium, low }

enum BoxAlertSource { all, sensor, camera, controller, esp32, ai, environment, box, crab }

enum BoxAlertDateRange { h24, d7, d30, d90, all, custom }

class BoxAlertItem {
  const BoxAlertItem({
    required this.id,
    required this.title,
    required this.message,
    required this.severity,
    required this.status,
    required this.source,
    required this.startedAt,
    this.sourceCode,
    this.deviceType,
    this.metric,
    this.valueText,
    this.thresholdText,
    this.unit,
    this.lastDataAt,
    this.acknowledgedAt,
    this.acknowledgedBy,
    this.resolvedAt,
    this.resolvedBy,
    this.recoveredAt,
    this.cause,
    this.suggestion,
    this.note,
    this.resolutionCode,
    this.resolutionNote,
    this.sharedSensorNote,
    this.crabTag,
    this.cameraCode,
    this.confidence,
    this.imageUrl,
    this.correlationId,
  });

  final String id;
  final String title;
  final String message;
  final BoxAlertSeverity severity;
  final BoxAlertStatus status;
  final BoxAlertSource source;
  final DateTime startedAt;
  final String? sourceCode;
  final String? deviceType;
  final String? metric;
  final String? valueText;
  final String? thresholdText;
  final String? unit;
  final DateTime? lastDataAt;
  final DateTime? acknowledgedAt;
  final String? acknowledgedBy;
  final DateTime? resolvedAt;
  final String? resolvedBy;
  final DateTime? recoveredAt;
  final String? cause;
  final String? suggestion;
  final String? note;
  final String? resolutionCode;
  final String? resolutionNote;
  final String? sharedSensorNote;
  final String? crabTag;
  final String? cameraCode;
  final int? confidence;
  final String? imageUrl;
  final String? correlationId;

  DateTime? get endedAt => recoveredAt ?? resolvedAt;

  bool get isOpen => status == BoxAlertStatus.open || status == BoxAlertStatus.acknowledged || status == BoxAlertStatus.inProgress;

  BoxAlertItem copyWith({
    BoxAlertStatus? status,
    DateTime? acknowledgedAt,
    String? acknowledgedBy,
    DateTime? resolvedAt,
    String? resolvedBy,
    String? note,
    String? resolutionCode,
    String? resolutionNote,
  }) {
    return BoxAlertItem(
      id: id,
      title: title,
      message: message,
      severity: severity,
      status: status ?? this.status,
      source: source,
      startedAt: startedAt,
      sourceCode: sourceCode,
      deviceType: deviceType,
      metric: metric,
      valueText: valueText,
      thresholdText: thresholdText,
      unit: unit,
      lastDataAt: lastDataAt,
      acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
      acknowledgedBy: acknowledgedBy ?? this.acknowledgedBy,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolvedBy: resolvedBy ?? this.resolvedBy,
      recoveredAt: recoveredAt,
      cause: cause,
      suggestion: suggestion,
      note: note ?? this.note,
      resolutionCode: resolutionCode ?? this.resolutionCode,
      resolutionNote: resolutionNote ?? this.resolutionNote,
      sharedSensorNote: sharedSensorNote,
      crabTag: crabTag,
      cameraCode: cameraCode,
      confidence: confidence,
      imageUrl: imageUrl,
      correlationId: correlationId,
    );
  }
}

class BoxAlertTab extends StatefulWidget {
  const BoxAlertTab({
    super.key,
    required this.box,
    required this.profileService,
    required this.areaId,
    required this.areaCode,
    required this.areaName,
    this.crabCode,
    this.cameraCode,
    this.sensorCodes = const [],
    this.inheritedSensor = true,
    this.onAlertsChanged,
    this.onOpenCamera,
    this.onOpenSensors,
    this.onOpenCrab,
    this.onOpenDevice,
    this.onOpenHistory,
  });

  final BoxRecord box;
  final CrabProfileService profileService;
  final String areaId;
  final String areaCode;
  final String areaName;
  final String? crabCode;
  final String? cameraCode;
  final List<String> sensorCodes;
  final bool inheritedSensor;
  final VoidCallback? onAlertsChanged;
  final VoidCallback? onOpenCamera;
  final VoidCallback? onOpenSensors;
  final VoidCallback? onOpenCrab;
  final VoidCallback? onOpenDevice;
  final VoidCallback? onOpenHistory;

  @override
  State<BoxAlertTab> createState() => _BoxAlertTabState();
}

class _BoxAlertTabState extends State<BoxAlertTab> {
  final _search = TextEditingController();
  Timer? _debounce;
  Timer? _tick;
  List<BoxAlertItem> _all = const [];
  var _loading = true;
  String? _error;
  BoxAlertStatus? _status;
  BoxAlertSeverity? _severity;
  var _severeBand = false;
  BoxAlertSource _source = BoxAlertSource.all;
  BoxAlertDateRange _range = BoxAlertDateRange.all;
  DateTimeRange? _custom;
  String _query = '';
  String? _selectedId;
  final _selected = <String>{};
  var _page = 0;
  var _pageSize = 10;
  var _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
    _tick = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didUpdateWidget(covariant BoxAlertTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.box.id != widget.box.id) _load();
  }

  @override
  void dispose() {
    _search.dispose();
    _debounce?.cancel();
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final raw = await widget.profileService.fetchBoxAlerts(
        boxId: widget.box.id,
        farmingAreaId: widget.areaId,
      );
      final items = raw
          .map((j) => parseBoxAlert(
                j,
                boxCode: widget.box.boxCode,
                areaCode: widget.areaCode,
                crabCode: widget.crabCode,
                cameraCode: widget.cameraCode,
                sensorCodes: widget.sensorCodes,
                inheritedSensor: widget.inheritedSensor,
              ))
          .whereType<BoxAlertItem>()
          .where(_inBoxScope)
          .toList()
        ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
      if (!mounted) return;
      setState(() {
        _all = items;
        _loading = false;
        _selectedId ??= items.isEmpty ? null : items.first.id;
        if (_selectedId != null && items.every((e) => e.id != _selectedId)) {
          _selectedId = items.isEmpty ? null : items.first.id;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  bool _inBoxScope(BoxAlertItem a) {
    final hay = '${a.title} ${a.message} ${a.sourceCode ?? ''} ${a.crabTag ?? ''} ${a.cameraCode ?? ''}'.toLowerCase();
    final box = widget.box.boxCode.toLowerCase();
    if (hay.contains('box-') && !hay.contains(box)) return false;
    if (hay.contains(box)) return true;
    final crab = (widget.crabCode ?? '').toLowerCase();
    if (crab.isNotEmpty && hay.contains(crab)) return true;
    final cam = (widget.cameraCode ?? '').toLowerCase();
    if (cam.isNotEmpty && hay.contains(cam)) return true;
    if (widget.sensorCodes.any((c) => c.isNotEmpty && hay.contains(c.toLowerCase()))) return true;
    return a.source == BoxAlertSource.sensor ||
        a.source == BoxAlertSource.environment ||
        a.source == BoxAlertSource.camera ||
        a.source == BoxAlertSource.controller ||
        a.source == BoxAlertSource.esp32 ||
        a.source == BoxAlertSource.ai ||
        a.source == BoxAlertSource.box ||
        a.source == BoxAlertSource.crab;
  }

  List<BoxAlertItem> get _filtered {
    final now = DateTime.now();
    DateTime? from;
    DateTime? to;
    switch (_range) {
      case BoxAlertDateRange.h24:
        from = now.subtract(const Duration(hours: 24));
      case BoxAlertDateRange.d7:
        from = now.subtract(const Duration(days: 7));
      case BoxAlertDateRange.d30:
        from = now.subtract(const Duration(days: 30));
      case BoxAlertDateRange.d90:
        from = now.subtract(const Duration(days: 90));
      case BoxAlertDateRange.all:
        break;
      case BoxAlertDateRange.custom:
        from = _custom?.start;
        to = _custom == null ? null : DateTime(_custom!.end.year, _custom!.end.month, _custom!.end.day, 23, 59, 59);
    }
    final q = _query.trim().toLowerCase();
    return _all.where((a) {
      if (_status != null && a.status != _status) return false;
      if (_severeBand) {
        if (a.severity != BoxAlertSeverity.critical && a.severity != BoxAlertSeverity.high) return false;
      } else if (_severity != null && a.severity != _severity) {
        return false;
      }
      if (_source != BoxAlertSource.all && a.source != _source) return false;
      if (from != null && a.startedAt.isBefore(from)) return false;
      if (to != null && a.startedAt.isAfter(to)) return false;
      if (q.isEmpty) return true;
      final hay = [
        a.title,
        a.message,
        a.sourceCode,
        widget.box.boxCode,
        a.metric,
        a.crabTag,
        a.cameraCode,
        sourceLabel(a.source),
        severityLabel(a.severity),
        statusLabel(a.status),
      ].whereType<String>().join(' ').toLowerCase();
      return hay.contains(q);
    }).toList();
  }

  BoxAlertItem? get _selectedItem {
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
        _page = 0;
      });
    });
  }

  void _setKpi({BoxAlertStatus? status, BoxAlertSeverity? severity, bool severeBand = false}) {
    setState(() {
      _status = status;
      _severity = severity;
      _severeBand = severeBand;
      _page = 0;
    });
  }

  Future<void> _pickCustom() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now,
      initialDateRange: _custom ?? DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now),
    );
    if (picked == null) return;
    setState(() {
      _range = BoxAlertDateRange.custom;
      _custom = picked;
      _page = 0;
    });
  }

  Future<void> _ack(BoxAlertItem item, {required bool bulk}) async {
    String? note;
    if (!bulk) {
      note = await showDialog<String>(
        context: context,
        builder: (ctx) => AcknowledgeAlertModal(onCancel: () => Navigator.pop(ctx), onSubmit: (n) => Navigator.pop(ctx, n)),
      );
      if (note == null) return;
    }
    setState(() => _busy = true);
    try {
      await widget.profileService.acknowledgeAlert(item.id, note: note);
      if (!mounted) return;
      setState(() {
        _all = _all
            .map((e) => e.id == item.id
                ? e.copyWith(
                    status: BoxAlertStatus.acknowledged,
                    acknowledgedAt: DateTime.now(),
                    acknowledgedBy: widget.profileService.userName,
                    note: note,
                  )
                : e)
            .toList();
        _busy = false;
      });
      widget.onAlertsChanged?.call();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đã xác nhận cảnh báo.', style: bvText(color: Colors.white)), backgroundColor: DashboardColors.brand));
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _resolve(BoxAlertItem item) async {
    final result = await showDialog<({String code, String note})>(
      context: context,
      builder: (ctx) => ResolveAlertModal(onCancel: () => Navigator.pop(ctx), onSubmit: (c, n) => Navigator.pop(ctx, (code: c, note: n))),
    );
    if (result == null) return;
    setState(() => _busy = true);
    try {
      await widget.profileService.resolveAlert(item.id, resolutionCode: result.code, note: result.note);
      if (!mounted) return;
      setState(() {
        _all = _all
            .map((e) => e.id == item.id
                ? e.copyWith(
                    status: BoxAlertStatus.resolved,
                    resolvedAt: DateTime.now(),
                    resolvedBy: widget.profileService.userName,
                    resolutionCode: result.code,
                    resolutionNote: result.note,
                    note: result.note,
                  )
                : e)
            .toList();
        _busy = false;
      });
      widget.onAlertsChanged?.call();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đã đánh dấu xử lý cảnh báo.', style: bvText(color: Colors.white)), backgroundColor: DashboardColors.brand));
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _bulkAck() async {
    final ids = _selected.toList();
    if (ids.isEmpty) return;
    setState(() => _busy = true);
    try {
      for (final id in ids) {
        await widget.profileService.acknowledgeAlert(id);
      }
      await _load();
      if (!mounted) return;
      setState(() {
        _selected.clear();
        _busy = false;
      });
      widget.onAlertsChanged?.call();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đã xác nhận ${ids.length} cảnh báo.', style: bvText(color: Colors.white)), backgroundColor: DashboardColors.brand));
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _export(String format, List<BoxAlertItem> rows) async {
    if (rows.isEmpty) return;
    final now = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    final stamp = '${now.year}${two(now.month)}${two(now.day)}';
    final base = 'crabsense_canhbao_${widget.box.boxCode}_$stamp';
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
      dialogTitle: 'Xuất cảnh báo',
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đã xuất ${rows.length} cảnh báo của ${widget.box.boxCode}.')));
  }

  void _openSource(BoxAlertItem a) {
    switch (a.source) {
      case BoxAlertSource.camera:
      case BoxAlertSource.ai:
        widget.onOpenCamera?.call();
      case BoxAlertSource.environment:
        widget.onOpenSensors?.call();
      case BoxAlertSource.crab:
        widget.onOpenCrab?.call();
      case BoxAlertSource.sensor:
      case BoxAlertSource.controller:
      case BoxAlertSource.esp32:
        widget.onOpenDevice?.call();
      case BoxAlertSource.box:
      case BoxAlertSource.all:
        widget.onOpenHistory?.call();
    }
  }

  void _openDetail(BoxAlertItem a, {required bool drawer}) {
    setState(() => _selectedId = a.id);
    if (!drawer) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SizedBox(
        height: MediaQuery.of(ctx).size.height * 0.86,
        child: AlertDetailPanel(
          alert: a,
          boxCode: widget.box.boxCode,
          areaCode: widget.areaCode,
          busy: _busy,
          onAck: () {
            Navigator.pop(ctx);
            _ack(a, bulk: false);
          },
          onResolve: () {
            Navigator.pop(ctx);
            _resolve(a);
          },
          onDevice: () {
            Navigator.pop(ctx);
            _openSource(a);
          },
          onHistory: () {
            Navigator.pop(ctx);
            widget.onOpenHistory?.call();
          },
          onAddNote: () => _ack(a, bulk: false),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rows = _filtered;
    final start = (_page * _pageSize).clamp(0, rows.length);
    final end = (start + _pageSize).clamp(0, rows.length);
    final pageRows = rows.isEmpty ? const <BoxAlertItem>[] : rows.sublist(start, end);
    final selected = _selectedItem;

    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final desktop = w >= 1100;
        final tablet = w >= 760;
        return Column(
          children: [
            AlertSummaryCards(
              items: _all,
              loading: _loading,
              onOpen: () => _setKpi(status: BoxAlertStatus.open),
              onCritical: () => _setKpi(severeBand: true),
              onMedium: () => _setKpi(severity: BoxAlertSeverity.medium),
              onAck: () => _setKpi(status: BoxAlertStatus.acknowledged),
              onResolved: () => _setKpi(status: BoxAlertStatus.resolved),
            ),
            const SizedBox(height: 12),
            AlertFilters(
              status: _status,
              severity: _severity,
              source: _source,
              range: _range,
              search: _search,
              onStatus: (v) => setState(() {
                _status = v;
                _page = 0;
              }),
              onSeverity: (v) => setState(() {
                _severity = v;
                _severeBand = false;
                _page = 0;
              }),
              onSource: (v) => setState(() {
                _source = v;
                _page = 0;
              }),
              onRange: (v) {
                if (v == BoxAlertDateRange.custom) {
                  _pickCustom();
                  return;
                }
                setState(() {
                  _range = v;
                  _page = 0;
                });
              },
              onSearch: _onSearch,
              onExport: (f) => _export(f, rows),
            ),
            if (_selected.isNotEmpty) ...[
              const SizedBox(height: 10),
              _BulkBar(
                count: _selected.length,
                busy: _busy,
                onAck: _bulkAck,
                onExport: () => _export('csv', _all.where((e) => _selected.contains(e.id)).toList()),
                onClear: () => setState(_selected.clear),
              ),
            ],
            const SizedBox(height: 12),
            if (_loading)
              const _AlertSkeleton()
            else if (_error != null)
              OverviewCard(
                icon: Icons.warning_amber_rounded,
                title: 'Cảnh báo',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Không thể tải danh sách cảnh báo.', style: bvText(fontWeight: FontWeight.w700, color: const Color(0xFFEF4444))),
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
                    flex: 70,
                    child: AlertTable(
                      boxCode: widget.box.boxCode,
                      rows: pageRows,
                      total: rows.length,
                      selectedId: selected?.id,
                      checked: _selected,
                      page: _page,
                      pageSize: _pageSize,
                      start: start,
                      end: end,
                      onToggle: (id, v) => setState(() => v ? _selected.add(id) : _selected.remove(id)),
                      onTogglePage: (v) => setState(() {
                        for (final r in pageRows) {
                          if (v) {
                            _selected.add(r.id);
                          } else {
                            _selected.remove(r.id);
                          }
                        }
                      }),
                      onSelect: (a) => _openDetail(a, drawer: false),
                      onPage: (p) => setState(() => _page = p),
                      onPageSize: (s) => setState(() {
                        _pageSize = s;
                        _page = 0;
                      }),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 30,
                    child: selected == null
                        ? OverviewCard(
                            icon: Icons.notifications_none_rounded,
                            title: 'Chi tiết cảnh báo',
                            child: Text('Chọn một cảnh báo để xem chi tiết.', style: bvText(color: DashboardColors.textMuted)),
                          )
                        : AlertDetailPanel(
                            alert: selected,
                            boxCode: widget.box.boxCode,
                            areaCode: widget.areaCode,
                            busy: _busy,
                            onAck: selected.isOpen && selected.status == BoxAlertStatus.open ? () => _ack(selected, bulk: false) : null,
                            onResolve: selected.status != BoxAlertStatus.resolved && selected.status != BoxAlertStatus.recovered
                                ? () => _resolve(selected)
                                : null,
                            onDevice: () => _openSource(selected),
                            onHistory: widget.onOpenHistory,
                            onAddNote: () => _ack(selected, bulk: false),
                          ),
                  ),
                ],
              )
            else
              AlertTable(
                boxCode: widget.box.boxCode,
                rows: pageRows,
                total: rows.length,
                selectedId: selected?.id,
                checked: _selected,
                page: _page,
                pageSize: _pageSize,
                start: start,
                end: end,
                compact: !tablet,
                onToggle: (id, v) => setState(() => v ? _selected.add(id) : _selected.remove(id)),
                onTogglePage: (v) => setState(() {
                  for (final r in pageRows) {
                    if (v) {
                      _selected.add(r.id);
                    } else {
                      _selected.remove(r.id);
                    }
                  }
                }),
                onSelect: (a) => _openDetail(a, drawer: true),
                onPage: (p) => setState(() => _page = p),
                onPageSize: (s) => setState(() {
                  _pageSize = s;
                  _page = 0;
                }),
              ),
          ],
        );
      },
    );
  }

  String _csv(List<BoxAlertItem> rows) {
    final sb = StringBuffer()..writeln('Thoi gian,Tieu de,Noi dung,Nguon,Muc do,Trang thai,Keo dai,BOX');
    String cell(String v) => v.contains(',') || v.contains('"') ? '"${v.replaceAll('"', '""')}"' : v;
    for (final a in rows) {
      sb.writeln([
        cell(fmtDateTimeVn(a.startedAt)),
        cell(a.title),
        cell(a.message),
        cell(a.sourceCode ?? sourceLabel(a.source)),
        cell(severityLabel(a.severity)),
        cell(statusLabel(a.status)),
        cell(alertDuration(a)),
        cell(widget.box.boxCode),
      ].join(','));
    }
    return sb.toString();
  }

  String _xls(List<BoxAlertItem> rows) {
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
    row(['Thời gian', 'Tiêu đề', 'Nội dung', 'Nguồn', 'Mức độ', 'Trạng thái', 'Kéo dài']);
    for (final a in rows) {
      row([fmtDateTimeVn(a.startedAt), a.title, a.message, a.sourceCode ?? sourceLabel(a.source), severityLabel(a.severity), statusLabel(a.status), alertDuration(a)]);
    }
    return '''<?xml version="1.0"?>
<?mso-application progid="Excel.Sheet"?>
<Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet" xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet">
<Worksheet ss:Name="Canh bao"><Table>
$buf
</Table></Worksheet></Workbook>''';
  }

  List<int> _pdf(List<BoxAlertItem> rows) {
    final lines = <String>[
      'CrabSense - Canh bao ${widget.box.boxCode}',
      'Tong: ${rows.length}',
      '',
      for (final a in rows) '${fmtDateTimeVn(a.startedAt)} | ${a.title} | ${severityLabel(a.severity)} | ${statusLabel(a.status)}',
    ];
    final content = StringBuffer('BT /F1 9 Tf 40 800 Td\n');
    for (var i = 0; i < lines.length; i++) {
      final yShift = i == 0 ? '' : '0 -13 Td\n';
      final safe = lines[i].replaceAll('\\', '\\\\').replaceAll('(', '\\(').replaceAll(')', '\\)');
      content.write('$yShift($safe) Tj\n');
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

class AlertSummaryCards extends StatelessWidget {
  const AlertSummaryCards({
    super.key,
    required this.items,
    required this.loading,
    required this.onOpen,
    required this.onCritical,
    required this.onMedium,
    required this.onAck,
    required this.onResolved,
  });

  final List<BoxAlertItem> items;
  final bool loading;
  final VoidCallback onOpen;
  final VoidCallback onCritical;
  final VoidCallback onMedium;
  final VoidCallback onAck;
  final VoidCallback onResolved;

  @override
  Widget build(BuildContext context) {
    if (loading && items.isEmpty) {
      return Row(
        children: [
          for (var i = 0; i < 5; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            Expanded(child: Container(height: 86, decoration: BoxDecoration(color: DashboardColors.lightMint, borderRadius: BorderRadius.circular(14)))),
          ],
        ],
      );
    }
    final now = DateTime.now();
    final d7 = now.subtract(const Duration(days: 7));
    final open = items.where((a) => a.status == BoxAlertStatus.open).length;
    final critical = items.where((a) => a.severity == BoxAlertSeverity.critical || a.severity == BoxAlertSeverity.high).length;
    final medium = items.where((a) => a.severity == BoxAlertSeverity.medium).length;
    final ack = items.where((a) => a.status == BoxAlertStatus.acknowledged).length;
    final resolved7 = items.where((a) => (a.status == BoxAlertStatus.resolved || a.status == BoxAlertStatus.recovered) && (a.endedAt ?? a.startedAt).isAfter(d7)).length;
    final openThen = items.where((a) => a.startedAt.isBefore(d7) && (a.endedAt == null || a.endedAt!.isAfter(d7))).length;
    final openDelta = open - openThen;
    final medThen = items.where((a) => a.severity == BoxAlertSeverity.medium && a.startedAt.isBefore(d7) && (a.endedAt == null || a.endedAt!.isAfter(d7))).length;
    final medNow = items.where((a) => a.severity == BoxAlertSeverity.medium && a.isOpen).length;
    final medDelta = medNow - medThen;

    final cards = [
      _Kpi(label: 'ĐANG MỞ', value: '$open', hint: _deltaHint(openDelta), color: const Color(0xFFEF4444), onTap: onOpen),
      _Kpi(label: 'NGHIÊM TRỌNG', value: '$critical', hint: critical == 0 ? 'Không có cảnh báo nặng' : 'Cần xử lý ngay', color: const Color(0xFFEF4444), onTap: onCritical),
      _Kpi(label: 'TRUNG BÌNH', value: '$medium', hint: _deltaHint(medDelta), color: const Color(0xFFF5B700), onTap: onMedium),
      _Kpi(label: 'ĐÃ XÁC NHẬN', value: '$ack', hint: ack == 0 ? 'Chưa có xác nhận' : 'Đang xử lý', color: const Color(0xFF2495E8), onTap: onAck),
      _Kpi(label: 'ĐÃ XỬ LÝ', value: '$resolved7', hint: 'Trong 7 ngày qua', color: DashboardColors.brand, onTap: onResolved),
    ];

    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth < 760) {
          return Wrap(
            spacing: 10,
            runSpacing: 10,
            children: cards.map((e) => SizedBox(width: (c.maxWidth - 10) / 2, child: e)).toList(),
          );
        }
        return Row(
          children: [
            for (var i = 0; i < cards.length; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              Expanded(child: cards[i]),
            ],
          ],
        );
      },
    );
  }

  String _deltaHint(int delta) {
    if (delta == 0) return 'Không đổi so với 7 ngày trước';
    if (delta > 0) return '↑ $delta so với 7 ngày trước';
    return '↓ ${-delta} so với 7 ngày trước';
  }
}

class _Kpi extends StatelessWidget {
  const _Kpi({required this.label, required this.value, required this.hint, required this.color, required this.onTap});

  final String label;
  final String value;
  final String hint;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: DashboardColors.cardBorder),
            color: color.withValues(alpha: 0.04),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: bvText(fontSize: 11, fontWeight: FontWeight.w800, color: DashboardColors.textMuted)),
              const SizedBox(height: 4),
              Text(value, style: bvText(fontSize: 26, fontWeight: FontWeight.w800, color: color)),
              const SizedBox(height: 2),
              Text(hint, style: bvText(fontSize: 11.5, color: DashboardColors.textMuted)),
            ],
          ),
        ),
      ),
    );
  }
}

class AlertFilters extends StatelessWidget {
  const AlertFilters({
    super.key,
    required this.status,
    required this.severity,
    required this.source,
    required this.range,
    required this.search,
    required this.onStatus,
    required this.onSeverity,
    required this.onSource,
    required this.onRange,
    required this.onSearch,
    required this.onExport,
  });

  final BoxAlertStatus? status;
  final BoxAlertSeverity? severity;
  final BoxAlertSource source;
  final BoxAlertDateRange range;
  final TextEditingController search;
  final ValueChanged<BoxAlertStatus?> onStatus;
  final ValueChanged<BoxAlertSeverity?> onSeverity;
  final ValueChanged<BoxAlertSource> onSource;
  final ValueChanged<BoxAlertDateRange> onRange;
  final ValueChanged<String> onSearch;
  final ValueChanged<String> onExport;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _drop<BoxAlertStatus?>(
          value: status,
          items: [
            const DropdownMenuItem(value: null, child: Text('Tất cả trạng thái')),
            ...BoxAlertStatus.values.map((e) => DropdownMenuItem(value: e, child: Text(statusLabel(e)))),
          ],
          onChanged: onStatus,
        ),
        _drop<BoxAlertSeverity?>(
          value: severity,
          items: [
            const DropdownMenuItem(value: null, child: Text('Tất cả mức độ')),
            ...BoxAlertSeverity.values.map((e) => DropdownMenuItem(value: e, child: Text(severityLabel(e)))),
          ],
          onChanged: onSeverity,
        ),
        _drop<BoxAlertSource>(
          value: source,
          items: [
            const DropdownMenuItem(value: BoxAlertSource.all, child: Text('Tất cả nguồn')),
            const DropdownMenuItem(value: BoxAlertSource.sensor, child: Text('Cảm biến')),
            const DropdownMenuItem(value: BoxAlertSource.camera, child: Text('Camera')),
            const DropdownMenuItem(value: BoxAlertSource.controller, child: Text('Controller')),
            const DropdownMenuItem(value: BoxAlertSource.esp32, child: Text('ESP32')),
            const DropdownMenuItem(value: BoxAlertSource.ai, child: Text('AI')),
            const DropdownMenuItem(value: BoxAlertSource.environment, child: Text('Môi trường')),
            const DropdownMenuItem(value: BoxAlertSource.box, child: Text('Hộp')),
            const DropdownMenuItem(value: BoxAlertSource.crab, child: Text('Cua')),
          ],
          onChanged: (v) => onSource(v ?? BoxAlertSource.all),
        ),
        _drop<BoxAlertDateRange>(
          value: range,
          items: const [
            DropdownMenuItem(value: BoxAlertDateRange.h24, child: Text('24 giờ')),
            DropdownMenuItem(value: BoxAlertDateRange.d7, child: Text('7 ngày qua')),
            DropdownMenuItem(value: BoxAlertDateRange.d30, child: Text('30 ngày')),
            DropdownMenuItem(value: BoxAlertDateRange.d90, child: Text('90 ngày')),
            DropdownMenuItem(value: BoxAlertDateRange.all, child: Text('Toàn bộ')),
            DropdownMenuItem(value: BoxAlertDateRange.custom, child: Text('Tùy chỉnh')),
          ],
          onChanged: (v) => onRange(v ?? BoxAlertDateRange.d7),
        ),
        SizedBox(
          width: 240,
          height: 40,
          child: TextField(
            controller: search,
            onChanged: onSearch,
            style: bvText(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Tìm kiếm cảnh báo...',
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
        PopupMenuButton<String>(
          tooltip: 'Xuất dữ liệu',
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
                Text('Xuất dữ liệu', style: bvText(fontSize: 12.5, fontWeight: FontWeight.w700, color: DashboardColors.brand)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _drop<T>({required T value, required List<DropdownMenuItem<T>> items, required ValueChanged<T?> onChanged}) {
    return SizedBox(
      width: 168,
      height: 40,
      child: DropdownButtonFormField<T>(
        value: value,
        isExpanded: true,
        items: items,
        onChanged: onChanged,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: DashboardColors.cardBorder)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: DashboardColors.cardBorder)),
        ),
        style: bvText(fontSize: 12.5, color: DashboardColors.textPrimary),
      ),
    );
  }
}

class AlertTable extends StatelessWidget {
  const AlertTable({
    super.key,
    required this.boxCode,
    required this.rows,
    required this.total,
    required this.checked,
    required this.page,
    required this.pageSize,
    required this.start,
    required this.end,
    required this.onToggle,
    required this.onTogglePage,
    required this.onSelect,
    required this.onPage,
    required this.onPageSize,
    this.selectedId,
    this.compact = false,
  });

  final String boxCode;
  final List<BoxAlertItem> rows;
  final int total;
  final Set<String> checked;
  final int page;
  final int pageSize;
  final int start;
  final int end;
  final String? selectedId;
  final bool compact;
  final void Function(String id, bool value) onToggle;
  final ValueChanged<bool> onTogglePage;
  final ValueChanged<BoxAlertItem> onSelect;
  final ValueChanged<int> onPage;
  final ValueChanged<int> onPageSize;

  @override
  Widget build(BuildContext context) {
    return OverviewCard(
      icon: Icons.notifications_none_rounded,
      title: 'Danh sách cảnh báo ($total)',
      child: Column(
        children: [
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Column(
                children: [
                  const Icon(Icons.check_circle_outline, size: 36, color: DashboardColors.brand),
                  const SizedBox(height: 8),
                  Text('Không có cảnh báo', style: bvText(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(
                    total == 0 && checked.isEmpty
                        ? '$boxCode hiện không có cảnh báo phù hợp với bộ lọc.\nHộp đang hoạt động bình thường.'
                        : '$boxCode hiện không có cảnh báo phù hợp với bộ lọc.',
                    textAlign: TextAlign.center,
                    style: bvText(fontSize: 12.5, color: DashboardColors.textMuted),
                  ),
                ],
              ),
            )
          else if (compact)
            Column(
              children: [
                for (final a in rows)
                  InkWell(
                    onTap: () => onSelect(a),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: a.id == selectedId ? DashboardColors.mint.withValues(alpha: 0.55) : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: DashboardColors.cardBorder),
                      ),
                      child: Row(
                        children: [
                          Checkbox(value: checked.contains(a.id), onChanged: (v) => onToggle(a.id, v == true)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(a.title, style: bvText(fontSize: 13, fontWeight: FontWeight.w700)),
                                Text(fmtDateTimeVn(a.startedAt), style: bvText(fontSize: 11.5, color: DashboardColors.textMuted)),
                              ],
                            ),
                          ),
                          _sev(a.severity),
                        ],
                      ),
                    ),
                  ),
              ],
            )
          else
            Column(
              children: [
                _head(),
                for (final a in rows)
                  InkWell(
                    onTap: () => onSelect(a),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: a.id == selectedId ? const Color(0xFFF3FBF8) : Colors.transparent,
                        border: Border(bottom: BorderSide(color: DashboardColors.cardBorder.withValues(alpha: 0.7))),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 36,
                            child: Checkbox(value: checked.contains(a.id), onChanged: (v) => onToggle(a.id, v == true), visualDensity: VisualDensity.compact),
                          ),
                          Expanded(flex: 15, child: Text(fmtDateTimeVn(a.startedAt), maxLines: 1, overflow: TextOverflow.ellipsis, style: bvText(fontSize: 12, color: DashboardColors.textMuted))),
                          Expanded(
                            flex: 24,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(a.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: bvText(fontSize: 12.5, fontWeight: FontWeight.w700)),
                                if (a.message.isNotEmpty && a.message != a.title)
                                  Text(a.message, maxLines: 1, overflow: TextOverflow.ellipsis, style: bvText(fontSize: 11.5, color: DashboardColors.textMuted)),
                              ],
                            ),
                          ),
                          Expanded(flex: 14, child: Text(a.sourceCode ?? sourceLabel(a.source), maxLines: 1, overflow: TextOverflow.ellipsis, style: bvText(fontSize: 12, fontWeight: FontWeight.w600))),
                          Expanded(flex: 16, child: _sev(a.severity)),
                          Expanded(flex: 16, child: _st(a.status)),
                          Expanded(flex: 13, child: Text(alertDuration(a), maxLines: 1, overflow: TextOverflow.ellipsis, style: bvText(fontSize: 12, color: DashboardColors.textMuted))),
                          const SizedBox(width: 18, child: Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF94A3B8))),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                total == 0 ? '0 của 0' : '${start + (total == 0 ? 0 : 1)} – $end của $total',
                style: bvText(fontSize: 12, color: DashboardColors.textMuted),
              ),
              const Spacer(),
              SizedBox(
                width: 110,
                child: DropdownButtonFormField<int>(
                  value: pageSize,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 10, child: Text('10 / trang')),
                    DropdownMenuItem(value: 20, child: Text('20 / trang')),
                    DropdownMenuItem(value: 50, child: Text('50 / trang')),
                  ],
                  onChanged: (v) => onPageSize(v ?? 10),
                  decoration: const InputDecoration(isDense: true, border: InputBorder.none),
                  style: bvText(fontSize: 12, color: DashboardColors.textPrimary),
                ),
              ),
              IconButton(
                onPressed: page > 0 ? () => onPage(page - 1) : null,
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Text('${page + 1}', style: bvText(fontWeight: FontWeight.w700)),
              IconButton(
                onPressed: end < total ? () => onPage(page + 1) : null,
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _head() {
    final allOn = rows.isNotEmpty && rows.every((e) => checked.contains(e.id));
    Widget h(String t, int flex) => Expanded(flex: flex, child: Text(t, style: bvText(fontSize: 11, fontWeight: FontWeight.w800, color: DashboardColors.textMuted)));
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Checkbox(value: allOn, onChanged: (v) => onTogglePage(v == true), visualDensity: VisualDensity.compact),
          ),
          h('THỜI GIAN', 15),
          h('NỘI DUNG CẢNH BÁO', 24),
          h('NGUỒN', 14),
          h('MỨC ĐỘ', 16),
          h('TRẠNG THÁI', 16),
          h('THỜI GIAN KÉO DÀI', 13),
          const SizedBox(width: 18),
        ],
      ),
    );
  }
}

class AlertDetailPanel extends StatelessWidget {
  const AlertDetailPanel({
    super.key,
    required this.alert,
    required this.boxCode,
    required this.areaCode,
    required this.busy,
    this.onAck,
    this.onResolve,
    this.onDevice,
    this.onHistory,
    this.onAddNote,
  });

  final BoxAlertItem alert;
  final String boxCode;
  final String areaCode;
  final bool busy;
  final VoidCallback? onAck;
  final VoidCallback? onResolve;
  final VoidCallback? onDevice;
  final VoidCallback? onHistory;
  final VoidCallback? onAddNote;

  @override
  Widget build(BuildContext context) {
    return OverviewCard(
      icon: Icons.warning_amber_rounded,
      title: 'Chi tiết cảnh báo',
      trailing: MgmtStatusBadge(label: statusLabel(alert.status), color: statusColor(alert.status)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(alert.title, style: bvText(fontSize: 15, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(alert.message.isEmpty ? '—' : alert.message, style: bvText(fontSize: 12.5, color: DashboardColors.textMuted)),
          if (alert.sharedSensorNote != null) ...[
            const SizedBox(height: 8),
            Text(alert.sharedSensorNote!, style: bvText(fontSize: 12, fontWeight: FontWeight.w600, color: DashboardColors.brand)),
          ],
          const SizedBox(height: 12),
          _kv('Mức độ', severityLabel(alert.severity)),
          _kv('Trạng thái', statusLabel(alert.status)),
          if ((alert.sourceCode ?? '').isNotEmpty) _kv('Nguồn', alert.sourceCode!),
          if ((alert.deviceType ?? '').isNotEmpty) _kv('Loại thiết bị', alert.deviceType!),
          _kv('BOX liên quan', boxCode),
          if (areaCode.isNotEmpty) _kv('Khu vực', areaCode),
          if ((alert.crabTag ?? '').isNotEmpty) _kv('Cua', alert.crabTag!),
          if ((alert.cameraCode ?? '').isNotEmpty) _kv('Camera', alert.cameraCode!),
          if (alert.metric != null) _kv('Chỉ số', alert.metric!),
          if (alert.valueText != null) _kv('Giá trị', alert.valueText!),
          if (alert.thresholdText != null) _kv('Ngưỡng', alert.thresholdText!),
          if (alert.confidence != null) _kv('Confidence', '${alert.confidence}%'),
          _kv('Bắt đầu', fmtDateTimeSec(alert.startedAt)),
          if (alert.lastDataAt != null) _kv('Lần nhận dữ liệu cuối', fmtDateTimeSec(alert.lastDataAt)),
          _kv('Thời gian kéo dài', alertDuration(alert)),
          if (alert.acknowledgedBy != null) _kv('Người xác nhận', alert.acknowledgedBy!),
          if (alert.acknowledgedAt != null) _kv('Xác nhận lúc', fmtDateTimeSec(alert.acknowledgedAt)),
          if (alert.resolvedBy != null) _kv('Người xử lý', alert.resolvedBy!),
          if (alert.resolvedAt != null) _kv('Xử lý lúc', fmtDateTimeSec(alert.resolvedAt)),
          const SizedBox(height: 8),
          Text('Nguyên nhân gần nhất', style: bvText(fontSize: 12.5, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(alert.cause ?? 'Chưa xác định.', style: bvText(fontSize: 12.5, color: DashboardColors.textMuted)),
          const SizedBox(height: 10),
          Text('Đề xuất', style: bvText(fontSize: 12.5, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(alert.suggestion ?? 'Kiểm tra nguồn gốc cảnh báo và cập nhật trạng thái sau khi xử lý.', style: bvText(fontSize: 12.5, color: DashboardColors.textMuted)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: Text('Ghi chú', style: bvText(fontSize: 12.5, fontWeight: FontWeight.w800))),
              if (onAddNote != null) OverviewLinkButton(label: 'Thêm ghi chú', onTap: onAddNote),
            ],
          ),
          Text(
            (alert.resolutionNote ?? alert.note ?? '').trim().isEmpty ? 'Chưa có ghi chú xử lý.' : (alert.resolutionNote ?? alert.note)!,
            style: bvText(fontSize: 12.5, color: DashboardColors.textMuted),
          ),
          if (alert.imageUrl != null) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(alert.imageUrl!, height: 120, width: double.infinity, fit: BoxFit.cover),
            ),
          ],
          const SizedBox(height: 14),
          if (onAck != null)
            SizedBox(
              width: double.infinity,
              child: MgmtOutlineButton(icon: Icons.task_alt_rounded, label: 'Xác nhận cảnh báo', onTap: busy ? null : onAck),
            ),
          if (onResolve != null) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: MgmtPrimaryButton(icon: Icons.check_rounded, label: 'Đánh dấu đã xử lý', height: 40, onTap: busy ? null : onResolve),
            ),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              OverviewLinkButton(label: 'Xem thiết bị', onTap: onDevice),
              OverviewLinkButton(label: 'Xem lịch sử', onTap: onHistory),
              if (alert.source == BoxAlertSource.ai) OverviewLinkButton(label: 'Xem phát hiện AI', onTap: onDevice),
            ],
          ),
        ],
      ),
    );
  }
}

class AcknowledgeAlertModal extends StatefulWidget {
  const AcknowledgeAlertModal({super.key, required this.onCancel, required this.onSubmit});
  final VoidCallback onCancel;
  final ValueChanged<String> onSubmit;

  @override
  State<AcknowledgeAlertModal> createState() => _AcknowledgeAlertModalState();
}

class _AcknowledgeAlertModalState extends State<AcknowledgeAlertModal> {
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Xác nhận cảnh báo?', style: bvText(fontSize: 16, fontWeight: FontWeight.w800)),
      content: SizedBox(
        width: 420,
        child: TextField(
          controller: _note,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Ghi chú xác nhận (không bắt buộc)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: widget.onCancel, child: const Text('Hủy')),
        FilledButton(
          onPressed: () => widget.onSubmit(_note.text.trim()),
          style: FilledButton.styleFrom(backgroundColor: DashboardColors.brand),
          child: const Text('Xác nhận'),
        ),
      ],
    );
  }
}

class ResolveAlertModal extends StatefulWidget {
  const ResolveAlertModal({super.key, required this.onCancel, required this.onSubmit});
  final VoidCallback onCancel;
  final void Function(String code, String note) onSubmit;

  @override
  State<ResolveAlertModal> createState() => _ResolveAlertModalState();
}

class _ResolveAlertModalState extends State<ResolveAlertModal> {
  final _note = TextEditingController();
  var _code = 'fixed';

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Xử lý cảnh báo', style: bvText(fontSize: 16, fontWeight: FontWeight.w800)),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Kết quả xử lý *', style: bvText(fontSize: 12.5, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _code,
              items: const [
                DropdownMenuItem(value: 'fixed', child: Text('Đã khắc phục')),
                DropdownMenuItem(value: 'gone', child: Text('Không còn lỗi')),
                DropdownMenuItem(value: 'replaced', child: Text('Thiết bị thay thế')),
                DropdownMenuItem(value: 'ignored', child: Text('Không cần xử lý')),
                DropdownMenuItem(value: 'other', child: Text('Khác')),
              ],
              onChanged: (v) => setState(() => _code = v ?? 'fixed'),
              decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
            ),
            const SizedBox(height: 12),
            Text('Ghi chú xử lý *', style: bvText(fontSize: 12.5, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            TextField(
              controller: _note,
              maxLines: 3,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Mô tả cách xử lý',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: widget.onCancel, child: const Text('Hủy')),
        FilledButton(
          onPressed: _note.text.trim().isEmpty ? null : () => widget.onSubmit(_code, _note.text.trim()),
          style: FilledButton.styleFrom(backgroundColor: DashboardColors.brand),
          child: const Text('Xác nhận đã xử lý'),
        ),
      ],
    );
  }
}

class _BulkBar extends StatelessWidget {
  const _BulkBar({required this.count, required this.busy, required this.onAck, required this.onExport, required this.onClear});
  final int count;
  final bool busy;
  final VoidCallback onAck;
  final VoidCallback onExport;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: DashboardColors.mint,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: DashboardColors.cardBorder),
      ),
      child: Row(
        children: [
          Text('Đã chọn $count', style: bvText(fontWeight: FontWeight.w800)),
          const SizedBox(width: 12),
          MgmtPrimaryButton(label: 'Xác nhận', height: 34, onTap: busy ? null : onAck),
          const SizedBox(width: 8),
          MgmtOutlineButton(label: 'Xuất dữ liệu', height: 34, onTap: onExport),
          const Spacer(),
          TextButton(onPressed: onClear, child: const Text('Bỏ chọn')),
        ],
      ),
    );
  }
}

class _AlertSkeleton extends StatelessWidget {
  const _AlertSkeleton();
  @override
  Widget build(BuildContext context) {
    Widget box(double h) => Container(height: h, decoration: BoxDecoration(color: DashboardColors.lightMint, borderRadius: BorderRadius.circular(12)));
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 70,
          child: Column(children: [for (var i = 0; i < 6; i++) Padding(padding: const EdgeInsets.only(bottom: 8), child: box(44))]),
        ),
        const SizedBox(width: 12),
        Expanded(flex: 30, child: box(280)),
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
        SizedBox(width: 148, child: Text(k, style: bvText(fontSize: 12.5, color: DashboardColors.textMuted))),
        Expanded(child: Text(v, style: bvText(fontSize: 12.5, fontWeight: FontWeight.w700))),
      ],
    ),
  );
}

Widget _sev(BoxAlertSeverity s) => MgmtStatusBadge(label: severityLabel(s), color: severityColor(s));
Widget _st(BoxAlertStatus s) => MgmtStatusBadge(label: statusLabel(s), color: statusColor(s));

String statusLabel(BoxAlertStatus s) => switch (s) {
      BoxAlertStatus.open => 'Đang mở',
      BoxAlertStatus.acknowledged => 'Đã xác nhận',
      BoxAlertStatus.inProgress => 'Đang xử lý',
      BoxAlertStatus.resolved => 'Đã xử lý',
      BoxAlertStatus.recovered => 'Đã khôi phục',
    };

Color statusColor(BoxAlertStatus s) => switch (s) {
      BoxAlertStatus.open => const Color(0xFFEF4444),
      BoxAlertStatus.acknowledged || BoxAlertStatus.inProgress => const Color(0xFF2495E8),
      BoxAlertStatus.resolved => DashboardColors.brand,
      BoxAlertStatus.recovered => const Color(0xFF2495E8),
    };

String severityLabel(BoxAlertSeverity s) => switch (s) {
      BoxAlertSeverity.critical => 'Nghiêm trọng',
      BoxAlertSeverity.high => 'Cao',
      BoxAlertSeverity.medium => 'Trung bình',
      BoxAlertSeverity.low => 'Thấp',
    };

Color severityColor(BoxAlertSeverity s) => switch (s) {
      BoxAlertSeverity.critical || BoxAlertSeverity.high => const Color(0xFFEF4444),
      BoxAlertSeverity.medium => const Color(0xFFF5B700),
      BoxAlertSeverity.low => const Color(0xFF94A3B8),
    };

String sourceLabel(BoxAlertSource s) => switch (s) {
      BoxAlertSource.all => 'Tất cả nguồn',
      BoxAlertSource.sensor => 'Cảm biến',
      BoxAlertSource.camera => 'Camera',
      BoxAlertSource.controller => 'Controller',
      BoxAlertSource.esp32 => 'ESP32',
      BoxAlertSource.ai => 'AI',
      BoxAlertSource.environment => 'Môi trường',
      BoxAlertSource.box => 'Hộp',
      BoxAlertSource.crab => 'Cua',
    };

String alertDuration(BoxAlertItem a) {
  final end = a.isOpen ? DateTime.now() : (a.endedAt ?? DateTime.now());
  var d = end.difference(a.startedAt);
  if (d.isNegative) d = Duration.zero;
  if (d.inMinutes < 1) return '${d.inSeconds} giây';
  if (d.inHours < 1) return '${d.inMinutes} phút';
  if (d.inHours < 24) {
    final m = d.inMinutes % 60;
    return m == 0 ? '${d.inHours} giờ' : '${d.inHours} giờ $m phút';
  }
  final h = d.inHours % 24;
  return h == 0 ? '${d.inDays} ngày' : '${d.inDays} ngày $h giờ';
}

String fmtDateTimeSec(DateTime? dt) {
  if (dt == null) return '—';
  final l = dt.isUtc ? dt.toLocal() : dt;
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(l.day)}/${two(l.month)}/${l.year} ${two(l.hour)}:${two(l.minute)}:${two(l.second)}';
}

BoxAlertItem? parseBoxAlert(
  Map<String, dynamic> j, {
  required String boxCode,
  required String areaCode,
  String? crabCode,
  String? cameraCode,
  List<String> sensorCodes = const [],
  bool inheritedSensor = true,
}) {
  String? str(List<String> keys) {
    for (final k in keys) {
      final v = j[k];
      if (v != null && '$v'.isNotEmpty && '$v' != 'null') return '$v';
    }
    return null;
  }

  final id = str(['id', 'Id']);
  final started = DateTime.tryParse((j['createdAt'] ?? j['CreatedAt'] ?? '').toString());
  if (id == null || started == null) return null;
  final rawTitle = str(['title', 'Title']) ?? '';
  final rawMessage = str(['message', 'Message']) ?? rawTitle;
  final category = (str(['category', 'Category']) ?? '').toLowerCase();
  final sensorType = str(['sensorType', 'SensorType']) ?? '';
  final sensorCode = str(['sensorCode', 'SensorCode']);
  final score = j['priorityScore'] ?? j['PriorityScore'];
  final sev = _severityOf((str(['severity', 'Severity']) ?? '').toLowerCase(), score is num ? score.toInt() : null);
  final status = _statusOf(str(['status', 'Status']) ?? '', rawMessage);
  final source = _sourceOf(category, sensorType, rawMessage, sensorCode);
  final ackAt = DateTime.tryParse((j['acknowledgedAt'] ?? j['AcknowledgedAt'] ?? '').toString());
  final rec = _recommend(source, sensorType, str(['aiRecommendation', 'AiRecommendation']));
  final cause = _cause(rawMessage);
  final trigger = j['triggerValue'] ?? j['TriggerValue'];
  final min = j['thresholdMin'] ?? j['ThresholdMin'];
  final max = j['thresholdMax'] ?? j['ThresholdMax'];
  final unit = str(['unit', 'Unit']) ?? _unitOf(sensorType);
  final title = humanAlertTitle(rawTitle, rawMessage, source);
  final message = humanAlertMessage(rawMessage, title, trigger, min, max, unit);
  final shared = inheritedSensor &&
          (source == BoxAlertSource.sensor || source == BoxAlertSource.environment) &&
          !rawMessage.toLowerCase().contains(boxCode.toLowerCase()) &&
          areaCode.isNotEmpty
      ? 'Ảnh hưởng qua sensor chung $areaCode.'
      : null;
  final metric = source == BoxAlertSource.environment || _isEnvType(sensorType) ? _metricLabel(sensorType, rawMessage) : null;

  return BoxAlertItem(
    id: id,
    title: title,
    message: message,
    severity: sev,
    status: status,
    source: source,
    startedAt: started.isUtc ? started.toLocal() : started,
    sourceCode: sensorCode ?? cameraCode,
    deviceType: _deviceType(source, sensorType),
    metric: metric,
    valueText: trigger == null ? null : '${_num(trigger)}${unit == null ? '' : ' $unit'}',
    thresholdText: _threshold(min, max, unit),
    unit: unit,
    lastDataAt: null,
    acknowledgedAt: ackAt?.toLocal(),
    acknowledgedBy: _actorName(str(['acknowledgedBy', 'AcknowledgedBy'])),
    cause: cause,
    suggestion: rec,
    sharedSensorNote: shared,
    crabTag: crabCode,
    cameraCode: source == BoxAlertSource.camera || source == BoxAlertSource.ai ? (sensorCode ?? cameraCode) : cameraCode,
    confidence: (j['aiConfidence'] ?? j['AiConfidence']) is num ? (j['aiConfidence'] ?? j['AiConfidence'] as num).toInt() : null,
    correlationId: str(['correlationId', 'CorrelationId']),
  );
}

BoxAlertSeverity _severityOf(String raw, int? score) {
  if (score != null) {
    if (score >= 85) return BoxAlertSeverity.critical;
    if (score >= 70) return BoxAlertSeverity.high;
    if (score >= 50) return BoxAlertSeverity.medium;
    return BoxAlertSeverity.low;
  }
  if (raw.contains('crit') || raw.contains('danger') || raw.contains('error')) return BoxAlertSeverity.critical;
  if (raw.contains('high')) return BoxAlertSeverity.high;
  if (raw.contains('info') || raw.contains('low')) return BoxAlertSeverity.low;
  return BoxAlertSeverity.medium;
}

BoxAlertStatus _statusOf(String raw, String message) {
  final s = raw.toLowerCase();
  final m = message.toLowerCase();
  if (s.contains('recover') || m.contains('đã khôi phục') || m.contains('reconnect')) return BoxAlertStatus.recovered;
  if (s.contains('resolve') || s.contains('closed')) return BoxAlertStatus.resolved;
  if (s.contains('progress') || s.contains('đang xử')) return BoxAlertStatus.inProgress;
  if (s.contains('ack') || s.contains('notified')) return BoxAlertStatus.acknowledged;
  return BoxAlertStatus.open;
}

BoxAlertSource _sourceOf(String category, String sensorType, String message, String? code) {
  final hay = '$category $sensorType $message ${code ?? ''}'.toLowerCase();
  if (hay.contains('esp32')) return BoxAlertSource.esp32;
  if (hay.contains('camera')) return BoxAlertSource.camera;
  if (hay.contains('controller') || hay.contains('gateway')) return BoxAlertSource.controller;
  if (hay.contains('crab') || hay.contains('cua') || category.contains('crab')) return BoxAlertSource.crab;
  if (category.contains('ai') || hay.contains('ai phát hiện') || hay.contains('vận động')) return BoxAlertSource.ai;
  if (hay.contains('ph') || hay.contains('nhiệt') || hay.contains('temp') || hay.contains('tds') || hay.contains('do') || hay.contains('mặn') || category.contains('water')) {
    return BoxAlertSource.environment;
  }
  if (hay.contains('box') || hay.contains('hộp')) return BoxAlertSource.box;
  if (hay.contains('sensor') || hay.contains('cảm biến')) return BoxAlertSource.sensor;
  if (category.contains('device')) return BoxAlertSource.sensor;
  return BoxAlertSource.sensor;
}

String humanAlertTitle(String title, String message, BoxAlertSource source) {
  final hay = '$title $message'.toLowerCase();
  if (hay.contains('realtime_sensor') || (hay.contains('realtime') && hay.contains('cảm biến'))) return 'Cảm biến realtime mất kết nối';
  if (hay.contains('camera_offline') || (hay.contains('camera') && hay.contains('mất kết nối'))) return 'Camera mất kết nối';
  if (hay.contains('esp32_disconnect') || (hay.contains('esp32') && hay.contains('mất kết nối'))) return 'ESP32 mất kết nối';
  if (hay.contains('sensor_timeout') || hay.contains('không nhận dữ liệu cảm biến')) return 'Không nhận dữ liệu cảm biến';
  if (hay.contains('cảm biến') && hay.contains('mất kết nối')) return 'Cảm biến realtime mất kết nối';
  if ((hay.contains('nhiệt') || hay.contains('temp')) && (hay.contains('vượt') || hay.contains('cao') || hay.contains('thấp'))) return 'Nhiệt độ vượt ngưỡng';
  if (hay.contains('ph') && (hay.contains('vượt') || hay.contains('cao') || hay.contains('thấp'))) return 'pH vượt ngưỡng';
  if (hay.contains('ai') && (hay.contains('bất thường') || hay.contains('vận động'))) return 'AI phát hiện vận động bất thường';
  final t = title.trim();
  if (t.isEmpty) return source == BoxAlertSource.camera ? 'Camera mất kết nối' : 'Cảnh báo hộp';
  if (RegExp(r'^[a-z0-9_]+$').hasMatch(t)) {
    return switch (t) {
      'realtime_sensor' => 'Cảm biến realtime mất kết nối',
      'esp32_disconnect' => 'ESP32 mất kết nối',
      'camera_offline' => 'Camera mất kết nối',
      'sensor_timeout' => 'Không nhận dữ liệu cảm biến',
      _ => 'Cảnh báo hộp',
    };
  }
  return t.split('(').first.trim();
}

String humanAlertMessage(String message, String title, Object? trigger, Object? min, Object? max, String? unit) {
  var m = message.trim();
  m = m
      .replaceAll('realtime_sensor', '')
      .replaceAll('esp32_disconnect', '')
      .replaceAll('camera_offline', '')
      .replaceAll('sensor_timeout', '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (m.isEmpty || m == title) {
    if (title.contains('Camera')) return 'Không nhận được luồng hình ảnh.';
    if (title.contains('Cảm biến') || title.contains('ESP32')) return 'Không nhận được dữ liệu từ thiết bị.';
    if (trigger != null) return 'Giá trị: ${_num(trigger)}${unit == null ? '' : ' $unit'}';
    return title;
  }
  return m;
}

String? _cause(String message) {
  final m = message.toLowerCase();
  if (m.contains('heartbeat')) return 'Không nhận heartbeat từ thiết bị.';
  if (m.contains('timeout') || m.contains('mất kết nối')) return null;
  return null;
}

String _recommend(BoxAlertSource source, String sensorType, String? apiTip) {
  if ((apiTip ?? '').trim().isNotEmpty) return apiTip!.trim();
  return switch (source) {
    BoxAlertSource.camera || BoxAlertSource.ai => 'Kiểm tra nguồn điện, kết nối mạng và thử kết nối lại camera.',
    BoxAlertSource.esp32 || BoxAlertSource.controller || BoxAlertSource.sensor => 'Kiểm tra nguồn điện, kết nối mạng và Controller. Thử khởi động lại thiết bị.',
    BoxAlertSource.environment => 'Kiểm tra cảm biến và thông số nước, ghi nhận kết quả xử lý.',
    _ => 'Kiểm tra nguồn gốc cảnh báo và cập nhật trạng thái sau khi xử lý.',
  };
}

String? _deviceType(BoxAlertSource source, String sensorType) {
  return switch (source) {
    BoxAlertSource.sensor => 'Cảm biến môi trường',
    BoxAlertSource.environment => 'Cảm biến môi trường',
    BoxAlertSource.camera => 'Camera AI',
    BoxAlertSource.esp32 => 'ESP32',
    BoxAlertSource.controller => 'Controller',
    BoxAlertSource.ai => 'AI Camera',
    BoxAlertSource.crab => 'Cua',
    BoxAlertSource.box => 'Hộp nuôi',
    BoxAlertSource.all => null,
  };
}

bool _isEnvType(String t) {
  final s = t.toLowerCase();
  return s.contains('ph') || s.contains('temp') || s.contains('tds') || s.contains('do') || s.contains('salin') || s.contains('nhiệt');
}

String? _metricLabel(String type, String message) {
  final s = '$type $message'.toLowerCase();
  if (s.contains('ph')) return 'pH';
  if (s.contains('tds')) return 'TDS';
  if (s.contains('temp') || s.contains('nhiệt')) return 'Nhiệt độ';
  if (s.contains('do') || s.contains('oxy')) return 'DO';
  if (s.contains('mặn') || s.contains('salin')) return 'Độ mặn';
  return type.isEmpty ? null : type;
}

String? _unitOf(String type) {
  final s = type.toLowerCase();
  if (s.contains('temp') || s.contains('nhiệt')) return '°C';
  if (s.contains('tds')) return 'ppm';
  if (s.contains('do')) return 'mg/L';
  if (s.contains('salin') || s.contains('mặn')) return 'ppt';
  return null;
}

String _num(Object v) {
  if (v is num) return v == v.roundToDouble() ? v.toStringAsFixed(v is int ? 0 : 1) : v.toStringAsFixed(2);
  return '$v';
}

String? _threshold(Object? min, Object? max, String? unit) {
  if (min == null && max == null) return null;
  final u = unit == null ? '' : ' $unit';
  if (min != null && max != null) return '${_num(min)} – ${_num(max)}$u';
  if (max != null) return '> ${_num(max)}$u';
  return '< ${_num(min ?? '')}$u';
}

String? _actorName(String? raw) {
  if (raw == null || raw.trim().isEmpty || raw == 'null') return null;
  if (RegExp(r'^[0-9a-fA-F-]{20,}$').hasMatch(raw.trim())) return 'Người dùng';
  return raw.trim();
}
