import 'package:flutter/material.dart';

import '../models/crab_individual.dart';
import '../models/crab_status.dart';
import '../theme/dashboard_theme.dart';

abstract final class MockCrabData {
  static const totalPopulation = 1248;
  static const allOption = 'Tất cả';

  static const lifeStatusOptions = [
    'Tất cả trạng thái',
    'Đang nuôi',
    'Sẵn sàng bán',
    'Đã bán',
    'Đã chết',
  ];
  static const healthStatusOptions = [
    'Tất cả sức khỏe',
    'Khỏe mạnh',
    'Tốt',
    'Theo dõi',
    'Đang lột xác',
    'Nguy cơ',
  ];

  static List<CrabIndividual> initialCrabs() => [
        _crabA01,
        _crabA02,
        _crabB01,
        _crabA03,
        _crabB02,
        _crabC01,
        _crabA04,
        _crabB03,
        _crabA05,
        _crabC02,
        _crabA06,
        _crabB04,
      ];

  static final _weightA01 = [
    CrabWeightPoint(date: DateTime(2026, 1, 1), weightGram: 15),
    CrabWeightPoint(date: DateTime(2026, 1, 15), weightGram: 28),
    CrabWeightPoint(date: DateTime(2026, 2, 1), weightGram: 56),
    CrabWeightPoint(date: DateTime(2026, 2, 15), weightGram: 92),
    CrabWeightPoint(date: DateTime(2026, 3, 1), weightGram: 125, shellSizeCm: 8.2),
  ];

  static List<String> areaOptions(List<CrabIndividual> crabs) => [
        allOption,
        ...crabs.map((c) => c.areaName).toSet(),
      ];

  static List<String> rowOptions(List<CrabIndividual> crabs, String area) {
    var list = crabs;
    if (area != allOption) list = list.where((c) => c.areaName == area).toList();
    return [allOption, ...list.map((c) => c.rowName).toSet()];
  }

  static List<String> boxOptions(
    List<CrabIndividual> crabs,
    String area,
    String row,
  ) {
    var list = crabs;
    if (area != allOption) list = list.where((c) => c.areaName == area).toList();
    if (row != allOption) list = list.where((c) => c.rowName == row).toList();
    return [allOption, ...list.map((c) => c.boxLabel).toSet()];
  }

  static List<String> batchOptions(List<CrabIndividual> crabs) => [
        allOption,
        ...crabs.map((c) => c.batchId).toSet(),
      ];

  static ({String area, String row, String box}) locationForBox(String box) {
    final zone = box.isNotEmpty ? box[0] : 'A';
    final area = switch (zone) {
      'B' => 'Khu B',
      'C' => 'Khu C',
      _ => 'Khu A',
    };
    final num = box.length > 1 ? box.substring(1) : '01';
    return (
      area: area,
      row: 'Dãy ${num.padLeft(2, '0')}',
      box: 'Hộp $num',
    );
  }

