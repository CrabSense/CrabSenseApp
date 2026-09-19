import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../models/crab_condition.dart';
import '../../models/production_models.dart';
import '../../services/cloud_api_client.dart';
import '../../theme/dashboard_theme.dart';
import '../../widgets/camera/camera_stream_player.dart';
import '../../widgets/shared/mgmt_ui.dart';

/// Màu tím chỉ dùng cho trạng thái "Lột xác".
const _kMolt = Color(0xFF7C3AED);
const _kCamFallback = 'assets/images/maps.png';

// ─────────────────────────────────────────────────────────────────────────────
// Models
// ─────────────────────────────────────────────────────────────────────────────

enum _CamStatus { online, connecting, offline }

extension on _CamStatus {
  String get badge => switch (this) {
        _CamStatus.online => 'LIVE',
        _CamStatus.connecting => 'Đang kết nối',
        _CamStatus.offline => 'OFFLINE',
      };
  String get label => switch (this) {
        _CamStatus.online => 'Trực tuyến',
        _CamStatus.connecting => 'Đang kết nối',
        _CamStatus.offline => 'Mất kết nối',
      };
  Color get color => switch (this) {
        _CamStatus.online => DashboardColors.brandGreen,
        _CamStatus.connecting => kMgmtAmber,
        _CamStatus.offline => DashboardColors.risk,
      };
}

class _Cam {
  const _Cam({
    required this.id,
    required this.code,
    required this.name,
    required this.status,
    this.lastSeenAt,
    this.ipAddress,
    this.streamUrl,
    this.snapshotUrl,
    this.resolution,
    this.row,
    this.raw = const {},
  });

  final String id;
  final String code;
  final String name;
  final _CamStatus status;
  final DateTime? lastSeenAt;
  final String? ipAddress;
  final String? streamUrl;
  final String? snapshotUrl;

  /// Độ phân giải khai báo trên thiết bị (BE `resolution`), vd. "1080p".
  final String? resolution;

  /// Dãy camera quan sát (BE `farmingRowId`, dự phòng khớp tên/mã) — null = tổng quan khu.
  final RowRecord? row;
  final Map<String, dynamic> raw;

  bool get isOnline => status == _CamStatus.online;
  String get scopeLabel => row == null ? 'Khu tổng quan' : 'Dãy ${row!.rowName}';
  String get title => '$code | $scopeLabel';

  static _Cam fromDevice(Map<String, dynamic> d, List<RowRecord> rows) {
    String s(List<String> keys) {
      for (final k in keys) {
        final v = d[k];
        if (v != null && '$v'.isNotEmpty && '$v' != 'null') return '$v';
      }
      return '';
    }

    final code = s(['deviceCode', 'DeviceCode']);
    final name = s(['name', 'Name']);
    final statusRaw = s(['status', 'Status']).toLowerCase();
    final lastSeen = DateTime.tryParse(s(['lastSeenAt', 'LastSeenAt']))?.toLocal();
    final recentlySeen =
        lastSeen != null && DateTime.now().difference(lastSeen).inMinutes < 15;
    final status = statusRaw == 'online' || (statusRaw.isEmpty && recentlySeen)
        ? _CamStatus.online
        : statusRaw == 'maintenance'
            ? _CamStatus.connecting
            : _CamStatus.offline;

    final fw = s(['firmwareVersion', 'FirmwareVersion']);
    final ip = s(['ipAddress', 'IpAddress']);
    // BE đã resolve StreamUrl/SnapshotUrl (Device.StreamUrl → FirmwareVersion URL → IP ESP32-CAM).
    // Giữ fallback phía client cho BE cũ chưa có trường này.
    String? stream = s(['streamUrl', 'StreamUrl']).isEmpty ? null : s(['streamUrl', 'StreamUrl']);
    String? snapshot =
        s(['snapshotUrl', 'SnapshotUrl']).isEmpty ? null : s(['snapshotUrl', 'SnapshotUrl']);
    if (stream == null) {
      final fwl = fw.toLowerCase();
      if (fwl.startsWith('rtsp://') || fwl.startsWith('http://') || fwl.startsWith('https://')) {
        stream = fw;
      } else if (ip.isNotEmpty) {
        final host = ip.startsWith('http') ? ip : 'http://$ip';
        stream = '$host/stream';
        snapshot ??= '$host/capture';
      }
    }
    final resolution = s(['resolution', 'Resolution']);

    // Dãy: ưu tiên farmingRowId từ BE; dự phòng khớp tên/mã dãy nguyên từ trong tên/mã camera.
    RowRecord? row;
    final rowId = s(['farmingRowId', 'FarmingRowId']);
    if (rowId.isNotEmpty) row = rows.where((r) => r.id == rowId).firstOrNull;
    if (row == null && rowId.isEmpty) {
      final hay = '$name $code';
      for (final r in rows) {
        for (final key in [r.rowName, r.rowCode]) {
          if (key.trim().isEmpty) continue;
          final re = RegExp('(^|[^A-Za-z0-9])${RegExp.escape(key)}([^A-Za-z0-9]|\$)',
              caseSensitive: false);
          if (re.hasMatch(hay)) {
            row = r;
            break;
          }
        }
        if (row != null) break;
      }
    }

    return _Cam(
      id: s(['id', 'Id']),
      code: code.isEmpty ? 'CAM' : code,
      name: name.isEmpty ? code : name,
      status: status,
      lastSeenAt: lastSeen,
      ipAddress: ip.isEmpty ? null : ip,
      streamUrl: stream,
      snapshotUrl: snapshot,
      resolution: resolution.isEmpty ? null : resolution,
      row: row,
      raw: d,
    );
  }
}

enum _Level { normal, watch, alert, molting }

extension on _Level {
  String get label => switch (this) {
        _Level.normal => 'Bình thường',
        _Level.watch => 'Theo dõi',
        _Level.alert => 'Cảnh báo',
        _Level.molting => 'Lột xác',
      };
  Color get color => switch (this) {
        _Level.normal => DashboardColors.brandGreen,
        _Level.watch => kMgmtAmber,
        _Level.alert => DashboardColors.risk,
        _Level.molting => _kMolt,
      };
}

class _AiEvent {
  const _AiEvent({
    required this.id,
    required this.at,
    required this.type,
    required this.typeLabel,
    required this.level,
    required this.confidence,
    this.box,
    this.note,
    this.deviceId,
    this.deviceCode,
    this.imageUrl,
    this.boxCode,
    this.crabTag,
    this.raw = const {},
  });

  final String id;
  final DateTime at;
  final String type;
  final String typeLabel;
  final _Level level;
  final double confidence;
  final BoxRecord? box;
  final String? note;

  /// Camera ghi nhận (BE `deviceId`/`deviceCode`).
  final String? deviceId;
  final String? deviceCode;

  /// Ảnh phát hiện (BE `imagePath`) — dùng làm thumbnail.
  final String? imageUrl;

  /// Mã hộp / mã cua do BE ghép sẵn (dự phòng khi hộp không còn trong danh sách khu).
  final String? boxCode;
  final String? crabTag;
  final Map<String, dynamic> raw;

  bool get isCrabEvent =>
      (box?.hasCrab == true || (crabTag ?? '').isNotEmpty) &&
      (type.contains('molt') ||
          type.contains('soft') ||
          type.contains('quarantine') ||
          type.contains('health'));

