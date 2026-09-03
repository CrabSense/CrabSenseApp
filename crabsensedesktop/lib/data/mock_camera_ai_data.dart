import 'package:flutter/material.dart';

import '../config/app_env.dart';
import '../models/camera_ai.dart';
import '../theme/dashboard_theme.dart';

abstract final class MockCameraAiData {
  static const cameraTabs = ['Camera 1', 'Camera 2', 'Camera 3', 'Tất cả camera'];
  static const cameraFilterOptions = ['Tất cả', 'Camera 1', 'Camera 2', 'Camera 3'];
  static const typeFilterOptions = [
    'Tất cả',
    'Lột xác',
    'Chết',
    'Bỏ ăn',
    'Thoát hộp',
    'Rong bám',
    'Bất thường',
  ];
  static const levelFilterOptions = ['Tất cả', 'Theo dõi', 'Cảnh báo', 'Khẩn cấp'];
  static const statusFilterOptions = [
    'Tất cả',
    'Chưa xử lý',
    'Đã xác nhận',
    'Báo sai AI',
  ];

  static List<CameraFeed> cameras() => [
        CameraFeed(
          id: 'cam1',
          name: 'Camera 1',
          area: 'Khu A',
          status: CameraStatus.online,
          fps: 24,
          resolution: '1080p',
          lastUpdateSeconds: 2,
          ipAddress: AppEnv.camera1Ip,
          streamUrl: AppEnv.camera1StreamUrl,
          snapshotFallbackUrl: AppEnv.camera1SnapshotFallbackUrl,
          overlays: const [
            AiBoundingBox(
              label: 'Cua lột xác',
              confidence: 0.91,
              left: 0.38,
              top: 0.32,
              width: 0.18,
              height: 0.22,
              color: Colors.white,
            ),
            AiBoundingBox(
              label: 'Bất thường',
              confidence: 0.82,
              left: 0.62,
              top: 0.48,
              width: 0.16,
              height: 0.18,
              color: DashboardColors.molting,
            ),
          ],
        ),
        CameraFeed(
          id: 'cam2',
          name: 'Camera 2',
          area: 'Khu B',
          status: CameraStatus.online,
          fps: 24,
          resolution: '1080p',
          lastUpdateSeconds: 3,
          ipAddress: AppEnv.camera2Ip,
          streamUrl: AppEnv.camera2StreamUrl,
          snapshotFallbackUrl: AppEnv.camera2SnapshotFallbackUrl,
          overlays: const [
            AiBoundingBox(
              label: 'Cua chết',
              confidence: 0.96,
              left: 0.45,
              top: 0.4,
              width: 0.14,
              height: 0.16,
              color: DashboardColors.risk,
            ),
          ],
        ),
        CameraFeed(
          id: 'cam3',
          name: 'Camera 3',
          area: 'Khu C',
          status: CameraStatus.lag,
          fps: 18,
          resolution: '1080p',
          lastUpdateSeconds: 8,
          overlays: const [],
        ),
      ];

