/// Models cho bộ tính liều khoáng Ca/Mg — `/api/mineral-dosing`.
///
/// Bốn loại giá trị PHẢI luôn phân biệt rõ trên UI (yêu cầu nghiệp vụ):
///   1. measured    — số đo thực từ test  ([ValueSource.measured])
///   2. estimated   — số ước lượng, không phải test ([ValueSource.estimated])
///   3. recommended — mục tiêu hệ đề xuất theo độ mặn ([MineralTargetRecommendation])
///   4. calculated  — liều hoá chất suy từ chênh lệch ([MineralDoseResult.caCl2DoseGrams])
///
/// Không có giá trị nào ở đây được suy diễn ở client: mọi phép tính nằm ở BE
/// (`MineralDosingCalculator`) để chỉ có MỘT nguồn sự thật cho công thức.
library;

/// Nguồn của một giá trị hiện tại — lấy từ BE, không tự đoán ở client.
enum ValueSource {
  /// Số đo thực từ test.
  measured,

  /// Số ước lượng, không phải kết quả test ⇒ liều chỉ mang tính tham khảo.
  estimated,

  /// Chưa có số ⇒ không tính được liều tương ứng.
  missing;

  static ValueSource fromApi(String? raw) {
    switch ((raw ?? '').trim().toLowerCase()) {
      case 'measured':
        return ValueSource.measured;
      case 'estimated':
        return ValueSource.estimated;
      default:
        return ValueSource.missing;
    }
  }

  String get labelVi {
    switch (this) {
      case ValueSource.measured:
        return 'Đã đo';
      case ValueSource.estimated:
        return 'Ước lượng';
      case ValueSource.missing:
        return 'Chưa đo';
    }
  }
}

/// Chế độ chọn mục tiêu Ca/Mg.
enum MineralTargetMode {
  /// Hệ thống đề xuất mục tiêu theo độ mặn; mục tiêu để trống sẽ được điền tự động.
  auto('auto'),

  /// Người dùng tự nhập mục tiêu; hệ thống KHÔNG tự sửa.
  manual('manual');

  const MineralTargetMode(this.apiValue);

  final String apiValue;
}

/// Input gửi lên `/api/mineral-dosing/calculate`.
class MineralDoseRequest {
  const MineralDoseRequest({
    required this.waterVolumeL,
    this.salinityCurrentPpt,
    this.salinityTargetPpt,
    this.calciumCurrentMgL,
    this.calciumTargetMgL,
    this.magnesiumCurrentMgL,
    this.magnesiumTargetMgL,
    this.calciumMeasured = true,
    this.magnesiumMeasured = true,
    this.targetMode = MineralTargetMode.auto,
  });

  /// Thể tích nước cần xử lý (L). Bắt buộc > 0.
  final double waterVolumeL;

  /// Độ mặn hiện tại (‰) — dùng để CHỌN mục tiêu và so sánh, không vào phép tính gram.
  final double? salinityCurrentPpt;

  /// Độ mặn mong muốn (‰) — chỉ để báo trạng thái.
  final double? salinityTargetPpt;

  /// Ca hiện tại (mg/L). Bỏ trống ⇒ không tính được liều CaCl2.
  final double? calciumCurrentMgL;

  /// Ca mục tiêu (mg/L). Ở chế độ auto để trống ⇒ BE điền theo độ mặn.
  final double? calciumTargetMgL;

  /// Mg hiện tại (mg/L). Bỏ trống ⇒ KHÔNG tính liều MgCl2 (không suy Mg từ Ca).
  final double? magnesiumCurrentMgL;

  /// Mg mục tiêu (mg/L). Ở chế độ auto để trống ⇒ BE điền theo độ mặn.
  final double? magnesiumTargetMgL;

  /// Ca hiện tại là số đo thật hay số ước lượng.
  final bool calciumMeasured;

  /// Mg hiện tại là số đo thật hay số ước lượng.
  final bool magnesiumMeasured;

  final MineralTargetMode targetMode;

  Map<String, dynamic> toJson() => {
        'waterVolumeL': waterVolumeL,
        if (salinityCurrentPpt != null) 'salinityCurrentPpt': salinityCurrentPpt,
        if (salinityTargetPpt != null) 'salinityTargetPpt': salinityTargetPpt,
        if (calciumCurrentMgL != null) 'calciumCurrentMgL': calciumCurrentMgL,
        if (calciumTargetMgL != null) 'calciumTargetMgL': calciumTargetMgL,
        if (magnesiumCurrentMgL != null)
          'magnesiumCurrentMgL': magnesiumCurrentMgL,
        if (magnesiumTargetMgL != null)
          'magnesiumTargetMgL': magnesiumTargetMgL,
        'calciumMeasured': calciumMeasured,
        'magnesiumMeasured': magnesiumMeasured,
        'targetMode': targetMode.apiValue,
      };
}