  String get objectLabel {
    final b = box;
    if (isCrabEvent) {
      final tag = (b?.crabTag ?? '').isNotEmpty ? b!.crabTag! : (crabTag ?? '');
      if (tag.isNotEmpty) return tag;
    }
    if (b != null) return b.boxCode;
    return (boxCode ?? '').isNotEmpty ? boxCode! : '—';
  }

  static _AiEvent? fromJson(Map<String, dynamic> j, Map<String, BoxRecord> boxes) {
    final at = DateTime.tryParse((j['detectedAt'] ?? j['DetectedAt'] ?? '').toString())
        ?.toLocal();
    if (at == null) return null;
    final type = (j['detectionType'] ?? j['DetectionType'] ?? '').toString().toLowerCase();
    final boxId = (j['boxId'] ?? j['BoxId'])?.toString();
    final conf = j['confidence'] ?? j['Confidence'];
    String? str(List<String> keys) {
      for (final k in keys) {
        final v = j[k];
        if (v != null && '$v'.isNotEmpty && '$v' != 'null') return '$v';
      }
      return null;
    }
    final img = str(['imagePath', 'ImagePath']);
    final imgOk = img != null && (img.startsWith('http://') || img.startsWith('https://'));
    String? note;
    final rj = (j['resultJson'] ?? j['ResultJson'])?.toString();
    if (rj != null && rj.isNotEmpty) {
      final m = RegExp(r'"note"\s*:\s*"((?:[^"\\]|\\.)*)"').firstMatch(rj);
      note = m?.group(1)?.replaceAll(r'\"', '"');
    }
    final (label, level) = _describe(type);
    return _AiEvent(
      id: (j['id'] ?? j['Id'] ?? '').toString(),
      at: at,
      type: type,
      typeLabel: label,
      level: level,
      confidence: conf is num ? conf.toDouble() : 0,
      box: boxId == null ? null : boxes[boxId],
      note: note,
      deviceId: str(['deviceId', 'DeviceId']),
      deviceCode: str(['deviceCode', 'DeviceCode']),
      imageUrl: imgOk ? img : null,
      boxCode: str(['boxCode', 'BoxCode']),
      crabTag: str(['crabTag', 'CrabTag']),
      raw: j,
    );
  }

  static (String, _Level) _describe(String type) {
    if (type.contains('molt')) return ('Phát hiện cua lột xác', _Level.molting);
    if (type.contains('soft')) return ('Cua vỏ mềm sau lột', _Level.molting);
    if (type.contains('empty')) return ('Không có cua trong hộp', _Level.normal);
    if (type.contains('quarantine')) return ('Hộp cách ly — nguy cơ bệnh', _Level.alert);
    if (type.contains('water')) return ('Cảnh báo chất lượng nước', _Level.alert);
    if (type.contains('abnormal') || type.contains('anomal')) {
      return ('Cua di chuyển bất thường', _Level.alert);
    }
    if (type.contains('dead') || type.contains('mortal')) return ('Nghi cua chết', _Level.alert);
    if (type.contains('feed')) return ('Cua ăn mồi', _Level.normal);
    if (type.contains('occupancy')) return ('Cua trong hộp bình thường', _Level.normal);
    if (type.contains('health')) return ('Kiểm tra sức khỏe định kỳ', _Level.normal);
    return (type.isEmpty ? 'Phát hiện AI' : type, _Level.watch);
  }
}

enum _ViewMode { grid, list }

enum _CamFilter { all, online, offline }

// ─────────────────────────────────────────────────────────────────────────────
// Tab
// ─────────────────────────────────────────────────────────────────────────────

class AreaCamerasTab extends StatefulWidget {
  const AreaCamerasTab({
    super.key,
    required this.token,
    required this.areaId,
    required this.areaName,
    required this.rows,
    required this.boxes,
    this.onOpenBox,
    this.onOpenCrab,
    this.onOpenAlerts,
    this.onAddCamera,
  });

  final String token;
  final String areaId;
  final String areaName;
  final List<RowRecord> rows;
  final List<BoxRecord> boxes;
  final void Function(BoxRecord box)? onOpenBox;
  final void Function(BoxRecord box)? onOpenCrab;
  final VoidCallback? onOpenAlerts;
  final VoidCallback? onAddCamera;

  @override
  State<AreaCamerasTab> createState() => _AreaCamerasTabState();
}

class _AreaCamerasTabState extends State<AreaCamerasTab> {
  final _api = CloudApiClient();
  final _mainKey = GlobalKey();
  Timer? _poll;

  List<_Cam> _cams = const [];
  List<_AiEvent> _events = const [];
  bool _loading = true;
  bool _aiLoaded = false;
  String? _error;

  String? _mainId;
  _ViewMode _view = _ViewMode.grid;
  _CamFilter _filter = _CamFilter.all;
  String _rowFilter = ''; // '' = tất cả dãy
  bool _paused = false;
  bool _muted = false;
  String _quality = 'HD';

