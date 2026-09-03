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
