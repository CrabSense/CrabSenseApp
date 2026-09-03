import 'package:flutter/material.dart';

import '../theme/dashboard_theme.dart';

enum CameraStatus {
  online,
  offline,
  lag;

  String get label => switch (this) {
        CameraStatus.online => 'Online',
        CameraStatus.offline => 'Offline',
        CameraStatus.lag => 'Lag',
      };

  Color get color => switch (this) {
        CameraStatus.online => DashboardColors.healthy,
        CameraStatus.offline => DashboardColors.risk,
        CameraStatus.lag => DashboardColors.monitoring,
      };
}

enum AiDetectionType {
  molting,
  dead,
  skippedMeal,
  escaped,
  algae,
  abnormal;

  String get label => switch (this) {
        AiDetectionType.molting => 'Cua lột xác',
        AiDetectionType.dead => 'Cua chết',
        AiDetectionType.skippedMeal => 'Cua bỏ ăn',
        AiDetectionType.escaped => 'Cua thoát hộp',
        AiDetectionType.algae => 'Rong bám',
        AiDetectionType.abnormal => 'Bất thường',
      };

  IconData get icon => switch (this) {
        AiDetectionType.molting => Icons.sync,
        AiDetectionType.dead => Icons.dangerous_outlined,
        AiDetectionType.skippedMeal => Icons.no_food_outlined,
        AiDetectionType.escaped => Icons.open_in_new,
        AiDetectionType.algae => Icons.grass_outlined,
        AiDetectionType.abnormal => Icons.warning_amber_outlined,
      };

  Color get accentColor => switch (this) {
        AiDetectionType.molting => DashboardColors.cyan,
        AiDetectionType.dead => DashboardColors.risk,
        AiDetectionType.skippedMeal => DashboardColors.monitoring,
        AiDetectionType.escaped => DashboardColors.molting,
        AiDetectionType.algae => DashboardColors.blue,
        AiDetectionType.abnormal => DashboardColors.risk,
      };
}

enum AiEventLevel {
  info,
  warning,
  critical;

  String get label => switch (this) {
        AiEventLevel.info => 'INFO',
        AiEventLevel.warning => 'WARNING',
        AiEventLevel.critical => 'CRITICAL',
      };

  Color get color => switch (this) {
        AiEventLevel.info => DashboardColors.textMuted,
        AiEventLevel.warning => DashboardColors.monitoring,
        AiEventLevel.critical => DashboardColors.risk,
      };
}

enum AiEventStatus {
  pending,
  viewed,
  confirmed,
  falsePositive;

  String get label => switch (this) {
        AiEventStatus.pending => 'Chưa xử lý',
        AiEventStatus.viewed => 'Đã xem',
        AiEventStatus.confirmed => 'Đã xác nhận',
        AiEventStatus.falsePositive => 'Báo sai AI',
      };
}

class CameraFeed {
  const CameraFeed({
    required this.id,
    required this.name,
    required this.area,
    required this.status,
    required this.fps,
    required this.resolution,
    required this.lastUpdateSeconds,
    required this.overlays,
    this.streamUrl,
    this.ipAddress,
    this.snapshotFallbackUrl,
    this.streamUrlCandidates,
    this.maxFps = 10,
    this.snapshotOnly = false,
    this.htmlPageMode = false,
    this.pollMinMs = 3500,
  });

  final String id;
  final String name;
  final String area;
  final CameraStatus status;
  final int fps;
  final String resolution;
  final int lastUpdateSeconds;
  final List<AiBoundingBox> overlays;

  /// HTTP MJPEG hoặc RTSP — null = placeholder.
  final String? streamUrl;
  final String? ipAddress;
  final String? snapshotFallbackUrl;
  final List<String>? streamUrlCandidates;
  final int maxFps;
  final bool snapshotOnly;
  final bool htmlPageMode;
  final int pollMinMs;
}

class AiBoundingBox {
  const AiBoundingBox({
    required this.label,
    required this.confidence,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.color,
  });

  final String label;
  final double confidence;
  final double left;
  final double top;
  final double width;
  final double height;
  final Color color;
}

class AiDetectionCount {
  const AiDetectionCount({required this.type, required this.count});

  final AiDetectionType type;
  final int count;
}

class AiCameraEvent {
  const AiCameraEvent({
    required this.id,
    required this.time,
    required this.cameraId,
    required this.cameraLabel,
    required this.boxId,
    required this.crabId,
    required this.detectionType,
    required this.confidence,
    required this.level,
    required this.status,
    this.note,
  });

  final String id;
  final String time;
  final String cameraId;
  final String cameraLabel;
  final String boxId;
  final String crabId;
  final AiDetectionType detectionType;
  final double confidence;
  final AiEventLevel level;
  final AiEventStatus status;
  final String? note;

  AiCameraEvent copyWith({AiEventStatus? status}) {
    return AiCameraEvent(
      id: id,
      time: time,
      cameraId: cameraId,
      cameraLabel: cameraLabel,
      boxId: boxId,
      crabId: crabId,
      detectionType: detectionType,
      confidence: confidence,
      level: level,
      status: status ?? this.status,
      note: note,
    );
  }
}