  @override
  void initState() {
    super.initState();
    _loadAll();
    _poll = Timer.periodic(const Duration(seconds: 15), (_) => _loadCams(silent: true));
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  // ── Loading ──────────────────────────────────────────────────────────────

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    await Future.wait([_loadCams(), _loadAi()]);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadCams({bool silent = false}) async {
    try {
      final devices =
          await _api.fetchCrabSenseDevices(widget.token, farmingAreaId: widget.areaId);
      final cams = devices
          .where((d) => (d['deviceType'] ?? d['DeviceType'] ?? '')
              .toString()
              .toLowerCase()
              .contains('cam'))
          .map((d) => _Cam.fromDevice(d, widget.rows))
          .toList()
        ..sort((a, b) => a.code.compareTo(b.code));
      if (!mounted) return;
      setState(() {
        _cams = cams;
        _error = null;
        if (_mainId == null || !cams.any((c) => c.id == _mainId)) {
          // Ưu tiên camera tổng quan đang online làm camera chính.
          final pick = cams.where((c) => c.row == null && c.isOnline).firstOrNull ??
              cams.where((c) => c.isOnline).firstOrNull ??
              cams.firstOrNull;
          _mainId = pick?.id;
        }
      });
    } catch (e) {
      if (!silent && mounted) setState(() => _error = '$e');
    }
  }

  Future<void> _loadAi() async {
    try {
      // BE lọc theo khu (hộp→dãy→khu hoặc camera của khu) và trả 200 bản ghi mới nhất.
      final raw = await _api.fetchAiDetections(
        widget.token,
        farmingAreaId: widget.areaId,
        take: 200,
      );
      final byId = {for (final b in widget.boxes) b.id: b};
      final out = <_AiEvent>[];
      for (final j in raw) {
        final e = _AiEvent.fromJson(j, byId);
        if (e == null) continue;
        // Giữ phát hiện thuộc hộp của khu, hoặc BE đã xác nhận thuộc khu (qua camera).
        final areaOk = (j['farmingAreaId'] ?? j['FarmingAreaId'] ?? '').toString() == widget.areaId;
        if (e.box == null && !areaOk) continue;
        out.add(e);
      }
      out.sort((a, b) => b.at.compareTo(a.at));
      if (mounted) {
        setState(() {
          _events = out;
          _aiLoaded = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _aiLoaded = true);
    }
  }

  // ── Derived ──────────────────────────────────────────────────────────────

  _Cam? get _main => _cams.where((c) => c.id == _mainId).firstOrNull;

  List<_Cam> get _filtered => _cams.where((c) {
        if (_filter == _CamFilter.online && !c.isOnline) return false;
        if (_filter == _CamFilter.offline && c.isOnline) return false;
        if (_rowFilter.isNotEmpty && c.row?.id != _rowFilter) return false;
        return true;
      }).toList();

  /// Hộp trong tầm quan sát của camera (theo dãy, hoặc cả khu).
  List<BoxRecord> _scope(_Cam? cam) {
    if (cam?.row == null) return widget.boxes;
    return widget.boxes.where((b) => b.rowId == cam!.row!.id).toList();
  }

  List<_AiEvent> _eventsFor(_Cam? cam) {
    if (cam?.row == null) return _events;
    final ids = _scope(cam).map((b) => b.id).toSet();
    return _events
        .where((e) => e.deviceId == cam!.id || (e.box != null && ids.contains(e.box!.id)))
        .toList();
  }

  /// Camera "phụ trách" một hộp: camera theo dãy của hộp, nếu không có → camera tổng quan.
  _Cam? _camForBox(BoxRecord? b) {
    if (b == null) return null;
    return _cams.where((c) => c.row?.id == b.rowId).firstOrNull ??
        _cams.where((c) => c.row == null).firstOrNull ??
        _cams.firstOrNull;
  }

  /// Camera ghi nhận sự kiện: theo `deviceId` BE trả về, dự phòng suy từ hộp.
  _Cam? _camForEvent(_AiEvent e) {
    if (e.deviceId != null) {
      final c = _cams.where((c) => c.id == e.deviceId).firstOrNull;
      if (c != null) return c;
    }
    return _camForBox(e.box);
  }

  /// Trạng thái AI của camera: null = chưa khởi tạo.
  (String, Color, bool)? _aiStatus(_Cam cam) {
    if (!cam.isOnline) return null;
    if (!_aiLoaded) return ('Đang tải AI...', kMgmtSlate, false);
    final ev = _eventsFor(cam);
    if (ev.isEmpty) return ('Đang khởi tạo AI...', kMgmtAmber, false);
    final recent = DateTime.now().difference(ev.first.at).inHours < 24;
    return recent
        ? ('Đang phân tích', DashboardColors.brandGreen, true)
        : ('Phân tích gần nhất ${_ago(DateTime.now().difference(ev.first.at))}', kMgmtSlate, true);
  }

  // ── Actions ──────────────────────────────────────────────────────────────

  void _select(_Cam c) {
    if (!c.isOnline) {
      _showOffline(c);
      return;
    }
    setState(() {
      _mainId = c.id;
      _paused = false;
    });
  }

  void _showOffline(_Cam c) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          const Icon(Icons.videocam_off_outlined, color: DashboardColors.risk),
          const SizedBox(width: 8),
          Text(c.code, style: bvText(fontSize: 16, fontWeight: FontWeight.w800)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(c.status.label,
                style: bvText(fontSize: 14, fontWeight: FontWeight.w700,
                    color: c.status.color)),
            const SizedBox(height: 6),
            Text('Lần kết nối cuối: ${fmtDateTimeVn(c.lastSeenAt)}',
                style: bvText(fontSize: 12.5, color: DashboardColors.textMuted)),
            if (c.ipAddress != null)
              Text('IP: ${c.ipAddress}',
                  style: bvText(fontSize: 12.5, color: DashboardColors.textMuted)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng')),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: DashboardColors.brand),
            onPressed: () async {
              Navigator.pop(ctx);
              await _loadCams();
              if (!mounted) return;
              final now = _cams.where((x) => x.id == c.id).firstOrNull;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(now?.isOnline == true
                    ? '${c.code} đã kết nối lại.'
                    : '${c.code} vẫn chưa phản hồi. Kiểm tra nguồn / mạng của camera.'),
              ));
            },
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Thử kết nối lại'),
          ),
        ],
      ),
    );
  }

  Future<void> _snapshot() async {
    final cam = _main;
    if (cam == null) return;
    try {
      final boundary =
          _mainKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final img = await boundary.toImage(pixelRatio: 2);
      final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) return;
      final now = DateTime.now();
      String two(int v) => v.toString().padLeft(2, '0');
      final name =
          '${cam.code}_${now.year}${two(now.month)}${two(now.day)}_${two(now.hour)}${two(now.minute)}${two(now.second)}.png';
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Lưu ảnh chụp camera',
        fileName: name,
        type: FileType.custom,
        allowedExtensions: const ['png'],
      );
      if (path == null || !mounted) return;
      await File(path).writeAsBytes(bytes.buffer.asUint8List());
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Đã lưu ảnh: $path')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Không chụp được ảnh: $e')));
    }
  }

  void _fullscreen() {
    final cam = _main;
    if (cam == null) return;
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.92),
      builder: (ctx) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: _MainCamera(
                cam: cam,
                scope: _scope(cam),
                aiStatus: _aiStatus(cam),
                paused: false,
                muted: _muted,
                quality: _quality,
                onPause: null,
                onMute: null,
                onQuality: null,
                onSnapshot: null,
                onFullscreen: () => Navigator.pop(ctx),
                onRefresh: _loadCams,
                onReconnect: () => _showOffline(cam),
                fullscreen: true,
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: IconButton(
                tooltip: 'Thoát (Esc)',
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(Icons.close_rounded, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEvent(_AiEvent e) {
    final cam = _camForEvent(e);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: e.level.color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(e.typeLabel,
                style: bvText(fontSize: 16, fontWeight: FontWeight.w800)),
          ),
        ]),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (e.imageUrl != null) ...[
                Center(child: _EventThumb(event: e, width: 400, height: 220)),
                const SizedBox(height: 12),
              ],
              _kv('Thời gian', fmtDateTimeVn(e.at)),
              _kv('Camera', cam?.title ?? e.deviceCode ?? '—'),
              _kv('Hộp', e.box?.boxCode ?? e.boxCode ?? '—'),
              if ((e.box?.crabTag ?? e.crabTag ?? '').isNotEmpty)
                _kv('Cua', e.box?.crabTag ?? e.crabTag!),
              if ((e.box?.rowName ?? e.raw['rowName'] ?? e.raw['RowName']) != null)
                _kv('Dãy', (e.box?.rowName ?? e.raw['rowName'] ?? e.raw['RowName']).toString()),
              _kv('Mức độ', e.level.label),
              _kv('Độ tin cậy', '${(e.confidence * 100).round()}%'),
              _kv('Mô hình', (e.raw['modelVersion'] ?? e.raw['ModelVersion'] ?? '—').toString()),
              if (e.note != null && e.note!.isNotEmpty) _kv('Ghi chú AI', e.note!),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng')),
          if (e.box != null && widget.onOpenBox != null)
            OutlinedButton(
              onPressed: () {
                Navigator.pop(ctx);
                widget.onOpenBox!(e.box!);
              },
              child: const Text('Mở hộp'),
            ),
          if (e.isCrabEvent && e.box != null && widget.onOpenCrab != null)
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: DashboardColors.brand),
              onPressed: () {
                Navigator.pop(ctx);
                widget.onOpenCrab!(e.box!);
              },
              child: const Text('Mở chi tiết cua'),
            ),
        ],
      ),
    );
  }

  /// Cấu hình camera: gán dãy, URL stream/snapshot, độ phân giải (PUT /api/devices/{id}).
  Future<void> _configureCam(_Cam c) async {
    const emptyGuid = '00000000-0000-0000-0000-000000000000';
    final rawStream = (c.raw['streamUrl'] ?? c.raw['StreamUrl'])?.toString() ?? '';
    final rawSnapshot = (c.raw['snapshotUrl'] ?? c.raw['SnapshotUrl'])?.toString() ?? '';
    final streamCtl = TextEditingController(text: rawStream == 'null' ? '' : rawStream);
    final snapshotCtl = TextEditingController(text: rawSnapshot == 'null' ? '' : rawSnapshot);
    final resCtl = TextEditingController(text: c.resolution ?? '');
    String rowId = c.row?.id ?? '';
    bool saving = false;
    String? err;

    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          InputDecoration deco(String label, String hint) => InputDecoration(
                labelText: label,
                hintText: hint,
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              );
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text('Cấu hình ${c.code}',
                style: bvText(fontSize: 16, fontWeight: FontWeight.w800)),
            content: SizedBox(
              width: 460,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: rowId,
                    decoration: deco('Dãy quan sát', ''),
                    items: [
                      const DropdownMenuItem(value: '', child: Text('Khu tổng quan (không gán dãy)')),
                      for (final r in widget.rows)
                        DropdownMenuItem(value: r.id, child: Text('Dãy ${r.rowName} · ${r.rowCode}')),
                    ],
                    onChanged: saving ? null : (v) => setS(() => rowId = v ?? ''),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: streamCtl,
                    enabled: !saving,
                    decoration: deco('URL stream', 'rtsp://… hoặc http://ip/stream'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: snapshotCtl,
                    enabled: !saving,
                    decoration: deco('URL ảnh chụp (tuỳ chọn)', 'http://ip/capture'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: resCtl,
                    enabled: !saving,
                    decoration: deco('Độ phân giải', '1080p, 720p…'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Để trống URL stream → hệ thống tự suy từ địa chỉ IP (ESP32-CAM: /stream, /capture).',
                    style: bvText(fontSize: 11.5, color: DashboardColors.textMuted),
                  ),
                  if (err != null) ...[
                    const SizedBox(height: 8),
                    Text(err!, style: bvText(fontSize: 12, color: DashboardColors.risk)),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.pop(ctx, false),
                child: const Text('Huỷ'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: DashboardColors.brand),
                onPressed: saving
                    ? null
                    : () async {
                        setS(() {
                          saving = true;
                          err = null;
                        });
                        try {
                          await _api.updateController(
                            widget.token,
                            c.id,
                            farmingRowId: rowId.isEmpty ? emptyGuid : rowId,
                            streamUrl: streamCtl.text.trim(),
                            snapshotUrl: snapshotCtl.text.trim(),
                            resolution: resCtl.text.trim(),
                          );
                          if (ctx.mounted) Navigator.pop(ctx, true);
                        } catch (e) {
                          setS(() {
                            saving = false;
                            err = '$e';
                          });
                        }
                      },
                child: saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Lưu'),
              ),
            ],
          );
        },
      ),
    );
    streamCtl.dispose();
    snapshotCtl.dispose();
    resCtl.dispose();
    if (saved == true) {
      await _loadCams(silent: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã lưu cấu hình ${c.code}.')),
        );
      }
    }
  }

  void _openObject(_AiEvent e) {
    final b = e.box;
    if (b == null) return;
    if (e.isCrabEvent && widget.onOpenCrab != null) {
      widget.onOpenCrab!(b);
    } else {
      widget.onOpenBox?.call(b);
    }
  }

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 100,
              child: Text(k, style: bvText(fontSize: 12.5, color: DashboardColors.textMuted)),
            ),
            Expanded(
              child: Text(v,
                  style: bvText(fontSize: 12.5, fontWeight: FontWeight.w600,
                      color: DashboardColors.textPrimary)),
            ),
          ],
        ),
      );

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(48),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final online = _cams.where((c) => c.isOnline).length;
    final main = _main;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Header + toolbar ───────────────────────────────────────────────
        Row(
          children: [
            Flexible(
              child: Text(
                'Camera giám sát ${widget.areaName}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: bvText(fontSize: 16, fontWeight: FontWeight.w800,
                    color: DashboardColors.textPrimary),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: _cams.isEmpty
                    ? kMgmtSlate
                    : online == _cams.length
                        ? DashboardColors.brandGreen
                        : online == 0
                            ? DashboardColors.risk
                            : kMgmtAmber,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              '$online/${_cams.length} camera trực tuyến',
              style: bvText(fontSize: 12, fontWeight: FontWeight.w600,
                  color: DashboardColors.textMuted),
            ),
            if (_error != null) ...[
              const SizedBox(width: 12),
              Text(_error!, style: bvText(fontSize: 12, color: DashboardColors.risk)),
            ],
            const Spacer(),
            SizedBox(
              height: 38,
              child: MgmtDropdown<_CamFilter>(
                width: 150,
                valueLabel: switch (_filter) {
                  _CamFilter.all => 'Tất cả camera',
                  _CamFilter.online => 'Đang trực tuyến',
                  _CamFilter.offline => 'Mất kết nối',
                },
                items: const [
                  (_CamFilter.all, 'Tất cả camera'),
                  (_CamFilter.online, 'Đang trực tuyến'),
                  (_CamFilter.offline, 'Mất kết nối'),
                ],
                onSelected: (v) => setState(() => _filter = v),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 38,
              child: MgmtDropdown<String>(
                width: 140,
                valueLabel: _rowFilter.isEmpty
                    ? 'Tất cả dãy'
                    : 'Dãy ${widget.rows.where((r) => r.id == _rowFilter).firstOrNull?.rowName ?? ''}',
                items: [
                  ('', 'Tất cả dãy'),
                  for (final r in widget.rows) (r.id, 'Dãy ${r.rowName}'),
                ],
                onSelected: (v) => setState(() => _rowFilter = v),
              ),
            ),
            const SizedBox(width: 8),
            _ViewBtn(
              icon: Icons.grid_view_rounded,
              label: 'Lưới',
              active: _view == _ViewMode.grid,
              onTap: () => setState(() => _view = _ViewMode.grid),
            ),
            const SizedBox(width: 6),
            _ViewBtn(
              icon: Icons.view_list_rounded,
              label: 'Danh sách',
              active: _view == _ViewMode.list,
              onTap: () => setState(() => _view = _ViewMode.list),
            ),
            const SizedBox(width: 6),
            MgmtOutlineButton(
              icon: Icons.fullscreen_rounded,
              tooltip: 'Toàn màn hình camera chính',
              height: 38,
              onTap: main == null || !main.isOnline ? null : _fullscreen,
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (_cams.isEmpty)
          MgmtEmptyState(
            icon: Icons.videocam_outlined,
            title: 'Chưa có camera giám sát',
            message: 'Khu ${widget.areaName} hiện chưa được cấu hình camera.',
            action: widget.onAddCamera == null
                ? null
                : MgmtPrimaryButton(
                    icon: Icons.add_rounded,
                    label: 'Thêm camera',
                    onTap: widget.onAddCamera,
                  ),
          )
        else ...[
          // ── Cameras ──────────────────────────────────────────────────────
          if (_view == _ViewMode.grid)
            LayoutBuilder(
              builder: (context, c) {
                final others = _filtered.where((x) => x.id != main?.id).toList();
                const gap = 12.0;
                final wide = c.maxWidth >= 1100;
                final mainW = wide ? (c.maxWidth - gap) * 0.58 : c.maxWidth;
                final mainH = (mainW * 9 / 16).clamp(260.0, 440.0);
                final mainCam = RepaintBoundary(
                  key: _mainKey,
                  child: main == null
                      ? const SizedBox.shrink()
                      : _MainCamera(
                          cam: main,
                          scope: _scope(main),
                          aiStatus: _aiStatus(main),
                          paused: _paused,
                          muted: _muted,
                          quality: _quality,
                          onPause: () => setState(() => _paused = !_paused),
                          onMute: () => setState(() => _muted = !_muted),
                          onQuality: (q) => setState(() => _quality = q),
                          onSnapshot: _snapshot,
                          onFullscreen: _fullscreen,
                          onRefresh: _loadCams,
                          onReconnect: () => _showOffline(main),
                        ),
                );
                final grid = _ThumbGrid(
                  cams: others,
                  height: mainH,
                  onSelect: _select,
                  emptyLabel: _filtered.isEmpty
                      ? 'Không có camera khớp bộ lọc.'
                      : 'Không có camera phụ.',
                );
                if (!wide) {
                  return Column(children: [
                    SizedBox(height: mainH, child: mainCam),
                    const SizedBox(height: gap),
                    grid,
                  ]);
                }
                return SizedBox(
                  height: mainH,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(width: mainW, child: mainCam),
                      const SizedBox(width: gap),
                      Expanded(child: grid),
                    ],
                  ),
                );
              },
            )
          else
            _CamTable(
              cams: _filtered,
              aiStatus: _aiStatus,
              selectedId: main?.id,
              onView: (c) {
                _select(c);
                if (c.isOnline) setState(() => _view = _ViewMode.grid);
              },
            ),
          const SizedBox(height: 14),

          // ── Info + AI events ─────────────────────────────────────────────
          LayoutBuilder(
            builder: (context, c) {
              final info = _InfoCard(
                cam: main,
                aiStatus: main == null ? null : _aiStatus(main),
                aiLoaded: _aiLoaded,
                latest: _eventsFor(main).firstOrNull,
                rows: widget.rows,
                onOpenEvent: _showEvent,
                onConfigure: _configureCam,
              );
              final ai = _AiEventsCard(
                events: _events,
                camForEvent: _camForEvent,
                onOpenAll: widget.onOpenAlerts,
                onOpenObject: _openObject,
                onOpenEvent: _showEvent,
              );
              if (c.maxWidth < 1100) {
                return Column(children: [info, const SizedBox(height: 14), ai]);
              }
              const gap = 12.0;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: (c.maxWidth - gap) * 0.58, child: info),
                  const SizedBox(width: gap),
                  Expanded(child: ai),
                ],
              );
            },
          ),
        ],
      ],
    );
  }
}