/// Mục tiêu Ca/Mg đề xuất theo độ mặn — trả từ `/api/mineral-dosing/targets`.
///
/// Đây là giá trị ĐỀ XUẤT, không bắt buộc. UI phải ghi rõ điều đó.
class MineralTargetRecommendation {
  const MineralTargetRecommendation({
    this.salinityPpt,
    this.calciumMgL,
    this.magnesiumMgL,
    this.ratio,
    this.totalMgL,
    this.note = '',
    this.warnings = const [],
  });

  final double? salinityPpt;
  final double? calciumMgL;
  final double? magnesiumMgL;

  /// Dạng "1:3".
  final String? ratio;

  /// Tổng Ca+Mg của mục tiêu — tổng quan trọng ngang tỷ lệ.
  final double? totalMgL;

  final String note;
  final List<String> warnings;

  bool get hasTargets => calciumMgL != null && magnesiumMgL != null;

  static double? _d(Map<String, dynamic> j, String k) =>
      (j[k] as num?)?.toDouble();

  factory MineralTargetRecommendation.fromJson(Map<String, dynamic> json) {
    return MineralTargetRecommendation(
      salinityPpt: _d(json, 'salinityPpt'),
      calciumMgL: _d(json, 'recommendedCalciumMgL'),
      magnesiumMgL: _d(json, 'recommendedMagnesiumMgL'),
      ratio: json['recommendedCaMgRatio']?.toString(),
      totalMgL: _d(json, 'calciumMagnesiumTotalMgL'),
      note: json['note']?.toString() ?? '',
      warnings: (json['warnings'] as List?)
              ?.map((e) => e.toString())
              .toList(growable: false) ??
          const [],
    );
  }
}

/// Kết quả tính liều — trả từ `/api/mineral-dosing/calculate`.
///
/// Mọi trường số có thể null khi thiếu dữ liệu đầu vào tương ứng.
/// `null` nghĩa là "chưa tính được", KHÔNG phải 0.
class MineralDoseResult {
  const MineralDoseResult({
    required this.targetMode,
    required this.usedRecommendedTargets,
    this.recommendedCalciumMgL,
    this.recommendedMagnesiumMgL,
    this.recommendedCaMgRatio,
    this.calciumTargetMgL,
    this.magnesiumTargetMgL,
    this.calciumMagnesiumTotalTargetMgL,
    this.calciumCurrentMgL,
    this.magnesiumCurrentMgL,
    this.calciumCurrentSource = ValueSource.missing,
    this.magnesiumCurrentSource = ValueSource.missing,
    this.calciumMagnesiumTotalCurrentMgL,
    this.calciumDeficitMgL,
    this.magnesiumDeficitMgL,
    this.caCl2DoseGrams,
    this.mgCl2DoseGrams,
    this.caCl2Product = '',
    this.mgCl2Product = '',
    this.salinityStatus = '',
    this.salinityStatusLabel = '',
    this.maxIncreasePerDoseMgL = 0,
    this.doseCount = 0,
    this.caCl2GramsPerDose,
    this.mgCl2GramsPerDose,
    this.doseIntervalHours = 24,
    this.dosingInstructions = const [],
    this.warnings = const [],
  });

  final String targetMode;

  /// true khi ít nhất một mục tiêu lấy từ đề xuất thay vì người dùng nhập.
  final bool usedRecommendedTargets;

  final double? recommendedCalciumMgL;
  final double? recommendedMagnesiumMgL;
  final String? recommendedCaMgRatio;

  final double? calciumTargetMgL;
  final double? magnesiumTargetMgL;
  final double? calciumMagnesiumTotalTargetMgL;

  final double? calciumCurrentMgL;
  final double? magnesiumCurrentMgL;
  final ValueSource calciumCurrentSource;
  final ValueSource magnesiumCurrentSource;
  final double? calciumMagnesiumTotalCurrentMgL;

  /// Dương = thiếu (cần châm); âm = đang vượt mục tiêu; null = chưa tính được.
  final double? calciumDeficitMgL;
  final double? magnesiumDeficitMgL;

  /// Liều sản phẩm thương mại (gram). 0 = đã đủ/vượt; null = chưa tính được.
  final double? caCl2DoseGrams;
  final double? mgCl2DoseGrams;

