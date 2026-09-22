import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../models/production_models.dart';
import '../../services/cloud_api_client.dart';
import '../../theme/dashboard_theme.dart';
import '../../widgets/shared/mgmt_ui.dart';

/// Tím chỉ dùng badge AI — không phải primary.
const _kAi = Color(0xFF7C3AED);
const _kBlue = Color(0xFF2495E8);

enum _Kind { alert, ai, device, user, system, watch, info }

extension on _Kind {
  String get label => switch (this) {
        _Kind.alert => 'Cảnh báo',
        _Kind.ai => 'AI',
        _Kind.device => 'Vận hành',
        _Kind.user => 'Thông tin',
        _Kind.system => 'Hệ thống',
        _Kind.watch => 'Theo dõi',
        _Kind.info => 'Thông tin',
      };
  Color get color => switch (this) {
        _Kind.alert => DashboardColors.risk,
        _Kind.ai => _kAi,
        _Kind.device => _kBlue,
        _Kind.user => DashboardColors.brandGreen,
        _Kind.system => kMgmtSlate,
        _Kind.watch => kMgmtAmber,
        _Kind.info => DashboardColors.brand,
      };
  IconData get icon => switch (this) {
        _Kind.alert => Icons.error_outline_rounded,
        _Kind.ai => Icons.auto_awesome_rounded,
        _Kind.device => Icons.settings_suggest_outlined,
        _Kind.user => Icons.person_outline_rounded,
        _Kind.system => Icons.dns_outlined,
        _Kind.watch => Icons.visibility_outlined,
        _Kind.info => Icons.info_outline_rounded,
      };
}

enum _Filter {
  all,
  alert,
  ai,
  environment,
  device,
  user,
  system,
}

extension on _Filter {
  String get label => switch (this) {
        _Filter.all => 'Tất cả loại sự kiện',
        _Filter.alert => 'Cảnh báo',
        _Filter.ai => 'AI phát hiện',
        _Filter.environment => 'Môi trường',
        _Filter.device => 'Vận hành thiết bị',
        _Filter.user => 'Thao tác người dùng',
        _Filter.system => 'Hệ thống',
      };
  bool matches(_Kind k) => switch (this) {
        _Filter.all => true,
        _Filter.alert => k == _Kind.alert,
        _Filter.ai => k == _Kind.ai,
        _Filter.environment => k == _Kind.watch,
        _Filter.device => k == _Kind.device,
        _Filter.user => k == _Kind.user || k == _Kind.info,
        _Filter.system => k == _Kind.system,
      };
}

enum _Sort { timeDesc, timeAsc, kind, row, actor }

class _Event {
  const _Event({
    required this.id,
    required this.at,
    required this.kind,
    required this.title,
    this.subtitle,
    this.objectLabel,
    this.rowLabel,
    this.actor,
    this.source,
    this.note,
    this.imageUrl,
    this.photos = const [],
    this.box,
    this.cameraCode,
    this.rasCode,
    this.extra = const [],
  });

  final String id;
  final DateTime at;
  final _Kind kind;
  final String title;
  final String? subtitle;
  final String? objectLabel;
  final String? rowLabel;
  final String? actor;
  final String? source;
  final String? note;
  final String? imageUrl;
  final List<String> photos;
  final BoxRecord? box;
  final String? cameraCode;
  final String? rasCode;
  final List<(String, String)> extra;

  bool get hasMedia =>
      (imageUrl ?? '').startsWith('http') || photos.any((u) => u.startsWith('http'));
}

/// Tab “Lịch sử & nhật ký” — audit log của một khu, dữ liệu thật từ BE.
class AreaHistoryTab extends StatefulWidget {
  const AreaHistoryTab({
    super.key,
    required this.token,
    required this.areaId,
    required this.areaName,
    required this.areaCode,
    required this.rows,
    required this.boxes,
    this.onOpenBox,
    this.onOpenCrab,
    this.onOpenCameras,
    this.onOpenRas,
  });

  final String token;
  final String areaId;
  final String areaName;
  final String areaCode;
  final List<RowRecord> rows;
  final List<BoxRecord> boxes;
  final void Function(BoxRecord box)? onOpenBox;
  final void Function(BoxRecord box)? onOpenCrab;
  final VoidCallback? onOpenCameras;
  final VoidCallback? onOpenRas;

  @override
  State<AreaHistoryTab> createState() => _AreaHistoryTabState();
}

class _AreaHistoryTabState extends State<AreaHistoryTab> {
  final _api = CloudApiClient();
  final _search = TextEditingController();

  List<_Event> _all = const [];
  bool _loading = true;
  String? _error;

