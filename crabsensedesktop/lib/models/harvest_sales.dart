import 'package:flutter/material.dart';

import '../theme/dashboard_theme.dart';

enum SalesOrderStatus {
  newOrder,
  delivering,
  delivered,
  paid,
  cancelled;

  String get label => switch (this) {
        SalesOrderStatus.newOrder => 'Mới tạo',
        SalesOrderStatus.delivering => 'Đang giao',
        SalesOrderStatus.delivered => 'Đã giao',
        SalesOrderStatus.paid => 'Đã thanh toán',
        SalesOrderStatus.cancelled => 'Đã hủy',
      };

  Color get color => switch (this) {
        SalesOrderStatus.newOrder => DashboardColors.blue,
        SalesOrderStatus.delivering => DashboardColors.monitoring,
        SalesOrderStatus.delivered => DashboardColors.cyan,
        SalesOrderStatus.paid => DashboardColors.healthy,
        SalesOrderStatus.cancelled => DashboardColors.risk,
      };
}

enum CrabSizeGrade {
  s,
  m,
  l,
  xl,
  xxl;

  String get label => name.toUpperCase();

  static CrabSizeGrade fromWeightG(int grams) {
    if (grams > 220) return CrabSizeGrade.xxl;
    if (grams >= 180) return CrabSizeGrade.xl;
    if (grams >= 150) return CrabSizeGrade.l;
    if (grams >= 120) return CrabSizeGrade.m;
    return CrabSizeGrade.s;
  }
}

class HarvestSalesKpi {
  const HarvestSalesKpi({
    required this.qualifiedCrabCount,
    required this.yieldKg,
    required this.monthlyRevenueVnd,
    required this.monthlyCostVnd,
    required this.monthlyProfitVnd,
    required this.orderCount,
    required this.revenueTrendPercent,
    required this.profitTrendPercent,
  });

  final int qualifiedCrabCount;
  final double yieldKg;
  final int monthlyRevenueVnd;
  final int monthlyCostVnd;
  final int monthlyProfitVnd;
  final int orderCount;
  final double revenueTrendPercent;
  final double profitTrendPercent;
}

class QualifiedCrab {
  const QualifiedCrab({
    required this.id,
    required this.code,
    required this.weightG,
    required this.size,
    required this.healthScore,
    required this.batchId,
    required this.area,
  });

  final String id;
  final String code;
  final int weightG;
  final CrabSizeGrade size;
  final int healthScore;
  final String batchId;
  final String area;
}

class CrabSizeSegment {
  const CrabSizeSegment({
    required this.size,
    required this.count,
    required this.percent,
    required this.color,
  });

  final CrabSizeGrade size;
  final int count;
  final double percent;
  final Color color;
}

class MonthlyFinancePoint {
  const MonthlyFinancePoint({
    required this.month,
    required this.revenueM,
    required this.profitM,
  });

  final String month;
  final double revenueM;
  final double profitM;
}

class BatchProfitPoint {
  const BatchProfitPoint({
    required this.batchId,
    required this.profitM,
  });

  final String batchId;
  final double profitM;
}

class SalesOrder {
  const SalesOrder({
    required this.id,
    required this.code,
    required this.customerName,
    required this.customerCode,
    required this.orderDate,
    required this.totalWeightKg,
    required this.pricePerKg,
    required this.revenueVnd,
    required this.status,
    required this.productType,
    required this.batchId,
  });

  final String id;
  final String code;
  final String customerName;
  final String customerCode;
  final String orderDate;
  final double totalWeightKg;
  final int pricePerKg;
  final int revenueVnd;
  final SalesOrderStatus status;
  final String productType;
  final String batchId;
}

class Customer {
  const Customer({
    required this.id,
    required this.code,
    required this.name,
    required this.phone,
    required this.address,
    required this.typeLabel,
    this.note,
  });

  final String id;
  final String code;
  final String name;
  final String phone;
  final String address;
  final String typeLabel;
  final String? note;
}

class HarvestSlip {
  HarvestSlip({
    required this.id,
    required this.code,
    required this.harvestDate,
    required this.batchId,
    required this.area,
    required this.quantity,
    required this.totalWeightKg,
    required this.performedBy,
    this.note,
  });

