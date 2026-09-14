import 'package:flutter/foundation.dart';

import '../models/farm_report.dart';

class FarmReportService extends ChangeNotifier {
  ReportTimeRange _timeRange = ReportTimeRange.days30;
  String _batchFilter = 'Tất cả';
  String _areaFilter = 'Tất cả';
  ReportType _reportType = ReportType.overview;
  String _search = '';

  ReportTimeRange get timeRange => _timeRange;
  String get batchFilter => _batchFilter;
  String get areaFilter => _areaFilter;
  ReportType get reportType => _reportType;

  FarmReportKpi get kpi => const FarmReportKpi(
        survivalRatePercent: 0,
        survivalTrendPercent: 0,
        avgGrowthPerWeekG: 0,
        avgHealthScore: 0,
        opsEfficiencyPercent: 0,
        totalRevenueVnd: 0,
        revenueForecastPercent: 0,
        totalCostVnd: 0,
        feedCostSharePercent: 0,
        netProfitVnd: 0,
        roiPercent: 0,
        electricityKwh: 0,
        electricityTrendPercent: 0,
        waterM3: 0,
        carbonReductionPercent: 0,
      );
  String get aiSummary => 'Chưa có dữ liệu báo cáo.';
  List<String> get aiAnalysis => const [];
  List<ReportAiAction> get aiActions => const [];
  List<SurvivalGrowthPeriod> get survivalGrowthBars => const [];
  List<CostAllocationSegment> get costAllocation => const [];
  List<ResourceUsageItem> get resources => const [];

  List<DailyReportRow> get dailyRows {
    var rows = const <DailyReportRow>[];
    if (_batchFilter != 'Tất cả') {
      rows = rows.where((r) => r.batchId == _batchFilter).toList();
    }
    if (_search.trim().isNotEmpty) {
      final q = _search.toLowerCase();
      rows = rows
          .where(
            (r) =>
                r.date.contains(q) ||
                r.batchId.toLowerCase().contains(q),
          )
          .toList();
    }
    return rows;
  }

  String get reportTypeLabel => switch (_reportType) {
        ReportType.overview => 'Báo cáo Tổng quan',
        ReportType.health => 'Sức khỏe',
        ReportType.environment => 'Môi trường',
        ReportType.finance => 'Tài chính',
        ReportType.devices => 'Thiết bị',
      };

  void setSearch(String v) {
    _search = v;
    notifyListeners();
  }

  void setTimeRange(ReportTimeRange r) {
    _timeRange = r;
    notifyListeners();
  }

  void setBatchFilter(String v) {
    _batchFilter = v;
    notifyListeners();
  }

  void setAreaFilter(String v) {
    _areaFilter = v;
    notifyListeners();
  }

  void setReportType(ReportType t) {
    _reportType = t;
    notifyListeners();
  }

  void exportPdf() => notifyListeners();
  void exportExcel() => notifyListeners();
}