  final String caCl2Product;
  final String mgCl2Product;

  /// SALINITY_OK | SALINITY_LOW | SALINITY_HIGH | SALINITY_UNKNOWN.
  final String salinityStatus;
  final String salinityStatusLabel;

  // ── Kế hoạch chia liều: châm nhiều lần để KHÔNG sốc cua ────────────────

  /// Trần tăng nồng độ mỗi lần châm (mg/L) — ngưỡng an toàn vận hành.
  final double maxIncreasePerDoseMgL;

  /// Số lần châm (0 = không cần châm).
  final int doseCount;

  /// gram mỗi lần châm; null khi không tính được, 0 khi đã đủ.
  final double? caCl2GramsPerDose;
  final double? mgCl2GramsPerDose;

  /// Số giờ tối thiểu giữa hai lần châm.
  final int doseIntervalHours;

  /// Các bước pha & châm theo thứ tự.
  final List<String> dosingInstructions;

  final List<String> warnings;

  /// Không đo Mg ⇒ không được suy từ Ca, và UI phải yêu cầu đo Mg.
  bool get magnesiumMissing =>
      magnesiumCurrentSource == ValueSource.missing ||
      magnesiumCurrentMgL == null;

  bool get calciumMissing =>
      calciumCurrentSource == ValueSource.missing || calciumCurrentMgL == null;

  /// Có gì phải châm không. false ⇒ Ca/Mg đã đạt hoặc vượt mục tiêu.
  bool get needsDosing => doseCount > 0;

  static double? _d(Map<String, dynamic> j, String k) =>
      (j[k] as num?)?.toDouble();

  static String? _s(Map<String, dynamic> j, String k) => j[k]?.toString();

  factory MineralDoseResult.fromJson(Map<String, dynamic> json) {
    return MineralDoseResult(
      targetMode: _s(json, 'targetMode') ?? MineralTargetMode.auto.apiValue,
      usedRecommendedTargets: json['usedRecommendedTargets'] == true,
      recommendedCalciumMgL: _d(json, 'recommendedCalciumMgL'),
      recommendedMagnesiumMgL: _d(json, 'recommendedMagnesiumMgL'),
      recommendedCaMgRatio: _s(json, 'recommendedCaMgRatio'),
      calciumTargetMgL: _d(json, 'calciumTargetMgL'),
      magnesiumTargetMgL: _d(json, 'magnesiumTargetMgL'),
      calciumMagnesiumTotalTargetMgL:
          _d(json, 'calciumMagnesiumTotalTargetMgL'),
      calciumCurrentMgL: _d(json, 'calciumCurrentMgL'),
      magnesiumCurrentMgL: _d(json, 'magnesiumCurrentMgL'),
      calciumCurrentSource: ValueSource.fromApi(_s(json, 'calciumCurrentSource')),
      magnesiumCurrentSource:
          ValueSource.fromApi(_s(json, 'magnesiumCurrentSource')),
      calciumMagnesiumTotalCurrentMgL:
          _d(json, 'calciumMagnesiumTotalCurrentMgL'),
      calciumDeficitMgL: _d(json, 'calciumDeficitMgL'),
      magnesiumDeficitMgL: _d(json, 'magnesiumDeficitMgL'),
      caCl2DoseGrams: _d(json, 'caCl2DoseGrams'),
      mgCl2DoseGrams: _d(json, 'mgCl2DoseGrams'),
      caCl2Product: _s(json, 'caCl2Product') ?? '',
      mgCl2Product: _s(json, 'mgCl2Product') ?? '',
      salinityStatus: _s(json, 'salinityStatus') ?? '',
      salinityStatusLabel: _s(json, 'salinityStatusLabel') ?? '',
      maxIncreasePerDoseMgL: _d(json, 'maxIncreasePerDoseMgL') ?? 0,
      doseCount: (json['doseCount'] as num?)?.toInt() ?? 0,
      caCl2GramsPerDose: _d(json, 'caCl2GramsPerDose'),
      mgCl2GramsPerDose: _d(json, 'mgCl2GramsPerDose'),
      doseIntervalHours: (json['doseIntervalHours'] as num?)?.toInt() ?? 24,
      dosingInstructions: (json['dosingInstructions'] as List?)
              ?.map((e) => e.toString())
              .toList(growable: false) ??
          const [],
      warnings: (json['warnings'] as List?)
              ?.map((e) => e.toString())
              .toList(growable: false) ??
          const [],
    );
  }
}
