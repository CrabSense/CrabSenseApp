/// Models for Trung tâm AI — GET /ai/detections, /ai/recommendations.
class AiDetectionItem {
  const AiDetectionItem({
    required this.id,
    required this.detectionType,
    required this.confidence,
    required this.status,
    required this.detectedAt,
    required this.modelVersion,
    this.boxId,
    this.mediaId,
    this.resultJson,
  });

  final String id;
  final String detectionType;
  final double confidence;
  final String status;
  final DateTime detectedAt;
  final String modelVersion;
  final String? boxId;
  final String? mediaId;
  final String? resultJson;

  int get confidencePct => (confidence <= 1 ? confidence * 100 : confidence).round();

  String get typeLabelVi {
    final t = detectionType.toLowerCase();
    if (t.contains('molt') || t.contains('softshell')) return 'Lột xác';
    if (t.contains('health')) return 'Sức khỏe';
    if (t.contains('quarantine')) return 'Cách ly';
    if (t.contains('empty')) return 'Hộp trống';
    if (t.contains('occupancy')) return 'Đang nuôi';
    if (t.contains('grade')) return 'Phân loại';
    if (detectionType.trim().isEmpty) return 'Phát hiện';
    return detectionType;
  }

  String get statusLabelVi {
    final s = status.toLowerCase();
    if (s == 'completed') return 'Hoàn tất';
    if (s == 'pending') return 'Đang chờ';
    if (s == 'failed') return 'Lỗi';
    return status.isEmpty ? '—' : status;
  }

  factory AiDetectionItem.fromJson(Map<String, dynamic> json) {
    final conf = (json['confidence'] as num?)?.toDouble() ?? 0;
    return AiDetectionItem(
      id: json['id']?.toString() ?? '',
      detectionType: json['detectionType']?.toString() ?? '',
      confidence: conf,
      status: json['status']?.toString() ?? '',
      detectedAt: DateTime.tryParse(json['detectedAt']?.toString() ?? '') ??
          DateTime.now(),
      modelVersion: json['modelVersion']?.toString() ?? '—',
      boxId: json['boxId']?.toString(),
      mediaId: json['mediaId']?.toString(),
      resultJson: json['resultJson']?.toString(),
    );
  }
}

class AiRecommendationItem {
  const AiRecommendationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.targetBoxOrArea,
    required this.confidencePercentage,
    required this.priority,
    required this.reason,
    required this.optimalTimeframe,
    required this.expectedImpact,
    required this.hasActiveRecommendation,
  });

  final String id;
  final String type;
  final String title;
  final String description;
  final String targetBoxOrArea;
  final int confidencePercentage;
  final String priority;
  final String reason;
  final String optimalTimeframe;
  final String expectedImpact;
  final bool hasActiveRecommendation;

  String get priorityLabelVi {
    switch (priority.toLowerCase()) {
      case 'high':
        return 'Cao';
      case 'medium':
        return 'Trung bình';
      default:
        return 'Thấp';
    }
  }

  String get typeLabelVi {
    switch (type.toLowerCase()) {
      case 'harvest':
        return 'Thu hoạch';
      case 'inspect':
        return 'Kiểm tra';
      case 'watertreatment':
      case 'water_treatment':
        return 'Xử lý nước';
      default:
        return 'Theo dõi';
    }
  }

  factory AiRecommendationItem.fromJson(Map<String, dynamic> json) {
    return AiRecommendationItem(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'observe',
      title: json['title']?.toString() ?? 'Khuyến nghị AI',
      description: json['description']?.toString() ?? '',
      targetBoxOrArea: json['targetBoxOrArea']?.toString() ?? '',
      confidencePercentage:
          (json['confidencePercentage'] as num?)?.toInt() ?? 0,
      priority: json['priority']?.toString() ?? 'low',
      reason: json['reason']?.toString() ?? '',
      optimalTimeframe: json['optimalTimeframe']?.toString() ?? '',
      expectedImpact: json['expectedImpact']?.toString() ?? '',
      hasActiveRecommendation: json['hasActiveRecommendation'] != false,
    );
  }
}

enum AiCenterTab { overview, detections, recommendations }
