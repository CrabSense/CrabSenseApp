import 'package:flutter/foundation.dart';

import '../models/auth_models.dart';
import '../models/harvest_sales.dart';
import '../models/production_models.dart';
import 'cloud_api_client.dart';

class HarvestAreaOption {
  const HarvestAreaOption({required this.id, required this.label});
  final String id;
  final String label;
}

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
    softshellWaiting: 0,
    harvestedToday: 0,
    waitingSale: 0,
    totalWeightKg: 0,
  );
  SalesKpi _salesKpi = const SalesKpi(
    revenueTodayVnd: 0,
    soldToday: 0,
    inventory: 0,
  );
  List<Customer> _customers = [];
  String _search = '';
  String? _areaFilterId;
  HarvestUiStatus? _statusFilter;
  HarvestProductType _productFilter = HarvestProductType.all;
  HarvestTimeRange _timeRange = HarvestTimeRange.d7;
  HarvestSlipSort _sort = HarvestSlipSort.newest;
  int _page = 0;
  int _pageSize = 10;
  bool _readySoftshellOnly = false;
  bool _completedTodayOnly = false;
  String _salesSearch = '';
  SalesOrderUiStatus? _salesStatusFilter;
  SalesPaymentUi? _salesPaymentFilter;
  String? _salesCustomer;
  HarvestProductType _salesProductFilter = HarvestProductType.all;
  HarvestTimeRange _salesTimeRange = HarvestTimeRange.d7;
  SalesOrderSort _salesSort = SalesOrderSort.newest;
  int _salesPage = 0;
  int _salesPageSize = 10;
  bool _salesTodayOnly = false;
  bool _salesCompletedOnly = false;
  bool _salesUnpaidOnly = false;
  bool loading = false;
  bool harvestsLoading = false;
  bool readyLoading = false;
  bool salesLoading = false;
  String? error;
  String? harvestsError;
  String? readyError;
  String? salesError;

  String get performerName => _session.user.displayName;
  String get areaCode => _session.selectedFarm.code;
  String get areaLabel {
    final code = areaCode.trim();
    final name = areaName.trim();
    if (code.isNotEmpty && name.isNotEmpty && code != name) {
      return '$code — $name';
    }
    return name.isEmpty ? code : name;
  }

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

  String get nextSalePreview {
    var max = 0;
    for (final o in _orders) {
      final code = o.code.toUpperCase();
      if (!code.startsWith('SALE-')) continue;
      final n = int.tryParse(code.substring(5));
      if (n != null && n > max) max = n;
    }
    return 'SALE-${(max + 1).toString().padLeft(3, '0')}';
  }

  Future<String?> uploadPhoto(String path) =>
      _api.uploadOperationPhoto(
        _session.token,
        path,
        relatedEntityType: 'HarvestVouchers',
      );
  String get areaName => _session.selectedFarm.name;
  String get areaId => _session.selectedFarm.id;
  String get token => _session.token;

  HarvestKpi get harvestKpi => _harvestKpi;
  SalesKpi get salesKpi => _salesKpi;
  List<HarvestableCrab> get harvestableCrabs => List.unmodifiable(_harvestable);
  List<HarvestableCrab> get softshellHarvestable =>
      _harvestable.where((c) => c.readyForSoftshellExport).toList();
  List<InventoryCrab> get inventory => List.unmodifiable(_inventory);

  String get search => _search;
  String? get areaFilterId => _areaFilterId;
  HarvestUiStatus? get statusFilter => _statusFilter;
  HarvestProductType get productFilter => _productFilter;
  HarvestTimeRange get timeRange => _timeRange;
  HarvestSlipSort get sort => _sort;
  int get page => _page;
  int get pageSize => _pageSize;
  bool get readySoftshellOnly => _readySoftshellOnly;
  bool get completedTodayOnly => _completedTodayOnly;

  List<HarvestAreaOption> get areaOptions {
    final map = <String, String>{
      if (areaId.isNotEmpty) areaId: areaName,
    };
    for (final h in _harvests) {
      final id = (h.farmingAreaId ?? '').trim();
      if (id.isEmpty) continue;
      map.putIfAbsent(id, () => h.area.isEmpty ? h.areaCode : h.area);
    }
    for (final c in _harvestable) {
      if (c.areaId.isEmpty) continue;
      map.putIfAbsent(c.areaId, () => c.areaName.isEmpty ? c.areaId : c.areaName);
    }
    return [
      for (final e in map.entries) HarvestAreaOption(id: e.key, label: e.value),
    ];
  }

  List<HarvestableCrab> get readyCrabs {
    var list = _harvestable.toList();
    if (_readySoftshellOnly) {
      list = list.where((c) => c.readyForSoftshellExport).toList();
    }
    if (_areaFilterId != null && _areaFilterId!.isNotEmpty) {
      list = list.where((c) => c.areaId == _areaFilterId).toList();
    }
    if (_search.trim().isNotEmpty) {
      final q = _search.trim().toLowerCase();
      list = list.where((c) => _crabMatches(c, q)).toList();
    }
    return list;
  }

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
  List<Customer> get customers => List.unmodifiable(_customers);
  String get salesSearch => _salesSearch;
  SalesOrderUiStatus? get salesStatusFilter => _salesStatusFilter;
  SalesPaymentUi? get salesPaymentFilter => _salesPaymentFilter;
  String? get salesCustomer => _salesCustomer;
  HarvestProductType get salesProductFilter => _salesProductFilter;
  HarvestTimeRange get salesTimeRange => _salesTimeRange;
  SalesOrderSort get salesSort => _salesSort;
  int get salesPage => _salesPage;
  int get salesPageSize => _salesPageSize;

  List<InventoryCrab> get readyToSell {
    var list = _inventory.toList();
    if (_salesProductFilter == HarvestProductType.softshell) {
      list = list.where((c) => c.isSoftshell).toList();
    } else if (_salesProductFilter == HarvestProductType.meat) {
      list = list.where((c) => !c.isSoftshell).toList();
    }
    final q = _salesSearch.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((c) => _sellCrabMatches(c, q)).toList();
    }
    return list;
  }

  List<SalesOrderDetail> get filteredSalesOrders {
    var list = _orders.toList();
    final q = _salesSearch.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((o) => _saleMatches(o, q)).toList();
    }
    if (_salesStatusFilter != null) {
      list = list.where((o) => o.uiStatus == _salesStatusFilter).toList();
    }
    if (_salesPaymentFilter != null || _salesUnpaidOnly) {
      list = list.where((o) {
        if (_salesUnpaidOnly) {
          return o.paymentUi == SalesPaymentUi.unpaid ||
              o.paymentUi == SalesPaymentUi.partial;
        }
        return o.paymentUi == _salesPaymentFilter;
      }).toList();
    }
    if (_salesCustomer != null && _salesCustomer!.isNotEmpty) {
      list = list.where((o) => o.customerName == _salesCustomer).toList();
    }
    if (_salesProductFilter != HarvestProductType.all) {
      list = list.where((o) => o.productType == _salesProductFilter).toList();
    }
    if (_salesCompletedOnly) {
      list = list.where((o) => o.uiStatus == SalesOrderUiStatus.completed).toList();
    }
    if (_salesTodayOnly || _salesTimeRange == HarvestTimeRange.today) {
      list = list.where((o) => _isToday(o.orderDate)).toList();
    } else {
      final from = _fromDate(_salesTimeRange);
      if (from != null) {
        list = list.where((o) => !o.orderDate.isBefore(from)).toList();
      }
    }
    list.sort((a, b) {
      switch (_salesSort) {
        case SalesOrderSort.oldest:
          return a.orderDate.compareTo(b.orderDate);
        case SalesOrderSort.mostAmount:
          return b.revenueVnd.compareTo(a.revenueVnd);
        case SalesOrderSort.mostCrabs:
          return b.crabCount.compareTo(a.crabCount);
        case SalesOrderSort.newest:
          return b.orderDate.compareTo(a.orderDate);
      }
    });
    return list;
  }

  int get filteredSalesCount => filteredSalesOrders.length;

  int get salesTotalPages {
    final n = filteredSalesCount;
    if (n == 0) return 1;
    return (n / _salesPageSize).ceil();
  }

  List<SalesOrderDetail> get pagedSalesOrders {
    final all = filteredSalesOrders;
    if (all.isEmpty) return const [];
    final start = (_salesPage * _salesPageSize).clamp(0, all.length);
    final end = (start + _salesPageSize).clamp(0, all.length);
    return all.sublist(start, end);
  }

  List<String> get customerNames =>
      {for (final o in _orders) if (o.customerName.isNotEmpty) o.customerName}
          .toList()
        ..sort();
  List<HarvestSlip> get harvests => List.unmodifiable(_harvests);
  List<HarvestSlipDetail> get harvestSlips => filteredHarvests;

  List<HarvestSlipDetail> get filteredHarvests {
    var list = _harvests.toList();
    final q = _search.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((h) => _slipMatches(h, q)).toList();
    }
    if (_areaFilterId != null && _areaFilterId!.isNotEmpty) {
      list = list.where((h) => (h.farmingAreaId ?? '') == _areaFilterId).toList();
    }
    if (_statusFilter != null) {
      list = list.where((h) => h.uiStatus == _statusFilter).toList();
    }
    if (_productFilter != HarvestProductType.all) {
      list = list.where((h) => h.productType == _productFilter).toList();
    }
    if (_completedTodayOnly) {
      list = list.where((h) => h.isCompleted && _isToday(h.harvestedAt)).toList();
    } else {
      final from = _fromDate(_timeRange);
      if (from != null) {
        list = list
            .where((h) =>
                h.harvestedAt == null || !h.harvestedAt!.isBefore(from))
            .toList();
      }
    }
    list.sort((a, b) {
      switch (_sort) {
        case HarvestSlipSort.oldest:
          return (a.harvestedAt ?? DateTime(1970))
              .compareTo(b.harvestedAt ?? DateTime(1970));
        case HarvestSlipSort.mostCrabs:
          return b.quantity.compareTo(a.quantity);
        case HarvestSlipSort.mostWeight:
          return b.totalWeightKg.compareTo(a.totalWeightKg);
        case HarvestSlipSort.newest:
          return (b.harvestedAt ?? DateTime(1970))
              .compareTo(a.harvestedAt ?? DateTime(1970));
      }
    });
    return list;
  }

  int get filteredHarvestCount => filteredHarvests.length;

  int get totalPages {
    final n = filteredHarvestCount;
    if (n == 0) return 1;
    return (n / _pageSize).ceil();
  }

  List<HarvestSlipDetail> get pagedHarvests {
    final all = filteredHarvests;
    if (all.isEmpty) return const [];
    final start = (_page * _pageSize).clamp(0, all.length);
    final end = (start + _pageSize).clamp(0, all.length);
    return all.sublist(start, end);
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
            batchId: c.batchId,
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
          status: o.isCancelled
              ? SalesOrderStatus.cancelled
              : o.isPaid
                  ? SalesOrderStatus.paid
                  : SalesOrderStatus.newOrder,
          productType: 'Cua sống',
          batchId: '',
        ),
      )
      .toList();

  List<SalesOrderDetail> get allSalesOrders => List.unmodifiable(_orders);

  List<SalesOrderDetail> get salesOrders {
    if (_search.trim().isEmpty) return List.unmodifiable(_orders);
    final q = _search.toLowerCase();
    return _orders
        .where((o) =>
            o.code.toLowerCase().contains(q) ||
            o.customerName.toLowerCase().contains(q))
        .toList();
  }

  List<InventoryCrab> inventoryForSlip(HarvestSlipDetail slip) {
    final ids = {
      for (final l in slip.lines)
        if ((l.crabId ?? '').isNotEmpty) l.crabId!,
    };
    final codes = {
      for (final l in slip.lines)
        if (l.crabCode.isNotEmpty) l.crabCode.toLowerCase(),
    };
    final found = _inventory
        .where((c) => ids.contains(c.id) || codes.contains(c.code.toLowerCase()))
        .toList();
    if (found.isNotEmpty) return found;
    return [
      for (final l in slip.lines)
        InventoryCrab(
          id: l.crabId ?? l.crabCode,
          code: l.crabCode,
          boxCode: l.boxCode,
          weightG: l.weightG,
          grade: l.grade,
          crabType: l.crabType,
        ),
    ];
  }

  void updateSession(AuthSession session) {
    _session = session;
    _harvestable = [];
    _inventory = [];
    _harvests = [];
    _orders = [];
    _customers = [];
  }

  void setSearch(String v) {
    _search = v;
    _page = 0;
    notifyListeners();
  }

  void setAreaFilter(String? id) {
    _areaFilterId = id;
    _page = 0;
    notifyListeners();
  }

  void setStatusFilter(HarvestUiStatus? status) {
    _statusFilter = status;
    _completedTodayOnly = false;
    _page = 0;
    notifyListeners();
  }

  void setProductFilter(HarvestProductType type) {
    _productFilter = type;
    _readySoftshellOnly = type == HarvestProductType.softshell;
    _page = 0;
    notifyListeners();
  }

  void setTimeRange(HarvestTimeRange range) {
    _timeRange = range;
    _completedTodayOnly = range == HarvestTimeRange.today;
    _page = 0;
    notifyListeners();
  }

  void setSort(HarvestSlipSort sort) {
    _sort = sort;
    notifyListeners();
  }

  void setPage(int page) {
    _page = page.clamp(0, totalPages - 1);
    notifyListeners();
  }

  void setPageSize(int size) {
    _pageSize = size;
    _page = 0;
    notifyListeners();
  }

  void clearFilters() {
    _search = '';
    _areaFilterId = null;
    _statusFilter = null;
    _productFilter = HarvestProductType.all;
    _timeRange = HarvestTimeRange.d7;
    _sort = HarvestSlipSort.newest;
    _page = 0;
    _readySoftshellOnly = false;
    _completedTodayOnly = false;
    notifyListeners();
  }

  void setSalesSearch(String v) {
    _salesSearch = v;
    _salesPage = 0;
    notifyListeners();
  }

  void setSalesStatusFilter(SalesOrderUiStatus? status) {
    _salesStatusFilter = status;
    _salesCompletedOnly = false;
    _salesPage = 0;
    notifyListeners();
  }

  void setSalesPaymentFilter(SalesPaymentUi? status) {
    _salesPaymentFilter = status;
    _salesUnpaidOnly = false;
    _salesPage = 0;
    notifyListeners();
  }

  void setSalesCustomer(String? name) {
    _salesCustomer = name;
    _salesPage = 0;
    notifyListeners();
  }

  void setSalesProductFilter(HarvestProductType type) {
    _salesProductFilter = type;
    _salesPage = 0;
    notifyListeners();
  }

  void setSalesTimeRange(HarvestTimeRange range) {
    _salesTimeRange = range;
    _salesTodayOnly = range == HarvestTimeRange.today;
    _salesPage = 0;
    notifyListeners();
  }

  void setSalesSort(SalesOrderSort sort) {
    _salesSort = sort;
    notifyListeners();
  }

  void setSalesPage(int page) {
    _salesPage = page.clamp(0, salesTotalPages - 1);
    notifyListeners();
  }

  void setSalesPageSize(int size) {
    _salesPageSize = size;
    _salesPage = 0;
    notifyListeners();
  }

  void clearSalesFilters() {
    _salesSearch = '';
    _salesStatusFilter = null;
    _salesPaymentFilter = null;
    _salesCustomer = null;
    _salesProductFilter = HarvestProductType.all;
    _salesTimeRange = HarvestTimeRange.d7;
    _salesSort = SalesOrderSort.newest;
    _salesPage = 0;
    _salesTodayOnly = false;
    _salesCompletedOnly = false;
    _salesUnpaidOnly = false;
    notifyListeners();
  }

  void applySalesKpi(SalesKpiFocus focus) {
    _salesTodayOnly = false;
    _salesCompletedOnly = false;
    _salesUnpaidOnly = false;
    _salesStatusFilter = null;
    _salesPaymentFilter = null;
    switch (focus) {
      case SalesKpiFocus.waitingSale:
        break;
      case SalesKpiFocus.sold:
        _salesCompletedOnly = true;
        _salesStatusFilter = SalesOrderUiStatus.completed;
      case SalesKpiFocus.ordersToday:
        _salesTimeRange = HarvestTimeRange.today;
        _salesTodayOnly = true;
      case SalesKpiFocus.unpaid:
        _salesUnpaidOnly = true;
    }
    _salesPage = 0;
    notifyListeners();
  }

  void applyKpi(HarvestKpiFocus focus) {
    _readySoftshellOnly = false;
    _completedTodayOnly = false;
    _statusFilter = null;
    _productFilter = HarvestProductType.all;
    switch (focus) {
      case HarvestKpiFocus.harvestable:
        break;
      case HarvestKpiFocus.softshell:
        _productFilter = HarvestProductType.softshell;
        _readySoftshellOnly = true;
      case HarvestKpiFocus.harvestedToday:
        _timeRange = HarvestTimeRange.today;
        _completedTodayOnly = true;
        _statusFilter = null;
      case HarvestKpiFocus.waitingSale:
        _statusFilter = HarvestUiStatus.waitingSale;
    }
    _page = 0;
    notifyListeners();
  }

  Future<void> load() async {
    loading = true;
    harvestsLoading = true;
    readyLoading = true;
    error = null;
    harvestsError = null;
    readyError = null;
    notifyListeners();
    try {
      final farmId = _session.selectedFarm.id;
      await Future.wait([
        _loadHarvests(farmId),
        _loadSales(farmId),
        _loadReady(farmId),
      ]);
      error = harvestsError ?? readyError;
    } finally {
      loading = false;
      harvestsLoading = false;
      readyLoading = false;
      notifyListeners();
    }
  }

  Future<void> reloadHarvests() async {
    harvestsLoading = true;
    harvestsError = null;
    notifyListeners();
    try {
      await _loadHarvests(_session.selectedFarm.id);
    } finally {
      harvestsLoading = false;
      notifyListeners();
    }
  }

  Future<void> reloadReady() async {
    readyLoading = true;
    readyError = null;
    notifyListeners();
    try {
      await _loadReady(_session.selectedFarm.id);
    } finally {
      readyLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadHarvests(String farmId) async {
    try {
      final results = await Future.wait([
        _api.fetchHarvestVouchers(_session.token, farmingAreaId: farmId),
        _api.fetchHarvestOverview(_session.token, farmingAreaId: farmId),
        _api.fetchSalesInventory(_session.token, farmingAreaId: farmId),
      ]);
      final vouchers = results[0] as List<Map<String, dynamic>>;
      final harvestOverview = results[1] as Map<String, dynamic>;
      final inventory = results[2] as List<Map<String, dynamic>>;
      _inventory = inventory.map(_inventoryFromJson).toList();
      final invIds = _inventory.map((c) => c.id).toSet();
      _harvests = vouchers.map((j) => _voucherToSlip(j, invIds)).toList();
      _harvestKpi = HarvestKpi(
        harvestable: _num(harvestOverview, const [
              'harvestableCount',
              'HarvestableCount',
            ])?.toInt() ??
            _harvestable.length,
        softshellWaiting: _num(harvestOverview, const [
              'softshellWaiting',
              'SoftshellWaiting',
            ])?.toInt() ??
            _harvestable.where((c) => c.readyForSoftshellExport).length,
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
            0,
      );
      harvestsError = null;
    } on CloudApiException catch (e) {
      harvestsError = e.message;
    } catch (e) {
      harvestsError = '$e';
    }
  }

  Future<void> reloadSales() async {
    salesLoading = true;
    salesError = null;
    notifyListeners();
    try {
      await _loadSales(_session.selectedFarm.id);
    } finally {
      salesLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadSales(String farmId) async {
    salesLoading = true;
    try {
      final results = await Future.wait([
        _api.fetchSalesOrders(_session.token, farmingAreaId: farmId),
        _api.fetchSalesOrderOverview(_session.token, farmingAreaId: farmId),
        _api.fetchCustomers(_session.token),
      ]);
      _orders = (results[0] as List<Map<String, dynamic>>)
          .map(_orderFromJson)
          .toList();
      final salesOverview = results[1] as Map<String, dynamic>;
      _customers = (results[2] as List<Map<String, dynamic>>)
          .map(_customerFromJson)
          .toList();
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
        ordersToday: _num(salesOverview, const [
              'ordersToday',
              'OrdersToday',
            ])?.toInt() ??
            0,
        unpaidVnd: _num(salesOverview, const [
              'unpaidAmount',
              'UnpaidAmount',
            ])?.toInt() ??
            0,
        revenueTrendPercent: _num(salesOverview, const [
              'revenueChangePercent',
              'RevenueChangePercent',
            ])?.toDouble() ??
            0,
        soldTrend: _num(salesOverview, const [
              'soldChange',
              'SoldChange',
            ])?.toInt() ??
            0,
        unpaidOrdersTrend: _num(salesOverview, const [
              'unpaidOrdersChange',
              'UnpaidOrdersChange',
            ])?.toInt() ??
            0,
      );
      salesError = null;
    } on CloudApiException catch (e) {
      salesError = e.message;
    } catch (e) {
      salesError = '$e';
    } finally {
      salesLoading = false;
    }
  }

  Future<void> _loadReady(String farmId) async {
    try {
      final farmCrabs = await _api.fetchFarmCrabs(_session.token, farmId);
      final busy = _busyCrabIds();
      _harvestable = farmCrabs.crabs
          .where((c) {
            final s = c.status.toLowerCase();
            return s != 'dead' &&
                s != 'harvested' &&
                s != 'sold' &&
                s != 'missing';
          })
          .map((c) => _mapReadyCrab(c, busy.contains(c.id)))
          .toList();
      if (_harvestKpi.harvestable == 0 && _harvestable.isNotEmpty) {
        _harvestKpi = HarvestKpi(
          harvestable: _harvestable
              .where((c) => c.eligibility != HarvestEligibility.notEligible)
              .length,
          softshellWaiting: _harvestKpi.softshellWaiting != 0
              ? _harvestKpi.softshellWaiting
              : _harvestable.where((c) => c.readyForSoftshellExport).length,
          harvestedToday: _harvestKpi.harvestedToday,
          waitingSale: _harvestKpi.waitingSale,
          totalWeightKg: _harvestKpi.totalWeightKg,
        );
      }
      readyError = null;
    } on CloudApiException catch (e) {
      readyError = e.message;
    } catch (e) {
      readyError = '$e';
    }
  }

  Set<String> _busyCrabIds() {
    final ids = <String>{};
    for (final h in _harvests) {
      if (h.uiStatus == HarvestUiStatus.completed ||
          h.uiStatus == HarvestUiStatus.waitingSale ||
          h.uiStatus == HarvestUiStatus.transferred ||
          h.uiStatus == HarvestUiStatus.cancelled) {
        continue;
      }
      for (final l in h.lines) {
        final id = l.crabId;
        if (id != null && id.isNotEmpty) ids.add(id);
      }
    }
    return ids;
  }

  HarvestableCrab _mapReadyCrab(CrabManagementListItem c, bool busy) {
    return HarvestableCrab(
      id: c.id,
      code: c.crabCode.isEmpty ? c.id : c.crabCode,
      boxCode: c.boxCode,
      weightG: (c.weight ?? 0).round(),
      condition: _conditionLabel(c.status, c.healthStatus),
      areaId: c.areaId,
      areaName: c.areaName.isEmpty ? c.areaCode : c.areaName,
      rowName: c.rowName.isEmpty ? c.rowCode : c.rowName,
      lotCode: c.batchCode,
      isSoftshell: _isSoftshell(c.status, c.healthStatus, c.growthStage),
      boxId: c.boxId,
      batchId: c.batchId,
      widthMm: c.shellWidth,
      lengthMm: c.shellLength,
      gender: _genderLabel(c.gender),
      crabType: 'Cua biển',
      healthRaw: c.healthStatus ?? '',
      lastWeightAt: DateTime.tryParse(c.updatedAt ?? ''),
      eligibility: _eligibility(c),
      busyInSlip: busy,
      statusRaw: c.status,
    );
  }

  HarvestEligibility _eligibility(CrabManagementListItem c) {
    final s = c.status.toLowerCase();
    final h = (c.healthStatus ?? '').toLowerCase();
    final g = (c.growthStage ?? '').toLowerCase();
    if (s == 'dead' || s == 'harvested' || s == 'sold' || s == 'missing') {
      return HarvestEligibility.notEligible;
    }
    if (h.contains('problem') ||
        h.contains('sick') ||
        h.contains('dead') ||
        h.contains('yếu') ||
        h.contains('bệnh') ||
        h.contains('risk')) {
      return HarvestEligibility.notEligible;
    }
    if (s == 'quarantined' ||
        s == 'molting' ||
        h.contains('monitor') ||
        h.contains('premolt') ||
        h.contains('theo dõi') ||
        h.contains('watch') ||
        h.contains('molt')) {
      return HarvestEligibility.monitoring;
    }
    if (g.contains('harvest') ||
        h.contains('good') ||
        h.contains('healthy') ||
        h.contains('khỏe') ||
        h.contains('tốt') ||
        h.contains('normal') ||
        h.isEmpty) {
      return HarvestEligibility.eligible;
    }
    return HarvestEligibility.monitoring;
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

  Future<String> createHarvestFromCrabs({
    required DateTime harvestDate,
    required String performedBy,
    String? note,
    required List<HarvestableCrab> crabs,
    required Map<String, String> grades,
    required Map<String, String> conditions,
    required Map<String, int> weights,
    Map<String, String> results = const {},
    Map<String, bool> softshell = const {},
    List<String> photoUrls = const [],
    String status = 'InProgress',
  }) async {
    final isDraft = status.toLowerCase() == 'planned';
    if (!isDraft && crabs.isEmpty) {
      throw CloudApiException('Chọn ít nhất một con cua');
    }
    final preview = nextVoucherPreview;
    for (final c in crabs) {
      if (!c.canSelect) {
        throw CloudApiException(c.disableReason);
      }
    }
    final created = await _api.createHarvestVoucher(
      _session.token,
      harvestDate: harvestDate,
      notes: note,
      quantity: crabs.length,
      totalWeightKg: crabs.fold<double>(
        0,
        (s, c) => s + (weights[c.id] ?? 0) / 1000,
      ),
      farmingAreaId: _session.selectedFarm.id,
      performedByName: performedBy,
      photoUrls: photoUrls,
      status: status,
      lines: [
        for (final c in crabs)
          {
            'crabId': c.id,
            'weightGram': weights[c.id] ?? 0,
            'grade': grades[c.id] ?? 'A',
            'isSoftshell': softshell[c.id] ?? c.isSoftshell,
            'conditionLabel': conditions[c.id] ?? c.condition,
            'result': results[c.id] ?? 'passed',
          },
      ],
    );
    await load();
    final code = (created['voucherCode'] ??
            created['VoucherCode'] ??
            created['code'] ??
            created['Code'] ??
            '')
        .toString();
    return code.isEmpty ? preview : code;
  }

  Future<void> updateHarvestStatus(String id, String status) async {
    await _api.updateHarvestVoucherStatus(_session.token, id, status: status);
    await load();
  }

  Future<void> completeHarvest(String id) =>
      updateHarvestStatus(id, 'Completed');

  Future<void> startHarvest(String id) =>
      updateHarvestStatus(id, 'InProgress');

  Future<void> cancelHarvest(String id) =>
      updateHarvestStatus(id, 'Cancelled');

  Future<void> deleteHarvest(String id) async {
    await _api.deleteHarvestVoucher(_session.token, id);
    await load();
  }

  Future<Customer> upsertCustomer({
    required String name,
    String? phone,
    String? address,
    String? customerType,
  }) async {
    final created = await _api.upsertCustomer(
      _session.token,
      name: name,
      phone: phone,
      address: address,
      customerType: customerType,
    );
    final customer = _customerFromJson(created);
    final idx = _customers.indexWhere((c) => c.id == customer.id || c.name == customer.name);
    if (idx >= 0) {
      _customers[idx] = customer;
    } else {
      _customers = [..._customers, customer];
    }
    notifyListeners();
    return customer;
  }

  ({int orders, int crabs, int weightG, int revenue}) customerStats(Customer c) {
    final rows = _orders.where((o) =>
        (c.id.isNotEmpty && o.customerId == c.id) ||
        o.customerName.trim().toLowerCase() == c.name.trim().toLowerCase());
    var crabs = 0;
    var weightG = 0;
    var revenue = 0;
    var n = 0;
    for (final o in rows) {
      if (o.isCancelled) continue;
      n += 1;
      crabs += o.crabCount;
      weightG += (o.totalWeightKg * 1000).round();
      revenue += o.revenueVnd;
    }
    return (orders: n, crabs: crabs, weightG: weightG, revenue: revenue);
  }

  Future<String> createSaleOrder({
    required DateTime orderDate,
    required String customerName,
    String? customerPhone,
    String? customerAddress,
    required String paymentStatus,
    String? paymentMethod,
    String orderStatus = 'Completed',
    required String sellerName,
    String? notes,
    int discountAmount = 0,
    int shippingFee = 0,
    int paidAmount = 0,
    String deliveryStatus = 'pickup',
    String? customerType,
    required List<InventoryCrab> crabs,
    required Map<String, int> weights,
    required Map<String, String> grades,
    required Map<String, int> prices,
  }) async {
    final isDraft = orderStatus.toLowerCase() == 'draft';
    if (!isDraft && crabs.isEmpty) {
      throw CloudApiException('Chọn ít nhất một con cua tồn kho');
    }
    if (customerName.trim().isEmpty) {
      throw CloudApiException('Nhập tên khách hàng');
    }
    for (final c in crabs) {
      if (!c.canSelect) throw CloudApiException(c.disableReason);
    }
    final preview = nextSalePreview;
    final created = await _api.createSalesOrder(
      _session.token,
      orderDate: orderDate,
      customerName: customerName.trim(),
      customerPhone: customerPhone?.trim().isEmpty == true
          ? null
          : customerPhone?.trim(),
      customerAddress: customerAddress?.trim().isEmpty == true
          ? null
          : customerAddress?.trim(),
      paymentStatus: paymentStatus,
      paymentMethod: paymentMethod,
      orderStatus: orderStatus,
      sellerName: sellerName,
      farmingAreaId: _session.selectedFarm.id,
      notes: notes?.trim().isEmpty == true ? null : notes?.trim(),
      discountAmount: discountAmount,
      shippingFee: shippingFee,
      paidAmount: paidAmount,
      deliveryStatus: deliveryStatus,
      customerType: customerType,
      lines: [
        for (final c in crabs)
          {
            'crabId': c.id,
            'unitPricePerKg': prices[c.id] ?? 0,
            'weightGram': weights[c.id] ?? c.weightG,
            'grade': grades[c.id] ?? c.grade,
          },
      ],
    );
    await load();
    final code = (created['orderCode'] ??
            created['OrderCode'] ??
            created['code'] ??
            created['Code'] ??
            '')
        .toString();
    return code.isEmpty ? preview : code;
  }

  Future<void> completeSaleOrder(String id) async {
    await _api.completeSalesOrder(_session.token, id);
    await load();
  }

  Future<void> cancelSaleOrder(String id) async {
    await _api.cancelSalesOrder(_session.token, id);
    await load();
  }

  String exportCsv() {
    final buf = StringBuffer();
    buf.writeln(
      'Ma phieu,Thoi gian,Khu vuc,So cua,Tong KL (kg),Loai san pham,Phan loai,Nguoi thuc hien,Trang thai',
    );
    for (final h in filteredHarvests) {
      buf.writeln(
        [
          h.code,
          h.harvestDate,
          h.area,
          h.quantity,
          h.totalWeightKg.toStringAsFixed(2),
          h.productTypeLabel,
          h.classificationLabel,
          h.performedBy,
          h.statusLabel,
        ].map(_csv).join(','),
      );
    }
    return buf.toString();
  }

  String exportSalesCsv() {
    final buf = StringBuffer();
    buf.writeln(
      'Ma don,Ngay ban,Khach hang,So cua,Tong KL (kg),Tong tien,Thanh toan,Trang thai',
    );
    for (final o in filteredSalesOrders) {
      buf.writeln(
        [
          o.code,
          formatHarvestDateTime(o.orderDate),
          o.customerName,
          o.crabCount,
          o.totalWeightKg.toStringAsFixed(2),
          o.revenueVnd,
          o.paymentStatusLabel,
          o.orderStatusLabel,
        ].map(_csv).join(','),
      );
    }
    return buf.toString();
  }

  HarvestSlipDetail _voucherToSlip(
    Map<String, dynamic> json,
    Set<String> inventoryIds,
  ) {
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
            boxId: (m['boxId'] ?? m['BoxId'] ?? '').toString(),
            batchId: (m['batchId'] ?? m['BatchId'] ?? '').toString(),
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
            isSoftshell: m['isSoftshell'] == true ||
                m['IsSoftshell'] == true,
          ),
        );
      }
    }
    final rawStatus = (json['status'] ?? json['Status'] ?? '').toString();
    final stillInInv = lines.any(
      (l) => l.crabId != null && inventoryIds.contains(l.crabId),
    );
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
      status: rawStatus,
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
      harvestedAt: at,
      farmingAreaId:
          (json['farmingAreaId'] ?? json['FarmingAreaId'])?.toString(),
      areaCode: (json['areaCode'] ?? json['AreaCode'] ?? '').toString(),
      uiStatus: parseHarvestUiStatus(rawStatus, stillInInventory: stillInInv),
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
            crabId: (m['crabId'] ?? m['CrabId'])?.toString(),
            crabCode: (m['crabCode'] ?? m['CrabCode'] ?? '').toString(),
            crabType: (m['crabType'] ?? m['CrabType'] ?? '').toString(),
            grade: (m['grade'] ?? m['Grade'] ?? '').toString(),
            quantity: (m['quantity'] ?? m['Quantity'] as num?)?.toInt() ?? 1,
            weightG:
                (m['weightGram'] ?? m['WeightGram'] as num?)?.toInt() ?? 0,
            unitPricePerKg:
                (m['unitPricePerKg'] ?? m['UnitPricePerKg'] as num?)?.toInt() ??
                    0,
            totalVnd:
                (m['totalAmount'] ?? m['TotalAmount'] as num?)?.toInt() ?? 0,
            harvestCode:
                (m['harvestSlipCode'] ?? m['HarvestSlipCode'] ?? '').toString(),
            boxCode: (m['boxCode'] ?? m['BoxCode'] ?? '').toString(),
            lotCode: (m['lotCode'] ?? m['LotCode'] ?? '').toString(),
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
      customerAddress:
          (json['customerAddress'] ?? json['CustomerAddress'] ?? '').toString(),
      sellerName: (json['sellerName'] ?? json['SellerName'] ?? '').toString(),
      orderStatus: (json['status'] ?? json['Status'] ?? 'Completed').toString(),
      paymentStatus:
          (json['paymentStatus'] ?? json['PaymentStatus'] ?? '').toString(),
      paymentMethod:
          (json['paymentMethod'] ?? json['PaymentMethod'] ?? '').toString(),
      deliveryStatus:
          (json['deliveryStatus'] ?? json['DeliveryStatus'] ?? 'pickup')
              .toString(),
      crabCount: (json['crabCount'] ?? json['CrabCount'] as num?)?.toInt() ??
          lines.length,
      subtotalVnd:
          (json['subtotalAmount'] ?? json['SubtotalAmount'] as num?)?.toInt() ??
              (json['totalAmount'] ?? json['TotalAmount'] as num?)?.toInt() ??
              0,
      discountVnd:
          (json['discountAmount'] ?? json['DiscountAmount'] as num?)?.toInt() ??
              0,
      shippingVnd:
          (json['shippingFee'] ?? json['ShippingFee'] as num?)?.toInt() ?? 0,
      revenueVnd:
          (json['totalAmount'] ?? json['TotalAmount'] as num?)?.toInt() ?? 0,
      paidVnd: (json['paidAmount'] ?? json['PaidAmount'] as num?)?.toInt() ?? 0,
      totalWeightKg: (json['totalWeightKg'] ?? json['TotalWeightKg'] as num?)
              ?.toDouble() ??
          lines.fold<double>(0, (s, l) => s + l.weightG / 1000),
      notes: (json['notes'] ?? json['Notes'])?.toString(),
      lines: lines,
      customerType:
          (json['customerType'] ?? json['CustomerType'] ?? '').toString(),
      customerId:
          (json['customerId'] ?? json['CustomerId'] ?? '').toString(),
    );
  }

  InventoryCrab _inventoryFromJson(Map<String, dynamic> json) {
    final el = (json['saleEligibility'] ?? json['SaleEligibility'] ?? 'READY')
        .toString()
        .toUpperCase();
    return InventoryCrab(
      id: (json['id'] ?? json['Id']).toString(),
      code: (json['code'] ?? json['Code'] ?? '').toString(),
      boxCode: (json['boxCode'] ?? json['BoxCode'] ?? '').toString(),
      weightG: (json['weightGram'] ?? json['WeightGram'] as num?)?.toInt() ?? 0,
      grade: (json['grade'] ?? json['Grade'] ?? 'A').toString(),
      crabType: (json['crabType'] ?? json['CrabType'] ?? '').toString(),
      harvestedAt: DateTime.tryParse(
        (json['harvestedAt'] ?? json['HarvestedAt'] ?? '').toString(),
      ),
      harvestCode:
          (json['harvestSlipCode'] ?? json['HarvestSlipCode'] ?? '').toString(),
      lotCode: (json['lotCode'] ?? json['LotCode'] ?? '').toString(),
      isSoftshell: json['isSoftshell'] == true || json['IsSoftshell'] == true,
      eligibility: el.contains('REVIEW')
          ? SaleEligibility.review
          : el.contains('NOT')
              ? SaleEligibility.notAvailable
              : SaleEligibility.ready,
    );
  }

  Customer _customerFromJson(Map<String, dynamic> json) {
    final type = (json['customerType'] ?? json['CustomerType'] ?? '').toString();
    return Customer(
      id: (json['id'] ?? json['Id']).toString(),
      code: (json['id'] ?? json['Id'] ?? '').toString(),
      name: (json['name'] ?? json['Name'] ?? '').toString(),
      phone: (json['phone'] ?? json['Phone'] ?? '').toString(),
      address: (json['address'] ?? json['Address'] ?? '').toString(),
      typeLabel: type,
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
    final t = '${status.toLowerCase()} ${(health ?? '').toLowerCase()}';
    if (_isSoftshell(status, health, null)) return 'Cua lột';
    if (t.contains('molt') || t.contains('lột')) return 'Đang lột';
    if (t.contains('monitor') || t.contains('theo dõi') || t.contains('watch')) {
      return 'Cần theo dõi';
    }
    if (t.contains('problem') || t.contains('risk') || t.contains('yếu')) {
      return 'Cần theo dõi';
    }
    if (t.contains('tốt') || t.contains('good') || t.contains('healthy') || t.contains('khỏe')) {
      return 'Khỏe mạnh';
    }
    return 'Khỏe mạnh';
  }

  bool _isSoftshell(String status, String? health, String? growth) {
    final t =
        '${status.toLowerCase()} ${(health ?? '').toLowerCase()} ${(growth ?? '').toLowerCase()}';
    return t.contains('soft') ||
        t.contains('postmolt') ||
        t.contains('cua lột') ||
        t.contains('lột mềm');
  }

  String _genderLabel(String raw) {
    final t = raw.toLowerCase();
    if (t.contains('female') || t.contains('cái') || t == 'f') return 'Cái';
    if (t.contains('male') || t.contains('đực') || t == 'm') return 'Đực';
    return '';
  }

  bool _crabMatches(HarvestableCrab c, String q) {
    return c.code.toLowerCase().contains(q) ||
        c.boxCode.toLowerCase().contains(q) ||
        c.lotCode.toLowerCase().contains(q) ||
        c.areaName.toLowerCase().contains(q) ||
        c.areaId.toLowerCase().contains(q) ||
        c.batchId.toLowerCase().contains(q);
  }

  bool _sellCrabMatches(InventoryCrab c, String q) {
    return c.code.toLowerCase().contains(q) ||
        c.boxCode.toLowerCase().contains(q) ||
        c.harvestCode.toLowerCase().contains(q) ||
        c.lotCode.toLowerCase().contains(q);
  }

  bool _saleMatches(SalesOrderDetail o, String q) {
    if (o.code.toLowerCase().contains(q) ||
        o.customerName.toLowerCase().contains(q) ||
        o.customerPhone.toLowerCase().contains(q)) {
      return true;
    }
    return o.lines.any((l) =>
        l.crabCode.toLowerCase().contains(q) ||
        l.harvestCode.toLowerCase().contains(q) ||
        l.boxCode.toLowerCase().contains(q) ||
        l.lotCode.toLowerCase().contains(q));
  }

  bool _slipMatches(HarvestSlipDetail h, String q) {
    if (h.code.toLowerCase().contains(q) ||
        h.area.toLowerCase().contains(q) ||
        h.areaCode.toLowerCase().contains(q) ||
        (h.farmingAreaId ?? '').toLowerCase().contains(q) ||
        h.performedBy.toLowerCase().contains(q)) {
      return true;
    }
    return h.lines.any((l) =>
        l.crabCode.toLowerCase().contains(q) ||
        l.boxCode.toLowerCase().contains(q) ||
        l.lotCode.toLowerCase().contains(q) ||
        (l.crabId ?? '').toLowerCase().contains(q));
  }

  DateTime? _fromDate(HarvestTimeRange range) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return switch (range) {
      HarvestTimeRange.today => today,
      HarvestTimeRange.d7 => today.subtract(const Duration(days: 7)),
      HarvestTimeRange.d30 => today.subtract(const Duration(days: 30)),
      HarvestTimeRange.all => null,
    };
  }

  bool _isToday(DateTime? at) {
    if (at == null) return false;
    final n = DateTime.now();
    final l = at.isUtc ? at.toLocal() : at;
    return l.year == n.year && l.month == n.month && l.day == n.day;
  }

  String _csv(Object v) {
    final s = '$v';
    if (s.contains(',') || s.contains('"') || s.contains('\n')) {
      return '"${s.replaceAll('"', '""')}"';
    }
    return s;
  }
}

enum HarvestKpiFocus { harvestable, softshell, harvestedToday, waitingSale }
