import '../models/auth_models.dart';
import '../models/harvest_assignment.dart';
import 'cloud_api_client.dart';
import '../models/production_models.dart';
import 'package:flutter/foundation.dart';


/// Điều phối các API của luồng Manager giao nhiệm vụ thu hoạch.
class HarvestAssignmentService {
  HarvestAssignmentService({
    required AuthSession session,
    CloudApiClient? api,
  })  : _session = session,
        _api = api ?? CloudApiClient();

  AuthSession _session;
  final CloudApiClient _api;

  /// Cập nhật token/khu hiện tại khi session trong ứng dụng thay đổi.
  void updateSession(AuthSession session) {
    _session = session;
  }

  /// Trả về khu đang được chọn trong desktop.
  String get selectedAreaId => _session.selectedFarm.id;

  String get selectedAreaLabel {
    final area = _session.selectedFarm;
    if (area.code.isEmpty || area.code == area.name) return area.name;
    return '${area.code} — ${area.name}';
  }

  /// Tải các cua thuộc khu và chỉ trả về cua đang Alive.
  /// BE vẫn kiểm tra lại trạng thái và task đang mở khi tạo assignment.
  Future<List<CrabManagementListItem>> loadAliveCrabs({
    required String farmingAreaId,
  }) async {
    if (farmingAreaId.trim().isEmpty) {
      throw CloudApiException('Chưa chọn khu nuôi.');
    }

    final result = await _api.fetchFarmCrabs(
      _session.token,
      farmingAreaId,
    );
    // Đặt ngay sau khi lấy result, trước khi lọc trạng thái.
    final counts = <String, int>{};
    for (final crab in result.crabs) {
      counts.update(crab.status, (count) => count + 1, ifAbsent: () => 1);
    }
    debugPrint(
      '[harvest-assignment] area=$farmingAreaId '
      'total=${result.crabs.length}, statuses=$counts',
    );

    return result.crabs
        .where((crab) => crab.status.trim().toLowerCase() == 'alive')
        .toList(growable: false);
  }

  /// Tải danh sách nhân viên cho khu đang giao việc.
  Future<List<HarvestAssignmentStaff>> loadStaff({
    required String farmingAreaId,
  }) {
    if (farmingAreaId.trim().isEmpty) {
      throw CloudApiException('Chưa chọn khu nuôi.');
    }

    return _api.fetchHarvestAssignmentStaff(
      _session.token,
      farmingAreaId: farmingAreaId,
    );
  }

  /// Tạo task. Điều kiện nghiệp vụ cuối cùng vẫn do BE xác thực.
  Future<Map<String, dynamic>> createAssignment({
    required String farmingAreaId,
    required String assignedToUserId,
    required List<String> crabIds,
    String? notes,
  }) {
    if (farmingAreaId.trim().isEmpty) {
      throw CloudApiException('Chưa chọn khu nuôi.');
    }
    if (assignedToUserId.trim().isEmpty) {
      throw CloudApiException('Vui lòng chọn nhân viên nhận việc.');
    }
    if (crabIds.isEmpty) {
      throw CloudApiException('Chọn ít nhất một con cua.');
    }

    return _api.createHarvestAssignment(
      _session.token,
      farmingAreaId: farmingAreaId,
      assignedToUserId: assignedToUserId,
      crabIds: crabIds,
      notes: notes,
    );
  }
}