  static List<AiCameraEvent> events() => [
        AiCameraEvent(
          id: 'e1',
          time: '10:35',
          cameraId: 'cam1',
          cameraLabel: 'Cam 1',
          boxId: 'A07',
          crabId: 'CRAB-A07-001',
          detectionType: AiDetectionType.molting,
          confidence: 0.91,
          level: AiEventLevel.warning,
          status: AiEventStatus.pending,
        ),
        AiCameraEvent(
          id: 'e2',
          time: '10:28',
          cameraId: 'cam1',
          cameraLabel: 'Cam 1',
          boxId: 'D09',
          crabId: 'CRAB-D09-002',
          detectionType: AiDetectionType.escaped,
          confidence: 0.85,
          level: AiEventLevel.critical,
          status: AiEventStatus.pending,
        ),
        AiCameraEvent(
          id: 'e3',
          time: '10:15',
          cameraId: 'cam1',
          cameraLabel: 'Cam 1',
          boxId: 'B12',
          crabId: 'CRAB-B12-003',
          detectionType: AiDetectionType.algae,
          confidence: 0.78,
          level: AiEventLevel.info,
          status: AiEventStatus.viewed,
        ),
        AiCameraEvent(
          id: 'e4',
          time: '11:10',
          cameraId: 'cam2',
          cameraLabel: 'Cam 2',
          boxId: 'B03',
          crabId: 'CRAB-B03-004',
          detectionType: AiDetectionType.dead,
          confidence: 0.96,
          level: AiEventLevel.critical,
          status: AiEventStatus.pending,
        ),
        AiCameraEvent(
          id: 'e5',
          time: '18:20',
          cameraId: 'cam3',
          cameraLabel: 'Cam 3',
          boxId: 'C12',
          crabId: 'CRAB-C12-005',
          detectionType: AiDetectionType.skippedMeal,
          confidence: 0.84,
          level: AiEventLevel.warning,
          status: AiEventStatus.pending,
          note: 'Thức ăn còn nhiều sau 2 giờ',
        ),
        AiCameraEvent(
          id: 'e6',
          time: '09:45',
          cameraId: 'cam1',
          cameraLabel: 'Cam 1',
          boxId: 'A15',
          crabId: 'CRAB-A15-006',
          detectionType: AiDetectionType.escaped,
          confidence: 0.89,
          level: AiEventLevel.critical,
          status: AiEventStatus.viewed,
        ),
        AiCameraEvent(
          id: 'e7',
          time: '14:05',
          cameraId: 'cam2',
          cameraLabel: 'Cam 2',
          boxId: 'B08',
          crabId: 'CRAB-B08-007',
          detectionType: AiDetectionType.algae,
          confidence: 0.78,
          level: AiEventLevel.info,
          status: AiEventStatus.pending,
          note: 'Khuyến nghị: Vệ sinh hộp',
        ),
        AiCameraEvent(
          id: 'e8',
          time: '10:02',
          cameraId: 'cam3',
          cameraLabel: 'Cam 3',
          boxId: 'C04',
          crabId: 'CRAB-C04-008',
          detectionType: AiDetectionType.abnormal,
          confidence: 0.82,
          level: AiEventLevel.warning,
          status: AiEventStatus.pending,
          note: 'Di chuyển chậm, ít phản ứng',
        ),
      ];

  static List<AiDetectionCount> detectionCountsFor(String? cameraId) {
    if (cameraId == 'cam1') {
      return const [
        AiDetectionCount(type: AiDetectionType.molting, count: 2),
        AiDetectionCount(type: AiDetectionType.dead, count: 0),
        AiDetectionCount(type: AiDetectionType.skippedMeal, count: 3),
        AiDetectionCount(type: AiDetectionType.escaped, count: 1),
        AiDetectionCount(type: AiDetectionType.algae, count: 4),
        AiDetectionCount(type: AiDetectionType.abnormal, count: 2),
      ];
    }
    final list = cameraId == null
        ? events()
        : events().where((e) => e.cameraId == cameraId).toList();
    return AiDetectionType.values
        .map(
          (t) => AiDetectionCount(
            type: t,
            count: list.where((e) => e.detectionType == t).length,
          ),
        )
        .toList();
  }

  static String aiInsightFor(String? cameraId) {
    if (cameraId == 'cam1') {
      return 'Camera 1 phát hiện 2 cua đang lột xác tại khu A.\n'
          'Camera 2 không có cảnh báo nghiêm trọng.\n'
          'Camera 3 có 3 trường hợp bỏ ăn cần theo dõi.';
    }
    return 'Hệ thống đang giám sát 3 camera. Tổng ${events().where((e) => e.status == AiEventStatus.pending).length} sự kiện chưa xử lý.';
  }

  static String aiRecommendation() =>
      'Kiểm tra hộp C12 và C15.\n'
      'Giảm tác động mạnh tại khu A trong 24 giờ tới.';

  static AiDetectionType? typeFromFilter(String label) => switch (label) {
        'Lột xác' => AiDetectionType.molting,
        'Chết' => AiDetectionType.dead,
        'Bỏ ăn' => AiDetectionType.skippedMeal,
        'Thoát hộp' => AiDetectionType.escaped,
        'Rong bám' => AiDetectionType.algae,
        'Bất thường' => AiDetectionType.abnormal,
        _ => null,
      };

  static String? cameraIdFromTab(String tab) => switch (tab) {
        'Camera 1' => 'cam1',
        'Camera 2' => 'cam2',
        'Camera 3' => 'cam3',
        _ => null,
      };

  static String? cameraIdFromFilter(String label) => switch (label) {
        'Camera 1' => 'cam1',
        'Camera 2' => 'cam2',
        'Camera 3' => 'cam3',
        _ => null,
      };
}
