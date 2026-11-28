/// Health Monitoring currently has no verified assessment source wired to
/// Desktop. Missing data is not a score of zero or a diagnosis.
/// This state cannot manufacture an assessment or an exportable report.
class HealthMonitoringState {
  const HealthMonitoringState.unavailable({required this.crabId});

  final String? crabId;

  bool get hasSelection => crabId != null && crabId!.trim().isNotEmpty;
  bool get canExport => false;
  String get title => hasSelection
      ? 'Chưa có hồ sơ sức khỏe xác minh'
      : 'Chưa chọn cua';
  String get explanation => hasSelection
      ? 'Chưa có nguồn đánh giá sức khỏe được xác minh cho cua đang chọn.'
      : 'Chọn cua từ hồ sơ thuộc khu nuôi hiện tại.';
  String get exportReason =>
      'Chỉ được xuất báo cáo khi có hồ sơ sức khỏe và nguồn dữ liệu xác minh.';
}