  final String id;
  final String code;
  final String harvestDate;
  final String batchId;
  final String area;
  final int quantity;
  final double totalWeightKg;
  final String performedBy;
  final String? note;
}

class MarketInfo {
  const MarketInfo({
    required this.priceLabel,
    required this.pricePerKg,
    required this.priceTrendPercent,
    required this.frozenStockKg,
  });

  final String priceLabel;
  final int pricePerKg;
  final double priceTrendPercent;
  final double frozenStockKg;
}

enum HarvestEligibility { eligible, monitoring, notEligible }

enum HarvestUiStatus {
  draft,
  pending,
  inProgress,
  completed,
  waitingSale,
  transferred,
  cancelled,
}

enum HarvestProductType { all, meat, softshell, other }

enum HarvestTimeRange { today, d7, d30, all }

enum HarvestSlipSort { newest, oldest, mostCrabs, mostWeight }

class HarvestKpi {
  const HarvestKpi({
    required this.harvestable,
    required this.softshellWaiting,
    required this.harvestedToday,
    required this.waitingSale,
    required this.totalWeightKg,
  });

  final int harvestable;
  final int softshellWaiting;
  final int harvestedToday;
  final int waitingSale;
  final double totalWeightKg;
}

enum SaleEligibility { ready, review, notAvailable }

enum SalesOrderUiStatus { draft, waiting, pendingPayment, completed, cancelled }

enum SalesPaymentUi { unpaid, partial, paid, refunded }

enum SalesOrderSort { newest, oldest, mostAmount, mostCrabs }

enum SalesKpiFocus { waitingSale, sold, ordersToday, unpaid }

class SalesKpi {
  const SalesKpi({
    required this.revenueTodayVnd,
    required this.soldToday,
    required this.inventory,
    this.ordersToday = 0,
    this.unpaidVnd = 0,
    this.revenueTrendPercent = 0,
    this.soldTrend = 0,
    this.unpaidOrdersTrend = 0,
  });

  final int revenueTodayVnd;
  final int soldToday;
  final int inventory;
  final int ordersToday;
  final int unpaidVnd;
  final double revenueTrendPercent;
  final int soldTrend;
  final int unpaidOrdersTrend;
}

class HarvestableCrab {
  const HarvestableCrab({
    required this.id,
    required this.code,
    required this.boxCode,
    required this.weightG,
    required this.condition,
    this.areaId = '',
    this.areaName = '',
    this.rowName = '',
    this.lotCode = '',
    this.isSoftshell = false,
    this.boxId = '',
    this.batchId = '',
    this.widthMm,
    this.lengthMm,
    this.gender = '',
    this.crabType = '',
    this.healthRaw = '',
    this.imageUrl,
    this.lastWeightAt,
    this.eligibility = HarvestEligibility.eligible,
    this.busyInSlip = false,
    this.statusRaw = '',
  });

  final String id;
  final String code;
  final String boxCode;
  final int weightG;
  final String condition;
  final String areaId;
  final String areaName;
  final String rowName;
  final String lotCode;
  final bool isSoftshell;
  final String boxId;
  final String batchId;
  final double? widthMm;
  final double? lengthMm;
  final String gender;
  final String crabType;
  final String healthRaw;
  final String? imageUrl;
  final DateTime? lastWeightAt;
  final HarvestEligibility eligibility;
  final bool busyInSlip;
  final String statusRaw;

  bool get canSelect =>
      !busyInSlip &&
      eligibility != HarvestEligibility.notEligible &&
      !_isDead &&
      !_isHarvested;

  bool get _isDead {
    final s = statusRaw.toLowerCase();
    return s == 'dead' || s.contains('chết');
  }

  bool get _isHarvested {
    final s = statusRaw.toLowerCase();
    return s == 'harvested' || s == 'sold';
  }

  String get disableReason {
    if (_isDead) return 'Cua này đã được đánh dấu chết.';
    if (_isHarvested) return 'Cua này đã được thu hoạch.';
    if (busyInSlip) return 'Cua đang thuộc phiếu thu hoạch khác chưa hoàn tất.';
    if (eligibility == HarvestEligibility.notEligible) {
      return 'Cua này chưa đủ điều kiện thu hoạch.';
    }
    return 'Không thể chọn cua này.';
  }

