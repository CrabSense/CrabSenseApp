enum AppRoute {
  dashboard,
  batches,
  batchDetail,
  farmAreas,
  farmManagement,
  areaManagement,
  areaDetail,
  rowManagement,
  boxManagement,
  boxDetail,
  farmingBatchManagement,
  farmingBatchDetail,
  inboundLots,
  inboundLotDetail,
  productionCrabManagement,
  crabManagementDetail,
  individuals,
  individualDetail,
  individualHealth,
  feed,
  cameraAi,
  devices,
  environment,
  alerts,
  farmLogs,
  harvestSales,
  reports,
  aiInsight,
  sensorUpgrade,
  deviceSetup,
}

extension AppRouteX on AppRoute {
  String get label => switch (this) {
        AppRoute.dashboard => 'Dashboard',
        AppRoute.batches => 'Lứa nuôi',
        AppRoute.batchDetail => 'Chi tiết lứa',
        AppRoute.farmAreas => 'Bản đồ trại',
        AppRoute.farmManagement => 'Quản lý khu',
        AppRoute.areaManagement => 'Quản lý khu',
        AppRoute.areaDetail => 'Chi tiết khu',
        AppRoute.rowManagement => 'Quản lý dãy',
        AppRoute.boxManagement => 'Quản lý hộp',
        AppRoute.boxDetail => 'Chi tiết hộp',
        AppRoute.farmingBatchManagement => 'Đợt nuôi (đã tắt)',
        AppRoute.farmingBatchDetail => 'Đợt nuôi (đã tắt)',
        AppRoute.inboundLots => 'Quản lý nhập hàng',
        AppRoute.inboundLotDetail => 'Chi tiết lô nhập',
        AppRoute.productionCrabManagement => 'Quản lý cua',
        AppRoute.crabManagementDetail => 'Chi tiết cua',
        AppRoute.individuals => 'Cá thể cua',
        AppRoute.individualDetail => 'Chi tiết cá thể',
        AppRoute.individualHealth => 'Health Monitoring',
        AppRoute.feed => 'Thức ăn',
        AppRoute.cameraAi => 'Camera AI',
        AppRoute.devices => 'Điều khiển thiết bị',
        AppRoute.environment => 'Cảm biến môi trường',
        AppRoute.alerts => 'Hệ thống cảnh báo',
        AppRoute.farmLogs => 'Nhật ký',
        AppRoute.harvestSales => 'Thu hoạch & Bán hàng',
        AppRoute.reports => 'Báo cáo',
        AppRoute.aiInsight => 'AI Insight',
        AppRoute.sensorUpgrade => 'Nâng cấp Sensor',
        AppRoute.deviceSetup => 'Device Setup',
      };

  bool get isProductionRoute => switch (this) {
        AppRoute.productionCrabManagement => true,
        _ => false,
      };

  bool get isImplemented =>
      this == AppRoute.dashboard ||
      this == AppRoute.farmAreas ||
      this == AppRoute.farmManagement ||
      isProductionRoute ||
      this == AppRoute.areaManagement ||
      this == AppRoute.areaDetail ||
      this == AppRoute.rowManagement ||
      this == AppRoute.boxManagement ||
      this == AppRoute.boxDetail ||
      this == AppRoute.inboundLots ||
      this == AppRoute.inboundLotDetail ||
      this == AppRoute.crabManagementDetail ||
      this == AppRoute.environment ||
      this == AppRoute.devices ||
      this == AppRoute.alerts ||
      this == AppRoute.farmLogs ||
      this == AppRoute.harvestSales ||
      this == AppRoute.aiInsight;
}