String _ago(Duration d) {
  if (d.inMinutes < 1) return 'vừa xong';
  if (d.inMinutes < 60) return '${d.inMinutes} phút trước';
  if (d.inHours < 24) return '${d.inHours} giờ trước';
  return '${d.inDays} ngày trước';
}

String _fmtFull(DateTime dt) {
  final l = dt.toLocal();
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(l.day)}/${two(l.month)}/${l.year} ${two(l.hour)}:${two(l.minute)}:${two(l.second)}';
}

// ─────────────────────────────────────────────────────────────────────────────
// Toolbar view button
// ─────────────────────────────────────────────────────────────────────────────

class _ViewBtn extends StatelessWidget {
  const _ViewBtn({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? DashboardColors.brand : Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: active ? DashboardColors.brand : DashboardColors.cardBorder),
          ),
          child: Row(children: [
            Icon(icon, size: 16, color: active ? Colors.white : DashboardColors.textMuted),
            const SizedBox(width: 6),
            Text(label,
                style: bvText(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: active ? Colors.white : DashboardColors.textPrimary,
                )),
          ]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Camera frames
// ─────────────────────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, this.small = false});
  final _CamStatus status;
  final bool small;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: small ? 6 : 8, vertical: small ? 2 : 3),
      decoration: BoxDecoration(
        color: status.color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 5,
          height: 5,
          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(status.badge,
            style: bvText(
              fontSize: small ? 9 : 10,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.5,
            )),
      ]),
    );
  }
}