  bool get readyForSoftshellExport =>
      isSoftshell ||
      condition.toLowerCase().contains('lột') ||
      condition.toLowerCase().contains('molt');

  String get locationLine {
    final parts = [
      if (areaName.trim().isNotEmpty) areaName.trim(),
      if (rowName.trim().isNotEmpty) rowName.trim(),
      if (boxCode.trim().isNotEmpty) boxCode.trim(),
    ];
    return parts.isEmpty ? '—' : parts.join(' → ');
  }
}

class InventoryCrab {
  const InventoryCrab({
    required this.id,
    required this.code,
    required this.boxCode,
    required this.weightG,
    required this.grade,
    this.crabType = '',
    this.harvestedAt,
    this.harvestCode = '',
    this.lotCode = '',
    this.isSoftshell = false,
    this.eligibility = SaleEligibility.ready,
    this.busyInOrder = false,
  });

  final String id;
  final String code;
  final String boxCode;
  final int weightG;
  final String grade;
  final String crabType;
  final DateTime? harvestedAt;
  final String harvestCode;
  final String lotCode;
  final bool isSoftshell;
  final SaleEligibility eligibility;
  final bool busyInOrder;

  String get typeLabel =>
      crabType.trim().isEmpty ? 'Cua biển' : crabType.trim();

  String get productLabel => isSoftshell ? 'Cua lột' : 'Cua thịt';

  String get gradeLabel => switch (grade.trim().toUpperCase()) {
        'A' || 'GRADE_1' || '1' => 'Loại 1',
        'B' || 'GRADE_2' || '2' => 'Loại 2',
        'C' || 'GRADE_3' || '3' => 'Loại 3',
        '' => '—',
        _ => grade,
      };

  bool get canSelect =>
      !busyInOrder && eligibility != SaleEligibility.notAvailable;

  String get disableReason {
    if (busyInOrder) return 'Cua đang thuộc đơn bán hàng khác.';
    if (eligibility == SaleEligibility.notAvailable) {
      return 'Cua này hiện không thể bán.';
    }
    return 'Cua này hiện không thể thêm vào đơn bán hàng.';
  }
}

class HarvestSlipDetail extends HarvestSlip {
  HarvestSlipDetail({
    required super.id,
    required super.code,
    required super.harvestDate,
    required super.batchId,
    required super.area,
    required super.quantity,
    required super.totalWeightKg,
    required super.performedBy,
    super.note,
    required this.status,
    required this.lines,
    this.passedCount = 0,
    this.failedCount = 0,
    this.averageWeightG = 0,
    this.photoUrls = const [],
    this.harvestedAt,
    this.farmingAreaId,
    this.areaCode = '',
    this.uiStatus = HarvestUiStatus.completed,
  });

  final String status;
  final List<HarvestLineItem> lines;
  final int passedCount;
  final int failedCount;
  final double averageWeightG;
  final List<String> photoUrls;
  final DateTime? harvestedAt;
  final String? farmingAreaId;
  final String areaCode;
  final HarvestUiStatus uiStatus;

  HarvestProductType get productType {
    if (lines.isEmpty) return HarvestProductType.meat;
    final soft = lines.where((l) => l.isSoftshell).length;
    if (soft == lines.length) return HarvestProductType.softshell;
    if (soft == 0) return HarvestProductType.meat;
    return HarvestProductType.other;
  }

  String get productTypeLabel => switch (productType) {
        HarvestProductType.softshell => 'Cua lột',
        HarvestProductType.other => 'Khác',
        _ => 'Cua thịt',
      };

  String get classificationLabel {
    final grades = lines.map((l) => l.grade.trim().toUpperCase()).where((g) => g.isNotEmpty);
    if (grades.isEmpty) return '—';
    final first = grades.first;
    return switch (first) {
      'A' || 'GRADE_1' || '1' => 'Loại 1',
      'B' || 'GRADE_2' || '2' => 'Loại 2',
      'C' || 'GRADE_3' || '3' => 'Loại 3',
      _ => first,
    };
  }

