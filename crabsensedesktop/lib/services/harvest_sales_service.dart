import 'package:flutter/foundation.dart';

import '../models/auth_models.dart';
import '../models/harvest_sales.dart';
import 'cloud_api_client.dart';

class HarvestSalesService extends ChangeNotifier {
  HarvestSalesService({required AuthSession session, CloudApiClient? api})
      : _session = session,
        _api = api ?? CloudApiClient();

  AuthSession _session;
  final CloudApiClient _api;

  List<QualifiedCrab> _qualified = [];
  List<SalesOrder> _orders = [];
  List<HarvestSlip> _harvests = [];
  HarvestSalesKpi _kpi = const HarvestSalesKpi(
    qualifiedCrabCount: 0,
    yieldKg: 0,
    monthlyRevenueVnd: 0,
    monthlyCostVnd: 0,
    monthlyProfitVnd: 0,
    orderCount: 0,
    revenueTrendPercent: 0,
    profitTrendPercent: 0,
  );
  String _search = '';
  bool loading = false;
  String? error;

  HarvestSalesKpi get kpi => _kpi;
  String get aiInsight => _orders.isEmpty
      ? 'Chưa có giao dịch bán trên CrabSenseBE.'
      : 'Có ${_orders.length} đơn, ${_harvests.length} phiếu thu hoạch.';
  String get aiRecommendation =>
      'Theo dõi phiếu thu hoạch và đối chiếu với đơn bán.';
  MarketInfo get market => const MarketInfo(
        priceLabel: '—',
        pricePerKg: 0,
        priceTrendPercent: 0,
        frozenStockKg: 0,
      );
  List<CrabSizeSegment> get sizeDistribution => const [];
  List<MonthlyFinancePoint> get monthlyFinance => const [];
  List<BatchProfitPoint> get batchProfits => const [];
  List<Customer> get customers => const [];
  List<HarvestSlip> get harvests => List.unmodifiable(_harvests);

  List<QualifiedCrab> get qualifiedCrabs {
    if (_search.trim().isEmpty) return List.unmodifiable(_qualified);
    final q = _search.toLowerCase();
    return _qualified
        .where(
          (c) =>
              c.code.toLowerCase().contains(q) ||
              c.batchId.toLowerCase().contains(q),
        )
        .toList();
  }

  List<SalesOrder> get orders {
    if (_search.trim().isEmpty) return List.unmodifiable(_orders);
    final q = _search.toLowerCase();
    return _orders
        .where(
          (o) =>
              o.code.toLowerCase().contains(q) ||
              o.customerName.toLowerCase().contains(q),
        )
        .toList();
  }

  void updateSession(AuthSession session) {
    _session = session;
  }