  _Filter _filter = _Filter.all;
  String _rowId = '';
  String _boxId = '';
  DateTime? _from;
  DateTime? _to;
  _Sort _sort = _Sort.timeDesc;
  String? _selectedId;
  int _page = 0;
  int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _from = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 30));
    _to = DateTime(now.year, now.month, now.day, 23, 59, 59);
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final boxes = {for (final b in widget.boxes) b.id: b};
    final byCode = {for (final b in widget.boxes) b.boxCode.toLowerCase(): b};
    final areaBoxes = boxes.keys.toSet();
    final out = <_Event>[];
    final seen = <String>{};

    void add(_Event e) {
      if (seen.add(e.id)) out.add(e);
    }

    try {
      final alerts = await _api.fetchAlertHistory(
        widget.token,
        farmingAreaId: widget.areaId,
        days: 90,
      );
      for (final a in alerts) {
        final e = _fromAlert(a, boxes, byCode);
        if (e != null) add(e);
      }
    } catch (_) {}

    try {
      final dets = await _api.fetchAiDetections(
        widget.token,
        farmingAreaId: widget.areaId,
        take: 200,
      );
      for (final j in dets) {
        final e = _fromAi(j, boxes);
        if (e != null) add(e);
      }
    } catch (_) {}

    try {
      final ops = await _api.fetchOperations(widget.token, limit: 200);
      for (final o in ops) {
        final e = _fromOp(o, boxes, areaBoxes);
        if (e != null) add(e);
      }
    } catch (_) {}

    try {
      final recent = await _api.fetchOperationsRecent(
        widget.token,
        farmingAreaId: widget.areaId,
        limit: 80,
      );
      for (final r in recent) {
        final e = _fromRecent(r, boxes, byCode);
        if (e != null) add(e);
      }
    } catch (_) {}

    try {
      final wa = await _api.fetchWaterAnalysis(widget.token, widget.areaId);
      final e = _fromWater(wa);
      if (e != null) add(e);
    } catch (_) {}

    out.sort((a, b) => b.at.compareTo(a.at));
    if (!mounted) return;
    setState(() {
      _all = out;
      _loading = false;
      if (_selectedId == null && out.isNotEmpty) _selectedId = out.first.id;
    });
  }

  _Event? _fromAlert(
    Map<String, dynamic> a,
    Map<String, BoxRecord> boxes,
    Map<String, BoxRecord> byCode,
  ) {
    final at = _parseAt(a['createdAt'] ?? a['CreatedAt']);
    if (at == null) return null;
    final sev = (a['severity'] ?? a['Severity'] ?? '').toString().toLowerCase();
    final cat = (a['category'] ?? a['Category'] ?? '').toString().toLowerCase();
    final kind = sev.contains('crit') || sev.contains('high') || sev.contains('alert')
        ? _Kind.alert
        : (cat.contains('water') || cat.contains('sensor') || sev.contains('warn')
            ? _Kind.watch
            : _Kind.alert);
    final loc = (a['locationLabel'] ?? a['LocationLabel'] ?? '').toString();
    final sensor = (a['sensorCode'] ?? a['SensorCode'] ?? a['sensorType'] ?? '').toString();
    final box = _boxFromLoc(loc, boxes, byCode);
    final msg = (a['message'] ?? a['Message'] ?? '').toString();
    final title = (a['title'] ?? a['Title'] ?? 'Cảnh báo').toString();
    return _Event(
      id: 'al-${a['id'] ?? a['Id']}',
      at: at,
      kind: kind,
      title: title,
      subtitle: msg,
      objectLabel: box?.boxCode ?? (sensor.isEmpty ? loc : sensor),
      rowLabel: box?.rowName ?? _rowFromLoc(loc),
      actor: 'Hệ thống',
      source: sensor.isEmpty ? null : sensor,
      note: (a['aiRecommendation'] ?? a['AiRecommendation'] ?? msg).toString(),
      box: box,
      extra: [
        if ((a['triggerValue'] ?? a['TriggerValue']) != null)
          ('Giá trị kích hoạt', '${a['triggerValue'] ?? a['TriggerValue']}'),
        if ((a['status'] ?? a['Status']) != null)
          ('Trạng thái cảnh báo', '${a['status'] ?? a['Status']}'),
      ],
    );
  }

  _Event? _fromAi(Map<String, dynamic> j, Map<String, BoxRecord> boxes) {
    final at = _parseAt(j['detectedAt'] ?? j['DetectedAt']);
    if (at == null) return null;
    final type = (j['detectionType'] ?? j['DetectionType'] ?? '').toString().toLowerCase();
    final boxId = (j['boxId'] ?? j['BoxId'])?.toString();
    final box = boxId == null ? null : boxes[boxId];
    final boxCode = (j['boxCode'] ?? j['BoxCode'] ?? box?.boxCode ?? '').toString();
    final crab = (j['crabTag'] ?? j['CrabTag'] ?? box?.crabTag ?? '').toString();
    final cam = (j['deviceCode'] ?? j['DeviceCode'] ?? '').toString();
    final img = (j['imagePath'] ?? j['ImagePath'] ?? '').toString();
    final conf = j['confidence'] ?? j['Confidence'];
    final (title, sub) = _aiLabel(type);
    final object = [
      if (boxCode.isNotEmpty) boxCode,
      if (crab.isNotEmpty) crab,
    ].join('\n');
    return _Event(
      id: 'ai-${j['id'] ?? j['Id']}',
      at: at,
      kind: _Kind.ai,
      title: title,
      subtitle: sub,
      objectLabel: object.isEmpty ? '—' : object,
      rowLabel: (j['rowName'] ?? j['RowName'] ?? box?.rowName)?.toString(),
      actor: 'AI System',
      source: cam.isEmpty ? null : 'Camera $cam',
      imageUrl: img.startsWith('http') ? img : null,
      box: box,
      cameraCode: cam.isEmpty ? null : cam,
      extra: [
        if (conf is num) ('Độ tin cậy', '${(conf * 100).round()}%'),
        ('Loại phát hiện', type.isEmpty ? '—' : type),
      ],
    );
  }

  _Event? _fromOp(
    Map<String, dynamic> o,
    Map<String, BoxRecord> boxes,
    Set<String> areaBoxIds,
  ) {
    final at = _parseAt(o['timestamp'] ?? o['Timestamp']);
    if (at == null) return null;
    final boxIds = _strList(o['boxIds'] ?? o['BoxIds']);
    final crabIds = _strList(o['crabIds'] ?? o['CrabIds']);
    final loc = (o['locationLabel'] ?? o['LocationLabel'] ?? '').toString();
    final inArea = boxIds.any(areaBoxIds.contains) ||
        loc.toLowerCase().contains(widget.areaName.toLowerCase()) ||
        loc.toLowerCase().contains(widget.areaCode.toLowerCase());
    if (!inArea && boxIds.isNotEmpty) return null;
    if (!inArea && loc.isNotEmpty) return null;

    BoxRecord? box;
    for (final id in boxIds) {
      box = boxes[id];
      if (box != null) break;
    }
    final type = (o['type'] ?? o['Type'] ?? '').toString().toLowerCase();
    final source = (o['source'] ?? o['Source'] ?? '').toString().toLowerCase();
    final notes = (o['notes'] ?? o['Notes'] ?? '').toString();
    final actor = (o['operatorName'] ?? o['OperatorName'] ?? '').toString();
    final kind = _kindOfOp(type, source);
    final photos = _strList(o['photoUrls'] ?? o['PhotoUrls']);
    final crabTags = crabIds
        .map((id) => widget.boxes.where((b) => b.crabId == id).firstOrNull?.crabTag)
        .whereType<String>()
        .toList();
    final object = [
      if (box != null) box.boxCode,
      ...crabTags,
      if (box == null && loc.isNotEmpty) loc,
    ].join('\n');
    return _Event(
      id: 'op-${o['id'] ?? o['Id']}',
      at: at,
      kind: kind,
      title: _opTitle(type, notes),
      subtitle: notes,
      objectLabel: object.isEmpty ? '—' : object,
      rowLabel: box?.rowName ?? _rowFromLoc(loc),
      actor: actor.isEmpty
          ? (source == 'auto' ? 'Hệ thống' : '—')
          : actor,
      source: source == 'auto' ? 'Tự động' : 'Thủ công',
      note: notes,
      photos: photos,
      box: box,
      extra: [
        if ((o['quantity'] ?? o['Quantity']) != null)
          (
            'Số lượng',
            '${o['quantity'] ?? o['Quantity']} ${o['unit'] ?? o['Unit'] ?? ''}'.trim()
          ),
        if ((o['appetite'] ?? o['Appetite']) != null)
          ('Mức ăn', '${o['appetite'] ?? o['Appetite']}'),
        if ((o['foodType'] ?? o['FoodType']) != null)
          ('Loại thức ăn', '${o['foodType'] ?? o['FoodType']}'),
        if ((o['condition'] ?? o['Condition']) != null)
          ('Tình trạng ghi nhận', '${o['condition'] ?? o['Condition']}'),
      ],
    );
  }

  _Event? _fromRecent(
    Map<String, dynamic> r,
    Map<String, BoxRecord> boxes,
    Map<String, BoxRecord> byCode,
  ) {
    final at = _parseAt(r['timestamp'] ?? r['Timestamp']);
    if (at == null) return null;
    final type = (r['type'] ?? r['Type'] ?? '').toString().toLowerCase();
    final title = (r['title'] ?? r['Title'] ?? 'Hoạt động hệ thống').toString();
    final desc = (r['description'] ?? r['Description'] ?? '').toString();
    final hay = '$type $title $desc'.toLowerCase();
    final kind = hay.contains('ai') || hay.contains('phát hiện')
        ? _Kind.ai
        : (hay.contains('ras') || hay.contains('bơm') || hay.contains('sủi')
            ? _Kind.device
            : (hay.contains('alert') || hay.contains('cảnh báo')
                ? _Kind.alert
                : (hay.contains('sensor') || hay.contains('nhiệt') || hay.contains('no')
                    ? _Kind.watch
                    : _Kind.system)));
    final box = _boxFromLoc('$title $desc', boxes, byCode);
    final ras = RegExp(r'(RAS|OXY|CTRL)-\d+', caseSensitive: false).firstMatch('$title $desc');
    return _Event(
      id: 'rc-${r['id'] ?? r['Id']}',
      at: at,
      kind: kind,
      title: title,
      subtitle: desc,
      objectLabel: box?.boxCode ?? ras?.group(0) ?? '—',
      rowLabel: box?.rowName,
      actor: kind == _Kind.device && !title.toLowerCase().contains('hệ thống')
          ? 'Hệ thống'
          : 'Hệ thống',
      source: ras?.group(0),
      note: desc,
      box: box,
      rasCode: ras?.group(0),
    );
  }

  _Event? _fromWater(Map<String, dynamic> wa) {
    final latest = wa['latest'] ?? wa['Latest'];
    if (latest is! Map) return null;
    final j = Map<String, dynamic>.from(latest);
    final at = _parseAt(j['completedAt'] ?? j['CompletedAt'] ?? j['startedAt'] ?? j['StartedAt']);
    if (at == null) return null;
    return _Event(
      id: 'wa-${j['id'] ?? j['Id'] ?? at.millisecondsSinceEpoch}',
      at: at,
      kind: _Kind.system,
      title: 'Hoàn thành phân tích nước',
      subtitle: widget.areaName,
      objectLabel: widget.areaCode,
      actor: 'Hệ thống',
      source: 'Phân tích nước',
    );
  }

  static _Kind _kindOfOp(String type, String source) {
    if (type.contains('ras') || type.contains('pump') || type.contains('oxy')) {
      return _Kind.device;
    }
    if (type.contains('ai')) return _Kind.ai;
    if (source == 'auto') return _Kind.system;
    if (type.contains('water') || type.contains('no2') || type.contains('threshold')) {
      return _Kind.info;
    }
    return _Kind.user;
  }

  static String _opTitle(String type, String notes) {
    if (notes.trim().isNotEmpty) {
      final first = notes.split('\n').first.trim();
      if (first.length <= 80) return first;
    }
    return switch (type) {
      'feeding' => 'Ghi nhận cho ăn',
      'waterchange' => 'Thay nước',
      'cleaning' => 'Vệ sinh',
      'medication' => 'Dùng thuốc',
      'inspection' => 'Kiểm tra',
      'placebox' => 'Đã thêm cua vào hộp',
      'movebox' => 'Chuyển cua sang hộp khác',
      'inbound' => 'Nhập cua',
      'harvest' => 'Thu hoạch',
      'molting' => 'Ghi nhận lột xác',
      'ras' => 'Thao tác thiết bị RAS',
      _ => 'Thao tác khu nuôi',
    };
  }

  static (String, String?) _aiLabel(String type) {
    if (type.contains('molt')) return ('Phát hiện cua lột xác', null);
    if (type.contains('empty')) return ('Phát hiện hộp trống', '(không có cua)');
    if (type.contains('abnormal') || type.contains('anomal')) {
      return ('Cua di chuyển bất thường', '(phát hiện bởi AI)');
    }
    if (type.contains('quarantine')) return ('Hộp cách ly — nguy cơ bệnh', null);
    if (type.contains('water')) return ('Cảnh báo chất lượng nước', '(AI)');
    if (type.contains('dead')) return ('Nghi cua chết', null);
    if (type.contains('soft')) return ('Cua vỏ mềm sau lột', null);
    if (type.contains('occupancy')) return ('Cua trong hộp bình thường', null);
    if (type.contains('health')) return ('Kiểm tra sức khỏe định kỳ', null);
    return ('Phát hiện AI', type.isEmpty ? null : type);
  }

  BoxRecord? _boxFromLoc(
    String loc,
    Map<String, BoxRecord> boxes,
    Map<String, BoxRecord> byCode,
  ) {
    final m = RegExp(r'BOX[-_]?\d+', caseSensitive: false).firstMatch(loc);
    if (m != null) return byCode[m.group(0)!.toLowerCase()];
    return null;
  }

  String? _rowFromLoc(String loc) {
    final low = loc.toLowerCase();
    for (final r in widget.rows) {
      if (low.contains(r.rowName.toLowerCase()) ||
          low.contains(r.rowCode.toLowerCase())) {
        return r.rowName;
      }
    }
    return null;
  }

  static DateTime? _parseAt(dynamic v) =>
      DateTime.tryParse('$v')?.toLocal();

  static List<String> _strList(dynamic v) {
    if (v is List) {
      return v.map((e) => '$e').where((e) => e.isNotEmpty && e != 'null').toList();
    }
    return const [];
  }

  // ── Filter / sort ────────────────────────────────────────────────────────

  List<_Event> get _filtered {
    var list = _all.where((e) {
      if (_from != null && e.at.isBefore(_from!)) return false;
      if (_to != null && e.at.isAfter(_to!)) return false;
      if (!_filter.matches(e.kind)) return false;
      if (_rowId.isNotEmpty) {
        final row = widget.rows.where((r) => r.id == _rowId).firstOrNull;
        if (row == null) return false;
        final ok = e.box?.rowId == _rowId ||
            (e.rowLabel ?? '').toLowerCase() == row.rowName.toLowerCase() ||
            (e.rowLabel ?? '').toLowerCase() == row.rowCode.toLowerCase();
        if (!ok) return false;
      }
      if (_boxId.isNotEmpty && e.box?.id != _boxId) return false;
      final q = _search.text.trim().toLowerCase();
      if (q.isNotEmpty) {
        final hay = [
          e.title,
          e.subtitle ?? '',
          e.objectLabel ?? '',
          e.rowLabel ?? '',
          e.actor ?? '',
          e.source ?? '',
          e.cameraCode ?? '',
          e.rasCode ?? '',
        ].join(' ').toLowerCase();
        if (!hay.contains(q)) return false;
      }
      return true;
    }).toList();
    list.sort((a, b) => switch (_sort) {
          _Sort.timeDesc => b.at.compareTo(a.at),
          _Sort.timeAsc => a.at.compareTo(b.at),
          _Sort.kind => a.kind.label.compareTo(b.kind.label),
          _Sort.row => (a.rowLabel ?? '￿').compareTo(b.rowLabel ?? '￿'),
          _Sort.actor => (a.actor ?? '').compareTo(b.actor ?? ''),
        });
    return list;
  }

  _Event? get _selected {
    final id = _selectedId;
    if (id == null) return null;
    return _filtered.where((e) => e.id == id).firstOrNull ??
        _all.where((e) => e.id == id).firstOrNull;
  }

  int get _nAlert => _all.where((e) => e.kind == _Kind.alert).length;
  int get _nDevice => _all.where((e) => e.kind == _Kind.device).length;
  int get _nUser => _all.where((e) => e.kind == _Kind.user || e.kind == _Kind.info).length;
  int get _nAi => _all.where((e) => e.kind == _Kind.ai).length;
  int get _nSys => _all.where((e) => e.kind == _Kind.system).length;

  void _setFilter(_Filter f) {
    setState(() {
      _filter = _filter == f && f != _Filter.all ? _Filter.all : f;
      _page = 0;
    });
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year, now.month, now.day),
      initialDateRange: DateTimeRange(
        start: _from ?? now.subtract(const Duration(days: 30)),
        end: _to ?? now,
      ),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(
            primary: DashboardColors.brand,
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: DashboardColors.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      _from = DateTime(picked.start.year, picked.start.month, picked.start.day);
      _to = DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59);
      _page = 0;
    });
  }

  void _clearFilters() {
    final now = DateTime.now();
    setState(() {
      _filter = _Filter.all;
      _rowId = '';
      _boxId = '';
      _search.clear();
      _from = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 30));
      _to = DateTime(now.year, now.month, now.day, 23, 59, 59);
      _page = 0;
    });
  }

  Future<void> _export() async {
    final rows = _filtered;
    final sb = StringBuffer()
      ..writeln('Thoi gian,Loai,Noi dung,Doi tuong,Day,Nguoi thuc hien,Nguon');
    for (final e in rows) {
      String csv(String v) =>
          v.contains(',') || v.contains('"') || v.contains('\n')
              ? '"${v.replaceAll('"', '""')}"'
              : v;
      sb.writeln([
        csv(_fmtFull(e.at)),
        csv(e.kind.label),
        csv([e.title, if ((e.subtitle ?? '').isNotEmpty) e.subtitle].join(' ')),
        csv((e.objectLabel ?? '').replaceAll('\n', ' ')),
        csv(e.rowLabel ?? ''),
        csv(e.actor ?? ''),
        csv(e.source ?? ''),
      ].join(','));
    }
    final now = DateTime.now();
    final name =
        'crabsense_nhatky_${widget.areaCode}_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}.csv';
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Xuất nhật ký',
      fileName: name,
      type: FileType.custom,
      allowedExtensions: const ['csv'],
    );
    if (path == null || !mounted) return;
    try {
      await File(path).writeAsString('\uFEFF$sb');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã xuất ${rows.length} sự kiện: $path')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không ghi được file: $e')),
      );
    }
  }

  void _openObject(_Event e) {
    final b = e.box;
    if (b == null) return;
    if ((b.crabTag ?? '').isNotEmpty && widget.onOpenCrab != null) {
      widget.onOpenCrab!(b);
    } else {
      widget.onOpenBox?.call(b);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(48),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return MgmtEmptyState(
        icon: Icons.error_outline_rounded,
        title: 'Không tải được nhật ký',
        message: _error!,
        action: MgmtPrimaryButton(label: 'Thử lại', onTap: _load),
      );
    }

    final filtered = _filtered;
    final pages = (filtered.length / _pageSize).ceil().clamp(1, 999);
    final page = _page.clamp(0, pages - 1);
    final start = filtered.isEmpty ? 0 : page * _pageSize;
    final slice = filtered.skip(start).take(_pageSize).toList();
    final selected = _selected;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SummaryRow(
          total: _all.length,
          alert: _nAlert,
          device: _nDevice,
          user: _nUser,
          ai: _nAi,
          system: _nSys,
          active: _filter,
          onTap: _setFilter,
        ),
        const SizedBox(height: 14),
        LayoutBuilder(builder: (context, c) {
          final wide = c.maxWidth >= 1100;
          final table = _TableCard(
            total: filtered.length,
            from: _from,
            to: _to,
            onPickRange: _pickRange,
            filter: _filter,
            onFilter: (f) => setState(() {
              _filter = f;
              _page = 0;
            }),
            rows: widget.rows,
            rowId: _rowId,
            onRow: (id) => setState(() {
              _rowId = id;
              _page = 0;
            }),
            boxes: widget.boxes,
            boxId: _boxId,
            onBox: (id) => setState(() {
              _boxId = id;
              _page = 0;
            }),
            search: _search,
            onSearch: () => setState(() => _page = 0),
            onExport: _export,
            sort: _sort,
            onSort: (s) => setState(() => _sort = s),
            events: slice,
            selectedId: selected?.id,
            onSelect: (e) => setState(() => _selectedId = e.id),
            onView: (e) => setState(() => _selectedId = e.id),
            empty: filtered.isEmpty,
            onClear: _clearFilters,
            page: page,
            pageSize: _pageSize,
            totalPages: pages,
            onPage: (p) => setState(() => _page = p),
            onPageSize: (n) => setState(() {
              _pageSize = n;
              _page = 0;
            }),
          );
          final detail = _DetailPanel(
            event: selected,
            onClose: () => setState(() => _selectedId = null),
            onOpenBox: widget.onOpenBox,
            onOpenCrab: widget.onOpenCrab,
            onOpenCameras: widget.onOpenCameras,
            onOpenRas: widget.onOpenRas,
            onOpenObject: _openObject,
          );
          if (!wide) {
            return Column(children: [
              table,
              const SizedBox(height: 14),
              detail,
            ]);
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 75, child: table),
              const SizedBox(width: 14),
              Expanded(flex: 25, child: detail),
            ],
          );
        }),
      ],
    );
  }

  static String _fmtDay(DateTime? d) {
    if (d == null) return '—';
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year}';
  }

  static String _fmtFull(DateTime dt) {
    String two(int v) => v.toString().padLeft(2, '0');
    final l = dt.toLocal();
    return '${two(l.day)}/${two(l.month)}/${l.year} ${two(l.hour)}:${two(l.minute)}:${two(l.second)}';
  }
}