  static final _crabA01 = CrabIndividual(
    id: 'CRAB-A01-001',
    displayCode: 'CR-1025',
    boxId: 'A01',
    batchId: 'BT-2024-Q1',
    areaName: 'Khu A',
    rowName: 'Dãy 01',
    boxName: 'Hộp 05',
    developmentStage: CrabDevelopmentStage.growing,
    updatedAt: DateTime(2026, 5, 28, 15, 30),
    estimatedValueVnd: 185000,
    meatQualityScore: 88,
    alertCount: 1,
    gender: CrabGender.male,
    weightGram: 125,
    shellSizeCm: 8.2,
    releaseDate: DateTime(2026, 1, 1),
    moltCount: 3,
    lastMoltDate: DateTime(2026, 2, 20),
    healthStatus: CrabHealthStatus.healthy,
    lifeStatus: CrabLifeStatus.raising,
    healthScore: 94,
    quickNote:
        'Cá thể có dấu hiệu tăng trưởng mạnh sau lần lột xác thứ 3. Cần bổ sung thêm canxi vào khẩu phần ăn tuần tới.',
    molts: [
      CrabMoltRecord(
        number: 1,
        date: DateTime(2026, 1, 10),
        condition: MoltCondition.normal,
        note: 'Tăng 12% kích thước',
      ),
      CrabMoltRecord(
        number: 2,
        date: DateTime(2026, 1, 28),
        condition: MoltCondition.normal,
        note: 'Phát triển tốt',
      ),
      CrabMoltRecord(
        number: 3,
        date: DateTime(2026, 2, 20),
        condition: MoltCondition.needsWatch,
        note: 'Mai chưa cứng hẳn — cần theo dõi 24h',
      ),
    ],
    diseases: [
      CrabDiseaseRecord(
        date: DateTime(2026, 2, 5),
        name: 'Đốm đen nhẹ',
        severity: DiseaseSeverity.mild,
        symptoms: 'Vài đốm trên càng phải',
        treatment: 'Tăng oxy, giảm mật độ ăn',
        status: DiseaseRecordStatus.resolved,
      ),
      CrabDiseaseRecord(
        date: DateTime(2026, 2, 18),
        name: 'Bỏ ăn 1 ngày',
        severity: DiseaseSeverity.moderate,
        symptoms: 'Không phản ứng với thức ăn',
        treatment: 'Theo dõi, kiểm tra nhiệt độ',
        status: DiseaseRecordStatus.monitoring,
      ),
    ],
    feedings: [
      CrabFeedingRecord(
        date: DateTime(2026, 3, 1),
        foodType: 'Cá tạp',
        amountGram: 8,
        note: 'Ăn tốt',
      ),
      CrabFeedingRecord(
        date: DateTime(2026, 3, 2),
        foodType: 'Thức ăn viên',
        amountGram: 7,
        note: 'Ăn chậm',
      ),
      CrabFeedingRecord(
        date: DateTime(2026, 3, 3),
        foodType: 'Cá tạp',
        amountGram: 9,
        note: 'Bình thường',
      ),
    ],
    weightHistory: _weightA01,
  );

  static final _crabA02 = CrabIndividual(
    id: 'CRAB-A02-002',
    displayCode: 'CR-1018',
    boxId: 'A02',
    batchId: 'BT-2024-Q1',
    areaName: 'Khu A',
    rowName: 'Dãy 02',
    boxName: 'Hộp 02',
    updatedAt: DateTime(2026, 5, 27, 9, 15),
    gender: CrabGender.female,
    weightGram: 118,
    shellSizeCm: 7.8,
    releaseDate: DateTime(2026, 1, 5),
    moltCount: 2,
    lastMoltDate: DateTime(2026, 2, 10),
    healthStatus: CrabHealthStatus.monitoring,
    lifeStatus: CrabLifeStatus.raising,
    healthScore: 82,
    molts: [
      CrabMoltRecord(
        number: 1,
        date: DateTime(2026, 1, 18),
        condition: MoltCondition.normal,
      ),
      CrabMoltRecord(
        number: 2,
        date: DateTime(2026, 2, 10),
        condition: MoltCondition.normal,
      ),
    ],
    weightHistory: [
      CrabWeightPoint(date: DateTime(2026, 1, 5), weightGram: 14),
      CrabWeightPoint(date: DateTime(2026, 2, 1), weightGram: 68),
      CrabWeightPoint(date: DateTime(2026, 3, 1), weightGram: 118),
    ],
  );

  static final _crabB01 = CrabIndividual(
    id: 'CRAB-B01-003',
    displayCode: 'CR-1062',
    boxId: 'B01',
    batchId: 'CFM-2026-002',
    areaName: 'Khu B',
    rowName: 'Dãy 01',
    boxName: 'Hộp 01',
    developmentStage: CrabDevelopmentStage.harvestReady,
    updatedAt: DateTime(2026, 5, 28, 8, 0),
    gender: CrabGender.male,
    weightGram: 160,
    shellSizeCm: 9.1,
    releaseDate: DateTime(2025, 11, 1),
    moltCount: 4,
    lastMoltDate: DateTime(2026, 1, 25),
    healthStatus: CrabHealthStatus.good,
    lifeStatus: CrabLifeStatus.readyForSale,
    healthScore: 91,
    molts: [
      CrabMoltRecord(number: 1, date: DateTime(2025, 12, 5), condition: MoltCondition.normal),
      CrabMoltRecord(number: 2, date: DateTime(2025, 12, 28), condition: MoltCondition.normal),
      CrabMoltRecord(number: 3, date: DateTime(2026, 1, 10), condition: MoltCondition.normal),
      CrabMoltRecord(number: 4, date: DateTime(2026, 1, 25), condition: MoltCondition.normal),
    ],
    weightHistory: [
      CrabWeightPoint(date: DateTime(2025, 11, 1), weightGram: 20),
      CrabWeightPoint(date: DateTime(2026, 1, 1), weightGram: 110),
      CrabWeightPoint(date: DateTime(2026, 3, 1), weightGram: 160),
    ],
  );

