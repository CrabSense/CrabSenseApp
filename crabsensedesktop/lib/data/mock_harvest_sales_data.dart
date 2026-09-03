import 'package:flutter/material.dart';

import '../models/harvest_sales.dart';

abstract final class MockHarvestSalesData {
  static const kpi = HarvestSalesKpi(
    qualifiedCrabCount: 2150,
    yieldKg: 320,
    monthlyRevenueVnd: 185000000,
    monthlyCostVnd: 118000000,
    monthlyProfitVnd: 67000000,
    orderCount: 12,
    revenueTrendPercent: 12,
    profitTrendPercent: 8,
  );

  static const aiInsight =
      'Lứa CFM-2026-001 đạt tỷ lệ sống 95%. FCR đạt 1.82 (tốt). '
      'Kích cỡ XL chiếm 58%.';

  static const aiRecommendation =
      'Thu hoạch trong vòng 5 ngày tới để đạt giá bán tối ưu.';

  static const market = MarketInfo(
    priceLabel: 'Giá cua gạch (XXL)',
    pricePerKg: 450000,
    priceTrendPercent: 2,
    frozenStockKg: 45.2,
  );

  static List<QualifiedCrab> qualifiedCrabs() => const [
        QualifiedCrab(
          id: 'q1',
          code: 'CRAB-A01-001',
          weightG: 185,
          size: CrabSizeGrade.xl,
          healthScore: 92,
          batchId: 'CFM-2026-001',
          area: 'Khu A',
        ),
        QualifiedCrab(
          id: 'q2',
          code: 'CRAB-A02-004',
          weightG: 170,
          size: CrabSizeGrade.l,
          healthScore: 88,
          batchId: 'CFM-2026-001',
          area: 'Khu A',
        ),
        QualifiedCrab(
          id: 'q3',
          code: 'CRAB-B01-002',
          weightG: 210,
          size: CrabSizeGrade.xxl,
          healthScore: 95,
          batchId: 'CFM-2026-002',
          area: 'Khu B',
        ),
        QualifiedCrab(
          id: 'q4',
          code: 'CRAB-B02-011',
          weightG: 198,
          size: CrabSizeGrade.xl,
          healthScore: 90,
          batchId: 'CFM-2026-002',
          area: 'Khu B',
        ),
        QualifiedCrab(
          id: 'q5',
          code: 'CRAB-C01-007',
          weightG: 155,
          size: CrabSizeGrade.l,
          healthScore: 84,
          batchId: 'CFM-2026-003',
          area: 'Khu C',
        ),
        QualifiedCrab(
          id: 'q6',
          code: 'CRAB-A01-018',
          weightG: 142,
          size: CrabSizeGrade.m,
          healthScore: 82,
          batchId: 'CFM-2026-001',
          area: 'Khu A',
        ),
      ];

  static List<CrabSizeSegment> sizeDistribution() => const [
        CrabSizeSegment(
          size: CrabSizeGrade.xxl,
          count: 120,
          percent: 25,
          color: Color(0xFF7C5CFF),
        ),
        CrabSizeSegment(
          size: CrabSizeGrade.xl,
          count: 520,
          percent: 20,
          color: Color(0xFF4DA6FF),
        ),
        CrabSizeSegment(
          size: CrabSizeGrade.l,
          count: 840,
          percent: 30,
          color: Color(0xFF57E6FF),
        ),
        CrabSizeSegment(
          size: CrabSizeGrade.m,
          count: 430,
          percent: 15,
          color: Color(0xFF3B82F6),
        ),
        CrabSizeSegment(
          size: CrabSizeGrade.s,
          count: 240,
          percent: 10,
          color: Color(0xFF64748B),
        ),
      ];

