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

class HarvestKpi {
  const HarvestKpi({
    required this.harvestable,
    required this.harvestedToday,
    required this.waitingSale,
    required this.totalWeightKg,
  });

  final int harvestable;
  final int harvestedToday;
  final int waitingSale;
  final double totalWeightKg;
}

class SalesKpi {
  const SalesKpi({
    required this.revenueTodayVnd,
    required this.soldToday,
    required this.inventory,
  });

  final int revenueTodayVnd;
  final int soldToday;
  final int inventory;
}

class HarvestableCrab {
  const HarvestableCrab({
    required this.id,
    required this.code,
    required this.boxCode,
    required this.weightG,
    required this.condition,
    this.areaName = '',
    this.rowName = '',
    this.lotCode = '',
  });

  final String id;
  final String code;
  final String boxCode;
  final int weightG;
  final String condition;
  final String areaName;
  final String rowName;
  final String lotCode;

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
  });

  final String id;
  final String code;
  final String boxCode;
  final int weightG;
  final String grade;
  final String crabType;
  final DateTime? harvestedAt;

  String get typeLabel =>
      crabType.trim().isEmpty ? 'Cua biển' : crabType.trim();
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
  });

  final String status;
  final List<HarvestLineItem> lines;
  final int passedCount;
  final int failedCount;
  final double averageWeightG;
  final List<String> photoUrls;

  String get statusLabel {
    final s = status.toLowerCase();
    if (s.contains('cancel')) return 'Đã hủy';
    if (s.contains('complete') || s.contains('hoàn')) return 'Hoàn thành';
    if (s.contains('progress')) return 'Đang thu';
    return 'Nháp';
  }
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

  String get orderStatusLabel {
    if (isCancelled) return 'Đã hủy';
    if (isDraft) return 'Nháp';
    if (isCompleted) return 'Hoàn thành';
    return 'Đang xử lý';
  }

  String get paymentStatusLabel {
    if (isCancelled) return 'Đã hủy';
    if (isPaid) return 'Đã thanh toán';
    if (isPartial) return 'Thanh toán một phần';
    return 'Chưa thanh toán';
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
    this.crabType = '',
    this.grade = '',
  });

  final String crabCode;
  final String crabType;
  final String grade;
  final int quantity;
  final int weightG;
  final int unitPricePerKg;
  final int totalVnd;

  String get typeLabel => crabType.trim().isEmpty ? 'Cua biển' : crabType.trim();
}

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