// ── Summary ────────────────────────────────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.total,
    required this.alert,
    required this.device,
    required this.user,
    required this.ai,
    required this.system,
    required this.active,
    required this.onTap,
  });

  final int total, alert, device, user, ai, system;
  final _Filter active;
  final ValueChanged<_Filter> onTap;

  @override
  Widget build(BuildContext context) {
    final items = <(_Filter, String, int, IconData, Color)>[
      (_Filter.all, 'Tất cả sự kiện', total, Icons.grid_view_rounded, DashboardColors.brand),
      (_Filter.alert, 'Cảnh báo', alert, Icons.error_outline_rounded, DashboardColors.risk),
      (_Filter.device, 'Vận hành thiết bị', device, Icons.settings_suggest_outlined, _kBlue),
      (_Filter.user, 'Thao tác người dùng', user, Icons.person_outline_rounded, DashboardColors.brandGreen),
      (_Filter.ai, 'AI phát hiện', ai, Icons.auto_awesome_rounded, _kAi),
      (_Filter.system, 'Nhật ký hệ thống', system, Icons.dns_outlined, kMgmtSlate),
    ];
    return LayoutBuilder(builder: (context, c) {
      final gap = 10.0;
      final w = ((c.maxWidth - gap * 5) / 6).clamp(140.0, 280.0);
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final it in items)
            SizedBox(
              width: w,
              child: _SumCard(
                label: it.$2,
                value: it.$3,
                icon: it.$4,
                color: it.$5,
                selected: active == it.$1,
                onTap: () => onTap(it.$1),
              ),
            ),
        ],
      );
    });
  }
}