  String get statusLabel => harvestUiStatusLabel(uiStatus);

  bool get isDraft => uiStatus == HarvestUiStatus.draft;
  bool get isPending => uiStatus == HarvestUiStatus.pending;
  bool get isInProgress => uiStatus == HarvestUiStatus.inProgress;
  bool get isCompleted =>
      uiStatus == HarvestUiStatus.completed ||
      uiStatus == HarvestUiStatus.waitingSale ||
      uiStatus == HarvestUiStatus.transferred;
  bool get isCancelled => uiStatus == HarvestUiStatus.cancelled;
  bool get canTransferToSale =>
      uiStatus == HarvestUiStatus.completed ||
      uiStatus == HarvestUiStatus.waitingSale;
  bool get canComplete =>
      uiStatus == HarvestUiStatus.draft ||
      uiStatus == HarvestUiStatus.pending ||
      uiStatus == HarvestUiStatus.inProgress;
  bool get canCancel =>
      uiStatus == HarvestUiStatus.draft ||
      uiStatus == HarvestUiStatus.pending;
}

String harvestUiStatusLabel(HarvestUiStatus s) => switch (s) {
      HarvestUiStatus.draft => 'Nháp',
      HarvestUiStatus.pending => 'Chờ thực hiện',
      HarvestUiStatus.inProgress => 'Đang thực hiện',
      HarvestUiStatus.completed => 'Hoàn thành',
      HarvestUiStatus.waitingSale => 'Chờ bán',
      HarvestUiStatus.transferred => 'Đã chuyển bán hàng',
      HarvestUiStatus.cancelled => 'Đã hủy',
    };

Color harvestUiStatusColor(HarvestUiStatus s) => switch (s) {
      HarvestUiStatus.draft => const Color(0xFF94A3B8),
      HarvestUiStatus.pending => DashboardColors.blue,
      HarvestUiStatus.inProgress => DashboardColors.blue,
      HarvestUiStatus.completed => DashboardColors.healthy,
      HarvestUiStatus.waitingSale => const Color(0xFFF5B700),
      HarvestUiStatus.transferred => DashboardColors.brand,
      HarvestUiStatus.cancelled => DashboardColors.risk,
    };

HarvestUiStatus parseHarvestUiStatus(String raw, {required bool stillInInventory}) {
  final s = raw.toLowerCase();
  if (s.contains('cancel') || s.contains('hủy')) return HarvestUiStatus.cancelled;
  if (s.contains('progress') || s.contains('đang')) return HarvestUiStatus.inProgress;
  if (s.contains('pending') || s.contains('chờ thực')) return HarvestUiStatus.pending;
  if (s.contains('plan') || s.contains('draft') || s.contains('nháp')) {
    return HarvestUiStatus.draft;
  }
  if (s.contains('complete') || s.contains('hoàn')) {
    return stillInInventory ? HarvestUiStatus.waitingSale : HarvestUiStatus.completed;
  }
  if (s.contains('sale') || s.contains('bán')) {
    return stillInInventory ? HarvestUiStatus.waitingSale : HarvestUiStatus.transferred;
  }
  return HarvestUiStatus.completed;
}

class HarvestLineItem {
  const HarvestLineItem({
    required this.crabId,
    required this.crabCode,
    required this.boxCode,
    required this.weightG,
    required this.grade,
    required this.condition,
    this.photoCount = 0,
    this.note,
    this.areaName = '',
    this.rowName = '',
    this.lotCode = '',
    this.result = 'passed',
    this.isSoftshell = false,
    this.boxId = '',
    this.batchId = '',
    this.gender = '',
    this.crabType = '',
    this.widthMm,
    this.lengthMm,
    this.imageUrl,
  });

  final String? crabId;
  final String crabCode;
  final String boxCode;
  final int weightG;
  final String grade;
  final String condition;
  final int photoCount;
  final String? note;
  final String areaName;
  final String rowName;
  final String lotCode;
  final String result;
  final bool isSoftshell;
  final String boxId;
  final String batchId;
  final String gender;
  final String crabType;
  final double? widthMm;
  final double? lengthMm;
  final String? imageUrl;

