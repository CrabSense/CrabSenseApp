/// Report types backed by GET /api/reports/*.
enum ReportKind {
  harvest,
  inventory,
  molting,
  survival,
  efficiency,
}

extension ReportKindX on ReportKind {
  String get apiPath => switch (this) {
        ReportKind.harvest => '/reports/harvest',
        ReportKind.inventory => '/reports/inventory',
        ReportKind.molting => '/reports/molting',
        ReportKind.survival => '/reports/survival-rate',
        ReportKind.efficiency => '/reports/operational-efficiency',
      };

  String get titleVi => switch (this) {
        ReportKind.harvest => 'Báo cáo thu hoạch',
        ReportKind.inventory => 'Báo cáo tồn kho & bán hàng',
        ReportKind.molting => 'Báo cáo tăng trưởng (lột xác)',
        ReportKind.survival => 'Báo cáo tỷ lệ sống / hao hụt',
        ReportKind.efficiency => 'Báo cáo hiệu quả vận hành',
      };

  String get subtitleVi => switch (this) {
        ReportKind.harvest => 'Phiếu thu hoạch, khối lượng, phân loại',
        ReportKind.inventory => 'Tồn kho đông lạnh theo grade',
        ReportKind.molting => 'Tỷ lệ lột xác theo khu vực',
        ReportKind.survival => 'Sống / chết / thu hoạch',
        ReportKind.efficiency => 'Molting · harvest · mortality',
      };

  String get queryValue => name;

  static ReportKind? fromQuery(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return ReportKind.values.where((e) => e.name == raw).firstOrNull;
  }
}

/// Normalized KPI row for report detail UI.
class ReportMetric {
  const ReportMetric({
    required this.label,
    required this.value,
    this.hint,
  });

  final String label;
  final String value;
  final String? hint;
}

class ReportDetailData {
  const ReportDetailData({
    required this.kind,
    required this.metrics,
    this.sections = const [],
    this.raw,
  });

  final ReportKind kind;
  final List<ReportMetric> metrics;
  final List<ReportSection> sections;
  final Map<String, dynamic>? raw;
}

class ReportSection {
  const ReportSection({required this.title, required this.rows});

  final String title;
  final List<ReportMetric> rows;
}