class _SumCard extends StatelessWidget {
  const _SumCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final bool selected;
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? color : DashboardColors.cardBorder,
              width: selected ? 1.6 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: DashboardColors.brand.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: bvText(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: DashboardColors.textMuted,
                          letterSpacing: 0.3,
                        )),
                    Text('$value',
                        style: bvText(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: DashboardColors.textPrimary,
                          height: 1.15,
                        )),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Table card ─────────────────────────────────────────────────────────────

class _TableCard extends StatelessWidget {
  const _TableCard({
    required this.total,
    required this.from,
    required this.to,
    required this.onPickRange,
    required this.filter,
    required this.onFilter,
    required this.rows,
    required this.rowId,
    required this.onRow,
    required this.boxes,
    required this.boxId,
    required this.onBox,
    required this.search,
    required this.onSearch,
    required this.onExport,
    required this.sort,
    required this.onSort,
    required this.events,
    required this.selectedId,
    required this.onSelect,
    required this.onView,
    required this.empty,
    required this.onClear,
    required this.page,
    required this.pageSize,
    required this.totalPages,
    required this.onPage,
    required this.onPageSize,
  });

  final int total;
  final DateTime? from, to;
  final VoidCallback onPickRange;
  final _Filter filter;
  final ValueChanged<_Filter> onFilter;
  final List<RowRecord> rows;
  final String rowId;
  final ValueChanged<String> onRow;
  final List<BoxRecord> boxes;
  final String boxId;
  final ValueChanged<String> onBox;
  final TextEditingController search;
  final VoidCallback onSearch;
  final VoidCallback onExport;
  final _Sort sort;
  final ValueChanged<_Sort> onSort;
  final List<_Event> events;
  final String? selectedId;
  final ValueChanged<_Event> onSelect;
  final ValueChanged<_Event> onView;
  final bool empty;
  final VoidCallback onClear;
  final int page, pageSize, totalPages;
  final ValueChanged<int> onPage;
  final ValueChanged<int> onPageSize;