/// Lớp video: stream thật nếu có URL, ngược lại khung hình khu nuôi.
class _VideoLayer extends StatelessWidget {
  const _VideoLayer({required this.cam, this.paused = false});
  final _Cam cam;
  final bool paused;

  @override
  Widget build(BuildContext context) {
    final url = cam.streamUrl ?? '';
    return Stack(
      fit: StackFit.expand,
      children: [
        if (url.isNotEmpty && !paused)
          CameraStreamPlayer(
            key: ValueKey('cam-${cam.id}-$url'),
            streamUrl: url,
            ipAddress: cam.ipAddress,
            snapshotFallbackUrl: cam.snapshotUrl,
          )
        else ...[
          Image.asset(
            _kCamFallback,
            fit: BoxFit.cover,
            alignment: const Alignment(0.2, 0.1),
            errorBuilder: (_, __, ___) => Container(color: const Color(0xFF1F2A2E)),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.30),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.40),
                ],
              ),
            ),
          ),
        ],
        if (paused)
          Container(
            color: Colors.black.withValues(alpha: 0.35),
            alignment: Alignment.center,
            child: const Icon(Icons.pause_circle_outline_rounded,
                size: 56, color: Colors.white70),
          ),
      ],
    );
  }
}

class _OfflinePanel extends StatelessWidget {
  const _OfflinePanel({required this.cam, this.compact = false, this.onReconnect});
  final _Cam cam;
  final bool compact;
  final VoidCallback? onReconnect;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF2B3A3F),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.videocam_off_outlined,
              size: compact ? 28 : 44, color: Colors.white.withValues(alpha: 0.7)),
          SizedBox(height: compact ? 6 : 10),
          Text(cam.status.label,
              style: bvText(
                fontSize: compact ? 12 : 15,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.9),
              )),
          SizedBox(height: compact ? 2 : 4),
          Text('Cập nhật cuối: ${fmtDateTimeVn(cam.lastSeenAt)}',
              style: bvText(
                fontSize: compact ? 10 : 12,
                color: Colors.white.withValues(alpha: 0.65),
              )),
          if (!compact && onReconnect != null) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.6)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: onReconnect,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Thử kết nối lại'),
            ),
          ],
        ],
      ),
    );
  }
}

class _MainCamera extends StatelessWidget {
  const _MainCamera({
    required this.cam,
    required this.scope,
    required this.aiStatus,
    required this.paused,
    required this.muted,
    required this.quality,
    required this.onPause,
    required this.onMute,
    required this.onQuality,
    required this.onSnapshot,
    required this.onFullscreen,
    required this.onRefresh,
    required this.onReconnect,
    this.fullscreen = false,
  });

