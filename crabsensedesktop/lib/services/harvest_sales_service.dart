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

  List<HarvestableCrab> _harvestable = [];
  List<InventoryCrab> _inventory = [];
  List<HarvestSlipDetail> _harvests = [];
  List<SalesOrderDetail> _orders = [];
  HarvestKpi _harvestKpi = const HarvestKpi(
    harvestable: 0,
    harvestedToday: 0,
    waitingSale: 0,
    totalWeightKg: 0,
  );
  SalesKpi _salesKpi = const SalesKpi(
    revenueTodayVnd: 0,
    soldToday: 0,
    inventory: 0,
  );
  String _search = '';
  bool loading = false;
  String? error;

  String get performerName => _session.user.displayName;

  String get nextVoucherPreview {
    var max = 0;
    for (final h in _harvests) {
      final code = h.code.toUpperCase();
      if (!code.startsWith('HAR-')) continue;
      final n = int.tryParse(code.substring(4));
      if (n != null && n > max) max = n;
    }
    return 'HAR-${(max + 1).toString().padLeft(3, '0')}';
  }

  Future<String?> uploadPhoto(String path) =>
      _api.uploadOperationPhoto(_session.token, path);
  String get areaName => _session.selectedFarm.name;
  String get areaId => _session.selectedFarm.id;
  String get token => _session.token;

  HarvestKpi get harvestKpi => _harvestKpi;
  SalesKpi get salesKpi => _salesKpi;
  List<HarvestableCrab> get harvestableCrabs => List.unmodifiable(_harvestable);
  List<InventoryCrab> get inventory => List.unmodifiable(_inventory);

  HarvestSalesKpi get kpi => HarvestSalesKpi(
        qualifiedCrabCount: _harvestKpi.harvestable,
        yieldKg: _harvestKpi.totalWeightKg,
        monthlyRevenueVnd: _salesKpi.revenueTodayVnd,
        monthlyCostVnd: 0,
        monthlyProfitVnd: _salesKpi.revenueTodayVnd,
        orderCount: _orders.length,
        revenueTrendPercent: 0,
        profitTrendPercent: 0,
      );

  String get aiInsight => _orders.isEmpty
      ? 'Chưa có đơn bán. Thu hoạch xong cua vào tồn kho, chưa tự bán.'
      : 'Có ${_orders.length} đơn, ${_harvests.length} phiếu thu hoạch.';
  String get aiRecommendation =>
      'Thu hoạch lấy cua ra khỏi nuôi. Bán hàng mới chuyển Đã bán.';
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
  List<HarvestSlipDetail> get harvestSlips {
    if (_search.trim().isEmpty) return List.unmodifiable(_harvests);
    final q = _search.toLowerCase();
    return _harvests
        .where((h) =>
            h.code.toLowerCase().contains(q) ||
            h.performedBy.toLowerCase().contains(q))
        .toList();
  }

  List<QualifiedCrab> get qualifiedCrabs {
    return _harvestable
        .map(
          (c) => QualifiedCrab(
            id: c.id,
            code: c.code,
            weightG: c.weightG,
            size: CrabSizeGrade.fromWeightG(c.weightG),
            healthScore: 80,
            batchId: '',
            area: c.areaName,
          ),
        )
        .toList();
  }

  List<SalesOrder> get orders => _orders
      .map(
        (o) => SalesOrder(
          id: o.id,
          code: o.code,
          customerName: o.customerName,
          customerCode: o.customerPhone,
          orderDate: formatHarvestDate(o.orderDate),
          totalWeightKg: o.lines.fold<double>(0, (s, l) => s + l.weightG / 1000),
          pricePerKg: o.lines.isEmpty ? 0 : o.lines.first.unitPricePerKg,
          revenueVnd: o.revenueVnd,
          status: o.isPaid ? SalesOrderStatus.paid : SalesOrderStatus.newOrder,
          productType: 'Cua sống',
          batchId: '',
        ),
      )
      .toList();

  List<SalesOrderDetail> get salesOrders {
    if (_search.trim().isEmpty) return List.unmodifiable(_orders);
    final q = _search.toLowerCase();
    return _orders
        .where((o) =>
            o.code.toLowerCase().contains(q) ||
            o.customerName.toLowerCase().contains(q))
        .toList();
  }

  void updateSession(AuthSession session) {
    _session = session;
    _harvestable = [];
    _inventory = [];
    _harvests = [];
    _orders = [];
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
      final farmId = _session.selectedFarm.id;
      final results = await Future.wait([
        _api.fetchHarvestVouchers(_session.token, farmingAreaId: farmId),
        _api.fetchHarvestOverview(_session.token, farmingAreaId: farmId),
        _api.fetchSalesOrders(_session.token, farmingAreaId: farmId),
        _api.fetchSalesOrderOverview(_session.token, farmingAreaId: farmId),
        _api.fetchSalesInventory(_session.token, farmingAreaId: farmId),
      ]);
      final farmCrabs = await _api.fetchFarmCrabs(_session.token, farmId);

      final vouchers = results[0] as List<Map<String, dynamic>>;
      final harvestOverview = results[1] as Map<String, dynamic>;
      final sales = results[2] as List<Map<String, dynamic>>;
      final salesOverview = results[3] as Map<String, dynamic>;
      final inventory = results[4] as List<Map<String, dynamic>>;
      final crabs = farmCrabs;

      _harvests = vouchers.map(_voucherToSlip).toList();
      _orders = sales.map(_orderFromJson).toList();
      _inventory = inventory.map(_inventoryFromJson).toList();
      _harvestable = crabs.crabs
          .where((c) {
            final s = c.status.toLowerCase();
            return s != 'dead' &&
                s != 'harvested' &&
                s != 'sold' &&
                s != 'missing';
          })
          .map(
            (c) => HarvestableCrab(
              id: c.id,
              code: c.crabCode.isEmpty ? c.id : c.crabCode,
              boxCode: c.boxCode,
              weightG: (c.weight ?? 0).round(),
              condition: _conditionLabel(c.status, c.healthStatus),
              areaName: c.areaName.isEmpty ? c.areaCode : c.areaName,
              rowName: c.rowName.isEmpty ? c.rowCode : c.rowName,
              lotCode: c.batchCode,
            ),
          )
          .toList();

      _harvestKpi = HarvestKpi(
        harvestable: _num(harvestOverview, const [
              'harvestableCount',
              'HarvestableCount',
            ])?.toInt() ??
            _harvestable.length,
        harvestedToday: _num(harvestOverview, const [
              'harvestedToday',
              'HarvestedToday',
            ])?.toInt() ??
            0,
        waitingSale: _num(harvestOverview, const [
              'waitingSale',
              'WaitingSale',
            ])?.toInt() ??
            _inventory.length,
        totalWeightKg: _num(harvestOverview, const [
              'totalHarvestWeightKg',
              'TotalHarvestWeightKg',
            ])?.toDouble() ??
            _inventory.fold<double>(0, (s, c) => s + c.weightG / 1000),
      );
      _salesKpi = SalesKpi(
        revenueTodayVnd: _num(salesOverview, const [
              'revenueToday',
              'RevenueToday',
            ])?.toInt() ??
            0,
        soldToday: _num(salesOverview, const [
              'soldToday',
              'SoldToday',
            ])?.toInt() ??
            0,
        inventory: _num(salesOverview, const [
              'inventoryCount',
              'InventoryCount',
            ])?.toInt() ??
            _inventory.length,
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
      notes: note,
      quantity: quantity,
      totalWeightKg: totalWeightKg,
      farmingAreaId: _session.selectedFarm.id,
      performedByName: performedBy,
    );
    await load();
  }

  Future<void> createHarvestFromCrabs({
    required DateTime harvestDate,
    required String performedBy,
    String? note,
    required List<HarvestableCrab> crabs,
    required Map<String, String> grades,
    required Map<String, String> conditions,
    required Map<String, int> weights,
    Map<String, String> results = const {},
    List<String> photoUrls = const [],
  }) async {
    if (crabs.isEmpty) throw CloudApiException('Chọn ít nhất một con cua');
    await _api.createHarvestVoucher(
      _session.token,
      harvestDate: harvestDate,
      notes: note,
      quantity: crabs.length,
      totalWeightKg:
          crabs.fold<double>(0, (s, c) => s + (weights[c.id] ?? c.weightG) / 1000),
      farmingAreaId: _session.selectedFarm.id,
      performedByName: performedBy,
      photoUrls: photoUrls,
      lines: [
        for (final c in crabs)
          {
            'crabId': c.id,
            'weightGram': weights[c.id] ?? c.weightG,
            'grade': grades[c.id] ?? 'A',
            'isSoftshell': false,
            'conditionLabel': conditions[c.id] ?? c.condition,
            'result': results[c.id] ?? 'passed',
          },
      ],
    );
    await load();
  }

  Future<void> createSaleOrder({
    required DateTime orderDate,
    required String customerName,
    String? customerPhone,
    required String paymentStatus,
    required String sellerName,
    required List<InventoryCrab> crabs,
    required int unitPricePerKg,
  }) async {
    if (crabs.isEmpty) throw CloudApiException('Chọn ít nhất một con cua tồn kho');
    if (customerName.trim().isEmpty) {
      throw CloudApiException('Nhập tên khách hàng');
    }
    await _api.createSalesOrder(
      _session.token,
      orderDate: orderDate,
      customerName: customerName.trim(),
      customerPhone: customerPhone?.trim().isEmpty == true
          ? null
          : customerPhone?.trim(),
      paymentStatus: paymentStatus,
      sellerName: sellerName,
      farmingAreaId: _session.selectedFarm.id,
      lines: [
        for (final c in crabs)
          {
            'crabId': c.id,
            'unitPricePerKg': unitPricePerKg,
            'weightGram': c.weightG,
            'grade': c.grade,
          },
      ],
    );
    await load();
  }

  HarvestSlipDetail _voucherToSlip(Map<String, dynamic> json) {
    final at = DateTime.tryParse(
          (json['harvestDate'] ?? json['HarvestDate'] ?? '').toString(),
        ) ??
        DateTime.now();
    final rawLines = json['lines'] ?? json['Lines'];
    final lines = <HarvestLineItem>[];
    if (rawLines is List) {
      for (final row in rawLines) {
        if (row is! Map) continue;
        final m = Map<String, dynamic>.from(row);
        final photos = m['photoUrls'] ?? m['PhotoUrls'];
        lines.add(
          HarvestLineItem(
            crabId: (m['crabId'] ?? m['CrabId'])?.toString(),
            crabCode: (m['crabCode'] ?? m['CrabCode'] ?? '').toString(),
            boxCode: (m['boxCode'] ?? m['BoxCode'] ?? '').toString(),
            weightG:
                (m['weightGram'] ?? m['WeightGram'] as num?)?.toInt() ?? 0,
            grade: (m['grade'] ?? m['Grade'] ?? '').toString(),
            condition:
                (m['conditionLabel'] ?? m['ConditionLabel'] ?? '').toString(),
            photoCount: photos is List ? photos.length : 0,
            areaName: (m['areaName'] ?? m['AreaName'] ?? '').toString(),
            rowName: (m['rowName'] ?? m['RowName'] ?? '').toString(),
            lotCode: (m['lotCode'] ?? m['LotCode'] ?? '').toString(),
            result: (m['result'] ?? m['Result'] ?? 'passed').toString(),
          ),
        );
      }
    }
    return HarvestSlipDetail(
      id: (json['id'] ?? json['Id']).toString(),
      code: (json['voucherCode'] ?? json['VoucherCode'] ?? '').toString(),
      harvestDate: formatHarvestDateTime(at),
      batchId: '',
      area: (json['areaName'] ?? json['AreaName'] ?? _session.selectedFarm.name)
          .toString(),
      quantity:
          (json['totalQuantity'] ?? json['TotalQuantity'] as num?)?.toInt() ??
              lines.length,
      totalWeightKg:
          (json['totalWeightKg'] ?? json['TotalWeightKg'] as num?)?.toDouble() ??
              0,
      performedBy:
          (json['performedByName'] ?? json['PerformedByName'] ?? '').toString(),
      note: (json['notes'] ?? json['Notes'])?.toString(),
      status: (json['status'] ?? json['Status'] ?? '').toString(),
      lines: lines,
      passedCount:
          (json['passedCount'] ?? json['PassedCount'] as num?)?.toInt() ??
              lines.where((l) => l.passed).length,
      failedCount:
          (json['failedCount'] ?? json['FailedCount'] as num?)?.toInt() ??
              lines.where((l) => !l.passed).length,
      averageWeightG: (json['averageWeightGram'] ??
                  json['AverageWeightGram'] as num?)
              ?.toDouble() ??
          (lines.isEmpty
              ? 0
              : lines.fold<int>(0, (s, l) => s + l.weightG) / lines.length),
      photoUrls: [
        for (final p in (json['photoUrls'] ?? json['PhotoUrls'] as List? ?? const []))
          p.toString(),
      ],
    );
  }

  SalesOrderDetail _orderFromJson(Map<String, dynamic> json) {
    final at = DateTime.tryParse(
          (json['orderDate'] ?? json['OrderDate'] ?? '').toString(),
        ) ??
        DateTime.now();
    final rawLines = json['lines'] ?? json['Lines'];
    final lines = <SalesOrderLineItem>[];
    if (rawLines is List) {
      for (final row in rawLines) {
        if (row is! Map) continue;
        final m = Map<String, dynamic>.from(row);
        lines.add(
          SalesOrderLineItem(
            crabCode: (m['crabCode'] ?? m['CrabCode'] ?? '').toString(),
            quantity: (m['quantity'] ?? m['Quantity'] as num?)?.toInt() ?? 1,
            weightG:
                (m['weightGram'] ?? m['WeightGram'] as num?)?.toInt() ?? 0,
            unitPricePerKg:
                (m['unitPricePerKg'] ?? m['UnitPricePerKg'] as num?)?.toInt() ??
                    0,
            totalVnd:
                (m['totalAmount'] ?? m['TotalAmount'] as num?)?.toInt() ?? 0,
          ),
        );
      }
    }
    return SalesOrderDetail(
      id: (json['id'] ?? json['Id']).toString(),
      code: (json['orderCode'] ?? json['OrderCode'] ?? '').toString(),
      orderDate: at,
      customerName:
          (json['customerName'] ?? json['CustomerName'] ?? '').toString(),
      customerPhone:
          (json['customerPhone'] ?? json['CustomerPhone'] ?? '').toString(),
      sellerName: (json['sellerName'] ?? json['SellerName'] ?? '').toString(),
      paymentStatus:
          (json['paymentStatus'] ?? json['PaymentStatus'] ?? '').toString(),
      crabCount: (json['crabCount'] ?? json['CrabCount'] as num?)?.toInt() ??
          lines.length,
      revenueVnd:
          (json['totalAmount'] ?? json['TotalAmount'] as num?)?.toInt() ?? 0,
      lines: lines,
    );
  }

  InventoryCrab _inventoryFromJson(Map<String, dynamic> json) {
    return InventoryCrab(
      id: (json['id'] ?? json['Id']).toString(),
      code: (json['code'] ?? json['Code'] ?? '').toString(),
      boxCode: (json['boxCode'] ?? json['BoxCode'] ?? '').toString(),
      weightG: (json['weightGram'] ?? json['WeightGram'] as num?)?.toInt() ?? 0,
      grade: (json['grade'] ?? json['Grade'] ?? 'A').toString(),
      harvestedAt: DateTime.tryParse(
        (json['harvestedAt'] ?? json['HarvestedAt'] ?? '').toString(),
      ),
    );
  }

  num? _num(Map<String, dynamic> json, List<String> keys) {
    for (final k in keys) {
      final v = json[k];
      if (v is num) return v;
    }
    return null;
  }

  String _conditionLabel(String status, String? health) {
    final s = status.toLowerCase();
    if (s.contains('molt')) return 'Đang lột';
    if (s.contains('soft')) return 'Cua mềm';
    if ((health ?? '').toLowerCase().contains('tốt') ||
        (health ?? '').toLowerCase().contains('good')) {
      return 'Tốt';
    }
    return 'Tốt';
  }
}