  static CrabIndividual _simple({
    required String id,
    required String displayCode,
    required String box,
    required String batch,
    required CrabGender gender,
    required double weight,
    required CrabHealthStatus health,
    required CrabLifeStatus life,
    required int score,
    required int molts,
    CrabDevelopmentStage stage = CrabDevelopmentStage.growing,
    int alerts = 0,
  }) {
    final loc = locationForBox(box);
    return CrabIndividual(
      id: id,
      displayCode: displayCode,
      boxId: box,
      batchId: batch,
      areaName: loc.area,
      rowName: loc.row,
      boxName: loc.box,
      gender: gender,
      weightGram: weight,
      shellSizeCm: (weight / 36).clamp(3.0, 15.0),
      releaseDate: DateTime(2026, 1, 1),
      moltCount: molts,
      lastMoltDate: DateTime(2026, 2, 1),
      healthStatus: health,
      lifeStatus: life,
      healthScore: score,
      developmentStage: stage,
      updatedAt: DateTime.now().subtract(const Duration(hours: 6)),
      estimatedValueVnd: weight * 1200,
      meatQualityScore: score.toDouble(),
      alertCount: alerts,
      weightHistory: [
        CrabWeightPoint(
          date: DateTime(2026, 1, 1),
          weightGram: weight * 0.3,
        ),
        CrabWeightPoint(
          date: DateTime(2026, 3, 1),
          weightGram: weight,
        ),
      ],
    );
  }

  static final _crabA03 = _simple(
    id: 'CRAB-A03-004',
    displayCode: 'CR-0988',
    box: 'A03',
    batch: 'CFM-2026-001',
    gender: CrabGender.male,
    weight: 132,
    health: CrabHealthStatus.healthy,
    life: CrabLifeStatus.raising,
    score: 90,
    molts: 3,
  );

  static final _crabB02 = _simple(
    id: 'CRAB-B02-005',
    displayCode: 'CR-1102',
    box: 'B02',
    batch: 'CFM-2026-002',
    gender: CrabGender.female,
    weight: 145,
    health: CrabHealthStatus.good,
    life: CrabLifeStatus.readyForSale,
    score: 88,
    molts: 3,
  );

  static final _crabC01 = _simple(
    id: 'CRAB-C01-006',
    displayCode: 'CR-1044',
    box: 'C01',
    batch: 'CFM-2026-002',
    gender: CrabGender.male,
    weight: 98,
    health: CrabHealthStatus.molting,
    life: CrabLifeStatus.raising,
    score: 76,
    molts: 2,
  );

  static final _crabA04 = _simple(
    id: 'CRAB-A04-007',
    displayCode: 'CR-1056',
    box: 'A04',
    batch: 'CFM-2026-001',
    gender: CrabGender.female,
    weight: 110,
    health: CrabHealthStatus.monitoring,
    life: CrabLifeStatus.raising,
    score: 79,
    molts: 2,
  );

  static final _crabB03 = _simple(
    id: 'CRAB-B03-008',
    displayCode: 'CR-1089',
    box: 'B03',
    batch: 'CFM-2026-002',
    gender: CrabGender.male,
    weight: 155,
    health: CrabHealthStatus.good,
    life: CrabLifeStatus.readyForSale,
    score: 92,
    molts: 4,
    stage: CrabDevelopmentStage.harvestReady,
  );

  static final _crabA05 = _simple(
    id: 'CRAB-A05-009',
    displayCode: 'CR-0991',
    box: 'A05',
    batch: 'CFM-2026-001',
    gender: CrabGender.male,
    weight: 105,
    health: CrabHealthStatus.atRisk,
    life: CrabLifeStatus.dead,
    score: 62,
    molts: 1,
    alerts: 2,
  );