  bool get passed => result.toLowerCase() != 'failed';

  String get locationLine {
    final parts = [
      if (areaName.trim().isNotEmpty) areaName.trim(),
      if (rowName.trim().isNotEmpty) rowName.trim(),
      if (boxCode.trim().isNotEmpty) boxCode.trim(),
    ];
    return parts.isEmpty ? (boxCode.isEmpty ? '—' : boxCode) : parts.join(' → ');
  }
}

class SalesOrderDetail {
  const SalesOrderDetail({
    required this.id,
    required this.code,
    required this.orderDate,
    required this.customerName,
    required this.customerPhone,
    required this.sellerName,
    required this.paymentStatus,
    required this.crabCount,
    required this.revenueVnd,
    required this.lines,
    this.customerAddress = '',
    this.orderStatus = 'Completed',
    this.paymentMethod = '',
    this.deliveryStatus = 'pickup',
    this.subtotalVnd = 0,
    this.discountVnd = 0,
    this.shippingVnd = 0,
    this.paidVnd = 0,
    this.totalWeightKg = 0,
    this.notes,
    this.customerType = '',
    this.customerId = '',
  });

  final String id;
  final String code;
  final DateTime orderDate;
  final String customerName;
  final String customerPhone;
  final String customerAddress;
  final String sellerName;
  final String orderStatus;
  final String paymentStatus;
  final String paymentMethod;
  final String deliveryStatus;
  final int crabCount;
  final int subtotalVnd;
  final int discountVnd;
  final int shippingVnd;
  final int revenueVnd;
  final int paidVnd;
  final double totalWeightKg;
  final String? notes;
  final List<SalesOrderLineItem> lines;
  final String customerType;
  final String customerId;

  bool get isPaid =>
      paymentStatus.toLowerCase() == 'paid' ||
      paymentStatus.toLowerCase().contains('đã thanh');

  bool get isPartial => paymentStatus.toLowerCase().contains('partial');

  bool get isDraft {
    final s = orderStatus.toLowerCase();
    return s.contains('draft') || s.contains('quotation') || s.contains('nháp');
  }

  bool get isCancelled {
    final s = orderStatus.toLowerCase();
    return s.contains('cancel') || s.contains('hủy');
  }

  bool get isCompleted {
    final s = orderStatus.toLowerCase();
    return s.contains('complete') || s.contains('hoàn');
  }

  int get remainingVnd => (revenueVnd - paidVnd).clamp(0, revenueVnd);

  SalesOrderUiStatus get uiStatus {
    if (isCancelled) return SalesOrderUiStatus.cancelled;
    if (isDraft) return SalesOrderUiStatus.draft;
    if (isCompleted) return SalesOrderUiStatus.completed;
    if (!isPaid) return SalesOrderUiStatus.pendingPayment;
    return SalesOrderUiStatus.waiting;
  }

  SalesPaymentUi get paymentUi {
    if (paymentStatus.toLowerCase().contains('refund')) {
      return SalesPaymentUi.refunded;
    }
    if (isPaid) return SalesPaymentUi.paid;
    if (isPartial) return SalesPaymentUi.partial;
    return SalesPaymentUi.unpaid;
  }

  String get orderStatusLabel => salesOrderUiLabel(uiStatus);

  String get paymentStatusLabel => salesPaymentUiLabel(paymentUi);

  String get customerTypeLabel => switch (customerType.toLowerCase()) {
        'wholesale' || 'sỉ' => 'Khách sỉ',
        'restaurant' || 'nhahang' || 'nhà hàng' => 'Nhà hàng',
        'agent' || 'đại lý' || 'daily' => 'Đại lý',
        'other' || 'khác' => 'Khác',
        _ => customerType.trim().isEmpty ? 'Khách lẻ' : customerType,
      };

  int get avgPricePerKg {
    if (totalWeightKg <= 0) return 0;
    return (subtotalVnd / totalWeightKg).round();
  }

  List<String> get harvestCodes =>
      {for (final l in lines) if (l.harvestCode.isNotEmpty) l.harvestCode}
          .toList();

