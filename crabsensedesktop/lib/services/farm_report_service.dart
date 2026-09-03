import 'package:flutter/foundation.dart';

import '../data/mock_farm_report_data.dart';
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

  FarmReportKpi get kpi => MockFarmReportData.kpi;
  String get aiSummary => MockFarmReportData.aiSummary;
  List<String> get aiAnalysis => MockFarmReportData.aiAnalysis;
  List<ReportAiAction> get aiActions => MockFarmReportData.aiActions;
  List<SurvivalGrowthPeriod> get survivalGrowthBars =>
      MockFarmReportData.survivalGrowthBars();
  List<CostAllocationSegment> get costAllocation =>
      MockFarmReportData.costAllocation();
  List<ResourceUsageItem> get resources => MockFarmReportData.resources();

  List<DailyReportRow> get dailyRows {
    var rows = MockFarmReportData.dailyRows();
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
