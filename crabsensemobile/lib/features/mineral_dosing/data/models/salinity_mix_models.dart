/// Models cho bộ tính PHA ĐỘ MẶN — `/api/mineral-dosing/salinity`.
///
/// Tách hẳn khỏi `mineral_dose_models.dart` vì đây là bài toán khác: thêm MUỐI để
/// tăng ‰ hoặc thêm NƯỚC NGỌT để giảm ‰. Ca/Mg không tham gia phép tính, phải đo
/// lại sau khi pha rồi mới sang tab khoáng.
///
/// Không có phép tính nào ở client: công thức nằm ở BE (`SalinityMixingCalculator`)
/// để mobile và desktop chỉ có MỘT nguồn sự thật.
library;

/// Loại muối dùng để tăng độ mặn — danh mục do BE trả, không chép lại ở client.
class SaltType {
  const SaltType({
    required this.key,
    required this.label,
    required this.note,
    this.typicalPurityPercent,
  });

  final String key;
  final String label;
  final String note;

  /// % tinh khiết thường gặp. `null` = KHÔNG có số đáng tin ⇒ để trống ô độ tinh
  /// khiết, hệ thống tính theo 100% (mức tối thiểu) và cảnh báo phải đo lại.
  final double? typicalPurityPercent;

  factory SaltType.fromJson(Map<String, dynamic> json) => SaltType(
        key: (json['key'] ?? '').toString(),
        label: (json['label'] ?? '').toString(),
        note: (json['note'] ?? '').toString(),
        typicalPurityPercent:
            (json['typicalPurityPercent'] as num?)?.toDouble(),
      );
}

/// Hướng cần điều chỉnh độ mặn — lấy từ BE, không tự suy ở client.
enum SalinityDirection {
  increase('INCREASE'),
  decrease('DECREASE'),
  hold('HOLD'),
  unknown('UNKNOWN');

  const SalinityDirection(this.apiValue);

  final String apiValue;

  static SalinityDirection fromApi(String? raw) {
    final key = (raw ?? '').trim().toUpperCase();
    for (final d in SalinityDirection.values) {
      if (d.apiValue == key) return d;
    }
    return SalinityDirection.unknown;
  }

  bool get needsSalt => this == SalinityDirection.increase;
  bool get needsFreshwater => this == SalinityDirection.decrease;
}

/// Input gửi lên `/api/mineral-dosing/salinity`.
class SalinityMixRequest {
  const SalinityMixRequest({
    required this.waterVolumeL,
    this.currentSalinityPpt,
    this.targetSalinityPpt,
    this.saltType = 'raw',
    this.saltPurityPercent,
  });

  /// Thể tích nước cần pha (L). Bắt buộc > 0.
  final double waterVolumeL;

  /// Độ mặn ĐO ĐƯỢC của nước hiện tại (‰).
  final double? currentSalinityPpt;

  /// Độ mặn mong muốn (‰). Phải > 0 nếu cần giảm.
  final double? targetSalinityPpt;

  /// raw | table | sea_salt_mix — chỉ dùng khi cần tăng độ mặn.
  final String saltType;

  /// % tinh khiết của lô muối. Bỏ trống = chưa biết ⇒ tính theo 100%.
  final double? saltPurityPercent;

  Map<String, dynamic> toJson() => {
        'waterVolumeL': waterVolumeL,
        if (currentSalinityPpt != null)
          'currentSalinityPpt': currentSalinityPpt,
        if (targetSalinityPpt != null) 'targetSalinityPpt': targetSalinityPpt,
        'saltType': saltType,
        if (saltPurityPercent != null) 'saltPurityPercent': saltPurityPercent,
      };
}

/// Kết quả tính pha độ mặn — trả từ `/api/mineral-dosing/salinity`.
///
/// Mọi trường số có thể null khi thiếu dữ liệu đầu vào tương ứng.
/// `null` nghĩa là "chưa tính được", KHÔNG phải 0.
class SalinityMixResult {
  const SalinityMixResult({
    required this.direction,
    required this.directionLabel,
    this.currentSalinityPpt,
    this.targetSalinityPpt,
    this.deltaPpt = 0,
    this.waterVolumeL = 0,
    this.theoreticalSaltKg,
    this.actualSaltKg,
    this.saltPurityPercent,
    this.purityAssumed = false,
    this.saltType = '',
    this.saltTypeLabel = '',
    this.saltTypeNote = '',
    this.freshwaterToAddL,
    this.finalVolumeL,
    this.waterToReplaceL,
    this.maxChangePerBatchPpt = 0,
    this.batchCount = 0,
    this.saltKgPerBatch,
    this.freshwaterLPerBatch,
    this.batchIntervalHours = 12,
    this.instructions = const [],
    this.warnings = const [],
    this.nextSteps = const [],
  });