  @override
  Widget build(BuildContext context) {
    final rowLabel = rowId.isEmpty
        ? 'Tất cả dãy'
        : 'Dãy ${rows.where((r) => r.id == rowId).firstOrNull?.rowName ?? ''}';
    final boxLabel = boxId.isEmpty
        ? 'Tất cả hộp'
        : boxes.where((b) => b.id == boxId).firstOrNull?.boxCode ?? 'Tất cả hộp';
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: mgmtCardDeco(radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Expanded(
              child: Text('Lịch sử & nhật ký ($total)',
                  style: bvText(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: DashboardColors.textPrimary,
                  )),
            ),
            MgmtOutlineButton(
              icon: Icons.download_rounded,
              label: 'Xuất nhật ký',
              height: 36,
              onTap: onExport,
            ),
          ]),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 210,
                child: InkWell(
                  onTap: onPickRange,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 42,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: DashboardColors.cardBorder),
                    ),
                    child: Row(children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 16, color: DashboardColors.brand),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${_AreaHistoryTabState._fmtDay(from)} → ${_AreaHistoryTabState._fmtDay(to)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: bvText(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: DashboardColors.textPrimary,
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),
              ),
              MgmtDropdown<_Filter>(
                width: 190,
                valueLabel: filter.label,
                items: [for (final f in _Filter.values) (f, f.label)],
                onSelected: onFilter,
              ),
              MgmtDropdown<String>(
                width: 140,
                valueLabel: rowLabel,
                items: [
                  ('', 'Tất cả dãy'),
                  for (final r in rows) (r.id, r.rowName),
                ],
                onSelected: onRow,
              ),
              MgmtDropdown<String>(
                width: 150,
                valueLabel: boxLabel,
                items: [
                  ('', 'Tất cả hộp'),
                  for (final b in boxes) (b.id, b.boxCode),
                ],
                onSelected: onBox,
              ),
              SizedBox(
                width: 280,
                child: MgmtSearchField(
                  controller: search,
                  onChanged: (_) => onSearch(),
                  hint: 'Tìm kiếm theo nội dung, mã hộp, mã cua...',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (empty)
            MgmtEmptyState(
              icon: Icons.assignment_outlined,
              title: 'Không tìm thấy sự kiện',
              message: 'Không có lịch sử phù hợp với bộ lọc hiện tại.',
              action: MgmtOutlineButton(
                label: 'Xóa bộ lọc',
                height: 36,
                onTap: onClear,
              ),
            )
          else ...[
            _header(onSort, sort),
            for (final e in events)
              _Line(
                event: e,
                selected: e.id == selectedId,
                onTap: () => onSelect(e),
                onView: () => onView(e),
              ),
            const SizedBox(height: 12),
            _Pager(
              page: page,
              totalPages: totalPages,
              pageSize: pageSize,
              onPage: onPage,
              onPageSize: onPageSize,
            ),
          ],
        ],
      ),
    );
  }

  Widget _header(ValueChanged<_Sort> onSort, _Sort sort) {
    Widget col(String t, int flex, [_Sort? s]) {
      final active = s != null &&
          ((s == _Sort.timeDesc && (sort == _Sort.timeDesc || sort == _Sort.timeAsc)) ||
              sort == s);
      return Expanded(
        flex: flex,
        child: InkWell(
          onTap: s == null
              ? null
              : () {
                  if (s == _Sort.timeDesc) {
                    onSort(sort == _Sort.timeDesc ? _Sort.timeAsc : _Sort.timeDesc);
                  } else {
                    onSort(s);
                  }
                },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(children: [
              Flexible(
                child: Text(t,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: bvText(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: DashboardColors.textMuted,
                      letterSpacing: 0.4,
                    )),
              ),
              if (s != null)
                Icon(
                  sort == _Sort.timeAsc && s == _Sort.timeDesc
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  size: 12,
                  color: active ? DashboardColors.brand : DashboardColors.textMuted,
                ),
            ]),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: DashboardColors.lightMint,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(children: [
        col('THỜI GIAN', 14, _Sort.timeDesc),
        col('LOẠI SỰ KIỆN', 12, _Sort.kind),
        col('NỘI DUNG', 22),
        col('ĐỐI TƯỢNG', 12),
        col('DÃY', 7, _Sort.row),
        col('NGƯỜI THỰC HIỆN', 12, _Sort.actor),
        col('THAO TÁC', 6),
      ]),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({
    required this.event,
    required this.selected,
    required this.onTap,
    required this.onView,
  });
  final _Event event;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    final e = event;
    final cell = bvText(fontSize: 12, color: DashboardColors.textPrimary);
    return Material(
      color: selected ? DashboardColors.mint.withValues(alpha: 0.55) : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: DashboardColors.cardBorder, width: 0.8),
            ),
          ),
          child: Row(children: [
            Expanded(
              flex: 14,
              child: Text(_AreaHistoryTabState._fmtFull(e.at), style: cell),
            ),
            Expanded(flex: 12, child: _KindBadge(kind: e.kind)),
            Expanded(
              flex: 22,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: bvText(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: DashboardColors.textPrimary,
                      )),
                  if ((e.subtitle ?? '').isNotEmpty)
                    Text(e.subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: bvText(fontSize: 11, color: DashboardColors.textMuted)),
                ],
              ),
            ),
            Expanded(
              flex: 12,
              child: Text(
                (e.objectLabel ?? '—').replaceAll('\n', ' · '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: cell,
              ),
            ),
            Expanded(
              flex: 7,
              child: Text(e.rowLabel ?? '—', style: cell),
            ),
            Expanded(
              flex: 12,
              child: Text(e.actor ?? '—',
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: cell),
            ),
            Expanded(
              flex: 6,
              child: Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  tooltip: 'Xem chi tiết',
                  visualDensity: VisualDensity.compact,
                  onPressed: onView,
                  icon: const Icon(Icons.visibility_outlined,
                      size: 18, color: DashboardColors.brand),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _KindBadge extends StatelessWidget {
  const _KindBadge({required this.kind});
  final _Kind kind;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: kind.color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(kind.icon, size: 13, color: kind.color),
          const SizedBox(width: 4),
          Text(kind.label,
              style: bvText(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: kind.color,
              )),
        ]),
      ),
    );
  }
}