  final _Cam cam;
  final List<BoxRecord> scope;
  final (String, Color, bool)? aiStatus;
  final bool paused;
  final bool muted;
  final String quality;
  final VoidCallback? onPause;
  final VoidCallback? onMute;
  final ValueChanged<String>? onQuality;
  final VoidCallback? onSnapshot;
  final VoidCallback onFullscreen;
  final VoidCallback onRefresh;
  final VoidCallback onReconnect;
  final bool fullscreen;

  @override
  Widget build(BuildContext context) {
    final total = scope.length;
    final withCrab = scope.where((b) => b.hasCrab).length;
    var alerts = 0, molting = 0;
    for (final b in scope) {
      if (!b.hasCrab) continue;
      final cond = CrabConditionX.parse(
        condition: b.crabCondition,
        moltingStage: b.crabMoltingStage,
        crabStatus: b.crabStatus,
        hasCrab: true,
      );
      if (b.alertCount > 0 || cond == CrabCondition.problem) {
        alerts++;
      } else if (cond == CrabCondition.molting ||
          cond == CrabCondition.premolt ||
          cond == CrabCondition.softshell) {
        molting++;
      }
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(fullscreen ? 12 : 16),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (cam.isOnline)
            _VideoLayer(cam: cam, paused: paused)
          else
            _OfflinePanel(cam: cam, onReconnect: onReconnect),

          // Top bar: tên + LIVE | refresh + timestamp
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 10, 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withValues(alpha: 0.55), Colors.transparent],
                ),
              ),
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      cam.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: bvText(fontSize: 12.5, fontWeight: FontWeight.w700,
                          color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusBadge(status: cam.status),
                  const Spacer(),
                  if (cam.isOnline)
                    IconButton(
                      tooltip: 'Tải lại',
                      onPressed: onRefresh,
                      iconSize: 16,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(width: 26, height: 26),
                      icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                    ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: cam.isOnline
                        ? const _LiveClock()
                        : Text(
                            cam.lastSeenAt == null ? '—' : _fmtFull(cam.lastSeenAt!),
                            style: bvText(fontSize: 11, color: Colors.white),
                          ),
                  ),
                ],
              ),
            ),
          ),

          // AI overlay (chỉ khi online)
          if (cam.isOnline)
            Positioned(
              right: 12,
              top: 0,
              bottom: 0,
              child: Center(
                child: Container(
                  width: 170,
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Icon(Icons.auto_awesome_rounded, size: 13, color: Colors.white),
                        const SizedBox(width: 6),
                        Text('AI giám sát',
                            style: bvText(fontSize: 12, fontWeight: FontWeight.w800,
                                color: Colors.white)),
                      ]),
                      if (aiStatus != null) ...[
                        const SizedBox(height: 2),
                        Row(children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration:
                                BoxDecoration(color: aiStatus!.$2, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(aiStatus!.$1,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: bvText(
                                    fontSize: 10, color: Colors.white.withValues(alpha: 0.85))),
                          ),
                        ]),
                      ],
                      const SizedBox(height: 8),
                      _ovLine('Tổng hộp:', '$total'),
                      _ovLine('Có cua:', '$withCrab'),
                      _ovLine('Cảnh báo:', '$alerts', dot: DashboardColors.risk),
                      _ovLine('Đang lột xác:', '$molting', dot: _kMolt),
                    ],
                  ),
                ),
              ),
            ),

          // Control bar
          if (cam.isOnline)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                color: Colors.black.withValues(alpha: 0.55),
                child: Row(
                  children: [
                    _CtlBtn(
                      icon: paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                      tooltip: paused ? 'Tiếp tục' : 'Tạm dừng',
                      onTap: onPause,
                    ),
                    _CtlBtn(
                      icon: muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                      tooltip: muted ? 'Bật tiếng' : 'Tắt tiếng',
                      onTap: onMute,
                    ),
                    PopupMenuButton<String>(
                      enabled: onQuality != null,
                      tooltip: 'Chất lượng',
                      onSelected: onQuality,
                      itemBuilder: (_) => [
                        for (final q in const ['HD', 'SD', 'Auto'])
                          PopupMenuItem(value: q, child: Text(q)),
                      ],
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(children: [
                          Text(quality,
                              style: bvText(fontSize: 12, fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                          const Icon(Icons.expand_more_rounded, size: 16, color: Colors.white),
                        ]),
                      ),
                    ),
                    const Spacer(),
                    _CtlBtn(
                      icon: Icons.photo_camera_outlined,
                      tooltip: 'Chụp ảnh',
                      onTap: onSnapshot,
                    ),
                    _CtlBtn(
                      icon: fullscreen ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded,
                      tooltip: fullscreen ? 'Thoát toàn màn hình' : 'Toàn màn hình',
                      onTap: onFullscreen,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _ovLine(String k, String v, {Color? dot}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(children: [
          if (dot != null) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
          ],
          Expanded(
            child: Text(k,
                style: bvText(fontSize: 11, color: Colors.white.withValues(alpha: 0.85))),
          ),
          Text(v,
              style: bvText(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white)),
        ]),
      );
}

class _CtlBtn extends StatelessWidget {
  const _CtlBtn({required this.icon, required this.tooltip, required this.onTap});
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      iconSize: 18,
      splashRadius: 18,
      icon: Icon(icon, color: onTap == null ? Colors.white38 : Colors.white),
    );
  }
}

class _LiveClock extends StatefulWidget {
  const _LiveClock();
  @override
  State<_LiveClock> createState() => _LiveClockState();
}

class _LiveClockState extends State<_LiveClock> {
  Timer? _t;
  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Text(
        _fmtFull(DateTime.now()),
        style: bvText(fontSize: 11, color: Colors.white),
      );
}

