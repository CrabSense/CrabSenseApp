import 'package:flutter/foundation.dart';

import '../config/app_env.dart';
import '../models/camera_ai.dart';

class CameraAiService extends ChangeNotifier {
  CameraAiService() {
    _events = const [];
    reloadCameras();
  }

  late List<AiCameraEvent> _events;
  late List<CameraFeed> _cameras;

  static const typeFilterOptions = [
    'Tất cả',
    'Lột xác',
    'Chết',
    'Bỏ ăn',
    'Thoát hộp',
    'Rong bám',
    'Bất thường',
  ];
  static const levelFilterOptions = ['Tất cả', 'Theo dõi', 'Cảnh báo', 'Khẩn cấp'];
  static const statusFilterOptions = [
    'Tất cả',
    'Chưa xử lý',
    'Đã xác nhận',
    'Báo sai AI',
  ];

  void reloadCameras() {
    _cameras = _configuredCameras();
    if (_cameras.isNotEmpty &&
        !_cameraTabs.contains(_cameraTab) &&
        _cameraTab != 'Tất cả camera') {
      _cameraTab = _cameras.first.name;
    }
    notifyListeners();
  }

  static List<CameraFeed> _configuredCameras() {
    return [
      CameraFeed(
        id: 'cam1',
        name: 'Camera 1',
        area: '—',
        status: CameraStatus.online,
        fps: 24,
        resolution: '1080p',
        lastUpdateSeconds: 0,
        ipAddress: AppEnv.camera1Ip,
        streamUrl: AppEnv.camera1StreamUrl,
        snapshotFallbackUrl: AppEnv.camera1SnapshotFallbackUrl,
        overlays: const [],
      ),
      CameraFeed(
        id: 'cam2',
        name: 'Camera 2',
        area: '—',
        status: CameraStatus.online,
        fps: 24,
        resolution: '1080p',
        lastUpdateSeconds: 0,
        ipAddress: AppEnv.camera2Ip,
        streamUrl: AppEnv.camera2StreamUrl,
        snapshotFallbackUrl: AppEnv.camera2SnapshotFallbackUrl,
        snapshotOnly: AppEnv.camera2SnapshotOnly,
        htmlPageMode: AppEnv.camera2HtmlPage,
        overlays: const [],
      ),
    ];
  }

  List<CameraFeed> get cameras => List.unmodifiable(_cameras);
  List<AiCameraEvent> get events => List.unmodifiable(_events);

  List<String> get cameraTabs => [
        ..._cameras.map((c) => c.name),
        'Tất cả camera',
      ];

  List<String> get cameraFilterOptions => [
        'Tất cả',
        ..._cameras.map((c) => c.name),
      ];

  String _cameraTab = 'Camera 1';
  String get cameraTab => _cameraTab;

  String _cameraFilter = 'Tất cả';
  String _typeFilter = 'Tất cả';
  String _levelFilter = 'Tất cả';
  String _statusFilter = 'Tất cả';
  String _search = '';

  List<String> get _cameraTabs => cameraTabs;

  String? get activeCameraId {
    for (final c in _cameras) {
      if (c.name == _cameraTab) return c.id;
    }
    return null;
  }

  void setCameraTab(String tab) {
    _cameraTab = tab;
    notifyListeners();
  }

  void setCameraFilter(String v) {
    _cameraFilter = v;
    notifyListeners();
  }

  void setTypeFilter(String v) {
    _typeFilter = v;
    notifyListeners();
  }

  void setLevelFilter(String v) {
    _levelFilter = v;
    notifyListeners();
  }

  void setStatusFilter(String v) {
    _statusFilter = v;
    notifyListeners();
  }

  void setSearch(String v) {
    _search = v.trim().toLowerCase();
    notifyListeners();
  }

  List<AiDetectionCount> get detectionCounts {
    final list = filteredEvents;
    return AiDetectionType.values
        .map(
          (t) => AiDetectionCount(
            type: t,
            count: list.where((e) => e.detectionType == t).length,
          ),
        )
        .toList();
  }

  List<AiCameraEvent> get filteredEvents {
    var list = _events;
    final tabCam = activeCameraId;
    if (tabCam != null) {
      list = list.where((e) => e.cameraId == tabCam).toList();
    }
    if (_cameraFilter != 'Tất cả') {
      final id = _cameras
          .where((c) => c.name == _cameraFilter)
          .map((c) => c.id)
          .firstOrNull;
      if (id != null) {
        list = list.where((e) => e.cameraId == id).toList();
      }
    }
    final type = switch (_typeFilter) {
      'Lột xác' => AiDetectionType.molting,
      'Chết' => AiDetectionType.dead,
      'Bỏ ăn' => AiDetectionType.skippedMeal,
      'Thoát hộp' => AiDetectionType.escaped,
      'Rong bám' => AiDetectionType.algae,
      'Bất thường' => AiDetectionType.abnormal,
      _ => null,
    };
    if (type != null) {
      list = list.where((e) => e.detectionType == type).toList();
    }
    if (_levelFilter == 'Theo dõi') {
      list = list.where((e) => e.level == AiEventLevel.info).toList();
    } else if (_levelFilter == 'Cảnh báo') {
      list = list.where((e) => e.level == AiEventLevel.warning).toList();
    } else if (_levelFilter == 'Khẩn cấp') {
      list = list.where((e) => e.level == AiEventLevel.critical).toList();
    }
    if (_statusFilter == 'Chưa xử lý') {
      list = list.where((e) => e.status == AiEventStatus.pending).toList();
    } else if (_statusFilter == 'Đã xác nhận') {
      list = list.where((e) => e.status == AiEventStatus.confirmed).toList();
    } else if (_statusFilter == 'Báo sai AI') {
      list = list.where((e) => e.status == AiEventStatus.falsePositive).toList();
    }
    if (_search.isNotEmpty) {
      list = list
          .where(
            (e) =>
                e.boxId.toLowerCase().contains(_search) ||
                e.crabId.toLowerCase().contains(_search) ||
                e.detectionType.label.toLowerCase().contains(_search),
          )
          .toList();
    }
    return list;
  }

  CameraFeed? get primaryCameraOrNull {
    final id = activeCameraId;
    if (id != null) {
      for (final c in _cameras) {
        if (c.id == id) return c;
      }
    }
    return _cameras.isEmpty ? null : _cameras.first;
  }

  CameraFeed get primaryCamera =>
      primaryCameraOrNull ??
      const CameraFeed(
        id: '',
        name: 'Chưa có camera',
        area: '—',
        status: CameraStatus.offline,
        fps: 0,
        resolution: '—',
        lastUpdateSeconds: 0,
        overlays: [],
      );

  List<CameraFeed> get thumbnailCameras {
    final primary = primaryCameraOrNull;
    if (primary == null) return const [];
    return _cameras.where((c) => c.id != primary.id).toList();
  }

  void updateEventStatus(String id, AiEventStatus status) {
    final i = _events.indexWhere((e) => e.id == id);
    if (i >= 0) {
      _events = [..._events]..[i] = _events[i].copyWith(status: status);
      notifyListeners();
    }
  }

  String get aiInsight =>
      'Chưa có sự kiện AI. Kết nối camera và mô hình phát hiện để xem cảnh báo.';
  String get aiRecommendation => '';
}
