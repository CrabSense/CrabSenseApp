
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

/// Một nhiệm vụ thu hoạch trong danh sách theo dõi của Manager.
class HarvestAssignmentListItem {
  const HarvestAssignmentListItem({
    required this.id,
    required this.assignmentCode,
    required this.assignedToUserId,
    required this.status,
    required this.lineCount,
    required this.harvestedCount,
    required this.deferredCount,
    required this.voucherCount,
    this.createdAt,
    this.startedAt,
    this.completedAt,
  });

  final String id;
  final String assignmentCode;
  final String assignedToUserId;
  final String status;

  // Số cua trong nhiệm vụ, đã thu hoạch, và được tiếp tục nuôi.
  final int lineCount;
  final int harvestedCount;
  final int deferredCount;
  final int voucherCount;

  final DateTime? createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;

  factory HarvestAssignmentListItem.fromJson(
    Map<String, dynamic> json,
  ) {
    String readText(String camelCase, String pascalCase) {
      return (json[camelCase] ?? json[pascalCase] ?? '').toString();
    }

    int readNumber(String camelCase, String pascalCase) {
      final value = json[camelCase] ?? json[pascalCase];
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    DateTime? readDate(String camelCase, String pascalCase) {
      final value = json[camelCase] ?? json[pascalCase];
      if (value == null) return null;
      return DateTime.tryParse(value.toString());
    }

    return HarvestAssignmentListItem(
      id: readText('id', 'Id'),
      assignmentCode: readText('assignmentCode', 'AssignmentCode'),
      assignedToUserId: readText('assignedToUserId', 'AssignedToUserId'),
      status: readText('status', 'Status'),
      lineCount: readNumber('lineCount', 'LineCount'),
      harvestedCount: readNumber('harvestedCount', 'HarvestedCount'),
      deferredCount: readNumber('deferredCount', 'DeferredCount'),
      voucherCount: readNumber('voucherCount', 'VoucherCount'),
      createdAt: readDate('createdAt', 'CreatedAt'),
      startedAt: readDate('startedAt', 'StartedAt'),
      completedAt: readDate('completedAt', 'CompletedAt'),
    );
  }
}