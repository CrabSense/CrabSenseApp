
/// Nhân viên được BE trả về khi Manager chọn khu giao việc.
class HarvestAssignmentStaff {
  const HarvestAssignmentStaff({
    required this.id,
    required this.fullName,
    this.userCode,
  });

  final String id;
  final String fullName;
  final String? userCode;

  factory HarvestAssignmentStaff.fromJson(Map<String, dynamic> json) {
    return HarvestAssignmentStaff(
      id: (json['id'] ?? json['Id'] ?? '').toString(),
      fullName: (json['fullName'] ?? json['FullName'] ?? '').toString(),
      userCode: (json['userCode'] ?? json['UserCode'])?.toString(),
    );
  }
}