import 'package:flutter/foundation.dart';

import '../data/mock_camera_ai_data.dart';
import '../models/camera_ai.dart';

class CameraAiService extends ChangeNotifier {
  CameraAiService() {
    _events = MockCameraAiData.events();
    reloadCameras();
  }

  late List<AiCameraEvent> _events;
  late List<CameraFeed> _cameras;

  /// Đọc lại URL từ `.env` (sau khi sửa cấu hình / hot restart).
  void reloadCameras() {
    _cameras = MockCameraAiData.cameras();
    notifyListeners();
  }

  List<CameraFeed> get cameras => List.unmodifiable(_cameras);
  List<AiCameraEvent> get events => List.unmodifiable(_events);

  String _cameraTab = MockCameraAiData.cameraTabs.first;
  String get cameraTab => _cameraTab;

  String _cameraFilter = 'Tất cả';
  String _typeFilter = 'Tất cả';
  String _levelFilter = 'Tất cả';
  String _statusFilter = 'Tất cả';
  String _search = '';

  String? get activeCameraId => MockCameraAiData.cameraIdFromTab(_cameraTab);

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

  List<AiDetectionCount> get detectionCounts =>
      MockCameraAiData.detectionCountsFor(activeCameraId);

  List<AiCameraEvent> get filteredEvents {
    var list = _events;
    final tabCam = activeCameraId;
    if (tabCam != null) {
      list = list.where((e) => e.cameraId == tabCam).toList();
    }
    final filterCam = MockCameraAiData.cameraIdFromFilter(_cameraFilter);
    if (filterCam != null) {
      list = list.where((e) => e.cameraId == filterCam).toList();
    }
    final type = MockCameraAiData.typeFromFilter(_typeFilter);
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

  CameraFeed get primaryCamera {
    final id = activeCameraId;
    if (id != null) {
      for (final c in _cameras) {
        if (c.id == id) return c;
      }
    }
    return _cameras.first;
  }

  List<CameraFeed> get thumbnailCameras {
    final primary = primaryCamera;
    return _cameras.where((c) => c.id != primary.id).toList();
  }

  void updateEventStatus(String id, AiEventStatus status) {
    final i = _events.indexWhere((e) => e.id == id);
    if (i >= 0) {
      _events = [..._events]..[i] = _events[i].copyWith(status: status);
      notifyListeners();
    }
  }

  String get aiInsight => MockCameraAiData.aiInsightFor(activeCameraId);
  String get aiRecommendation => MockCameraAiData.aiRecommendation();
}