  void setSearch(String v) {
    _search = v;
    notifyListeners();
  }

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, 1);
      final vouchers = await _api.fetchHarvestVouchers(_session.token);
      final sales = await _api.fetchSalesHistory(_session.token);
      Map<String, dynamic> summary = {};
      try {
        summary = await _api.fetchSalesSummary(
          _session.token,
          start: start,
          end: now,
          farmingAreaId: _session.selectedFarm.id,
        );
      } catch (_) {}

      _harvests = vouchers.map(_voucherToSlip).toList();
      _orders = sales.map(_saleToOrder).toList();
      final crabs = await _api.fetchFarmCrabs(
        _session.token,
        _session.selectedFarm.id,
      );
      _qualified = crabs.crabs
          .where((c) => c.status != 'dead')
          .map(
            (c) => QualifiedCrab(
              id: c.id,
              code: c.crabCode,
              weightG: (c.weight ?? 0).round(),
              size: CrabSizeGrade.fromWeightG((c.weight ?? 0).round()),
              healthScore: c.status == 'alive' ? 80 : 60,
              batchId: c.batchCode,
              area: c.areaName,
            ),
          )
          .toList();

      final revenue = (summary['totalRevenue'] ?? summary['TotalRevenue'] as num?)
              ?.toInt() ??
          _orders.fold<int>(0, (s, o) => s + o.revenueVnd);
      final qty = (summary['totalQuantity'] ?? summary['TotalQuantity'] as num?)
              ?.toDouble() ??
          _harvests.fold<double>(0, (s, h) => s + h.totalWeightKg);
      _kpi = HarvestSalesKpi(
        qualifiedCrabCount: _qualified.length,
        yieldKg: qty,
        monthlyRevenueVnd: revenue,
        monthlyCostVnd: 0,
        monthlyProfitVnd: revenue,
        orderCount: (summary['transactionCount'] ??
                    summary['TransactionCount'] as num?)
                ?.toInt() ??
            _orders.length,
        revenueTrendPercent: 0,
        profitTrendPercent: 0,
      );
      error = null;
    } on CloudApiException catch (e) {
      error = e.message;
    } catch (e) {
      error = '$e';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> createHarvestSlip({
    required String harvestDate,
    required String batchId,
    required String area,
    required int quantity,
    required double totalWeightKg,
    required String performedBy,
    String? note,
  }) async {
    final parsed = DateTime.tryParse(harvestDate) ?? DateTime.now();
    await _api.createHarvestVoucher(
      _session.token,
      harvestDate: parsed,
      notes: [
        if (batchId.isNotEmpty) 'Lô $batchId',
        if (area.isNotEmpty) area,
        if (performedBy.isNotEmpty) performedBy,
        if (note != null) note,
      ].join(' — '),
      quantity: quantity,
      totalWeightKg: totalWeightKg,
    );
    await load();
  }

  HarvestSlip _voucherToSlip(Map<String, dynamic> json) {
    final at = DateTime.tryParse(
          (json['harvestDate'] ?? json['HarvestDate'] ?? '').toString(),
        ) ??
        DateTime.now();
    return HarvestSlip(
      id: (json['id'] ?? json['Id']).toString(),
      code: (json['voucherCode'] ?? json['VoucherCode'] ?? '').toString(),
      harvestDate:
          '${at.day.toString().padLeft(2, '0')}/${at.month.toString().padLeft(2, '0')}/${at.year}',
      batchId: '',
      area: _session.selectedFarm.name,
      quantity: (json['totalQuantity'] ?? json['TotalQuantity'] as num?)?.toInt() ?? 0,
      totalWeightKg:
          (json['totalWeightKg'] ?? json['TotalWeightKg'] as num?)?.toDouble() ??
              0,
      performedBy: '',
      note: (json['notes'] ?? json['Notes'])?.toString(),
    );
  }

  SalesOrder _saleToOrder(Map<String, dynamic> json) {
    final at = DateTime.tryParse(
          (json['saleDate'] ?? json['SaleDate'] ?? '').toString(),
        ) ??
        DateTime.now();
    final statusRaw =
        (json['paymentStatus'] ?? json['PaymentStatus'] ?? '').toString();
    return SalesOrder(
      id: (json['id'] ?? json['Id']).toString(),
      code: (json['id'] ?? json['Id']).toString().substring(
            0,
            ((json['id'] ?? json['Id']).toString().length).clamp(0, 8),
          ),
      customerName: (json['buyerName'] ?? json['BuyerName'] ?? '').toString(),
      customerCode: (json['buyerContact'] ?? json['BuyerContact'] ?? '').toString(),
      orderDate:
          '${at.day.toString().padLeft(2, '0')}/${at.month.toString().padLeft(2, '0')}/${at.year}',
      totalWeightKg:
          (json['quantity'] ?? json['Quantity'] as num?)?.toDouble() ?? 0,
      pricePerKg: (json['unitPrice'] ?? json['UnitPrice'] as num?)?.toInt() ?? 0,
      revenueVnd:
          (json['totalAmount'] ?? json['TotalAmount'] as num?)?.toInt() ?? 0,
      status: _saleStatus(statusRaw),
      productType: 'Cua sống',
      batchId: '',
    );
  }

  SalesOrderStatus _saleStatus(String raw) {
    final s = raw.toLowerCase();
    if (s.contains('paid') || s.contains('complete')) {
      return SalesOrderStatus.paid;
    }
    if (s.contains('cancel')) return SalesOrderStatus.cancelled;
    if (s.contains('deliver')) return SalesOrderStatus.delivering;
    return SalesOrderStatus.newOrder;
  }
}