/// Lưới camera phụ (2 cột, tối đa 3 hàng).
class _ThumbGrid extends StatelessWidget {
  const _ThumbGrid({
    required this.cams,
    required this.height,
    required this.onSelect,
    required this.emptyLabel,
  });
  final List<_Cam> cams;
  final double height;
  final ValueChanged<_Cam> onSelect;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    if (cams.isEmpty) {
      return Container(
        height: height,
        decoration: mgmtCardDeco(radius: 16),
        alignment: Alignment.center,
        child: Text(emptyLabel, style: bvText(fontSize: 12.5, color: DashboardColors.textMuted)),
      );
    }
    final shown = cams.take(6).toList();
    final rows = (shown.length / 2).ceil().clamp(1, 3);
    const gap = 12.0;
    final cellH = (height - gap * (rows - 1)) / rows;
    return Column(
      children: [
        for (var r = 0; r < rows; r++) ...[
          if (r > 0) const SizedBox(height: gap),
          SizedBox(
            height: cellH,
            child: Row(
              children: [
                for (var c = 0; c < 2; c++) ...[
                  if (c > 0) const SizedBox(width: gap),
                  Expanded(
                    child: r * 2 + c < shown.length
                        ? _Thumb(cam: shown[r * 2 + c], onTap: () => onSelect(shown[r * 2 + c]))
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          ),
        ],
        if (cams.length > 6)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text('+${cams.length - 6} camera khác — xem ở chế độ Danh sách',
                style: bvText(fontSize: 11, color: DashboardColors.textMuted)),
          ),
      ],
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.cam, required this.onTap});
  final _Cam cam;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (cam.isOnline)
              _VideoLayer(cam: cam)
            else
              _OfflinePanel(cam: cam, compact: true),
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(10, 7, 8, 7),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black.withValues(alpha: 0.55), Colors.transparent],
                  ),
                ),
                child: Row(children: [
                  Expanded(
                    child: Text(cam.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: bvText(fontSize: 11.5, fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ),
                  _StatusBadge(status: cam.status, small: true),
                ]),
              ),
            ),
            if (cam.isOnline)
              Positioned(
                right: 8,
                bottom: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    cam.lastSeenAt == null ? '' : _fmtFull(cam.lastSeenAt!),
                    style: bvText(fontSize: 9.5, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// List mode
// ─────────────────────────────────────────────────────────────────────────────

class _CamTable extends StatelessWidget {
  const _CamTable({
    required this.cams,
    required this.aiStatus,
    required this.selectedId,
    required this.onView,
  });
  final List<_Cam> cams;
  final (String, Color, bool)? Function(_Cam) aiStatus;
  final String? selectedId;
  final ValueChanged<_Cam> onView;

  static const _cols = <(String, int)>[
    ('CAMERA', 12),
    ('KHU VỰC', 12),
    ('DÃY', 8),
    ('TRẠNG THÁI', 11),
    ('AI', 14),
    ('ĐỘ PHÂN GIẢI', 9),
    ('CẬP NHẬT CUỐI', 12),
    ('THAO TÁC', 7),
  ];

  @override
  Widget build(BuildContext context) {
    final head = bvText(fontSize: 10, fontWeight: FontWeight.w700,
        color: DashboardColors.textMuted, letterSpacing: 0.3);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: mgmtCardDeco(radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: DashboardColors.lightMint,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(children: [
              for (final (t, f) in _cols) Expanded(flex: f, child: Text(t, style: head)),
            ]),
          ),
          if (cams.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 22),
              child: Center(
                child: Text('Không có camera khớp bộ lọc.',
                    style: bvText(fontSize: 12.5, color: DashboardColors.textMuted)),
              ),
            )
          else
            for (final c in cams) _camLine(c),
        ],
      ),
    );
  }

  Widget _camLine(_Cam c) {
    final ai = aiStatus(c);
    final cell = bvText(fontSize: 12.5, color: DashboardColors.textPrimary);
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: c.id == selectedId ? DashboardColors.mint.withValues(alpha: 0.45) : null,
        borderRadius: BorderRadius.circular(8),
        border: Border(bottom: BorderSide(color: DashboardColors.cardBorder, width: 0.8)),
      ),
      child: Row(children: [
        Expanded(
          flex: 12,
          child: Row(children: [
            const Icon(Icons.videocam_outlined, size: 16, color: DashboardColors.brand),
            const SizedBox(width: 6),
            Text(c.code,
                style: bvText(fontSize: 12.5, fontWeight: FontWeight.w800,
                    color: DashboardColors.brand)),
          ]),
        ),
        Expanded(flex: 12, child: Text(c.scopeLabel, style: cell)),
        Expanded(flex: 8, child: Text(c.row?.rowName ?? 'Tất cả', style: cell)),
        Expanded(
          flex: 11,
          child: Align(
            alignment: Alignment.centerLeft,
            child: _DotBadge(label: c.status.label, color: c.status.color),
          ),
        ),
        Expanded(
          flex: 14,
          child: Align(
            alignment: Alignment.centerLeft,
            child: ai == null
                ? Text('—', style: bvText(fontSize: 12, color: DashboardColors.textMuted))
                : _DotBadge(label: ai.$1, color: ai.$2),
          ),
        ),
        Expanded(
          flex: 9,
          child: Text(
            c.resolution ??
                ((c.streamUrl ?? '').toLowerCase().startsWith('rtsp') ? '1080p' : '—'),
            style: cell,
          ),
        ),
        Expanded(flex: 12, child: Text(fmtDateTimeVn(c.lastSeenAt), style: cell)),
        Expanded(
          flex: 7,
          child: Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              tooltip: 'Xem camera',
              onPressed: () => onView(c),
              iconSize: 18,
              splashRadius: 18,
              icon: const Icon(Icons.visibility_outlined, color: DashboardColors.brand),
            ),
          ),
        ),
      ]),
    );
  }
}

class _DotBadge extends StatelessWidget {
  const _DotBadge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Flexible(
          child: Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: bvText(fontSize: 10.5, fontWeight: FontWeight.w700, color: color)),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Info card
// ─────────────────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.cam,
    required this.aiStatus,
    required this.aiLoaded,
    required this.latest,
    required this.rows,
    required this.onOpenEvent,
    this.onConfigure,
  });
  final _Cam? cam;
  final (String, Color, bool)? aiStatus;
  final bool aiLoaded;
  final _AiEvent? latest;
  final List<RowRecord> rows;
  final ValueChanged<_AiEvent> onOpenEvent;
  final ValueChanged<_Cam>? onConfigure;

  @override
  Widget build(BuildContext context) {
    final c = cam;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: mgmtCardDeco(radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text('Thông tin camera đang chọn',
                  style: bvText(fontSize: 14, fontWeight: FontWeight.w800,
                      color: DashboardColors.textPrimary)),
            ),
            if (c != null && onConfigure != null)
              MgmtOutlineButton(
                icon: Icons.tune_rounded,
                label: 'Cấu hình',
                height: 30,
                onTap: () => onConfigure!(c),
              ),
          ]),
          const SizedBox(height: 10),
          if (c == null)
            Text('Chưa chọn camera.',
                style: bvText(fontSize: 12.5, color: DashboardColors.textMuted))
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _left(c)),
                Container(width: 1, height: 150, color: DashboardColors.cardBorder),
                const SizedBox(width: 16),
                Expanded(child: _right(c)),
              ],
            ),
        ],
      ),
    );
  }

  Widget _left(_Cam c) {
    final watched = c.row != null
        ? c.row!.rowName
        : rows.isEmpty
            ? '—'
            : rows.map((r) => r.rowName).join(', ');
    return Container(
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DashboardColors.lightMint,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.videocam_outlined, size: 18, color: DashboardColors.brand),
            const SizedBox(width: 8),
            Text(c.code,
                style: bvText(fontSize: 14, fontWeight: FontWeight.w800,
                    color: DashboardColors.textPrimary)),
            const SizedBox(width: 10),
            _DotBadge(label: c.status.label, color: c.status.color),
          ]),
          const SizedBox(height: 10),
          _kv('Khu vực:', c.scopeLabel),
          _kv('Độ phân giải:', _resolutionLabel(c)),
          _kv('Góc nhìn:', c.row == null ? 'Toàn khu' : 'Dãy ${c.row!.rowName}'),
          _kv('Dãy quan sát:', watched),
          if (c.ipAddress != null) _kv('Địa chỉ IP:', c.ipAddress!),
          _kv('Lần cập nhật:', c.lastSeenAt == null ? '—' : _fmtFull(c.lastSeenAt!)),
        ],
      ),
    );
  }

  Widget _right(_Cam c) {
    final ai = aiStatus;
    final e = latest;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text('Trạng thái AI',
              style: bvText(fontSize: 12.5, fontWeight: FontWeight.w700,
                  color: DashboardColors.textPrimary)),
          const SizedBox(width: 10),
          if (!c.isOnline)
            const _DotBadge(label: 'Camera mất kết nối', color: kMgmtSlate)
          else if (ai != null)
            _DotBadge(label: ai.$1, color: ai.$2),
        ]),
        const SizedBox(height: 10),
        if (!c.isOnline)
          Text('AI tạm dừng do camera không có tín hiệu.',
              style: bvText(fontSize: 12.5, color: DashboardColors.textMuted))
        else if (ai != null && !ai.$3)
          Row(children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: kMgmtAmber),
            ),
            const SizedBox(width: 8),
            Text(ai.$1, style: bvText(fontSize: 12.5, color: DashboardColors.textMuted)),
          ])
        else if (e == null)
          Row(children: [
            const Icon(Icons.check_circle_outline_rounded,
                size: 16, color: DashboardColors.brandGreen),
            const SizedBox(width: 6),
            Text('Không phát hiện bất thường',
                style: bvText(fontSize: 12.5, fontWeight: FontWeight.w600,
                    color: DashboardColors.brand)),
          ])
        else ...[
          Text('Phát hiện gần nhất:',
              style: bvText(fontSize: 12, color: DashboardColors.textMuted)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _EventThumb(event: e, width: 56, height: 44),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.objectLabel,
                        style: bvText(fontSize: 13, fontWeight: FontWeight.w800,
                            color: DashboardColors.textPrimary)),
                    Text(e.typeLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: bvText(fontSize: 12, fontWeight: FontWeight.w600,
                            color: e.level.color)),
                    Text(fmtDateTimeVn(e.at),
                        style: bvText(fontSize: 11, color: DashboardColors.textMuted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          MgmtOutlineButton(
            label: 'Xem chi tiết →',
            height: 32,
            onTap: () => onOpenEvent(e),
          ),
        ],
      ],
    );
  }

  /// "1080p (Full HD)" từ BE `resolution`; dự phòng suy theo loại stream.
  static String _resolutionLabel(_Cam c) {
    final r = (c.resolution ?? '').trim();
    if (r.isNotEmpty) {
      final l = r.toLowerCase();
      if (l.startsWith('2160') || l.contains('4k')) return '$r (4K UHD)';
      if (l.startsWith('1440')) return '$r (QHD)';
      if (l.startsWith('1080')) return '$r (Full HD)';
      if (l.startsWith('720')) return '$r (HD)';
      return r;
    }
    return (c.streamUrl ?? '').toLowerCase().startsWith('rtsp') ? '1080p (Full HD)' : '—';
  }

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 104,
              child: Text(k, style: bvText(fontSize: 12, color: DashboardColors.textMuted)),
            ),
            Expanded(
              child: Text(v,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: bvText(fontSize: 12, fontWeight: FontWeight.w600,
                      color: DashboardColors.textPrimary)),
            ),
          ],
        ),
      );
}

