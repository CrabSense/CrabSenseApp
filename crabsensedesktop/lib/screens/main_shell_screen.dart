import 'package:flutter/material.dart';

import '../models/crab_batch.dart';
import '../models/crab_individual.dart';
import '../models/farm_layout.dart';
import '../models/production_models.dart';
import '../models/row_list_item.dart';
import '../navigation/app_route.dart';
import '../services/batch_service.dart';
import '../services/crab_service.dart';
import '../widgets/dashboard/app_sidebar.dart';
import '../widgets/dashboard/wave_background.dart';
import '../widgets/shared/app_footer.dart';
import '../widgets/shared/app_top_bar.dart';
import 'batch/batch_detail_page.dart';
import 'batch/batch_list_page.dart';
import 'crab/crab_detail_page.dart';
import 'crab/crab_list_page.dart';
import 'crab/crab_management_page.dart';
import 'crab/crab_management_detail_page.dart';
import 'lot/crab_lot_inbound_page.dart';
import 'lot/crab_lot_inbound_detail_page.dart';
import '../services/crab_lot_inbound_service.dart';
import 'dashboard_screen.dart';
import 'farm/farm_layout_page.dart';
import '../services/farm_layout_service.dart';
import 'area/area_detail_page.dart';
import 'area/area_management_page.dart';
import 'row/row_management_page.dart';
import 'box/box_management_page.dart';
import '../services/area_management_service.dart';
import '../services/row_management_service.dart';
import '../services/box_management_service.dart';
import 'health/health_monitoring_page.dart';
import 'environment/realtime_monitor_page.dart';
import 'environment/water_analysis_page.dart';
import '../services/water_analysis_service.dart';
import '../models/box_list_item.dart';
import 'box/box_detail_page.dart';
import 'devices/ras_control_page.dart';
import 'devices/controller_management_page.dart';
import '../services/controller_service.dart';
import 'alerts/alert_system_page.dart';
import 'logs/farm_activity_log_page.dart';
import 'harvest/harvest_sales_page.dart';
import 'ai/ai_insight_page.dart';
import '../services/water_quality_service.dart';
import '../services/iot_device_service.dart';
import '../services/area_environment_service.dart';
import '../services/ras_flow_service.dart';
import '../services/camera_device_service.dart';
import '../services/gateway_service.dart';
import '../services/crab_profile_service.dart';
import '../services/alert_service.dart';
import '../services/farm_management_service.dart';
import '../services/production_management_service.dart';
import '../services/farm_log_service.dart';
import '../services/harvest_sales_service.dart';
import '../services/ai_assistant_service.dart';
import '../models/auth_models.dart';
import '../services/cloud_api_client.dart';
import '../services/cloud_auth_service.dart';
import '../services/connectivity_link_service.dart';
import '../services/farm_dashboard_service.dart';
import 'login_screen.dart';

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({
    super.key,
    required this.session,
  });

  final AuthSession session;

  String get email => session.user.email;

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  late AuthSession _session;
  final _cloudApi = CloudApiClient();
  final _batchService = BatchService();
  late final CrabService _crabService;
  late final CrabLotInboundService _inboundLotService;
  late final FarmDashboardService _farmDashboardService;
  late final WaterQualityService _waterQualityService;
  WaterAnalysisService? _waterAnalysisServiceInstance;
  late final FarmManagementService _farmManagementService;
  late final ProductionManagementService _productionManagementService;
  late final AreaManagementService _areaManagementService;
  late final RowManagementService _rowManagementService;
  late final BoxManagementService _boxManagementService;
  late final IotDeviceService _iotDeviceService;
  late final ControllerService _controllerService;
  late final CameraDeviceService _cameraDeviceService;
  AreaEnvironmentService? _areaEnvironmentServiceInstance;
  RasFlowService? _rasFlowServiceInstance;
  FarmLayoutService? _farmLayoutServiceInstance;

  WaterAnalysisService get _waterAnalysisService =>
      _waterAnalysisServiceInstance ??=
          WaterAnalysisService(session: _session);

  AreaEnvironmentService get _areaEnvironmentService =>
      _areaEnvironmentServiceInstance ??=
          AreaEnvironmentService(session: _session);

  RasFlowService get _rasFlowService =>
      _rasFlowServiceInstance ??= RasFlowService(session: _session);

  FarmLayoutService get _farmLayoutService =>
      _farmLayoutServiceInstance ??= FarmLayoutService(session: _session);
  late final GatewayService _gatewayService;
  late final CrabProfileService _crabProfileService;
  late final AlertService _alertService;
  late final FarmLogService _farmLogService;
  late final HarvestSalesService _harvestSalesService;
  late final AiAssistantService _aiAssistantService;
  late final ConnectivityLinkService _connectivityLinkService;
  AppRoute _route = AppRoute.dashboard;
  CrabBatch? _selectedBatch;
  String? _selectedCrabId;
  String? _selectedLotId;
  String? _selectedAreaId;
  BoxListItem? _selectedBoxItem;
  AppRoute _boxDetailBack = AppRoute.boxManagement;

  @override
  void initState() {
    super.initState();
    _session = widget.session;
    _crabService = CrabService(session: _session);
    _inboundLotService = CrabLotInboundService(session: _session);
    _farmDashboardService = FarmDashboardService(session: _session);
    _connectivityLinkService =
        ConnectivityLinkService(session: _session);
    _waterQualityService = WaterQualityService(session: _session);
    _waterAnalysisServiceInstance = WaterAnalysisService(session: _session);
    _farmManagementService = FarmManagementService(session: _session);
    _productionManagementService =
        ProductionManagementService(session: _session);
    _areaManagementService = AreaManagementService(session: _session);
    _rowManagementService = RowManagementService(session: _session);
    _boxManagementService = BoxManagementService(session: _session);
    _iotDeviceService = IotDeviceService(session: _session);
    _controllerService = ControllerService(session: _session);
    _alertService = AlertService(session: _session);
    _farmLogService = FarmLogService(session: _session);
    _harvestSalesService = HarvestSalesService(session: _session);
    _aiAssistantService = AiAssistantService(session: _session);
    _cameraDeviceService = CameraDeviceService(session: _session);
    _areaEnvironmentServiceInstance =
        AreaEnvironmentService(session: _session);
    _rasFlowServiceInstance = RasFlowService(session: _session);
    _farmLayoutServiceInstance = FarmLayoutService(session: _session);
    _gatewayService = GatewayService(session: _session);
    _alertService.load();
    _crabProfileService = CrabProfileService(session: _session);
    _connectivityLinkService.addListener(_onConnectivityUpdate);
    _connectivityLinkService.refreshCloud();
    _gatewayService.registerHeartbeat();
    if (_session.isOrgAdmin || _session.isFarmOwner) {
      _refreshAdminFarms();
    }
  }

  void _applySessionToServices() {
    _connectivityLinkService.updateSession(_session);
    _waterQualityService.updateSession(_session);
    _waterAnalysisServiceInstance?.updateSession(_session);
    _farmManagementService.updateSession(_session);
    _productionManagementService.updateSession(_session);
    _areaManagementService.updateSession(_session);
    _rowManagementService.updateSession(_session);
    _boxManagementService.updateSession(_session);
    _iotDeviceService.updateSession(_session);
    _controllerService.updateSession(_session);
    _cameraDeviceService.updateSession(_session);
    _areaEnvironmentServiceInstance?.updateSession(_session);
    _rasFlowServiceInstance?.updateSession(_session);
    _farmLayoutServiceInstance?.updateSession(_session);
    _gatewayService.updateSession(_session);
    _alertService.updateSession(_session);
    _farmLogService.updateSession(_session);
    _harvestSalesService.updateSession(_session);
    _aiAssistantService.updateSession(_session);
    _gatewayService.registerHeartbeat();
    _crabProfileService.updateSession(_session);
    _crabService.updateSession(_session);
    _inboundLotService.updateSession(_session);
    _farmDashboardService.updateSession(_session);
    _rowManagementService.updateSession(_session);
    _boxManagementService.updateSession(_session);
  }

  Future<void> _refreshAdminFarms() async {
    try {
      final farms = await _cloudApi.fetchFarms(_session.token);
      if (!mounted || farms.isEmpty) return;
      final selected = farms.any((f) => f.id == _session.selectedFarm.id)
          ? _session.selectedFarm
          : farms.first;
      setState(() {
        _session = _session.copyWith(farms: farms, selectedFarm: selected);
      });
      _applySessionToServices();
    } catch (_) {
      // Giữ danh sách từ /api/auth/me nếu refresh thất bại.
    }
  }

  /// Cua lột có 2 hướng: xuất bán ngay (tạo phiếu thu hoạch cua lột), hoặc
  /// để lại nuôi tiếp — hướng thứ hai chỉ cần đóng drawer, không gọi API.
  Future<void> _exportMoltingCrab(FarmMapBox item) async {
    final crabId = item.source?.crabId;
    if (crabId == null || crabId.isEmpty) {
      _snack('Hộp ${item.display.id} chưa gắn cá thể cua nào.');
      return;
    }
    final ok = await _crabService.exportSoftshell(crabId);
    if (!mounted) return;
    if (!ok) {
      _snack(_crabService.error ?? 'Không xuất được cua lột.');
      return;
    }
    await _farmLayoutService.load(force: true);
    if (!mounted) return;
    _snack('Đã xuất bán cua lột ở hộp ${item.display.id}.');
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _connectivityLinkService.removeListener(_onConnectivityUpdate);
    super.dispose();
  }

  void _onConnectivityUpdate() {
    if (!mounted) return;
    setState(() {});
  }

  void _onFarmChanged(FarmSummary farm) {
    if (farm.id == _session.selectedFarm.id) return;
    setState(() {
      _session = _session.copyWith(selectedFarm: farm);
      _selectedAreaId = null;
      _selectedBoxItem = null;
      _selectedCrabId = null;
      _selectedLotId = null;
      _selectedBatch = null;
      _route = switch (_route) {
        AppRoute.areaDetail => AppRoute.areaManagement,
        AppRoute.boxDetail => AppRoute.boxManagement,
        AppRoute.crabManagementDetail => AppRoute.productionCrabManagement,
        AppRoute.inboundLotDetail => AppRoute.inboundLots,
        AppRoute.individualDetail ||
        AppRoute.individualHealth =>
          AppRoute.productionCrabManagement,
        AppRoute.batchDetail => AppRoute.batches,
        _ => _route,
      };
    });
    _applySessionToServices();
    _reloadSelectedFarmData();
    CloudAuthService().persistSessionIfRemembered(_session);
  }

  void _reloadSelectedFarmData() {
    _connectivityLinkService.refreshCloud();
    _waterQualityService.refreshTrend(quiet: true);
    _alertService.load();
    _gatewayService.registerHeartbeat();

    if (_route.isProductionRoute) {
      _productionManagementService.loadCurrentTab();
    }

    switch (_route) {
      case AppRoute.dashboard:
        _farmDashboardService.load(force: true);
        _farmLayoutService.load();
        _waterQualityService.refresh();
        _waterAnalysisService.load();
        _alertService.load();
        _farmLogService.load();
        _rasFlowService.startLiveRefresh(_session.selectedFarm.id);
      case AppRoute.farmAreas:
        _farmLayoutService.load(force: true);
        _areaManagementService.load();
        _iotDeviceService.loadUiDevices();
      case AppRoute.farmManagement:
      case AppRoute.areaManagement:
        _areaManagementService.load();
      case AppRoute.rowManagement:
        _rowManagementService.load();
      case AppRoute.boxManagement:
        _boxManagementService.load();
      case AppRoute.inboundLots:
      case AppRoute.inboundLotDetail:
        _inboundLotService.load();
      case AppRoute.productionCrabManagement:
      case AppRoute.individuals:
        _crabService.load();
      case AppRoute.devices:
        _rasFlowService.startLiveRefresh(_session.selectedFarm.id);
      case AppRoute.controllers:
        _controllerService.load();
      case AppRoute.environment:
        _waterQualityService.refresh();
        _areaEnvironmentService.loadByArea(_session.selectedFarm.id);
      case AppRoute.waterAnalysis:
        _waterAnalysisService.load();
      case AppRoute.farmLogs:
        _farmLogService.load();
      case AppRoute.harvestSales:
        _harvestSalesService.load();
      case AppRoute.aiInsight:
        _aiAssistantService.load();
      default:
        break;
    }
  }

  AppTopBar _shellTopBar({
    String? title,
    String? subtitle,
    String searchHint = 'Tìm kiếm...',
    ValueChanged<String>? onSearchChanged,
    int alertCount = 5,
    Widget? leading,
    Widget? centerTitle,
    bool hideSearch = false,
  }) {
    return AppTopBar(
      title: title,
      subtitle: subtitle,
      searchHint: searchHint,
      onSearchChanged: onSearchChanged,
      displayName: _session.user.displayName,
      alertCount: alertCount,
      leading: leading,
      centerTitle: centerTitle,
      hideSearch: hideSearch,
      onLogout: _logout,
      connectivity: _connectivityLinkService,
      onOpenDeviceSetup: () => _navigate(AppRoute.devices),
      onSettingsTap: () => _navigate(AppRoute.devices),
      farms: _session.farms,
      selectedFarm: _session.selectedFarm,
      onFarmChanged: (_session.isOrgAdmin || _session.farms.length > 1)
          ? _onFarmChanged
          : null,
    );
  }

  void _navigate(AppRoute route) {
    setState(() {
      _route = route;
      if (route != AppRoute.batchDetail) {
        _selectedBatch = null;
      }
      if (route != AppRoute.individualDetail &&
          route != AppRoute.individualHealth &&
          route != AppRoute.crabManagementDetail) {
        _selectedCrabId = null;
      }
      if (route != AppRoute.inboundLotDetail) {
        _selectedLotId = null;
      }
    });
    if (route.isProductionRoute) {
      _productionManagementService.setTab(ProductionTab.crab);
      _productionManagementService.loadCurrentTab();
    }
    if (route == AppRoute.areaManagement ||
        route == AppRoute.farmManagement) {
      _areaManagementService.load();
    }
    if (route == AppRoute.rowManagement) {
      _rowManagementService.load();
    }
    if (route == AppRoute.boxManagement) {
      _boxManagementService.load();
    }
    if (route == AppRoute.inboundLots) {
      _inboundLotService.load();
    }
    if (route == AppRoute.farmAreas) {
      _farmLayoutService.load(force: true);
      _iotDeviceService.loadUiDevices();
    }
    if (route == AppRoute.devices) {
      _rasFlowService.startLiveRefresh(_session.selectedFarm.id);
    }
    if (route == AppRoute.controllers) {
      _controllerService.load();
    }
    if (route == AppRoute.environment) {
      _waterQualityService.refresh();
    }
    if (route == AppRoute.waterAnalysis) {
      _waterAnalysisService.load();
    }
    if (route == AppRoute.alerts) {
      _alertService.load();
    }
    // Giữ khu đang xem khi đi Chi tiết khu → Chi tiết hộp → quay lại.
    if (route != AppRoute.areaDetail && route != AppRoute.boxDetail) {
      _selectedAreaId = null;
    }
    if (route == AppRoute.productionCrabManagement ||
        route == AppRoute.individuals) {
      _crabService.load();
    }
    if (route == AppRoute.dashboard) {
      _farmDashboardService.load(force: true);
      _farmLayoutService.load();
      _waterQualityService.refresh();
      _waterAnalysisService.load();
      _alertService.load();
      _farmLogService.load();
      _rasFlowService.startLiveRefresh(_session.selectedFarm.id);
    } else {
      _farmDashboardService.stopLiveRefresh();
    }
    if (route == AppRoute.farmLogs) {
      _farmLogService.load();
    }
    if (route == AppRoute.harvestSales) {
      _harvestSalesService.load();
    }
    if (route == AppRoute.aiInsight) {
      _aiAssistantService.load();
    }
  }

  void _openInboundLotDetail(FarmingBatchRecord lot) {
    setState(() {
      _selectedLotId = lot.id;
      _route = AppRoute.inboundLotDetail;
    });
    _inboundLotService.refreshOne(lot.id);
  }

  void _backToInboundLots() {
    setState(() {
      _route = AppRoute.inboundLots;
      _selectedLotId = null;
    });
    _inboundLotService.load();
  }

  void _openCrabManagementDetail(CrabIndividual crab) {
    setState(() {
      _selectedCrabId = crab.id;
      _route = AppRoute.crabManagementDetail;
    });
    _crabService.loadDetail(crab.id);
  }

  void _backToCrabManagementList() {
    setState(() {
      _route = AppRoute.productionCrabManagement;
      _selectedCrabId = null;
    });
  }

  void _openAreaDetail(String areaId) {
    setState(() {
      _selectedAreaId = areaId;
      _route = AppRoute.areaDetail;
    });
  }

  /// "Xem dãy →" trên card khu: mở Quản lý dãy đã lọc theo khu đó.
  void _openRowsOfArea(AreaRecord area) {
    _rowManagementService.setAreaFilter(area.id);
    _navigate(AppRoute.rowManagement);
  }

  /// Dãy → "Xem hộp →": mở Quản lý hộp lọc theo khu + dãy đã chọn.
  void _openBoxesOfRow(RowListItem row) =>
      _openBoxes(areaId: row.areaId, rowId: row.rowId);

  /// Mở Quản lý hộp lọc theo khu (và dãy nếu có).
  void _openBoxes({required String areaId, String? rowId}) {
    // setAreaFilter reset rowFilter → phải gọi trước setRowFilter.
    _boxManagementService.setAreaFilter(areaId);
    _boxManagementService.setRowFilter(rowId);
    _navigate(AppRoute.boxManagement);
  }

  void _backToAreaList() {
    setState(() {
      _route = AppRoute.areaManagement;
      _selectedAreaId = null;
    });
    _areaManagementService.load();
  }

  void _openBatchDetail(CrabBatch batch) {
    setState(() {
      _selectedBatch = batch;
      _selectedCrabId = null;
      _route = AppRoute.batchDetail;
    });
  }

  void _backToBatchList() {
    setState(() {
      _route = AppRoute.batches;
      _selectedBatch = null;
    });
  }

  void _openCrabDetail(CrabIndividual crab) {
    setState(() {
      _selectedCrabId = crab.id;
      _selectedBatch = null;
      _route = AppRoute.individualDetail;
    });
  }

  void _openHealthMonitoring(String crabId) {
    setState(() {
      _selectedCrabId = crabId;
      _selectedBatch = null;
      _route = AppRoute.individualHealth;
    });
  }

  void _backToCrabList() {
    setState(() {
      _route = AppRoute.individuals;
      _selectedCrabId = null;
    });
  }

  void _backToCrabDetail() {
    setState(() {
      _route = AppRoute.individualDetail;
    });
  }

  Future<void> _logout() async {
    final token = _session.token;
    final auth = CloudAuthService();
    await auth.clearSession(keepUsername: true);
    await auth.logoutRemote(token);
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildShell(context);
  }

  Widget _buildShell(BuildContext context) {
    final sidebarRoute = switch (_route) {
      AppRoute.batchDetail => AppRoute.batches,
      AppRoute.individualDetail || AppRoute.individualHealth => AppRoute.individuals,
      AppRoute.areaDetail => AppRoute.areaManagement,
      AppRoute.inboundLotDetail => AppRoute.inboundLots,
      _ => _route,
    };

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const WaveBackground(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppSidebar(
                selected: sidebarRoute,
                onSelect: _navigate,
                onLogout: _logout,
                onUpgradeSensorKit: () => _navigate(AppRoute.devices),
                onOpenDeviceSetup: () => _navigate(AppRoute.devices),
              ),
              Expanded(
                child: Column(
                  children: [
                    _buildTopBar(),
                    Expanded(child: _buildBody()),
                    const AppFooter(),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    if (_route == AppRoute.batchDetail && _selectedBatch != null) {
      return _shellTopBar(
        searchHint: 'Tìm kiếm lứa nuôi, thiết bị...',
        leading: IconButton(
          onPressed: _backToBatchList,
          icon: const Icon(Icons.arrow_back, color: Color(0xFF94A3B8)),
        ),
        centerTitle: const SizedBox.shrink(),
      );
    }

    if (_route == AppRoute.individualHealth && _selectedCrabId != null) {
      return _shellTopBar(
        searchHint: 'Tìm kiếm cá thể, thiết bị hoặc khu nuôi...',
        leading: IconButton(
          onPressed: _backToCrabDetail,
          icon: const Icon(Icons.arrow_back, color: Color(0xFF94A3B8)),
        ),
        centerTitle: const SizedBox.shrink(),
      );
    }

    if (_route == AppRoute.individualDetail && _selectedCrabId != null) {
      return _shellTopBar(
        searchHint: 'Tìm kiếm cá thể...',
        leading: IconButton(
          onPressed: _backToCrabList,
          icon: const Icon(Icons.arrow_back, color: Color(0xFF94A3B8)),
        ),
        centerTitle: const SizedBox.shrink(),
      );
    }

    if (_route == AppRoute.batches) {
      return _shellTopBar(
        searchHint: 'Tìm kiếm lứa nuôi...',
        onSearchChanged: _batchService.setSearch,
      );
    }

    if (_route == AppRoute.individuals) {
      return _shellTopBar(
        searchHint: 'Tìm kiếm cá thể, thiết bị hoặc khu nuôi...',
        onSearchChanged: _crabService.setSearch,
      );
    }

    if (_route == AppRoute.farmAreas) {
      return _shellTopBar(
        title: 'Bản đồ trại',
        subtitle: 'Tổng quan bố trí khu, dãy và hộp trong trại nuôi',
        alertCount: _farmDashboardService.alertCount,
        hideSearch: true,
      );
    }

    if (_route == AppRoute.farmManagement ||
        _route == AppRoute.areaManagement) {
      return _shellTopBar(
        title: 'Quản lý khu',
        subtitle: 'Quản lý và cấu hình các khu nuôi trong trại',
        alertCount: _farmDashboardService.alertCount,
        hideSearch: true,
      );
    }

    if (_route == AppRoute.rowManagement) {
      return _shellTopBar(
        title: 'Quản lý dãy',
        subtitle: 'Quản lý thông tin các dãy trong khu nuôi',
        alertCount: _farmDashboardService.alertCount,
        hideSearch: true,
      );
    }

    if (_route == AppRoute.boxManagement) {
      return _shellTopBar(
        searchHint: 'Tìm kiếm theo mã hộp hoặc mã cua...',
        onSearchChanged: _boxManagementService.setSearch,
        centerTitle: const SizedBox.shrink(),
      );
    }

    if (_route == AppRoute.inboundLots) {
      return _shellTopBar(
        searchHint: 'Tìm kiếm mã lô, tên lô hoặc nhà cung cấp...',
        onSearchChanged: _inboundLotService.setSearch,
        centerTitle: const SizedBox.shrink(),
      );
    }

    if (_route == AppRoute.inboundLotDetail) {
      return _shellTopBar(
        searchHint: 'Tìm kiếm lô nhập...',
        leading: IconButton(
          onPressed: _backToInboundLots,
          icon: const Icon(Icons.arrow_back, color: Color(0xFF94A3B8)),
        ),
        centerTitle: const SizedBox.shrink(),
      );
    }

    if (_route == AppRoute.areaDetail) {
      return _shellTopBar(
        title: 'Chi tiết khu',
        subtitle: 'Tổng quan theo dõi và quản lý một khu nuôi',
        alertCount: _farmDashboardService.alertCount,
        hideSearch: true,
        leading: IconButton(
          tooltip: 'Về Quản lý khu',
          onPressed: _backToAreaList,
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF087F5B)),
        ),
      );
    }

    if (_route == AppRoute.crabManagementDetail) {
      return _shellTopBar(
        searchHint: 'Tìm mã cua...',
        leading: IconButton(
          onPressed: _backToCrabManagementList,
          icon: const Icon(Icons.arrow_back, color: Color(0xFF94A3B8)),
        ),
        centerTitle: const SizedBox.shrink(),
      );
    }

    if (_route == AppRoute.productionCrabManagement) {
      return _shellTopBar(
        searchHint: 'Tìm mã cua (VD: CR-1025)...',
        onSearchChanged: _crabService.setSearch,
        centerTitle: const SizedBox.shrink(),
      );
    }

    if (_route.isProductionRoute) {
      return _shellTopBar(
        searchHint: 'Tìm kiếm...',
        onSearchChanged: _productionManagementService.setSearch,
        centerTitle: const SizedBox.shrink(),
      );
    }

    if (_route == AppRoute.environment) {
      return _shellTopBar(
        searchHint: 'Khu nuôi, thiết bị...',
        centerTitle: const SizedBox.shrink(),
      );
    }

    if (_route == AppRoute.waterAnalysis) {
      return _shellTopBar(
        searchHint: 'Phân tích hóa học...',
        centerTitle: const SizedBox.shrink(),
      );
    }

    if (_route == AppRoute.devices) {
      return _shellTopBar(
        searchHint: 'Tìm thiết bị RAS...',
        centerTitle: const SizedBox.shrink(),
      );
    }

    if (_route == AppRoute.controllers) {
      return _shellTopBar(
        searchHint: 'Tìm ESP32 / controller...',
        centerTitle: const SizedBox.shrink(),
      );
    }

    if (_route == AppRoute.alerts) {
      return _shellTopBar(
        searchHint: 'Tìm kiếm cảnh báo...',
        onSearchChanged: _alertService.setSearch,
        centerTitle: const SizedBox.shrink(),
      );
    }

    if (_route == AppRoute.farmLogs) {
      return _shellTopBar(
        searchHint: 'Tìm kiếm nhật ký, mã cua...',
        onSearchChanged: _farmLogService.setSearch,
        centerTitle: const SizedBox.shrink(),
      );
    }

    if (_route == AppRoute.harvestSales) {
      return _shellTopBar(
        searchHint: 'Tìm kiếm đơn hàng, mã cua...',
        onSearchChanged: _harvestSalesService.setSearch,
        centerTitle: const SizedBox.shrink(),
      );
    }

    if (_route == AppRoute.aiInsight) {
      return _shellTopBar(
        searchHint: 'Hỏi Crab Assistant...',
        onSearchChanged: _aiAssistantService.setSearch,
        centerTitle: const SizedBox.shrink(),
      );
    }

    return _shellTopBar(
      title: 'Dashboard Tổng Quan',
      subtitle: 'Giám sát và quản lý trại nuôi cua lột thông minh',
      alertCount: _farmDashboardService.alertCount,
      hideSearch: true,
    );
  }

  Widget _buildBody() {
    switch (_route) {
      case AppRoute.dashboard:
        return DashboardContent(
          displayName: _session.user.displayName,
          dashboardService: _farmDashboardService,
          farmLayoutService: _farmLayoutService,
          waterQualityService: _waterQualityService,
          waterAnalysisService: _waterAnalysisService,
          rasFlowService: _rasFlowService,
          alertService: _alertService,
          farmLogService: _farmLogService,
          areaId: _session.selectedFarm.id,
          areaLabel: () {
            final f = _session.selectedFarm;
            if (f.code.isNotEmpty) return '${f.name} (${f.code})';
            return f.name;
          }(),
          onNavigate: _navigate,
        );
      case AppRoute.batches:
        return BatchListPage(
          service: _batchService,
          onViewBatch: _openBatchDetail,
        );
      case AppRoute.batchDetail:
        final batch = _selectedBatch ??
            _batchService.getById('CFM-2026-001') ??
            _batchService.batches.first;
        return BatchDetailPage(
          batch: batch,
          service: _batchService,
          onBack: _backToBatchList,
        );
      case AppRoute.farmAreas:
        return FarmLayoutPage(
          farmLayoutService: _farmLayoutService,
          rasFlowService: _rasFlowService,
          areaService: _areaManagementService,
          deviceService: _iotDeviceService,
          farmName: _session.selectedFarm.name,
          onOpenRas: () => _navigate(AppRoute.devices),
          onOpenBox: (item) {
            _selectedBoxItem = item;
            _boxDetailBack = AppRoute.farmAreas;
            _navigate(AppRoute.boxDetail);
          },
          onExportMolting: _exportMoltingCrab,
          onOpenAreaDetail: _openAreaDetail,
        );
      // "Quản lý khu" trên sidebar dùng route farmManagement → render trang
      // Quản lý khu mới (danh sách khu theo card ngang).
      case AppRoute.farmManagement:
      case AppRoute.areaManagement:
        return AreaManagementPage(
          service: _areaManagementService,
          onNavigate: _navigate,
          onOpenDetail: (a) => _openAreaDetail(a.id),
          onViewRows: _openRowsOfArea,
        );
      case AppRoute.areaDetail:
        final areaId = _selectedAreaId ??
            (_areaManagementService.areas.isNotEmpty
                ? _areaManagementService.areas.first.id
                : null);
        if (areaId == null) {
          return AreaManagementPage(
            service: _areaManagementService,
            onNavigate: _navigate,
            onOpenDetail: (a) => _openAreaDetail(a.id),
            onViewRows: _openRowsOfArea,
          );
        }
        return AreaDetailPage(
          service: _areaManagementService,
          areaEnvironmentService: _areaEnvironmentService,
          rasFlowService: _rasFlowService,
          areaId: areaId,
          onBack: _backToAreaList,
          onNavigate: _navigate,
          productionService: _productionManagementService,
          onViewBoxesOfRow: (row) =>
              _openBoxes(areaId: row.areaId, rowId: row.id),
          onOpenCrab: (box) {
            final id = box.crabId;
            if (id == null || id.isEmpty || id == 'null') return;
            setState(() {
              _selectedCrabId = id;
              _route = AppRoute.crabManagementDetail;
            });
            _crabService.loadDetail(id);
          },
          onOpenBox: (box) {
            final area = _areaManagementService.areas
                .where((a) => a.id == areaId)
                .firstOrNull;
            _selectedBoxItem = BoxListItem(
              box: box,
              areaId: areaId,
              areaCode: box.areaCode ?? area?.areaCode ?? '',
              areaName: box.areaName ?? area?.areaName ?? '',
              rowId: box.rowId,
              rowCode: box.rowCode ?? '',
              rowName: box.rowName ?? '',
            );
            _boxDetailBack = AppRoute.areaDetail;
            _navigate(AppRoute.boxDetail);
          },
        );
      case AppRoute.rowManagement:
        return RowManagementPage(
          service: _rowManagementService,
          productionService: _productionManagementService,
          onNavigate: _navigate,
          onViewBoxes: _openBoxesOfRow,
        );
      case AppRoute.boxManagement:
        return BoxManagementPage(
          service: _boxManagementService,
          productionService: _productionManagementService,
          onNavigate: _navigate,
          onBoxTap: (item) {
            _selectedBoxItem = item;
            _boxDetailBack = AppRoute.boxManagement;
            _navigate(AppRoute.boxDetail);
          },
        );
      case AppRoute.boxDetail:
        if (_selectedBoxItem != null) {
          return BoxDetailPage(
            box: _selectedBoxItem!.box,
            areaId: _selectedBoxItem!.areaId,
            areaCode: _selectedBoxItem!.areaCode,
            areaName: _selectedBoxItem!.areaName,
            rowName: _selectedBoxItem!.rowName,
            crabProfileService: _crabProfileService,
            cameraService: _cameraDeviceService,
            areaEnvironmentService: _areaEnvironmentService,
            onBack: () => _navigate(_boxDetailBack),
          );
        }
        return const SizedBox.shrink();
      case AppRoute.inboundLots:
        return CrabLotInboundPage(
          service: _inboundLotService,
          crabService: _crabService,
          onNavigate: _navigate,
          onOpenDetail: _openInboundLotDetail,
        );
      case AppRoute.inboundLotDetail:
        final lotId = _selectedLotId ??
            (_inboundLotService.lots.isNotEmpty ? _inboundLotService.lots.first.id : null);
        if (lotId == null) {
          return CrabLotInboundPage(
            service: _inboundLotService,
            crabService: _crabService,
            onNavigate: _navigate,
            onOpenDetail: _openInboundLotDetail,
          );
        }
        return CrabLotInboundDetailPage(
          lotId: lotId,
          service: _inboundLotService,
          crabService: _crabService,
          onBack: _backToInboundLots,
          onNavigate: _navigate,
          onOpenCrab: (id) {
            final crab = _crabService.getById(id);
            if (crab != null) _openCrabManagementDetail(crab);
          },
        );
      case AppRoute.farmingBatchManagement:
      case AppRoute.farmingBatchDetail:
        return const Center(
          child: Text(
            'BE đã tắt CropBatch (đợt nuôi).\nThêm cua trong Quản lý cua — hệ thống dùng lô cua.',
            textAlign: TextAlign.center,
          ),
        );
      case AppRoute.productionCrabManagement:
        return CrabManagementPage(
          service: _crabService,
          onNavigate: _navigate,
          onOpenDetail: _openCrabManagementDetail,
        );
      case AppRoute.crabManagementDetail:
        final crabId = _selectedCrabId ??
            (_crabService.filteredCrabs.isNotEmpty
                ? _crabService.filteredCrabs.first.id
                : (_crabService.crabs.isNotEmpty
                    ? _crabService.crabs.first.id
                    : null));
        if (crabId == null) {
          return CrabManagementPage(
            service: _crabService,
            onNavigate: _navigate,
            onOpenDetail: _openCrabManagementDetail,
          );
        }
        return CrabManagementDetailPage(
          crabId: crabId,
          service: _crabService,
          cameraService: _cameraDeviceService,
          gatewayService: _gatewayService,
          onBack: _backToCrabManagementList,
        );
      case AppRoute.individuals:
        return CrabListPage(
          service: _crabService,
          onViewCrab: _openCrabDetail,
          onOpenHealth: (c) => _openHealthMonitoring(c.id),
        );
      case AppRoute.individualDetail:
        final id = _selectedCrabId ??
            (_crabService.crabs.isNotEmpty
                ? _crabService.crabs.first.id
                : 'CRAB-A01-001');
        return CrabDetailPage(
          crabId: id,
          service: _crabService,
          onBack: _backToCrabList,
          onOpenHealth: () => _openHealthMonitoring(id),
        );
      case AppRoute.individualHealth:
        final id = _selectedCrabId ?? 'CRAB-A01-001';
        return HealthMonitoringPage(
          crabId: id,
          onBack: _backToCrabDetail,
          onOpenHistory: _backToCrabDetail,
        );
      case AppRoute.cameraAi:
      case AppRoute.feed:
      case AppRoute.reports:
      case AppRoute.sensorUpgrade:
      case AppRoute.deviceSetup:
        return Center(
          child: Text(
            '${_route.label} không có trên CrabSenseBE',
            style: const TextStyle(color: Color(0xFF94A3B8)),
          ),
        );
      case AppRoute.environment:
        return RealtimeMonitorPage(
          service: _waterQualityService,
          alertService: _alertService,
        );
      case AppRoute.waterAnalysis:
        return WaterAnalysisPage(
          service: _waterAnalysisService,
          areaName: _session.selectedFarm.name,
        );
      case AppRoute.devices:
        return RasControlPage(
          service: _rasFlowService,
          areaId: _session.selectedFarm.id,
          areaName: _session.selectedFarm.name,
        );
      case AppRoute.controllers:
        return ControllerManagementPage(
          service: _controllerService,
          areaName: _session.selectedFarm.name,
        );
      case AppRoute.alerts:
        return AlertSystemPage(service: _alertService);
      case AppRoute.farmLogs:
        return FarmActivityLogPage(
          service: _farmLogService,
          layoutService: _farmLayoutService,
          crabService: _crabService,
        );
      case AppRoute.harvestSales:
        return HarvestSalesPage(service: _harvestSalesService);
      case AppRoute.aiInsight:
        return AiInsightPage(service: _aiAssistantService);
    }
  }
}
