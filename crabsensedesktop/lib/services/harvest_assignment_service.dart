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
  int _generation = 0;
  int get scopeGeneration => _generation;
  void _checkScope(String area,int generation) { _requireArea(area); if (generation != _generation) throw CloudApiException('Khu nuôi hoặc phiên đã thay đổi.'); }

  /// Cập nhật token/khu hiện tại khi session trong ứng dụng thay đổi.
  void updateSession(AuthSession session) {
    ++_generation;
    _session = session;
  }

  /// Trả về khu đang được chọn trong desktop.
  String get selectedAreaId => _session.selectedFarm.id;

  String get selectedAreaLabel {
    final area = _session.selectedFarm;
    if (area.code.isEmpty || area.code == area.name) return area.name;
    return '${area.code} — ${area.name}';
  }

  void _requireArea(String id) {
    if (_session.user.role != UserRoles.farmManager ||
        id.trim().isEmpty || id != selectedAreaId ||
        !_session.farms.any((f) => f.id == id)) {
      throw CloudApiException('Khu nuôi hoặc quyền Manager không hợp lệ.');
    }
  }

  Future<List<Map<String, dynamic>>> loadAssignments(String areaId) async {
    _requireArea(areaId);
    final generation = _generation;
    final rows = await _api.fetchHarvestAssignments(_session.token, farmingAreaId: areaId);
    _checkScope(areaId,generation);
    return rows.where((row) => (row['farmingAreaId'] ?? row['FarmingAreaId']).toString() == areaId).toList();
  }

  Future<Map<String, dynamic>> loadAssignmentDetail(String areaId, String id) async {
    _requireArea(areaId);
    final generation = _generation;
    final detail = await _api.fetchHarvestAssignmentDetail(_session.token, id, farmingAreaId: areaId);
    _checkScope(areaId,generation);
    if ((detail['farmingAreaId'] ?? detail['FarmingAreaId']).toString() != areaId) {
      throw CloudApiException('Nhiệm vụ không thuộc khu hiện tại.');
    }
    return detail;
  }

  Future<void> reviewAssignment(String areaId, String id, {
    required bool confirm, String? notes,
  }) async {
    _requireArea(areaId);
    final generation = _generation;
    final detail = await loadAssignmentDetail(areaId, id);
    _checkScope(areaId, generation);
    if ((detail['status'] ?? detail['Status']).toString().toLowerCase() != 'pendingreview') {
      throw CloudApiException('Nhiệm vụ không còn chờ xác nhận.');
    }
    await _api.reviewHarvestAssignment(_session.token, id, farmingAreaId: areaId,
      confirm: confirm, notes: notes);
    _checkScope(areaId, generation);
  }

  Future<void> handleAssignmentException(String areaId, String id, {
    required String action, required String reason, String? staffId, String? lineId,
  }) async {
    _requireArea(areaId);
    final generation = _generation;
    final detail = await loadAssignmentDetail(areaId, id);
    _checkScope(areaId, generation);
    final status = (detail['status'] ?? detail['Status']).toString().toLowerCase();
    if (!const {'assigned','inprogress','pendingreview'}.contains(status)) {
      throw CloudApiException('Nhiệm vụ đã kết thúc.');
    }
    if (action == 'skip') {
      final lines = detail['lines'];
      if (lines is! List || !lines.whereType<Map>().any((l) => l['id'].toString() == lineId &&
          const {'assigned','eligible','inprogress'}.contains(l['status'].toString().toLowerCase()))) {
        throw CloudApiException('Dòng cua không còn thuộc nhiệm vụ đang mở.');
      }
    }
    await _api.handleHarvestAssignmentException(_session.token, id, farmingAreaId: areaId,
      action: action, reason: reason, staffId: staffId, lineId: lineId);
    _checkScope(areaId, generation);
  }

  /// Tải các cua thuộc khu và chỉ trả về cua đang Alive.
  /// BE vẫn kiểm tra lại trạng thái và task đang mở khi tạo assignment.
  Future<List<CrabManagementListItem>> loadAliveCrabs({
    required String farmingAreaId,
  }) async {
    _requireArea(farmingAreaId);

    final generation = _generation;
    final result = await _api.fetchFarmCrabs(
      _session.token,
      farmingAreaId,
    );
    _checkScope(farmingAreaId,generation);
    final reserved=await _api.fetchOpenHarvestAssignmentCrabIds(_session.token,farmingAreaId:farmingAreaId);
    _checkScope(farmingAreaId,generation);
    final vouchers=await _api.fetchHarvestVouchers(_session.token,farmingAreaId:farmingAreaId);
    _checkScope(farmingAreaId,generation);
    for(final voucher in vouchers) {
      if((voucher['farmingAreaId']??voucher['FarmingAreaId']).toString()!=farmingAreaId)continue;
      final status=(voucher['status']??voucher['Status']).toString().toLowerCase();
      if(const {'rejected','cancelled','completed'}.contains(status))continue;
      final lines=voucher['lines']??voucher['Lines'];
      if(lines is! List)throw CloudApiException('Không xác minh được cua đang thuộc phiếu.');
      for(final row in lines.whereType<Map>()) { final id=(row['crabId']??row['CrabId']??'').toString(); if(id.isNotEmpty)reserved.add(id); }
    }
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
        .where((crab) => crab.areaId == farmingAreaId && crab.boxId.isNotEmpty && crab.rawStatus.trim().toLowerCase() == 'alive' && !reserved.contains(crab.id))
        .toList(growable: false);
  }

  /// Tải danh sách nhân viên cho khu đang giao việc.
  Future<List<HarvestAssignmentStaff>> loadStaff({
    required String farmingAreaId,
  }) async {
    _requireArea(farmingAreaId);
    final generation = _generation;
    final staff = await _api.fetchHarvestAssignmentStaff(
      _session.token,
      farmingAreaId: farmingAreaId,
    );
    _checkScope(farmingAreaId,generation);
    return staff;
  }

  /// Tạo task. Điều kiện nghiệp vụ cuối cùng vẫn do BE xác thực.
  Future<Map<String, dynamic>> createAssignment({
    required String farmingAreaId,
    required String assignedToUserId,
    required List<String> crabIds,
    String? notes,
  }) {
    _requireArea(farmingAreaId);
    if (assignedToUserId.trim().isEmpty) {
      throw CloudApiException('Vui lòng chọn nhân viên nhận việc.');
    }
    if (crabIds.isEmpty || crabIds.any((id) => id.trim().isEmpty) || crabIds.toSet().length != crabIds.length) {
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