  static List<MonthlyFinancePoint> monthlyFinance() => const [
        MonthlyFinancePoint(month: 'T1', revenueM: 25, profitM: 8),
        MonthlyFinancePoint(month: 'T2', revenueM: 32, profitM: 11),
        MonthlyFinancePoint(month: 'T3', revenueM: 42, profitM: 14),
        MonthlyFinancePoint(month: 'T4', revenueM: 48, profitM: 16),
        MonthlyFinancePoint(month: 'T5', revenueM: 53, profitM: 18),
        MonthlyFinancePoint(month: 'T6', revenueM: 58, profitM: 20),
        MonthlyFinancePoint(month: 'T7', revenueM: 62, profitM: 22),
        MonthlyFinancePoint(month: 'T8', revenueM: 55, profitM: 19),
        MonthlyFinancePoint(month: 'T9', revenueM: 61, profitM: 21),
        MonthlyFinancePoint(month: 'T10', revenueM: 68, profitM: 24),
        MonthlyFinancePoint(month: 'T11', revenueM: 72, profitM: 26),
        MonthlyFinancePoint(month: 'T12', revenueM: 78, profitM: 28),
      ];

  static List<BatchProfitPoint> batchProfits() => const [
        BatchProfitPoint(batchId: 'CFM-2026-001', profitM: 11.7),
        BatchProfitPoint(batchId: 'CFM-2026-002', profitM: 14.2),
        BatchProfitPoint(batchId: 'CFM-2026-003', profitM: 9.8),
      ];

  static List<SalesOrder> orders() => const [
        SalesOrder(
          id: 'o1',
          code: 'ORD-5501',
          customerName: 'Hải Sản Biển Đông',
          customerCode: 'KH001',
          orderDate: '18/05/2026',
          totalWeightKg: 168,
          pricePerKg: 320000,
          revenueVnd: 53760000,
          status: SalesOrderStatus.paid,
          productType: 'Cua thịt',
          batchId: 'CFM-2026-001',
        ),
        SalesOrder(
          id: 'o2',
          code: 'ORD-5502',
          customerName: 'Công ty Hải Sản ABC',
          customerCode: 'KH002',
          orderDate: '15/05/2026',
          totalWeightKg: 95,
          pricePerKg: 310000,
          revenueVnd: 29450000,
          status: SalesOrderStatus.delivering,
          productType: 'Cua thịt',
          batchId: 'CFM-2026-002',
        ),
        SalesOrder(
          id: 'o3',
          code: 'ORD-5503',
          customerName: 'Nhà hàng Cua Biển',
          customerCode: 'KH003',
          orderDate: '12/05/2026',
          totalWeightKg: 42,
          pricePerKg: 450000,
          revenueVnd: 18900000,
          status: SalesOrderStatus.paid,
          productType: 'Cua gạch XXL',
          batchId: 'CFM-2026-002',
        ),
        SalesOrder(
          id: 'o4',
          code: 'ORD-5504',
          customerName: 'Chợ đầu mối Cà Mau',
          customerCode: 'KH004',
          orderDate: '10/05/2026',
          totalWeightKg: 120,
          pricePerKg: 295000,
          revenueVnd: 35400000,
          status: SalesOrderStatus.newOrder,
          productType: 'Cua thịt',
          batchId: 'CFM-2026-001',
        ),
        SalesOrder(
          id: 'o5',
          code: 'ORD-5505',
          customerName: 'Xuất khẩu SG',
          customerCode: 'KH005',
          orderDate: '08/05/2026',
          totalWeightKg: 200,
          pricePerKg: 340000,
          revenueVnd: 68000000,
          status: SalesOrderStatus.delivered,
          productType: 'Cua thịt',
          batchId: 'CFM-2026-003',
        ),
      ];

  static List<Customer> customers() => const [
        Customer(
          id: 'c1',
          code: 'KH001',
          name: 'Công ty Hải Sản ABC',
          phone: '0901234567',
          address: 'Cà Mau',
          typeLabel: 'Đại lý',
        ),
        Customer(
          id: 'c2',
          code: 'KH002',
          name: 'Hải Sản Biển Đông',
          phone: '0912345678',
          address: 'Bạc Liêu',
          typeLabel: 'Nhà hàng',
        ),
      ];

  static String formatVndShort(int vnd) {
    if (vnd >= 1000000000) {
      return '${(vnd / 1000000000).toStringAsFixed(1)}B';
    }
    if (vnd >= 1000000) {
      return '${(vnd / 1000000).toStringAsFixed(vnd % 1000000 == 0 ? 0 : 1)}M';
    }
    if (vnd >= 1000) {
      return '${(vnd / 1000).round()}K';
    }
    return '$vnd';
  }

  static String formatVndFull(int vnd) {
    final s = vnd.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return '${buf.toString()}đ';
  }
}