  static final _crabC02 = _simple(
    id: 'CRAB-C02-010',
    displayCode: 'CR-1012',
    box: 'C02',
    batch: 'CFM-2026-002',
    gender: CrabGender.female,
    weight: 88,
    health: CrabHealthStatus.monitoring,
    life: CrabLifeStatus.raising,
    score: 74,
    molts: 2,
  );

  static final _crabA06 = _simple(
    id: 'CRAB-A06-011',
    displayCode: 'CR-1033',
    box: 'A06',
    batch: 'CFM-2026-001',
    gender: CrabGender.female,
    weight: 128,
    health: CrabHealthStatus.healthy,
    life: CrabLifeStatus.raising,
    score: 89,
    molts: 3,
  );

  static final _crabB04 = _simple(
    id: 'CRAB-B04-012',
    displayCode: 'CR-1077',
    box: 'B04',
    batch: 'CFM-2026-002',
    gender: CrabGender.male,
    weight: 170,
    health: CrabHealthStatus.good,
    life: CrabLifeStatus.sold,
    score: 95,
    molts: 4,
  );

  static List<CrabSummaryKpi> managementSummaryKpis(CrabManagementSummary s) => [
        CrabSummaryKpi(
          label: 'TỔNG SỐ CUA',
          value: _formatNum(s.total),
          subtext: '↗ +12% so với tháng trước',
          icon: Icons.groups_outlined,
          accentColor: DashboardColors.oceanBlue,
        ),
        CrabSummaryKpi(
          label: 'CUA ĐANG SỐNG',
          value: _formatNum(s.alive),
          subtext: '${s.aliveRate.toStringAsFixed(1)}% tỷ lệ sống',
          icon: Icons.favorite_outline,
          accentColor: DashboardColors.healthy,
          showProgress: true,
          progress: s.aliveRate / 100,
        ),
        CrabSummaryKpi(
          label: 'CUA CHẾT',
          value: _formatNum(s.dead),
          subtext: 'Cần kiểm tra nguồn nước',
          icon: Icons.heart_broken_outlined,
          accentColor: DashboardColors.risk,
        ),
        CrabSummaryKpi(
          label: 'ĐANG LỘT XÁC',
          value: _formatNum(s.molting),
          subtext: 'Trạng thái nhạy cảm',
          icon: Icons.sync_outlined,
          accentColor: DashboardColors.molting,
        ),
        CrabSummaryKpi(
          label: 'SẮP THU HOẠCH',
          value: _formatNum(s.readyHarvest),
          subtext: 'Kích thước đạt chuẩn',
          icon: Icons.shopping_basket_outlined,
          accentColor: DashboardColors.seaGreen,
        ),
      ];

  static List<CrabSummaryKpi> summaryKpis(List<CrabIndividual> crabs) {
    final alive = crabs
        .where((c) => c.lifeStatus != CrabLifeStatus.dead && c.lifeStatus != CrabLifeStatus.sold)
        .length;
    final dead = crabs.where((c) => c.lifeStatus == CrabLifeStatus.dead).length;
    final molting =
        crabs.where((c) => c.healthStatus == CrabHealthStatus.molting).length;
    final ready = crabs
        .where((c) => c.lifeStatus == CrabLifeStatus.readyForSale)
        .length;
    final s = CrabManagementSummary(
      total: totalPopulation,
      alive: (totalPopulation * alive / crabs.length.clamp(1, 99)).round(),
      dead: (totalPopulation * dead / crabs.length.clamp(1, 99)).round(),
      molting: (totalPopulation * molting / crabs.length.clamp(1, 99)).round(),
      readyHarvest: (totalPopulation * ready / crabs.length.clamp(1, 99)).round(),
      aliveRate: alive / crabs.length.clamp(1, 99) * 100,
    );
    return managementSummaryKpis(s);
  }

  static CrabIndividual? findById(List<CrabIndividual> crabs, String id) {
    try {
      return crabs.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  static String _formatNum(int n) {
    if (n >= 1000) {
      final s = n.toString();
      final buf = StringBuffer();
      for (var i = 0; i < s.length; i++) {
        if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
        buf.write(s[i]);
      }
      return buf.toString();
    }
    return n.toString();
  }

  static String formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