  HarvestProductType get productType {
    if (lines.isEmpty) return HarvestProductType.meat;
    final soft = lines.where((l) => l.isSoftshell).length;
    if (soft == lines.length) return HarvestProductType.softshell;
    if (soft == 0) return HarvestProductType.meat;
    return HarvestProductType.other;
  }

  String get paymentMethodLabel => switch (paymentMethod.toLowerCase()) {
        'transfer' || 'bank' => 'Chuyển khoản',
        'unpaid' => 'Chưa thanh toán',
        'cash' => 'Tiền mặt',
        _ => isPaid || isPartial ? 'Tiền mặt' : 'Chưa thanh toán',
      };

  String get deliveryStatusLabel => switch (deliveryStatus.toLowerCase()) {
        'delivery' => 'Giao hàng',
        'shipping' => 'Đang giao',
        'delivered' => 'Đã giao',
        _ => 'Nhận tại trại',
      };
}

class SalesOrderLineItem {
  const SalesOrderLineItem({
    required this.crabCode,
    required this.quantity,
    required this.weightG,
    required this.unitPricePerKg,
    required this.totalVnd,
    this.crabId,
    this.crabType = '',
    this.grade = '',
    this.harvestCode = '',
    this.boxCode = '',
    this.lotCode = '',
    this.isSoftshell = false,
    this.gender = '',
    this.widthMm,
    this.lengthMm,
    this.imageUrl,
  });

  final String? crabId;
  final String crabCode;
  final String crabType;
  final String grade;
  final int quantity;
  final int weightG;
  final int unitPricePerKg;
  final int totalVnd;
  final String harvestCode;
  final String boxCode;
  final String lotCode;
  final bool isSoftshell;
  final String gender;
  final double? widthMm;
  final double? lengthMm;
  final String? imageUrl;

  String get typeLabel => crabType.trim().isEmpty ? 'Cua biển' : crabType.trim();
}

String salesOrderUiLabel(SalesOrderUiStatus s) => switch (s) {
      SalesOrderUiStatus.draft => 'Nháp',
      SalesOrderUiStatus.waiting => 'Chờ bán',
      SalesOrderUiStatus.pendingPayment => 'Chờ thanh toán',
      SalesOrderUiStatus.completed => 'Hoàn thành',
      SalesOrderUiStatus.cancelled => 'Đã hủy',
    };

Color salesOrderUiColor(SalesOrderUiStatus s) => switch (s) {
      SalesOrderUiStatus.draft => const Color(0xFF94A3B8),
      SalesOrderUiStatus.waiting => const Color(0xFFF5B700),
      SalesOrderUiStatus.pendingPayment => DashboardColors.blue,
      SalesOrderUiStatus.completed => DashboardColors.brand,
      SalesOrderUiStatus.cancelled => DashboardColors.risk,
    };

String salesPaymentUiLabel(SalesPaymentUi s) => switch (s) {
      SalesPaymentUi.unpaid => 'Chưa thanh toán',
      SalesPaymentUi.partial => 'Thanh toán một phần',
      SalesPaymentUi.paid => 'Đã thanh toán',
      SalesPaymentUi.refunded => 'Đã hoàn tiền',
    };

Color salesPaymentUiColor(SalesPaymentUi s) => switch (s) {
      SalesPaymentUi.unpaid => DashboardColors.risk,
      SalesPaymentUi.partial => const Color(0xFFF5B700),
      SalesPaymentUi.paid => DashboardColors.brand,
      SalesPaymentUi.refunded => const Color(0xFF94A3B8),
    };

String saleEligibilityLabel(SaleEligibility e) => switch (e) {
      SaleEligibility.ready => 'Sẵn sàng bán',
      SaleEligibility.review => 'Cần xem xét',
      SaleEligibility.notAvailable => 'Không thể bán',
    };

String formatVnd(int vnd) {
  final s = vnd.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  return '${buf.toString()}đ';
}

String formatHarvestDate(DateTime at) =>
    '${at.day.toString().padLeft(2, '0')}/${at.month.toString().padLeft(2, '0')}/${at.year}';

String formatHarvestDateTime(DateTime at) =>
    '${formatHarvestDate(at)}  ${at.hour.toString().padLeft(2, '0')}:${at.minute.toString().padLeft(2, '0')}';