class _Pager extends StatelessWidget {
  const _Pager({
    required this.page,
    required this.totalPages,
    required this.pageSize,
    required this.onPage,
    required this.onPageSize,
  });
  final int page, totalPages, pageSize;
  final ValueChanged<int> onPage;
  final ValueChanged<int> onPageSize;

  @override
  Widget build(BuildContext context) {
    final idxs = <int>[];
    if (totalPages <= 7) {
      for (var i = 0; i < totalPages; i++) {
        idxs.add(i);
      }
    } else {
      idxs.addAll([0, 1, 2, 3, 4]);
      if (page > 4 && page < totalPages - 1) idxs.add(page);
      idxs.add(-1);
      idxs.add(totalPages - 1);
    }
    return Row(
      children: [
        MgmtPageBtn(
          icon: Icons.chevron_left_rounded,
          onTap: page > 0 ? () => onPage(page - 1) : null,
        ),
        for (final i in idxs) ...[
          const SizedBox(width: 6),
          if (i < 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text('…',
                  style: bvText(color: DashboardColors.textMuted, fontSize: 13)),
            )
          else
            MgmtPageBtn(
              label: '${i + 1}',
              active: i == page,
              onTap: () => onPage(i),
            ),
        ],
        const SizedBox(width: 6),
        MgmtPageBtn(
          icon: Icons.chevron_right_rounded,
          onTap: page < totalPages - 1 ? () => onPage(page + 1) : null,
        ),
        const Spacer(),
        Text('Hiển thị:',
            style: bvText(fontSize: 12, color: DashboardColors.textMuted)),
        const SizedBox(width: 8),
        MgmtDropdown<int>(
          width: 110,
          valueLabel: '$pageSize / trang',
          items: const [(10, '10 / trang'), (20, '20 / trang'), (50, '50 / trang'), (100, '100 / trang')],
          onSelected: onPageSize,
        ),
      ],
    );
  }
}

