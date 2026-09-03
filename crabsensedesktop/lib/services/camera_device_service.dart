import 'package:flutter/foundation.dart';

import '../models/auth_models.dart';
import '../models/camera_device.dart';
import 'cloud_api_client.dart';

class CameraDeviceService extends ChangeNotifier {
  CameraDeviceService({required AuthSession session, CloudApiClient? api})
      : _session = session,
        _api = api ?? CloudApiClient();

  AuthSession _session;
  final CloudApiClient _api;

  void updateSession(AuthSession session) {
    _session = session;
    notifyListeners();
  }

  var _loading = false;
  String? _error;
  List<CameraDevice> _cameras = [];
  String? _selectedBoxId;
  String? _selectedGatewayId;

  bool get loading => _loading;
  String? get error => _error;
  List<CameraDevice> get cameras => List.unmodifiable(_cameras);
  String? get selectedBoxId => _selectedBoxId;
  String? get selectedGatewayId => _selectedGatewayId;

  List<CameraDevice> get filteredCameras {
    if (_selectedBoxId == null) return _cameras;
    return _cameras.where((c) => c.boxId == _selectedBoxId).toList();
  }

  void selectBox(String? boxId) {
    _selectedBoxId = boxId;
    notifyListeners();
  }

  void selectGateway(String? gatewayId) {
    _selectedGatewayId = gatewayId;
    notifyListeners();
  }

  Future<void> loadCameras({String? gatewayId}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final devices = await _api.fetchCrabSenseDevices(
        _session.token,
        farmingAreaId: _session.selectedFarm.id,
      );
      _cameras = devices
          .where((d) {
            final t = (d['deviceType'] ?? d['DeviceType'] ?? '')
                .toString()
                .toLowerCase();
            return t.contains('cam');
          })
          .map(CameraDevice.fromJson)
          .toList();
      _error = null;
    } catch (e) {
      _error = '$e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadCamerasForBoxes(
    List<String> boxIds, {
    String? gatewayId,
  }) async {
    if (boxIds.isEmpty) {
      _cameras = [];
      _error = null;
      _loading = false;
      notifyListeners();
      return;
    }
    if (boxIds.length == 1) {
      await loadCamerasByBox(boxIds.first);
      return;
    }

    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final out = <CameraDevice>[];
      for (final id in boxIds) {
        final raw = await _api.fetchBoxCamera(_session.token, id);
        if (raw == null || raw.isEmpty) continue;
        out.add(CameraDevice.fromBoxCamera(raw, fallbackBoxId: id));
      }
      _cameras = out;
      _error = null;
    } catch (e) {
      _error = '$e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadCamerasByBox(String boxId) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final raw = await _api.fetchBoxCamera(_session.token, boxId);
      _cameras = raw == null || raw.isEmpty
          ? []
          : [CameraDevice.fromBoxCamera(raw, fallbackBoxId: boxId)];
      _error = null;
    } catch (e) {
      _error = '$e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<String?> getNextCameraCode({String? gatewayId}) async {
    return 'CAM-${DateTime.now().millisecondsSinceEpoch % 10000}';
  }

  Future<CameraDevice?> createCamera(
    UpsertCameraRequest request, {
    String? gatewayId,
  }) async {
    _error = 'CrabSenseBE không có CRUD camera. Camera gắn theo hộp.';
    notifyListeners();
    return null;
  }

  Future<CameraDevice?> updateCamera(
    String cameraId,
    UpsertCameraRequest request,
  ) async {
    _error = 'CrabSenseBE không có cập nhật camera.';
    notifyListeners();
    return null;
  }

  Future<bool> deleteCamera(String cameraId) async {
    _error = 'CrabSenseBE không có xóa camera.';
    notifyListeners();
    return false;
  }
}