/// Thumbnail sự kiện AI: ảnh phát hiện từ BE (`imagePath`) nếu tải được, không thì icon.
class _EventThumb extends StatelessWidget {
  const _EventThumb({required this.event, required this.width, required this.height});
  final _AiEvent event;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final e = event;
    final fallback = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: e.level.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Icon(
        e.isCrabEvent ? Icons.pest_control_rounded : Icons.inventory_2_outlined,
        size: height * 0.5,
        color: e.level.color,
      ),
    );
    if (e.imageUrl == null) return fallback;
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: width,
        height: height,
        child: Image.network(
          e.imageUrl!,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) => fallback,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AI events card
// ─────────────────────────────────────────────────────────────────────────────

class _AiEventsCard extends StatelessWidget {
  const _AiEventsCard({
    required this.events,
    required this.camForEvent,
    required this.onOpenAll,
    required this.onOpenObject,
    required this.onOpenEvent,
  });
  final List<_AiEvent> events;
  final _Cam? Function(_AiEvent) camForEvent;
  final VoidCallback? onOpenAll;
  final ValueChanged<_AiEvent> onOpenObject;
  final ValueChanged<_AiEvent> onOpenEvent;

  @override
  Widget build(BuildContext context) {
    final head = bvText(fontSize: 10, fontWeight: FontWeight.w700,
        color: DashboardColors.textMuted, letterSpacing: 0.3);
    final shown = events.take(6).toList();
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: mgmtCardDeco(radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Expanded(
              child: Text('Phát hiện AI gần đây',
                  style: bvText(fontSize: 14, fontWeight: FontWeight.w800,
                      color: DashboardColors.textPrimary)),
            ),
            MgmtOutlineButton(label: 'Xem tất cả →', height: 30, onTap: onOpenAll),
          ]),
          const SizedBox(height: 10),
          Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: DashboardColors.lightMint,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(children: [
              Expanded(flex: 8, child: Text('THỜI GIAN', style: head)),
              Expanded(flex: 8, child: Text('CAMERA', style: head)),
              Expanded(flex: 10, child: Text('ĐỐI TƯỢNG', style: head)),
              Expanded(flex: 18, child: Text('LOẠI PHÁT HIỆN', style: head)),
              Expanded(flex: 11, child: Text('TRẠNG THÁI', style: head)),
            ]),
          ),
          if (shown.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 22),
              child: Center(
                child: Text('Chưa có phát hiện AI cho khu này.',
                    style: bvText(fontSize: 12.5, color: DashboardColors.textMuted)),
              ),
            )
          else
            for (final e in shown) _line(e),
        ],
      ),
    );
  }

  Widget _line(_AiEvent e) {
    String two(int v) => v.toString().padLeft(2, '0');
    final t = '${two(e.at.hour)}:${two(e.at.minute)}:${two(e.at.second)}';
    final today = DateTime.now().difference(e.at).inHours < 24;
    final cam = camForEvent(e);
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: DashboardColors.cardBorder, width: 0.8)),
      ),
      child: Row(children: [
        Expanded(
          flex: 8,
          child: Tooltip(
            message: fmtDateTimeVn(e.at),
            child: Text(today ? t : '${two(e.at.day)}/${two(e.at.month)} $t',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: bvText(fontSize: 11.5, color: DashboardColors.textPrimary)),
          ),
        ),
        Expanded(
          flex: 8,
          child: Text(cam?.code ?? '—',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: bvText(fontSize: 11.5, fontWeight: FontWeight.w600,
                  color: DashboardColors.textPrimary)),
        ),
        Expanded(
          flex: 10,
          child: Align(
            alignment: Alignment.centerLeft,
            child: InkWell(
              onTap: e.box == null ? null : () => onOpenObject(e),
              child: Text(e.objectLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: bvText(fontSize: 11.5, fontWeight: FontWeight.w800,
                      color: DashboardColors.brand)),
            ),
          ),
        ),
        Expanded(
          flex: 18,
          child: Align(
            alignment: Alignment.centerLeft,
            child: InkWell(
              onTap: () => onOpenEvent(e),
              child: Text(e.typeLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: bvText(fontSize: 11.5, fontWeight: FontWeight.w600,
                      color: e.level == _Level.normal
                          ? DashboardColors.textPrimary
                          : e.level.color)),
            ),
          ),
        ),
        Expanded(
          flex: 11,
          child: Align(
            alignment: Alignment.centerLeft,
            child: _DotBadge(label: e.level.label, color: e.level.color),
          ),
        ),
      ]),
    );
  }
}