  final SalinityDirection direction;

  /// Nhãn tiếng Việt do BE trả — ví dụ "Cần TĂNG 10‰".
  final String directionLabel;

  final double? currentSalinityPpt;
  final double? targetSalinityPpt;

  /// Dương = cần tăng, âm = cần giảm, 0 = đã đạt (hoặc chưa tính được).
  final double deltaPpt;

  final double waterVolumeL;

  /// kg muối nếu muối tinh khiết 100% — mức TỐI THIỂU phải dùng.
  final double? theoreticalSaltKg;

  /// kg muối thực tế theo độ tinh khiết đã nhập.
  final double? actualSaltKg;

  final double? saltPurityPercent;

  /// true = chưa có số tinh khiết nên BE tính theo 100%.
  final bool purityAssumed;

  final String saltType;
  final String saltTypeLabel;
  final String saltTypeNote;

  /// L nước ngọt đã khử clo cần thêm — cách này làm TĂNG thể tích lên [finalVolumeL].
  final double? freshwaterToAddL;

  /// Thể tích sau khi thêm nước ngọt.
  final double? finalVolumeL;

  /// L nước cần THAY (rút ra rồi châm lại nước ngọt) — giữ nguyên thể tích.
  final double? waterToReplaceL;

  /// Trần đổi độ mặn mỗi lần pha (‰).
  final double maxChangePerBatchPpt;

  /// Số lần pha (0 = không cần làm gì).
  final int batchCount;

  final double? saltKgPerBatch;
  final double? freshwaterLPerBatch;

  /// Số giờ tối thiểu giữa hai lần pha.
  final int batchIntervalHours;

  /// Các bước pha theo thứ tự.
  final List<String> instructions;

  final List<String> warnings;

  /// Việc phải làm sau khi pha: đo lại, rồi sang tab Ca/Mg, rồi kiểm tra cuối.
  final List<String> nextSteps;

  static double? _d(Map<String, dynamic> j, String k) =>
      (j[k] as num?)?.toDouble();

  static String? _s(Map<String, dynamic> j, String k) => j[k]?.toString();

  static List<String> _list(Map<String, dynamic> j, String k) =>
      (j[k] as List?)?.map((e) => e.toString()).toList(growable: false) ??
      const [];

  factory SalinityMixResult.fromJson(Map<String, dynamic> json) {
    return SalinityMixResult(
      direction: SalinityDirection.fromApi(_s(json, 'direction')),
      directionLabel: _s(json, 'directionLabel') ?? '',
      currentSalinityPpt: _d(json, 'currentSalinityPpt'),
      targetSalinityPpt: _d(json, 'targetSalinityPpt'),
      deltaPpt: _d(json, 'deltaPpt') ?? 0,
      waterVolumeL: _d(json, 'waterVolumeL') ?? 0,
      theoreticalSaltKg: _d(json, 'theoreticalSaltKg'),
      actualSaltKg: _d(json, 'actualSaltKg'),
      saltPurityPercent: _d(json, 'saltPurityPercent'),
      purityAssumed: json['purityAssumed'] == true,
      saltType: _s(json, 'saltType') ?? '',
      saltTypeLabel: _s(json, 'saltTypeLabel') ?? '',
      saltTypeNote: _s(json, 'saltTypeNote') ?? '',
      freshwaterToAddL: _d(json, 'freshwaterToAddL'),
      finalVolumeL: _d(json, 'finalVolumeL'),
      waterToReplaceL: _d(json, 'waterToReplaceL'),
      maxChangePerBatchPpt: _d(json, 'maxChangePerBatchPpt') ?? 0,
      batchCount: (json['batchCount'] as num?)?.toInt() ?? 0,
      saltKgPerBatch: _d(json, 'saltKgPerBatch'),
      freshwaterLPerBatch: _d(json, 'freshwaterLPerBatch'),
      batchIntervalHours:
          (json['batchIntervalHours'] as num?)?.toInt() ?? 12,
      instructions: _list(json, 'instructions'),
      warnings: _list(json, 'warnings'),
      nextSteps: _list(json, 'nextSteps'),
    );
  }
}