// ── Detail panel ───────────────────────────────────────────────────────────

class _DetailPanel extends StatelessWidget {
  const _DetailPanel({
    required this.event,
    required this.onClose,
    this.onOpenBox,
    this.onOpenCrab,
    this.onOpenCameras,
    this.onOpenRas,
    this.onOpenObject,
  });

  final _Event? event;
  final VoidCallback onClose;
  final void Function(BoxRecord box)? onOpenBox;
  final void Function(BoxRecord box)? onOpenCrab;
  final VoidCallback? onOpenCameras;
  final VoidCallback? onOpenRas;
  final void Function(_Event e)? onOpenObject;

  @override
  Widget build(BuildContext context) {
    final e = event;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: mgmtCardDeco(radius: 16),
      child: e == null
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Text('Chọn một sự kiện để xem chi tiết.',
                  textAlign: TextAlign.center,
                  style: bvText(fontSize: 13, color: DashboardColors.textMuted)),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(children: [
                  Expanded(
                    child: Text('Chi tiết sự kiện',
                        style: bvText(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: DashboardColors.textPrimary,
                        )),
                  ),
                  InkWell(
                    onTap: onClose,
                    borderRadius: BorderRadius.circular(8),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.close_rounded, size: 18),
                    ),
                  ),
                ]),
                const SizedBox(height: 10),
                _KindBadge(kind: e.kind),
                const SizedBox(height: 10),
                Text(e.title,
                    style: bvText(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: DashboardColors.textPrimary,
                      height: 1.25,
                    )),
                if ((e.subtitle ?? '').isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(e.subtitle!,
                      style: bvText(fontSize: 12.5, color: DashboardColors.textMuted, height: 1.35)),
                ],
                const SizedBox(height: 14),
                _kv('Thời gian', _AreaHistoryTabState._fmtFull(e.at)),
                _linkKv(
                  'Đối tượng',
                  e.objectLabel ?? '—',
                  onTap: e.box == null ? null : () => onOpenObject?.call(e),
                ),
                _kv('Dãy', e.rowLabel ?? '—'),
                _kv('Loại sự kiện', e.kind == _Kind.ai ? '${e.kind.label} (AI)' : e.kind.label),
                if ((e.source ?? '').isNotEmpty)
                  _linkKv(
                    'Nguồn',
                    e.source!,
                    onTap: e.cameraCode != null
                        ? onOpenCameras
                        : (e.rasCode != null ? onOpenRas : null),
                  ),
                _kv('Người thực hiện', e.actor ?? '—'),
                for (final x in e.extra) _kv(x.$1, x.$2),
                const SizedBox(height: 14),
                Text('Hình ảnh / Video liên quan',
                    style: bvText(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: DashboardColors.textPrimary,
                    )),
                const SizedBox(height: 8),
                if (e.hasMedia) _Media(event: e) else
                  Text('Không có hình ảnh/video cho sự kiện này.',
                      style: bvText(fontSize: 12.5, color: DashboardColors.textMuted)),
                if ((e.note ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text('Ghi chú',
                      style: bvText(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: DashboardColors.textPrimary,
                      )),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7FAF9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: DashboardColors.cardBorder),
                    ),
                    child: Text(e.note!.trim(),
                        style: bvText(
                          fontSize: 12.5,
                          color: DashboardColors.textPrimary,
                          height: 1.45,
                        )),
                  ),
                ],
                if (e.box != null) ...[
                  const SizedBox(height: 12),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    if (widgetOpenBox(e))
                      MgmtOutlineButton(
                        label: 'Mở hộp ${e.box!.boxCode}',
                        height: 32,
                        onTap: () => onOpenBox?.call(e.box!),
                      ),
                    if ((e.box!.crabTag ?? '').isNotEmpty && onOpenCrab != null)
                      MgmtOutlineButton(
                        label: 'Mở ${e.box!.crabTag}',
                        height: 32,
                        onTap: () => onOpenCrab!(e.box!),
                      ),
                  ]),
                ],
              ],
            ),
    );
  }

  bool widgetOpenBox(_Event e) => e.box != null && onOpenBox != null;

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 108,
              child: Text('$k:',
                  style: bvText(fontSize: 12, color: DashboardColors.textMuted)),
            ),
            Expanded(
              child: Text(v.replaceAll('\n', ' · '),
                  style: bvText(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: DashboardColors.textPrimary,
                  )),
            ),
          ],
        ),
      );

  Widget _linkKv(String k, String v, {VoidCallback? onTap}) {
    if (onTap == null) return _kv(k, v);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 108,
            child: Text('$k:',
                style: bvText(fontSize: 12, color: DashboardColors.textMuted)),
          ),
          Expanded(
            child: InkWell(
              onTap: onTap,
              child: Text(v.replaceAll('\n', ' · '),
                  style: bvText(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: DashboardColors.brand,
                  )),
            ),
          ),
        ],
      ),
    );
  }
}

class _Media extends StatelessWidget {
  const _Media({required this.event});
  final _Event event;

  @override
  Widget build(BuildContext context) {
    final url = event.imageUrl ?? event.photos.where((u) => u.startsWith('http')).firstOrNull;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: 16 / 10,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (url != null)
              Image.network(url, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _ph())
            else
              _ph(),
            Positioned(
              left: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _AreaHistoryTabState._fmtFull(event.at).split(' ').last,
                  style: bvText(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ph() => Container(
        color: DashboardColors.mint,
        alignment: Alignment.center,
        child: const Icon(Icons.videocam_outlined, color: DashboardColors.brand, size: 32),
      );
}
